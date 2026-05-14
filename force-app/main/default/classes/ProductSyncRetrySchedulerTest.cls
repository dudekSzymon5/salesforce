@IsTest
private class ProductSyncRetrySchedulerTest {

    @IsTest
    static void testSchedulerEnqueuesRetryJob() {
        Test.startTest();
        System.schedule('Daily Product Sync Retry', '0 0 2 * * ?', new ProductSyncRetryScheduler());
        Test.stopTest();

        List<AsyncApexJob> queuedJobs = [
            SELECT Id, ApexClass.Name
            FROM AsyncApexJob
            WHERE JobType = 'Queueable'
            AND ApexClass.Name = 'ProductSyncRetryQueueable'
        ];
        Assert.areEqual(1, queuedJobs.size(), 'Scheduler should enqueue exactly one ProductSyncRetryQueueable job');
    }

    @IsTest
    static void testSchedulerExecuteDirectly_withQueuedRecords() {
        TriggerBase.bypass('ProductTrigger');
        Product2 product = TestDataFactory.aProduct().create();
        TriggerBase.clearBypass('ProductTrigger');
        TestDataFactory.aQueueRecord().forProduct(product.Id).create();

        Test.startTest();
        new ProductSyncRetryScheduler().execute(null);
        Test.stopTest();

        List<AsyncApexJob> queuedJobs = [
            SELECT Id, ApexClass.Name
            FROM AsyncApexJob
            WHERE JobType = 'Queueable'
            AND ApexClass.Name = 'ProductSyncRetryQueueable'
        ];
        Assert.areEqual(1, queuedJobs.size(), 'Scheduler should enqueue retry job when queue has records');
    }
}