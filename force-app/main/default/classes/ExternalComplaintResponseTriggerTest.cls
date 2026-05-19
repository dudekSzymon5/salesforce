@IsTest
private class ExternalComplaintResponseTriggerTest {

    @IsTest
    static void testTriggerUpdatesCaseExternalId() {
        Case aCase = new Case(
            Status = Utils.ORDER_COMPLAINT.CASE_STATUS.NEW_CASE,
            Origin = Utils.ORDER_COMPLAINT.CASE_ORIGIN.WEB
        );
        insert aCase;

        Test.startTest();
        EventBus.publish(new External_Complaint_Response__e(
            Case_Id__c = aCase.Id,
            External_Case_Id__c = 'EXT-CASE-001'
        ));
        Test.stopTest();

        Case updated = [SELECT External_Case_Id__c FROM Case WHERE Id = :aCase.Id];
        Assert.areEqual('EXT-CASE-001', updated.External_Case_Id__c);
    }
}
