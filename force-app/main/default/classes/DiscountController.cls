public with sharing class DiscountController {

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

    @AuraEnabled(cacheable=true)
    public static List<Discount__c> getDiscounts() {
        return [
            SELECT Id, Name, Type__c, Discount_Form__c, Value__c, Is_Active__c,
                   Start_Date__c, End_Date__c, Recurrence_Pattern__c, Minimum_Order_Amount__c,
                   Minimum_Quantity__c,
                   Target_Product__c, Target_Product__r.Name,
                   Trigger_Product__c, Trigger_Product__r.Name
            FROM Discount__c
            ORDER BY CreatedDate DESC
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<Id> getAssignedDiscountIds() {
        Set<Id> ids = new Set<Id>();
        for (Order_Discount__c od : [SELECT Discount__c FROM Order_Discount__c WHERE Discount__c != null]) {
            ids.add(od.Discount__c);
        }
        return new List<Id>(ids);
    }

    @AuraEnabled(cacheable=true)
    public static List<Product2> getProductOptions() {
        return [
            SELECT Id, Name FROM Product2
            WHERE IsActive = true
            AND Id IN (SELECT Product2Id FROM PricebookEntry WHERE IsActive = true)
            ORDER BY Name
        ];
    }

    @AuraEnabled(cacheable=true)
    public static Discount_Settings__mdt getDiscountSettings() {
        return [
            SELECT Discount_Strategy__c, Minimum_Discount_Percentage__c
            FROM Discount_Settings__mdt
            WHERE DeveloperName = 'Default'
            LIMIT 1
        ];
    }

    @AuraEnabled
    public static void saveDiscountSettings(String strategy, Decimal minPercentage) {
        Metadata.CustomMetadata cm = new Metadata.CustomMetadata();
        cm.fullName = 'Discount_Settings__mdt.Default';
        cm.label = 'Default';

        Metadata.CustomMetadataValue strategyVal = new Metadata.CustomMetadataValue();
        strategyVal.field = 'Discount_Strategy__c';
        strategyVal.value = strategy;
        cm.values.add(strategyVal);

        Metadata.CustomMetadataValue minVal = new Metadata.CustomMetadataValue();
        minVal.field = 'Minimum_Discount_Percentage__c';
        minVal.value = minPercentage;
        cm.values.add(minVal);

        Metadata.DeployContainer container = new Metadata.DeployContainer();
        container.addMetadata(cm);
        Metadata.Operations.enqueueDeployment(container, null);
    }

    @AuraEnabled
    public static Discount__c saveDiscount(Discount__c discount) {
        if (discount.Id != null) {
            List<Order_Discount__c> assigned = [
                SELECT Id FROM Order_Discount__c WHERE Discount__c = :discount.Id LIMIT 1
            ];
            if (!assigned.isEmpty()) {
                throw new AuraHandledException('This discount is already assigned to an order and cannot be edited.');
            }
        }
        if (discount.Discount_Form__c == 'Percentage' && (discount.Value__c < 0 || discount.Value__c > 100)) {
            throw new AuraHandledException('Percentage discount value must be between 0 and 100.');
        }
        upsert discount;
        return discount;
    }

    @AuraEnabled
    public static void toggleDiscounts(List<Id> discountIds, Boolean isActive) {
        List<Discount__c> discounts = [SELECT Id, Is_Active__c FROM Discount__c WHERE Id IN :discountIds];
        for (Discount__c d : discounts) {
            d.Is_Active__c = isActive;
        }
        update discounts;
    }

    @AuraEnabled
    public static List<Order_Discount__c> applyDiscountsToOrder(Id orderId, Decimal orderAmount) {
        List<OrderItem> orderItems = [
            SELECT PricebookEntry.Product2Id, TotalPrice, Quantity
            FROM OrderItem WHERE OrderId = :orderId
        ];
        Map<Id, Decimal> productAmounts = new Map<Id, Decimal>();
        Map<Id, Decimal> productQuantities = new Map<Id, Decimal>();
        Set<Id> productIds = new Set<Id>();
        for (OrderItem oi : orderItems) {
            productAmounts.put(oi.PricebookEntry.Product2Id, oi.TotalPrice);
            productQuantities.put(oi.PricebookEntry.Product2Id, oi.Quantity);
            productIds.add(oi.PricebookEntry.Product2Id);
        }

        Discount_Settings__mdt settings = getDiscountSettings();
        String strategy = settings.Discount_Strategy__c;
        Decimal minPct = settings.Minimum_Discount_Percentage__c;

        Date today = Date.today();
        List<Discount__c> activeDiscounts = [
            SELECT Id, Name, Type__c, Discount_Form__c, Value__c,
                   Recurrence_Pattern__c, Minimum_Order_Amount__c, Minimum_Quantity__c,
                   Start_Date__c, End_Date__c,
                   Target_Product__c, Trigger_Product__c
            FROM Discount__c
            WHERE Is_Active__c = true
        ];

        List<Discount__c> globalApplicable = new List<Discount__c>();
        List<Discount__c> productApplicable = new List<Discount__c>();
        for (Discount__c d : activeDiscounts) {
            if (!isApplicable(d, orderAmount, today, productIds, productQuantities)) continue;
            if (d.Target_Product__c != null) {
                productApplicable.add(d);
            } else {
                globalApplicable.add(d);
            }
        }

        List<Order_Discount__c> orderDiscounts = new List<Order_Discount__c>();
        Decimal remaining = orderAmount;

        for (Discount__c d : productApplicable) {
            Decimal productAmount = productAmounts.get(d.Target_Product__c);
            if (productAmount == null) continue;
            Decimal applied = getDiscountAmount(d, productAmount);
            Decimal effectivePct = d.Discount_Form__c == 'Percentage' ? d.Value__c : (productAmount > 0 ? (applied / productAmount * 100) : 0);
            if (minPct != null && effectivePct < minPct) continue;

            orderDiscounts.add(new Order_Discount__c(
                Order__c = orderId,
                Discount__c = d.Id,
                Applied_Value__c = applied,
                Original_Price__c = productAmount,
                Discounted_Price__c = productAmount - applied
            ));
            remaining -= applied;
        }

        List<Discount__c> toApplyGlobal = new List<Discount__c>();
        if (!globalApplicable.isEmpty()) {
            if (strategy == 'Highest Discount') {
                Discount__c best = globalApplicable[0];
                Decimal bestVal = getDiscountAmount(best, remaining);
                for (Discount__c d : globalApplicable) {
                    Decimal val = getDiscountAmount(d, remaining);
                    if (val > bestVal) { bestVal = val; best = d; }
                }
                toApplyGlobal.add(best);
            } else if (strategy == 'Lowest Discount') {
                Discount__c lowest = globalApplicable[0];
                Decimal lowestVal = getDiscountAmount(lowest, remaining);
                for (Discount__c d : globalApplicable) {
                    Decimal val = getDiscountAmount(d, remaining);
                    if (val < lowestVal) { lowestVal = val; lowest = d; }
                }
                toApplyGlobal.add(lowest);
            } else {
                toApplyGlobal = globalApplicable;
            }

            for (Discount__c d : toApplyGlobal) {
                Decimal applied = getDiscountAmount(d, remaining);
                Decimal effectivePct = d.Discount_Form__c == 'Percentage' ? d.Value__c : (orderAmount > 0 ? (applied / orderAmount * 100) : 0);
                if (minPct != null && effectivePct < minPct) continue;

                orderDiscounts.add(new Order_Discount__c(
                    Order__c = orderId,
                    Discount__c = d.Id,
                    Applied_Value__c = applied,
                    Original_Price__c = remaining,
                    Discounted_Price__c = remaining - applied
                ));
                remaining -= applied;
            }
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

    @AuraEnabled
    public static List<DiscountPreview> previewDiscounts(Decimal orderAmount, List<ItemInput> items) {
        Map<Id, Decimal> productAmounts = new Map<Id, Decimal>();
        Map<Id, Decimal> productQuantities = new Map<Id, Decimal>();
        Set<Id> productIds = new Set<Id>();
        if (items != null) {
            for (ItemInput item : items) {
                if (item.product2Id != null) {
                    productAmounts.put(item.product2Id, item.amount);
                    productQuantities.put(item.product2Id, item.quantity != null ? item.quantity : 1);
                    productIds.add(item.product2Id);
                }
            }
        }

        Discount_Settings__mdt settings = getDiscountSettings();
        String strategy = settings.Discount_Strategy__c;
        Decimal minPct = settings.Minimum_Discount_Percentage__c;

        Date today = Date.today();
        List<Discount__c> activeDiscounts = [
            SELECT Id, Name, Type__c, Discount_Form__c, Value__c,
                   Recurrence_Pattern__c, Minimum_Order_Amount__c, Minimum_Quantity__c,
                   Start_Date__c, End_Date__c,
                   Target_Product__c, Target_Product__r.Name,
                   Trigger_Product__c
            FROM Discount__c
            WHERE Is_Active__c = true
        ];

        List<Discount__c> globalApplicable = new List<Discount__c>();
        List<Discount__c> productApplicable = new List<Discount__c>();
        for (Discount__c d : activeDiscounts) {
            if (!isApplicable(d, orderAmount, today, productIds, productQuantities)) continue;
            if (d.Target_Product__c != null) {
                productApplicable.add(d);
            } else {
                globalApplicable.add(d);
            }
        }

        List<DiscountPreview> previews = new List<DiscountPreview>();
        Decimal remaining = orderAmount;

        for (Discount__c d : productApplicable) {
            Decimal productAmount = productAmounts.get(d.Target_Product__c);
            if (productAmount == null) continue;
            Decimal applied = getDiscountAmount(d, productAmount);
            Decimal effectivePct = d.Discount_Form__c == 'Percentage' ? d.Value__c : (productAmount > 0 ? (applied / productAmount * 100) : 0);
            if (minPct != null && effectivePct < minPct) continue;

            DiscountPreview p = new DiscountPreview();
            p.discountName = d.Name;
            p.appliedValue = applied;
            p.originalPrice = productAmount;
            p.discountedPrice = productAmount - applied;
            p.targetProductName = d.Target_Product__r.Name;
            previews.add(p);
            remaining -= applied;
        }

        List<Discount__c> toApplyGlobal = new List<Discount__c>();
        if (!globalApplicable.isEmpty()) {
            if (strategy == 'Highest Discount') {
                Discount__c best = globalApplicable[0];
                Decimal bestVal = getDiscountAmount(best, remaining);
                for (Discount__c d : globalApplicable) {
                    Decimal val = getDiscountAmount(d, remaining);
                    if (val > bestVal) { bestVal = val; best = d; }
                }
                toApplyGlobal.add(best);
            } else if (strategy == 'Lowest Discount') {
                Discount__c lowest = globalApplicable[0];
                Decimal lowestVal = getDiscountAmount(lowest, remaining);
                for (Discount__c d : globalApplicable) {
                    Decimal val = getDiscountAmount(d, remaining);
                    if (val < lowestVal) { lowestVal = val; lowest = d; }
                }
                toApplyGlobal.add(lowest);
            } else {
                toApplyGlobal = globalApplicable;
            }

            for (Discount__c d : toApplyGlobal) {
                Decimal applied = getDiscountAmount(d, remaining);
                Decimal effectivePct = d.Discount_Form__c == 'Percentage' ? d.Value__c : (orderAmount > 0 ? (applied / orderAmount * 100) : 0);
                if (minPct != null && effectivePct < minPct) continue;

                DiscountPreview p = new DiscountPreview();
                p.discountName = d.Name;
                p.appliedValue = applied;
                p.originalPrice = remaining;
                p.discountedPrice = remaining - applied;
                p.targetProductName = null;
                previews.add(p);
                remaining -= applied;
            }
        }

        return previews;
    }

    private static Boolean isApplicable(Discount__c d, Decimal amount, Date today, Set<Id> productIds, Map<Id, Decimal> productQuantities) {
        if (d.Trigger_Product__c != null && !productIds.contains(d.Trigger_Product__c)) return false;
        if (d.Target_Product__c != null && !productIds.contains(d.Target_Product__c)) return false;
        if (d.Minimum_Quantity__c != null) {
            Id qtyCheckId = d.Trigger_Product__c != null ? d.Trigger_Product__c : d.Target_Product__c;
            Decimal qty = qtyCheckId != null ? productQuantities.get(qtyCheckId) : null;
            if (qty == null || qty < d.Minimum_Quantity__c) return false;
        }

        if (d.Type__c == 'Conditional' && d.Minimum_Order_Amount__c != null && amount < d.Minimum_Order_Amount__c) return false;

        if (d.Type__c == 'Recurring') {
            if (d.Recurrence_Pattern__c == 'Every Monday') {
                return today.toStartOfWeek().addDays(1) == today;
            }
            if (d.Recurrence_Pattern__c == 'Last Day of Month') {
                return today.addDays(1).month() != today.month();
            }
            if (d.Recurrence_Pattern__c == 'Black Friday') {
                if (today.month() != 11) return false;
                Date nov1 = Date.newInstance(today.year(), 11, 1);
                Integer dow = Math.mod(Date.newInstance(1900,1,7).daysBetween(nov1), 7);
                Integer daysToFriday = Math.mod(5 - dow, 7);
                Date blackFriday = nov1.addDays(daysToFriday + 21);
                return today == blackFriday;
            }
            if (d.Recurrence_Pattern__c == 'Custom Date') {
                return d.Start_Date__c != null
                    && today.month() == d.Start_Date__c.month()
                    && today.day() == d.Start_Date__c.day();
            }
            return false;
        }

        if (d.Start_Date__c != null && today < d.Start_Date__c) return false;
        if (d.End_Date__c != null && today > d.End_Date__c) return false;
        return true;
    }

    private static Decimal getDiscountAmount(Discount__c d, Decimal amount) {
        if (d.Discount_Form__c == 'Percentage') return (amount * d.Value__c / 100).setScale(2);
        return d.Value__c;
    }
}
