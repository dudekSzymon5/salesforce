public interface IConditionStrategy {
    Boolean isMet(Discount__c discount, Decimal amount);
}
