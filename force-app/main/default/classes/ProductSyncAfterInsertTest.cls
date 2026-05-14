@IsTest
private class ProductSyncAfterInsertTest {

    @IsTest
    static void testAfterInsertSyncsNonExternalProducts() {
        TriggerBase.bypass('ProductTrigger');
        List<Product2> products = new List<Product2>{
            TestDataFactory.aProduct().withCode('TP-001').build(),
            TestDataFactory.aProduct().withCode('TP-002').build()
        };
        insert products;
        TriggerBase.clearBypass('ProductTrigger');

        Test.setMock(HttpCalloutMock.class, TestDataFactory.httpSuccess());
        Test.startTest();
        new ProductSyncAfterInsert().afterInsert(products);
        Test.stopTest();

        Assert.areEqual(1, [SELECT Id FROM AsyncApexJob WHERE JobType = 'Queueable' AND ApexClass.Name = 'ProductSyncQueueable'].size());
        Assert.areEqual(0, [SELECT Id FROM Product_Sync_Queue__c WHERE Status__c = :Utils.PRODUCT_SYNC.STATUS.FAILED].size());
    }

    @IsTest
    static void testAfterInsertSyncsNonExternalProducts_serverError_addsToQueue() {
        TriggerBase.bypass('ProductTrigger');
        List<Product2> products = new List<Product2>{
            TestDataFactory.aProduct().withCode('TP-001').build()
        };
        insert products;
        TriggerBase.clearBypass('ProductTrigger');

        Test.setMock(HttpCalloutMock.class, TestDataFactory.httpError());
        Test.startTest();
        new ProductSyncAfterInsert().afterInsert(products);
        Test.stopTest();

        List<Product_Sync_Queue__c> queue = [SELECT Status__c, Operation__c FROM Product_Sync_Queue__c];
        Assert.areEqual(1, queue.size());
        Assert.areEqual(Utils.PRODUCT_SYNC.STATUS.FAILED, queue[0].Status__c);
        Assert.areEqual(Utils.PRODUCT_SYNC.OPERATION.INSERT_OP, queue[0].Operation__c);
    }

    @IsTest
    static void testAfterInsertSkipsExternalProducts() {
        TriggerBase.bypass('ProductTrigger');
        List<Product2> products = new List<Product2>{
            TestDataFactory.aProduct().withCode('EP-001').external().build()
        };
        insert products;
        TriggerBase.clearBypass('ProductTrigger');

        Test.startTest();
        new ProductSyncAfterInsert().afterInsert(products);
        Test.stopTest();

        Assert.areEqual(0, [SELECT Id FROM AsyncApexJob WHERE JobType = 'Queueable' AND ApexClass.Name = 'ProductSyncQueueable'].size());
    }
}