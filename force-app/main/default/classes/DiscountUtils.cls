public class DiscountUtils {

    public final TypeConst              TYPE               = new TypeConst();
    public final ConditionConst         CONDITION          = new ConditionConst();
    public final FormConst              FORM               = new FormConst();
    public final RecurrencePatternConst RECURRENCE_PATTERN = new RecurrencePatternConst();
    public final StrategyConst          STRATEGY           = new StrategyConst();
    public final TargetConst            TARGET             = new TargetConst();
    public final ErrorConst             ERROR              = new ErrorConst();

    public class TypeConst {
        public String RECURRING   { get { return 'Recurring'; } }
        public String CONDITIONAL { get { return 'Conditional'; } }
        public String ONE_TIME    { get { return 'One-Time'; } }
    }

    public class ConditionConst {
        public String MIN_ORDER_VALUE { get { return 'Minimum Order Value'; } }
        public String TWO_FOR_ONE     { get { return 'Two For One'; } }
    }

    public class FormConst {
        public String PERCENTAGE { get { return 'Percentage'; } }
        public String AMOUNT     { get { return 'Amount'; } }
    }

    public class RecurrencePatternConst {
        public String EVERY_MONDAY      { get { return 'Every Monday'; } }
        public String LAST_DAY_OF_MONTH { get { return 'Last Day of Month'; } }
        public String BLACK_FRIDAY      { get { return 'Black Friday'; } }
        public String CUSTOM_DATE       { get { return 'Custom Date'; } }
    }

    public class StrategyConst {
        public String HIGHEST { get { return 'Highest Discount'; } }
        public String LOWEST  { get { return 'Lowest Discount'; } }
    }

    public class TargetConst {
        public String ALL      { get { return 'All Products'; } }
        public String FAMILIES { get { return 'Specific Families'; } }
        public String PRODUCTS { get { return 'Specific Products'; } }
    }

    public class ErrorConst {
        public String ALREADY_ASSIGNED { get { return Label.Discount_ErrorAlreadyAssigned; } }
        public String PERCENTAGE_RANGE { get { return Label.Discount_ErrorPercentageRange; } }
    }
}
