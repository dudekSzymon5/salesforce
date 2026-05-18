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
                AuraHandledException ex = new AuraHandledException('Product is already deleted');
                ex.setMessage('Product is already deleted');
                throw ex;
            }
            product.Is_Deleted__c = true;
            update product;
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            AuraHandledException ex = new AuraHandledException(e.getMessage());
            ex.setMessage(e.getMessage());
            throw ex;
        }
    }
}