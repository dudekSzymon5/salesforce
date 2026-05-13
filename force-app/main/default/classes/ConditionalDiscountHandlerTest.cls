@IsTest
private class ConditionalDiscountHandlerTest {

    private static final ConditionalDiscountHandler HANDLER = new ConditionalDiscountHandler();
    private static final Set<Id> NO_PRODUCTS = new Set<Id>();
    private static final Map<Id, Decimal> NO_QUANTITIES = new Map<Id, Decimal>();
    private static final Map<Id, String> NO_FAMILIES = new Map<Id, String>();

    @IsTest
    static void testBeforeStartDate_returnsFalse() {
        Discount__c discount = TestDataFactory.aDiscount()
            .conditional(null)
            .validFrom(Date.today().addDays(5))
            .build();

        Assert.isFalse(HANDLER.isApplicable(discount, 100, Date.today(), NO_PRODUCTS, NO_QUANTITIES, NO_FAMILIES, null));
    }

    @IsTest
    static void testAfterEndDate_returnsFalse() {
        Discount__c discount = TestDataFactory.aDiscount()
            .conditional(null)
            .validUntil(Date.today().addDays(-5))
            .build();

        Assert.isFalse(HANDLER.isApplicable(discount, 100, Date.today(), NO_PRODUCTS, NO_QUANTITIES, NO_FAMILIES, null));
    }

    @IsTest
    static void testWithinDateRange_noCondition_returnsTrue() {
        Discount__c discount = TestDataFactory.aDiscount()
            .conditional(null)
            .validFrom(Date.today().addDays(-5))
            .validUntil(Date.today().addDays(5))
            .build();

        Assert.isTrue(HANDLER.isApplicable(discount, 100, Date.today(), NO_PRODUCTS, NO_QUANTITIES, NO_FAMILIES, null));
    }

    @IsTest
    static void testNoDates_noCondition_returnsTrue() {
        Discount__c discount = TestDataFactory.aDiscount().conditional(null).build();

        Assert.isTrue(HANDLER.isApplicable(discount, 100, Date.today(), NO_PRODUCTS, NO_QUANTITIES, NO_FAMILIES, null));
    }

    @IsTest
    static void testMinOrderValue_amountBelowMinimum_returnsFalse() {
        Discount__c discount = TestDataFactory.aDiscount()
            .conditional(Utils.DISCOUNT.CONDITION.MIN_ORDER_VALUE)
            .withMinOrder(200)
            .build();

        Assert.isFalse(HANDLER.isApplicable(discount, 100, Date.today(), NO_PRODUCTS, NO_QUANTITIES, NO_FAMILIES, null));
    }

    @IsTest
    static void testMinOrderValue_amountMeetsMinimum_returnsTrue() {
        Discount__c discount = TestDataFactory.aDiscount()
            .conditional(Utils.DISCOUNT.CONDITION.MIN_ORDER_VALUE)
            .withMinOrder(50)
            .build();

        Assert.isTrue(HANDLER.isApplicable(discount, 100, Date.today(), NO_PRODUCTS, NO_QUANTITIES, NO_FAMILIES, null));
    }
}
