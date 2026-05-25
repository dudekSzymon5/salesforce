@IsTest
private class ExternalComplaintTriggerTest {

    private class ComplaintCalloutMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(201);
            res.setBody('{"id":"e02xx0000000001AAA","success":true,"errors":[]}');
            return res;
        }
    }

    @IsTest
    static void testTriggerCreatesCase() {
        Test.setMock(HttpCalloutMock.class, new ComplaintCalloutMock());

        String fakeCaseId = '500000000000001AAA';
        String fakeOrderId = '801000000000001AAA';

        Test.startTest();
        EventBus.publish(new External_Complaint__e(
            Case_Id__c = fakeCaseId,
            Order_Id__c = fakeOrderId,
            Reason__c = 'Test reason',
            Product_Ids__c = '01t000000000001AAA'
        ));
        Test.stopTest();

        List<Case> cases = [
            SELECT Id, External_Case_Id__c, Complaint_Reason__c, Status, Origin
            FROM Case
            WHERE External_Case_Id__c = :fakeCaseId
        ];

        Assert.areEqual(1, cases.size(), 'Should create one Case');
        Assert.areEqual('Test reason', cases[0].Complaint_Reason__c);
        Assert.areEqual(Utils.ORDER_COMPLAINT.CASE_STATUS.NEW_CASE, cases[0].Status);
        Assert.areEqual(Utils.ORDER_COMPLAINT.CASE_ORIGIN.WEB, cases[0].Origin);
    }

    @IsTest
    static void testTriggerLinksExistingProduct() {
        Test.setMock(HttpCalloutMock.class, new ComplaintCalloutMock());

        String extProductId = 'EXT-PROD-COMPLAINT-001';
        Product2 product = TestDataFactory.product().external(extProductId, 'ORG-TEST-001').create();

        String fakeCaseId = '500000000000002AAA';

        Test.startTest();
        EventBus.publish(new External_Complaint__e(
            Case_Id__c = fakeCaseId,
            Order_Id__c = '801000000000002AAA',
            Reason__c = 'External product complaint',
            Product_Ids__c = extProductId
        ));
        Test.stopTest();

        List<Case> cases = [SELECT Id FROM Case WHERE External_Case_Id__c = :fakeCaseId];
        Assert.areEqual(1, cases.size(), 'Should create one Case');

        List<Case_Order_Product__c> cops = [
            SELECT Id, Is_External__c, Product_Name__c
            FROM Case_Order_Product__c
            WHERE Case__c = :cases[0].Id
        ];
        Assert.areEqual(1, cops.size(), 'Should link one Case_Order_Product__c to the external product');
        Assert.isTrue(cops[0].Is_External__c, 'Should be marked as external');
        Assert.areEqual(product.Name, cops[0].Product_Name__c);
    }

    @IsTest
    static void testTriggerWithNoProductIds() {
        Test.setMock(HttpCalloutMock.class, new ComplaintCalloutMock());

        String fakeCaseId = '500000000000003AAA';

        Test.startTest();
        EventBus.publish(new External_Complaint__e(
            Case_Id__c = fakeCaseId,
            Order_Id__c = '801000000000003AAA',
            Reason__c = 'No products'
        ));
        Test.stopTest();

        List<Case> cases = [SELECT Id FROM Case WHERE External_Case_Id__c = :fakeCaseId];
        Assert.areEqual(1, cases.size(), 'Should create one Case even with no product IDs');

        List<Case_Order_Product__c> cops = [SELECT Id FROM Case_Order_Product__c WHERE Case__c = :cases[0].Id];
        Assert.areEqual(0, cops.size(), 'Should not create any Case_Order_Product__c when no product IDs');
    }
}
