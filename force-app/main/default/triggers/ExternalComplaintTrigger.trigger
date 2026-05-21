trigger ExternalComplaintTrigger on External_Complaint__e (after insert) {
    List<Case> casesToInsert = new List<Case>();

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
        return;
    }

    try {
        Set<String> allExternalProductIds = new Set<String>();
        for (External_Complaint__e ev : Trigger.new) {
            if (String.isNotBlank(ev.Product_Ids__c)) {
                allExternalProductIds.addAll(ev.Product_Ids__c.split(','));
            }
        }

        Map<String, Product2> productsByExternalId = new Map<String, Product2>();
        for (Product2 p : [SELECT Id, Name, External_Product_Id__c FROM Product2 WHERE External_Product_Id__c IN :allExternalProductIds]) {
            productsByExternalId.put(p.External_Product_Id__c, p);
        }

        List<Case_Order_Product__c> caseOrderProducts = new List<Case_Order_Product__c>();
        for (Integer i = 0; i < casesToInsert.size(); i++) {
            External_Complaint__e ev = Trigger.new[i];
            if (String.isBlank(ev.Product_Ids__c)) {
                continue;
            }
            for (String extId : ev.Product_Ids__c.split(',')) {
                Product2 product = productsByExternalId.get(extId);
                if (product != null) {
                    caseOrderProducts.add(new Case_Order_Product__c(
                        Case__c = casesToInsert[i].Id,
                        Product_Name__c = product.Name,
                        Is_External__c = true
                    ));
                }
            }
        }

        if (!caseOrderProducts.isEmpty()) {
            insert caseOrderProducts;
            ErrorLogger.logInfo('ExternalComplaintTrigger', 'Created ' + caseOrderProducts.size() + ' Case_Order_Product__c record(s)');
        }
    } catch (Exception e) {
        ErrorLogger.log('ExternalComplaintTrigger', e);
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
    }
    // Używam queueable żeby wysłać Konradowi reponse. 
    // Dlatego, że jestem na triggerze to używam queable
    System.enqueueJob(new ComplaintResponseQueueable(casesToInsert, Trigger.new));
}
