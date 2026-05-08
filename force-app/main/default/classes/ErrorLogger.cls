public class ErrorLogger {

    public enum Severity { ERROR, WARNING, INFO }

    public static void log(Error_Log__c errorLog) {
        Error_Log_Event__e event = new Error_Log_Event__e(
            Payload__c = JSON.serialize(errorLog)
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
        log(new Error_Log__c(
            Apex_Class__c    = apexClass,
            Error_Message__c = e.getMessage() + '\n' + e.getStackTraceString(),
            Severity__c      = Severity.ERROR.name(),
            User__c          = UserInfo.getUserId()
        ));
    }

    public static void log(String apexClass, Exception e, String recordId) {
        log(new Error_Log__c(
            Apex_Class__c    = apexClass,
            Error_Message__c = e.getMessage() + '\n' + e.getStackTraceString(),
            Severity__c      = Severity.ERROR.name(),
            Record_Id__c     = recordId,
            User__c          = UserInfo.getUserId()
        ));
    }

    public static void logWarning(String apexClass, String message, String context) {
        log(new Error_Log__c(
            Apex_Class__c         = apexClass,
            Error_Message__c      = message,
            Severity__c           = Severity.WARNING.name(),
            Additional_Context__c = context,
            User__c               = UserInfo.getUserId()
        ));
    }

    public static void logInfo(String apexClass, String message) {
        log(new Error_Log__c(
            Apex_Class__c    = apexClass,
            Error_Message__c = message,
            Severity__c      = Severity.INFO.name(),
            User__c          = UserInfo.getUserId()
        ));
    }
}
