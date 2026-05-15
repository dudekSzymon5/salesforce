@IsTest
private class ProductSyncCalloutTest {

    @TestSetup
    static void makeData() {
        TriggerBase.bypass('Product2');
        
        TestDataFactory.product().withCode('TEST-01').create();
        TestDataFactory.product().withCode('TEST-02').create();
        
        TestDataFactory.product()
            .withName('Test-Apex')
            .withCode('TP-01')
            .withFamily('Software')
            .withDescription('Test')
            .withLanguage('Polish').create();

        TriggerBase.clearBypass('Product2');
    }

    @IsTest
    static void testSyncProductSuccessNoQueueEntry() {
        Product2 product = [SELECT Id, Name, ProductCode, Family, Description, Language__c FROM Product2 WHERE ProductCode = 'TEST-01'];

        Test.setMock(HttpCalloutMock.class, TestDataFactory.httpSuccess('{"status":"success","productId":"01TEST"}'));
        Test.startTest();
        ProductSyncCallout.syncProduct(product);
        Test.stopTest();
        Assert.areEqual(0, [SELECT Id FROM Product_Sync_Queue__c WHERE Status__c = 'Failed'].size());
    }

    @IsTest
    static void testSyncProductServerErrorAddsToQueue() {
        Product2 product = [SELECT Id, Name, ProductCode, Family, Description, Language__c FROM Product2 WHERE ProductCode = 'TEST-02'];

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
    static void testDeleteProductSuccessNoQueueEntry() {
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
    static void testDeleteProductNotFoundAddsToQueue() {
        Test.setMock(HttpCalloutMock.class, TestDataFactory.httpError(404, '{"errorCode":"NOT_FOUND"}'));
        Test.startTest();
        ProductSyncCallout.deleteProduct('EXT-001');
        Test.stopTest();

        List<Product_Sync_Queue__c> queue = [SELECT Status__c FROM Product_Sync_Queue__c WHERE Operation__c = 'DELETE'];
        Assert.areEqual(1, queue.size());
        Assert.areEqual('Failed', queue[0].Status__c);
    }

    @IsTest
    static void testBuildPayloadContainsAllFields() {
        Product2 product = [SELECT Id, Name, ProductCode, Family, Description, Language__c FROM Product2 WHERE ProductCode = 'TP-01'];

        String payload = ProductSyncCallout.buildPayload(product);
        Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(payload);

        Assert.areEqual(product.Id, parsed.get('externalProductId'), 'externalProductId must equal product Id');
        Assert.areEqual('Test-Apex', parsed.get('name'));
        Assert.areEqual('TP-01', parsed.get('productCode'));
        Assert.areEqual('Software', parsed.get('family'));
        Assert.areEqual('Test', parsed.get('description'));
        Assert.areEqual('Polish', parsed.get('language'));
        Assert.isNotNull(parsed.get('externalOrgId'));
    }
}
