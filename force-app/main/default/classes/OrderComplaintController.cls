public with sharing class OrderComplaintController {

    public class ComplaintResult {
        @AuraEnabled public String caseId;
        @AuraEnabled public String correlationId;
    }

    @AuraEnabled(cacheable=true)
    public static List<OrderItem> getOrderProducts(Id orderId) {
        List<OrderItem> orderItems = [
                SELECT Id, Product2Id, Product2.Name, Product2.Is_External__c, Quantity, UnitPrice
                FROM OrderItem
                WHERE OrderId = :orderId
        ];
        return orderItems;
    }

    @AuraEnabled
    public static ComplaintResult submitComplaint(Id orderId, String reason, String expectedRefundType, List<Id> selectedOrderItemsId) {
        try {
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

            for (OrderItem orderItem : getItems) { // Iteruje po wybranych produktach i segreguje je na dwie listy
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
            Case trackingCase = null;

            if (hasExternal) {
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
                        refundAmount
                ).toJSON());

                HttpResponse response = new Http().send(request);

                if (response.getStatusCode() != 200 && response.getStatusCode() != 201) {
                    throw new AuraHandledException('External system rejected the complaint: ' + response.getStatusCode());
                }
                
                result.correlationId = correlationId;

                // Czyli trackingCase tworzę po to aby widzieć, że wysłałem complaint do Konrada i czekam na odpowiedź
                trackingCase = new Case(
                        Order__c = orderId,
                        Complaint_Reason__c = reason,
                        Expected_Refund_Type__c = expectedRefundType,
                        External_Case_Id__c = correlationId,
                        Has_External_Product__c = true,
                        Refund_Status__c = Utils.ORDER_COMPLAINT.REFUND_STATUS.PENDING,
                        Status = Utils.ORDER_COMPLAINT.CASE_STATUS.NEW_CASE,
                        Origin = Utils.ORDER_COMPLAINT.CASE_ORIGIN.WEB
                );
                insert trackingCase;

                List<Case_Order_Product__c> externalCaseProducts = new List<Case_Order_Product__c>();
                for (OrderItem item : externalItems) {
                    externalCaseProducts.add(new Case_Order_Product__c(
                            Case__c = trackingCase.Id,
                            Order_Product__c = item.Id,
                            Product_Name__c = item.Product2.Name,
                            Is_External__c = true
                    ));
                }
               
                if (!externalCaseProducts.isEmpty()) {
                    insert externalCaseProducts;
                }

                if (!hasLocal) {
                    // Przypisuje trackingCase jako główny Case orderu
                    update new Order(Id = orderId, ComplaintCaseId__c = trackingCase.Id);
                    result.caseId = trackingCase.Id;
                }
                ErrorLogger.logInfo('OrderComplaintController.submitComplaint', 'External complaint forwarded | correlationId: ' + correlationId + ' | trackingCaseId: ' + trackingCase.Id + ' | products: ' + String.join(externalProductIds, ','));
            }

            if (hasLocal) {
                Case aCase = new Case(
                        Order__c = orderId,
                        Complaint_Reason__c = reason,
                        Expected_Refund_Type__c = expectedRefundType,
                        Has_External_Product__c = hasExternal,
                        Refund_Status__c = Utils.ORDER_COMPLAINT.REFUND_STATUS.PENDING,
                        Status = Utils.ORDER_COMPLAINT.CASE_STATUS.NEW_CASE,
                        Origin = Utils.ORDER_COMPLAINT.CASE_ORIGIN.WEB
                );
                insert aCase;
                ErrorLogger.logInfo('OrderComplaintController.submitComplaint', 'Case created: ' + aCase.Id + ' for Order: ' + orderId);

               
                // Każdy Case musi mieć swoją własną listę powiązanych produktów
                List<Case_Order_Product__c> caseOrderProducts = new List<Case_Order_Product__c>();
                for (OrderItem orderItem : localItems) {
                    caseOrderProducts.add(new Case_Order_Product__c(
                            Case__c = aCase.Id,
                            Order_Product__c = orderItem.Id,
                            Product_Name__c = orderItem.Product2.Name,
                            Is_External__c = false
                    ));
                }
                for (OrderItem orderItem : externalItems) {
                    caseOrderProducts.add(new Case_Order_Product__c(
                            Case__c = aCase.Id,
                            Order_Product__c = orderItem.Id,
                            Product_Name__c = orderItem.Product2.Name,
                            Is_External__c = true
                    ));
                }
                insert caseOrderProducts;

                update new Order(Id = orderId, ComplaintCaseId__c = aCase.Id, Tracking_Case__c = trackingCase != null ? trackingCase.Id : null);
                // Wbudowana klasa salesforce do obsługi zatwierdzania procesu
                Approval.ProcessSubmitRequest approvalRequest = new Approval.ProcessSubmitRequest();
                approvalRequest.setObjectId(aCase.Id);
                approvalRequest.setSubmitterId(UserInfo.getUserId());
                Approval.process(approvalRequest);
                ErrorLogger.logInfo('OrderComplaintController.submitComplaint', 'Approval process submitted for Case: ' + aCase.Id);

                result.caseId = aCase.Id;
            }
            return result;

        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            ErrorLogger.log('OrderComplaintController.submitComplaint', e, orderId);
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static String generateUUID() {
        String hex = EncodingUtil.convertToHex(Crypto.generateAesKey(128));
        return hex.substring(0, 8) + '-' + hex.substring(8, 12) + '-' + hex.substring(12, 16) + '-' + hex.substring(16, 20) + '-' + hex.substring(20);
    }

    @AuraEnabled
    public static void approveComplaint(Id caseId, String refundType, Decimal refundAmount, String comment, String action) {
        try {
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
            // Buduje proces zatwirdzenia
            Approval.ProcessWorkitemRequest approvalWorkItemRequest = new Approval.ProcessWorkitemRequest();
            approvalWorkItemRequest.setWorkitemId(workitem.Id);
            approvalWorkItemRequest.setAction(approvalAction);
            approvalWorkItemRequest.setComments(comment);
            Approval.process(approvalWorkItemRequest);

            ErrorLogger.logInfo('OrderComplaintController.approveComplaint', 'Approval decision: ' + approvalAction + ' for Case: ' + caseId + ', refundType: ' + refundType);
            Case aCase = [
                    SELECT Id, Order__c, External_Case_Id__c, Refund_Amount__c
                    FROM Case
                    WHERE Id = :caseId
            ];
            
            if (approvalAction == Utils.ORDER_COMPLAINT.APPROVAL_ACTION.APPROVE) {
                Decimal approvedAmount = refundAmount;
                if (refundType == Utils.ORDER_COMPLAINT.REFUND_TYPE.FULL) {
                    approvedAmount = 0;
                    for (Case_Order_Product__c caseOrderProduct : [
                            SELECT Order_Product__r.UnitPrice, Order_Product__r.Quantity
                            FROM Case_Order_Product__c
                            WHERE Case__c = :caseId AND Is_External__c = false AND Order_Product__c != null
                    ]) {
                        approvedAmount += caseOrderProduct.Order_Product__r.UnitPrice * caseOrderProduct.Order_Product__r.Quantity;
                    }
                }

                aCase.Approved_Refund_Type__c = refundType;
                aCase.Refund_Amount__c = approvedAmount;
                aCase.Refund_Status__c = Utils.ORDER_COMPLAINT.REFUND_STATUS.APPROVED;
                update aCase;

                if (aCase.Order__c != null) {
                    Order currentOrder = [
                        SELECT Id, Tracking_Case__c 
                        FROM Order 
                        WHERE Id = :aCase.Order__c
                    ];
                    if (currentOrder.Tracking_Case__c == null) {
                        update new Order(Id = aCase.Order__c, Refund_Type__c = refundType, Refund_Amount__c = approvedAmount);
                    } else {
                        Case trackingCase = [
                            SELECT Id, Refund_Status__c, Refund_Amount__c 
                            FROM Case 
                            WHERE Id = :currentOrder.Tracking_Case__c
                        ];
                        if (trackingCase.Refund_Status__c == Utils.ORDER_COMPLAINT.REFUND_STATUS.APPROVED) {
                            Decimal externalAmount = trackingCase.Refund_Amount__c != null ? trackingCase.Refund_Amount__c : 0;
                            update new Order(Id = aCase.Order__c, Refund_Type__c = refundType, Refund_Amount__c = approvedAmount + externalAmount);
                        }
                    }
                }
                ErrorLogger.logInfo('OrderComplaintController.approveComplaint', 'Refund type ' + refundType + ' applied to Case: ' + caseId + (aCase.Order__c != null ? ' and Order: ' + aCase.Order__c : ''));
            } else {
                aCase.Refund_Status__c = Utils.ORDER_COMPLAINT.REFUND_STATUS.REJECTED;
                update aCase;
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
                        refundType
                ));
                ErrorLogger.logInfo('OrderComplaintController.approveComplaint', 'Enqueued approval sync to Org B | externalCaseId: ' + aCase.External_Case_Id__c + ' | status: ' + responseStatus);
            }

        } catch (Exception e) {
            ErrorLogger.log('OrderComplaintController.approveComplaint', e, caseId);
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static Decimal getMaxRefundAmount(Id caseId) {
        Decimal total = 0;
        for (Case_Order_Product__c caseOrderProduct : [
                SELECT Order_Product__r.UnitPrice, Order_Product__r.Quantity
                FROM Case_Order_Product__c
                WHERE Case__c = :caseId AND Is_External__c = false AND Order_Product__c != null
        ]) {
            total += caseOrderProduct.Order_Product__r.UnitPrice * caseOrderProduct.Order_Product__r.Quantity;
        }
        return total;
    }
}
