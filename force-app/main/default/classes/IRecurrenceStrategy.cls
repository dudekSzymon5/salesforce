public interface IRecurrenceStrategy {
    Boolean matchesDate(Discount__c discount, Date today);
}
