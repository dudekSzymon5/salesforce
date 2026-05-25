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
    Map<Id, Order> ordersToUpdateById = new Map<Id, Order>();

    String approvedFull    = Utils.EXTERNAL_COMPLAINT.RESPONSE_STATUS.APPROVED_FULL;
    String approvedPartial = Utils.EXTERNAL_COMPLAINT.RESPONSE_STATUS.APPROVED_PARTIAL;
    String rejectedStatus  = Utils.EXTERNAL_COMPLAINT.RESPONSE_STATUS.REJECTED;

    Set<Id> orderIdsToQuery = new Set<Id>();
    for (Case aCase : casesByCorrelationId.values()) {
        if (aCase.Order__c != null) orderIdsToQuery.add(aCase.Order__c);
    }
    Map<Id, Order> currentOrders = new Map<Id, Order>([SELECT Id, ComplaintCaseId__c, Tracking_Case__c FROM Order WHERE Id IN :orderIdsToQuery]);

    Set<Id> localCaseIds = new Set<Id>();
    for (Order ord : currentOrders.values()) {
        if (ord.Tracking_Case__c != null && ord.ComplaintCaseId__c != null) {
            localCaseIds.add(ord.ComplaintCaseId__c);
        }
    }
    Map<Id, Case> localCases = localCaseIds.isEmpty() ? new Map<Id, Case>() : new Map<Id, Case>([
            SELECT Id, Refund_Status__c, Refund_Amount__c
            FROM Case
            WHERE Id IN :localCaseIds
    ]);

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
                ? Utils.ORDER_COMPLAINT.REFUND_STATUS.APPROVED
                : Utils.ORDER_COMPLAINT.REFUND_STATUS.REJECTED;
        aCase.Approved_Refund_Type__c = response.Final_Refund_Type__c;
        aCase.Refund_Amount__c = response.Final_Refund_Amount__c;
        casesToUpdate.add(aCase);

        if (aCase.Order__c != null && isApproved) {
            Order currentOrder = currentOrders.get(aCase.Order__c);
            if (currentOrder != null) {
                if (currentOrder.Tracking_Case__c == null) {
                    ordersToUpdateById.put(aCase.Order__c, new Order(
                            Id = aCase.Order__c,
                            Refund_Type__c = response.Final_Refund_Type__c,
                            Refund_Amount__c = response.Final_Refund_Amount__c
                    ));
                } else {
                    Case localCase = localCases.get(currentOrder.ComplaintCaseId__c);
                    if (localCase != null && localCase.Refund_Status__c == Utils.ORDER_COMPLAINT.REFUND_STATUS.APPROVED) {
                        Decimal localAmount = localCase.Refund_Amount__c != null ? localCase.Refund_Amount__c : 0;
                        ordersToUpdateById.put(aCase.Order__c, new Order(
                                Id = aCase.Order__c,
                                Refund_Type__c = response.Final_Refund_Type__c,
                                Refund_Amount__c = localAmount + response.Final_Refund_Amount__c
                        ));
                    }
                }
            }
        }
    }

    if (!casesToUpdate.isEmpty()) {
        update casesToUpdate;
    }
    if (!ordersToUpdateById.isEmpty()) {
        update ordersToUpdateById.values();
    }

    List<CustomNotificationType> notifTypes = [
        SELECT Id 
        FROM CustomNotificationType 
        WHERE DeveloperName = 'Complaint_Decision' 
        LIMIT 1
    ];
    if (!notifTypes.isEmpty() && !casesToUpdate.isEmpty()) {
        String notifTypeId = notifTypes[0].Id;
        for (Case aCase : casesToUpdate) {
            String status = aCase.Refund_Status__c == Utils.ORDER_COMPLAINT.REFUND_STATUS.APPROVED ? 'approved' : 'rejected';
            try {
                Messaging.CustomNotification notification = new Messaging.CustomNotification();
                notification.setNotificationTypeId(notifTypeId);
                notification.setTargetId(aCase.Id);
                notification.setTitle('Complaint Decision');
                notification.setBody('Your complaint refund has been ' + status + ' by the external system.');
                notification.send(new Set<String>{ aCase.OwnerId });
            } catch (Exception e) {
                ErrorLogger.log('ExternalComplaintResponseTrigger.notification', e);
            }
        }
    }
}
