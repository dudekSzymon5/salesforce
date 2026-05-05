@isTest
public class ErrorLoggerTest {
    
    @isTest
    static void testLogException() {
        Test.startTest();
        
        try {
            Integer x = Integer.valueOf('not_a_number');
        } catch (Exception e) {
            ErrorLogger.log('ErrorLoggerTest', e, 'fakeRecordId123');
        }
        
        Test.stopTest();
        
        List<Error_Log__c> logs = [
            SELECT Id, Severity__c, Apex_Class__c 
            FROM Error_Log__c
        ];
        
        Assert.areEqual(1, logs.size(), 'Powinien być 1 log');
        Assert.areEqual('ERROR', logs[0].Severity__c);
        Assert.areEqual('ErrorLoggerTest', logs[0].Apex_Class__c);
    }
    
    @isTest
    static void testLogWarning() {
        Test.startTest();
        ErrorLogger.logWarning('TestClass', 'Test warning', '{"key":"value"}');
        Test.stopTest();
        
        List<Error_Log__c> logs = [SELECT Severity__c FROM Error_Log__c];
        Assert.areEqual(1, logs.size(), 'Powinien być 1 log');
        Assert.areEqual('WARNING', logs[0].Severity__c);
    }
}