@IsTest
private class OrderComplaintApprovalControllerTest {

    static OrderItem setupOrderWithProduct() {
        Account account = TestDataFactory.createAccount();
        Product2 product = TestDataFactory.product().create();
        PricebookEntry pricebookEntry = TestDataFactory.addToPricebook(product.Id, 100);
        Order order = TestDataFactory.order().forAccount(account.Id).create();
        OrderItem item = new OrderItem(
            OrderId = order.Id,
            PricebookEntryId = pricebookEntry.Id,
            Quantity = 1,
            UnitPrice = 100
        );
        insert item;
        order.Status = 'Activated';
        update order;
        return item;
    }

    @IsTest
    static void testGetCaseProducts() {
        OrderItem item = setupOrderWithProduct();
        OrderComplaintService.ComplaintResult result = OrderComplaintController.submitComplaint(
            item.OrderId, 'Test reason', 'Partial', new List<Id>{ item.Id }
        );

        Test.startTest();
        List<Case_Order_Product__c> products = OrderComplaintApprovalController.getCaseProducts(result.caseId);
        Test.stopTest();

        Assert.areEqual(1, products.size(), 'Should return one product for the case');
        Assert.areEqual(item.Id, products[0].Order_Product__c, 'Should be linked to the correct order item');
    }

    @IsTest
    static void testApproveComplaintNoWorkitem() {
        Case aCase = new Case(Status = 'New', Origin = 'Web');
        insert aCase;

        Test.startTest();
        try {
            OrderComplaintApprovalController.approveComplaint(aCase.Id, 'Partial', 'comment', null);
            Assert.fail('Expected AuraHandledException');
        } catch (AuraHandledException e) {
            Assert.isNotNull(e.getMessage());
        }
        Test.stopTest();
    }

    @IsTest
    static void testGetMaxRefundAmount() {
        OrderItem item = setupOrderWithProduct();
        OrderComplaintService.ComplaintResult result = OrderComplaintController.submitComplaint(
            item.OrderId, 'Test reason', 'Partial', new List<Id>{ item.Id }
        );

        Test.startTest();
        Decimal amount = OrderComplaintApprovalController.getMaxRefundAmount(result.caseId);
        Test.stopTest();

        Assert.isTrue(amount > 0, 'Max refund amount should reflect order item price');
        Assert.areEqual(100.00, amount, 'Should equal unit price * quantity');
    }

    @IsTest
    static void testGetMaxRefundAmountNoLocalProducts() {
        Case externalCase = new Case(
            Status = 'Closed',
            Origin = 'Web',
            Has_External_Product__c = true,
            Refund_Amount__c = 300.00
        );
        insert externalCase;

        Test.startTest();
        Decimal amount = OrderComplaintApprovalController.getMaxRefundAmount(externalCase.Id);
        Test.stopTest();

        Assert.areEqual(300.00, amount, 'Should fall back to Case.Refund_Amount__c when no local products');
    }
}
