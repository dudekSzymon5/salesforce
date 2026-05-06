public with sharing class DiscountService {

    public class ItemInput {
        @AuraEnabled public Id product2Id { get; set; }
        @AuraEnabled public Decimal amount { get; set; }
        @AuraEnabled public Decimal quantity { get; set; }
    }

    public class DiscountPreview {
        @AuraEnabled public String discountName;
        @AuraEnabled public Decimal appliedValue;
        @AuraEnabled public Decimal originalPrice;
        @AuraEnabled public Decimal discountedPrice;
        @AuraEnabled public String targetProductName;
    }

    public static List<Discount__c> getDiscounts() {
        return [
            SELECT Id, Name, Type__c, Discount_Form__c, Value__c, Is_Active__c,
                   Start_Date__c, End_Date__c, Recurrence_Pattern__c, Minimum_Order_Amount__c,
                   Minimum_Quantity__c, Target_Application__c, Target_Families__c,
                   Condition_Type__c
            FROM Discount__c
            ORDER BY CreatedDate DESC
        ];
    }
    
    public static List<Id> getAssignedDiscountIds() {
        Set<Id> ids = new Set<Id>();
        for (Order_Discount__c orderDiscount : [SELECT Discount__c FROM Order_Discount__c WHERE Discount__c != null]) {
            ids.add(orderDiscount.Discount__c);
        }
        return new List<Id>(ids);
    }

    public static List<Product2> getProductOptions() {
        return [
            SELECT Id, Name, Family
            FROM Product2
            WHERE IsActive = true
            AND Id IN (SELECT Product2Id FROM PricebookEntry WHERE IsActive = true)
            ORDER BY Name
        ];
    }

    public static List<String> getProductFamilies() {
        Set<String> families = new Set<String>();
        for (Product2 product : [SELECT Family FROM Product2 WHERE IsActive = true AND Family != null]) {
            families.add(product.Family);
        }
        List<String> result = new List<String>(families);
        result.sort();
        return result;
    }

    public static List<Id> getDiscountProducts(Id discountId) { 
        List<Id> productIds = new List<Id>();
        for (Discount_Product__c discountProduct : [SELECT Product__c FROM Discount_Product__c WHERE Discount__c = :discountId]) {
            productIds.add(discountProduct.Product__c);
        }
        return productIds;
    }

    public static void saveDiscountProducts(Id discountId, List<Id> productIds) {
        delete [SELECT Id FROM Discount_Product__c WHERE Discount__c = :discountId];
        List<Discount_Product__c> toInsert = new List<Discount_Product__c>();
        for (Id productId : productIds) {
            toInsert.add(new Discount_Product__c(Discount__c = discountId, Product__c = productId));
        }
        if (!toInsert.isEmpty()) insert toInsert;
    }

    public static Discount_Settings__mdt getDiscountSettings() {
        return getSettings();
    }

    public static List<Order_Discount__c> applyDiscountsToOrder(Id orderId, Decimal orderAmount) {
        List<OrderItem> orderItems = [
            SELECT PricebookEntry.Product2Id, TotalPrice, Quantity
            FROM OrderItem WHERE OrderId = :orderId
        ];
        Map<Id, Decimal> productAmounts = new Map<Id, Decimal>();
        Map<Id, Decimal> productQuantities = new Map<Id, Decimal>();
        for (OrderItem orderItem : orderItems) {
            productAmounts.put(orderItem.PricebookEntry.Product2Id, orderItem.TotalPrice);
            productQuantities.put(orderItem.PricebookEntry.Product2Id, orderItem.Quantity);
        }

        Map<Id, String> productFamilies = fetchProductFamilies(productAmounts.keySet());
        Map<Id, Set<Id>> discountToProducts = fetchDiscountToProducts();

        Discount_Settings__mdt settings = getSettings();
        List<Discount__c> globalApplicable = new List<Discount__c>();
        List<Discount__c> targetedApplicable = new List<Discount__c>();
        partitionDiscounts( 
            fetchActiveDiscounts(), orderAmount, productAmounts.keySet(), productQuantities,
            productFamilies, discountToProducts, globalApplicable, targetedApplicable
        );

        List<Order_Discount__c> orderDiscounts = new List<Order_Discount__c>();
        Decimal remaining = orderAmount;

        for (Discount__c discount : targetedApplicable) {
            Decimal baseAmount = getTargetAmount(discount, productAmounts, discountToProducts, productFamilies, productQuantities);
            if (baseAmount == 0) continue;
            Decimal applied = calculateDiscountAmount(discount, baseAmount);
            if (!meetsMinimumDiscountPercentage(discount, applied, baseAmount, settings.Minimum_Discount_Percentage__c)) continue;
            orderDiscounts.add(new Order_Discount__c(
                Order__c = orderId,
                Discount__c = discount.Id,
                Applied_Value__c = applied,
                Original_Price__c = baseAmount,
                Discounted_Price__c = baseAmount - applied
            ));
            remaining -= applied;
        }

        for (Discount__c discount : selectByStrategy(globalApplicable, settings.Discount_Strategy__c, remaining)) {
            Decimal applied = calculateDiscountAmount(discount, remaining);
            if (!meetsMinimumDiscountPercentage(discount, applied, orderAmount, settings.Minimum_Discount_Percentage__c)) continue;
            orderDiscounts.add(new Order_Discount__c(
                Order__c = orderId,
                Discount__c = discount.Id,
                Applied_Value__c = applied,
                Original_Price__c = remaining,
                Discounted_Price__c = remaining - applied
            ));
            remaining -= applied;
        }

        if (!orderDiscounts.isEmpty()) {
            insert orderDiscounts;
            update new Order(Id = orderId, Total_After_Discounts__c = remaining);
            return [
                SELECT Id, Discount__c, Discount__r.Name, Applied_Value__c,
                    Original_Price__c, Discounted_Price__c
                FROM Order_Discount__c
                WHERE Order__c = :orderId
            ];
        }
        update new Order(Id = orderId, Total_After_Discounts__c = orderAmount);
        return new List<Order_Discount__c>();
    }

    public static List<DiscountPreview> previewDiscounts(Decimal orderAmount, List<ItemInput> items) {
        Map<Id, Decimal> productAmounts = new Map<Id, Decimal>();
        Map<Id, Decimal> productQuantities = new Map<Id, Decimal>();
        if (items != null) {
            for (ItemInput item : items) {
                if (item.product2Id != null) {
                    productAmounts.put(item.product2Id, item.amount);
                    productQuantities.put(item.product2Id, item.quantity != null ? item.quantity : 1);
                }
            }
        }

        Map<Id, String> productFamilies = fetchProductFamilies(productAmounts.keySet());
        Map<Id, Set<Id>> discountToProducts = fetchDiscountToProducts();

        Discount_Settings__mdt settings = getSettings();
        List<Discount__c> globalApplicable = new List<Discount__c>();
        List<Discount__c> targetedApplicable = new List<Discount__c>();
        partitionDiscounts(
            fetchActiveDiscounts(), orderAmount, productAmounts.keySet(), productQuantities,
            productFamilies, discountToProducts, globalApplicable, targetedApplicable
        );

        List<DiscountPreview> previews = new List<DiscountPreview>();
        Decimal remaining = orderAmount;

        for (Discount__c discount : targetedApplicable) {
            Decimal baseAmount = getTargetAmount(discount, productAmounts, discountToProducts, productFamilies, productQuantities);
            if (baseAmount == 0) continue;
            Decimal applied = calculateDiscountAmount(discount, baseAmount);
            if (!meetsMinimumDiscountPercentage(discount, applied, baseAmount, settings.Minimum_Discount_Percentage__c)) continue;
            previews.add(buildPreview(discount, applied, baseAmount, discount.Target_Application__c));
            remaining -= applied;
        }

        for (Discount__c discount : selectByStrategy(globalApplicable, settings.Discount_Strategy__c, remaining)) {
            Decimal applied = calculateDiscountAmount(discount, remaining);
            if (!meetsMinimumDiscountPercentage(discount, applied, orderAmount, settings.Minimum_Discount_Percentage__c)) continue;
            previews.add(buildPreview(discount, applied, remaining, null));
            remaining -= applied;
        }

        return previews;
    }

    public static Discount__c saveDiscount(Discount__c discount) { 
        if (discount.Id != null) {
            List<Order_Discount__c> assigned = [
                SELECT Id FROM Order_Discount__c WHERE Discount__c = :discount.Id LIMIT 1
            ];
            if (!assigned.isEmpty()) {
                throw new AuraHandledException(DiscountUtils.ERROR_ALREADY_ASSIGNED);
            }
        }
        if (discount.Discount_Form__c == DiscountUtils.FORM_PERCENTAGE && (discount.Value__c < 0 || discount.Value__c > 100)) {
            throw new AuraHandledException(DiscountUtils.ERROR_PERCENTAGE_RANGE);
        }

        if (discount.Condition_Type__c == DiscountUtils.CONDITION_TWO_FOR_ONE) {
            discount.Minimum_Quantity__c = 2;
        }

        upsert discount;
        return discount;
    }

    public static void toggleDiscounts(List<Id> discountIds, Boolean isActive) {
        List<Discount__c> discounts = [SELECT Id, Is_Active__c FROM Discount__c WHERE Id IN :discountIds];
        for (Discount__c discount : discounts) {
            discount.Is_Active__c = isActive;
        }
        update discounts;
    }

    public static void saveDiscountSettings(String strategy, Decimal minPercentage) {
        Metadata.CustomMetadata customMetadata = new Metadata.CustomMetadata();
        customMetadata.fullName = DiscountSettingsUtils.FULL_NAME;
        customMetadata.label = DiscountSettingsUtils.LABEL;

        Metadata.CustomMetadataValue strategyMetadataValue = new Metadata.CustomMetadataValue();
        strategyMetadataValue.field = DiscountSettingsUtils.FIELD_STRATEGY;
        strategyMetadataValue.value = strategy;
        customMetadata.values.add(strategyMetadataValue);

        Metadata.CustomMetadataValue minPercentageMetadataValue = new Metadata.CustomMetadataValue();
        minPercentageMetadataValue.field = DiscountSettingsUtils.FIELD_MIN_PCT;
        minPercentageMetadataValue.value = minPercentage;
        customMetadata.values.add(minPercentageMetadataValue);

        Metadata.DeployContainer container = new Metadata.DeployContainer();
        container.addMetadata(customMetadata);
        Metadata.Operations.enqueueDeployment(container, null);
    }

    private static Discount_Settings__mdt getSettings() {
        return [
            SELECT Discount_Strategy__c, Minimum_Discount_Percentage__c
            FROM Discount_Settings__mdt
            WHERE DeveloperName = :DiscountSettingsUtils.DEVELOPER_NAME
            LIMIT 1
        ];
    }

    private static List<Discount__c> fetchActiveDiscounts() {
        return [
            SELECT Id, Name, Type__c, Discount_Form__c, Value__c,
                   Recurrence_Pattern__c, Minimum_Order_Amount__c, Minimum_Quantity__c,
                   Start_Date__c, End_Date__c, Target_Application__c, Target_Families__c,
                   Condition_Type__c
            FROM Discount__c
            WHERE Is_Active__c = true
        ];
    }

    private static Map<Id, String> fetchProductFamilies(Set<Id> productIds) {
        Map<Id, String> result = new Map<Id, String>();
        for (Product2 product : [SELECT Id, Family FROM Product2 WHERE Id IN :productIds]) {
            result.put(product.Id, product.Family);
        }
        return result;
    }

    private static Map<Id, Set<Id>> fetchDiscountToProducts() {
        Map<Id, Set<Id>> result = new Map<Id, Set<Id>>();
        for (Discount_Product__c discountProduct : [SELECT Discount__c, Product__c FROM Discount_Product__c]) {
            if (!result.containsKey(discountProduct.Discount__c)) result.put(discountProduct.Discount__c, new Set<Id>());
            result.get(discountProduct.Discount__c).add(discountProduct.Product__c);
        }
        return result;
    }

    private static void partitionDiscounts(
        List<Discount__c> activeDiscounts, Decimal orderAmount,
        Set<Id> productIds, Map<Id, Decimal> productQuantities,
        Map<Id, String> productFamilies, Map<Id, Set<Id>> discountToProducts,
        List<Discount__c> globalApplicable, List<Discount__c> targetedApplicable
    ) {
        Date today = Date.today();
        Map<String, DiscountTypeHandler> handlerCache = new Map<String, DiscountTypeHandler>();
        for (Discount__c discount : activeDiscounts) {
            if (!handlerCache.containsKey(discount.Type__c)) {
                handlerCache.put(discount.Type__c, DiscountTypeHandler.forType(discount.Type__c));
            }
            Set<Id> linkedProducts = discountToProducts.get(discount.Id);
            if (!handlerCache.get(discount.Type__c).isApplicable(
                discount, orderAmount, today, productIds, productQuantities, productFamilies, linkedProducts
            )) continue;

            String targetApplication = discount.Target_Application__c != null ? discount.Target_Application__c : DiscountUtils.TARGET_ALL;

            if (targetApplication == DiscountUtils.TARGET_ALL && (discount.Minimum_Quantity__c == null || discount.Minimum_Quantity__c <= 1)) {
                globalApplicable.add(discount);
            } else {
                targetedApplicable.add(discount);
            }
        }
    }

    private static Decimal getTargetAmount(
        Discount__c discount, Map<Id, Decimal> productAmounts,
        Map<Id, Set<Id>> discountToProducts, Map<Id, String> productFamilies,
        Map<Id, Decimal> productQuantities
    ) {
        String targetApplication = discount.Target_Application__c != null ? discount.Target_Application__c : DiscountUtils.TARGET_ALL;
        Decimal total = 0;

        if (targetApplication == DiscountUtils.TARGET_PRODUCTS) {
            Set<Id> linkedProductIds = discountToProducts.get(discount.Id);
            if (linkedProductIds == null) return 0;
            for (Id productId : linkedProductIds) {
                total += calculateEligibleAmount(discount, productId, productAmounts, productQuantities);
            }
        } else if (targetApplication == DiscountUtils.TARGET_FAMILIES) {
            if (discount.Target_Families__c == null) return 0;
            Set<String> targetFamilyNames = new Set<String>();
            for (String family : discount.Target_Families__c.split(',')) targetFamilyNames.add(family.trim());
            for (Id productId : productAmounts.keySet()) {
                String productFamily = productFamilies.get(productId);
                if (productFamily != null && targetFamilyNames.contains(productFamily)) {
                    total += calculateEligibleAmount(discount, productId, productAmounts, productQuantities);
                }
            }
        } else if (targetApplication == DiscountUtils.TARGET_ALL) {
            for (Id productId : productAmounts.keySet()) {
                total += calculateEligibleAmount(discount, productId, productAmounts, productQuantities);
            }
        }

        return total;
    }

    private static Decimal calculateEligibleAmount(
        Discount__c discount, Id productId,
        Map<Id, Decimal> productAmounts, Map<Id, Decimal> productQuantities
    ) {
        Decimal quantity = productQuantities.get(productId);
        Decimal lineAmount = productAmounts.get(productId);
        Decimal eligibleTotal = 0;

        if (quantity != null && quantity > 0 && lineAmount != null) {
            Decimal unitPrice = lineAmount / quantity;

            if (discount.Minimum_Quantity__c != null && discount.Minimum_Quantity__c > 0) {
                if (quantity >= discount.Minimum_Quantity__c) {
                    Decimal eligibleMultiplier = Math.floor(quantity / discount.Minimum_Quantity__c);
                    Decimal eligibleQuantity = eligibleMultiplier * discount.Minimum_Quantity__c;
                    eligibleTotal = (eligibleQuantity * unitPrice);
                }
            } else {
                eligibleTotal = lineAmount;
            }
        }
        return eligibleTotal;
    }

    private static List<Discount__c> selectByStrategy(List<Discount__c> candidates, String strategy, Decimal remaining) {
        if (candidates.isEmpty()) return candidates;
        if (strategy == DiscountUtils.STRATEGY_HIGHEST) {
            Discount__c best = candidates[0];
            Decimal bestDiscountValue = calculateDiscountAmount(best, remaining);
            for (Discount__c discount : candidates) {
                Decimal discountValue = calculateDiscountAmount(discount, remaining);
                if (discountValue > bestDiscountValue) { bestDiscountValue = discountValue; best = discount; }
            }
            return new List<Discount__c>{ best };
        }
        if (strategy == DiscountUtils.STRATEGY_LOWEST) {
            Discount__c lowest = candidates[0];
            Decimal lowestDiscountValue = calculateDiscountAmount(lowest, remaining);
            for (Discount__c discount : candidates) {
                Decimal discountValue = calculateDiscountAmount(discount, remaining);
                if (discountValue < lowestDiscountValue) { lowestDiscountValue = discountValue; lowest = discount; }
            }
            return new List<Discount__c>{ lowest };
        }
        return candidates;
    }

    private static Boolean meetsMinimumDiscountPercentage(Discount__c discount, Decimal applied, Decimal base, Decimal minimumPercentage) {
        if (minimumPercentage == null) return true;
        Decimal effectivePercentage = discount.Discount_Form__c == DiscountUtils.FORM_PERCENTAGE ? discount.Value__c : (base > 0 ? (applied / base * 100) : 0);
        return effectivePercentage >= minimumPercentage;
    }

    private static Decimal calculateDiscountAmount(Discount__c discount, Decimal amount) {
        if (discount.Discount_Form__c == DiscountUtils.FORM_PERCENTAGE) return (amount * discount.Value__c / 100).setScale(2);
        return discount.Value__c;
    }

    private static DiscountPreview buildPreview(Discount__c discount, Decimal applied, Decimal originalPrice, String targetLabel) {
        DiscountPreview preview = new DiscountPreview();
        preview.discountName = discount.Name;
        preview.appliedValue = applied;
        preview.originalPrice = originalPrice;
        preview.discountedPrice = originalPrice - applied;
        preview.targetProductName = targetLabel;
        return preview;
    }
}
