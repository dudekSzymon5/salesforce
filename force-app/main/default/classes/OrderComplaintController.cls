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
                Refund_Status__c = 'Pending',
                Status = 'New',
                Origin = 'Web'
        );
        insert aCase;

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
            External_Complaint__e externalComplaintEvent = new External_Complaint__e (
                    Order_Id__c = orderId,
                    Case_Id__c = aCase.Id,
                    Reason__c = reason,
                    Product_Ids__c = String.join(externalProductsId, ',')
            );
            EventBus.publish(externalComplaintEvent);
        }
        Approval.ProcessSubmitRequest request = new Approval.ProcessSubmitRequest();
        request.setObjectId(aCase.Id);
        request.setSubmitterId(UserInfo.getUserId());
        Approval.process(request);
        return aCase.Id;
    }

    @AuraEnabled
    public static void approveComplaint(Id caseId, String refundType, String comment, String action) {
        ProcessInstanceWorkitem workitem = [
                SELECT Id
                FROM ProcessInstanceWorkitem
                WHERE ProcessInstance.TargetObjectId = :caseId
                AND ActorId = :UserInfo.getUserId()
                LIMIT 1
        ];

        String approvalAction = refundType == 'Rejected' ? 'Reject' : 'Approve';

        Approval.ProcessWorkitemRequest approvalWorkItemRequest = new Approval.ProcessWorkitemRequest();
        approvalWorkItemRequest.setWorkitemId(workitem.Id);
        approvalWorkItemRequest.setAction(approvalAction);
        approvalWorkItemRequest.setComments(comment);
        Approval.process(approvalWorkItemRequest);

        if (approvalAction == 'Approve') {
            Case aCase = [SELECT Id, Order__c FROM Case WHERE Id = :caseId];
            aCase.Approved_Refund_Type__c = refundType;
            update aCase;
            update new Order(Id = aCase.Order__c, Refund_Type__c = refundType);
        }
    }
}