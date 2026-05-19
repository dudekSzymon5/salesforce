public with sharing class OrderComplaintController {

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
    public static Id submitComplaint(Id orderId, String reason, String expectedRefundType, List<Id> selectedOrderItemsId) {
        try {
            List<OrderItem> getItems = [
                    SELECT Id, Product2Id, Product2.Name, Product2.Is_External__c
                    FROM OrderItem
                    WHERE Id IN :selectedOrderItemsId
            ];

            Boolean hasExternal = false;

            for (OrderItem orderItem : getItems) {
                if (orderItem.Product2.Is_External__c) {
                    hasExternal = true;
                    break;
                }
            }

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

            List<Case_Order_Product__c> caseOrderProducts = new List<Case_Order_Product__c>();
            for (OrderItem orderItem : getItems) {
                caseOrderProducts.add(new Case_Order_Product__c(
                        Case__c = aCase.Id,
                        Order_Product__c = orderItem.Id,
                        Product_Name__c = orderItem.Product2.Name,
                        Is_External__c = orderItem.Product2.Is_External__c
                ));
            }
            insert caseOrderProducts;

            update new Order(Id = orderId, ComplaintCaseId__c = aCase.Id);

            List<String> externalProductsId = new List<String>();
            for (OrderItem orderItem : getItems) {
                if (orderItem.Product2.Is_External__c) {
                    externalProductsId.add(orderItem.Product2Id);
                }
            }

            if (hasExternal) {
                External_Complaint__e externalComplaintEvent = new External_Complaint__e(
                        Order_Id__c = orderId,
                        Case_Id__c = aCase.Id,
                        Reason__c = reason,
                        Product_Ids__c = String.join(externalProductsId, ',')
                );
                System.enqueueJob(new ComplaintForwarderQueueable(
                    new List<External_Complaint__e>{ externalComplaintEvent }
                ));
                ErrorLogger.logInfo('OrderComplaintController.submitComplaint', 'ComplaintForwarderQueueable enqueued for Case: ' + aCase.Id + ', products: ' + String.join(externalProductsId, ','));
            }

            Approval.ProcessSubmitRequest request = new Approval.ProcessSubmitRequest();
            request.setObjectId(aCase.Id);
            request.setSubmitterId(UserInfo.getUserId());
            Approval.process(request);
            ErrorLogger.logInfo('OrderComplaintController.submitComplaint', 'Approval process submitted for Case: ' + aCase.Id);

            return aCase.Id;

        } catch (Exception e) {
            ErrorLogger.log('OrderComplaintController.submitComplaint', e, orderId);
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void approveComplaint(Id caseId, String refundType, String comment, String action) {
        try {
            ProcessInstanceWorkitem workitem = [
                    SELECT Id
                    FROM ProcessInstanceWorkitem
                    WHERE ProcessInstance.TargetObjectId = :caseId
                    AND ActorId = :UserInfo.getUserId()
                    LIMIT 1
            ];

            String approvalAction = refundType == Utils.ORDER_COMPLAINT.REFUND_TYPE.REJECTED ? Utils.ORDER_COMPLAINT.APPROVAL_ACTION.REJECT : Utils.ORDER_COMPLAINT.APPROVAL_ACTION.APPROVE;

            Approval.ProcessWorkitemRequest approvalWorkItemRequest = new Approval.ProcessWorkitemRequest();
            approvalWorkItemRequest.setWorkitemId(workitem.Id);
            approvalWorkItemRequest.setAction(approvalAction);
            approvalWorkItemRequest.setComments(comment);
            Approval.process(approvalWorkItemRequest);

            ErrorLogger.logInfo('OrderComplaintController.approveComplaint', 'Approval decision: ' + approvalAction + ' for Case: ' + caseId + ', refundType: ' + refundType);

            if (approvalAction == Utils.ORDER_COMPLAINT.APPROVAL_ACTION.APPROVE) {
                Case aCase = [
                    SELECT Id, Order__c 
                    FROM Case 
                    WHERE Id = :caseId
                ];
                aCase.Approved_Refund_Type__c = refundType;
                update aCase;
                update new Order(Id = aCase.Order__c, Refund_Type__c = refundType);
                ErrorLogger.logInfo('OrderComplaintController.approveComplaint', 'Refund type ' + refundType + ' applied to Order: ' + aCase.Order__c + ' and Case: ' + caseId);
            }

        } catch (Exception e) {
            ErrorLogger.log('OrderComplaintController.approveComplaint', e, caseId);
            throw new AuraHandledException(e.getMessage());
        }
    }
}