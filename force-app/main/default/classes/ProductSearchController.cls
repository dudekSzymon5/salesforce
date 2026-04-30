public with sharing class ProductSearchController {

    @AuraEnabled(cacheable=true)
    public static List<PricebookEntry> getProducts(String searchName, String searchFamily, Id opportunityId) {
        return ProductSearchService.getProducts(searchName, searchFamily, opportunityId);
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getProductFamilies() {
        return ProductSearchService.getProductFamilies();
    }

    @AuraEnabled
    public static Id createOrder(Id opportunityId, List<ProductSearchService.OrderLineItem> items) {
        return ProductSearchService.createOrder(opportunityId, items);
    }
}
