public class TwoForOneStrategy implements IConditionStrategy {

    public Boolean isMet(Discount__c discount, Decimal amount) {
        return true;
    }
}
