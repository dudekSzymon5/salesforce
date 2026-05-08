public class BlackFridayStrategy implements IRecurrenceStrategy {

    public Boolean matchesDate(Discount__c discount, Date today) {
        if (today.month() != 11) return false;
        Date firstDayOfNovember = Date.newInstance(today.year(), 11, 1);
        Integer dayOfWeek    = Math.mod(Date.newInstance(1900, 1, 7).daysBetween(firstDayOfNovember), 7);
        Integer daysToFriday = Math.mod(5 - dayOfWeek, 7);
        Date blackFriday     = firstDayOfNovember.addDays(daysToFriday + 21);
        return today == blackFriday;
    }
}
