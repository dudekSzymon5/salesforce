public class CustomDateStrategy implements IRecurrenceStrategy {

    public Boolean matchesDate(Discount__c discount, Date today) {
        return discount.Start_Date__c != null
            && today.month() == discount.Start_Date__c.month()
            && today.day()   == discount.Start_Date__c.day();
    }
}
