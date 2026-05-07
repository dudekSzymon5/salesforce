trigger ErrorLogEventTrigger on Error_Log_Event__e (after insert) {

    List<Error_Log__c> logsToInsert = new List<Error_Log__c>();

    for (Error_Log_Event__e event : Trigger.new) {
        Error_Log__c log = (Error_Log__c) JSON.deserialize(event.Payload__c, Error_Log__c.class);
        log.Occurred_At__c = System.now();
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
