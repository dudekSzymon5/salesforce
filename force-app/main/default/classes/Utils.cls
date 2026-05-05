public class Utils {

    public static final DiscountConst Discount = new DiscountConst();
    public static final DiscountSettingsConst DiscountSettings = new DiscountSettingsConst();

    public class DiscountConst {
        public String TYPE_RECURRING   { get { return 'Recurring'; } }
        public String TYPE_CONDITIONAL { get { return 'Conditional'; } }
        public String TYPE_ONE_TIME    { get { return 'One-Time'; } }

        public String CONDITION_MIN_ORDER_VALUE { get { return 'Minimum Order Value'; } }
        public String CONDITION_TWO_FOR_ONE     { get { return 'Two For One'; } }

        public String FORM_PERCENTAGE { get { return 'Percentage'; } }
        public String FORM_AMOUNT     { get { return 'Amount'; } }

        public String RECURRENCE_EVERY_MONDAY      { get { return 'Every Monday'; } }
        public String RECURRENCE_LAST_DAY_OF_MONTH { get { return 'Last Day of Month'; } }
        public String RECURRENCE_BLACK_FRIDAY      { get { return 'Black Friday'; } }
        public String RECURRENCE_CUSTOM_DATE       { get { return 'Custom Date'; } }

        public String STRATEGY_HIGHEST { get { return 'Highest Discount'; } }
        public String STRATEGY_LOWEST  { get { return 'Lowest Discount'; } }

        public String TARGET_ALL      { get { return 'All Products'; } }
        public String TARGET_FAMILIES { get { return 'Specific Families'; } }
        public String TARGET_PRODUCTS { get { return 'Specific Products'; } }

        public String ERROR_ALREADY_ASSIGNED { get { return Label.Discount_ErrorAlreadyAssigned; } }
        public String ERROR_PERCENTAGE_RANGE { get { return Label.Discount_ErrorPercentageRange; } }
    }

    public class DiscountSettingsConst {
        public String FULL_NAME      { get { return 'Discount_Settings__mdt.Default'; } }
        public String LABEL          { get { return 'Default'; } }
        public String DEVELOPER_NAME { get { return 'Default'; } }
        public String FIELD_STRATEGY { get { return 'Discount_Strategy__c'; } }
        public String FIELD_MIN_PCT  { get { return 'Minimum_Discount_Percentage__c'; } }
    }
}
