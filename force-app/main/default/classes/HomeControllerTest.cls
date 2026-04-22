@IsTest
private class HomeControllerTest {
    
    @TestSetup
    static void setupData() {
        Lead lead = new Lead(FirstName='Test', LastName='Lead', Company='TestCo', IsConverted=false);
        insert lead;
        
        Account acc = new Account(Name='Test Account');
        insert acc;
        
        Contact con = new Contact(FirstName='Test', LastName='Contact', AccountId=acc.Id);
        insert con;
        
        Opportunity opp = new Opportunity(
            Name='Test Opp', AccountId=acc.Id,
            StageName='Prospecting', CloseDate=Date.today().addDays(30)
        );
        insert opp;
    }
    
    @IsTest
    static void testGetDashboardStats() {
        Test.startTest();
        Map<String, Object> stats = HomeController.getDashboardStats();
        Test.stopTest();
        
        Assert.isNotNull(stats);
        Assert.isTrue(stats.containsKey('totalLeads'));
        Assert.isTrue(stats.containsKey('totalAccounts'));
        Assert.isTrue(stats.containsKey('totalOpps'));
        Assert.isTrue(stats.containsKey('totalContacts'));
        Assert.isTrue(stats.containsKey('totalOrders'));
        Assert.isTrue(stats.containsKey('openCases'));
        Assert.isTrue(stats.containsKey('totalComplaints'));
    }
}