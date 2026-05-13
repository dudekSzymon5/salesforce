public class ProductSyncRetryQueueable implements Queueable, Database.AllowsCallouts {

    private static final Integer MAX_ATTEMPTS = 3;

    public void execute(QueueableContext ctx) {
        List<Product_Sync_Queue__c> failedSyncs = [
            SELECT Id, Product__c, Operation__c, Payload__c, Attempt_Count__c, Target_Org__c
            FROM Product_Sync_Queue__c
            WHERE Status__c = :Utils.PRODUCT_SYNC.STATUS.FAILED
            AND Attempt_Count__c < :MAX_ATTEMPTS
            ORDER BY LastModifiedDate ASC
            LIMIT 50
        ];

        if (failedSyncs.isEmpty()) return;

        // Zbieramy ID produktów do odświeżenia payloadu (tylko INSERT/UPDATE)
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
                HttpRequest req = new HttpRequest();
                req.setTimeout(Utils.PRODUCT_SYNC.API.TIMEOUT);
                req.setHeader('Content-Type', 'application/json');

                if (record.Operation__c == Utils.PRODUCT_SYNC.OPERATION.DELETE_OP) {
                    req.setMethod('DELETE');
                    // Payload__c przechowuje externalProductId dla operacji DELETE
                    req.setEndpoint(Utils.PRODUCT_SYNC.API.NAMED_CREDENTIAL + Utils.PRODUCT_SYNC.API.ENDPOINT + record.Payload__c);
                } else {
                    Product2 freshProduct = productMap.get(record.Product__c);
                    if (freshProduct == null) {
                        // Produkt został usunięty — INSERT/UPDATE bez sensu
                        record.Status__c = Utils.PRODUCT_SYNC.STATUS.SUCCESS;
                        record.Error_Message__c = 'Product deleted - retry skipped';
                        record.Attempt_Count__c = (record.Attempt_Count__c == null ? 0 : record.Attempt_Count__c) + 1;
                        record.Last_Attempt__c = DateTime.now();
                        toUpdate.add(record);
                        continue;
                    }
                    String freshPayload = ProductSyncCallout.buildPayload(freshProduct);
                    record.Payload__c = freshPayload;
                    req.setMethod('POST');
                    req.setEndpoint(Utils.PRODUCT_SYNC.API.NAMED_CREDENTIAL + Utils.PRODUCT_SYNC.API.ENDPOINT);
                    req.setBody(freshPayload);
                }

                HttpResponse res = new Http().send(req);

                ErrorLogger.logInfo(
                    'ProductSyncRetryQueueable',
                    'RETRY ' + record.Operation__c + ' | QueueId: ' + record.Id + ' | Status: ' + res.getStatusCode()
                );

                if (res.getStatusCode() == 200) {
                    record.Status__c = Utils.PRODUCT_SYNC.STATUS.SUCCESS;
                } else {
                    record.Status__c = Utils.PRODUCT_SYNC.STATUS.FAILED;
                    record.Error_Message__c = res.getBody();
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
