public class ProductSyncAfterDelete implements TriggerAction.AfterDelete {
    public void afterDelete(List<Product2> oldList) {
        List<Product2> toSync = new List<Product2>();
        for (Product2 product : oldList) {
            if (!product.Is_External__c) {
                toSync.add(product);
            }
        }
        if (!toSync.isEmpty()) {
            ProductSyncQueueable job = new ProductSyncQueueable(toSync, 'DELETE');
            System.enqueueJob(job);
        }
    }
}