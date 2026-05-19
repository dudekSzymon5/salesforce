public class ComplaintForwarderQueueable implements Queueable, Database.AllowsCallouts {

    private List<External_Complaint__e> events;

    public ComplaintForwarderQueueable(List<External_Complaint__e> events) {
        this.events = events;
    }

    public void execute(QueueableContext context) {

        Http httpClient = new Http();
        String endpoint = Utils.EXTERNAL_COMPLAINT.API.FORWARD_ENDPOINT;

        for (External_Complaint__e event : events) {
            HttpRequest request = new HttpRequest();
            request.setEndpoint(endpoint);
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json');

            Map<String, Object> payload = new Map<String, Object>{
                'Order_Id__c'    => event.Order_Id__c,
                'Case_Id__c'     => event.Case_Id__c,
                'Reason__c'      => event.Reason__c,
                'Product_Ids__c' => event.Product_Ids__c
            };

            String body = JSON.serialize(payload);
            request.setBody(body);

            try {
                ErrorLogger.logInfo('ComplaintForwarderQueueable', 'Sending External_Complaint__e | endpoint: ' + endpoint + ' | payload: ' + body);
                HttpResponse response = httpClient.send(request);

                if (response.getStatusCode() == 200 || response.getStatusCode() == 201) {
                    ErrorLogger.logInfo('ComplaintForwarderQueueable', 'Success | status: ' + response.getStatusCode() + ' | response: ' + response.getBody());
                } else {
                    ErrorLogger.logWarning('ComplaintForwarderQueueable', 'Rejected | status: ' + response.getStatusCode() + ' | response: ' + response.getBody(), 'Case_Id__c: ' + event.Case_Id__c);
                }
            } catch (Exception e) {
                ErrorLogger.log('ComplaintForwarderQueueable', e, event.Case_Id__c);
            }
        }
    }
}
