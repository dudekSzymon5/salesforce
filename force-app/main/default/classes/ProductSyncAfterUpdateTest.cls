@IsTest
private class ProductSyncAfterUpdateTest {

    @IsTest
    static void testAfterUpdateSyncsNonExternalProducts() {
        List<Product2> products = new List<Product2>{
            new Product2(Name = 'Test Product', ProductCode = 'TP-001', Is_External__c = false)
        };

        Test.startTest();
        ProductSyncAfterUpdate action = new ProductSyncAfterUpdate();
        action.afterUpdate(products, products);
        Test.stopTest();

        System.assertEquals(1, [SELECT Id FROM AsyncApexJob WHERE JobType = 'Queueable'].size());
    }

    @IsTest
    static void testAfterUpdateSkipsExternalProducts() {
        List<Product2> products = new List<Product2>{
            new Product2(Name = 'External Product', ProductCode = 'EP-001', Is_External__c = true)
        };

        Test.startTest();
        ProductSyncAfterUpdate action = new ProductSyncAfterUpdate();
        action.afterUpdate(products, products);
        Test.stopTest();

        System.assertEquals(0, [SELECT Id FROM AsyncApexJob WHERE JobType = 'Queueable'].size());
    }
}