public with sharing class ProductSearchController {

    @AuraEnabled(cacheable=true)
    public static List<PricebookEntry> getProducts(String searchName, String searchFamily, Id opportunityId) {
        try {
            return ProductSearchService.getProducts(searchName, searchFamily, opportunityId);
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            ErrorLogger.log('ProductSearchController', e);
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getProductFamilies() {
        try {
            return ProductSearchService.getProductFamilies();
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            ErrorLogger.log('ProductSearchController', e);
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Id createOrder(Id opportunityId, List<ProductSearchService.OrderLineItem> items) {
        try {
            return ProductSearchService.createOrder(opportunityId, items);
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            ErrorLogger.log('ProductSearchController', e);
            throw new AuraHandledException(e.getMessage());
        }
    }
}
