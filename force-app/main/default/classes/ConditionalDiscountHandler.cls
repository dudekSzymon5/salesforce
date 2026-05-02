public class ConditionalDiscountHandler extends DiscountTypeHandler {

    protected override Boolean meetsTypeConditions(Discount__c d, Decimal amount, Date today) {
        if (d.Start_Date__c != null && today < d.Start_Date__c) return false;
        if (d.End_Date__c != null && today > d.End_Date__c) return false;

        if (d.Condition_Type__c == Utils.Discount.CONDITION_MIN_ORDER_VALUE) {
            if (d.Minimum_Order_Amount__c != null && amount < d.Minimum_Order_Amount__c) return false;
        }

        return true;
    }
}
