trigger ExternalComplaintTrigger on External_Complaint__e (after insert) {
    List<Case> casesToInsert = new List<Case>();

    for (External_Complaint__e ev : Trigger.new) {
        ErrorLogger.logInfo('ExternalComplaintTrigger', 'Received External_Complaint__e | Case_Id__c: ' + ev.Case_Id__c + ' | Order_Id__c: ' + ev.Order_Id__c);
        casesToInsert.add(new Case(
            Complaint_Reason__c = ev.Reason__c,
            External_Case_Id__c = ev.Case_Id__c,
            Status = Utils.ORDER_COMPLAINT.CASE_STATUS.NEW_CASE,
            Origin = Utils.ORDER_COMPLAINT.CASE_ORIGIN.WEB
        ));
    }

    try {
        insert casesToInsert;
        ErrorLogger.logInfo('ExternalComplaintTrigger', 'Created ' + casesToInsert.size() + ' Case(s) from external complaint');

        for (Case c : casesToInsert) {
            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
            req.setObjectId(c.Id);
            req.setSubmitterId(UserInfo.getUserId());
            Approval.process(req);
        }
        ErrorLogger.logInfo('ExternalComplaintTrigger', 'Approval process submitted for ' + casesToInsert.size() + ' Case(s)');

        System.enqueueJob(new ComplaintResponseQueueable(casesToInsert, Trigger.new));
    } catch (Exception e) {
        ErrorLogger.log('ExternalComplaintTrigger', e);
    }
}
