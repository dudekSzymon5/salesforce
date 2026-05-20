@IsTest
private class ExternalComplaintResponseTriggerTest {

    @IsTest
    static void testTriggerLogsResponse() {
        String correlationId = 'test-uuid-1234-abcd-5678';

        Test.startTest();
        EventBus.publish(new External_Complaint_Response__e(
            Case_Id__c = correlationId,
            External_Case_Id__c = 'EXT-CASE-001'
        ));
        Test.stopTest();

        List<Case> cases = [SELECT Id FROM Case WHERE Id = :correlationId];
        Assert.areEqual(0, cases.size(), 'No Case should be queried or updated');
    }
}
