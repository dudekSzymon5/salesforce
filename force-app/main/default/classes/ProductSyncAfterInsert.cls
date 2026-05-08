public class ProductSyncAfterInsert implements TriggerAction.AfterInsert {
    public void afterInsert(List<Product2> newList) {
        List<Product2> toSync = new List<Product2>();
        for (Product2 p : newList) {
            if (!p.Is_External__c) {
                toSync.add(p);
            }
        }
        if (!toSync.isEmpty()) {
            ProductSyncQueueable job = new ProductSyncQueueable(toSync, 'INSERT');
            System.enqueueJob(job);
        }
    }
}