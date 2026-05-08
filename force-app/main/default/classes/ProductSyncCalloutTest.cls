@IsTest
private class ProductSyncCalloutTest {

    @IsTest
    static void testSyncProductSuccess() {
        TriggerBase.bypass('ProductTrigger');
        Product2 p = new Product2(Name = 'Test Product', ProductCode = 'TEST-001', Family = 'Software', Is_External__c = false);
        insert p;
        TriggerBase.clearBypass('ProductTrigger');
        p = [SELECT Id, Name, ProductCode, Family, Description, Language__c FROM Product2 WHERE Id = :p.Id];

        Test.setMock(HttpCalloutMock.class, new ProductSyncCalloutMock(200, '{"status":"success","productId":"001TEST"}'));
        Test.startTest();
        ProductSyncCallout.syncProduct(p);
        Test.stopTest();

        System.assertEquals(0, [SELECT Id FROM Product_Sync_Queue__c].size(), 'Nie powinno być wpisów w kolejce przy sukcesie');
    }

    @IsTest
    static void testSyncProductFailure() {
        TriggerBase.bypass('ProductTrigger');
        Product2 p = new Product2(Name = 'Test Product', ProductCode = 'TEST-001', Family = 'Software', Is_External__c = false);
        insert p;
        TriggerBase.clearBypass('ProductTrigger');

        p = [SELECT Id, Name, ProductCode, Family, Description, Language__c FROM Product2 WHERE Id = :p.Id];

        Integer countBefore = [SELECT COUNT() FROM Product_Sync_Queue__c];

        Test.setMock(HttpCalloutMock.class, new ProductSyncCalloutMock(500, '{"status":"error","message":"Internal Server Error"}'));
        Test.startTest();
        ProductSyncCallout.syncProduct(p);
        Test.stopTest();

        List<Product_Sync_Queue__c> queue = [SELECT Id, Status__c, Attempt_Count__c FROM Product_Sync_Queue__c WHERE Status__c = 'Failed' AND CreatedDate = TODAY];
        System.assertEquals(countBefore + 1, [SELECT COUNT() FROM Product_Sync_Queue__c], 'Powinien być 1 nowy wpis w kolejce');
        System.assertEquals('Failed', queue[queue.size()-1].Status__c);
    }
    @IsTest
    static void testDeleteProductSuccess() {
        Test.setMock(HttpCalloutMock.class, new ProductSyncCalloutMock(200, '{"status":"success"}'));
        Test.startTest();
        ProductSyncCallout.deleteProduct('EXT-001');
        Test.stopTest();

        System.assertEquals(0, [SELECT Id FROM Product_Sync_Queue__c].size());
    }

    @IsTest
    static void testDeleteProductFailure() {
        Test.setMock(HttpCalloutMock.class, new ProductSyncCalloutMock(404, '{"errorCode":"NOT_FOUND"}'));
        Test.startTest();
        ProductSyncCallout.deleteProduct('EXT-001');
        Test.stopTest();

        List<Product_Sync_Queue__c> queue = [SELECT Id, Status__c FROM Product_Sync_Queue__c];
        System.assertEquals(1, queue.size());
        System.assertEquals('Failed', queue[0].Status__c);
    }

    private class ProductSyncCalloutMock implements HttpCalloutMock {
        private Integer statusCode;
        private String body;

        public ProductSyncCalloutMock(Integer statusCode, String body) {
            this.statusCode = statusCode;
            this.body = body;
        }

        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode);
            res.setBody(body);
            return res;
        }
    }
}