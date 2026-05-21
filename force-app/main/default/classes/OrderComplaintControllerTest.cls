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
        OrderComplaintController.ComplaintResult result = OrderComplaintController.submitComplaint(
            item.OrderId, 'Test reason', 'Partial', new List<Id>{ item.Id }
        );
        Test.stopTest();

        Assert.isNotNull(result.caseId, 'Should return a Case ID for local product');
        Assert.isNull(result.correlationId, 'Should not return a correlation ID for local-only complaint');

        Case aCase = [SELECT Id, Complaint_Reason__c, Expected_Refund_Type__c FROM Case WHERE Id = :result.caseId];
        Assert.areEqual('Test reason', aCase.Complaint_Reason__c);
        Assert.areEqual('Partial', aCase.Expected_Refund_Type__c);

        List<Case_Order_Product__c> lines = [SELECT Id FROM Case_Order_Product__c WHERE Case__c = :result.caseId];
        Assert.areEqual(1, lines.size());
    }

    @IsTest
    static void testSubmitComplaintExternalProduct() {
        Test.setMock(HttpCalloutMock.class, new TestDataFactory.HttpMock(201, SUCCESS_BODY));
        OrderItem item = setupOrderWithProduct(true);

        Test.startTest();
        OrderComplaintController.ComplaintResult result = OrderComplaintController.submitComplaint(
            item.OrderId, 'External reason', 'Full', new List<Id>{ item.Id }
        );
        Test.stopTest();

        Assert.isNotNull(result.correlationId, 'Should return a correlation UUID for external product');
        Assert.isTrue(result.correlationId.contains('-'), 'Correlation ID should be a UUID');
        Assert.isNotNull(result.caseId, 'Should create a local tracking Case for external-only complaint');

        Case trackingCase = [SELECT Id, External_Case_Id__c, Refund_Status__c FROM Case WHERE Id = :result.caseId];
        Assert.areEqual(result.correlationId, trackingCase.External_Case_Id__c, 'Tracking Case should store correlationId in External_Case_Id__c');
        Assert.areEqual('Pending', trackingCase.Refund_Status__c);

        List<Case_Order_Product__c> lines = [SELECT Id FROM Case_Order_Product__c WHERE Case__c = :result.caseId];
        Assert.areEqual(1, lines.size(), 'External product should be linked to tracking Case');
    }

    @IsTest
    static void testSubmitComplaintMixedProducts() {
        Test.setMock(HttpCalloutMock.class, new TestDataFactory.HttpMock(201, SUCCESS_BODY));

        Account account = TestDataFactory.createAccount();
        Product2 localProduct = TestDataFactory.product().create();
        Product2 externalProduct = TestDataFactory.product().external().create();

        PricebookEntry localEntry = TestDataFactory.addToPricebook(localProduct.Id, 100);
        PricebookEntry externalEntry = TestDataFactory.addToPricebook(externalProduct.Id, 200);

        Order order = TestDataFactory.order().forAccount(account.Id).create();

        OrderItem localItem = new OrderItem(OrderId = order.Id, PricebookEntryId = localEntry.Id, Quantity = 1, UnitPrice = 100);
        OrderItem externalItem = new OrderItem(OrderId = order.Id, PricebookEntryId = externalEntry.Id, Quantity = 2, UnitPrice = 200);
        insert new List<OrderItem>{ localItem, externalItem };

        Test.startTest();
        OrderComplaintController.ComplaintResult result = OrderComplaintController.submitComplaint(
            order.Id, 'Mixed reason', 'Partial', new List<Id>{ localItem.Id, externalItem.Id }
        );
        Test.stopTest();

        Assert.isNotNull(result.caseId, 'Should create a local Case for local product');
        Assert.isNotNull(result.correlationId, 'Should return a correlation UUID for external product');
        Assert.isTrue(result.correlationId.contains('-'), 'Correlation ID should be a UUID');

        Case aCase = [SELECT Id, Complaint_Reason__c FROM Case WHERE Id = :result.caseId];
        Assert.areEqual('Mixed reason', aCase.Complaint_Reason__c);

        List<Case_Order_Product__c> lines = [SELECT Id FROM Case_Order_Product__c WHERE Case__c = :result.caseId];
        Assert.areEqual(1, lines.size(), 'Only local product should be linked to the local Case');
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
