@IsTest
private class ProductSyncEndpointTest {

    @TestSetup
    static void setup() {
        TriggerBase.bypass('ProductTrigger');
        Product2 p = new Product2(
            Name = 'Test External Product',
            ProductCode = 'TEST-001',
            Family = 'Software',
            Is_External__c = true,
            External_Product_Id__c = 'EXT-001',
            External_Org_Id__c = '00DTEST000000001'
        );
        insert p;
        TriggerBase.clearBypass('ProductTrigger');
    }

    @IsTest
    static void testUpsertProductInsert() {
        String body = JSON.serialize(new Map<String, Object>{
            'externalProductId' => 'EXT-NEW-001',
            'externalOrgId' => '00DTEST000000001',
            'name' => 'New External Product',
            'description' => 'Test description',
            'productCode' => 'EXT-PC-001',
            'family' => 'Software',
            'language' => 'English'
        });

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/v1/products/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(body);
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        ProductSyncEndpoint.upsertProduct();
        Test.stopTest();

        System.assertEquals(200, res.statusCode);
        Product2 created = [
            SELECT Id, Name, Is_External__c
            FROM Product2
            WHERE External_Product_Id__c = 'EXT-NEW-001'
            LIMIT 1
        ];
        System.assertEquals('New External Product', created.Name);
        System.assertEquals(true, created.Is_External__c);
    }

    @IsTest
    static void testUpsertProductUpdate() {
        String body = JSON.serialize(new Map<String, Object>{
            'externalProductId' => 'EXT-001',
            'externalOrgId' => '00DTEST000000001',
            'name' => 'Updated External Product',
            'description' => 'Updated description',
            'productCode' => 'TEST-001',
            'family' => 'Software',
            'language' => 'Polish'
        });

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/v1/products/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(body);
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        ProductSyncEndpoint.upsertProduct();
        Test.stopTest();

        System.assertEquals(200, res.statusCode);
        Product2 updated = [
            SELECT Name FROM Product2
            WHERE External_Product_Id__c = 'EXT-001'
            LIMIT 1
        ];
        System.assertEquals('Updated External Product', updated.Name);
    }

    @IsTest
    static void testSoftDeleteProduct() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/v1/products/EXT-001';
        req.httpMethod = 'DELETE';
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        ProductSyncEndpoint.softDeleteProduct();
        Test.stopTest();

        System.assertEquals(200, res.statusCode);
        Product2 deleted = [
            SELECT Is_Deleted__c FROM Product2
            WHERE External_Product_Id__c = 'EXT-001'
            LIMIT 1
        ];
        System.assertEquals(true, deleted.Is_Deleted__c);
    }

    @IsTest
    static void testSoftDeleteProductNotFound() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/v1/products/NON-EXISTENT';
        req.httpMethod = 'DELETE';
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        ProductSyncEndpoint.softDeleteProduct();
        Test.stopTest();

        System.assertEquals(200, res.statusCode);
    }
}