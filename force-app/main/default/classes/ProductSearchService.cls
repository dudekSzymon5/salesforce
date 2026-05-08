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
                       'WHERE Pricebook2Id = :pricebookId AND IsActive = true AND Product2.Is_External__c = false AND Product2.Is_Deleted__c = false';

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
        Opportunity opportunity = [SELECT Id, AccountId, Pricebook2Id FROM Opportunity WHERE Id = :opportunityId];

        Order order = new Order(
            AccountId = opportunity.AccountId,
            OpportunityId = opportunityId,
            Pricebook2Id = getOpportunityPricebookId(opportunityId),
            Status = 'Draft',
            EffectiveDate = Date.today()
        );
        insert order;

        List<OrderItem> orderItems = new List<OrderItem>();
        for (OrderLineItem item : items) {
            orderItems.add(new OrderItem(
                OrderId = order.Id,
                PricebookEntryId = item.pricebookEntryId,
                Quantity = item.quantity,
                UnitPrice = item.unitPrice
            ));
        }
        insert orderItems;

        return order.Id;
    }

    private static Id getOpportunityPricebookId(Id opportunityId) {
        Opportunity opportunity = [SELECT Pricebook2Id FROM Opportunity WHERE Id = :opportunityId];
        if (opportunity.Pricebook2Id != null) {
            return opportunity.Pricebook2Id;
        }
        return [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1].Id;
    }
}
