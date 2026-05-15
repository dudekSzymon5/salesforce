@IsTest
private class ProductSyncAfterUpdateTest {

    @TestSetup
    static void makeData(){
        TriggerBase.bypass('Product2');

        TestDataFactory.product().withCode('TP-01').create();
        TestDataFactory.product().withCode('EP-01').external().create();
        TriggerBase.clearBypass('Product2');
    }

    @IsTest
    static void testAfterUpdateSyncsNonExternalProducts() {
        
        List<Product2> products = [SELECT Id, Name, ProductCode, Is_External__c FROM Product2 WHERE ProductCode = 'TP-01'];

        Test.setMock(HttpCalloutMock.class, TestDataFactory.httpSuccess());
        Test.startTest();
        new ProductSyncAfterUpdate().afterUpdate(products, products);
        Test.stopTest();

        Assert.areEqual(1, [SELECT Id FROM AsyncApexJob WHERE JobType = 'Queueable' AND ApexClass.Name = 'ProductSyncQueueable' AND CreatedDate = TODAY].size());
        Assert.areEqual(0, [SELECT Id FROM Product_Sync_Queue__c WHERE Status__c = :Utils.PRODUCT_SYNC.STATUS.FAILED].size());
    }

    @IsTest
    static void testAfterUpdateSyncsNonExternalProductsServerErrorAddsToQueue() {

        List<Product2> products = [SELECT Id, Name, ProductCode, Is_External__c FROM Product2 WHERE ProductCode = 'TP-01'];

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
       
        List<Product2> products = [SELECT Id, Name, ProductCode, Is_External__c FROM Product2 WHERE ProductCode = 'EP-01'];
        
        Test.startTest();
        new ProductSyncAfterUpdate().afterUpdate(products, products);
        Test.stopTest();

        Assert.areEqual(0, [SELECT Id FROM AsyncApexJob WHERE JobType = 'Queueable' AND ApexClass.Name = 'ProductSyncQueueable' AND CreatedDate = TODAY].size());
    }
}