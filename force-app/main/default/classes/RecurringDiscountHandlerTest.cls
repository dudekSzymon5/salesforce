@IsTest
private class RecurringDiscountHandlerTest {

    static Discount__c makeRecurring(String pattern) {
        return new Discount__c(
            Name = 'Test Recurring',
            Type__c = 'Recurring',
            Discount_Form__c = 'Percentage',
            Value__c = 10,
            Is_Active__c = true,
            Recurrence_Pattern__c = pattern
        );
    }

    @IsTest
    static void testEveryMonday_onMonday_returnsTrue() {
        // May 5, 2025 is a Monday
        Date monday = Date.newInstance(2025, 5, 5);
        Discount__c d = makeRecurring('Every Monday');

        RecurringDiscountHandler handler = new RecurringDiscountHandler();
        Boolean result = handler.isApplicable(d, 100, monday, new Set<Id>(), new Map<Id, Decimal>(), new Map<Id, String>(), null);

        Assert.isTrue(result);
    }

    @IsTest
    static void testEveryMonday_onTuesday_returnsFalse() {
        // May 6, 2025 is a Tuesday
        Date tuesday = Date.newInstance(2025, 5, 6);
        Discount__c d = makeRecurring('Every Monday');

        RecurringDiscountHandler handler = new RecurringDiscountHandler();
        Boolean result = handler.isApplicable(d, 100, tuesday, new Set<Id>(), new Map<Id, Decimal>(), new Map<Id, String>(), null);

        Assert.isFalse(result);
    }

    @IsTest
    static void testLastDayOfMonth_onLastDay_returnsTrue() {
        // January 31 is always the last day of January
        Date lastDayJan = Date.newInstance(2025, 1, 31);
        Discount__c d = makeRecurring('Last Day of Month');

        RecurringDiscountHandler handler = new RecurringDiscountHandler();
        Boolean result = handler.isApplicable(d, 100, lastDayJan, new Set<Id>(), new Map<Id, Decimal>(), new Map<Id, String>(), null);

        Assert.isTrue(result);
    }

    @IsTest
    static void testLastDayOfMonth_notLastDay_returnsFalse() {
        Date mid = Date.newInstance(2025, 1, 15);
        Discount__c d = makeRecurring('Last Day of Month');

        RecurringDiscountHandler handler = new RecurringDiscountHandler();
        Boolean result = handler.isApplicable(d, 100, mid, new Set<Id>(), new Map<Id, Decimal>(), new Map<Id, String>(), null);

        Assert.isFalse(result);
    }

    @IsTest
    static void testBlackFriday_onBlackFriday_returnsTrue() {
        // Nov 1, 2024 is Friday: 4th Friday = Nov 22, 2024
        Date blackFriday = Date.newInstance(2024, 11, 22);
        Discount__c d = makeRecurring('Black Friday');

        RecurringDiscountHandler handler = new RecurringDiscountHandler();
        Boolean result = handler.isApplicable(d, 100, blackFriday, new Set<Id>(), new Map<Id, Decimal>(), new Map<Id, String>(), null);

        Assert.isTrue(result);
    }

    @IsTest
    static void testBlackFriday_notInNovember_returnsFalse() {
        Date october = Date.newInstance(2025, 10, 15);
        Discount__c d = makeRecurring('Black Friday');

        RecurringDiscountHandler handler = new RecurringDiscountHandler();
        Boolean result = handler.isApplicable(d, 100, october, new Set<Id>(), new Map<Id, Decimal>(), new Map<Id, String>(), null);

        Assert.isFalse(result);
    }

    @IsTest
    static void testBlackFriday_novemberButWrongDay_returnsFalse() {
        // Nov 15, 2024 is not Black Friday
        Date november15 = Date.newInstance(2024, 11, 15);
        Discount__c d = makeRecurring('Black Friday');

        RecurringDiscountHandler handler = new RecurringDiscountHandler();
        Boolean result = handler.isApplicable(d, 100, november15, new Set<Id>(), new Map<Id, Decimal>(), new Map<Id, String>(), null);

        Assert.isFalse(result);
    }

    @IsTest
    static void testCustomDate_sameMonthAndDay_returnsTrue() {
        // Start_Date__c defines the recurring day-of-year
        Date startDate = Date.newInstance(2020, 6, 15);
        Date testDate  = Date.newInstance(2025, 6, 15);
        Discount__c d = makeRecurring('Custom Date');
        d.Start_Date__c = startDate;

        RecurringDiscountHandler handler = new RecurringDiscountHandler();
        Boolean result = handler.isApplicable(d, 100, testDate, new Set<Id>(), new Map<Id, Decimal>(), new Map<Id, String>(), null);

        Assert.isTrue(result);
    }

    @IsTest
    static void testCustomDate_differentMonth_returnsFalse() {
        Date startDate = Date.newInstance(2020, 6, 15);
        Date testDate  = Date.newInstance(2025, 7, 15);
        Discount__c d = makeRecurring('Custom Date');
        d.Start_Date__c = startDate;

        RecurringDiscountHandler handler = new RecurringDiscountHandler();
        Boolean result = handler.isApplicable(d, 100, testDate, new Set<Id>(), new Map<Id, Decimal>(), new Map<Id, String>(), null);

        Assert.isFalse(result);
    }

    @IsTest
    static void testCustomDate_nullStartDate_returnsFalse() {
        Discount__c d = makeRecurring('Custom Date');
        d.Start_Date__c = null;

        RecurringDiscountHandler handler = new RecurringDiscountHandler();
        Boolean result = handler.isApplicable(d, 100, Date.today(), new Set<Id>(), new Map<Id, Decimal>(), new Map<Id, String>(), null);

        Assert.isFalse(result);
    }

    @IsTest
    static void testUnknownPattern_returnsFalse() {
        Discount__c d = makeRecurring('Unknown Pattern');

        RecurringDiscountHandler handler = new RecurringDiscountHandler();
        Boolean result = handler.isApplicable(d, 100, Date.today(), new Set<Id>(), new Map<Id, Decimal>(), new Map<Id, String>(), null);

        Assert.isFalse(result);
    }
}
