@IsTest
private class ConditionalDiscountHandlerTest {

    private static final ConditionalDiscountHandler HANDLER = new ConditionalDiscountHandler();
    private static final Set<Id> NO_PRODUCTS = new Set<Id>();
    private static final Map<Id, Decimal> NO_QUANTITIES = new Map<Id, Decimal>();
    private static final Map<Id, String> NO_FAMILIES = new Map<Id, String>();

    @IsTest
    static void testBeforeStartDateReturnsFalse() {
        // Zniżka jeszcze nie zaczęła obowiązywać — start za 5 dni, dziś nie powinna działać
        Discount__c discount = TestDataFactory.aDiscount()
            .conditional(null)
            .validFrom(Date.today().addDays(5))
            .build();

        Assert.isFalse(HANDLER.isApplicable(discount, 100, Date.today(), NO_PRODUCTS, NO_QUANTITIES, NO_FAMILIES, null));
    }

    @IsTest
    static void testAfterEndDateReturnsFalse() {
        // Zniżka już wygasła — koniec był 5 dni temu, dziś nie powinna działać
        Discount__c discount = TestDataFactory.aDiscount()
            .conditional(null)
            .validUntil(Date.today().addDays(-5))
            .build();

        Assert.isFalse(HANDLER.isApplicable(discount, 100, Date.today(), NO_PRODUCTS, NO_QUANTITIES, NO_FAMILIES, null));
    }

    @IsTest
    static void testWithinDateRangeNoConditionReturnsTrue() {
        // Dziś jest w środku okresu, brak dodatkowego warunku — zniżka powinna działać
        Discount__c discount = TestDataFactory.aDiscount()
            .conditional(null)
            .validFrom(Date.today().addDays(-5))
            .validUntil(Date.today().addDays(5))
            .build();

        Assert.isTrue(HANDLER.isApplicable(discount, 100, Date.today(), NO_PRODUCTS, NO_QUANTITIES, NO_FAMILIES, null));
    }

    @IsTest
    static void testNoDatesNoConditionReturnsTrue() {
        // Brak dat i brak warunku — zniżka bezterminowa, zawsze powinna działać
        Discount__c discount = TestDataFactory.aDiscount().conditional(null).build();

        Assert.isTrue(HANDLER.isApplicable(discount, 100, Date.today(), NO_PRODUCTS, NO_QUANTITIES, NO_FAMILIES, null));
    }

    @IsTest
    static void testMinOrderValueAmountBelowMinimumReturnsFalse() {
        // Zamówienie za 100, minimum to 200 — warunek nie spełniony, zniżka nie działa
        Discount__c discount = TestDataFactory.aDiscount()
            .conditional(Utils.DISCOUNT.CONDITION.MIN_ORDER_VALUE)
            .withMinOrder(200)
            .build();

        Assert.isFalse(HANDLER.isApplicable(discount, 100, Date.today(), NO_PRODUCTS, NO_QUANTITIES, NO_FAMILIES, null));
    }

    @IsTest
    static void testMinOrderValueAmountMeetsMinimumReturnsTrue() {
        // Zamówienie za 100, minimum to 50 — warunek spełniony, zniżka działa
        Discount__c discount = TestDataFactory.aDiscount()
            .conditional(Utils.DISCOUNT.CONDITION.MIN_ORDER_VALUE)
            .withMinOrder(50)
            .build();

        Assert.isTrue(HANDLER.isApplicable(discount, 100, Date.today(), NO_PRODUCTS, NO_QUANTITIES, NO_FAMILIES, null));
    }
}
