public abstract class DiscountTypeHandler {

    public Boolean isApplicable(
        Discount__c discount, Decimal amount, Date today,
        Set<Id> productIds, Map<Id, Decimal> productQuantities,
        Map<Id, String> productFamilies, Set<Id> linkedProductIds
    ) {
        if (!meetsProductConditions(discount, productIds, productQuantities, productFamilies, linkedProductIds)) return false;
        return meetsTypeConditions(discount, amount, today);
    }

    protected abstract Boolean meetsTypeConditions(Discount__c discount, Decimal amount, Date today);

    public static DiscountTypeHandler forType(String type) {
        if (type == Utils.DISCOUNT.TYPE.RECURRING)   return new RecurringDiscountHandler();
        if (type == Utils.DISCOUNT.TYPE.CONDITIONAL) return new ConditionalDiscountHandler();
        return new OneTimeDiscountHandler();
    }

    private Boolean meetsProductConditions(
        Discount__c discount, Set<Id> productIds, Map<Id, Decimal> productQuantities,
        Map<Id, String> productFamilies, Set<Id> linkedProductIds
    ) {
        String targetApplication = discount.Target_Application__c != null ? discount.Target_Application__c : Utils.DISCOUNT.TARGET.ALL;
        Set<Id> qualifying = new Set<Id>();

        if (targetApplication == Utils.DISCOUNT.TARGET.PRODUCTS) {
            if (linkedProductIds == null || linkedProductIds.isEmpty()) return false;
            for (Id productId : linkedProductIds) {
                if (productIds.contains(productId)) qualifying.add(productId);
            }
            if (qualifying.isEmpty()) return false;

        } else if (targetApplication == Utils.DISCOUNT.TARGET.FAMILIES) {
            if (discount.Target_Families__c == null) return false;
            Set<String> targetFamilies = new Set<String>();
            for (String family : discount.Target_Families__c.split(',')) targetFamilies.add(family.trim());
            for (Id productId : productIds) {
                String productFamily = productFamilies.get(productId);
                if (productFamily != null && targetFamilies.contains(productFamily)) qualifying.add(productId);
            }
            if (qualifying.isEmpty()) return false;

        } else {
            qualifying = productIds;
        }

        if (discount.Minimum_Quantity__c != null) {
            Boolean anyProductMeetsMinimumQuantity = false;
            for (Id productId : qualifying) {
                Decimal quantity = productQuantities.get(productId);
                if (quantity != null && quantity >= discount.Minimum_Quantity__c) { anyProductMeetsMinimumQuantity = true; break; }
            }
            if (!anyProductMeetsMinimumQuantity) return false;
        }

        return true;
    }
}
