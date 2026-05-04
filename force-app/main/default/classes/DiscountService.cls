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
        for (Order_Discount__c od : [SELECT Discount__c FROM Order_Discount__c WHERE Discount__c != null]) {
            ids.add(od.Discount__c);
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
        for (Product2 p : [SELECT Family FROM Product2 WHERE IsActive = true AND Family != null]) {
            families.add(p.Family);
        }
        List<String> result = new List<String>(families);
        result.sort();
        return result;
    }

    public static List<Id> getDiscountProducts(Id discountId) {
        List<Id> productIds = new List<Id>();
        for (Discount_Product__c dp : [SELECT Product__c FROM Discount_Product__c WHERE Discount__c = :discountId]) {
            productIds.add(dp.Product__c);
        }
        return productIds;
    }

    public static void saveDiscountProducts(Id discountId, List<Id> productIds) {
        delete [SELECT Id FROM Discount_Product__c WHERE Discount__c = :discountId];
        List<Discount_Product__c> toInsert = new List<Discount_Product__c>();
        for (Id pid : productIds) {
            toInsert.add(new Discount_Product__c(Discount__c = discountId, Product__c = pid));
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
        for (OrderItem oi : orderItems) {
            productAmounts.put(oi.PricebookEntry.Product2Id, oi.TotalPrice);
            productQuantities.put(oi.PricebookEntry.Product2Id, oi.Quantity);
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

        for (Discount__c d : targetedApplicable) {
            Decimal baseAmount = getTargetAmount(d, productAmounts, discountToProducts, productFamilies, productQuantities);
            if (baseAmount == 0) continue;
            Decimal applied = calcAmount(d, baseAmount);
            if (!meetsMinPct(d, applied, baseAmount, settings.Minimum_Discount_Percentage__c)) continue;
            orderDiscounts.add(new Order_Discount__c(
                Order__c = orderId,
                Discount__c = d.Id,
                Applied_Value__c = applied,
                Original_Price__c = baseAmount,
                Discounted_Price__c = baseAmount - applied
            ));
            remaining -= applied;
        }

        for (Discount__c d : selectByStrategy(globalApplicable, settings.Discount_Strategy__c, remaining)) {
            Decimal applied = calcAmount(d, remaining);
            if (!meetsMinPct(d, applied, orderAmount, settings.Minimum_Discount_Percentage__c)) continue;
            orderDiscounts.add(new Order_Discount__c(
                Order__c = orderId,
                Discount__c = d.Id,
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

        for (Discount__c d : targetedApplicable) {
            Decimal baseAmount = getTargetAmount(d, productAmounts, discountToProducts, productFamilies, productQuantities);
            if (baseAmount == 0) continue;
            Decimal applied = calcAmount(d, baseAmount);
            if (!meetsMinPct(d, applied, baseAmount, settings.Minimum_Discount_Percentage__c)) continue;
            previews.add(buildPreview(d, applied, baseAmount, d.Target_Application__c));
            remaining -= applied;
        }

        for (Discount__c d : selectByStrategy(globalApplicable, settings.Discount_Strategy__c, remaining)) {
            Decimal applied = calcAmount(d, remaining);
            if (!meetsMinPct(d, applied, orderAmount, settings.Minimum_Discount_Percentage__c)) continue;
            previews.add(buildPreview(d, applied, remaining, null));
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
                throw new AuraHandledException(Utils.Discount.ERROR_ALREADY_ASSIGNED);
            }
        }
        if (discount.Discount_Form__c == Utils.Discount.FORM_PERCENTAGE && (discount.Value__c < 0 || discount.Value__c > 100)) {
            throw new AuraHandledException(Utils.Discount.ERROR_PERCENTAGE_RANGE);
        }
        
        if (discount.Condition_Type__c == Utils.Discount.CONDITION_TWO_FOR_ONE) {
            discount.Minimum_Quantity__c = 2;
        }

        upsert discount;
        return discount;
    }

    public static void toggleDiscounts(List<Id> discountIds, Boolean isActive) {
        List<Discount__c> discounts = [SELECT Id, Is_Active__c FROM Discount__c WHERE Id IN :discountIds];
        for (Discount__c d : discounts) {
            d.Is_Active__c = isActive;
        }
        update discounts;
    }

    public static void saveDiscountSettings(String strategy, Decimal minPercentage) {
        Metadata.CustomMetadata cm = new Metadata.CustomMetadata();
        cm.fullName = Utils.DiscountSettings.FULL_NAME;
        cm.label = Utils.DiscountSettings.LABEL;

        Metadata.CustomMetadataValue strategyVal = new Metadata.CustomMetadataValue();
        strategyVal.field = Utils.DiscountSettings.FIELD_STRATEGY;
        strategyVal.value = strategy;
        cm.values.add(strategyVal);

        Metadata.CustomMetadataValue minVal = new Metadata.CustomMetadataValue();
        minVal.field = Utils.DiscountSettings.FIELD_MIN_PCT;
        minVal.value = minPercentage;
        cm.values.add(minVal);

        Metadata.DeployContainer container = new Metadata.DeployContainer();
        container.addMetadata(cm);
        Metadata.Operations.enqueueDeployment(container, null);
    }

    private static Discount_Settings__mdt getSettings() {
        return [
            SELECT Discount_Strategy__c, Minimum_Discount_Percentage__c
            FROM Discount_Settings__mdt
            WHERE DeveloperName = :Utils.DiscountSettings.DEVELOPER_NAME
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
        for (Product2 p : [SELECT Id, Family FROM Product2 WHERE Id IN :productIds]) {
            result.put(p.Id, p.Family);
        }
        return result;
    }

    private static Map<Id, Set<Id>> fetchDiscountToProducts() {
        Map<Id, Set<Id>> result = new Map<Id, Set<Id>>();
        for (Discount_Product__c dp : [SELECT Discount__c, Product__c FROM Discount_Product__c]) {
            if (!result.containsKey(dp.Discount__c)) result.put(dp.Discount__c, new Set<Id>());
            result.get(dp.Discount__c).add(dp.Product__c);
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
        for (Discount__c d : activeDiscounts) {
            if (!handlerCache.containsKey(d.Type__c)) {
                handlerCache.put(d.Type__c, DiscountTypeHandler.forType(d.Type__c));
            }
            Set<Id> linkedProducts = discountToProducts.get(d.Id);
            if (!handlerCache.get(d.Type__c).isApplicable(
                d, orderAmount, today, productIds, productQuantities, productFamilies, linkedProducts
            )) continue;

            String targetApp = d.Target_Application__c != null ? d.Target_Application__c : Utils.Discount.TARGET_ALL;
            
            // Poprawka dla All Products + Minimum Quantity
            if (targetApp == Utils.Discount.TARGET_ALL && (d.Minimum_Quantity__c == null || d.Minimum_Quantity__c <= 1)) {
                globalApplicable.add(d);
            } else {
                targetedApplicable.add(d);
            }
        }
    }

    private static Decimal getTargetAmount(
        Discount__c d, Map<Id, Decimal> productAmounts,
        Map<Id, Set<Id>> discountToProducts, Map<Id, String> productFamilies,
        Map<Id, Decimal> productQuantities
    ) {
        String targetApp = d.Target_Application__c != null ? d.Target_Application__c : Utils.Discount.TARGET_ALL;
        Decimal total = 0;

        if (targetApp == Utils.Discount.TARGET_PRODUCTS) {
            Set<Id> linked = discountToProducts.get(d.Id);
            if (linked == null) return 0;
            for (Id pid : linked) {
                total += calculateEligibleAmount(d, pid, productAmounts, productQuantities);
            }
        } else if (targetApp == Utils.Discount.TARGET_FAMILIES) {
            if (d.Target_Families__c == null) return 0;
            Set<String> targetFams = new Set<String>();
            for (String f : d.Target_Families__c.split(',')) targetFams.add(f.trim());
            for (Id pid : productAmounts.keySet()) {
                String fam = productFamilies.get(pid);
                if (fam != null && targetFams.contains(fam)) {
                    total += calculateEligibleAmount(d, pid, productAmounts, productQuantities);
                }
            }
        } else if (targetApp == Utils.Discount.TARGET_ALL) {
            // Obsługa "All Products" linijka po linijce dla warunku ilościowego
            for (Id pid : productAmounts.keySet()) {
                total += calculateEligibleAmount(d, pid, productAmounts, productQuantities);
            }
        }

        return total;
    }

    private static Decimal calculateEligibleAmount(
        Discount__c d, Id pid, 
        Map<Id, Decimal> productAmounts, Map<Id, Decimal> productQuantities
    ) {
        Decimal qty = productQuantities.get(pid);
        Decimal lineAmount = productAmounts.get(pid);
        Decimal eligibleTotal = 0;

        if (qty != null && qty > 0 && lineAmount != null) {
            Decimal unitPrice = lineAmount / qty;
            
            if (d.Minimum_Quantity__c != null && d.Minimum_Quantity__c > 0) {
                if (qty >= d.Minimum_Quantity__c) {
                    Decimal eligibleMultiplier = Math.floor(qty / d.Minimum_Quantity__c);
                    Decimal eligibleQty = eligibleMultiplier * d.Minimum_Quantity__c;
                    eligibleTotal = (eligibleQty * unitPrice);
                }
            } else {
                eligibleTotal = lineAmount;
            }
        }
        return eligibleTotal;
    }

    private static List<Discount__c> selectByStrategy(List<Discount__c> candidates, String strategy, Decimal remaining) {
        if (candidates.isEmpty()) return candidates;
        if (strategy == Utils.Discount.STRATEGY_HIGHEST) {
            Discount__c best = candidates[0];
            Decimal bestVal = calcAmount(best, remaining);
            for (Discount__c d : candidates) {
                Decimal val = calcAmount(d, remaining);
                if (val > bestVal) { bestVal = val; best = d; }
            }
            return new List<Discount__c>{ best };
        }
        if (strategy == Utils.Discount.STRATEGY_LOWEST) {
            Discount__c lowest = candidates[0];
            Decimal lowestVal = calcAmount(lowest, remaining);
            for (Discount__c d : candidates) {
                Decimal val = calcAmount(d, remaining);
                if (val < lowestVal) { lowestVal = val; lowest = d; }
            }
            return new List<Discount__c>{ lowest };
        }
        return candidates;
    }

    private static Boolean meetsMinPct(Discount__c d, Decimal applied, Decimal base, Decimal minPct) {
        if (minPct == null) return true;
        Decimal effectivePct = d.Discount_Form__c == Utils.Discount.FORM_PERCENTAGE ? d.Value__c : (base > 0 ? (applied / base * 100) : 0);
        return effectivePct >= minPct;
    }

    private static Decimal calcAmount(Discount__c d, Decimal amount) {
        if (d.Discount_Form__c == Utils.Discount.FORM_PERCENTAGE) return (amount * d.Value__c / 100).setScale(2);
        return d.Value__c;
    }

    private static DiscountPreview buildPreview(Discount__c d, Decimal applied, Decimal originalPrice, String targetLabel) {
        DiscountPreview p = new DiscountPreview();
        p.discountName = d.Name;
        p.appliedValue = applied;
        p.originalPrice = originalPrice;
        p.discountedPrice = originalPrice - applied;
        p.targetProductName = targetLabel;
        return p;
    }
}