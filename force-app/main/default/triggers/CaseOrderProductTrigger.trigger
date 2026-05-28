trigger CaseOrderProductTrigger on Case_Order_Product__c (after insert, after update, after delete, after undelete) {
    List<Case_Order_Product__c> newCops = Trigger.isDelete ? null : Trigger.new;
    List<Case_Order_Product__c> oldCops = (Trigger.isInsert || Trigger.isUndelete) ? null : Trigger.old;
    CaseTriggerHandler.updateOrderRefundTotalsByCop(newCops, oldCops);
}
