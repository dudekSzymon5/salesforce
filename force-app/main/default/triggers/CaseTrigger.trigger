trigger CaseTrigger on Case (after insert, after update, after delete, after undelete) {
    List<Case> newCases = (Trigger.isDelete) ? null : Trigger.new;
    List<Case> oldCases = (Trigger.isInsert || Trigger.isUndelete) ? null : Trigger.old;
    CaseTriggerHandler.updateOrderRefundTotals(newCases, oldCases);
}
