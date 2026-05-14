public class ProductSyncQueueable implements Queueable, Database.AllowsCallouts {
    private List<Product2> products;
    private String operation;

    // Tutaj dostaje listę produktów i typ operacji z triggera
    // Database.AllowsCallouts pozwala na HTTP requesty
    public ProductSyncQueueable(List<Product2> products, String operation) {
        this.products = products;
        this.operation = operation;
    }

    //Iteruje sobie po liście produktów i wybieram odpowiednią metodę w zależności od operacji
    public void execute(QueueableContext context) {
        for (Product2 product : products) {
            if (operation == Utils.PRODUCT_SYNC.OPERATION.DELETE_OP) {
                ProductSyncCallout.deleteProduct(product.Id);
            } else {
                // Teraz daje operation (insert albo update) do syncProduct żeby retry queue wiedziało
                // jaki typ operacji zapisać — wcześniej nie przyjmował operacji
                // i zawsze zapisywał insert
                ProductSyncCallout.syncProduct(product, operation);
            }
        }
    }
}