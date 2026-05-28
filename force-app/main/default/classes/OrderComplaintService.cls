public with sharing class OrderComplaintService {

    public class ComplaintResult {
        @AuraEnabled public String caseId;
        @AuraEnabled public String correlationId;
    }

    public static List<OrderItem> getOrderProducts(Id orderId) {
        Set<Id> excludedIds = new Set<Id>();

        for (Case_Order_Product__c cop : [
            SELECT Order_Product__c
            FROM Case_Order_Product__c
            WHERE Order__c = :orderId
            AND Order_Product__c != null
        ]) {
            excludedIds.add(cop.Order_Product__c);
        }

        Order ord = [SELECT Pending_Complaint_JSON__c FROM Order WHERE Id = :orderId];
        if (String.isNotBlank(ord.Pending_Complaint_JSON__c)) {
            try {
                OrderComplaintPayload.PendingComplaint pending =
                    (OrderComplaintPayload.PendingComplaint) JSON.deserialize(
                        ord.Pending_Complaint_JSON__c, OrderComplaintPayload.PendingComplaint.class
                    );
                if (pending.localItemIds != null) {
                    excludedIds.addAll(pending.localItemIds);
                }
                if (pending.externalItemIds != null) {
                    excludedIds.addAll(pending.externalItemIds);
                }
            } catch (Exception e) {
                ErrorLogger.log('OrderComplaintService.getOrderProducts', e, orderId);
            }
        }

        return [
            SELECT Id, Product2Id, Product2.Name, Product2.Is_External__c, Quantity, UnitPrice
            FROM OrderItem
            WHERE OrderId = :orderId
            AND Id NOT IN :excludedIds
        ];
    }

    public static ComplaintResult submitComplaint(Id orderId, String reason, String expectedRefundType, List<Id> selectedOrderItemsId) {
        Order order = [
            SELECT Status, ComplaintCaseId__c, External_Complaint_Correlation_Id__c
            FROM Order
            WHERE Id = :orderId
        ];
        if (order.Status != 'Activated') {
            throw new AuraHandledException('Complaint can only be submitted for an Activated Order.');
        }

        List<OrderItem> getItems = [
                SELECT Id, Product2Id, Product2.Name, Product2.Is_External__c, Product2.External_Product_Id__c, Quantity, UnitPrice
                FROM OrderItem
                WHERE Id IN :selectedOrderItemsId
        ];

        Boolean hasExternal = false;
        Boolean hasLocal = false;
        List<String> externalProductIds = new List<String>();
        List<OrderItem> externalItems = new List<OrderItem>();
        List<OrderItem> localItems = new List<OrderItem>();
        Decimal refundAmount = 0;

        for (OrderItem orderItem : getItems) {
            if (orderItem.Product2.Is_External__c) {
                hasExternal = true;
                externalProductIds.add(orderItem.Product2.External_Product_Id__c);
                refundAmount += orderItem.UnitPrice * orderItem.Quantity;
                externalItems.add(orderItem);
            } else {
                hasLocal = true;
                localItems.add(orderItem);
            }
        }

        ComplaintResult result = new ComplaintResult();
        String correlationId = null;
        String lineItemsJson = null;

        if (hasExternal && String.isNotBlank(order.External_Complaint_Correlation_Id__c)) {
            throw new AuraHandledException('An external complaint is already pending for this order. Please wait for it to be processed.');
        }

        if (hasExternal) {
            List<OrderComplaintPayload.LineItem> lineItems = new List<OrderComplaintPayload.LineItem>();
            for (OrderItem item : externalItems) {
                OrderComplaintPayload.LineItem lineItem = new OrderComplaintPayload.LineItem();
                lineItem.productId = item.Product2.External_Product_Id__c;
                lineItem.refundAmount = item.UnitPrice * item.Quantity;
                lineItem.refundType = expectedRefundType;
                lineItems.add(lineItem);
            }
            lineItemsJson = JSON.serialize(lineItems);

            correlationId = generateUUID();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(Utils.EXTERNAL_COMPLAINT.API.FORWARD_ENDPOINT);
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json');
            request.setTimeout(10000);
            request.setBody(new OrderComplaintPayload.OrderComplaintController(
                    correlationId,
                    orderId,
                    String.join(externalProductIds, ','),
                    expectedRefundType + ' - ' + reason,
                    refundAmount,
                    lineItemsJson
            ).toJSON());

            HttpResponse response = new Http().send(request);

            if (response.getStatusCode() != 200 && response.getStatusCode() != 201) {
                throw new AuraHandledException('External system rejected the complaint:' + response.getStatusCode());
            }

            result.correlationId = correlationId;
            ErrorLogger.logInfo('OrderComplaintService.submitComplaint', 'External complaint forwarded | correlationId: ' + correlationId + ' | products: ' + String.join(externalProductIds, ','));
        }

        if (hasLocal && !hasExternal) {
            Case aCase = new Case(
                    Order__c = orderId,
                    Complaint_Reason__c = reason,
                    Expected_Refund_Type__c = expectedRefundType,
                    Has_External_Product__c = false,
                    Refund_Status__c = Utils.ORDER_COMPLAINT.REFUND_STATUS.PENDING,
                    Status = Utils.ORDER_COMPLAINT.CASE_STATUS.NEW_CASE,
                    Origin = Utils.ORDER_COMPLAINT.CASE_ORIGIN.WEB
            );
            insert aCase;
            ErrorLogger.logInfo('OrderComplaintService.submitComplaint', 'Case created: ' + aCase.Id + ' for Order: ' + orderId);

            List<Case_Order_Product__c> caseOrderProducts = new List<Case_Order_Product__c>();
            for (OrderItem orderItem : localItems) {
                caseOrderProducts.add(new Case_Order_Product__c(
                        Case__c = aCase.Id,
                        Order__c = orderId,
                        Order_Product__c = orderItem.Id,
                        Product_Name__c = orderItem.Product2.Name,
                        Is_External__c = false
                ));
            }
            insert caseOrderProducts;

            Order orderToUpdate = new Order(
                    Id = orderId,
                    ComplaintCaseId__c = aCase.Id,
                    Tracking_Case__c = null,
                    Refund_Status__c = Utils.ORDER_COMPLAINT.REFUND_STATUS.PENDING
            );
            // Preserve pending external complaint data if one is still in flight
            if (String.isBlank(order.External_Complaint_Correlation_Id__c)) {
                orderToUpdate.External_Complaint_Correlation_Id__c = null;
                orderToUpdate.Pending_Complaint_JSON__c = null;
            }
            update orderToUpdate;

            Approval.ProcessSubmitRequest approvalRequest = new Approval.ProcessSubmitRequest();
            approvalRequest.setObjectId(aCase.Id);
            approvalRequest.setSubmitterId(UserInfo.getUserId());
            Approval.process(approvalRequest);
            ErrorLogger.logInfo('OrderComplaintService.submitComplaint', 'Approval process submitted for Case: ' + aCase.Id);

            result.caseId = aCase.Id;
        } else if (hasExternal) {
            OrderComplaintPayload.PendingComplaint pendingData = new OrderComplaintPayload.PendingComplaint();
            pendingData.reason = reason;
            pendingData.expectedRefundType = expectedRefundType;
            pendingData.externalLineItemsJson = lineItemsJson;
            pendingData.localItemIds = new List<Id>();
            for (OrderItem orderItem : localItems) {
                pendingData.localItemIds.add(orderItem.Id);
            }
            pendingData.externalItemIds = new List<Id>();
            for (OrderItem orderItem : externalItems) {
                pendingData.externalItemIds.add(orderItem.Id);
            }

            update new Order(
                    Id = orderId,
                    External_Complaint_Correlation_Id__c = correlationId,
                    Tracking_Case__c = null,
                    ComplaintCaseId__c = null,
                    Pending_Complaint_JSON__c = JSON.serialize(pendingData),
                    Refund_Status__c = Utils.ORDER_COMPLAINT.REFUND_STATUS.PENDING
            );
        }

        return result;
    }

    private static String generateUUID() {
        String hex = EncodingUtil.convertToHex(Crypto.generateAesKey(128));
        return hex.substring(0, 8) + '-' + hex.substring(8, 12) + '-' + hex.substring(12, 16) + '-' + hex.substring(16, 20) + '-' + hex.substring(20);
    }
}
