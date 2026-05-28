public with sharing class OrderComplaintPayload {

    public class LineItem {
        public String productId;
        public Decimal refundAmount;
        public String refundType;
        public String status;
    }

    public class PendingComplaint {
        public String reason;
        public String expectedRefundType;
        public List<Id> localItemIds;
        public List<Id> externalItemIds;
        public String externalLineItemsJson;
    }

    public class OrderComplaintController {
        private String orderId;
        private String caseId;
        private String reason;
        private String productIds;
        private Decimal refundAmount;
        private String lineItemsJson;

        public OrderComplaintController(String caseId, String orderId, String productIds, String reason, Decimal refundAmount, String lineItemsJson) {
            this.caseId = caseId;
            this.orderId = orderId;
            this.productIds = productIds;
            this.reason = reason;
            this.refundAmount = refundAmount;
            this.lineItemsJson = lineItemsJson;
        }

        public String toJSON() {
            JSONGenerator generator = JSON.createGenerator(false);
            generator.writeStartObject();
            generator.writeStringField('Order_Id__c', orderId);
            generator.writeStringField('Case_Id__c', caseId);
            generator.writeStringField('Reason__c', reason);
            generator.writeStringField('Product_Ids__c', productIds);
            generator.writeNumberField('Refund_Amount__c', refundAmount);
            generator.writeStringField('Line_Items_JSON__c', lineItemsJson != null ? lineItemsJson : '[]');
            generator.writeEndObject();
            return generator.getAsString();
        }
    }
    public class ApprovalSyncQueueable {
        private String caseId;
        private String status;
        private Decimal finalRefundAmount;
        private String finalRefundType;
        private String lineItemsJson;

        public ApprovalSyncQueueable(String caseId, Decimal finalRefundAmount, String finalRefundType, String status, String lineItemsJson) {
            this.caseId = caseId;
            this.finalRefundAmount = finalRefundAmount;
            this.finalRefundType = finalRefundType;
            this.status = status;
            this.lineItemsJson = lineItemsJson;
        }

        public String toJSON() {
            JSONGenerator generator = JSON.createGenerator(false);
            generator.writeStartObject();
            generator.writeStringField('Case_Id__c', caseId);
            generator.writeStringField('Status__c', status);
            generator.writeNumberField('Final_Refund_Amount__c', finalRefundAmount);
            generator.writeStringField('Final_Refund_Type__c', finalRefundType);
            generator.writeStringField('Line_Items_JSON__c', lineItemsJson != null ? lineItemsJson : '[]');
            generator.writeEndObject();
            return generator.getAsString();
        }
    }

    public class ComplaintResponseQueueable {
        private String caseId;
        private String externalCaseId;
        private String status;

        public ComplaintResponseQueueable(String caseId, String externalCaseId, String status) {
            this.caseId = caseId;
            this.externalCaseId = externalCaseId;
            this.status = status;
        }

        public String toJSON() {
            JSONGenerator generator = JSON.createGenerator(false);
            generator.writeStartObject();
            generator.writeStringField('Case_Id__c', caseId);
            generator.writeStringField('External_Case_Id__c', externalCaseId);
            generator.writeStringField('Status__c', status);
            generator.writeEndObject();
            return generator.getAsString();
        }
    }

}