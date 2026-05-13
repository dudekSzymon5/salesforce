@IsTest
private class ProductSyncRetryQueueableTest {

    @IsTest
    static void testRetryInsertSuccess() {
        Product2 p = new Product2(Name = 'Retry Product', ProductCode = 'RET-001', Family = 'Software', Is_External__c = true);
        insert p;
        p = [SELECT Id, Name, ProductCode, Family, Description, Language__c FROM Product2 WHERE Id = :p.Id];

        Product_Sync_Queue__c queueRecord = new Product_Sync_Queue__c(
            Product__c = p.Id,
            Operation__c = Utils.PRODUCT_SYNC.OPERATION.INSERT_OP,
            Payload__c = '{"old":"payload"}',
            Status__c = Utils.PRODUCT_SYNC.STATUS.FAILED,
            Attempt_Count__c = 1,
            Last_Attempt__c = DateTime.now().addHours(-1)
        );
        insert queueRecord;

        Test.setMock(HttpCalloutMock.class, new RetryMock(200, '{"status":"success"}'));
        Test.startTest();
        System.enqueueJob(new ProductSyncRetryQueueable());
        Test.stopTest();

        Product_Sync_Queue__c updated = [SELECT Status__c, Attempt_Count__c, Payload__c FROM Product_Sync_Queue__c WHERE Id = :queueRecord.Id];
        System.assertEquals(Utils.PRODUCT_SYNC.STATUS.SUCCESS, updated.Status__c, 'Status powinien być Success');
        System.assertEquals(2, updated.Attempt_Count__c, 'Attempt_Count powinien wzrosnąć');
        System.assertNotEquals('{"old":"payload"}', updated.Payload__c, 'Payload powinien być odświeżony');
    }

    @IsTest
    static void testRetryInsertFailure() {
        Product2 p = new Product2(Name = 'Retry Product', ProductCode = 'RET-002', Family = 'Software', Is_External__c = true);
        insert p;

        Product_Sync_Queue__c queueRecord = new Product_Sync_Queue__c(
            Product__c = p.Id,
            Operation__c = Utils.PRODUCT_SYNC.OPERATION.INSERT_OP,
            Payload__c = '{"old":"payload"}',
            Status__c = Utils.PRODUCT_SYNC.STATUS.FAILED,
            Attempt_Count__c = 1,
            Last_Attempt__c = DateTime.now().addHours(-1)
        );
        insert queueRecord;

        Test.setMock(HttpCalloutMock.class, new RetryMock(500, 'Internal Server Error'));
        Test.startTest();
        System.enqueueJob(new ProductSyncRetryQueueable());
        Test.stopTest();

        Product_Sync_Queue__c updated = [SELECT Status__c, Attempt_Count__c FROM Product_Sync_Queue__c WHERE Id = :queueRecord.Id];
        System.assertEquals(Utils.PRODUCT_SYNC.STATUS.FAILED, updated.Status__c, 'Status powinien zostać Failed');
        System.assertEquals(2, updated.Attempt_Count__c);
    }

    @IsTest
    static void testRetryInsertProductDeleted() {
        Product2 p = new Product2(Name = 'Deleted Product', ProductCode = 'DEL-001', Family = 'Software', Is_External__c = true);
        insert p;

        Product_Sync_Queue__c queueRecord = new Product_Sync_Queue__c(
            Product__c = p.Id,
            Operation__c = Utils.PRODUCT_SYNC.OPERATION.INSERT_OP,
            Payload__c = '{"old":"payload"}',
            Status__c = Utils.PRODUCT_SYNC.STATUS.FAILED,
            Attempt_Count__c = 1,
            Last_Attempt__c = DateTime.now().addHours(-1)
        );
        insert queueRecord;

        // Usuwamy produkt — teraz go nie ma, retry powinien pominąć callout
        delete p;

        Test.startTest();
        System.enqueueJob(new ProductSyncRetryQueueable());
        Test.stopTest();

        Product_Sync_Queue__c updated = [SELECT Status__c FROM Product_Sync_Queue__c WHERE Id = :queueRecord.Id];
        System.assertEquals(Utils.PRODUCT_SYNC.STATUS.SUCCESS, updated.Status__c, 'Usunięty produkt powinien być oznaczony jako Success');
    }

    @IsTest
    static void testRetryDeleteSuccess() {
        Product_Sync_Queue__c queueRecord = new Product_Sync_Queue__c(
            Product__c = null,
            Operation__c = Utils.PRODUCT_SYNC.OPERATION.DELETE_OP,
            Payload__c = 'EXT-PROD-001',
            Status__c = Utils.PRODUCT_SYNC.STATUS.FAILED,
            Attempt_Count__c = 1,
            Last_Attempt__c = DateTime.now().addHours(-1)
        );
        insert queueRecord;

        Test.setMock(HttpCalloutMock.class, new RetryMock(200, '{"status":"deleted"}'));
        Test.startTest();
        System.enqueueJob(new ProductSyncRetryQueueable());
        Test.stopTest();

        Product_Sync_Queue__c updated = [SELECT Status__c, Attempt_Count__c FROM Product_Sync_Queue__c WHERE Id = :queueRecord.Id];
        System.assertEquals(Utils.PRODUCT_SYNC.STATUS.SUCCESS, updated.Status__c);
        System.assertEquals(2, updated.Attempt_Count__c);
    }

    @IsTest
    static void testMaxAttemptsReached() {
        Product2 p = new Product2(Name = 'Max Retry', ProductCode = 'RET-MAX', Family = 'Software', Is_External__c = true);
        insert p;

        Product_Sync_Queue__c queueRecord = new Product_Sync_Queue__c(
            Product__c = p.Id,
            Operation__c = Utils.PRODUCT_SYNC.OPERATION.INSERT_OP,
            Payload__c = '{"payload":"x"}',
            Status__c = Utils.PRODUCT_SYNC.STATUS.FAILED,
            Attempt_Count__c = 3,
            Last_Attempt__c = DateTime.now().addHours(-1)
        );
        insert queueRecord;

        Test.setMock(HttpCalloutMock.class, new RetryMock(200, '{"status":"success"}'));
        Test.startTest();
        System.enqueueJob(new ProductSyncRetryQueueable());
        Test.stopTest();

        // Rekord z Attempt_Count__c = 3 nie powinien być przetworzony
        Product_Sync_Queue__c updated = [SELECT Status__c, Attempt_Count__c FROM Product_Sync_Queue__c WHERE Id = :queueRecord.Id];
        System.assertEquals(Utils.PRODUCT_SYNC.STATUS.FAILED, updated.Status__c, 'Rekord po MAX_ATTEMPTS nie powinien być retryowany');
        System.assertEquals(3, updated.Attempt_Count__c);
    }

    private class RetryMock implements HttpCalloutMock {
        private Integer statusCode;
        private String body;

        public RetryMock(Integer statusCode, String body) {
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
