// classes/ErrorLogger.cls
public class ErrorLogger {
    
    public enum Severity { ERROR, WARNING, INFO }
    
    public static void log(
        String apexClass,
        String errorMessage,
        Severity severity,
        String recordId,
        String additionalContext
    ) {
        Error_Log_Event__e event = new Error_Log_Event__e(
            Apex_Class__c         = apexClass,
            Error_Message__c      = errorMessage,
            Severity__c           = severity.name(),
            Record_Id__c          = recordId,
            User_Id__c            = UserInfo.getUserId(),
            Additional_Context__c = additionalContext
        );
        
        Database.SaveResult result = EventBus.publish(event);
        
        if (!result.isSuccess()) {
            for (Database.Error err : result.getErrors()) {
                System.debug(LoggingLevel.ERROR, 
                    'ErrorLogger publish failed: ' + err.getMessage());
            }
        }
    }
    
    public static void log(String apexClass, Exception e) {
        log(apexClass, e.getMessage() + '\n' + e.getStackTraceString(),
            Severity.ERROR, null, null);
    }
    
    public static void log(String apexClass, Exception e, String recordId) {
        log(apexClass, e.getMessage() + '\n' + e.getStackTraceString(),
            Severity.ERROR, recordId, null);
    }
    
    public static void logWarning(String apexClass, String message, String context) {
        log(apexClass, message, Severity.WARNING, null, context);
    }
    
    public static void logInfo(String apexClass, String message) {
        log(apexClass, message, Severity.INFO, null, null);
    }
}