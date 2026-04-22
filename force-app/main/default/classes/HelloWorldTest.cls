@IsTest
private class HelloWorldTest {
    @IsTest
    static void testHelloWorld() {
        HelloWorld hw = new HelloWorld();
        Assert.isNotNull(hw);
    }
}