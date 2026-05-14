@IsTest
private class ProductSyncEndpointTest {

    @IsTest
    static void testUpsertProductInsertCreatesProduct() {
        String externalId = 'EXT-NEW-001';
        // Wysyłam POST z nowym produktem
        TestDataFactory.setupRestPost(
            '/services/apexrest/v1/products/',
            TestDataFactory.buildProductPayload(externalId, Utils.TEST.PRODUCT.DEFAULT_ORG_ID, 'New External Product')
        );

        Test.startTest();
        ProductSyncEndpoint.upsertProduct(); // wywołuje sobie endpoint
        Test.stopTest();
        // No i sprawdzam sobie czy rekord trafił do bazy
        Assert.areEqual(200, RestContext.response.statusCode);

        Product2 created = [SELECT Name, Is_External__c, Sync_Count__c FROM Product2 WHERE External_Product_Id__c = :externalId LIMIT 1];
        Assert.areEqual('New External Product', created.Name);
        Assert.isTrue(created.Is_External__c);
        Assert.areEqual(1, created.Sync_Count__c, 'Sync_Count should be 1 after first sync');
    }

    @IsTest
    static void testUpsertProductUpdateModifiesExistingProduct() {
        TriggerBase.bypass('Product2');
        TestDataFactory.aProduct()
            .withCode('EXT-PC-001')
            .external('EXT-001', Utils.TEST.PRODUCT.DEFAULT_ORG_ID)
            .create(); //Tworzę sobie produkt w bazie
        TriggerBase.clearBypass('Product2');
        //Potem sprawdzam, że przyszła aktualizacja
        TestDataFactory.setupRestPost(
            '/services/apexrest/v1/products/',
            TestDataFactory.buildProductPayload('EXT-001', Utils.TEST.PRODUCT.DEFAULT_ORG_ID, 'Updated Product')
        );

        Test.startTest();
        ProductSyncEndpoint.upsertProduct();
        Test.stopTest();
        // Sprawdzam czy nazwa się zmieniła
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
        // Endpoint powinnien zwrócić 500
        Assert.areEqual(500, RestContext.response.statusCode);
        Assert.isTrue(RestContext.response.responseBody.toString().contains('error'));
    }

    @IsTest
    static void testSoftDeleteFoundMarksProductDeleted() {
        TriggerBase.bypass('Product2');
        TestDataFactory.aProduct()
            .withCode('EXT-PC-DEL')
            .external('EXT-DEL-001', Utils.TEST.PRODUCT.DEFAULT_ORG_ID)
            .create();
        TriggerBase.clearBypass('Product2');
        // Symuluje, że ktos wysłał DELETE dla produktu EXT-DEL-001
        TestDataFactory.setupRestDelete('/services/apexrest/v1/products/EXT-DEL-001');

        Test.startTest();
        ProductSyncEndpoint.softDeleteProduct();
        Test.stopTest();

        // Produkt nie znika z bazy — tylko dostaje flagę Is_Deleted__c = true
        Assert.areEqual(200, RestContext.response.statusCode);
        Product2 deleted = [SELECT Is_Deleted__c FROM Product2 WHERE External_Product_Id__c = 'EXT-DEL-001' LIMIT 1];
        Assert.isTrue(deleted.Is_Deleted__c);
    }

    @IsTest
    static void testSoftDeleteNotFoundReturns200Gracefully() {
        // Symuluje, że produkt nie istnieje w bazie, przeszedł DELETE
        TestDataFactory.setupRestDelete('/services/apexrest/v1/products/NON-EXISTENT-XYZ');

        Test.startTest();
        ProductSyncEndpoint.softDeleteProduct();
        Test.stopTest();
        // Endpoint nie powinien się wysypać - zwraca 200 i idzie dalej
        Assert.areEqual(200, RestContext.response.statusCode);
    }

    @IsTest
    static void testSoftDeleteIncrementsSyncCount() {
        TriggerBase.bypass('Product2');
        // Tworze produkt
        Product2 product = TestDataFactory.aProduct()
            .withCode('EXT-PC-CNT')
            .external('EXT-COUNT-001', Utils.TEST.PRODUCT.DEFAULT_ORG_ID)
            .create();
        TriggerBase.clearBypass('Product2');
        // Wysyłam DELETE
        TestDataFactory.setupRestDelete('/services/apexrest/v1/products/EXT-COUNT-001');

        Test.startTest();
        ProductSyncEndpoint.softDeleteProduct();
        Test.stopTest();
        // Sprwadzamy, że Sync_Count wzrósł z 0 do 1
        Product2 updated = [SELECT Sync_Count__c FROM Product2 WHERE Id = :product.Id];
        Assert.areEqual(1, updated.Sync_Count__c, 'Sync_Count should increment after DELETE');
    }
}
