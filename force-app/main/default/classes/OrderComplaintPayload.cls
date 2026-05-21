public with sharing class OrderComplaintPayload {

    public class OrderComplaintController {
        public String Order_Id__c;
        public String Case_Id__c;
        public String Reason__c;
        public String Product_Ids__c;
        public Decimal Refund_Amount__c;

        public OrderComplaintController(String Case_Id__c, String Order_Id__c, String Product_Ids__c, String Reason__c, Decimal Refund_Amount__c) {
            this.Case_Id__c = Case_Id__c;
            this.Order_Id__c = Order_Id__c;
            this.Product_Ids__c = Product_Ids__c;
            this.Reason__c = Reason__c;
            this.Refund_Amount__c = Refund_Amount__c;
        }
    }
    public class ApprovalSyncQueueable {
        public String Case_Id__c;
        public String Status__c;
        public Decimal Final_Refund_Amount__c;
        public String Final_Refund_Type__c;

        public ApprovalSyncQueueable(String Case_Id__c, Decimal Final_Refund_Amount__c, String Final_Refund_Type__c, String Status__c) {
            this.Case_Id__c = Case_Id__c;
            this.Final_Refund_Amount__c = Final_Refund_Amount__c;
            this.Final_Refund_Type__c = Final_Refund_Type__c;
            this.Status__c = Status__c;
        }
    }

    public class ComplaintResponseQueueable {
        public String Case_Id__c;
        public String External_Case_Id__c;
        public String Status__c;

        public ComplaintResponseQueueable(String Case_Id__c, String External_Case_Id__c, String Status__c) {
            this.Case_Id__c = Case_Id__c;
            this.External_Case_Id__c = External_Case_Id__c;
            this.Status__c = Status__c;
        }
    }

}