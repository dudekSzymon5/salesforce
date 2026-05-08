@IsTest
private class ConditionalDiscountHandlerTest {

    static Discount__c makeConditional() {
        return new Discount__c(
            Name = 'Test Conditional',
            Type__c = Utils.DISCOUNT.TYPE.CONDITIONAL,
            Discount_Form__c = Utils.DISCOUNT.FORM.PERCENTAGE,
            Value__c = 10,
            Is_Active__c = true
        );
    }

    @IsTest
    static void testBeforeStartDate_returnsFalse() {
        Discount__c d = makeConditional();
        d.Start_Date__c = Date.today().addDays(5);

        ConditionalDiscountHandler handler = new ConditionalDiscountHandler();
        Boolean result = handler.isApplicable(d, 100, Date.today(), new Set<Id>(), new Map<Id, Decimal>(), new Map<Id, String>(), null);

        Assert.isFalse(result);
    }

    @IsTest
    static void testAfterEndDate_returnsFalse() {
        Discount__c d = makeConditional();
        d.End_Date__c = Date.today().addDays(-5);

        ConditionalDiscountHandler handler = new ConditionalDiscountHandler();
        Boolean result = handler.isApplicable(d, 100, Date.today(), new Set<Id>(), new Map<Id, Decimal>(), new Map<Id, String>(), null);

        Assert.isFalse(result);
    }

    @IsTest
    static void testMinOrderValue_amountBelowMinimum_returnsFalse() {
        Discount__c d = makeConditional();
        d.Condition_Type__c = Utils.DISCOUNT.CONDITION.MIN_ORDER_VALUE;
        d.Minimum_Order_Amount__c = 200;

        ConditionalDiscountHandler handler = new ConditionalDiscountHandler();
        Boolean result = handler.isApplicable(d, 100, Date.today(), new Set<Id>(), new Map<Id, Decimal>(), new Map<Id, String>(), null);

        Assert.isFalse(result);
    }

    @IsTest
    static void testMinOrderValue_amountMeetsMinimum_returnsTrue() {
        Discount__c d = makeConditional();
        d.Condition_Type__c = Utils.DISCOUNT.CONDITION.MIN_ORDER_VALUE;
        d.Minimum_Order_Amount__c = 50;

        ConditionalDiscountHandler handler = new ConditionalDiscountHandler();
        Boolean result = handler.isApplicable(d, 100, Date.today(), new Set<Id>(), new Map<Id, Decimal>(), new Map<Id, String>(), null);

        Assert.isTrue(result);
    }

    @IsTest
    static void testWithinDateRange_noCondition_returnsTrue() {
        Discount__c d = makeConditional();
        d.Start_Date__c = Date.today().addDays(-5);
        d.End_Date__c = Date.today().addDays(5);

        ConditionalDiscountHandler handler = new ConditionalDiscountHandler();
        Boolean result = handler.isApplicable(d, 100, Date.today(), new Set<Id>(), new Map<Id, Decimal>(), new Map<Id, String>(), null);

        Assert.isTrue(result);
    }

    @IsTest
    static void testNoDates_noCondition_returnsTrue() {
        Discount__c d = makeConditional();

        ConditionalDiscountHandler handler = new ConditionalDiscountHandler();
        Boolean result = handler.isApplicable(d, 100, Date.today(), new Set<Id>(), new Map<Id, Decimal>(), new Map<Id, String>(), null);

        Assert.isTrue(result);
    }
}
