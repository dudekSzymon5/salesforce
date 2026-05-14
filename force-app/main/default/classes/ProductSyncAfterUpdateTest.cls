@IsTest
private class ProductSyncAfterUpdateTest {

    @IsTest
    static void testAfterUpdateSyncsNonExternalProducts() {
        TriggerBase.bypass('Product2');
        List<Product2> products = new List<Product2>{
            TestDataFactory.aProduct().withCode('TP-001').build()
        };
        insert products;
        TriggerBase.clearBypass('Product2');

        Test.setMock(HttpCalloutMock.class, TestDataFactory.httpSuccess());
        Test.startTest();
        new ProductSyncAfterUpdate().afterUpdate(products, products);
        Test.stopTest();

        Assert.areEqual(1, [SELECT Id FROM AsyncApexJob WHERE JobType = 'Queueable' AND ApexClass.Name = 'ProductSyncQueueable' AND CreatedDate = TODAY].size());
        Assert.areEqual(0, [SELECT Id FROM Product_Sync_Queue__c WHERE Status__c = :Utils.PRODUCT_SYNC.STATUS.FAILED].size());
    }

    @IsTest
    static void testAfterUpdateSyncsNonExternalProductsServerErrorAddsToQueue() {
        TriggerBase.bypass('Product2');
        List<Product2> products = new List<Product2>{
            TestDataFactory.aProduct().withCode('TP-001').build()
        };
        insert products;
        TriggerBase.clearBypass('Product2');

        Test.setMock(HttpCalloutMock.class, TestDataFactory.httpError());
        Test.startTest();
        new ProductSyncAfterUpdate().afterUpdate(products, products);
        Test.stopTest();

        List<Product_Sync_Queue__c> queue = [SELECT Status__c, Operation__c FROM Product_Sync_Queue__c];
        Assert.areEqual(1, queue.size());
        Assert.areEqual(Utils.PRODUCT_SYNC.STATUS.FAILED, queue[0].Status__c);
        Assert.areEqual(Utils.PRODUCT_SYNC.OPERATION.UPDATE_OP, queue[0].Operation__c);
    }

    @IsTest
    static void testAfterUpdateSkipsExternalProducts() {
        TriggerBase.bypass('Product2');
        List<Product2> products = new List<Product2>{
            TestDataFactory.aProduct().withCode('EP-001').external().build()
        };
        insert products;
        TriggerBase.clearBypass('Product2');

        Test.startTest();
        new ProductSyncAfterUpdate().afterUpdate(products, products);
        Test.stopTest();

        Assert.areEqual(0, [SELECT Id FROM AsyncApexJob WHERE JobType = 'Queueable' AND ApexClass.Name = 'ProductSyncQueueable' AND CreatedDate = TODAY].size());
    }
}