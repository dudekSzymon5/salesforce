trigger ExternalComplaintTrigger on External_Complaint__e (after insert) {
    List<Case> casesToInsert = new List<Case>();
    List<External_Complaint_Response__e> errorResponses = new List<External_Complaint_Response__e>();

    for (External_Complaint__e externalComplaint : Trigger.new) {
        ErrorLogger.logInfo('ExternalComplaintTrigger', 'Received External_Complaint__e | Case_Id__c: ' + externalComplaint.Case_Id__c + ' | Order_Id__c: ' + externalComplaint.Order_Id__c);
        casesToInsert.add(new Case(
            Complaint_Reason__c = externalComplaint.Reason__c,
            External_Case_Id__c = externalComplaint.Case_Id__c,
            Refund_Amount__c = externalComplaint.Refund_Amount__c,
            Refund_Status__c = Utils.ORDER_COMPLAINT.REFUND_STATUS.PENDING,
            Status = Utils.ORDER_COMPLAINT.CASE_STATUS.NEW_CASE,
            Origin = Utils.ORDER_COMPLAINT.CASE_ORIGIN.WEB
        ));
    }

    try {
        insert casesToInsert;
        ErrorLogger.logInfo('ExternalComplaintTrigger', 'Created ' + casesToInsert.size() + ' Case(s) from external complaint');
    } catch (Exception e) {
        ErrorLogger.log('ExternalComplaintTrigger', e);
        for (External_Complaint__e externalComplaint : Trigger.new) {
            errorResponses.add(new External_Complaint_Response__e(
                Case_Id__c = externalComplaint.Case_Id__c,
                Status__c = Utils.EXTERNAL_COMPLAINT.RESPONSE_STATUS.FAILED,
                Error_Message__c = 'Failed to create Case: ' + e.getMessage()
            ));
        }
        EventBus.publish(errorResponses);
        return;
    }

    try {
        Set<String> allExternalProductIds = new Set<String>();
        for (External_Complaint__e externalComplaint : Trigger.new) {
            if (String.isNotBlank(externalComplaint.Line_Items_JSON__c)) {
                List<OrderComplaintPayload.LineItem> items = (List<OrderComplaintPayload.LineItem>) JSON.deserialize(externalComplaint.Line_Items_JSON__c, List<OrderComplaintPayload.LineItem>.class);
                for (OrderComplaintPayload.LineItem item : items) {
                    if (String.isNotBlank(item.productId)) allExternalProductIds.add(item.productId);
                }
            } else if (String.isNotBlank(externalComplaint.Product_Ids__c)) {
                allExternalProductIds.addAll(externalComplaint.Product_Ids__c.split(','));
            }
        }

        Map<String, Product2> productsByExternalId = new Map<String, Product2>();
        for (Product2 product : [
                SELECT Id, Name, External_Product_Id__c
                FROM Product2
                WHERE External_Product_Id__c IN :allExternalProductIds
        ]) {
            productsByExternalId.put(product.External_Product_Id__c, product);
        }

        List<Case_Order_Product__c> caseOrderProducts = new List<Case_Order_Product__c>();
        for (Integer i = 0; i < casesToInsert.size(); i++) {
            External_Complaint__e externalComplaint = Trigger.new[i];

            if (String.isNotBlank(externalComplaint.Line_Items_JSON__c)) {
                List<OrderComplaintPayload.LineItem> lineItems = (List<OrderComplaintPayload.LineItem>) JSON.deserialize(externalComplaint.Line_Items_JSON__c, List<OrderComplaintPayload.LineItem>.class);
                for (OrderComplaintPayload.LineItem item : lineItems) {
                    Product2 product = productsByExternalId.get(item.productId);
                    if (product != null) {
                        caseOrderProducts.add(new Case_Order_Product__c(
                            Case__c = casesToInsert[i].Id,
                            Product_Name__c = product.Name,
                            Refund_Amount__c = item.refundAmount != null ? item.refundAmount : 0,
                            Is_External__c = true
                        ));
                    }
                }
            } else if (String.isNotBlank(externalComplaint.Product_Ids__c)) {
                for (String externalId : externalComplaint.Product_Ids__c.split(',')) {
                    Product2 product = productsByExternalId.get(externalId);
                    if (product != null) {
                        caseOrderProducts.add(new Case_Order_Product__c(
                            Case__c = casesToInsert[i].Id,
                            Product_Name__c = product.Name,
                            Is_External__c = true
                        ));
                    }
                }
            }
        }

        if (!caseOrderProducts.isEmpty()) {
            insert caseOrderProducts;
            ErrorLogger.logInfo('ExternalComplaintTrigger', 'Created ' + caseOrderProducts.size() + ' Case_Order_Product__c record(s)');
        }
    } catch (Exception e) {
        ErrorLogger.log('ExternalComplaintTrigger', e);
        for (External_Complaint__e externalComplaint : Trigger.new) {
            errorResponses.add(new External_Complaint_Response__e(
                Case_Id__c = externalComplaint.Case_Id__c,
                Status__c = Utils.EXTERNAL_COMPLAINT.RESPONSE_STATUS.FAILED,
                Error_Message__c = 'Failed to link products: ' + e.getMessage()
            ));
        }
        EventBus.publish(errorResponses);
        return;
    }

    try {
        for (Case aCase : casesToInsert) {
            Approval.ProcessSubmitRequest request = new Approval.ProcessSubmitRequest();
            request.setObjectId(aCase.Id);
            request.setSubmitterId(UserInfo.getUserId());
            Approval.process(request);
        }
        ErrorLogger.logInfo('ExternalComplaintTrigger', 'Approval process submitted for ' + casesToInsert.size() + ' Case(s)');
    } catch (Exception e) {
        ErrorLogger.log('ExternalComplaintTrigger', e);
        for (External_Complaint__e externalComplaint : Trigger.new) {
            errorResponses.add(new External_Complaint_Response__e(
                Case_Id__c = externalComplaint.Case_Id__c,
                Status__c = Utils.EXTERNAL_COMPLAINT.RESPONSE_STATUS.FAILED,
                Error_Message__c = 'Failed to submit for approval: ' + e.getMessage()
            ));
        }
        EventBus.publish(errorResponses);
        return;
    }

    System.enqueueJob(new ComplaintResponseQueueable(casesToInsert, Trigger.new));
}
