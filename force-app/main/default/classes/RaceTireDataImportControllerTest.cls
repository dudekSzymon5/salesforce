@IsTest
private class RaceTireDataImportControllerTest {

    @IsTest
    static void testImportRecords() {
        String rowsJson = '[{"rowNumber":1,"trackName":"Silverstone","raceCountry":"United Kingdom","raceName":"British GP","driver":"Lewis Hamilton","team":"Ferrari","tireCompound":"Hard","laps":"38","wearPercent":"46.3"}]';

        Test.startTest();
        List<RaceTireDataImportService.ImportResult> results = RaceTireDataImportController.importRecords(rowsJson);
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals('success', results[0].status);
    }

    @IsTest
    static void testImportRecordsThrowsOnInvalidJson() {
        Test.startTest();
        try {
            RaceTireDataImportController.importRecords('not valid json');
            System.assert(false, 'Expected exception');
        } catch (AuraHandledException e) {
            System.assertNotEquals(null, e.getMessage());
        }
        Test.stopTest();
    }
}
