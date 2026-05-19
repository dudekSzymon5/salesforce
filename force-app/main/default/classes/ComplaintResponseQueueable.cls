public class ComplaintResponseQueueable implements Queueable, Database.AllowsCallouts {

    private List<Case> createdCases;
    private List<External_Complaint__e> originalEvents;

    public ComplaintResponseQueueable(List<Case> createdCases, List<External_Complaint__e> originalEvents) {
        this.createdCases = createdCases;
        this.originalEvents = originalEvents;
    }

    public void execute(QueueableContext context) {
        Http httpClient = new Http();
        String endpoint = Utils.EXTERNAL_COMPLAINT.API.RESPONSE_ENDPOINT;

        for (Integer i = 0; i < createdCases.size(); i++) {
            Case createdCase = createdCases[i];
            External_Complaint__e originalEvent = originalEvents[i];

            Map<String, Object> payload = new Map<String, Object> {
                'Case_Id__c'          => originalEvent.Case_Id__c,
                'External_Case_Id__c' => createdCase.Id,
                'Status__c'           => Utils.EXTERNAL_COMPLAINT.RESPONSE_STATUS.CREATED
            };

            String body = JSON.serialize(payload);
            
            HttpRequest request = new HttpRequest();
            request.setEndpoint(endpoint);
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json');
            request.setBody(body);

            try {
                ErrorLogger.logInfo('ComplaintResponseQueueable', 'Sending response | Case_Id__c: ' + originalEvent.Case_Id__c + ' | External_Case_Id__c: ' + createdCase.Id);

                HttpResponse response = httpClient.send(request);

                if (response.getStatusCode() == 200 || response.getStatusCode() == 201) {
                    ErrorLogger.logInfo('ComplaintResponseQueueable', 'Success | status: ' + response.getStatusCode() + ' | response: ' + response.getBody());
                } else {
                    ErrorLogger.logWarning('ComplaintResponseQueueable', 'Rejected | status: ' + response.getStatusCode() + ' | response: ' + response.getBody(), 'Case_Id__c: ' + originalEvent.Case_Id__c);
                }
            } catch (Exception e) {
                ErrorLogger.log('ComplaintResponseQueueable', e, createdCase.Id);
            }
        }
    }
}
