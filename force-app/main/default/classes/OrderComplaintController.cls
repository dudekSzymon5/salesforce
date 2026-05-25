public with sharing class OrderComplaintController {

    @AuraEnabled(cacheable=true)
    public static List<OrderItem> getOrderProducts(Id orderId) {
        try {
            return OrderComplaintService.getOrderProducts(orderId);
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            ErrorLogger.log('OrderComplaintController', e);
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static OrderComplaintService.ComplaintResult submitComplaint(Id orderId, String reason, String expectedRefundType, List<Id> selectedOrderItemsId) {
        try {
            return OrderComplaintService.submitComplaint(orderId, reason, expectedRefundType, selectedOrderItemsId);
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            ErrorLogger.log('OrderComplaintController', e, orderId);
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void approveComplaint(Id caseId, String refundType, Decimal refundAmount, String comment, String action) {
        try {
            OrderComplaintService.approveComplaint(caseId, refundType, refundAmount, comment, action);
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            ErrorLogger.log('OrderComplaintController', e, caseId);
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static Decimal getMaxRefundAmount(Id caseId) {
        try {
            return OrderComplaintService.getMaxRefundAmount(caseId);
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            ErrorLogger.log('OrderComplaintController', e);
            throw new AuraHandledException(e.getMessage());
        }
    }
}
