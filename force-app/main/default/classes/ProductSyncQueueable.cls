public class ProductSyncQueueable implements Queueable, Database.AllowsCallouts {
    private List<Product2> products;
    private String operation;

    public ProductSyncQueueable() {}

    public ProductSyncQueueable(List<Product2> products, String operation) {
        this.products = products;
        this.operation = operation;
    }

    public void execute(QueueableContext context) {
        List<Product_Sync_Queue__c> pending = [
            SELECT Id, Product__c, Operation__c, Payload__c
            FROM Product_Sync_Queue__c
            WHERE Status__c = :Utils.PRODUCT_SYNC.STATUS.PENDING
            FOR UPDATE
        ];

        Set<Id> productsId = new Set<Id>();
        for (Product_Sync_Queue__c record: pending) {
            if (record.Operation__c != Utils.PRODUCT_SYNC.OPERATION.DELETE_OP) {
                productsId.add(record.Product__c);
            }
        }

        Map<Id, Product2> productMap = new Map<Id, Product2>([
            SELECT Id, Name, Description, ProductCode, Family, Language__c
            FROM Product2
            WHERE Id IN :productsId
            FOR UPDATE
        ]);

        for (Product_Sync_Queue__c record : pending) {
            if (record.Operation__c == Utils.PRODUCT_SYNC.OPERATION.DELETE_OP) {
                ProductSyncCallout.deleteProduct(record.Payload__c);
            } else {
                Product2 product = productMap.get(record.Product__c);
                if (product != null) {
                    ProductSyncCallout.syncProduct(product, record.Operation__c);
                }
            }
        }
        delete pending;
    }

    public static void enqueueSync(List<Product2> products, String operation) {
        if (operation == Utils.PRODUCT_SYNC.OPERATION.DELETE_OP ) {
            List<Product_Sync_Queue__c> toInsert = new List<Product_Sync_Queue__c>();
            for (Product2 product : products) {
                Product_Sync_Queue__c newRecord = new Product_Sync_Queue__c(
                    Payload__c = product.Id,
                    Operation__c = operation,
                    Status__c = Utils.PRODUCT_SYNC.STATUS.PENDING
                );
                toInsert.add(newRecord);
            }
            insert toInsert;

            Integer howManyQueuedJobs = [SELECT COUNT() FROM AsyncApexJob WHERE Status IN :Utils.PRODUCT_SYNC.JOB_STATUS.ACTIVE AND ApexClass.Name = 'ProductSyncQueueable'];
            if (howManyQueuedJobs == 0) {
            System.enqueueJob(new ProductSyncQueueable());
            }
        } else {
             Set<Id> productsId = new Set<Id>();
        for (Product2 product : products) {
            productsId.add(product.Id);
        }

        Map<Id, Product_Sync_Queue__c> isPending = new Map<Id, Product_Sync_Queue__c>();
            for (Product_Sync_Queue__c queue : [
                SELECT Id, Product__c, Operation__c
                FROM Product_Sync_Queue__c
                WHERE Product__c IN :productsId AND Status__c = :Utils.PRODUCT_SYNC.STATUS.PENDING
                ]) {
                isPending.put(queue.Product__c, queue);
        }

        List<Product_Sync_Queue__c> toUpsert = new List<Product_Sync_Queue__c>();
        for (Product2 product : products) {
            if (isPending.containsKey(product.Id)) {
                Product_Sync_Queue__c queue = isPending.get(product.Id);
                queue.Operation__c = operation;
                toUpsert.add(queue);
            } else {
                Product_Sync_Queue__c newRecord = new Product_Sync_Queue__c (
                    Product__c = product.Id,
                    Operation__c = operation,
                    Status__c = Utils.PRODUCT_SYNC.STATUS.PENDING
                );
                toUpsert.add(newRecord);
            }
        }
        upsert toUpsert;

        Integer howManyQueuedJobs = [SELECT COUNT() FROM AsyncApexJob WHERE Status IN :Utils.PRODUCT_SYNC.JOB_STATUS.ACTIVE AND ApexClass.Name = 'ProductSyncQueueable'];

        if (howManyQueuedJobs == 0) {
                System.enqueueJob(new ProductSyncQueueable());
            }
        }
    }       
}