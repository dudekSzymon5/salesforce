public with sharing class ProductSyncSoftDeleteController {
    @AuraEnabled
    public static void softDeleteProduct(Id productId) {
        try {
            Product2 product = [
                SELECT Id, Is_Deleted__c
                FROM Product2
                WHERE Id = :productId
                LIMIT 1
            ];
            if (product.Is_Deleted__c == true) {
                AuraHandledException exception = new AuraHandledException('Product is already deleted');
                exception.setMessage('Product is already deleted');
                throw exception;
            }
            product.Is_Deleted__c = true;
            update product;
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            AuraHandledException exception = new AuraHandledException(e.getMessage());
            exception.setMessage(e.getMessage());
            throw exception;
        }
    }
}