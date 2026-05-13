@IsTest
private class ProductSyncCalloutTest {

    @IsTest
    static void testSyncProduct_success_noQueueEntry() {
        Product2 product = TestDataFactory.aProduct().withCode('TEST-001').create();
        product = [SELECT Id, Name, ProductCode, Family, Description, Language__c FROM Product2 WHERE Id = :product.Id];

        Test.setMock(HttpCalloutMock.class, TestDataFactory.httpSuccess('{"status":"success","productId":"001TEST"}'));
        Test.startTest();
        ProductSyncCallout.syncProduct(product);
        Test.stopTest();

        Assert.areEqual(0, [SELECT Id FROM Product_Sync_Queue__c WHERE Status__c = 'Failed'].size());
    }

    @IsTest
    static void testSyncProduct_serverError_addsToQueue() {
        TriggerBase.bypass('ProductTrigger');
        Product2 product = TestDataFactory.aProduct().withCode('TEST-002').create();
        TriggerBase.clearBypass('ProductTrigger');
        product = [SELECT Id, Name, ProductCode, Family, Description, Language__c FROM Product2 WHERE Id = :product.Id];

        Test.setMock(HttpCalloutMock.class, TestDataFactory.httpError());
        Test.startTest();
        ProductSyncCallout.syncProduct(product);
        Test.setMock(HttpCalloutMock.class, TestDataFactory.httpSuccess());
        Test.stopTest();

        List<Product_Sync_Queue__c> queue = [
            SELECT Status__c, Attempt_Count__c FROM Product_Sync_Queue__c WHERE Product__c = :product.Id
        ];
        Assert.areEqual(1, queue.size(), 'Queue entry should be created on HTTP 500');
        Assert.areEqual('Failed', queue[0].Status__c);
        Assert.areEqual(1, queue[0].Attempt_Count__c);
    }

    @IsTest
    static void testDeleteProduct_success_noQueueEntry() {
        Test.setMock(HttpCalloutMock.class, TestDataFactory.httpSuccess());
        Test.startTest();
        ProductSyncCallout.deleteProduct('EXT-001');
        Test.stopTest();

        Assert.areEqual(
            0,
            [SELECT Id FROM Product_Sync_Queue__c WHERE Operation__c = 'DELETE' AND Status__c = 'Failed'].size()
        );
    }

    @IsTest
    static void testDeleteProduct_notFound_addsToQueue() {
        Test.setMock(HttpCalloutMock.class, TestDataFactory.httpError(404, '{"errorCode":"NOT_FOUND"}'));
        Test.startTest();
        ProductSyncCallout.deleteProduct('EXT-001');
        Test.stopTest();

        List<Product_Sync_Queue__c> queue = [SELECT Status__c FROM Product_Sync_Queue__c WHERE Operation__c = 'DELETE'];
        Assert.areEqual(1, queue.size());
        Assert.areEqual('Failed', queue[0].Status__c);
    }

    @IsTest
    static void testBuildPayload_containsAllFields() {
        Product2 product = TestDataFactory.aProduct()
            .withName('My Product')
            .withCode('MP-001')
            .withFamily('Electronics')
            .withDescription('Test Desc')
            .withLanguage('Polish')
            .create();
        product = [SELECT Id, Name, ProductCode, Family, Description, Language__c FROM Product2 WHERE Id = :product.Id];

        String payload = ProductSyncCallout.buildPayload(product);
        Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(payload);

        Assert.areEqual(product.Id, parsed.get('externalProductId'), 'externalProductId must equal product Id');
        Assert.areEqual('My Product', parsed.get('name'));
        Assert.areEqual('MP-001', parsed.get('productCode'));
        Assert.areEqual('Electronics', parsed.get('family'));
        Assert.areEqual('Test Desc', parsed.get('description'));
        Assert.areEqual('Polish', parsed.get('language'));
        Assert.isNotNull(parsed.get('externalOrgId'));
    }
}
