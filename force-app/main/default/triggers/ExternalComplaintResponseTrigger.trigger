trigger ExternalComplaintResponseTrigger on External_Complaint_Response__e (after insert) {
    Set<String> correlationIds = new Set<String>();
    for (External_Complaint_Response__e response : Trigger.new) {
        if (String.isNotBlank(response.Case_Id__c)) {
            correlationIds.add(response.Case_Id__c);
        }
    }

    Map<String, Case> casesByCorrelationId = new Map<String, Case>();
    for (Case c : [
            SELECT Id, External_Case_Id__c, Order__c
            FROM Case
            WHERE External_Case_Id__c IN :correlationIds
    ]) {
        casesByCorrelationId.put(c.External_Case_Id__c, c);
    }

    List<Case> casesToUpdate = new List<Case>();
    List<Order> ordersToUpdate = new List<Order>();

    String approvedFull    = Utils.EXTERNAL_COMPLAINT.RESPONSE_STATUS.APPROVED_FULL;
    String approvedPartial = Utils.EXTERNAL_COMPLAINT.RESPONSE_STATUS.APPROVED_PARTIAL;
    String rejectedStatus  = Utils.EXTERNAL_COMPLAINT.RESPONSE_STATUS.REJECTED;

    for (External_Complaint_Response__e response : Trigger.new) {
        ErrorLogger.logInfo('ExternalComplaintResponseTrigger', 'Received response | correlationId: ' + response.Case_Id__c + ' | status: ' + response.Status__c);

        Boolean isApproved = response.Status__c == approvedFull || response.Status__c == approvedPartial;
        Boolean isRejected = response.Status__c == rejectedStatus;

        if (!isApproved && !isRejected) {
            continue;
        }

        Case aCase = casesByCorrelationId.get(response.Case_Id__c);
        if (aCase == null) continue;

        aCase.Refund_Status__c = isApproved
                ? Utils.EXTERNAL_COMPLAINT.RESPONSE_STATUS.APPROVED
                : Utils.EXTERNAL_COMPLAINT.RESPONSE_STATUS.REJECTED;
        aCase.Approved_Refund_Type__c = response.Final_Refund_Type__c;
        aCase.Refund_Amount__c = response.Final_Refund_Amount__c;
        casesToUpdate.add(aCase);

        if (aCase.Order__c != null && isApproved) {
            ordersToUpdate.add(new Order(
                    Id = aCase.Order__c,
                    Refund_Type__c = response.Final_Refund_Type__c,
                    Refund_Amount__c = response.Final_Refund_Amount__c
            ));
        }
    }

    if (!casesToUpdate.isEmpty()) {
        update casesToUpdate;
    }
    if (!ordersToUpdate.isEmpty()) {
        update ordersToUpdate;
    }
}
