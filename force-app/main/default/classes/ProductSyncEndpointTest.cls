@IsTest
private class ProductSyncEndpointTest {

    @IsTest
    static void testUpsertProduct_insert_createsProduct() {
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
    static void testUpsertProduct_update_modifiesExistingProduct() {
        TriggerBase.bypass('Product2');
        TestDataFactory.aProduct()
            .withCode('EXT-PC-001')
            .external('EXT-001', Utils.TEST.PRODUCT.DEFAULT_ORG_ID)
            .create();
        TriggerBase.clearBypass('Product2');

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
    static void testUpsertProduct_invalidJson_returns500() {
        TestDataFactory.setupRestPost('/services/apexrest/v1/products/', 'NOT_VALID_JSON{{{{');

        Test.startTest();
        ProductSyncEndpoint.upsertProduct();
        Test.stopTest();

        Assert.areEqual(500, RestContext.response.statusCode);
        Assert.isTrue(RestContext.response.responseBody.toString().contains('error'));
    }

    @IsTest
    static void testSoftDelete_found_marksProductDeleted() {
        TriggerBase.bypass('Product2');
        TestDataFactory.aProduct()
            .withCode('EXT-PC-DEL')
            .external('EXT-DEL-001', Utils.TEST.PRODUCT.DEFAULT_ORG_ID)
            .create();
        TriggerBase.clearBypass('Product2');

        TestDataFactory.setupRestDelete('/services/apexrest/v1/products/EXT-DEL-001');

        Test.startTest();
        ProductSyncEndpoint.softDeleteProduct();
        Test.stopTest();

        Assert.areEqual(200, RestContext.response.statusCode);
        Product2 deleted = [SELECT Is_Deleted__c FROM Product2 WHERE External_Product_Id__c = 'EXT-DEL-001' LIMIT 1];
        Assert.isTrue(deleted.Is_Deleted__c);
    }

    @IsTest
    static void testSoftDelete_notFound_returns200Gracefully() {
        TestDataFactory.setupRestDelete('/services/apexrest/v1/products/NON-EXISTENT-XYZ');

        Test.startTest();
        ProductSyncEndpoint.softDeleteProduct();
        Test.stopTest();

        Assert.areEqual(200, RestContext.response.statusCode);
    }

    @IsTest
    static void testSoftDelete_incrementsSyncCount() {
        TriggerBase.bypass('Product2');
        Product2 product = TestDataFactory.aProduct()
            .withCode('EXT-PC-CNT')
            .external('EXT-COUNT-001', Utils.TEST.PRODUCT.DEFAULT_ORG_ID)
            .create();
        TriggerBase.clearBypass('Product2');

        TestDataFactory.setupRestDelete('/services/apexrest/v1/products/EXT-COUNT-001');

        Test.startTest();
        ProductSyncEndpoint.softDeleteProduct();
        Test.stopTest();

        Product2 updated = [SELECT Sync_Count__c FROM Product2 WHERE Id = :product.Id];
        Assert.areEqual(1, updated.Sync_Count__c, 'Sync_Count should increment after DELETE');
    }
}
