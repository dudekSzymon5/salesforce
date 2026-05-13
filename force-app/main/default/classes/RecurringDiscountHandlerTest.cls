@IsTest
private class RecurringDiscountHandlerTest {

    private static final RecurringDiscountHandler HANDLER = new RecurringDiscountHandler();
    private static final Set<Id> NO_PRODUCTS = new Set<Id>();
    private static final Map<Id, Decimal> NO_QUANTITIES = new Map<Id, Decimal>();
    private static final Map<Id, String> NO_FAMILIES = new Map<Id, String>();

    @IsTest
    static void testEveryMonday_onMonday_returnsTrue() {
        Date monday = Date.newInstance(2025, 5, 5);
        Discount__c discount = TestDataFactory.aDiscount()
            .recurring(Utils.DISCOUNT.RECURRENCE_PATTERN.EVERY_MONDAY)
            .build();

        Assert.isTrue(HANDLER.isApplicable(discount, 100, monday, NO_PRODUCTS, NO_QUANTITIES, NO_FAMILIES, null));
    }

    @IsTest
    static void testEveryMonday_onTuesday_returnsFalse() {
        Date tuesday = Date.newInstance(2025, 5, 6);
        Discount__c discount = TestDataFactory.aDiscount()
            .recurring(Utils.DISCOUNT.RECURRENCE_PATTERN.EVERY_MONDAY)
            .build();

        Assert.isFalse(HANDLER.isApplicable(discount, 100, tuesday, NO_PRODUCTS, NO_QUANTITIES, NO_FAMILIES, null));
    }

    @IsTest
    static void testLastDayOfMonth_onLastDay_returnsTrue() {
        Date lastJan = Date.newInstance(2025, 1, 31);
        Discount__c discount = TestDataFactory.aDiscount()
            .recurring(Utils.DISCOUNT.RECURRENCE_PATTERN.LAST_DAY_OF_MONTH)
            .build();

        Assert.isTrue(HANDLER.isApplicable(discount, 100, lastJan, NO_PRODUCTS, NO_QUANTITIES, NO_FAMILIES, null));
    }

    @IsTest
    static void testLastDayOfMonth_notLastDay_returnsFalse() {
        Date midJanuary = Date.newInstance(2025, 1, 15);
        Discount__c discount = TestDataFactory.aDiscount()
            .recurring(Utils.DISCOUNT.RECURRENCE_PATTERN.LAST_DAY_OF_MONTH)
            .build();

        Assert.isFalse(HANDLER.isApplicable(discount, 100, midJanuary, NO_PRODUCTS, NO_QUANTITIES, NO_FAMILIES, null));
    }

    @IsTest
    static void testBlackFriday_onBlackFriday2024_returnsTrue() {
        Date blackFriday = Date.newInstance(2024, 11, 22);
        Discount__c discount = TestDataFactory.aDiscount()
            .recurring(Utils.DISCOUNT.RECURRENCE_PATTERN.BLACK_FRIDAY)
            .build();

        Assert.isTrue(HANDLER.isApplicable(discount, 100, blackFriday, NO_PRODUCTS, NO_QUANTITIES, NO_FAMILIES, null));
    }

    @IsTest
    static void testBlackFriday_notInNovember_returnsFalse() {
        Date october = Date.newInstance(2025, 10, 15);
        Discount__c discount = TestDataFactory.aDiscount()
            .recurring(Utils.DISCOUNT.RECURRENCE_PATTERN.BLACK_FRIDAY)
            .build();

        Assert.isFalse(HANDLER.isApplicable(discount, 100, october, NO_PRODUCTS, NO_QUANTITIES, NO_FAMILIES, null));
    }

    @IsTest
    static void testBlackFriday_novemberWrongDay_returnsFalse() {
        Date nov15 = Date.newInstance(2024, 11, 15);
        Discount__c discount = TestDataFactory.aDiscount()
            .recurring(Utils.DISCOUNT.RECURRENCE_PATTERN.BLACK_FRIDAY)
            .build();

        Assert.isFalse(HANDLER.isApplicable(discount, 100, nov15, NO_PRODUCTS, NO_QUANTITIES, NO_FAMILIES, null));
    }

    @IsTest
    static void testCustomDate_sameMonthAndDay_returnsTrue() {
        Discount__c discount = TestDataFactory.aDiscount()
            .recurring(Utils.DISCOUNT.RECURRENCE_PATTERN.CUSTOM_DATE)
            .validFrom(Date.newInstance(2020, 6, 15))
            .build();

        Assert.isTrue(HANDLER.isApplicable(
            discount, 100, Date.newInstance(2025, 6, 15), NO_PRODUCTS, NO_QUANTITIES, NO_FAMILIES, null
        ));
    }

    @IsTest
    static void testCustomDate_differentMonth_returnsFalse() {
        Discount__c discount = TestDataFactory.aDiscount()
            .recurring(Utils.DISCOUNT.RECURRENCE_PATTERN.CUSTOM_DATE)
            .validFrom(Date.newInstance(2020, 6, 15))
            .build();

        Assert.isFalse(HANDLER.isApplicable(
            discount, 100, Date.newInstance(2025, 7, 15), NO_PRODUCTS, NO_QUANTITIES, NO_FAMILIES, null
        ));
    }

    @IsTest
    static void testCustomDate_nullStartDate_returnsFalse() {
        Discount__c discount = TestDataFactory.aDiscount()
            .recurring(Utils.DISCOUNT.RECURRENCE_PATTERN.CUSTOM_DATE)
            .build();

        Assert.isFalse(HANDLER.isApplicable(
            discount, 100, Date.today(), NO_PRODUCTS, NO_QUANTITIES, NO_FAMILIES, null
        ));
    }

    @IsTest
    static void testUnknownPattern_returnsFalse() {
        Discount__c discount = TestDataFactory.aDiscount()
            .recurring('UnknownPatternXyz')
            .build();

        Assert.isFalse(HANDLER.isApplicable(
            discount, 100, Date.today(), NO_PRODUCTS, NO_QUANTITIES, NO_FAMILIES, null
        ));
    }
}
