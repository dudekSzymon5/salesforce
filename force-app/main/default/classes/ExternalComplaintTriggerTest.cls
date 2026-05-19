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
}
