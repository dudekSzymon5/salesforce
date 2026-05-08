public class ConditionalDiscountHandler extends DiscountTypeHandler {

    protected override Boolean meetsTypeConditions(Discount__c discount, Decimal amount, Date today) {
        if (discount.Start_Date__c != null && today < discount.Start_Date__c) return false;
        if (discount.End_Date__c   != null && today > discount.End_Date__c)   return false;
        if (discount.Condition_Type__c == null) return true;
        IConditionStrategy strategy = ConditionStrategyFactory.forCondition(discount.Condition_Type__c);
        if (strategy == null) return true;
        return strategy.isMet(discount, amount);
    }
}
