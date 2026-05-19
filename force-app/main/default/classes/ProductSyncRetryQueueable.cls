public class ProductSyncRetryQueueable implements Queueable, Database.AllowsCallouts {

    private static final Integer MAX_ATTEMPTS = 3;

    public void execute(QueueableContext ctx) {
        List<Product_Sync_Queue__c> failedSyncs = [
            SELECT Id, Product__c, Operation__c, Payload__c, Attempt_Count__c, Target_Org__c, Error_Message__c
            FROM Product_Sync_Queue__c
            WHERE Status__c = :Utils.PRODUCT_SYNC.STATUS.FAILED
            AND Attempt_Count__c < :MAX_ATTEMPTS
            ORDER BY LastModifiedDate ASC
            LIMIT 50
        ];

        if (failedSyncs.isEmpty()) return;

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

        List<Product_Sync_Queue__c> sendItemsToEmail = new List<Product_Sync_Queue__c>();
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

            if(record.Status__c == Utils.PRODUCT_SYNC.STATUS.FAILED && record.Attempt_Count__c >= MAX_ATTEMPTS) {
                sendItemsToEmail.add(record);
            }

            toUpdate.add(record);
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }

        if (!sendItemsToEmail.isEmpty()) {
            sendFailureEmail(sendItemsToEmail, productMap);
        }
    }

    private void sendFailureEmail(List<Product_Sync_Queue__c> failedItems, Map<Id, Product2> productsMap) {
        Messaging.SingleEmailMessage singleEmailMessage = new Messaging.SingleEmailMessage();
        singleEmailMessage.setToAddresses(new List<String> {'szymon.dudek@britenet.eu'});
        singleEmailMessage.setSubject('Alert: ' + failedItems.size() + ' Execution failed 3 times');

         String message = 'The synchronization for the following products has failed 3 times and will no longer be retried automatically.\n\n';

         for (Product_Sync_Queue__c item : failedItems) {
            Product2 product = productsMap.get(item.Product__c);

            if ( product != null ) {
                message += 'Product' + product.Name + ' (' + product.ProductCode + ')\n';
            } else {
                message += 'Product: [DELETED] \n';
            }
            message += ' Operation: ' + item.Operation__c + '\n';
            message += ' Error: ' + item.Error_Message__c + '\n\n';
         }

         message += 'Please review the data and update these products in Salesforce to re-trigger the sync.';
         singleEmailMessage.setPlainTextBody(message);

         try {
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage> {singleEmailMessage});
         } catch (Exception e) {
            ErrorLogger.log('ProductSyncRetryQueueable', e);
         }
    }

}
