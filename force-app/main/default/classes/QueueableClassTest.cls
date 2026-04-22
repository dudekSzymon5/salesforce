@IsTest
private class QueueableClassTest {
    @IsTest
    static void testExecute() {
        Test.startTest();
        System.enqueueJob(new QueueableClass());
        Test.stopTest();
    }
}