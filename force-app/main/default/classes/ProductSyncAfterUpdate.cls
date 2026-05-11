public class ProductSyncAfterUpdate implements TriggerAction.AfterUpdate {
    public void afterUpdate(List<Product2> newList, List<Product2> oldList) {
        List<Product2> toSync = new List<Product2>();
        for (Product2 product : newList) {
            if (!product.Is_External__c) {
                toSync.add(product);
            }
        }
        if (!toSync.isEmpty()) {
            ProductSyncQueueable job = new ProductSyncQueueable(toSync, 'UPDATE');
            System.enqueueJob(job);
        }
    }
}