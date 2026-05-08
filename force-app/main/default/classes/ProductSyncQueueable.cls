public class ProductSyncQueueable implements Queueable, Database.AllowsCallouts {
    private List<Product2> products;
    private String operation;

    public ProductSyncQueueable(List<Product2> products, String operation) {
        this.products = products;
        this.operation = operation;
    }

    public void execute(QueueableContext ctx) {
        for (Product2 p : products) {
            if (operation == 'DELETE') {
                ProductSyncCallout.deleteProduct(p.Id);
            } else {
                ProductSyncCallout.syncProduct(p);
            }
        }
    }
}