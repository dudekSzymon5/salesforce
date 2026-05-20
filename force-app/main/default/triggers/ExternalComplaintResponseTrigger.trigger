trigger ExternalComplaintResponseTrigger on External_Complaint_Response__e (after insert) {
    for (External_Complaint_Response__e response : Trigger.new) {
        ErrorLogger.logInfo('ExternalComplaintResponseTrigger', 'Received response | correlationId: ' + response.Case_Id__c + ', externalCaseId: ' + response.External_Case_Id__c);
    }
}
