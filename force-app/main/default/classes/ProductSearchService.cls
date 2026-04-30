public with sharing class ProductSearchService {

    public class OrderLineItem {
        @AuraEnabled public Id pricebookEntryId { get; set; }
        @AuraEnabled public Decimal quantity { get; set; }
        @AuraEnabled public Decimal unitPrice { get; set; }
    }

    public static List<PricebookEntry> getProducts(String searchName, String searchFamily, Id opportunityId) {
        Id pricebookId = getOpportunityPricebookId(opportunityId);

        String query = 'SELECT Id, Name, UnitPrice, Product2Id, Product2.Name, Product2.Family, Product2.ProductCode, Product2.Description, Product2.Single_Purchase_Only__c ' +
                       'FROM PricebookEntry ' +
                       'WHERE Pricebook2Id = :pricebookId AND IsActive = true';

        if (String.isNotBlank(searchName)) {
            searchName = '%' + searchName + '%';
            query += ' AND Product2.Name LIKE :searchName';
        }

        if (String.isNotBlank(searchFamily)) {
            query += ' AND Product2.Family = :searchFamily';
        }

        query += ' ORDER BY Product2.Name LIMIT 50';

        return Database.query(query);
    }

    public static List<String> getProductFamilies() {
        List<String> families = new List<String>();
        for (Schema.PicklistEntry entry : Product2.Family.getDescribe().getPicklistValues()) {
            if (entry.isActive()) {
                families.add(entry.getValue());
            }
        }
        return families;
    }

    public static Id createOrder(Id opportunityId, List<OrderLineItem> items) {
        Opportunity opp = [SELECT Id, AccountId, Pricebook2Id FROM Opportunity WHERE Id = :opportunityId];

        Order ord = new Order(
            AccountId = opp.AccountId,
            OpportunityId = opportunityId,
            Pricebook2Id = getOpportunityPricebookId(opportunityId),
            Status = 'Draft',
            EffectiveDate = Date.today()
        );
        insert ord;

        List<OrderItem> orderItems = new List<OrderItem>();
        for (OrderLineItem item : items) {
            orderItems.add(new OrderItem(
                OrderId = ord.Id,
                PricebookEntryId = item.pricebookEntryId,
                Quantity = item.quantity,
                UnitPrice = item.unitPrice
            ));
        }
        insert orderItems;

        return ord.Id;
    }

    private static Id getOpportunityPricebookId(Id opportunityId) {
        Opportunity opp = [SELECT Pricebook2Id FROM Opportunity WHERE Id = :opportunityId];
        if (opp.Pricebook2Id != null) {
            return opp.Pricebook2Id;
        }
        return [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1].Id;
    }
}
