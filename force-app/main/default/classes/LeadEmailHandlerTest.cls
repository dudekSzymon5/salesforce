@IsTest
private class LeadEmailHandlerTest {
    
    @TestSetup
    static void setupData() {
        Lead lead = new Lead(
            FirstName='Test',
            LastName='Lead',
            Company='TestCo',
            Email='test@test.com',
            IsConverted=false
        );
        insert lead;
    }
    
    @IsTest
    static void testHandleInboundEmail() {
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.subject = 'Test Subject';
        email.plainTextBody = 'Test Body';
        
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        envelope.fromAddress = 'test@test.com';
        
        Test.startTest();
        LeadEmailHandler handler = new LeadEmailHandler();
        Messaging.InboundEmailResult result = handler.handleInboundEmail(email, envelope);
        Test.stopTest();
        
        Assert.isTrue(result.success);
        Task t = [SELECT Subject FROM Task LIMIT 1];
        Assert.areEqual('Odpowiedź email: Test Subject', t.Subject);
    }
    
    @IsTest
    static void testHandleInboundEmailNoLead() {
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.subject = 'Test Subject';
        email.plainTextBody = 'Test Body';
        
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        envelope.fromAddress = 'nieistniejacy@test.com';
        
        Test.startTest();
        LeadEmailHandler handler = new LeadEmailHandler();
        Messaging.InboundEmailResult result = handler.handleInboundEmail(email, envelope);
        Test.stopTest();
        
        Assert.isTrue(result.success);
        Assert.areEqual(0, [SELECT COUNT() FROM Task]);
    }
}