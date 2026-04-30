@IsTest
private class ProductSearchControllerTest {

    @TestSetup
    static void setupData() {
        Account acc = new Account(Name='Test Account');
        insert acc;

        Opportunity opp = new Opportunity(
            Name='Test Opp',
            AccountId=acc.Id,
            StageName='Prospecting',
            CloseDate=Date.today().addDays(30)
        );
        insert opp;

        Product2 prod = new Product2(
            Name='Test Product',
            Family='Software',
            IsActive=true
        );
        insert prod;

        Id pricebookId = Test.getStandardPricebookId();

        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id=pricebookId,
            Product2Id=prod.Id,
            UnitPrice=100,
            IsActive=true
        );
        insert pbe;

        opp.Pricebook2Id = pricebookId;
        update opp;
    }

    @IsTest
    static void testGetProducts() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        List<PricebookEntry> results = ProductSearchController.getProducts('Test', '', opp.Id);
        Test.stopTest();

        Assert.isTrue(results.size() > 0);
    }

    @IsTest
    static void testGetProductsNoFilter() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        List<PricebookEntry> results = ProductSearchController.getProducts('', '', opp.Id);
        Test.stopTest();

        Assert.isNotNull(results);
    }

    @IsTest
    static void testGetProductFamilies() {
        Test.startTest();
        List<String> families = ProductSearchController.getProductFamilies();
        Test.stopTest();

        Assert.isNotNull(families);
    }

    @IsTest
    static void testCreateOrder() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        PricebookEntry pbe = [SELECT Id, UnitPrice FROM PricebookEntry LIMIT 1];

        ProductSearchService.OrderLineItem item = new ProductSearchService.OrderLineItem();
        item.pricebookEntryId = pbe.Id;
        item.quantity = 2;
        item.unitPrice = pbe.UnitPrice;

        Test.startTest();
        Id orderId = ProductSearchController.createOrder(opp.Id, new List<ProductSearchService.OrderLineItem>{ item });
        Test.stopTest();

        Assert.isNotNull(orderId);
        Order ord = [SELECT Id, Status FROM Order WHERE Id = :orderId];
        Assert.areEqual('Draft', ord.Status);
    }
}