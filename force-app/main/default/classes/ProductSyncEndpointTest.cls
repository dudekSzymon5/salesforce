@IsTest
private class ProductSyncEndpointTest {

    @TestSetup
    static void makeData() {
        TriggerBase.bypass('Product2');
        
        TestDataFactory.product().withCode('EXT-PC-01').external('EXT-001', Utils.TEST.PRODUCT.DEFAULT_ORG_ID).create();
        TestDataFactory.product().withCode('EXT-DEL-01').external('EXT-DEL-001', Utils.TEST.PRODUCT.DEFAULT_ORG_ID).create();
        TestDataFactory.product().withCode('EXT-COUNT-01').external('EXT-COUNT-001', Utils.TEST.PRODUCT.DEFAULT_ORG_ID).create();
        TriggerBase.clearBypass('Product2');
    }

    @IsTest
    static void testUpsertProductInsertCreatesProduct() {
        String externalId = 'EXT-NEW-001';
        TestDataFactory.setupRestPost(
            '/services/apexrest/v1/products/',
            TestDataFactory.buildProductPayload(externalId, Utils.TEST.PRODUCT.DEFAULT_ORG_ID, 'New External Product')
        );

        Test.startTest();
        ProductSyncEndpoint.upsertProduct();
        Test.stopTest();

        Assert.areEqual(200, RestContext.response.statusCode);
        Product2 created = [SELECT Name, Is_External__c, Sync_Count__c FROM Product2 WHERE External_Product_Id__c = :externalId LIMIT 1];
        Assert.areEqual('New External Product', created.Name);
        Assert.isTrue(created.Is_External__c);
        Assert.areEqual(1, created.Sync_Count__c, 'Sync_Count should be 1 after first sync');
    }

    @IsTest
    static void testUpsertProductUpdateModifiesExistingProduct() {
        TestDataFactory.setupRestPost(
            '/services/apexrest/v1/products/',
            TestDataFactory.buildProductPayload('EXT-001', Utils.TEST.PRODUCT.DEFAULT_ORG_ID, 'Updated Product')
        );

        Test.startTest();
        ProductSyncEndpoint.upsertProduct();
        Test.stopTest();

        Assert.areEqual(200, RestContext.response.statusCode);
        Product2 updated = [SELECT Name FROM Product2 WHERE External_Product_Id__c = 'EXT-001' LIMIT 1];
        Assert.areEqual('Updated Product', updated.Name);
    }

    @IsTest
    static void testUpsertProductInvalidJsonReturns500() {
        TestDataFactory.setupRestPost('/services/apexrest/v1/products/', 'NOT_VALID_JSON{{{{');

        Test.startTest();
        ProductSyncEndpoint.upsertProduct();
        Test.stopTest();

        Assert.areEqual(500, RestContext.response.statusCode);
        Assert.isTrue(RestContext.response.responseBody.toString().contains('error'));
    }

    @IsTest
    static void testSoftDeleteFoundMarksProductDeleted() {
        TestDataFactory.setupRestDelete('/services/apexrest/v1/products/EXT-DEL-001');

        Test.startTest();
        ProductSyncEndpoint.softDeleteProduct();
        Test.stopTest();

        Assert.areEqual(200, RestContext.response.statusCode);
        Product2 deleted = [SELECT Is_Deleted__c FROM Product2 WHERE External_Product_Id__c = 'EXT-DEL-001' LIMIT 1];
        Assert.isTrue(deleted.Is_Deleted__c);
    }

    @IsTest
    static void testSoftDeleteNotFoundReturns200Gracefully() {
        TestDataFactory.setupRestDelete('/services/apexrest/v1/products/NON-EXISTENT-XYZ');

        Test.startTest();
        ProductSyncEndpoint.softDeleteProduct();
        Test.stopTest();

        Assert.areEqual(200, RestContext.response.statusCode);
    }

    @IsTest
    static void testSoftDeleteIncrementsSyncCount() {
        TestDataFactory.setupRestDelete('/services/apexrest/v1/products/EXT-COUNT-001');

        Test.startTest();
        ProductSyncEndpoint.softDeleteProduct();
        Test.stopTest();

        Product2 updated = [SELECT Sync_Count__c FROM Product2 WHERE External_Product_Id__c = 'EXT-COUNT-001'];
        Assert.areEqual(1, updated.Sync_Count__c, 'Sync_Count should increment after DELETE');
    }
}
