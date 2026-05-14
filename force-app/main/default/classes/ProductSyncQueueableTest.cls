@IsTest
private class ProductSyncQueueableTest {

    @IsTest
    static void testExecuteInsertSuccessNoQueueEntry() {
        // Callout się udał
        TriggerBase.bypass('Product2');
        Product2 product = TestDataFactory.aProduct().withCode('TP-001').create();
        TriggerBase.clearBypass('Product2');
        product = [SELECT Id, Name, ProductCode, Family, Description, Language__c FROM Product2 WHERE Id = :product.Id];

        Test.setMock(HttpCalloutMock.class, TestDataFactory.httpSuccess());
        Test.startTest();
        System.enqueueJob(new ProductSyncQueueable(new List<Product2>{ product }, Utils.PRODUCT_SYNC.OPERATION.INSERT_OP));
        Test.stopTest();
        // HTTP 200 = sukces = nic nie trafia do kolejki błędów
        Assert.areEqual(0, [SELECT Id FROM Product_Sync_Queue__c WHERE Product__c = :product.Id AND Status__c = :Utils.PRODUCT_SYNC.STATUS.FAILED].size());
    }

    @IsTest
    static void testExecuteInsertServerErrorAddsToQueue() {
        // Callout się wyjebał
        TriggerBase.bypass('Product2');
        Product2 product = TestDataFactory.aProduct().withCode('TP-002').create();
        TriggerBase.clearBypass('Product2');
        product = [SELECT Id, Name, ProductCode, Family, Description, Language__c FROM Product2 WHERE Id = :product.Id];

        Test.setMock(HttpCalloutMock.class, TestDataFactory.httpError());
        Test.startTest();
        System.enqueueJob(new ProductSyncQueueable(new List<Product2>{ product }, Utils.PRODUCT_SYNC.OPERATION.INSERT_OP));
        Test.stopTest();

        List<Product_Sync_Queue__c> queue = [SELECT Status__c, Attempt_Count__c FROM Product_Sync_Queue__c WHERE Product__c = :product.Id];
        // Produkt trafił do kolejki błędów
        Assert.areEqual(1, queue.size());
        Assert.areEqual(Utils.PRODUCT_SYNC.STATUS.FAILED, queue[0].Status__c);
        Assert.areEqual(1, queue[0].Attempt_Count__c);
    }

    @IsTest
    static void testExecuteDeleteSuccessNoQueueEntry() {
        // DELETE - callout się udał
        TriggerBase.bypass('Product2');
        Product2 product = TestDataFactory.aProduct().withCode('TP-003').create();
        TriggerBase.clearBypass('Product2');

        Test.setMock(HttpCalloutMock.class, TestDataFactory.httpSuccess());
        Test.startTest();
        System.enqueueJob(new ProductSyncQueueable(new List<Product2>{ product }, Utils.PRODUCT_SYNC.OPERATION.DELETE_OP));
        Test.stopTest();
        // HTTP 200 = sukces = nic nie trafia do kolejki błędów
        Assert.areEqual(0, [SELECT Id FROM Product_Sync_Queue__c WHERE Operation__c = :Utils.PRODUCT_SYNC.OPERATION.DELETE_OP AND Status__c = :Utils.PRODUCT_SYNC.STATUS.FAILED].size());
    }

    @IsTest
    static void testExecuteDeleteServerErrorAddsToQueue() {
        // DELETE - callout się wyjebał
        TriggerBase.bypass('Product2');
        Product2 product = TestDataFactory.aProduct().withCode('TP-004').create();
        TriggerBase.clearBypass('Product2');

        Test.setMock(HttpCalloutMock.class, TestDataFactory.httpError());
        Test.startTest();
        System.enqueueJob(new ProductSyncQueueable(new List<Product2>{ product }, Utils.PRODUCT_SYNC.OPERATION.DELETE_OP));
        Test.stopTest();

        List<Product_Sync_Queue__c> queue = [SELECT Status__c FROM Product_Sync_Queue__c WHERE Operation__c = :Utils.PRODUCT_SYNC.OPERATION.DELETE_OP];
        // DELETE się wyjebał i trafił do kolejki błędów
        Assert.areEqual(1, queue.size());
        Assert.areEqual(Utils.PRODUCT_SYNC.STATUS.FAILED, queue[0].Status__c);
    }
}