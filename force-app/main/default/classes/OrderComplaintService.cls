public with sharing class OrderComplaintService {

    public class ComplaintResult {
        @AuraEnabled public String caseId;
        @AuraEnabled public String correlationId;
    }

    public static List<Case_Order_Product__c> getCaseProducts(Id caseId) {
        return [
                SELECT Id, Product_Name__c, Order_Product__r.UnitPrice, Order_Product__r.Quantity, Refund_Amount__c, Is_External__c
                FROM Case_Order_Product__c
                WHERE Case__c = :caseId
                AND ((Is_External__c = false AND Order_Product__c != null) OR Is_External__c = true)
        ];
    }

    public static List<OrderItem> getOrderProducts(Id orderId) {
        return [
                SELECT Id, Product2Id, Product2.Name, Product2.Is_External__c, Quantity, UnitPrice
                FROM OrderItem
                WHERE OrderId = :orderId
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
        if (order.ComplaintCaseId__c != null || String.isNotBlank(order.External_Complaint_Correlation_Id__c)) {
            throw new AuraHandledException('A complaint already exists for this Order.');
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

            update new Order(
                    Id = orderId,
                    ComplaintCaseId__c = aCase.Id,
                    External_Complaint_Correlation_Id__c = null,
                    Tracking_Case__c = null,
                    Pending_Complaint_JSON__c = null,
                    Refund_Status__c = Utils.ORDER_COMPLAINT.REFUND_STATUS.PENDING
            );

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

    public static void approveComplaint(Id caseId, String refundType, String comment, String productRefundsJson) {
        List<ProcessInstanceWorkitem> workitems = [
                SELECT Id
                FROM ProcessInstanceWorkitem
                WHERE ProcessInstance.TargetObjectId = :caseId
                AND ActorId = :UserInfo.getUserId()
                LIMIT 1
        ];

        if (workitems.isEmpty()) {
            throw new AuraHandledException('No pending approval found for this Case.');
        }

        ProcessInstanceWorkitem workitem = workitems[0];
        String approvalAction = refundType == Utils.ORDER_COMPLAINT.REFUND_TYPE.REJECTED ? Utils.ORDER_COMPLAINT.APPROVAL_ACTION.REJECT : Utils.ORDER_COMPLAINT.APPROVAL_ACTION.APPROVE;

        Approval.ProcessWorkitemRequest approvalWorkItemRequest = new Approval.ProcessWorkitemRequest();
        approvalWorkItemRequest.setWorkitemId(workitem.Id);
        approvalWorkItemRequest.setAction(approvalAction);
        approvalWorkItemRequest.setComments(comment);
        Approval.process(approvalWorkItemRequest);

        ErrorLogger.logInfo('OrderComplaintService.approveComplaint', 'Approval decision: ' + approvalAction + ' for Case: ' + caseId + ', refundType: ' + refundType);
        Case aCase = [
                SELECT Id, Order__c, External_Case_Id__c, Refund_Amount__c
                FROM Case
                WHERE Id = :caseId
        ];

        if (approvalAction == Utils.ORDER_COMPLAINT.APPROVAL_ACTION.APPROVE) {
            Decimal approvedAmount = 0;

            if (refundType == Utils.ORDER_COMPLAINT.REFUND_TYPE.PARTIAL && String.isNotBlank(productRefundsJson)) {
                List<Object> productRefundList = (List<Object>) JSON.deserializeUntyped(productRefundsJson);

                Set<Id> productIds = new Set<Id>();
                for (Object productRefund : productRefundList) {
                    productIds.add((Id) ((Map<String, Object>) productRefund).get('id'));
                }
                Map<Id, Case_Order_Product__c> caseProductsById = new Map<Id, Case_Order_Product__c>([
                    SELECT Id, Order_Product__r.UnitPrice, Order_Product__r.Quantity
                    FROM Case_Order_Product__c
                    WHERE Id IN :productIds AND Is_External__c = false
                ]);

                List<Case_Order_Product__c> productsToUpdate = new List<Case_Order_Product__c>();
                for (Object productRefund : productRefundList) {
                    Map<String, Object> productRefundEntry = (Map<String, Object>) productRefund;
                    Decimal amount = productRefundEntry.get('amount') != null ? (Decimal) productRefundEntry.get('amount') : 0;
                    if (amount < 0) {
                        throw new AuraHandledException('Refund amount cannot be negative.');
                    }
                    Case_Order_Product__c cop = caseProductsById.get((Id) productRefundEntry.get('id'));
                    if (cop != null) {
                        Decimal maxAmount = cop.Order_Product__r.UnitPrice * cop.Order_Product__r.Quantity;
                        if (amount > maxAmount) {
                            throw new AuraHandledException('Refund amount exceeds product value.');
                        }
                    }
                    productsToUpdate.add(new Case_Order_Product__c(Id = (Id) productRefundEntry.get('id'), Refund_Amount__c = amount));
                    approvedAmount += amount;
                }
                if (!productsToUpdate.isEmpty()) update productsToUpdate;
            } else if (refundType == Utils.ORDER_COMPLAINT.REFUND_TYPE.FULL) {
                Integer localProductCount = 0;
                List<Case_Order_Product__c> productsToUpdate = new List<Case_Order_Product__c>();
                for (Case_Order_Product__c caseProduct : [
                        SELECT Id, Order_Product__r.UnitPrice, Order_Product__r.Quantity
                        FROM Case_Order_Product__c
                        WHERE Case__c = :caseId AND Is_External__c = false AND Order_Product__c != null
                ]) {
                    Decimal productAmount = caseProduct.Order_Product__r.UnitPrice * caseProduct.Order_Product__r.Quantity;
                    approvedAmount += productAmount;
                    localProductCount++;
                    productsToUpdate.add(new Case_Order_Product__c(Id = caseProduct.Id, Refund_Amount__c = productAmount));
                }
                if (!productsToUpdate.isEmpty()) update productsToUpdate;
                if (localProductCount == 0) {
                    for (Case_Order_Product__c externalCaseProduct : [
                        SELECT Refund_Amount__c FROM Case_Order_Product__c
                        WHERE Case__c = :caseId AND Is_External__c = true
                    ]) {
                        approvedAmount += externalCaseProduct.Refund_Amount__c != null ? externalCaseProduct.Refund_Amount__c : 0;
                    }
                }
            }

            aCase.Approved_Refund_Type__c = refundType;
            aCase.Refund_Amount__c = approvedAmount;
            aCase.Refund_Status__c = Utils.ORDER_COMPLAINT.REFUND_STATUS.APPROVED;
            aCase.Status = Utils.ORDER_COMPLAINT.CASE_STATUS.CLOSED;
            update aCase;

            if (aCase.Order__c != null) {
                Order currentOrder = [
                    SELECT Id, External_Complaint_Correlation_Id__c
                    FROM Order
                    WHERE Id = :aCase.Order__c
                ];
                if (String.isBlank(currentOrder.External_Complaint_Correlation_Id__c)) {
                    Decimal externalAmount = 0;
                    for (Case_Order_Product__c cop : [
                        SELECT Refund_Amount__c FROM Case_Order_Product__c
                        WHERE Case__c = :caseId AND Is_External__c = true
                    ]) {
                        externalAmount += cop.Refund_Amount__c != null ? cop.Refund_Amount__c : 0;
                    }
                    update new Order(Id = aCase.Order__c, Refund_Type__c = refundType, Refund_Amount__c = approvedAmount + externalAmount, Refund_Status__c = Utils.ORDER_COMPLAINT.REFUND_STATUS.APPROVED);
                }
            }
            ErrorLogger.logInfo('OrderComplaintService.approveComplaint', 'Refund type ' + refundType + ' applied to Case: ' + caseId + (aCase.Order__c != null ? ' and Order: ' + aCase.Order__c : ''));
        } else {
            aCase.Refund_Status__c = Utils.ORDER_COMPLAINT.REFUND_STATUS.REJECTED;
            aCase.Status = Utils.ORDER_COMPLAINT.CASE_STATUS.CLOSED;
            update aCase;
            if (aCase.Order__c != null) {
                update new Order(Id = aCase.Order__c, Refund_Status__c = Utils.ORDER_COMPLAINT.REFUND_STATUS.REJECTED);
            }
        }

        if (String.isNotBlank(aCase.External_Case_Id__c)) {
            String responseStatus;
            if (approvalAction == Utils.ORDER_COMPLAINT.APPROVAL_ACTION.REJECT) {
                responseStatus = Utils.EXTERNAL_COMPLAINT.RESPONSE_STATUS.REJECTED;
            } else if (refundType == Utils.ORDER_COMPLAINT.REFUND_TYPE.FULL) {
                responseStatus = Utils.EXTERNAL_COMPLAINT.RESPONSE_STATUS.APPROVED_FULL;
            } else {
                responseStatus = Utils.EXTERNAL_COMPLAINT.RESPONSE_STATUS.APPROVED_PARTIAL;
            }

            System.enqueueJob(new ApprovalSyncQueueable(
                    aCase.External_Case_Id__c,
                    responseStatus,
                    aCase.Refund_Amount__c,
                    refundType,
                    aCase.Id
            ));
            ErrorLogger.logInfo('OrderComplaintService.approveComplaint', 'Enqueued approval sync to Org B | externalCaseId: ' + aCase.External_Case_Id__c + ' | status: ' + responseStatus);
        }
    }

    public static Decimal getMaxRefundAmount(Id caseId) {
        Decimal total = 0;
        Integer localProductCount = 0;
        for (Case_Order_Product__c caseOrderProduct : [
                SELECT Order_Product__r.UnitPrice, Order_Product__r.Quantity
                FROM Case_Order_Product__c
                WHERE Case__c = :caseId AND Is_External__c = false AND Order_Product__c != null
        ]) {
            total += caseOrderProduct.Order_Product__r.UnitPrice * caseOrderProduct.Order_Product__r.Quantity;
            localProductCount++;
        }
        if (localProductCount == 0) {
            Case aCase = [
                SELECT Refund_Amount__c 
                FROM Case 
                WHERE Id = :caseId
            ];
            total = aCase.Refund_Amount__c != null ? aCase.Refund_Amount__c : 0;
        }
        return total;
    }

    private static String generateUUID() {
        String hex = EncodingUtil.convertToHex(Crypto.generateAesKey(128));
        return hex.substring(0, 8) + '-' + hex.substring(8, 12) + '-' + hex.substring(12, 16) + '-' + hex.substring(16, 20) + '-' + hex.substring(20);
    }
}
