@IsTest
private class OrderComplaintControllerTest {

    private static final String SUCCESS_BODY = '{"id":"e02xx0000000001AAA","success":true,"errors":[]}';

    static OrderItem setupOrderWithProduct(Boolean isExternal) {
        Account acc = TestDataFactory.createAccount();
        Product2 product = isExternal
            ? TestDataFactory.product().external().create()
            : TestDataFactory.product().create();
        PricebookEntry pbe = TestDataFactory.addToPricebook(product.Id, 100);
        Order ord = TestDataFactory.order().forAccount(acc.Id).create();
        OrderItem item = new OrderItem(
            OrderId = ord.Id,
            PricebookEntryId = pbe.Id,
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
        Id caseId = OrderComplaintController.submitComplaint(
            item.OrderId, 'Test reason', 'Partial', new List<Id>{ item.Id }
        );
        Test.stopTest();

        Case c = [SELECT Id, Complaint_Reason__c, Expected_Refund_Type__c, Has_External_Product__c FROM Case WHERE Id = :caseId];
        Assert.areEqual('Test reason', c.Complaint_Reason__c);
        Assert.areEqual('Partial', c.Expected_Refund_Type__c);
        Assert.isFalse(c.Has_External_Product__c);

        List<Case_Order_Product__c> lines = [SELECT Id FROM Case_Order_Product__c WHERE Case__c = :caseId];
        Assert.areEqual(1, lines.size());
    }

    @IsTest
    static void testSubmitComplaintExternalProduct() {
        Test.setMock(HttpCalloutMock.class, new TestDataFactory.HttpMock(201, SUCCESS_BODY));
        OrderItem item = setupOrderWithProduct(true);

        Test.startTest();
        Id caseId = OrderComplaintController.submitComplaint(
            item.OrderId, 'External reason', 'Full', new List<Id>{ item.Id }
        );
        Test.stopTest();

        Case c = [SELECT Id, Has_External_Product__c FROM Case WHERE Id = :caseId];
        Assert.isTrue(c.Has_External_Product__c);

        List<Case_Order_Product__c> lines = [SELECT Id, Is_External__c FROM Case_Order_Product__c WHERE Case__c = :caseId];
        Assert.areEqual(1, lines.size());
        Assert.isTrue(lines[0].Is_External__c);
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
