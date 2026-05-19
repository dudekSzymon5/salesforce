trigger ExternalComplaintResponseTrigger on External_Complaint_Response__e (after insert) {
    List<Case> caseToUpdate = new List<Case>();
    for (External_Complaint_Response__e response : Trigger.new) {

        caseToUpdate.add(new Case(
            Id = response.Case_Id__c,
            External_Case_Id__c = response.External_Case_Id__c
        ));
    }
    update caseToUpdate;
}