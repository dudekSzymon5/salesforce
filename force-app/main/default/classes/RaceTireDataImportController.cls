public with sharing class RaceTireDataImportController {

    @AuraEnabled
    public static List<RaceTireDataImportService.ImportResult> importRecords(String rowsJson) {
        try {
            return RaceTireDataImportService.importRecords(rowsJson);
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}
