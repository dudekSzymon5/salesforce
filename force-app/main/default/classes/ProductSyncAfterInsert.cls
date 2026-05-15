public class ProductSyncAfterInsert implements TriggerAction.AfterInsert {
    public void afterInsert(List<Product2> newList) {
        // Lista wszystkich produktów 
        // + przy okazji sprawdzam czy jest z mojego ORGA czy Konrada za pomocą Is_External_c
        List<Product2> toSync = new List<Product2>();
        for (Product2 product : newList) {
            if (!product.Is_External__c) {
                toSync.add(product);
            }
        }
        // Jeśli są jakieś produkty do synchronizacji — tworzy Queueable z listą produktów i operacją, i wpieprza go do kolejki.
        if (!toSync.isEmpty()) {
            ProductSyncQueueable.enqueueSync(toSync, Utils.PRODUCT_SYNC.OPERATION.INSERT_OP);
        }
    }
}