@IsTest
private class ProductSyncRetrySchedulerTest {

    @IsTest
    static void testSchedulerEnqueuesRetryJob() {
        Test.startTest();
        System.schedule('Daily Product Sync Retry ' + DateTime.now().getTime(), '0 0 2 * * ?', new ProductSyncRetryScheduler());
        Test.stopTest();

        List<AsyncApexJob> queuedJobs = [
            SELECT Id, ApexClass.Name
            FROM AsyncApexJob
            WHERE JobType = 'Queueable'
            AND ApexClass.Name = 'ProductSyncRetryQueueable'
            AND CreatedDate = TODAY
        ];
        Assert.areEqual(1, queuedJobs.size(), 'Scheduler should enqueue exactly one ProductSyncRetryQueueable job');
    }

    @IsTest
    static void testSchedulerExecuteDirectlyWithQueuedRecords() {
        TriggerBase.bypass('Product2');
        Product2 product = TestDataFactory.product().create();
        TriggerBase.clearBypass('Product2');
        TestDataFactory.queueRecord().forProduct(product.Id).create();

        Test.startTest();
        new ProductSyncRetryScheduler().execute(null);
        Test.stopTest();

        List<AsyncApexJob> queuedJobs = [
            SELECT Id, ApexClass.Name
            FROM AsyncApexJob
            WHERE JobType = 'Queueable'
            AND ApexClass.Name = 'ProductSyncRetryQueueable'
            AND CreatedDate = TODAY
        ];
        Assert.areEqual(1, queuedJobs.size(), 'Scheduler should enqueue retry job when queue has records');
    }
}