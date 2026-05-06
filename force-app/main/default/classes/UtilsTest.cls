@IsTest
private class UtilsTest {

    @IsTest
    static void testDiscountTypeConstants() {
        Assert.areEqual('Recurring', DiscountUtils.TYPE_RECURRING);
        Assert.areEqual('Conditional', DiscountUtils.TYPE_CONDITIONAL);
        Assert.areEqual('One-Time', DiscountUtils.TYPE_ONE_TIME);
    }

    @IsTest
    static void testDiscountConditionConstants() {
        Assert.areEqual('Minimum Order Value', DiscountUtils.CONDITION_MIN_ORDER_VALUE);
        Assert.areEqual('Two For One', DiscountUtils.CONDITION_TWO_FOR_ONE);
    }

    @IsTest
    static void testDiscountFormConstants() {
        Assert.areEqual('Percentage', DiscountUtils.FORM_PERCENTAGE);
        Assert.areEqual('Amount', DiscountUtils.FORM_AMOUNT);
    }

    @IsTest
    static void testRecurrencePatternConstants() {
        Assert.areEqual('Every Monday', DiscountUtils.RECURRENCE_EVERY_MONDAY);
        Assert.areEqual('Last Day of Month', DiscountUtils.RECURRENCE_LAST_DAY_OF_MONTH);
        Assert.areEqual('Black Friday', DiscountUtils.RECURRENCE_BLACK_FRIDAY);
        Assert.areEqual('Custom Date', DiscountUtils.RECURRENCE_CUSTOM_DATE);
    }

    @IsTest
    static void testStrategyConstants() {
        Assert.areEqual('Highest Discount', DiscountUtils.STRATEGY_HIGHEST);
        Assert.areEqual('Lowest Discount', DiscountUtils.STRATEGY_LOWEST);
    }

    @IsTest
    static void testTargetConstants() {
        Assert.areEqual('All Products', DiscountUtils.TARGET_ALL);
        Assert.areEqual('Specific Families', DiscountUtils.TARGET_FAMILIES);
        Assert.areEqual('Specific Products', DiscountUtils.TARGET_PRODUCTS);
    }

    @IsTest
    static void testErrorMessageConstants() {
        Assert.isNotNull(DiscountUtils.ERROR_ALREADY_ASSIGNED);
        Assert.isNotNull(DiscountUtils.ERROR_PERCENTAGE_RANGE);
    }

    @IsTest
    static void testDiscountSettingsConstants() {
        Assert.areEqual('Discount_Settings__mdt.Default', DiscountSettingsUtils.FULL_NAME);
        Assert.areEqual('Default', DiscountSettingsUtils.LABEL);
        Assert.areEqual('Default', DiscountSettingsUtils.DEVELOPER_NAME);
        Assert.areEqual('Discount_Strategy__c', DiscountSettingsUtils.FIELD_STRATEGY);
        Assert.areEqual('Minimum_Discount_Percentage__c', DiscountSettingsUtils.FIELD_MIN_PCT);
    }
}
