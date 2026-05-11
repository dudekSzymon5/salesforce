@RestResource(urlMapping='/v1/products/*')
global class ProductSyncEndpoint {

    @HttpPost
    global static void upsertProduct() {
        // Pobieram request który przyszedł z Callouta i wyciągam z niego informacje
        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;
        String body = request.requestBody.toString();

        ErrorLogger.logInfo(
            'ProductSyncEndpoint.upsertProduct',
            'INBOUND POST | URI: ' + request.requestURI + ' | Body: ' + body
        );

        try {
            // Zamieniam sobie JSON na obiekt APEX - żeby sobie normalnie działać
            ProductPayload payload = (ProductPayload) JSON.deserialize(body, ProductPayload.class);

            List<Product2> existing = [
                SELECT Id, Sync_Count__c 
                FROM Product2
                WHERE External_Product_Id__c = :payload.externalProductId
                AND Is_External__c = true
                LIMIT 1
            ];
            // Sprawdzam czy produkt istnieje u Konrada
            // Jeśli nie istnieje to sobie utworze.
            Product2 product = existing.isEmpty() ? new Product2() : existing[0];
            product.Name = payload.name;
            product.Description = payload.description;
            product.ProductCode = payload.productCode;
            product.Family = payload.family;
            product.Language__c = payload.language;
            product.Is_External__c = true;
            product.Is_Deleted__c = false;
            product.External_Product_Id__c = payload.externalProductId;
            product.External_Org_Id__c = payload.externalOrgId;
            product.Sync_Status__c = Utils.PRODUCT_SYNC.STATUS.SUCCESS;
            product.Sync_Count__c = (product.Sync_Count__c == null ? 0 : product.Sync_Count__c) + 1;

            upsert product;

            String responseBody = JSON.serialize(new Map<String, String>{
                'status' => 'success',
                'productId' => product.Id
            });

            response.statusCode = 200;
            response.responseBody = Blob.valueOf(responseBody);

            ErrorLogger.logInfo(
                'ProductSyncEndpoint.upsertProduct',
                'INBOUND POST SUCCESS | Response: ' + responseBody
            );

        } catch (Exception e) {
            String errorBody = JSON.serialize(new Map<String, String>{
                'status' => 'error',
                'message' => e.getMessage()
            });

            response.statusCode = 500;
            response.responseBody = Blob.valueOf(errorBody);

            ErrorLogger.log('ProductSyncEndpoint.upsertProduct', e);
        }
    }

    // Tak jak było powiedziane, rekord nie jest usuwan fizycznie
    // Ustawiana jest flaga Is_Deleted__c = true.
    @HttpDelete
    global static void softDeleteProduct() {
        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;

        String externalProductId = request.requestURI.substring(
            request.requestURI.lastIndexOf('/') + 1
        );

        ErrorLogger.logInfo(
            'ProductSyncEndpoint.softDeleteProduct',
            'INBOUND DELETE | ExternalProductId: ' + externalProductId
        );

        try {
            List<Product2> products = [
                SELECT Id, Sync_Count__c FROM Product2
                WHERE External_Product_Id__c = :externalProductId
                AND Is_External__c = true
                LIMIT 1
            ];

            if (!products.isEmpty()) {
                products[0].Is_Deleted__c = true;
                products[0].Sync_Status__c = 'Success';
                products[0].Sync_Count__c = (products[0].Sync_Count__c == null ? 0 : products[0].Sync_Count__c) + 1;
                update products[0];
            }

            String responseBody = JSON.serialize(new Map<String, String>{
                'status' => 'success'
            });

            response.statusCode = 200;
            response.responseBody = Blob.valueOf(responseBody);

            ErrorLogger.logInfo(
                'ProductSyncEndpoint.softDeleteProduct',
                'INBOUND DELETE SUCCESS | ExternalProductId: ' + externalProductId
            );

        } catch (Exception e) {
            String errorBody = JSON.serialize(new Map<String, String>{
                'status' => 'error',
                'message' => e.getMessage()
            });

            response.statusCode = 500;
            response.responseBody = Blob.valueOf(errorBody);

            ErrorLogger.log('ProductSyncEndpoint.softDeleteProduct', e);
        }
    }   
    // Rodzaj szablonu do ktorego Apex deserializuje przychodzący JSON.
    global class ProductPayload {
        public String externalProductId;
        public String externalOrgId;
        public String name;
        public String description;
        public String productCode;
        public String family;
        public String language;
    }
}