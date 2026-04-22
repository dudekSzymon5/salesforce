@IsTest
private class FutureClassTest {
    @IsTest
    static void testFutureNothing() {
        Test.startTest();
        FutureClass.FutureNothing();
        Test.stopTest();
    }
}