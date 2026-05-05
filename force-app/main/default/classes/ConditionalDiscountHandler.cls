public class ConditionalDiscountHandler extends DiscountTypeHandler {

    protected override Boolean meetsTypeConditions(Discount__c discount, Decimal amount, Date today) {
        if (discount.Start_Date__c != null && today < discount.Start_Date__c) return false;
        if (discount.End_Date__c != null && today > discount.End_Date__c) return false;

        if (discount.Condition_Type__c == Utils.Discount.CONDITION_MIN_ORDER_VALUE) {
            if (discount.Minimum_Order_Amount__c != null && amount < discount.Minimum_Order_Amount__c) return false;
        }

        return true;
    }
}
