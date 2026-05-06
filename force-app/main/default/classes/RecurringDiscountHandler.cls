public class RecurringDiscountHandler extends DiscountTypeHandler {

    protected override Boolean meetsTypeConditions(Discount__c discount, Decimal amount, Date today) {
        if (discount.Recurrence_Pattern__c == DiscountUtils.RECURRENCE_EVERY_MONDAY) {
            return today.toStartOfWeek().addDays(1) == today;
        }
        if (discount.Recurrence_Pattern__c == DiscountUtils.RECURRENCE_LAST_DAY_OF_MONTH) {
            return today.addDays(1).month() != today.month();
        }
        if (discount.Recurrence_Pattern__c == DiscountUtils.RECURRENCE_BLACK_FRIDAY) {
            if (today.month() != 11) return false;
            Date firstDayOfNovember = Date.newInstance(today.year(), 11, 1);
            Integer dayOfWeek = Math.mod(Date.newInstance(1900, 1, 7).daysBetween(firstDayOfNovember), 7);
            Integer daysToFriday = Math.mod(5 - dayOfWeek, 7);
            Date blackFriday = firstDayOfNovember.addDays(daysToFriday + 21);
            return today == blackFriday;
        }
        if (discount.Recurrence_Pattern__c == DiscountUtils.RECURRENCE_CUSTOM_DATE) {
            return discount.Start_Date__c != null
                && today.month() == discount.Start_Date__c.month()
                && today.day() == discount.Start_Date__c.day();
        }
        return false;
    }
}
