trigger ErrorLogEventTrigger on Error_Log_Event__e (after insert) {
    
    List<Error_Log__c> logsToInsert = new List<Error_Log__c>();
    
    for (Error_Log_Event__e event : Trigger.new) {
        Error_Log__c log = new Error_Log__c(
            Error_Message__c   = event.Error_Message__c,
            Apex_Class__c      = event.Apex_Class__c,
            Severity__c        = event.Severity__c,
            Record_Id__c       = event.Record_Id__c,
            Additional_Context__c = event.Additional_Context__c,
            Occurred_At__c     = System.now()
        );
        
        if (String.isNotBlank(event.User_Id__c)) {
            log.User__c = event.User_Id__c;
        }
        
        logsToInsert.add(log);
    }
    
    if (!logsToInsert.isEmpty()) {
        Database.SaveResult[] results = Database.insert(logsToInsert, false);
        for (Database.SaveResult sr : results) {
            if (!sr.isSuccess()) {
                for (Database.Error err : sr.getErrors()) {
                    System.debug(LoggingLevel.ERROR,
                        'ErrorLogEventTrigger insert failed: ' + err.getMessage());
                }
            }
        }
    }
}