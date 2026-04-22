global class LeadEmailReplyHandler implements Messaging.InboundEmailHandler {
    
    global Messaging.InboundEmailResult handleInboundEmail(
        Messaging.InboundEmail email, 
        Messaging.InboundEnvelope envelope
    ) {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
        
        String fromEmail = email.fromAddress;
        
        List<Lead> leads = [
            SELECT Id, Name 
            FROM Lead 
            WHERE Email = :fromEmail 
              AND IsConverted = false 
            ORDER BY CreatedDate DESC 
            LIMIT 1
        ];
        
        if (!leads.isEmpty()) {
            Task t = new Task();
            t.WhoId = leads[0].Id;
            t.Subject = 'Email Reply: ' + email.subject;
            t.Description = email.plainTextBody;
            t.Status = 'Completed';
            t.Type = 'Email';
            t.ActivityDate = Date.today();
            insert t;
        }
        
        result.success = true;
        return result;
    }
}