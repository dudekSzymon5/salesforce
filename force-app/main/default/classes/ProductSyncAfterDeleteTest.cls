@IsTest
private class ProductSyncAfterDeleteTest {

    @IsTest
    static void testAfterDeleteSyncsNonExternalProducts() {
        TriggerBase.bypass('Product2');
        Product2 product = TestDataFactory.aProduct().withCode('TP-001').create();
        TriggerBase.clearBypass('Product2');

        Test.setMock(HttpCalloutMock.class, TestDataFactory.httpSuccess());
        Test.startTest();
        new ProductSyncAfterDelete().afterDelete(new List<Product2>{ product });
        Test.stopTest();

        Assert.areEqual(1, [SELECT Id FROM AsyncApexJob WHERE JobType = 'Queueable' AND ApexClass.Name = 'ProductSyncQueueable' AND CreatedDate = TODAY].size());
        Assert.areEqual(0, [SELECT Id FROM Product_Sync_Queue__c WHERE Status__c = :Utils.PRODUCT_SYNC.STATUS.FAILED].size());
    }

    @IsTest
    static void testAfterDeleteSyncsNonExternalProducts_serverError_addsToQueue() {
        TriggerBase.bypass('Product2');
        Product2 product = TestDataFactory.aProduct().withCode('TP-001').create();
        TriggerBase.clearBypass('Product2');

        Test.setMock(HttpCalloutMock.class, TestDataFactory.httpError());
        Test.startTest();
        new ProductSyncAfterDelete().afterDelete(new List<Product2>{ product });
        Test.stopTest();

        List<Product_Sync_Queue__c> queue = [SELECT Status__c, Operation__c FROM Product_Sync_Queue__c];
        Assert.areEqual(1, queue.size());
        Assert.areEqual(Utils.PRODUCT_SYNC.STATUS.FAILED, queue[0].Status__c);
        Assert.areEqual(Utils.PRODUCT_SYNC.OPERATION.DELETE_OP, queue[0].Operation__c);
    }

    @IsTest
    static void testAfterDeleteSkipsExternalProducts() {
        TriggerBase.bypass('Product2');
        Product2 product = TestDataFactory.aProduct().withCode('EP-001').external().create();
        TriggerBase.clearBypass('Product2');

        Test.startTest();
        new ProductSyncAfterDelete().afterDelete(new List<Product2>{ product });
        Test.stopTest();

        Assert.areEqual(0, [SELECT Id FROM AsyncApexJob WHERE JobType = 'Queueable' AND ApexClass.Name = 'ProductSyncQueueable' AND CreatedDate = TODAY].size());
    }
}