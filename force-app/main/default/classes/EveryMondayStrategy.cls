public class EveryMondayStrategy implements IRecurrenceStrategy {

    public Boolean matchesDate(Discount__c discount, Date today) {
        return today.toStartOfWeek().addDays(1) == today;
    }
}
