@IsTest
private class UtilsTest {

    @IsTest
    static void testDiscountTypeConstants() {
        Assert.areEqual('Recurring',   Utils.DISCOUNT.TYPE.RECURRING);
        Assert.areEqual('Conditional', Utils.DISCOUNT.TYPE.CONDITIONAL);
        Assert.areEqual('One-Time',    Utils.DISCOUNT.TYPE.ONE_TIME);
    }

    @IsTest
    static void testDiscountConditionConstants() {
        Assert.areEqual('Minimum Order Value', Utils.DISCOUNT.CONDITION.MIN_ORDER_VALUE);
        Assert.areEqual('Two For One',         Utils.DISCOUNT.CONDITION.TWO_FOR_ONE);
    }

    @IsTest
    static void testDiscountFormConstants() {
        Assert.areEqual('Percentage', Utils.DISCOUNT.FORM.PERCENTAGE);
        Assert.areEqual('Amount',     Utils.DISCOUNT.FORM.AMOUNT);
    }

    @IsTest
    static void testRecurrencePatternConstants() {
        Assert.areEqual('Every Monday',      Utils.DISCOUNT.RECURRENCE_PATTERN.EVERY_MONDAY);
        Assert.areEqual('Last Day of Month', Utils.DISCOUNT.RECURRENCE_PATTERN.LAST_DAY_OF_MONTH);
        Assert.areEqual('Black Friday',      Utils.DISCOUNT.RECURRENCE_PATTERN.BLACK_FRIDAY);
        Assert.areEqual('Custom Date',       Utils.DISCOUNT.RECURRENCE_PATTERN.CUSTOM_DATE);
    }

    @IsTest
    static void testStrategyConstants() {
        Assert.areEqual('Highest Discount', Utils.DISCOUNT.STRATEGY.HIGHEST);
        Assert.areEqual('Lowest Discount',  Utils.DISCOUNT.STRATEGY.LOWEST);
    }

    @IsTest
    static void testTargetConstants() {
        Assert.areEqual('All Products',       Utils.DISCOUNT.TARGET.ALL);
        Assert.areEqual('Specific Families',  Utils.DISCOUNT.TARGET.FAMILIES);
        Assert.areEqual('Specific Products',  Utils.DISCOUNT.TARGET.PRODUCTS);
    }

    @IsTest
    static void testErrorMessageConstants() {
        Assert.isNotNull(Utils.DISCOUNT.ERROR.ALREADY_ASSIGNED);
        Assert.isNotNull(Utils.DISCOUNT.ERROR.PERCENTAGE_RANGE);
    }

    @IsTest
    static void testDiscountSettingsConstants() {
        Assert.areEqual('Discount_Settings__mdt.Default', Utils.DISCOUNT_SETTINGS.RECORD.FULL_NAME);
        Assert.areEqual('Default',                        Utils.DISCOUNT_SETTINGS.RECORD.LABEL);
        Assert.areEqual('Default',                        Utils.DISCOUNT_SETTINGS.RECORD.DEVELOPER_NAME);
        Assert.areEqual('Discount_Strategy__c',           Utils.DISCOUNT_SETTINGS.FIELD.STRATEGY);
        Assert.areEqual('Minimum_Discount_Percentage__c', Utils.DISCOUNT_SETTINGS.FIELD.MIN_PCT);
    }
}
