public abstract class DiscountTypeHandler {

    public Boolean isApplicable(
        Discount__c d, Decimal amount, Date today,
        Set<Id> productIds, Map<Id, Decimal> productQuantities,
        Map<Id, String> productFamilies, Set<Id> linkedProductIds
    ) {
        if (!meetsProductConditions(d, productIds, productQuantities, productFamilies, linkedProductIds)) return false;
        return meetsTypeConditions(d, amount, today);
    }

    protected abstract Boolean meetsTypeConditions(Discount__c d, Decimal amount, Date today);

    public static DiscountTypeHandler forType(String type) {
        if (type == Utils.Discount.TYPE_RECURRING)   return new RecurringDiscountHandler();
        if (type == Utils.Discount.TYPE_CONDITIONAL) return new ConditionalDiscountHandler();
        return new OneTimeDiscountHandler();
    }

    private Boolean meetsProductConditions(
        Discount__c d, Set<Id> productIds, Map<Id, Decimal> productQuantities,
        Map<Id, String> productFamilies, Set<Id> linkedProductIds
    ) {
        String targetApp = d.Target_Application__c != null ? d.Target_Application__c : Utils.Discount.TARGET_ALL;
        Set<Id> qualifying = new Set<Id>();

        if (targetApp == Utils.Discount.TARGET_PRODUCTS) {
            if (linkedProductIds == null || linkedProductIds.isEmpty()) return false;
            for (Id pid : linkedProductIds) {
                if (productIds.contains(pid)) qualifying.add(pid);
            }
            if (qualifying.isEmpty()) return false;

        } else if (targetApp == Utils.Discount.TARGET_FAMILIES) {
            if (d.Target_Families__c == null) return false;
            Set<String> targetFamilies = new Set<String>();
            for (String f : d.Target_Families__c.split(',')) targetFamilies.add(f.trim());
            for (Id pid : productIds) {
                String fam = productFamilies.get(pid);
                if (fam != null && targetFamilies.contains(fam)) qualifying.add(pid);
            }
            if (qualifying.isEmpty()) return false;

        } else {
            qualifying = productIds;
        }

        if (d.Minimum_Quantity__c != null) {
            Boolean hasMinQty = false;
            for (Id pid : qualifying) {
                Decimal qty = productQuantities.get(pid);
                if (qty != null && qty >= d.Minimum_Quantity__c) { hasMinQty = true; break; }
            }
            if (!hasMinQty) return false;
        }

        return true;
    }
}
