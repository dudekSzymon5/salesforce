public with sharing class CaseTriggerHandler {

    public static void updateOrderRefundTotals(List<Case> newCases, List<Case> oldCases) {
        Set<Id> orderIds = new Set<Id>();
        if (newCases != null) {
            for (Case c : newCases) {
                if (c.Order__c != null) orderIds.add(c.Order__c);
            }
        }
        if (oldCases != null) {
            for (Case c : oldCases) {
                if (c.Order__c != null) orderIds.add(c.Order__c);
            }
        }
        recalculateTotals(orderIds);
    }

    public static void updateOrderRefundTotalsByCop(List<Case_Order_Product__c> newCops, List<Case_Order_Product__c> oldCops) {
        Set<Id> orderIds = new Set<Id>();
        if (newCops != null) {
            for (Case_Order_Product__c cop : newCops) {
                if (cop.Order__c != null) orderIds.add(cop.Order__c);
            }
        }
        if (oldCops != null) {
            for (Case_Order_Product__c cop : oldCops) {
                if (cop.Order__c != null) orderIds.add(cop.Order__c);
            }
        }
        recalculateTotals(orderIds);
    }

    private static void recalculateTotals(Set<Id> orderIds) {
        if (orderIds.isEmpty()) return;

        Map<Id, Decimal> totals = new Map<Id, Decimal>();
        for (Id orderId : orderIds) {
            totals.put(orderId, 0);
        }

        for (AggregateResult ar : [
            SELECT Order__c, SUM(Refund_Amount__c) total
            FROM Case_Order_Product__c
            WHERE Order__c IN :orderIds
            AND Refund_Amount__c != null
            GROUP BY Order__c
        ]) {
            totals.put((Id) ar.get('Order__c'), (Decimal) ar.get('total'));
        }

        List<Order> ordersToUpdate = new List<Order>();
        for (Id orderId : totals.keySet()) {
            ordersToUpdate.add(new Order(
                Id = orderId,
                Total_Refund_Amount__c = totals.get(orderId)
            ));
        }

        if (!ordersToUpdate.isEmpty()) {
            update ordersToUpdate;
        }
    }
}
