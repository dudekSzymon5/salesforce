@IsTest
private class ProductSyncRetryQueueableTest {

    @TestSetup
    static void makeData() {
         TriggerBase.bypass('Product2');

        TestDataFactory.product().withCode('RET-01').create();
        TestDataFactory.product().withCode('RET-02').create();
        TestDataFactory.product().withCode('RET-MAX').create();
        TestDataFactory.product().withCode('DEL-01').create();
        TestDataFactory.product().withCode('RET-EMAIL').create();
        TriggerBase.clearBypass('Product2');
    }

    @IsTest
    static void testRetryInsertSuccessMarksSuccessAndRefreshesPayload() {
        Product2 product = [SELECT Id FROM Product2 WHERE ProductCode = 'RET-01'];
        Product_Sync_Queue__c queueRecord = TestDataFactory.queueRecord()
            .forProduct(product.Id)
            .withPayload('{"old":"payload"}')
            .create();

        Test.setMock(HttpCalloutMock.class, TestDataFactory.httpSuccess());
        Test.startTest();
        System.enqueueJob(new ProductSyncRetryQueueable());
        Test.stopTest();

        Product_Sync_Queue__c result = [SELECT Status__c, Attempt_Count__c, Payload__c FROM Product_Sync_Queue__c WHERE Id = :queueRecord.Id];
        Assert.areEqual(Utils.PRODUCT_SYNC.STATUS.SUCCESS, result.Status__c);
        Assert.areEqual(2, result.Attempt_Count__c, 'Attempt_Count should increment by 1');
        Assert.areNotEqual('{"old":"payload"}', result.Payload__c, 'Payload should be refreshed with current product data');
    }

    @IsTest
    static void testRetryInsertServerErrorRemainsFailed() {
        Product2 product = [SELECT Id FROM Product2 WHERE ProductCode = 'RET-02'];
        Product_Sync_Queue__c queueRecord = TestDataFactory.queueRecord().forProduct(product.Id).create();

        Test.setMock(HttpCalloutMock.class, TestDataFactory.httpError());
        Test.startTest();
        System.enqueueJob(new ProductSyncRetryQueueable());
        Test.stopTest();

        Product_Sync_Queue__c result = [SELECT Status__c, Attempt_Count__c FROM Product_Sync_Queue__c WHERE Id = :queueRecord.Id];
        Assert.areEqual(Utils.PRODUCT_SYNC.STATUS.FAILED, result.Status__c);
        Assert.areEqual(2, result.Attempt_Count__c);
    }

    @IsTest
    static void testRetryInsertProductDeletedSkipsCalloutAndMarksSuccess() {
        Product2 product = [SELECT Id FROM Product2 WHERE ProductCode = 'DEL-01'];
        Product_Sync_Queue__c queueRecord = TestDataFactory.queueRecord().forProduct(product.Id).create();

        TriggerBase.bypass('Product2');
        delete product;
        TriggerBase.clearBypass('Product2');

        Test.setMock(HttpCalloutMock.class, TestDataFactory.httpSuccess());
        Test.startTest();
        System.enqueueJob(new ProductSyncRetryQueueable());
        Test.stopTest();

        Product_Sync_Queue__c result = [SELECT Status__c FROM Product_Sync_Queue__c WHERE Id = :queueRecord.Id];
        Assert.areEqual(
            Utils.PRODUCT_SYNC.STATUS.SUCCESS, result.Status__c,
            'Deleted product should skip callout and be marked Success'
        );
    }

    @IsTest
    static void testRetryDeleteSuccessMarksSuccess() {
        Product_Sync_Queue__c queueRecord = TestDataFactory.queueRecord()
            .asDelete('EXT-PROD-001').create();

        Test.setMock(HttpCalloutMock.class, TestDataFactory.httpSuccess('{"status":"deleted"}'));
        Test.startTest();
        System.enqueueJob(new ProductSyncRetryQueueable());
        Test.stopTest();

        Product_Sync_Queue__c result = [SELECT Status__c, Attempt_Count__c FROM Product_Sync_Queue__c WHERE Id = :queueRecord.Id];
        Assert.areEqual(Utils.PRODUCT_SYNC.STATUS.SUCCESS, result.Status__c);
        Assert.areEqual(2, result.Attempt_Count__c);
    }

    @IsTest
    static void testRetryMaxAttemptsReachedRecordNotProcessed() {
        Product2 product = [SELECT Id FROM Product2 WHERE ProductCode = 'RET-MAX'];
        Product_Sync_Queue__c queueRecord = TestDataFactory.queueRecord()
            .forProduct(product.Id)
            .withAttempts(3).create();

        Test.setMock(HttpCalloutMock.class, TestDataFactory.httpSuccess());
        Test.startTest();
        System.enqueueJob(new ProductSyncRetryQueueable());
        Test.stopTest();

        Product_Sync_Queue__c result = [SELECT Status__c, Attempt_Count__c FROM Product_Sync_Queue__c WHERE Id = :queueRecord.Id];
        Assert.areEqual(Utils.PRODUCT_SYNC.STATUS.FAILED, result.Status__c, 'Record at MAX_ATTEMPTS should not be retried');
        Assert.areEqual(3, result.Attempt_Count__c, 'Attempt_Count should not change');
    }

    @IsTest
    static void testRetryEmptyQueueCompletesWithoutError() {
        Test.startTest();
        System.enqueueJob(new ProductSyncRetryQueueable());
        Test.stopTest();
        Assert.areEqual(0, [SELECT Id FROM Product_Sync_Queue__c].size());
    }

    @IsTest
    static void testRetryThirdFailureSendsEmail() {
        Product2 product = [
            SELECT Id
            FROM Product2
            WHERE ProductCode = 'RET-EMAIL'
        ];

        Product_Sync_Queue__c queueRecord = TestDataFactory.queueRecord()
            .forProduct(product.Id)
            .withAttempts(2).create();

        Test.setMock(HttpCalloutMock.class, TestDataFactory.httpError());
        Test.startTest();
        System.enqueueJob(new ProductSyncRetryQueueable());
        Test.stopTest();

        Product_Sync_Queue__c result = [
            SELECT Status__c, Attempt_Count__c
            FROM  Product_Sync_Queue__c 
            WHERE Id = :queueRecord.Id
        ];
        Assert.areEqual(Utils.PRODUCT_SYNC.STATUS.FAILED, result.Status__c);
        Assert.areEqual(3, result.Attempt_Count__c, 'Should be at MAX_ATTEMPTS after 3rd failure');
        Assert.areEqual(1, Limits.getEmailInvocations(), 'Email should be sent on 3rd failure');
    }

    @IsTest
    static void testRetrySecondFailureDoesNotSendEmail() {
        Product2 product = [
            SELECT Id 
            FROM Product2 
            WHERE ProductCode = 'RET-EMAIL'
        ];
        
        TestDataFactory.queueRecord().forProduct(product.Id).withAttempts(1).create();

        Test.setMock(HttpCalloutMock.class, TestDataFactory.httpError());
        Test.startTest();
        System.enqueueJob(new ProductSyncRetryQueueable());
        Test.stopTest();

        Assert.areEqual(0, Limits.getEmailInvocations(), 'Email should NOT be sent before 3rd failure');
    }
}
