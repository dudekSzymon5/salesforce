@IsTest
private class ConditionalDiscountHandlerTest {

    private static final ConditionalDiscountHandler HANDLER = new ConditionalDiscountHandler();
    private static final Set<Id> NO_PRODUCTS = new Set<Id>();
    private static final Map<Id, Decimal> NO_QUANTITIES = new Map<Id, Decimal>();
    private static final Map<Id, String> NO_FAMILIES = new Map<Id, String>();

    @IsTest
    static void testBeforeStartDateReturnsFalse() {
        Discount__c discount = TestDataFactory.discount()
            .conditional(null)
            .validFrom(Date.today().addDays(5)).build();

        Assert.isFalse(HANDLER.isApplicable(discount, 100, Date.today(), NO_PRODUCTS, NO_QUANTITIES, NO_FAMILIES, null));
    }

    @IsTest
    static void testAfterEndDateReturnsFalse() {
        Discount__c discount = TestDataFactory.discount()
            .conditional(null)
            .validUntil(Date.today().addDays(-5)).build();

        Assert.isFalse(HANDLER.isApplicable(discount, 100, Date.today(), NO_PRODUCTS, NO_QUANTITIES, NO_FAMILIES, null));
    }

    @IsTest
    static void testWithinDateRangeNoConditionReturnsTrue() {
        Discount__c discount = TestDataFactory.discount()
            .conditional(null)
            .validFrom(Date.today().addDays(-5))
            .validUntil(Date.today().addDays(5)).build();

        Assert.isTrue(HANDLER.isApplicable(discount, 100, Date.today(), NO_PRODUCTS, NO_QUANTITIES, NO_FAMILIES, null));
    }

    @IsTest
    static void testNoDatesNoConditionReturnsTrue() {
        Discount__c discount = TestDataFactory.discount().conditional(null).build();

        Assert.isTrue(HANDLER.isApplicable(discount, 100, Date.today(), NO_PRODUCTS, NO_QUANTITIES, NO_FAMILIES, null));
    }

    @IsTest
    static void testMinOrderValueAmountBelowMinimumReturnsFalse() {
        Discount__c discount = TestDataFactory.discount()
            .conditional(Utils.DISCOUNT.CONDITION.MIN_ORDER_VALUE)
            .withMinOrder(200).build();

        Assert.isFalse(HANDLER.isApplicable(discount, 100, Date.today(), NO_PRODUCTS, NO_QUANTITIES, NO_FAMILIES, null));
    }

    @IsTest
    static void testMinOrderValueAmountMeetsMinimumReturnsTrue() {
        Discount__c discount = TestDataFactory.discount()
            .conditional(Utils.DISCOUNT.CONDITION.MIN_ORDER_VALUE)
            .withMinOrder(50).build();

        Assert.isTrue(HANDLER.isApplicable(discount, 100, Date.today(), NO_PRODUCTS, NO_QUANTITIES, NO_FAMILIES, null));
    }
}
