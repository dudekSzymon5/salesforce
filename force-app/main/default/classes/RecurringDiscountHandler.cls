public class RecurringDiscountHandler extends DiscountTypeHandler {

    protected override Boolean meetsTypeConditions(Discount__c discount, Decimal amount, Date today) {
        IRecurrenceStrategy strategy = RecurrenceStrategyFactory.forPattern(discount.Recurrence_Pattern__c);
        if (strategy == null) return false;
        return strategy.matchesDate(discount, today);
    }
}
