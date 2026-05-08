@RestResource(urlMapping='/v1/products/*')
global class ProductSyncEndpoint {

    @HttpPost
    global static void upsertProduct() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        String body = req.requestBody.toString();

        ErrorLogger.logInfo(
            'ProductSyncEndpoint.upsertProduct',
            'INBOUND POST | URI: ' + req.requestURI + ' | Body: ' + body
        );

        try {
            ProductPayload payload = (ProductPayload) JSON.deserialize(body, ProductPayload.class);

            // TUTAJ używamy payload.externalProductId
            List<Product2> existing = [
                SELECT Id, Sync_Count__c 
                FROM Product2
                WHERE External_Product_Id__c = :payload.externalProductId
                AND Is_External__c = true
                LIMIT 1
            ];

            Product2 p = existing.isEmpty() ? new Product2() : existing[0];
            p.Name = payload.name;
            p.Description = payload.description;
            p.ProductCode = payload.productCode;
            p.Family = payload.family;
            p.Language__c = payload.language;
            p.Is_External__c = true;
            p.Is_Deleted__c = false;
            p.External_Product_Id__c = payload.externalProductId;
            p.External_Org_Id__c = payload.externalOrgId;
            p.Sync_Status__c = Utils.PRODUCT_SYNC.STATUS.SUCCESS;
            p.Sync_Count__c = (p.Sync_Count__c == null ? 0 : p.Sync_Count__c) + 1;

            upsert p;

            String responseBody = JSON.serialize(new Map<String, String>{
                'status' => 'success',
                'productId' => p.Id
            });

            res.statusCode = 200;
            res.responseBody = Blob.valueOf(responseBody);

            ErrorLogger.logInfo(
                'ProductSyncEndpoint.upsertProduct',
                'INBOUND POST SUCCESS | Response: ' + responseBody
            );

        } catch (Exception e) {
            String errorBody = JSON.serialize(new Map<String, String>{
                'status' => 'error',
                'message' => e.getMessage()
            });

            res.statusCode = 500;
            res.responseBody = Blob.valueOf(errorBody);

            ErrorLogger.log('ProductSyncEndpoint.upsertProduct', e);
        }
    }

    @HttpDelete
    global static void softDeleteProduct() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        String externalProductId = req.requestURI.substring(
            req.requestURI.lastIndexOf('/') + 1
        );

        ErrorLogger.logInfo(
            'ProductSyncEndpoint.softDeleteProduct',
            'INBOUND DELETE | ExternalProductId: ' + externalProductId
        );

        try {
            // TUTAJ używamy tylko externalProductId (bez payload!)
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

            res.statusCode = 200;
            res.responseBody = Blob.valueOf(responseBody);

            ErrorLogger.logInfo(
                'ProductSyncEndpoint.softDeleteProduct',
                'INBOUND DELETE SUCCESS | ExternalProductId: ' + externalProductId
            );

        } catch (Exception e) {
            String errorBody = JSON.serialize(new Map<String, String>{
                'status' => 'error',
                'message' => e.getMessage()
            });

            res.statusCode = 500;
            res.responseBody = Blob.valueOf(errorBody);

            ErrorLogger.log('ProductSyncEndpoint.softDeleteProduct', e);
        }
    }

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