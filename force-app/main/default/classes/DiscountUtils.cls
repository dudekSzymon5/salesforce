public class DiscountUtils {

    public static final String TYPE_RECURRING   = 'Recurring';
    public static final String TYPE_CONDITIONAL = 'Conditional';
    public static final String TYPE_ONE_TIME    = 'One-Time';

    public static final String CONDITION_MIN_ORDER_VALUE = 'Minimum Order Value';
    public static final String CONDITION_TWO_FOR_ONE     = 'Two For One';

    public static final String FORM_PERCENTAGE = 'Percentage';
    public static final String FORM_AMOUNT     = 'Amount';

    public static final String RECURRENCE_EVERY_MONDAY      = 'Every Monday';
    public static final String RECURRENCE_LAST_DAY_OF_MONTH = 'Last Day of Month';
    public static final String RECURRENCE_BLACK_FRIDAY      = 'Black Friday';
    public static final String RECURRENCE_CUSTOM_DATE       = 'Custom Date';

    public static final String STRATEGY_HIGHEST = 'Highest Discount';
    public static final String STRATEGY_LOWEST  = 'Lowest Discount';

    public static final String TARGET_ALL      = 'All Products';
    public static final String TARGET_FAMILIES = 'Specific Families';
    public static final String TARGET_PRODUCTS = 'Specific Products';

    public static String ERROR_ALREADY_ASSIGNED { get { return Label.Discount_ErrorAlreadyAssigned; } }
    public static String ERROR_PERCENTAGE_RANGE { get { return Label.Discount_ErrorPercentageRange; } }
}
