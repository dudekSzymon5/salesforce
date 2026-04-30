public abstract class DiscountTypeHandler {

    public Boolean isApplicable(Discount__c d, Decimal amount, Date today, Set<Id> productIds, Map<Id, Decimal> productQuantities) {
        if (!meetsProductConditions(d, productIds, productQuantities)) return false;
        return meetsTypeConditions(d, amount, today);
    }

    protected abstract Boolean meetsTypeConditions(Discount__c d, Decimal amount, Date today);

    public static DiscountTypeHandler forType(String type) {
        if (type == Utils.Discount.TYPE_RECURRING) return new RecurringDiscountHandler();
        if (type == Utils.Discount.TYPE_CONDITIONAL) return new ConditionalDiscountHandler();
        return new OneTimeDiscountHandler();
    }

    private Boolean meetsProductConditions(Discount__c d, Set<Id> productIds, Map<Id, Decimal> productQuantities) {
        if (d.Trigger_Product__c != null && !productIds.contains(d.Trigger_Product__c)) return false;
        if (d.Target_Product__c != null && !productIds.contains(d.Target_Product__c)) return false;
        if (d.Minimum_Quantity__c != null) {
            Id qtyCheckId = d.Trigger_Product__c != null ? d.Trigger_Product__c : d.Target_Product__c;
            Decimal qty = qtyCheckId != null ? productQuantities.get(qtyCheckId) : null;
            if (qty == null || qty < d.Minimum_Quantity__c) return false;
        }
        return true;
    }
}
