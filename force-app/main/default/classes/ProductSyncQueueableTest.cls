@IsTest
private class ProductSyncQueueableTest {

    @TestSetup
    static void makeData() {
        TriggerBase.bypass('Product2');
        
        TestDataFactory.product().withCode('TP-01').create();
        TestDataFactory.product().withCode('TP-02').create();
        TestDataFactory.product().withCode('TP-03').create();
        TestDataFactory.product().withCode('TP-04').create();
        TriggerBase.clearBypass('Product2');
    }

    @IsTest
    static void testExecuteInsertSuccessNoQueueEntry() {
        Product2 product = [SELECT Id, Name, ProductCode, Family, Description, Language__c FROM Product2 WHERE ProductCode = 'TP-01'];

        Test.setMock(HttpCalloutMock.class, TestDataFactory.httpSuccess());
        Test.startTest();
        System.enqueueJob(new ProductSyncQueueable(new List<Product2>{ product }, Utils.PRODUCT_SYNC.OPERATION.INSERT_OP));
        Test.stopTest();

        Assert.areEqual(0, [SELECT Id FROM Product_Sync_Queue__c WHERE Product__c = :product.Id AND Status__c = :Utils.PRODUCT_SYNC.STATUS.FAILED].size());
    }

    @IsTest
    static void testExecuteInsertServerErrorAddsToQueue() {
        Product2 product = [SELECT Id, Name, ProductCode, Family, Description, Language__c FROM Product2 WHERE ProductCode = 'TP-02'];

        Test.setMock(HttpCalloutMock.class, TestDataFactory.httpError());
        Test.startTest();
        System.enqueueJob(new ProductSyncQueueable(new List<Product2>{ product }, Utils.PRODUCT_SYNC.OPERATION.INSERT_OP));
        Test.stopTest();

        List<Product_Sync_Queue__c> queue = [SELECT Status__c, Attempt_Count__c FROM Product_Sync_Queue__c WHERE Product__c = :product.Id];
        Assert.areEqual(1, queue.size());
        Assert.areEqual(Utils.PRODUCT_SYNC.STATUS.FAILED, queue[0].Status__c);
        Assert.areEqual(1, queue[0].Attempt_Count__c);
    }

    @IsTest
    static void testExecuteDeleteSuccessNoQueueEntry() {
        Product2 product = [SELECT Id, Name, ProductCode, Family, Description, Language__c FROM Product2 WHERE ProductCode = 'TP-03'];

        Test.setMock(HttpCalloutMock.class, TestDataFactory.httpSuccess());
        Test.startTest();
        System.enqueueJob(new ProductSyncQueueable(new List<Product2>{ product }, Utils.PRODUCT_SYNC.OPERATION.DELETE_OP));
        Test.stopTest();

        Assert.areEqual(0, [SELECT Id FROM Product_Sync_Queue__c WHERE Operation__c = :Utils.PRODUCT_SYNC.OPERATION.DELETE_OP AND Status__c = :Utils.PRODUCT_SYNC.STATUS.FAILED].size());
    }

    @IsTest
    static void testExecuteDeleteServerErrorAddsToQueue() {
        Product2 product = [SELECT Id, Name, ProductCode, Family, Description, Language__c FROM Product2 WHERE ProductCode = 'TP-04'];

        Test.setMock(HttpCalloutMock.class, TestDataFactory.httpError());
        Test.startTest();
        System.enqueueJob(new ProductSyncQueueable(new List<Product2>{ product }, Utils.PRODUCT_SYNC.OPERATION.DELETE_OP));
        Test.stopTest();

        List<Product_Sync_Queue__c> queue = [SELECT Status__c FROM Product_Sync_Queue__c WHERE Operation__c = :Utils.PRODUCT_SYNC.OPERATION.DELETE_OP];
        Assert.areEqual(1, queue.size());
        Assert.areEqual(Utils.PRODUCT_SYNC.STATUS.FAILED, queue[0].Status__c);
    }
}
