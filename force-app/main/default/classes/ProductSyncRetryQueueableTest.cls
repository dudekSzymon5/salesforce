@IsTest
private class ProductSyncRetryQueueableTest {

    @IsTest
    static void testRetryInsertSuccessMarksSuccessAndRefreshesPayload() {
        // Retry się udał, payload odświezony
        // Tworzę produkt i rekord w kolejce ze starym paylodem
        Product2 product = TestDataFactory.product().withCode('RET-001').create();
        Product_Sync_Queue__c queueRecord = TestDataFactory.queueRecord()
            .forProduct(product.Id)
            .withPayload('{"old":"payload"}')
            .create();

        Test.setMock(HttpCalloutMock.class, TestDataFactory.httpSuccess());
        Test.startTest();
        System.enqueueJob(new ProductSyncRetryQueueable());
        Test.stopTest();

        // Status zmieniony na success
        Product_Sync_Queue__c result = [SELECT Status__c, Attempt_Count__c, Payload__c FROM Product_Sync_Queue__c WHERE Id = :queueRecord.Id];
        Assert.areEqual(Utils.PRODUCT_SYNC.STATUS.SUCCESS, result.Status__c);
        Assert.areEqual(2, result.Attempt_Count__c, 'Attempt_Count should increment by 1');
        Assert.areNotEqual('{"old":"payload"}', result.Payload__c, 'Payload should be refreshed with current product data');
    }

    @IsTest
    static void testRetryInsertServerErrorRemainsFailed() {
        // Retry się wyjebał
        Product2 product = TestDataFactory.product().withCode('RET-002').create();
        Product_Sync_Queue__c queueRecord = TestDataFactory.queueRecord().forProduct(product.Id).create();

        Test.setMock(HttpCalloutMock.class, TestDataFactory.httpError());
        Test.startTest();
        System.enqueueJob(new ProductSyncRetryQueueable());
        Test.stopTest();

        Product_Sync_Queue__c result = [SELECT Status__c, Attempt_Count__c FROM Product_Sync_Queue__c WHERE Id = :queueRecord.Id];
        // Status nadal wyjebania, ale liczba prób wzrosła z 1 do 2
        Assert.areEqual(Utils.PRODUCT_SYNC.STATUS.FAILED, result.Status__c);
        Assert.areEqual(2, result.Attempt_Count__c);
    }

    @IsTest
    static void testRetryInsertProductDeletedSkipsCalloutAndMarksSuccess() {
        // Produkt usunięty z bazy, pomijany callout
        // Tworzę produkt, rekord w kolejce, potem usuwam produkt
        TriggerBase.bypass('Product2');
        Product2 product = TestDataFactory.product().withCode('DEL-001').create();
        TriggerBase.clearBypass('Product2');
        Product_Sync_Queue__c queueRecord = TestDataFactory.queueRecord().forProduct(product.Id).create();

        TriggerBase.bypass('Product2');
        delete product;
        TriggerBase.clearBypass('Product2');

        Test.setMock(HttpCalloutMock.class, TestDataFactory.httpSuccess());
        Test.startTest();
        System.enqueueJob(new ProductSyncRetryQueueable());
        Test.stopTest();

        Product_Sync_Queue__c result = [SELECT Status__c FROM Product_Sync_Queue__c WHERE Id = :queueRecord.Id];
        // Nie ma co wysyłać — oznaczam jako Success bez callout
        Assert.areEqual(
            Utils.PRODUCT_SYNC.STATUS.SUCCESS, result.Status__c,
            'Deleted product should skip callout and be marked Success'
        );
    }

    @IsTest
    static void testRetryDeleteSuccessMarksSuccess() {
        //Rekord w kolejce to operacja DELETE (bez produktu w bazie)
        Product_Sync_Queue__c queueRecord = TestDataFactory.queueRecord()
            .asDelete('EXT-PROD-001')
            .create();

        Test.setMock(HttpCalloutMock.class, TestDataFactory.httpSuccess('{"status":"deleted"}'));
        Test.startTest();
        System.enqueueJob(new ProductSyncRetryQueueable());
        Test.stopTest();

        Product_Sync_Queue__c result = [SELECT Status__c, Attempt_Count__c FROM Product_Sync_Queue__c WHERE Id = :queueRecord.Id];
        //Callout się udał
        Assert.areEqual(Utils.PRODUCT_SYNC.STATUS.SUCCESS, result.Status__c);
        Assert.areEqual(2, result.Attempt_Count__c);
    }

    @IsTest
    static void testRetryMaxAttemptsReachedRecordNotProcessed() {
        // Maksymalna liczba prób
        // Rekord ma 3 proby - nie powinien być przetworzony
        Product2 product = TestDataFactory.product().withCode('RET-MAX').create();
        Product_Sync_Queue__c queueRecord = TestDataFactory.queueRecord()
            .forProduct(product.Id)
            .withAttempts(3)
            .create();

        Test.setMock(HttpCalloutMock.class, TestDataFactory.httpSuccess());
        Test.startTest();
        System.enqueueJob(new ProductSyncRetryQueueable());
        Test.stopTest();

        Product_Sync_Queue__c result = [SELECT Status__c, Attempt_Count__c FROM Product_Sync_Queue__c WHERE Id = :queueRecord.Id];
        // Status i liczba prób bez zmian - job ma wyjebane w niego
        Assert.areEqual(Utils.PRODUCT_SYNC.STATUS.FAILED, result.Status__c, 'Record at MAX_ATTEMPTS should not be retried');
        Assert.areEqual(3, result.Attempt_Count__c, 'Attempt_Count should not change');
    }

    @IsTest
    static void testRetryEmptyQueueCompletesWithoutError() {
        // pusta kolejka
        // Nie tworzy żadnych rekordów
        Test.startTest();
        System.enqueueJob(new ProductSyncRetryQueueable());
        Test.stopTest();
        // Job się kończy bez błędu
        Assert.areEqual(0, [SELECT Id FROM Product_Sync_Queue__c].size());
    }
}
