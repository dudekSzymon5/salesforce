public class ProductSyncCallout {

    public static void syncProduct(Product2 product) {
        String payload = buildPayload(product);

        ErrorLogger.logInfo(
            'ProductSyncCallout.syncProduct',
            'OUTBOUND POST | ProductId: ' + product.Id + ' | Payload: ' + payload
        );
        // Budowanie JSON z danych produktu
        // adres, metoda, nagłówek, tiemout
        try {
            HttpRequest httpRequest = new HttpRequest();
            httpRequest.setEndpoint(Utils.PRODUCT_SYNC.API.NAMED_CREDENTIAL + Utils.PRODUCT_SYNC.API.ENDPOINT);
            httpRequest.setMethod('POST');
            httpRequest.setHeader('Content-Type', 'application/json');
            httpRequest.setBody(payload);
            httpRequest.setTimeout(Utils.PRODUCT_SYNC.API.TIMEOUT);

            HttpResponse httpResponse = new Http().send(httpRequest);

            ErrorLogger.logInfo(
                'ProductSyncCallout.syncProduct',
                'OUTBOUND POST RESPONSE | Status: ' + httpResponse.getStatusCode() + ' | Body: ' + httpResponse.getBody()
            );
            // Jeśli Org Konrada odpowiedział czymś innym niż 200 - to zapisuje do kolejki retry
            if (httpResponse.getStatusCode() != 200) {
                addToRetryQueue(product.Id, 'INSERT', payload, httpResponse.getBody());
            }
            // Jeśli w ogóle się wyjebał - też do retry 
        } catch (Exception e) {
            ErrorLogger.log('ProductSyncCallout.syncProduct', e, product.Id);
            addToRetryQueue(product.Id, 'INSERT', payload, e.getMessage());
        }
    }
    // Jest to praktycznie to samo co syncProduct, ale zamiast POST mam DELETE
    // ID produktu jedzie w URL zamiast body
    public static void deleteProduct(String externalProductId) {
        ErrorLogger.logInfo(
            'ProductSyncCallout.deleteProduct',
            'OUTBOUND DELETE | ExternalProductId: ' + externalProductId
        );

        try {
            HttpRequest httpRequest = new HttpRequest();
            httpRequest.setEndpoint(Utils.PRODUCT_SYNC.API.NAMED_CREDENTIAL + Utils.PRODUCT_SYNC.API.ENDPOINT + externalProductId);
            httpRequest.setMethod('DELETE');
            httpRequest.setTimeout(Utils.PRODUCT_SYNC.API.TIMEOUT);

            HttpResponse httpResponse = new Http().send(httpRequest);

            ErrorLogger.logInfo(
                'ProductSyncCallout.deleteProduct',
                'OUTBOUND DELETE RESPONSE | Status: ' + httpResponse.getStatusCode() + ' | Body: ' + httpResponse.getBody()
            );

            if (httpResponse.getStatusCode() != 200) {
                addToRetryQueue(null, 'DELETE', externalProductId, httpResponse.getBody());
            }

        } catch (Exception e) {
            ErrorLogger.log('ProductSyncCallout.deleteProduct', e);
            addToRetryQueue(null, 'DELETE', externalProductId, e.getMessage());
        }
    }
    // Pakuje dane produktu do JSON
    // externalOrgId to ID mojego orga (Szymon->Konrad)
    private static String buildPayload(Product2 product) {
        Map<String, Object> payload = new Map<String, Object>{
            'externalProductId' => product.Id,
            'externalOrgId' => UserInfo.getOrganizationId(),
            'name' => product.Name,
            'description' => product.Description,
            'productCode' => product.ProductCode,
            'family' => product.Family,
            'language' => product.Language__c
        };
        return JSON.serialize(payload);
    }
    // Tutaj zapisujemy informacje z wiadomością co się wyjebało.
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
