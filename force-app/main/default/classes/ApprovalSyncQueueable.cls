public class ApprovalSyncQueueable implements Queueable, Database.AllowsCallouts {

    private String externalCaseId;
    private String status;
    private Decimal refundAmount;
    private String refundType;

    public ApprovalSyncQueueable(String externalCaseId, String status, Decimal refundAmount, String refundType) {
        this.externalCaseId = externalCaseId;
        this.status = status;
        this.refundAmount = refundAmount;
        this.refundType = refundType;
    }

    public void execute(QueueableContext context) {
        HttpRequest request = new HttpRequest();
        request.setEndpoint(Utils.EXTERNAL_COMPLAINT.API.RESPONSE_ENDPOINT);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setBody(new OrderComplaintPayload.ApprovalSyncQueueable(
                externalCaseId,
                refundAmount,
                refundType,
                status
        ).toJSON());

        try {
            HttpResponse response = new Http().send(request);
            ErrorLogger.logInfo('ApprovalSyncQueueable', 'Sent approval result to Org B | externalCaseId: ' + externalCaseId + ' | status: ' + status + ' | httpStatus: ' + response.getStatusCode());
        } catch (Exception e) {
            ErrorLogger.log('ApprovalSyncQueueable', e, externalCaseId);
        }
    }
}
