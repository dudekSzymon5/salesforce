@IsTest
private class UtilsTest {

    @IsTest
    static void testDiscountTypeConstants() {
        Assert.areEqual('Recurring', Utils.Discount.TYPE_RECURRING);
        Assert.areEqual('Conditional', Utils.Discount.TYPE_CONDITIONAL);
        Assert.areEqual('One-Time', Utils.Discount.TYPE_ONE_TIME);
    }

    @IsTest
    static void testDiscountConditionConstants() {
        Assert.areEqual('Minimum Order Value', Utils.Discount.CONDITION_MIN_ORDER_VALUE);
        Assert.areEqual('Two For One', Utils.Discount.CONDITION_TWO_FOR_ONE);
    }

    @IsTest
    static void testDiscountFormConstants() {
        Assert.areEqual('Percentage', Utils.Discount.FORM_PERCENTAGE);
        Assert.areEqual('Amount', Utils.Discount.FORM_AMOUNT);
    }

    @IsTest
    static void testRecurrencePatternConstants() {
        Assert.areEqual('Every Monday', Utils.Discount.RECURRENCE_EVERY_MONDAY);
        Assert.areEqual('Last Day of Month', Utils.Discount.RECURRENCE_LAST_DAY_OF_MONTH);
        Assert.areEqual('Black Friday', Utils.Discount.RECURRENCE_BLACK_FRIDAY);
        Assert.areEqual('Custom Date', Utils.Discount.RECURRENCE_CUSTOM_DATE);
    }

    @IsTest
    static void testStrategyConstants() {
        Assert.areEqual('Highest Discount', Utils.Discount.STRATEGY_HIGHEST);
        Assert.areEqual('Lowest Discount', Utils.Discount.STRATEGY_LOWEST);
    }

    @IsTest
    static void testTargetConstants() {
        Assert.areEqual('All Products', Utils.Discount.TARGET_ALL);
        Assert.areEqual('Specific Families', Utils.Discount.TARGET_FAMILIES);
        Assert.areEqual('Specific Products', Utils.Discount.TARGET_PRODUCTS);
    }

    @IsTest
    static void testErrorMessageConstants() {
        Assert.isNotNull(Utils.Discount.ERROR_ALREADY_ASSIGNED);
        Assert.isNotNull(Utils.Discount.ERROR_PERCENTAGE_RANGE);
    }

    @IsTest
    static void testDiscountSettingsConstants() {
        Assert.areEqual('Discount_Settings__mdt.Default', Utils.DiscountSettings.FULL_NAME);
        Assert.areEqual('Default', Utils.DiscountSettings.LABEL);
        Assert.areEqual('Default', Utils.DiscountSettings.DEVELOPER_NAME);
        Assert.areEqual('Discount_Strategy__c', Utils.DiscountSettings.FIELD_STRATEGY);
        Assert.areEqual('Minimum_Discount_Percentage__c', Utils.DiscountSettings.FIELD_MIN_PCT);
    }
}
