public class OneTimeDiscountHandler extends DiscountTypeHandler {

    protected override Boolean meetsTypeConditions(Discount__c d, Decimal amount, Date today) {
        if (d.Start_Date__c != null && today < d.Start_Date__c) return false;
        if (d.End_Date__c != null && today > d.End_Date__c) return false;
        return true;
    }
}
