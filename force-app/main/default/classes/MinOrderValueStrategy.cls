public class MinOrderValueStrategy implements IConditionStrategy {

    public Boolean isMet(Discount__c discount, Decimal amount) {
        return discount.Minimum_Order_Amount__c == null || amount >= discount.Minimum_Order_Amount__c;
    }
}
