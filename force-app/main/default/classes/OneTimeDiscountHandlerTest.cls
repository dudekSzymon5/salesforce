@IsTest
private class OneTimeDiscountHandlerTest {

    static Discount__c makeOneTime() {
        return new Discount__c(
            Name = 'Test One-Time',
            Type__c = 'One-Time',
            Discount_Form__c = 'Percentage',
            Value__c = 10,
            Is_Active__c = true
        );
    }

    @IsTest
    static void testBeforeStartDate_returnsFalse() {
        Discount__c d = makeOneTime();
        d.Start_Date__c = Date.today().addDays(5);

        OneTimeDiscountHandler handler = new OneTimeDiscountHandler();
        Boolean result = handler.isApplicable(d, 100, Date.today(), new Set<Id>(), new Map<Id, Decimal>(), new Map<Id, String>(), null);

        Assert.isFalse(result);
    }

    @IsTest
    static void testAfterEndDate_returnsFalse() {
        Discount__c d = makeOneTime();
        d.End_Date__c = Date.today().addDays(-5);

        OneTimeDiscountHandler handler = new OneTimeDiscountHandler();
        Boolean result = handler.isApplicable(d, 100, Date.today(), new Set<Id>(), new Map<Id, Decimal>(), new Map<Id, String>(), null);

        Assert.isFalse(result);
    }

    @IsTest
    static void testWithinDateRange_returnsTrue() {
        Discount__c d = makeOneTime();
        d.Start_Date__c = Date.today().addDays(-5);
        d.End_Date__c = Date.today().addDays(5);

        OneTimeDiscountHandler handler = new OneTimeDiscountHandler();
        Boolean result = handler.isApplicable(d, 100, Date.today(), new Set<Id>(), new Map<Id, Decimal>(), new Map<Id, String>(), null);

        Assert.isTrue(result);
    }

    @IsTest
    static void testNoDates_returnsTrue() {
        Discount__c d = makeOneTime();

        OneTimeDiscountHandler handler = new OneTimeDiscountHandler();
        Boolean result = handler.isApplicable(d, 100, Date.today(), new Set<Id>(), new Map<Id, Decimal>(), new Map<Id, String>(), null);

        Assert.isTrue(result);
    }
}
