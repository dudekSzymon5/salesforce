trigger ExternalComplaintResponseTrigger on External_Complaint_Response__e (after insert) {

    Set<String> correlationIds = new Set<String>();
    for (External_Complaint_Response__e response : Trigger.new) {
        if (String.isNotBlank(response.Case_Id__c)) {
            correlationIds.add(response.Case_Id__c);
        }
    }

    Map<String, Order> ordersByCorrelationId = new Map<String, Order>();
    for (Order ord : [
            SELECT Id, ComplaintCaseId__c, External_Complaint_Correlation_Id__c
            FROM Order
            WHERE External_Complaint_Correlation_Id__c IN :correlationIds
    ]) {
        ordersByCorrelationId.put(ord.External_Complaint_Correlation_Id__c, ord);
    }

    String approvedFull    = Utils.EXTERNAL_COMPLAINT.RESPONSE_STATUS.APPROVED_FULL;
    String approvedPartial = Utils.EXTERNAL_COMPLAINT.RESPONSE_STATUS.APPROVED_PARTIAL;
    String rejectedStatus  = Utils.EXTERNAL_COMPLAINT.RESPONSE_STATUS.REJECTED;

    List<Case> casesToInsert = new List<Case>();
    Map<String, External_Complaint_Response__e> responseByCorrelationId = new Map<String, External_Complaint_Response__e>();

    for (External_Complaint_Response__e response : Trigger.new) {
        ErrorLogger.logInfo('ExternalComplaintResponseTrigger', 'Received response | correlationId: ' + response.Case_Id__c + ' | status: ' + response.Status__c);

        Boolean isApproved = response.Status__c == approvedFull || response.Status__c == approvedPartial;
        Boolean isRejected = response.Status__c == rejectedStatus;

        if (!isApproved && !isRejected) continue;

        Order targetOrder = ordersByCorrelationId.get(response.Case_Id__c);
        if (targetOrder == null) continue;

        casesToInsert.add(new Case(
                Order__c = targetOrder.Id,
                External_Case_Id__c = response.Case_Id__c,
                Has_External_Product__c = true,
                Refund_Status__c = isApproved ? Utils.ORDER_COMPLAINT.REFUND_STATUS.APPROVED : Utils.ORDER_COMPLAINT.REFUND_STATUS.REJECTED,
                Approved_Refund_Type__c = response.Final_Refund_Type__c,
                Refund_Amount__c = response.Final_Refund_Amount__c,
                Status = Utils.ORDER_COMPLAINT.CASE_STATUS.CLOSED,
                Origin = Utils.ORDER_COMPLAINT.CASE_ORIGIN.WEB
        ));
        responseByCorrelationId.put(response.Case_Id__c, response);
    }

    if (casesToInsert.isEmpty()) return;

    insert casesToInsert;

    Set<Id> localCaseIds = new Set<Id>();
    for (String correlationId : responseByCorrelationId.keySet()) {
        Order ord = ordersByCorrelationId.get(correlationId);
        if (ord.ComplaintCaseId__c != null) {
            localCaseIds.add(ord.ComplaintCaseId__c);
        }
    }
    Map<Id, Case> localCases = localCaseIds.isEmpty() ? new Map<Id, Case>() : new Map<Id, Case>([
            SELECT Id, Refund_Status__c, Refund_Amount__c
            FROM Case
            WHERE Id IN :localCaseIds
    ]);

    List<Order> ordersToUpdate = new List<Order>();
    for (Case newCase : casesToInsert) {
        External_Complaint_Response__e response = responseByCorrelationId.get(newCase.External_Case_Id__c);
        Order targetOrder = ordersByCorrelationId.get(newCase.External_Case_Id__c);
        Boolean isApproved = newCase.Refund_Status__c == Utils.ORDER_COMPLAINT.REFUND_STATUS.APPROVED;

        Order orderUpdate = new Order(
                Id = targetOrder.Id,
                Tracking_Case__c = newCase.Id,
                External_Complaint_Correlation_Id__c = null
        );

        if (isApproved) {
            if (targetOrder.ComplaintCaseId__c != null) {
                Case localCase = localCases.get(targetOrder.ComplaintCaseId__c);
                if (localCase != null && localCase.Refund_Status__c == Utils.ORDER_COMPLAINT.REFUND_STATUS.APPROVED) {
                    Decimal localAmount = localCase.Refund_Amount__c != null ? localCase.Refund_Amount__c : 0;
                    orderUpdate.Refund_Type__c = response.Final_Refund_Type__c;
                    orderUpdate.Refund_Amount__c = localAmount + response.Final_Refund_Amount__c;
                }
            } else {
                orderUpdate.Refund_Type__c = response.Final_Refund_Type__c;
                orderUpdate.Refund_Amount__c = response.Final_Refund_Amount__c;
                orderUpdate.ComplaintCaseId__c = newCase.Id;
            }
        }

        ordersToUpdate.add(orderUpdate);
    }

    if (!ordersToUpdate.isEmpty()) {
        update ordersToUpdate;
    }

    List<CustomNotificationType> notifTypes = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'Complaint_Decision' LIMIT 1];
    if (!notifTypes.isEmpty()) {
        String notifTypeId = notifTypes[0].Id;
        for (Case newCase : casesToInsert) {
            String status = newCase.Refund_Status__c == Utils.ORDER_COMPLAINT.REFUND_STATUS.APPROVED ? 'approved' : 'rejected';
            try {
                Messaging.CustomNotification notification = new Messaging.CustomNotification();
                notification.setNotificationTypeId(notifTypeId);
                notification.setTargetId(newCase.Id);
                notification.setTitle('Complaint Decision');
                notification.setBody('Your complaint refund has been ' + status + ' by the external system.');
                notification.send(new Set<String>{ newCase.OwnerId });
            } catch (Exception e) {
                ErrorLogger.log('ExternalComplaintResponseTrigger.notification', e);
            }
        }
    }
}
