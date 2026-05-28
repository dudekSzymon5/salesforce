public with sharing class OrderComplaintApprovalController {

    @AuraEnabled(cacheable=true)
    public static List<Case_Order_Product__c> getCaseProducts(Id caseId) {
        try {
            return OrderComplaintApprovalService.getCaseProducts(caseId);
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            ErrorLogger.log('OrderComplaintApprovalController', e);
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void approveComplaint(Id caseId, String refundType, String comment, String productRefundsJson) {
        try {
            OrderComplaintApprovalService.approveComplaint(caseId, refundType, comment, productRefundsJson);
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            ErrorLogger.log('OrderComplaintApprovalController', e, caseId);
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static Decimal getMaxRefundAmount(Id caseId) {
        try {
            return OrderComplaintApprovalService.getMaxRefundAmount(caseId);
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            ErrorLogger.log('OrderComplaintApprovalController', e);
            throw new AuraHandledException(e.getMessage());
        }
    }
}
