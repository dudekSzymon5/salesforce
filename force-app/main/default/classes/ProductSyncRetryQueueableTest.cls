@IsTest
private class ProductSyncRetryQueueableTest {

    @IsTest
    static void testRetryInsert_success_marksSuccessAndRefreshesPayload() {
        Product2 product = TestDataFactory.aProduct().withCode('RET-001').create();
        Product_Sync_Queue__c queueRecord = TestDataFactory.aQueueRecord()
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
    static void testRetryInsert_serverError_remainsFailed() {
        Product2 product = TestDataFactory.aProduct().withCode('RET-002').create();
        Product_Sync_Queue__c queueRecord = TestDataFactory.aQueueRecord().forProduct(product.Id).create();

        Test.setMock(HttpCalloutMock.class, TestDataFactory.httpError());
        Test.startTest();
        System.enqueueJob(new ProductSyncRetryQueueable());
        Test.stopTest();

        Product_Sync_Queue__c result = [SELECT Status__c, Attempt_Count__c FROM Product_Sync_Queue__c WHERE Id = :queueRecord.Id];
        Assert.areEqual(Utils.PRODUCT_SYNC.STATUS.FAILED, result.Status__c);
        Assert.areEqual(2, result.Attempt_Count__c);
    }

    @IsTest
    static void testRetryInsert_productDeleted_skipsCalloutAndMarksSuccess() {
        TriggerBase.bypass('ProductTrigger');
        Product2 product = TestDataFactory.aProduct().withCode('DEL-001').create();
        TriggerBase.clearBypass('ProductTrigger');
        Product_Sync_Queue__c queueRecord = TestDataFactory.aQueueRecord().forProduct(product.Id).create();

        TriggerBase.bypass('ProductTrigger');
        delete product;
        TriggerBase.clearBypass('ProductTrigger');

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
    static void testRetryDelete_success_marksSuccess() {
        Product_Sync_Queue__c queueRecord = TestDataFactory.aQueueRecord()
            .asDelete('EXT-PROD-001')
            .create();

        Test.setMock(HttpCalloutMock.class, TestDataFactory.httpSuccess('{"status":"deleted"}'));
        Test.startTest();
        System.enqueueJob(new ProductSyncRetryQueueable());
        Test.stopTest();

        Product_Sync_Queue__c result = [SELECT Status__c, Attempt_Count__c FROM Product_Sync_Queue__c WHERE Id = :queueRecord.Id];
        Assert.areEqual(Utils.PRODUCT_SYNC.STATUS.SUCCESS, result.Status__c);
        Assert.areEqual(2, result.Attempt_Count__c);
    }

    @IsTest
    static void testRetry_maxAttemptsReached_recordNotProcessed() {
        Product2 product = TestDataFactory.aProduct().withCode('RET-MAX').create();
        Product_Sync_Queue__c queueRecord = TestDataFactory.aQueueRecord()
            .forProduct(product.Id)
            .withAttempts(3)
            .create();

        Test.setMock(HttpCalloutMock.class, TestDataFactory.httpSuccess());
        Test.startTest();
        System.enqueueJob(new ProductSyncRetryQueueable());
        Test.stopTest();

        Product_Sync_Queue__c result = [SELECT Status__c, Attempt_Count__c FROM Product_Sync_Queue__c WHERE Id = :queueRecord.Id];
        Assert.areEqual(Utils.PRODUCT_SYNC.STATUS.FAILED, result.Status__c, 'Record at MAX_ATTEMPTS should not be retried');
        Assert.areEqual(3, result.Attempt_Count__c, 'Attempt_Count should not change');
    }

    @IsTest
    static void testRetry_emptyQueue_completesWithoutError() {
        Test.startTest();
        System.enqueueJob(new ProductSyncRetryQueueable());
        Test.stopTest();

        Assert.areEqual(0, [SELECT Id FROM Product_Sync_Queue__c].size());
    }
}
