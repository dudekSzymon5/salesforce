public with sharing class OrderComplaintController {

    @AuraEnabled
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

}
