public with sharing class ProductSyncSoftDeleteController {
    @AuraEnabled
    public static void softDeleteProduct(Id productId) {
            Product2 product = [
                SELECT Id, Is_Deleted__c
                FROM Product2
                WHERE Id = :productId
                LIMIT 1
            ];
            if (product.Is_Deleted__c == true) {
                throw new AuraHandledException('Product is already deleted');
            }
            try {
            product.Is_Deleted__c = true;
            update product;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}