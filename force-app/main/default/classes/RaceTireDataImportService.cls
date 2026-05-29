public with sharing class RaceTireDataImportService {

    public class RowData {
        public Integer rowNumber;
        public String trackName;
        public String raceCountry;
        public String raceName;
        public String driver;
        public String team;
        public String tireCompound;
        public String laps;
        public String wearPercent;
    }

    public class ImportResult {
        @AuraEnabled public Integer rowNumber;
        @AuraEnabled public String status;
        @AuraEnabled public String errorMessage;
        @AuraEnabled public String trackName;
        @AuraEnabled public String raceName;
        @AuraEnabled public String driver;
        @AuraEnabled public String team;
        @AuraEnabled public Id recordId;
    }

    private static final Set<String> VALID_COMPOUNDS = new Set<String>{ 'Soft', 'Medium', 'Hard' };

    public static List<ImportResult> importRecords(String rowsJson) {
        List<RowData> rows = (List<RowData>) JSON.deserialize(rowsJson, List<RowData>.class);

        List<ImportResult> results = new List<ImportResult>();
        List<Race_Tire_Data__c> toInsert = new List<Race_Tire_Data__c>();
        List<Integer> resultIndices = new List<Integer>();

        for (RowData row : rows) {
            ImportResult result = buildResult(row);
            String error = validate(row);

            if (error != null) {
                result.status = 'error';
                result.errorMessage = error;
            } else {
                resultIndices.add(results.size());
                toInsert.add(toRecord(row));
            }
            results.add(result);
        }

        applyDatabaseResults(toInsert, resultIndices, results);

        return results;
    }

    private static ImportResult buildResult(RowData row) {
        ImportResult result = new ImportResult();
        result.rowNumber = row.rowNumber;
        result.trackName = row.trackName;
        result.raceName = row.raceName;
        result.driver = row.driver;
        result.team = row.team;
        return result;
    }

    private static Race_Tire_Data__c toRecord(RowData row) {
        return new Race_Tire_Data__c(
            Name = row.driver + ' - ' + row.raceName,
            Track_Name__c = row.trackName,
            Race_Country__c = row.raceCountry,
            Race_Name__c = row.raceName,
            Driver__c = row.driver,
            Team__c = row.team,
            Tire_Compound__c = row.tireCompound,
            Laps__c = Integer.valueOf(row.laps),
            Wear_Percent__c = Decimal.valueOf(row.wearPercent)
        );
    }

    private static void applyDatabaseResults(
        List<Race_Tire_Data__c> toInsert,
        List<Integer> resultIndices,
        List<ImportResult> results
    ) {
        if (toInsert.isEmpty()) {
            return;
        }

        Database.SaveResult[] saveResults = Database.insert(toInsert, false);
        for (Integer i = 0; i < saveResults.size(); i++) {
            ImportResult result = results[resultIndices[i]];
            if (saveResults[i].isSuccess()) {
                result.status = 'success';
                result.recordId = saveResults[i].getId();
            } else {
                result.status = 'error';
                result.errorMessage = saveResults[i].getErrors()[0].getMessage();
            }
        }
    }

    private static String validate(RowData row) {
        if (String.isBlank(row.trackName)) {
            return System.Label.RaceTireImport_ErrTrackNameRequired;
        }
        if (String.isBlank(row.raceName)) {
            return System.Label.RaceTireImport_ErrRaceNameRequired;
        }
        if (String.isBlank(row.driver)) {
            return System.Label.RaceTireImport_ErrDriverRequired;
        }
        if (String.isBlank(row.tireCompound)) {
            return System.Label.RaceTireImport_ErrCompoundRequired;
        }
        if (!VALID_COMPOUNDS.contains(row.tireCompound)) {
            return System.Label.RaceTireImport_ErrCompoundInvalid;
        }
        if (String.isBlank(row.laps)) {
            return System.Label.RaceTireImport_ErrLapsRequired;
        }
        if (String.isBlank(row.wearPercent)) {
            return System.Label.RaceTireImport_ErrWearRequired;
        }
        try {
            if (Integer.valueOf(row.laps) <= 0) {
                return System.Label.RaceTireImport_ErrLapsInvalid;
            }
        } catch (Exception e) {
            return System.Label.RaceTireImport_ErrLapsNotNumber;
        }
        try {
            Decimal wear = Decimal.valueOf(row.wearPercent);
            if (wear < 0 || wear > 100) {
                return System.Label.RaceTireImport_ErrWearRange;
            }
        } catch (Exception e) {
            return System.Label.RaceTireImport_ErrWearInvalid;
        }
        return null;
    }
}
