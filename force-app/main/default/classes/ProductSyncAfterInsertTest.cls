@IsTest
private class ProductSyncAfterInsertTest {

    @IsTest
    static void testAfterInsertSyncsNonExternalProducts() {
        TriggerBase.bypass('Product2');
        // Tworzę dwa produkty wewnątrz, a nie zewnątrz bo potrzebuje produktów żeby je
        // przekazać do afterInsert(products).create() tworzy jeden rekord na raz build()
        List<Product2> products = new List<Product2>{
            TestDataFactory.aProduct().withCode('TP-001').build(),
            TestDataFactory.aProduct().withCode('TP-002').build()
        };
        insert products;
        TriggerBase.clearBypass('Product2');

        Test.setMock(HttpCalloutMock.class, TestDataFactory.httpSuccess());
        Test.startTest();
        new ProductSyncAfterInsert().afterInsert(products);
        Test.stopTest();
        // Sprawdzam czy job został dodany do kolejki Salesforce i że nie jest w kolejce błedów
        Assert.areEqual(1, [SELECT Id FROM AsyncApexJob WHERE JobType = 'Queueable' AND ApexClass.Name = 'ProductSyncQueueable' AND CreatedDate = TODAY].size());
        Assert.areEqual(0, [SELECT Id FROM Product_Sync_Queue__c WHERE Status__c = :Utils.PRODUCT_SYNC.STATUS.FAILED].size());
    }

    @IsTest
    static void testAfterInsertSyncsNonExternalProductsServerErrorAddsToQueue() {
        TriggerBase.bypass('Product2');
        List<Product2> products = new List<Product2>{
            TestDataFactory.aProduct().withCode('TP-001').build()
        };
        insert products;
        TriggerBase.clearBypass('Product2');

        Test.setMock(HttpCalloutMock.class, TestDataFactory.httpError());
        Test.startTest();
        new ProductSyncAfterInsert().afterInsert(products);
        Test.stopTest();

        List<Product_Sync_Queue__c> queue = [SELECT Status__c, Operation__c FROM Product_Sync_Queue__c];
        // Produkt trafił do kolejki błędów z operacją INSERT
        Assert.areEqual(1, queue.size());
        Assert.areEqual(Utils.PRODUCT_SYNC.STATUS.FAILED, queue[0].Status__c);
        Assert.areEqual(Utils.PRODUCT_SYNC.OPERATION.INSERT_OP, queue[0].Operation__c);
    }

    @IsTest
    static void testAfterInsertSkipsExternalProducts() {
        // Produkt zewnętrzny — przyszedł z innego systemu, nie wysyłamy go z powrotem
        TriggerBase.bypass('Product2');
        List<Product2> products = new List<Product2>{
            TestDataFactory.aProduct().withCode('EP-001').external().build()
        };
        insert products;
        TriggerBase.clearBypass('Product2');

        Test.startTest();
        new ProductSyncAfterInsert().afterInsert(products);
        Test.stopTest();
        // Żaden job nie został dodany do kolejki
        Assert.areEqual(0, [SELECT Id FROM AsyncApexJob WHERE JobType = 'Queueable' AND ApexClass.Name = 'ProductSyncQueueable' AND CreatedDate = TODAY].size());
    }
}