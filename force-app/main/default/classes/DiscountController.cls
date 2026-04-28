public with sharing class DiscountController {

    @AuraEnabled(cacheable=true)
    public static List<Discount__c> getDiscounts() {
        return [
            SELECT Id, Name, Type__c, Discount_Form__c, Value__c, Is_Active__c,
                   Start_Date__c, End_Date__c, Recurrence_Pattern__c, Minimum_Order_Amount__c
            FROM Discount__c
            ORDER BY CreatedDate DESC
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
        Discount_Settings__mdt settings = getDiscountSettings();
        String strategy = settings.Discount_Strategy__c;
        Decimal minPct = settings.Minimum_Discount_Percentage__c;

        Date today = Date.today();
        List<Discount__c> activeDiscounts = [
            SELECT Id, Name, Type__c, Discount_Form__c, Value__c,
                   Recurrence_Pattern__c, Minimum_Order_Amount__c,
                   Start_Date__c, End_Date__c
            FROM Discount__c
            WHERE Is_Active__c = true
        ];

        List<Discount__c> applicable = new List<Discount__c>();
        for (Discount__c d : activeDiscounts) {
            if (isApplicable(d, orderAmount, today)) {
                applicable.add(d);
            }
        }

        if (applicable.isEmpty()) return new List<Order_Discount__c>();

        List<Discount__c> toApply = new List<Discount__c>();

        if (strategy == 'Highest Discount') {
            Discount__c best = applicable[0];
            Decimal bestVal = getDiscountAmount(best, orderAmount);
            for (Discount__c d : applicable) {
                Decimal val = getDiscountAmount(d, orderAmount);
                if (val > bestVal) { bestVal = val; best = d; }
            }
            toApply.add(best);
        } else if (strategy == 'Lowest Discount') {
            Discount__c lowest = applicable[0];
            Decimal lowestVal = getDiscountAmount(lowest, orderAmount);
            for (Discount__c d : applicable) {
                Decimal val = getDiscountAmount(d, orderAmount);
                if (val < lowestVal) { lowestVal = val; lowest = d; }
            }
            toApply.add(lowest);
        } else {
            toApply = applicable;
        }

        List<Order_Discount__c> orderDiscounts = new List<Order_Discount__c>();
        Decimal remaining = orderAmount;

        for (Discount__c d : toApply) {
            Decimal applied = getDiscountAmount(d, remaining);
            Decimal effectivePct = d.Discount_Form__c == 'Percentage' ? d.Value__c : (applied / orderAmount * 100);
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

        if (!orderDiscounts.isEmpty()) {
            insert orderDiscounts;
            return [
                SELECT Id, Discount__c, Discount__r.Name, Applied_Value__c,
                    Original_Price__c, Discounted_Price__c
                FROM Order_Discount__c
                WHERE Order__c = :orderId
            ];
        }
        return new List<Order_Discount__c>();
    }

    public class DiscountPreview {
        @AuraEnabled public String discountName;
        @AuraEnabled public Decimal appliedValue;
        @AuraEnabled public Decimal originalPrice;
        @AuraEnabled public Decimal discountedPrice;
    }

    @AuraEnabled
    public static List<DiscountPreview> previewDiscounts(Decimal orderAmount) {
        Discount_Settings__mdt settings = getDiscountSettings();
        String strategy = settings.Discount_Strategy__c;
        Decimal minPct = settings.Minimum_Discount_Percentage__c;

        Date today = Date.today();
        List<Discount__c> activeDiscounts = [
            SELECT Id, Name, Type__c, Discount_Form__c, Value__c,
                   Recurrence_Pattern__c, Minimum_Order_Amount__c,
                   Start_Date__c, End_Date__c
            FROM Discount__c
            WHERE Is_Active__c = true
        ];

        List<Discount__c> applicable = new List<Discount__c>();
        for (Discount__c d : activeDiscounts) {
            if (isApplicable(d, orderAmount, today)) applicable.add(d);
        }

        if (applicable.isEmpty()) return new List<DiscountPreview>();

        List<Discount__c> toApply = new List<Discount__c>();
        if (strategy == 'Highest Discount') {
            Discount__c best = applicable[0];
            Decimal bestVal = getDiscountAmount(best, orderAmount);
            for (Discount__c d : applicable) {
                Decimal val = getDiscountAmount(d, orderAmount);
                if (val > bestVal) { bestVal = val; best = d; }
            }
            toApply.add(best);
        } else if (strategy == 'Lowest Discount') {
            Discount__c lowest = applicable[0];
            Decimal lowestVal = getDiscountAmount(lowest, orderAmount);
            for (Discount__c d : applicable) {
                Decimal val = getDiscountAmount(d, orderAmount);
                if (val < lowestVal) { lowestVal = val; lowest = d; }
            }
            toApply.add(lowest);
        } else {
            toApply = applicable;
        }

        List<DiscountPreview> previews = new List<DiscountPreview>();
        Decimal remaining = orderAmount;
        for (Discount__c d : toApply) {
            Decimal applied = getDiscountAmount(d, remaining);
            Decimal effectivePct = d.Discount_Form__c == 'Percentage' ? d.Value__c : (applied / orderAmount * 100);
            if (minPct != null && effectivePct < minPct) continue;

            DiscountPreview p = new DiscountPreview();
            p.discountName = d.Name;
            p.appliedValue = applied;
            p.originalPrice = remaining;
            p.discountedPrice = remaining - applied;
            previews.add(p);
            remaining -= applied;
        }
        return previews;
    }

    private static Boolean isApplicable(Discount__c d, Decimal amount, Date today) {
        if (d.Type__c == 'Conditional' && d.Minimum_Order_Amount__c != null && amount < d.Minimum_Order_Amount__c) return false;
        if (d.Type__c == 'Recurring') {
            if (d.Recurrence_Pattern__c == 'Every Monday' && today.toStartOfWeek().addDays(1) != today) return false;
            if (d.Recurrence_Pattern__c == 'Last Day of Month' && today.addDays(1).month() != today.month()) return false;
            if (d.Recurrence_Pattern__c == 'Black Friday') {
                if (today.month() != 11) return false;
                Date nov1 = Date.newInstance(today.year(), 11, 1);
                Integer dow = Math.mod(Date.newInstance(1900,1,7).daysBetween(nov1), 7);
                Integer daysToFriday = Math.mod(5 - dow, 7);
                Date blackFriday = nov1.addDays(daysToFriday + 21);
                if (today != blackFriday) return false;
            }
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