@IsTest
private class HouseServiceTest {
    
    @TestSetup
    static void setupData() {
        House__c house = new House__c(
            Name='Test House',
            Address__c='123 Test St',
            State__c='CA',
            City__c='San Francisco',
            Zip__c='94105'
        );
        insert house;
    }
    
    @IsTest
    static void testGetRecords() {
        Test.startTest();
        List<House__c> houses = HouseService.getRecords();
        Test.stopTest();
        
        Assert.isNotNull(houses);
    }
}