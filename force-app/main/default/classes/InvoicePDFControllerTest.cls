@IsTest
private class InvoicePDFControllerTest {
    
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
        
        Invoice__c inv = new Invoice__c(Order__c=ord.Id);
        insert inv;
    }
    
    @IsTest
    static void testController() {
        Invoice__c inv = [SELECT Id FROM Invoice__c LIMIT 1];
        ApexPages.StandardController sc = new ApexPages.StandardController(inv);
        Test.startTest();
        InvoicePDFController ctrl = new InvoicePDFController(sc);
        Test.stopTest();
        Assert.isNotNull(ctrl.invoice);
        Assert.isNotNull(ctrl.subtotal);
        Assert.isNotNull(ctrl.vatAmount);
        Assert.isNotNull(ctrl.total);
    }
}