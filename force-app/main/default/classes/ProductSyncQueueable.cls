public class ProductSyncQueueable implements Queueable, Database.AllowsCallouts {
    private List<Product2> products;
    private String operation;

    public ProductSyncQueueable(List<Product2> products, String operation) {
        this.products = products;
        this.operation = operation;
    }

    public void execute(QueueableContext context) {
        if (operation != Utils.PRODUCT_SYNC.OPERATION.DELETE_OP) {
            Set<Id> productIds = new Set<Id>();
            for (Product2 p : products) {
                productIds.add(p.Id);
            }
            Map<Id, Product2> productMap = new Map<Id, Product2>([
                SELECT Id, Name, Description, ProductCode, Family, Language__c
                FROM Product2
                WHERE Id IN :productIds
                FOR UPDATE
            ]);
            products = productMap.values();
        }

        for (Product2 product : products) {
            if (operation == Utils.PRODUCT_SYNC.OPERATION.DELETE_OP) {
                ProductSyncCallout.deleteProduct(product.Id);
            } else {
                ProductSyncCallout.syncProduct(product, operation);
            }
        }
    }
}