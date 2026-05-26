@IsTest
private class ExternalComplaintResponseTriggerTest {

    static Order createOrderWithCorrelation(String correlationId) {
        Account account = TestDataFactory.createAccount();
        Order order = TestDataFactory.order().forAccount(account.Id).create();
        update new Order(
            Id = order.Id,
            External_Complaint_Correlation_Id__c = correlationId,
            Pending_Complaint_JSON__c = '{"reason":"Test","expectedRefundType":"Full","localItemIds":[]}'
        );
        return order;
    }

    @IsTest
    static void testTriggerNoMatchingOrder() {
        String correlationId = 'test-uuid-no-match';

        Test.startTest();
        EventBus.publish(new External_Complaint_Response__e(
            Case_Id__c = correlationId,
            Status__c = Utils.EXTERNAL_COMPLAINT.RESPONSE_STATUS.APPROVED_FULL
        ));
        Test.stopTest();

        List<Case> cases = [SELECT Id FROM Case WHERE External_Case_Id__c = :correlationId];
        Assert.areEqual(0, cases.size(), 'No Case should be created when Order is not found');
    }

    @IsTest
    static void testTriggerApprovedFullCreatesCase() {
        String correlationId = 'test-uuid-approved-full';
        Order order = createOrderWithCorrelation(correlationId);

        Test.startTest();
        EventBus.publish(new External_Complaint_Response__e(
            Case_Id__c = correlationId,
            Status__c = Utils.EXTERNAL_COMPLAINT.RESPONSE_STATUS.APPROVED_FULL,
            Final_Refund_Type__c = Utils.ORDER_COMPLAINT.REFUND_TYPE.FULL,
            Final_Refund_Amount__c = 200.00
        ));
        Test.stopTest();

        List<Case> cases = [
            SELECT Id, Refund_Status__c, Status, Has_External_Product__c, Refund_Amount__c
            FROM Case
            WHERE Order__c = :order.Id
        ];
        Assert.areEqual(1, cases.size(), 'Should create one Case from external approved response');
        Assert.areEqual(Utils.ORDER_COMPLAINT.REFUND_STATUS.APPROVED, cases[0].Refund_Status__c);
        Assert.areEqual(Utils.ORDER_COMPLAINT.CASE_STATUS.CLOSED, cases[0].Status);
        Assert.isTrue(cases[0].Has_External_Product__c);
        Assert.areEqual(200.00, cases[0].Refund_Amount__c);

        Order updatedOrder = [SELECT External_Complaint_Correlation_Id__c, Refund_Amount__c, ComplaintCaseId__c FROM Order WHERE Id = :order.Id];
        Assert.isNull(updatedOrder.External_Complaint_Correlation_Id__c, 'CorrelationId should be cleared');
        Assert.areEqual(200.00, updatedOrder.Refund_Amount__c);
        Assert.areEqual(cases[0].Id, updatedOrder.ComplaintCaseId__c);
    }

    @IsTest
    static void testTriggerRejectedCreatesCase() {
        String correlationId = 'test-uuid-rejected';
        Order order = createOrderWithCorrelation(correlationId);

        Test.startTest();
        EventBus.publish(new External_Complaint_Response__e(
            Case_Id__c = correlationId,
            Status__c = Utils.EXTERNAL_COMPLAINT.RESPONSE_STATUS.REJECTED
        ));
        Test.stopTest();

        List<Case> cases = [
            SELECT Id, Refund_Status__c, Status
            FROM Case
            WHERE Order__c = :order.Id
        ];
        Assert.areEqual(1, cases.size(), 'Should create one Case from external rejected response');
        Assert.areEqual(Utils.ORDER_COMPLAINT.REFUND_STATUS.REJECTED, cases[0].Refund_Status__c);
        Assert.areEqual(Utils.ORDER_COMPLAINT.CASE_STATUS.CLOSED, cases[0].Status);

        Order updatedOrder = [SELECT External_Complaint_Correlation_Id__c FROM Order WHERE Id = :order.Id];
        Assert.isNull(updatedOrder.External_Complaint_Correlation_Id__c);
    }

    @IsTest
    static void testTriggerMixedApprovedCreatesPendingCase() {
        String correlationId = 'test-uuid-mixed-approved';
        Account account = TestDataFactory.createAccount();
        Product2 localProduct = TestDataFactory.product().create();
        PricebookEntry localEntry = TestDataFactory.addToPricebook(localProduct.Id, 50);
        Order order = TestDataFactory.order().forAccount(account.Id).create();
        OrderItem localItem = new OrderItem(OrderId = order.Id, PricebookEntryId = localEntry.Id, Quantity = 1, UnitPrice = 50);
        insert localItem;

        update new Order(
            Id = order.Id,
            External_Complaint_Correlation_Id__c = correlationId,
            Pending_Complaint_JSON__c = JSON.serialize(new Map<String, Object>{
                'reason' => 'Mixed test',
                'expectedRefundType' => 'Full',
                'localItemIds' => new List<Id>{ localItem.Id }
            })
        );

        Test.startTest();
        EventBus.publish(new External_Complaint_Response__e(
            Case_Id__c = correlationId,
            Status__c = Utils.EXTERNAL_COMPLAINT.RESPONSE_STATUS.APPROVED_FULL,
            Final_Refund_Type__c = Utils.ORDER_COMPLAINT.REFUND_TYPE.FULL,
            Final_Refund_Amount__c = 100.00
        ));
        Test.stopTest();

        List<Case> cases = [SELECT Id, Refund_Status__c, Status FROM Case WHERE Order__c = :order.Id];
        Assert.areEqual(1, cases.size(), 'Should create one Case from external response');
        Assert.areEqual(Utils.ORDER_COMPLAINT.REFUND_STATUS.PENDING, cases[0].Refund_Status__c);
        Assert.areEqual(Utils.ORDER_COMPLAINT.CASE_STATUS.NEW_CASE, cases[0].Status);
    }

    @IsTest
    static void testTriggerMixedRejectedClosesCase() {
        String correlationId = 'test-uuid-mixed-rejected';
        Account account = TestDataFactory.createAccount();
        Product2 localProduct = TestDataFactory.product().create();
        PricebookEntry localEntry = TestDataFactory.addToPricebook(localProduct.Id, 50);
        Order order = TestDataFactory.order().forAccount(account.Id).create();
        OrderItem localItem = new OrderItem(OrderId = order.Id, PricebookEntryId = localEntry.Id, Quantity = 1, UnitPrice = 50);
        insert localItem;

        update new Order(
            Id = order.Id,
            External_Complaint_Correlation_Id__c = correlationId,
            Pending_Complaint_JSON__c = JSON.serialize(new Map<String, Object>{
                'reason' => 'Mixed rejected test',
                'expectedRefundType' => 'Full',
                'localItemIds' => new List<Id>{ localItem.Id }
            })
        );

        Test.startTest();
        EventBus.publish(new External_Complaint_Response__e(
            Case_Id__c = correlationId,
            Status__c = Utils.EXTERNAL_COMPLAINT.RESPONSE_STATUS.REJECTED
        ));
        Test.stopTest();

        List<Case> cases = [SELECT Id, Refund_Status__c, Status FROM Case WHERE Order__c = :order.Id];
        Assert.areEqual(1, cases.size(), 'Should create one Case even when external rejects');
        Assert.areEqual(Utils.ORDER_COMPLAINT.REFUND_STATUS.REJECTED, cases[0].Refund_Status__c);
        Assert.areEqual(Utils.ORDER_COMPLAINT.CASE_STATUS.CLOSED, cases[0].Status);
    }

    @IsTest
    static void testTriggerIgnoresUnknownStatus() {
        String correlationId = 'test-uuid-unknown-status';
        Order order = createOrderWithCorrelation(correlationId);

        Test.startTest();
        EventBus.publish(new External_Complaint_Response__e(
            Case_Id__c = correlationId,
            Status__c = 'Created'
        ));
        Test.stopTest();

        List<Case> cases = [SELECT Id FROM Case WHERE Order__c = :order.Id];
        Assert.areEqual(0, cases.size(), 'Unknown status should not create a Case');
    }
}
