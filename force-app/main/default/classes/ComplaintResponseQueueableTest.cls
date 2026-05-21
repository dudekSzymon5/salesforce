@IsTest
private class ComplaintResponseQueueableTest {

    private static final String SUCCESS_BODY = '{"id":"e02xx0000000001AAA","success":true,"errors":[]}';

    @TestSetup
    static void makeData() {
        TriggerBase.bypass('Case');

        Case aCase = new Case(Status = 'New', Origin = 'Web');
        insert aCase;
        TriggerBase.clearBypass('Case');
    }

    @IsTest
    static void testComplaintResponseSuccess() {
        Test.setMock(HttpCalloutMock.class, new TestDataFactory.HttpMock(201, SUCCESS_BODY));
        Case aCase = [
                SELECT Id
                FROM Case
                LIMIT 1
        ];

        External_Complaint__e externalComplaint = new External_Complaint__e(
            Case_Id__c = 'test-correlation-id',
            Order_Id__c = '801000000000001AAA'
        );

        Test.startTest();
        System.enqueueJob(new ComplaintResponseQueueable(
            new List<Case>{ aCase },
            new List<External_Complaint__e>{ externalComplaint }
        ));
        Test.stopTest();
    }

    @IsTest
    static void testComplaintResponseError() {
        Test.setMock(HttpCalloutMock.class, new TestDataFactory.HttpMock(500, '{"error":"Internal Server Error"}'));
        Case aCase = [
                SELECT Id
                FROM Case
                LIMIT 1
        ];

        External_Complaint__e externalComplaint = new External_Complaint__e(
            Case_Id__c = 'test-correlation-id',
            Order_Id__c = '801000000000001AAA'
        );

        Test.startTest();
        System.enqueueJob(new ComplaintResponseQueueable(
            new List<Case>{ aCase },
            new List<External_Complaint__e>{ externalComplaint }
        ));
        Test.stopTest();
    }
}
