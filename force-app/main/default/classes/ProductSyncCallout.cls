public class ProductSyncCallout {

    public static void syncProduct(Product2 product) {
        String payload = buildPayload(product);

        ErrorLogger.logInfo(
            'ProductSyncCallout.syncProduct',
            'OUTBOUND POST | ProductId: ' + product.Id + ' | Payload: ' + payload
        );

        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint(Utils.PRODUCT_SYNC.API.NAMED_CREDENTIAL + Utils.PRODUCT_SYNC.API.ENDPOINT);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setBody(payload);
            req.setTimeout(Utils.PRODUCT_SYNC.API.TIMEOUT);

            HttpResponse res = new Http().send(req);

            ErrorLogger.logInfo(
                'ProductSyncCallout.syncProduct',
                'OUTBOUND POST RESPONSE | Status: ' + res.getStatusCode() + ' | Body: ' + res.getBody()
            );

            if (res.getStatusCode() != 200) {
                addToRetryQueue(product.Id, 'INSERT', payload, res.getBody());
            }

        } catch (Exception e) {
            ErrorLogger.log('ProductSyncCallout.syncProduct', e, product.Id);
            addToRetryQueue(product.Id, 'INSERT', payload, e.getMessage());
        }
    }

    public static void deleteProduct(String externalProductId) {
        ErrorLogger.logInfo(
            'ProductSyncCallout.deleteProduct',
            'OUTBOUND DELETE | ExternalProductId: ' + externalProductId
        );

        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint(Utils.PRODUCT_SYNC.API.NAMED_CREDENTIAL + Utils.PRODUCT_SYNC.API.ENDPOINT + externalProductId);
            req.setMethod('DELETE');
            req.setTimeout(Utils.PRODUCT_SYNC.API.TIMEOUT);

            HttpResponse res = new Http().send(req);

            ErrorLogger.logInfo(
                'ProductSyncCallout.deleteProduct',
                'OUTBOUND DELETE RESPONSE | Status: ' + res.getStatusCode() + ' | Body: ' + res.getBody()
            );

            if (res.getStatusCode() != 200) {
                addToRetryQueue(null, 'DELETE', externalProductId, res.getBody());
            }

        } catch (Exception e) {
            ErrorLogger.log('ProductSyncCallout.deleteProduct', e);
            addToRetryQueue(null, 'DELETE', externalProductId, e.getMessage());
        }
    }

    private static String buildPayload(Product2 p) {
        Map<String, Object> payload = new Map<String, Object>{
            'externalProductId' => p.Id,
            'externalOrgId' => UserInfo.getOrganizationId(),
            'name' => p.Name,
            'description' => p.Description,
            'productCode' => p.ProductCode,
            'family' => p.Family,
            'language' => p.Language__c
        };
        return JSON.serialize(payload);
    }

    private static void addToRetryQueue(Id productId, String operation, String payload, String errorMessage) {
        Product_Sync_Queue__c queue = new Product_Sync_Queue__c(
            Product__c = productId,
            Operation__c = operation,
            Payload__c = payload,
            Status__c = Utils.PRODUCT_SYNC.STATUS.FAILED,
            Attempt_Count__c = 1,
            Last_Attempt__c = DateTime.now(),
            Target_Org__c = Utils.PRODUCT_SYNC.API.NAMED_CREDENTIAL,
            Error_Message__c = errorMessage
        );
        insert queue;
    }
}
