trigger ExternalComplaintResponseTrigger on External_Complaint_Response__e (after insert) {
    List<Case> caseToUpdate = new List<Case>();
    for (External_Complaint_Response__e response : Trigger.new) {
        ErrorLogger.logInfo('ExternalComplaintResponseTrigger', 'Received response for Case: ' + response.Case_Id__c + ', externalCaseId: ' + response.External_Case_Id__c);
        caseToUpdate.add(new Case(
            Id = response.Case_Id__c,
            External_Case_Id__c = response.External_Case_Id__c
        ));
    }
    try {
        update caseToUpdate;
        ErrorLogger.logInfo('ExternalComplaintResponseTrigger', 'Updated ' + caseToUpdate.size() + ' Case(s) with external case ID');
    } catch (Exception e) {
        ErrorLogger.log('ExternalComplaintResponseTrigger', e);
    }
}