global class LeadEmailHandler implements Messaging.InboundEmailHandler {
    global Messaging.InboundEmailResult handleInboundEmail(
        Messaging.InboundEmail email, 
        Messaging.InboundEnvelope envelope
    ) {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
        
        List<Lead> leads = [
            SELECT Id FROM Lead 
            WHERE Email = :envelope.fromAddress 
            AND IsConverted = false
            LIMIT 1
        ];
        
        if (!leads.isEmpty()) {
            Task t = new Task();
            t.Subject = 'Odpowiedź email: ' + email.subject;
            t.Description = email.plainTextBody;
            t.Status = 'Completed';
            t.WhoId = leads[0].Id;
            t.ActivityDate = Date.today();
            insert t;
        }
        
        result.success = true;
        return result;
    }
}