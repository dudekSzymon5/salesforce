@IsTest
private class ProductSyncAfterInsertTest {

    @IsTest
    static void testAfterInsertSyncsNonExternalProducts() {
        List<Product2> products = new List<Product2>{
            new Product2(Name = 'Test Product 1', ProductCode = 'TP-001', Is_External__c = false),
            new Product2(Name = 'Test Product 2', ProductCode = 'TP-002', Is_External__c = false)
        };

        Test.startTest();
        ProductSyncAfterInsert action = new ProductSyncAfterInsert();
        action.afterInsert(products);
        Test.stopTest();

        System.assertEquals(1, [SELECT Id FROM AsyncApexJob WHERE JobType = 'Queueable'].size());
    }

    @IsTest
    static void testAfterInsertSkipsExternalProducts() {
        List<Product2> products = new List<Product2>{
            new Product2(Name = 'External Product', ProductCode = 'EP-001', Is_External__c = true)
        };

        Test.startTest();
        ProductSyncAfterInsert action = new ProductSyncAfterInsert();
        action.afterInsert(products);
        Test.stopTest();

        System.assertEquals(0, [SELECT Id FROM AsyncApexJob WHERE JobType = 'Queueable'].size());
    }
}