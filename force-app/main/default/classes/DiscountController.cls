public with sharing class DiscountController {

    @AuraEnabled(cacheable=true)
    public static List<Discount__c> getDiscounts() {
        return DiscountService.getDiscounts();
    }

    @AuraEnabled(cacheable=true)
    public static List<Id> getAssignedDiscountIds() {
        return DiscountService.getAssignedDiscountIds();
    }

    @AuraEnabled(cacheable=true)
    public static List<Product2> getProductOptions() {
        return DiscountService.getProductOptions();
    }

    @AuraEnabled(cacheable=true)
    public static Discount_Settings__mdt getDiscountSettings() {
        return DiscountService.getDiscountSettings();
    }

    @AuraEnabled
    public static void saveDiscountSettings(String strategy, Decimal minPercentage) {
        DiscountService.saveDiscountSettings(strategy, minPercentage);
    }

    @AuraEnabled
    public static Discount__c saveDiscount(Discount__c discount) {
        return DiscountService.saveDiscount(discount);
    }

    @AuraEnabled
    public static void toggleDiscounts(List<Id> discountIds, Boolean isActive) {
        DiscountService.toggleDiscounts(discountIds, isActive);
    }

    @AuraEnabled
    public static List<Order_Discount__c> applyDiscountsToOrder(Id orderId, Decimal orderAmount) {
        return DiscountService.applyDiscountsToOrder(orderId, orderAmount);
    }

    @AuraEnabled
    public static List<DiscountService.DiscountPreview> previewDiscounts(Decimal orderAmount, List<DiscountService.ItemInput> items) {
        return DiscountService.previewDiscounts(orderAmount, items);
    }
}
