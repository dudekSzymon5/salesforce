public class DiscountUtils {

    public Type TYPE { get { return new Type(); } }
    public Condition CONDITION { get { return new Condition(); } }
    public Form FORM { get { return new Form(); } }
    public RecurrencePattern RECURRENCE_PATTERN { get { return new RecurrencePattern(); } }
    public Strategy STRATEGY { get { return new Strategy(); } }
    public Target TARGET { get { return new Target(); } }
    public Error ERROR { get { return new Error(); } }

    public class Type {
        public String RECURRING { get { return 'Recurring'; } }
        public String CONDITIONAL { get { return 'Conditional'; } }
        public String ONE_TIME { get { return 'One-Time'; } }
    }

    public class Condition {
        public String MIN_ORDER_VALUE { get { return 'Minimum Order Value'; } }
        public String TWO_FOR_ONE { get { return 'Two For One'; } }
    }

    public class Form {
        public String PERCENTAGE { get { return 'Percentage'; } }
        public String AMOUNT { get { return 'Amount'; } }
    }

    public class RecurrencePattern {
        public String EVERY_MONDAY { get { return 'Every Monday'; } }
        public String LAST_DAY_OF_MONTH { get { return 'Last Day of Month'; } }
        public String BLACK_FRIDAY { get { return 'Black Friday'; } }
        public String CUSTOM_DATE { get { return 'Custom Date'; } }
    }

    public class Strategy {
        public String HIGHEST { get { return 'Highest Discount'; } }
        public String LOWEST { get { return 'Lowest Discount'; } }
    }

    public class Target {
        public String ALL { get { return 'All Products'; } }
        public String FAMILIES { get { return 'Specific Families'; } }
        public String PRODUCTS { get { return 'Specific Products'; } }
    }

    public class Error {
        public String ALREADY_ASSIGNED { get { return Label.Discount_ErrorAlreadyAssigned; } }
        public String PERCENTAGE_RANGE { get { return Label.Discount_ErrorPercentageRange; } }
    }
}
