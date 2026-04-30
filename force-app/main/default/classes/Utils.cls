public class Utils {

    public static final DiscountConst Discount = new DiscountConst();
    public static final DiscountSettingsConst DiscountSettings = new DiscountSettingsConst();

    public class DiscountConst {
        public final String TYPE_RECURRING   = 'Recurring';
        public final String TYPE_CONDITIONAL = 'Conditional';
        public final String TYPE_ONE_TIME    = 'One-Time';

        public final String FORM_PERCENTAGE = 'Percentage';
        public final String FORM_AMOUNT     = 'Amount';

        public final String RECURRENCE_EVERY_MONDAY      = 'Every Monday';
        public final String RECURRENCE_LAST_DAY_OF_MONTH = 'Last Day of Month';
        public final String RECURRENCE_BLACK_FRIDAY      = 'Black Friday';
        public final String RECURRENCE_CUSTOM_DATE       = 'Custom Date';

        public final String STRATEGY_HIGHEST = 'Highest Discount';
        public final String STRATEGY_LOWEST  = 'Lowest Discount';

        public final String ERROR_ALREADY_ASSIGNED = 'This discount is already assigned to an order and cannot be edited.';
        public final String ERROR_PERCENTAGE_RANGE = 'Percentage discount value must be between 0 and 100.';
    }

    public class DiscountSettingsConst {
        public final String FULL_NAME      = 'Discount_Settings__mdt.Default';
        public final String LABEL          = 'Default';
        public final String DEVELOPER_NAME = 'Default';
        public final String FIELD_STRATEGY = 'Discount_Strategy__c';
        public final String FIELD_MIN_PCT  = 'Minimum_Discount_Percentage__c';
    }
}
