@IsTest
private class RaceTireDataImportServiceTest {

    private static String buildJson(List<Map<String, Object>> rows) {
        List<String> parts = new List<String>();
        Integer rowNum = 1;
        for (Map<String, Object> row : rows) {
            row.put('rowNumber', rowNum++);
            List<String> fields = new List<String>();
            for (String key : row.keySet()) {
                Object val = row.get(key);
                if (val instanceof Integer) {
                    fields.add('"' + key + '":' + val);
                } else {
                    fields.add('"' + key + '":"' + String.valueOf(val) + '"');
                }
            }
            parts.add('{' + String.join(fields, ',') + '}');
        }
        return '[' + String.join(parts, ',') + ']';
    }

    @IsTest
    static void testImportValidRow() {
        String json = buildJson(new List<Map<String, Object>>{
            TestDataFactory.raceTireRow().build()
        });

        Test.startTest();
        List<RaceTireDataImportService.ImportResult> results = RaceTireDataImportService.importRecords(json);
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals('success', results[0].status);
        System.assertNotEquals(null, results[0].recordId);
    }

    @IsTest
    static void testImportMultipleValidRows() {
        String json = buildJson(new List<Map<String, Object>>{
            TestDataFactory.raceTireRow().build(),
            TestDataFactory.raceTireRow().withDriver('Max Verstappen').withCompound('Soft').withLaps('16').withWear('81.4').build()
        });

        Test.startTest();
        List<RaceTireDataImportService.ImportResult> results = RaceTireDataImportService.importRecords(json);
        Test.stopTest();

        System.assertEquals(2, results.size());
        for (RaceTireDataImportService.ImportResult result : results) {
            System.assertEquals('success', result.status);
        }
    }

    @IsTest
    static void testMissingTrackName() {
        String json = buildJson(new List<Map<String, Object>>{
            TestDataFactory.raceTireRow().withTrackName('').build()
        });

        Test.startTest();
        List<RaceTireDataImportService.ImportResult> results = RaceTireDataImportService.importRecords(json);
        Test.stopTest();

        System.assertEquals('error', results[0].status);
        System.assertEquals(System.Label.RaceTireImport_ErrTrackNameRequired, results[0].errorMessage);
    }

    @IsTest
    static void testMissingRaceName() {
        String json = buildJson(new List<Map<String, Object>>{
            TestDataFactory.raceTireRow().withRaceName('').build()
        });

        Test.startTest();
        List<RaceTireDataImportService.ImportResult> results = RaceTireDataImportService.importRecords(json);
        Test.stopTest();

        System.assertEquals('error', results[0].status);
        System.assertEquals(System.Label.RaceTireImport_ErrRaceNameRequired, results[0].errorMessage);
    }

    @IsTest
    static void testMissingDriver() {
        String json = buildJson(new List<Map<String, Object>>{
            TestDataFactory.raceTireRow().withDriver('').build()
        });

        Test.startTest();
        List<RaceTireDataImportService.ImportResult> results = RaceTireDataImportService.importRecords(json);
        Test.stopTest();

        System.assertEquals('error', results[0].status);
        System.assertEquals(System.Label.RaceTireImport_ErrDriverRequired, results[0].errorMessage);
    }

    @IsTest
    static void testMissingTireCompound() {
        String json = buildJson(new List<Map<String, Object>>{
            TestDataFactory.raceTireRow().withCompound('').build()
        });

        Test.startTest();
        List<RaceTireDataImportService.ImportResult> results = RaceTireDataImportService.importRecords(json);
        Test.stopTest();

        System.assertEquals('error', results[0].status);
        System.assertEquals(System.Label.RaceTireImport_ErrCompoundRequired, results[0].errorMessage);
    }

    @IsTest
    static void testInvalidTireCompound() {
        String json = buildJson(new List<Map<String, Object>>{
            TestDataFactory.raceTireRow().withCompound('Intermediate').build()
        });

        Test.startTest();
        List<RaceTireDataImportService.ImportResult> results = RaceTireDataImportService.importRecords(json);
        Test.stopTest();

        System.assertEquals('error', results[0].status);
        System.assertEquals(System.Label.RaceTireImport_ErrCompoundInvalid, results[0].errorMessage);
    }

    @IsTest
    static void testMissingLaps() {
        String json = buildJson(new List<Map<String, Object>>{
            TestDataFactory.raceTireRow().withLaps('').build()
        });

        Test.startTest();
        List<RaceTireDataImportService.ImportResult> results = RaceTireDataImportService.importRecords(json);
        Test.stopTest();

        System.assertEquals('error', results[0].status);
        System.assertEquals(System.Label.RaceTireImport_ErrLapsRequired, results[0].errorMessage);
    }

    @IsTest
    static void testLapsNotNumber() {
        String json = buildJson(new List<Map<String, Object>>{
            TestDataFactory.raceTireRow().withLaps('abc').build()
        });

        Test.startTest();
        List<RaceTireDataImportService.ImportResult> results = RaceTireDataImportService.importRecords(json);
        Test.stopTest();

        System.assertEquals('error', results[0].status);
        System.assertEquals(System.Label.RaceTireImport_ErrLapsNotNumber, results[0].errorMessage);
    }

    @IsTest
    static void testLapsZero() {
        String json = buildJson(new List<Map<String, Object>>{
            TestDataFactory.raceTireRow().withLaps('0').build()
        });

        Test.startTest();
        List<RaceTireDataImportService.ImportResult> results = RaceTireDataImportService.importRecords(json);
        Test.stopTest();

        System.assertEquals('error', results[0].status);
        System.assertEquals(System.Label.RaceTireImport_ErrLapsInvalid, results[0].errorMessage);
    }

    @IsTest
    static void testMissingWearPercent() {
        String json = buildJson(new List<Map<String, Object>>{
            TestDataFactory.raceTireRow().withWear('').build()
        });

        Test.startTest();
        List<RaceTireDataImportService.ImportResult> results = RaceTireDataImportService.importRecords(json);
        Test.stopTest();

        System.assertEquals('error', results[0].status);
        System.assertEquals(System.Label.RaceTireImport_ErrWearRequired, results[0].errorMessage);
    }

    @IsTest
    static void testWearPercentNotNumber() {
        String json = buildJson(new List<Map<String, Object>>{
            TestDataFactory.raceTireRow().withWear('xyz').build()
        });

        Test.startTest();
        List<RaceTireDataImportService.ImportResult> results = RaceTireDataImportService.importRecords(json);
        Test.stopTest();

        System.assertEquals('error', results[0].status);
        System.assertEquals(System.Label.RaceTireImport_ErrWearInvalid, results[0].errorMessage);
    }

    @IsTest
    static void testWearPercentAbove100() {
        String json = buildJson(new List<Map<String, Object>>{
            TestDataFactory.raceTireRow().withWear('112.3').build()
        });

        Test.startTest();
        List<RaceTireDataImportService.ImportResult> results = RaceTireDataImportService.importRecords(json);
        Test.stopTest();

        System.assertEquals('error', results[0].status);
        System.assertEquals(System.Label.RaceTireImport_ErrWearRange, results[0].errorMessage);
    }

    @IsTest
    static void testWearPercentNegative() {
        String json = buildJson(new List<Map<String, Object>>{
            TestDataFactory.raceTireRow().withWear('-5').build()
        });

        Test.startTest();
        List<RaceTireDataImportService.ImportResult> results = RaceTireDataImportService.importRecords(json);
        Test.stopTest();

        System.assertEquals('error', results[0].status);
        System.assertEquals(System.Label.RaceTireImport_ErrWearRange, results[0].errorMessage);
    }

    @IsTest
    static void testPartialSuccess() {
        String json = buildJson(new List<Map<String, Object>>{
            TestDataFactory.raceTireRow().build(),
            TestDataFactory.raceTireRow().withDriver('').build()
        });

        Test.startTest();
        List<RaceTireDataImportService.ImportResult> results = RaceTireDataImportService.importRecords(json);
        Test.stopTest();

        System.assertEquals(2, results.size());
        System.assertEquals('success', results[0].status);
        System.assertEquals('error', results[1].status);
    }

    @IsTest
    static void testAllCompounds() {
        String json = buildJson(new List<Map<String, Object>>{
            TestDataFactory.raceTireRow().withCompound('Soft').withDriver('Driver Soft').build(),
            TestDataFactory.raceTireRow().withCompound('Medium').withDriver('Driver Medium').build(),
            TestDataFactory.raceTireRow().withCompound('Hard').withDriver('Driver Hard').build()
        });

        Test.startTest();
        List<RaceTireDataImportService.ImportResult> results = RaceTireDataImportService.importRecords(json);
        Test.stopTest();

        for (RaceTireDataImportService.ImportResult result : results) {
            System.assertEquals('success', result.status);
        }
    }
}
