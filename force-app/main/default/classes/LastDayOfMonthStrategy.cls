public class LastDayOfMonthStrategy implements IRecurrenceStrategy {

    public Boolean matchesDate(Discount__c discount, Date today) {
        return today.addDays(1).month() != today.month();
    }
}
