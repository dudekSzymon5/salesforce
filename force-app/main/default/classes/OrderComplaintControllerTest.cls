@IsTest
private class OrderComplaintControllerTest {

    private static final String SUCCESS_BODY = '{"id":"e02xx0000000001AAA","success":true,"errors":[]}';

    static OrderItem setupOrderWithProduct(Boolean isExternal) {
        Account account = TestDataFactory.createAccount();
        Product2 product = isExternal ? TestDataFactory.product().external().create() : TestDataFactory.product().create();

        PricebookEntry pricebookEntry = TestDataFactory.addToPricebook(product.Id, 100);
        Order order = TestDataFactory.order().forAccount(account.Id).create();
        OrderItem item = new OrderItem(
            OrderId = order.Id,
            PricebookEntryId = pricebookEntry.Id,
            Quantity = 1,
            UnitPrice = 100
        );
        insert item;
        return item;
    }

    @IsTest
    static void testGetOrderProducts() {
        OrderItem item = setupOrderWithProduct(false);

        Test.startTest();
        List<OrderItem> result = OrderComplaintController.getOrderProducts(item.OrderId);
        Test.stopTest();

        Assert.areEqual(1, result.size());
        Assert.areEqual(item.Id, result[0].Id);
    }

    @IsTest
    static void testSubmitComplaintInternalProduct() {
        OrderItem item = setupOrderWithProduct(false);

        Test.startTest();
        String result = OrderComplaintController.submitComplaint(
            item.OrderId, 'Test reason', 'Partial', new List<Id>{ item.Id }
        );
        Test.stopTest();

        Case aCase = [SELECT Id, Complaint_Reason__c, Expected_Refund_Type__c FROM Case WHERE Id = :result];
        Assert.areEqual('Test reason', aCase.Complaint_Reason__c);
        Assert.areEqual('Partial', aCase.Expected_Refund_Type__c);

        List<Case_Order_Product__c> lines = [SELECT Id FROM Case_Order_Product__c WHERE Case__c = :result];
        Assert.areEqual(1, lines.size());
    }

    @IsTest
    static void testSubmitComplaintExternalProduct() {
        Test.setMock(HttpCalloutMock.class, new TestDataFactory.HttpMock(201, SUCCESS_BODY));
        OrderItem item = setupOrderWithProduct(true);

        Test.startTest();
        String correlationId = OrderComplaintController.submitComplaint(
            item.OrderId, 'External reason', 'Full', new List<Id>{ item.Id }
        );
        Test.stopTest();

        Assert.isNotNull(correlationId, 'Should return a correlation UUID');
        Assert.isTrue(correlationId.contains('-'), 'Correlation ID should be a UUID');

        List<Case> cases = [SELECT Id FROM Case WHERE Order__c = :item.OrderId];
        Assert.areEqual(0, cases.size(), 'No local Case should be created for external products');
    }

    @IsTest
    static void testApproveComplaintNoWorkitem() {
        Case aCase = new Case(Status = 'New', Origin = 'Web');
        insert aCase;

        Test.startTest();
        try {
            OrderComplaintController.approveComplaint(aCase.Id, 'Partial', 'comment', 'Approve');
            Assert.fail('Expected AuraHandledException');
        } catch (AuraHandledException e) {
            Assert.isNotNull(e.getMessage());
        }
        Test.stopTest();
    }
}
