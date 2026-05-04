public with sharing class DiscountController {

    @AuraEnabled(cacheable=true)
    public static List<Discount__c> getDiscounts() {
        try {
            return DiscountService.getDiscounts();
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Id> getAssignedDiscountIds() {
        try {
            return DiscountService.getAssignedDiscountIds();
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Product2> getProductOptions() {
        try {
            return DiscountService.getProductOptions();
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getProductFamilies() {
        try {
            return DiscountService.getProductFamilies();
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<Id> getDiscountProducts(Id discountId) {
        try {
            return DiscountService.getDiscountProducts(discountId);
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void saveDiscountProducts(Id discountId, List<Id> productIds) {
        try {
            DiscountService.saveDiscountProducts(discountId, productIds);
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static Discount_Settings__mdt getDiscountSettings() {
        try {
            return DiscountService.getDiscountSettings();
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void saveDiscountSettings(String strategy, Decimal minPercentage) {
        try {
            DiscountService.saveDiscountSettings(strategy, minPercentage);
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Discount__c saveDiscount(Discount__c discount) {
        try {
            return DiscountService.saveDiscount(discount);
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void toggleDiscounts(List<Id> discountIds, Boolean isActive) {
        try {
            DiscountService.toggleDiscounts(discountIds, isActive);
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<Order_Discount__c> applyDiscountsToOrder(Id orderId, Decimal orderAmount) {
        try {
            return DiscountService.applyDiscountsToOrder(orderId, orderAmount);
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<DiscountService.DiscountPreview> previewDiscounts(Decimal orderAmount, List<DiscountService.ItemInput> items) {
        try {
            return DiscountService.previewDiscounts(orderAmount, items);
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}
