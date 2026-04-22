@IsTest
private class InvoiceManagerTest {
    
    @TestSetup
    static void setupData() {
        Account acc = new Account(Name='Test Account');
        insert acc;
        
        Contract con = new Contract(
            AccountId=acc.Id,
            StartDate=Date.today(),
            ContractTerm=12,
            Status='Draft'
        );
        insert con;
        con.Status = 'Activated';
        update con;
        
        Order ord = new Order(
            AccountId=acc.Id,
            ContractId=con.Id,
            Status='Draft',
            EffectiveDate=Date.today(),
            Pricebook2Id=Test.getStandardPricebookId()
        );
        insert ord;
        
        Product2 prod = new Product2(Name='Test Product', IsActive=true);
        insert prod;
        
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id=Test.getStandardPricebookId(),
            Product2Id=prod.Id,
            UnitPrice=100,
            IsActive=true
        );
        insert pbe;
        
        OrderItem item = new OrderItem(
            OrderId=ord.Id,
            PricebookEntryId=pbe.Id,
            Quantity=1,
            UnitPrice=100
        );
        insert item;
        
        ord.Status = 'Activated';
        update ord;
        
        Invoice__c inv = new Invoice__c(
            Order__c=ord.Id,
            Status__c='Unsigned'
        );
        insert inv;
    }
    
    @IsTest
    static void testGenerateInvoiceFromFlow() {
        Invoice__c inv = [SELECT Id FROM Invoice__c LIMIT 1];
        
        Test.startTest();
        InvoiceManager.generateInvoiceFromFlow(new List<Id>{ inv.Id });
        Test.stopTest();
        
        Order ord = [SELECT Invoice_Status__c FROM Order LIMIT 1];
        Assert.areEqual('Unsigned', ord.Invoice_Status__c);
    }
    
    @IsTest
    static void testSignAndRegenerateInvoice() {
        Order ord = [SELECT Id FROM Order LIMIT 1];
        String fakeSignature = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';
        
        Test.startTest();
        String result = InvoiceManager.signAndRegenerateInvoice(ord.Id, fakeSignature);
        Test.stopTest();
        
        Assert.areEqual('Success', result);
    }
}