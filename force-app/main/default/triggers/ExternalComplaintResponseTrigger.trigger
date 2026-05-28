trigger ExternalComplaintResponseTrigger on External_Complaint_Response__e (after insert) {

    Set<String> correlationIds = new Set<String>();
    for (External_Complaint_Response__e response : Trigger.new) {
        if (String.isNotBlank(response.Case_Id__c)) correlationIds.add(response.Case_Id__c);
    }

    Map<String, Order> ordersByCorrelationId = new Map<String, Order>();
    for (Order order : [
            SELECT Id, External_Complaint_Correlation_Id__c, Pending_Complaint_JSON__c
            FROM Order
            WHERE External_Complaint_Correlation_Id__c IN :correlationIds
    ]) {
        ordersByCorrelationId.put(order.External_Complaint_Correlation_Id__c, order);
    }

    String approvedFull    = Utils.EXTERNAL_COMPLAINT.RESPONSE_STATUS.APPROVED_FULL;
    String approvedPartial = Utils.EXTERNAL_COMPLAINT.RESPONSE_STATUS.APPROVED_PARTIAL;
    String rejectedStatus  = Utils.EXTERNAL_COMPLAINT.RESPONSE_STATUS.REJECTED;

    Map<String, OrderComplaintPayload.PendingComplaint> pendingDataByCorrelationId = new Map<String, OrderComplaintPayload.PendingComplaint>();
    Map<String, External_Complaint_Response__e> responseByCorrelationId = new Map<String, External_Complaint_Response__e>();
    Set<Id> allLocalItemIds = new Set<Id>();
    Set<String> allExternalProductIds = new Set<String>();

    for (External_Complaint_Response__e response : Trigger.new) {
        ErrorLogger.logInfo('ExternalComplaintResponseTrigger', 'Received response | payload: ' + JSON.serialize(response));

        Boolean isApproved = response.Status__c == approvedFull || response.Status__c == approvedPartial;
        Boolean isRejected = response.Status__c == rejectedStatus;
        if (!isApproved && !isRejected) {
            continue;
        }

        Order targetOrder = ordersByCorrelationId.get(response.Case_Id__c);
        if (targetOrder == null || String.isBlank(targetOrder.Pending_Complaint_JSON__c)) {
            continue;
        }

        OrderComplaintPayload.PendingComplaint pendingData = (OrderComplaintPayload.PendingComplaint) JSON.deserialize(targetOrder.Pending_Complaint_JSON__c, OrderComplaintPayload.PendingComplaint.class);
        pendingDataByCorrelationId.put(response.Case_Id__c, pendingData);
        responseByCorrelationId.put(response.Case_Id__c, response);

        if (pendingData.localItemIds != null) {
            allLocalItemIds.addAll(pendingData.localItemIds);
        }

        String lineItemsSourceForIds = String.isNotBlank(response.Line_Items_JSON__c)
                ? response.Line_Items_JSON__c
                : pendingData.externalLineItemsJson;
        if (String.isNotBlank(lineItemsSourceForIds)) {
            List<OrderComplaintPayload.LineItem> lineItems = (List<OrderComplaintPayload.LineItem>) JSON.deserialize(lineItemsSourceForIds, List<OrderComplaintPayload.LineItem>.class);
            for (OrderComplaintPayload.LineItem lineItem : lineItems) {
                if (String.isNotBlank(lineItem.productId)) allExternalProductIds.add(lineItem.productId);
            }
        }
    }

    if (pendingDataByCorrelationId.isEmpty()) {
        return;
    }

    Map<Id, OrderItem> orderItemsById = allLocalItemIds.isEmpty() ? new Map<Id, OrderItem>() : new Map<Id, OrderItem>([
            SELECT Id, Product2.Name
            FROM OrderItem
            WHERE Id IN :allLocalItemIds
    ]);

    Map<String, Product2> productsByExternalId = new Map<String, Product2>();
    if (!allExternalProductIds.isEmpty()) {
        for (Product2 product : [
            SELECT Id, Name, External_Product_Id__c 
            FROM Product2 
            WHERE External_Product_Id__c IN :allExternalProductIds
        ]) {
            productsByExternalId.put(product.External_Product_Id__c, product);
        }
    }

    List<Case> casesToInsert = new List<Case>();
    List<String> correlationIdsForCases = new List<String>();

    for (String correlationId : responseByCorrelationId.keySet()) {
        External_Complaint_Response__e response = responseByCorrelationId.get(correlationId);
        OrderComplaintPayload.PendingComplaint pendingData = pendingDataByCorrelationId.get(correlationId);
        Order targetOrder = ordersByCorrelationId.get(correlationId);

        Boolean isApproved = response.Status__c == approvedFull || response.Status__c == approvedPartial;
        Boolean isMixed = pendingData.localItemIds != null && !pendingData.localItemIds.isEmpty();

        Case newCase = new Case(
                Order__c = targetOrder.Id,
                Has_External_Product__c = true,
                Complaint_Reason__c = pendingData.reason,
                Expected_Refund_Type__c = pendingData.expectedRefundType,
                Origin = Utils.ORDER_COMPLAINT.CASE_ORIGIN.WEB
        );

        if (isMixed && isApproved) {
            newCase.Refund_Status__c = Utils.ORDER_COMPLAINT.REFUND_STATUS.PENDING;
            newCase.Status = Utils.ORDER_COMPLAINT.CASE_STATUS.NEW_CASE;
            Decimal externalRefundAmount = response.Final_Refund_Amount__c;
            if (externalRefundAmount == null && String.isNotBlank(response.Line_Items_JSON__c)) {
                externalRefundAmount = 0;
                List<OrderComplaintPayload.LineItem> li = (List<OrderComplaintPayload.LineItem>) JSON.deserialize(response.Line_Items_JSON__c, List<OrderComplaintPayload.LineItem>.class);
                for (OrderComplaintPayload.LineItem item : li) externalRefundAmount += item.refundAmount != null ? item.refundAmount : 0;
            }
            newCase.External_Refund_Amount__c = externalRefundAmount;
        } else {
            newCase.Refund_Status__c = isApproved ? Utils.ORDER_COMPLAINT.REFUND_STATUS.APPROVED : Utils.ORDER_COMPLAINT.REFUND_STATUS.REJECTED;
            newCase.Status = Utils.ORDER_COMPLAINT.CASE_STATUS.CLOSED;
            if (isApproved && !isMixed) {
                String derivedRefundType = String.isNotBlank(response.Final_Refund_Type__c)
                        ? response.Final_Refund_Type__c
                        : (response.Status__c == approvedFull ? Utils.ORDER_COMPLAINT.REFUND_TYPE.FULL : Utils.ORDER_COMPLAINT.REFUND_TYPE.PARTIAL);
                newCase.Approved_Refund_Type__c = derivedRefundType;

                Decimal caseRefundAmount = response.Final_Refund_Amount__c;
                if (caseRefundAmount == null && String.isNotBlank(response.Line_Items_JSON__c)) {
                    caseRefundAmount = 0;
                    List<OrderComplaintPayload.LineItem> li = (List<OrderComplaintPayload.LineItem>) JSON.deserialize(response.Line_Items_JSON__c, List<OrderComplaintPayload.LineItem>.class);
                    for (OrderComplaintPayload.LineItem item : li) caseRefundAmount += item.refundAmount != null ? item.refundAmount : 0;
                }
                newCase.Refund_Amount__c = caseRefundAmount;
                newCase.External_Refund_Amount__c = caseRefundAmount;
            }
        }

        casesToInsert.add(newCase);
        correlationIdsForCases.add(correlationId);
    }

    if (casesToInsert.isEmpty()) return;
    insert casesToInsert;

    List<Case_Order_Product__c> caseOrderProducts = new List<Case_Order_Product__c>();
    List<Order> ordersToUpdate = new List<Order>();
    List<Case> mixedCasesForApproval = new List<Case>();

    for (Integer i = 0; i < casesToInsert.size(); i++) {
        Case newCase = casesToInsert[i];
        String correlationId = correlationIdsForCases[i];
        External_Complaint_Response__e response = responseByCorrelationId.get(correlationId);
        OrderComplaintPayload.PendingComplaint pendingData = pendingDataByCorrelationId.get(correlationId);
        Order targetOrder = ordersByCorrelationId.get(correlationId);

        Boolean isApproved = response.Status__c == approvedFull || response.Status__c == approvedPartial;
        Boolean isMixed = pendingData.localItemIds != null && !pendingData.localItemIds.isEmpty();

        if (isMixed) {
            for (Id localItemId : pendingData.localItemIds) {
                OrderItem orderItem = orderItemsById.get(localItemId);
                if (orderItem != null) {
                    caseOrderProducts.add(new Case_Order_Product__c(
                            Case__c = newCase.Id,
                            Order__c = targetOrder.Id,
                            Order_Product__c = orderItem.Id,
                            Product_Name__c = orderItem.Product2.Name,
                            Is_External__c = false
                    ));
                }
            }
            if (isApproved) {
                mixedCasesForApproval.add(newCase);
            }
        }

        String lineItemsSource = String.isNotBlank(response.Line_Items_JSON__c)
                ? response.Line_Items_JSON__c
                : pendingData.externalLineItemsJson;
        if (String.isNotBlank(lineItemsSource)) {
            List<OrderComplaintPayload.LineItem> lineItems = (List<OrderComplaintPayload.LineItem>) JSON.deserialize(lineItemsSource, List<OrderComplaintPayload.LineItem>.class);
            for (OrderComplaintPayload.LineItem lineItem : lineItems) {
                Product2 product = productsByExternalId.get(lineItem.productId);
                if (product != null) {
                    caseOrderProducts.add(new Case_Order_Product__c(
                            Case__c = newCase.Id,
                            Order__c = targetOrder.Id,
                            Product_Name__c = product.Name,
                            Refund_Amount__c = isApproved && lineItem.refundAmount != null ? lineItem.refundAmount : 0,
                            Is_External__c = true
                    ));
                }
            }
        }

        Order orderUpdate = new Order(
                Id = targetOrder.Id,
                ComplaintCaseId__c = newCase.Id,
                External_Complaint_Correlation_Id__c = null,
                Pending_Complaint_JSON__c = null
        );
        if (!isMixed && isApproved) {
            Decimal totalRefund = response.Final_Refund_Amount__c;
            if (totalRefund == null && String.isNotBlank(response.Line_Items_JSON__c)) {
                totalRefund = 0;
                List<OrderComplaintPayload.LineItem> lineItems = (List<OrderComplaintPayload.LineItem>) JSON.deserialize(response.Line_Items_JSON__c, List<OrderComplaintPayload.LineItem>.class);
                for (OrderComplaintPayload.LineItem li : lineItems) {
                    totalRefund += li.refundAmount != null ? li.refundAmount : 0;
                }
            }
            orderUpdate.Refund_Type__c = String.isNotBlank(response.Final_Refund_Type__c)
                    ? response.Final_Refund_Type__c
                    : (response.Status__c == approvedFull ? Utils.ORDER_COMPLAINT.REFUND_TYPE.FULL : Utils.ORDER_COMPLAINT.REFUND_TYPE.PARTIAL);
            orderUpdate.Refund_Amount__c = totalRefund;
            orderUpdate.Refund_Status__c = Utils.ORDER_COMPLAINT.REFUND_STATUS.APPROVED;
        } else if (!isApproved) {
            orderUpdate.Refund_Status__c = Utils.ORDER_COMPLAINT.REFUND_STATUS.REJECTED;
        }
        ordersToUpdate.add(orderUpdate);
    }

    if (!caseOrderProducts.isEmpty()) {
        insert caseOrderProducts;
    }
    if (!ordersToUpdate.isEmpty()) {
        update ordersToUpdate;
    }

    for (Case mixedCase : mixedCasesForApproval) {
        try {
            Approval.ProcessSubmitRequest approvalRequest = new Approval.ProcessSubmitRequest();
            approvalRequest.setObjectId(mixedCase.Id);
            approvalRequest.setSubmitterId(UserInfo.getUserId());
            Approval.process(approvalRequest);
            ErrorLogger.logInfo('ExternalComplaintResponseTrigger', 'Approval submitted for mixed Case: ' + mixedCase.Id);
        } catch (Exception e) {
            ErrorLogger.log('ExternalComplaintResponseTrigger', e);
        }
    }

    Map<Id, Case> closedCasesWithOwner = new Map<Id, Case>();
    for (Case c : [SELECT Id, OwnerId FROM Case WHERE Id IN :casesToInsert AND Status = :Utils.ORDER_COMPLAINT.CASE_STATUS.CLOSED]) {
        closedCasesWithOwner.put(c.Id, c);
    }

    List<CustomNotificationType> notifTypes = [
        SELECT Id
        FROM CustomNotificationType
        WHERE DeveloperName = :Utils.ORDER_COMPLAINT.NOTIFICATION_TYPE.COMPLAINT_DECISION
        LIMIT 1
    ];
    if (!notifTypes.isEmpty()) {
        String notifTypeId = notifTypes[0].Id;
        for (Case newCase : casesToInsert) {
            if (newCase.Status != Utils.ORDER_COMPLAINT.CASE_STATUS.CLOSED) continue;
            Case caseWithOwner = closedCasesWithOwner.get(newCase.Id);
            if (caseWithOwner == null || String.isBlank(caseWithOwner.OwnerId)) continue;
            String refundStatus = newCase.Refund_Status__c == Utils.ORDER_COMPLAINT.REFUND_STATUS.APPROVED ? 'approved' : 'rejected';
            try {
                Messaging.CustomNotification notification = new Messaging.CustomNotification();
                notification.setNotificationTypeId(notifTypeId);
                notification.setTargetId(newCase.Id);
                notification.setTitle('Complaint Decision');
                notification.setBody('Your complaint refund has been ' + refundStatus + ' by the external system.');
                notification.send(new Set<String>{ caseWithOwner.OwnerId });
            } catch (Exception e) {
                ErrorLogger.log('ExternalComplaintResponseTrigger.notification', e);
            }
        }
    }
}
