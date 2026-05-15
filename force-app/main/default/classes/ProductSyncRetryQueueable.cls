public class ProductSyncRetryQueueable implements Queueable, Database.AllowsCallouts {

    private static final Integer MAX_ATTEMPTS = 3;

    public void execute(QueueableContext ctx) {
        List<Product_Sync_Queue__c> failedSyncs = [
            SELECT Id, Product__c, Operation__c, Payload__c, Attempt_Count__c, Target_Org__c
            FROM Product_Sync_Queue__c
            WHERE Status__c = :Utils.PRODUCT_SYNC.STATUS.FAILED
            AND Attempt_Count__c < :MAX_ATTEMPTS
            ORDER BY LastModifiedDate ASC // Najstarsze rekordy są przetwarzane pierwsze - te które czekają najdłużej 
            LIMIT 50
        ];

        if (failedSyncs.isEmpty()) return;

        // Z: Przed retry pobieramy świeże dane produktów jednym SOQL 
        // zamiast używać starego Payload__c który mógł mieć dane.
        Set<Id> productIds = new Set<Id>();
        for (Product_Sync_Queue__c record : failedSyncs) {
            if (record.Operation__c != Utils.PRODUCT_SYNC.OPERATION.DELETE_OP && record.Product__c != null) {
                productIds.add(record.Product__c);
            }
        }

        Map<Id, Product2> productMap = new Map<Id, Product2>();
        if (!productIds.isEmpty()) {
            productMap = new Map<Id, Product2>([
                SELECT Id, Name, Description, ProductCode, Family, Language__c
                FROM Product2
                WHERE Id IN :productIds
            ]);
        }

        List<Product_Sync_Queue__c> toUpdate = new List<Product_Sync_Queue__c>();

        for (Product_Sync_Queue__c record : failedSyncs) {
            try {
                HttpRequest httpRequest = new HttpRequest();
                httpRequest.setTimeout(Utils.PRODUCT_SYNC.API.TIMEOUT);
                httpRequest.setHeader('Content-Type', 'application/json');

                if (record.Operation__c == Utils.PRODUCT_SYNC.OPERATION.DELETE_OP) {
                    httpRequest.setMethod('DELETE');
                    httpRequest.setEndpoint(Utils.PRODUCT_SYNC.API.NAMED_CREDENTIAL + Utils.PRODUCT_SYNC.API.ENDPOINT + record.Payload__c);
                } else {
                    Product2 currentProduct = productMap.get(record.Product__c);
                    if (currentProduct == null) {
                        record.Status__c = Utils.PRODUCT_SYNC.STATUS.SUCCESS;
                        record.Error_Message__c = 'Product deleted - retry skipped';
                        record.Attempt_Count__c = (record.Attempt_Count__c == null ? 0 : record.Attempt_Count__c) + 1;
                        record.Last_Attempt__c = DateTime.now();
                        toUpdate.add(record);
                        continue;
                    }
                    // Z: Odbudowujemy payload ze świeżych danych zamiast używać record.Payload__c
                    // Zamiast wysłać to co było zapisane przy błędzie, pobieramy aktualne dane produktu z bazy i wysyłam je
                    String currentPayload = ProductSyncCallout.buildPayload(currentProduct);
                    record.Payload__c = currentPayload;
                    httpRequest.setMethod('POST');
                    httpRequest.setEndpoint(Utils.PRODUCT_SYNC.API.NAMED_CREDENTIAL + Utils.PRODUCT_SYNC.API.ENDPOINT);
                    httpRequest.setBody(currentPayload);
                }

                HttpResponse httpResponse = new Http().send(httpRequest);

                ErrorLogger.logInfo(
                    'ProductSyncRetryQueueable',
                    'RETRY ' + record.Operation__c + ' | QueueId: ' + record.Id + ' | Status: ' + httpResponse.getStatusCode()
                );

                if (httpResponse.getStatusCode() == 200) {
                    record.Status__c = Utils.PRODUCT_SYNC.STATUS.SUCCESS;
                } else {
                    record.Status__c = Utils.PRODUCT_SYNC.STATUS.FAILED;
                    record.Error_Message__c = httpResponse.getBody();
                }

            } catch (Exception e) {
                record.Status__c = Utils.PRODUCT_SYNC.STATUS.FAILED;
                record.Error_Message__c = e.getMessage();
                ErrorLogger.log('ProductSyncRetryQueueable', e, record.Id);
            }

            record.Attempt_Count__c = (record.Attempt_Count__c == null ? 0 : record.Attempt_Count__c) + 1;
            record.Last_Attempt__c = DateTime.now();
            toUpdate.add(record);
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }
}
