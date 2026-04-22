@IsTest
private class LeadEmailReplyHandlerTest {
    
    @TestSetup
    static void setupData() {
        Lead lead = new Lead(
            FirstName='Test',
            LastName='Lead',
            Company='TestCo',
            Email='reply@test.com',
            IsConverted=false
        );
        insert lead;
    }
    
    @IsTest
    static void testHandleInboundEmailWithLead() {
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.subject = 'Re: Test';
        email.plainTextBody = 'Reply body';
        email.fromAddress = 'reply@test.com';
        
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        envelope.fromAddress = 'reply@test.com';
        
        Test.startTest();
        LeadEmailReplyHandler handler = new LeadEmailReplyHandler();
        Messaging.InboundEmailResult result = handler.handleInboundEmail(email, envelope);
        Test.stopTest();
        
        Assert.isTrue(result.success);
        Task t = [SELECT Subject, Type FROM Task LIMIT 1];
        Assert.areEqual('Email Reply: Re: Test', t.Subject);
        Assert.areEqual('Email', t.Type);
    }
    
    @IsTest
    static void testHandleInboundEmailNoLead() {
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.subject = 'Re: Test';
        email.plainTextBody = 'Reply body';
        email.fromAddress = 'brak@test.com';
        
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        envelope.fromAddress = 'brak@test.com';
        
        Test.startTest();
        LeadEmailReplyHandler handler = new LeadEmailReplyHandler();
        Messaging.InboundEmailResult result = handler.handleInboundEmail(email, envelope);
        Test.stopTest();
        
        Assert.isTrue(result.success);
        Assert.areEqual(0, [SELECT COUNT() FROM Task]);
    }
}