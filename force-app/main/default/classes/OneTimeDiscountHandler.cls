public class OneTimeDiscountHandler extends DiscountTypeHandler {

    protected override Boolean meetsTypeConditions(Discount__c discount, Decimal amount, Date today) {
        if (discount.Start_Date__c != null && today < discount.Start_Date__c) return false;
        if (discount.End_Date__c != null && today > discount.End_Date__c) return false;
        return true;
    }
}
