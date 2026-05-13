@IsTest
private class ProductSyncRetrySchedulerTest {

    @IsTest
    static void testSchedulerEnqueuesRetryJob() {
        Test.startTest();
        System.schedule('TestRetryScheduler', '0 0 0 * * ?', new ProductSyncRetryScheduler());
        Test.stopTest();

        List<AsyncApexJob> queuedJobs = [
            SELECT Id, ApexClass.Name
            FROM AsyncApexJob
            WHERE JobType = 'Queueable'
        ];
        Assert.areEqual(1, queuedJobs.size(), 'Scheduler should enqueue exactly one Queueable job');
    }
}
