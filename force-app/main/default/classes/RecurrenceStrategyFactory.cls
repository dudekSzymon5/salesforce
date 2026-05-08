public class RecurrenceStrategyFactory {

    public static IRecurrenceStrategy forPattern(String pattern) {
        if (pattern == Utils.DISCOUNT.RECURRENCE_PATTERN.EVERY_MONDAY)      return new EveryMondayStrategy();
        if (pattern == Utils.DISCOUNT.RECURRENCE_PATTERN.LAST_DAY_OF_MONTH) return new LastDayOfMonthStrategy();
        if (pattern == Utils.DISCOUNT.RECURRENCE_PATTERN.BLACK_FRIDAY)      return new BlackFridayStrategy();
        if (pattern == Utils.DISCOUNT.RECURRENCE_PATTERN.CUSTOM_DATE)       return new CustomDateStrategy();
        return null;
    }
}
