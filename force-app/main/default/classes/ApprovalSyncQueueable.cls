public class ApprovalSyncQueueable implements Queueable, Database.AllowsCallouts {

    private String externalCaseId;
    private String status;
    private Decimal refundAmount;
    private String refundType;
    private Id localCaseId;

    public ApprovalSyncQueueable(String externalCaseId, String status, Decimal refundAmount, String refundType, Id localCaseId) {
        this.externalCaseId = externalCaseId;
        this.status = status;
        this.refundAmount = refundAmount;
        this.refundType = refundType;
        this.localCaseId = localCaseId;
    }

    public void execute(QueueableContext context) {
        String lineItemsJson = buildLineItemsJson();

        HttpRequest request = new HttpRequest();
        request.setEndpoint(Utils.EXTERNAL_COMPLAINT.API.RESPONSE_ENDPOINT);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setTimeout(10000);
        request.setBody(new OrderComplaintPayload.ApprovalSyncQueueable(externalCaseId, refundAmount, refundType, status, lineItemsJson).toJSON());

        try {
            HttpResponse response = new Http().send(request);
            ErrorLogger.logInfo('ApprovalSyncQueueable', 'Sent approval result to Org B | externalCaseId: ' + externalCaseId + ' | status: ' + status + ' | httpStatus: ' + response.getStatusCode());
        } catch (Exception e) {
            ErrorLogger.log('ApprovalSyncQueueable', e, externalCaseId);
        }
    }

    private String buildLineItemsJson() {
        if (localCaseId == null) return '[]';

        List<Case_Order_Product__c> caseOrderProducts = [
            SELECT Product_Name__c, Refund_Amount__c
            FROM Case_Order_Product__c
            WHERE Case__c = :localCaseId AND Is_External__c = true
        ];
        if (caseOrderProducts.isEmpty()) return '[]';

        Set<String> productNames = new Set<String>();
        for (Case_Order_Product__c caseOrderProduct : caseOrderProducts) productNames.add(caseOrderProduct.Product_Name__c);

        Map<String, String> externalIdByName = new Map<String, String>();
        for (Product2 product : [
            SELECT Id, Name, External_Product_Id__c 
            FROM Product2 
            WHERE Name IN :productNames
        ]) {
            externalIdByName.put(product.Name, String.isNotBlank(product.External_Product_Id__c) ? product.External_Product_Id__c : product.Id);
        }

        List<OrderComplaintPayload.LineItem> lineItems = new List<OrderComplaintPayload.LineItem>();
        for (Case_Order_Product__c caseOrderProduct : caseOrderProducts) {
            OrderComplaintPayload.LineItem lineItem = new OrderComplaintPayload.LineItem();
            lineItem.productId = externalIdByName.get(caseOrderProduct.Product_Name__c);
            lineItem.status = status;
            lineItem.refundAmount = caseOrderProduct.Refund_Amount__c != null ? caseOrderProduct.Refund_Amount__c : 0;
            lineItem.refundType = refundType;
            lineItems.add(lineItem);
        }
        return JSON.serialize(lineItems);
    }
}
