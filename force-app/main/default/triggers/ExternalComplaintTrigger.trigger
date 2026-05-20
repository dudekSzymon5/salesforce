trigger ExternalComplaintTrigger on External_Complaint__e (after insert) {
    List<Case> casesToInsert = new List<Case>();

    for (External_Complaint__e ev : Trigger.new) {
        ErrorLogger.logInfo('ExternalComplaintTrigger', 'Received External_Complaint__e | Case_Id__c: ' + ev.Case_Id__c + ' | Order_Id__c: ' + ev.Order_Id__c);
        casesToInsert.add(new Case(
            Complaint_Reason__c = ev.Reason__c,
            External_Case_Id__c = ev.Case_Id__c,
            Refund_Status__c = Utils.ORDER_COMPLAINT.REFUND_STATUS.PENDING,
            Status = Utils.ORDER_COMPLAINT.CASE_STATUS.NEW_CASE,
            Origin = Utils.ORDER_COMPLAINT.CASE_ORIGIN.WEB
        ));
    }

    try {
        insert casesToInsert;
        ErrorLogger.logInfo('ExternalComplaintTrigger', 'Created ' + casesToInsert.size() + ' Case(s) from external complaint');
    } catch (Exception e) {
        ErrorLogger.log('ExternalComplaintTrigger', e);
        return;
    }

    try {
        for (Case aCase : casesToInsert) {
            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
            req.setObjectId(aCase.Id);
            req.setSubmitterId(UserInfo.getUserId());
            Approval.process(req);
        }
        ErrorLogger.logInfo('ExternalComplaintTrigger', 'Approval process submitted for ' + casesToInsert.size() + ' Case(s)');
    } catch (Exception e) {
        ErrorLogger.log('ExternalComplaintTrigger', e);
    }

    System.enqueueJob(new ComplaintResponseQueueable(casesToInsert, Trigger.new));
}
