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
    public static String submitComplaint(Id orderId, String reason, String expectedRefundType, List<Id> selectedOrderItemsId) {
        try {
            List<OrderItem> getItems = [
                    SELECT Id, Product2Id, Product2.Name, Product2.Is_External__c, Product2.External_Product_Id__c, Quantity, UnitPrice
                    FROM OrderItem
                    WHERE Id IN :selectedOrderItemsId
            ];

            Boolean hasExternal = false;
            List<String> externalProductIds = new List<String>();
            Decimal refundAmount = 0;

            for (OrderItem orderItem : getItems) {
                if (orderItem.Product2.Is_External__c) {
                    hasExternal = true;
                    externalProductIds.add(orderItem.Product2.External_Product_Id__c);
                    refundAmount += orderItem.UnitPrice * orderItem.Quantity;
                }
            }

            if (hasExternal) {
                String correlationId = generateUUID();

                HttpRequest request = new HttpRequest();
                request.setEndpoint(Utils.EXTERNAL_COMPLAINT.API.FORWARD_ENDPOINT);
                request.setMethod('POST');
                request.setHeader('Content-Type', 'application/json');
                request.setBody(JSON.serialize(new Map<String, Object>{
                        'Order_Id__c' => orderId,
                        'Case_Id__c' => correlationId,
                        'Reason__c' => expectedRefundType + ' - ' + reason,
                        'Product_Ids__c' => String.join(externalProductIds, ','),
                        'Refund_Amount__c' => refundAmount
                }));

                HttpResponse response = new Http().send(request);

                if (response.getStatusCode() != 200 && response.getStatusCode() != 201) {
                    throw new AuraHandledException('External system rejected the complaint: ' + response.getStatusCode());
                }

                ErrorLogger.logInfo('OrderComplaintController.submitComplaint', 'External complaint forwarded | correlationId: ' + correlationId + ' | products: ' + String.join(externalProductIds, ','));
                return correlationId;
            }

            Case aCase = new Case(
                    Order__c = orderId,
                    Complaint_Reason__c = reason,
                    Expected_Refund_Type__c = expectedRefundType,
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

            Approval.ProcessSubmitRequest request = new Approval.ProcessSubmitRequest();
            request.setObjectId(aCase.Id);
            request.setSubmitterId(UserInfo.getUserId());
            Approval.process(request);
            ErrorLogger.logInfo('OrderComplaintController.submitComplaint', 'Approval process submitted for Case: ' + aCase.Id);

            return aCase.Id;

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
                if (aCase.Order__c != null) {
                    update new Order(Id = aCase.Order__c, Refund_Type__c = refundType);
                }
                ErrorLogger.logInfo('OrderComplaintController.approveComplaint', 'Refund type ' + refundType + ' applied to Case: ' + caseId + (aCase.Order__c != null ? ' and Order: ' + aCase.Order__c : ''));
            }

        } catch (Exception e) {
            ErrorLogger.log('OrderComplaintController.approveComplaint', e, caseId);
            throw new AuraHandledException(e.getMessage());
        }
    }
}