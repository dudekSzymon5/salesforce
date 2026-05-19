@IsTest
private class ComplaintQueueableTest {

    private static final String SUCCESS_BODY = '{"id":"e02xx0000000001AAA","success":true,"errors":[]}';

    @IsTest
    static void testComplaintForwarderSuccess() {
        Test.setMock(HttpCalloutMock.class, new TestDataFactory.HttpMock(201, SUCCESS_BODY));

        External_Complaint__e ev = new External_Complaint__e(
            Order_Id__c = '801000000000001AAA',
            Case_Id__c = '500000000000001AAA',
            Reason__c = 'Test reason',
            Product_Ids__c = '01t000000000001AAA'
        );

        Test.startTest();
        System.enqueueJob(new ComplaintForwarderQueueable(new List<External_Complaint__e>{ ev }));
        Test.stopTest();
    }

    @IsTest
    static void testComplaintForwarderError() {
        Test.setMock(HttpCalloutMock.class, new TestDataFactory.HttpMock(500, '{"error":"Internal Server Error"}'));

        External_Complaint__e ev = new External_Complaint__e(
            Order_Id__c = '801000000000001AAA',
            Case_Id__c = '500000000000001AAA',
            Reason__c = 'Test reason',
            Product_Ids__c = '01t000000000001AAA'
        );

        Test.startTest();
        System.enqueueJob(new ComplaintForwarderQueueable(new List<External_Complaint__e>{ ev }));
        Test.stopTest();
    }

    @IsTest
    static void testComplaintResponseSuccess() {
        Test.setMock(HttpCalloutMock.class, new TestDataFactory.HttpMock(201, SUCCESS_BODY));

        Case aCase = new Case(Status = 'New', Origin = 'Web');
        insert aCase;

        External_Complaint__e ev = new External_Complaint__e(
            Case_Id__c = '500000000000001AAA',
            Order_Id__c = '801000000000001AAA',
            Reason__c = 'Test reason',
            Product_Ids__c = '01t000000000001AAA'
        );

        Test.startTest();
        System.enqueueJob(new ComplaintResponseQueueable(
            new List<Case>{ aCase },
            new List<External_Complaint__e>{ ev }
        ));
        Test.stopTest();
    }

    @IsTest
    static void testComplaintResponseError() {
        Test.setMock(HttpCalloutMock.class, new TestDataFactory.HttpMock(500, '{"error":"Internal Server Error"}'));

        Case aCase = new Case(Status = 'New', Origin = 'Web');
        insert aCase;

        External_Complaint__e ev = new External_Complaint__e(
            Case_Id__c = '500000000000001AAA',
            Order_Id__c = '801000000000001AAA',
            Reason__c = 'Test reason',
            Product_Ids__c = '01t000000000001AAA'
        );

        Test.startTest();
        System.enqueueJob(new ComplaintResponseQueueable(
            new List<Case>{ aCase },
            new List<External_Complaint__e>{ ev }
        ));
        Test.stopTest();
    }
}
