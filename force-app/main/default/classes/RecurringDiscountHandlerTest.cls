@IsTest
private class RecurringDiscountHandlerTest {

    private static final RecurringDiscountHandler HANDLER = new RecurringDiscountHandler();
    private static final Set<Id> NO_PRODUCTS = new Set<Id>();
    private static final Map<Id, Decimal> NO_QUANTITIES = new Map<Id, Decimal>();
    private static final Map<Id, String> NO_FAMILIES = new Map<Id, String>();

    @IsTest
    static void testEveryMondayOnMondayReturnsTrue() {
        // Zniżka co poniedziałek — sprawdzam że aktywuje się dokładnie w poniedziałek
        Date monday = Date.newInstance(2025, 5, 5);
        Discount__c discount = TestDataFactory.aDiscount()
            .recurring(Utils.DISCOUNT.RECURRENCE_PATTERN.EVERY_MONDAY)
            .build();

        Assert.isTrue(HANDLER.isApplicable(discount, 100, monday, NO_PRODUCTS, NO_QUANTITIES, NO_FAMILIES, null));
    }

    @IsTest
    static void testEveryMondayOnTuesdayReturnsFalse() {
        // Zniżka co poniedziałek — we wtorek nie powinna się aktywować
        Date tuesday = Date.newInstance(2025, 5, 6);
        Discount__c discount = TestDataFactory.aDiscount()
            .recurring(Utils.DISCOUNT.RECURRENCE_PATTERN.EVERY_MONDAY)
            .build();

        Assert.isFalse(HANDLER.isApplicable(discount, 100, tuesday, NO_PRODUCTS, NO_QUANTITIES, NO_FAMILIES, null));
    }

    @IsTest
    static void testLastDayOfMonthOnLastDayReturnsTrue() {
        // Zniżka ostatniego dnia miesiąca — 31 stycznia to ostatni dzień stycznia
        Date lastJan = Date.newInstance(2025, 1, 31);
        Discount__c discount = TestDataFactory.aDiscount()
            .recurring(Utils.DISCOUNT.RECURRENCE_PATTERN.LAST_DAY_OF_MONTH)
            .build();

        Assert.isTrue(HANDLER.isApplicable(discount, 100, lastJan, NO_PRODUCTS, NO_QUANTITIES, NO_FAMILIES, null));
    }

    @IsTest
    static void testLastDayOfMonthNotLastDayReturnsFalse() {
        // Zniżka ostatniego dnia miesiąca — w połowie miesiąca nie powinna się aktywować
        Date midJanuary = Date.newInstance(2025, 1, 15);
        Discount__c discount = TestDataFactory.aDiscount()
            .recurring(Utils.DISCOUNT.RECURRENCE_PATTERN.LAST_DAY_OF_MONTH)
            .build();

        Assert.isFalse(HANDLER.isApplicable(discount, 100, midJanuary, NO_PRODUCTS, NO_QUANTITIES, NO_FAMILIES, null));
    }

    @IsTest
    static void testBlackFridayOnBlackFriday2024ReturnsTrue() {
        // Black Friday 2024 to 22 listopada — czwarty piątek listopada
        Date blackFriday = Date.newInstance(2024, 11, 22);
        Discount__c discount = TestDataFactory.aDiscount()
            .recurring(Utils.DISCOUNT.RECURRENCE_PATTERN.BLACK_FRIDAY)
            .build();

        Assert.isTrue(HANDLER.isApplicable(discount, 100, blackFriday, NO_PRODUCTS, NO_QUANTITIES, NO_FAMILIES, null));
    }

    @IsTest
    static void testBlackFridayNotInNovemberReturnsFalse() {
        // Black Friday jest tylko w listopadzie — październik wypierdala
        Date october = Date.newInstance(2025, 10, 15);
        Discount__c discount = TestDataFactory.aDiscount()
            .recurring(Utils.DISCOUNT.RECURRENCE_PATTERN.BLACK_FRIDAY)
            .build();

        Assert.isFalse(HANDLER.isApplicable(discount, 100, october, NO_PRODUCTS, NO_QUANTITIES, NO_FAMILIES, null));
    }

    @IsTest
    static void testBlackFridayNovemberWrongDayReturnsFalse() {
        // Listopad, ale nie czwarty piątek — zniżka nie powinna się aktywować
        Date nov15 = Date.newInstance(2024, 11, 15);
        Discount__c discount = TestDataFactory.aDiscount()
            .recurring(Utils.DISCOUNT.RECURRENCE_PATTERN.BLACK_FRIDAY)
            .build();

        Assert.isFalse(HANDLER.isApplicable(discount, 100, nov15, NO_PRODUCTS, NO_QUANTITIES, NO_FAMILIES, null));
    }

    @IsTest
    static void testCustomDateSameMonthAndDayReturnsTrue() {
        // Data zniżki to 15 czerwca — sprawdzam że aktywuje się w tym samym miesiącu i dniu w innym roku
        Discount__c discount = TestDataFactory.aDiscount()
            .recurring(Utils.DISCOUNT.RECURRENCE_PATTERN.CUSTOM_DATE)
            .validFrom(Date.newInstance(2020, 6, 15))
            .build();

        Assert.isTrue(HANDLER.isApplicable(
            discount, 100, Date.newInstance(2025, 6, 15), NO_PRODUCTS, NO_QUANTITIES, NO_FAMILIES, null
        ));
    }

    @IsTest
    static void testCustomDateDifferentMonthReturnsFalse() {
        // Data zniżki to 15 czerwca — lipiec nie pasuje, nawet jeśli dzień się zgadza
        Discount__c discount = TestDataFactory.aDiscount()
            .recurring(Utils.DISCOUNT.RECURRENCE_PATTERN.CUSTOM_DATE)
            .validFrom(Date.newInstance(2020, 6, 15))
            .build();

        Assert.isFalse(HANDLER.isApplicable(
            discount, 100, Date.newInstance(2025, 7, 15), NO_PRODUCTS, NO_QUANTITIES, NO_FAMILIES, null
        ));
    }

    @IsTest
    static void testCustomDateNullStartDateReturnsFalse() {
        // Brak daty startowej przy CUSTOM_DATE — nie ma z czym porównać, więc zwraca false
        Discount__c discount = TestDataFactory.aDiscount()
            .recurring(Utils.DISCOUNT.RECURRENCE_PATTERN.CUSTOM_DATE)
            .build();

        Assert.isFalse(HANDLER.isApplicable(
            discount, 100, Date.today(), NO_PRODUCTS, NO_QUANTITIES, NO_FAMILIES, null
        ));
    }

    @IsTest
    static void testUnknownPatternReturnsFalse() {
        // wzorzec powtarzania — handler powinien bezpiecznie zwrócić false zamiast się wysypać
        Discount__c discount = TestDataFactory.aDiscount()
            .recurring('UnknownPatternXyz')
            .build();

        Assert.isFalse(HANDLER.isApplicable(
            discount, 100, Date.today(), NO_PRODUCTS, NO_QUANTITIES, NO_FAMILIES, null
        ));
    }
}
