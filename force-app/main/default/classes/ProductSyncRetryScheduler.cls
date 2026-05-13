public class ProductSyncRetryScheduler implements Schedulable {

    public void execute(SchedulableContext ctx) {
        System.enqueueJob(new ProductSyncRetryQueueable());
    }
}