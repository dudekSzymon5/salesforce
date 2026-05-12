public class ProductSyncQueueable implements Queueable, Database.AllowsCallouts {
    private List<Product2> products;
    private String operation;
    // Przechowuje sobie tutaj to co dostałem z Triggera
    // Produkty i operacje
    // Database.AllowsCallouts daje możliwość robienia HTTP requestów
    public ProductSyncQueueable(List<Product2> products, String operation) {
        this.products = products;
        this.operation = operation;
    }
    public void execute(QueueableContext context) {
        // Następuje przekierowanie do ProductSyncCallout
        for (Product2 product : products) {
            if (operation == Utils.PRODUCT_SYNC.OPERATION.DELETE_OP) {
                ProductSyncCallout.deleteProduct(product.Id);
            } else {
                ProductSyncCallout.syncProduct(product);
            }
        }
    }
}