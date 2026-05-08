@IsTest
private class ProductSyncQueueableTest {

    @IsTest
    static void testExecuteInsert() {
        Product2 p = new Product2(
            Name = 'Test Product',
            ProductCode = 'TP-001',
            Is_External__c = false
        );
        insert p;

        p = [SELECT Id, Name, ProductCode, Family, Description, Language__c FROM Product2 WHERE Id = :p.Id];

        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, '{"status":"success"}'));

        Test.startTest();
        ProductSyncQueueable job = new ProductSyncQueueable(new List<Product2>{p}, 'INSERT');
        System.enqueueJob(job);
        Test.stopTest();
    }

    @IsTest
    static void testExecuteDelete() {
        Product2 p = new Product2(
            Name = 'Test Product',
            ProductCode = 'TP-001',
            Is_External__c = false
        );
        insert p;

        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, '{"status":"success"}'));

        Test.startTest();
        ProductSyncQueueable job = new ProductSyncQueueable(new List<Product2>{p}, 'DELETE');
        System.enqueueJob(job);
        Test.stopTest();
    }

    private class MockHttpResponse implements HttpCalloutMock {
        private Integer statusCode;
        private String body;

        public MockHttpResponse(Integer statusCode, String body) {
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