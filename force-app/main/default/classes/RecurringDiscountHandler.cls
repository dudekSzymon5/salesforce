public class RecurringDiscountHandler extends DiscountTypeHandler {

    protected override Boolean meetsTypeConditions(Discount__c d, Decimal amount, Date today) {
        if (d.Recurrence_Pattern__c == Utils.Discount.RECURRENCE_EVERY_MONDAY) {
            return today.toStartOfWeek().addDays(1) == today;
        }
        if (d.Recurrence_Pattern__c == Utils.Discount.RECURRENCE_LAST_DAY_OF_MONTH) {
            return today.addDays(1).month() != today.month();
        }
        if (d.Recurrence_Pattern__c == Utils.Discount.RECURRENCE_BLACK_FRIDAY) {
            if (today.month() != 11) return false;
            Date nov1 = Date.newInstance(today.year(), 11, 1);
            Integer dow = Math.mod(Date.newInstance(1900, 1, 7).daysBetween(nov1), 7);
            Integer daysToFriday = Math.mod(5 - dow, 7);
            Date blackFriday = nov1.addDays(daysToFriday + 21);
            return today == blackFriday;
        }
        if (d.Recurrence_Pattern__c == Utils.Discount.RECURRENCE_CUSTOM_DATE) {
            return d.Start_Date__c != null
                && today.month() == d.Start_Date__c.month()
                && today.day() == d.Start_Date__c.day();
        }
        return false;
    }
}
