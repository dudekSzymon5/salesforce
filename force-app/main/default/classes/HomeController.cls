public with sharing class HomeController {

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getDashboardStats() {
        Map<String, Object> stats = new Map<String, Object>();

        // LEADS
        Integer totalLeads     = [SELECT COUNT() FROM Lead];
        Integer convertedLeads = [SELECT COUNT() FROM Lead WHERE IsConverted = true];
        Integer newLeadsMonth  = [SELECT COUNT() FROM Lead WHERE CreatedDate = THIS_MONTH];
        Decimal convRate = totalLeads > 0
            ? ((Decimal.valueOf(convertedLeads) / totalLeads) * 100).setScale(1)
            : 0;

        // ACCOUNTS
        Integer totalAccounts   = [SELECT COUNT() FROM Account];
        Integer newAcctsQuarter = [SELECT COUNT() FROM Account WHERE CreatedDate = THIS_QUARTER];

        // OPPORTUNITIES
        Integer totalOpps = [SELECT COUNT() FROM Opportunity];
        Integer openOpps  = [SELECT COUNT() FROM Opportunity WHERE IsClosed = false];
        Integer wonOpps   = [SELECT COUNT() FROM Opportunity WHERE IsWon = true];
        AggregateResult pipelineAgg = [
            SELECT SUM(Amount) total FROM Opportunity
            WHERE IsClosed = false AND IsWon = false
        ];
        Decimal pipelineValue = pipelineAgg.get('total') != null
            ? (Decimal) pipelineAgg.get('total') : 0;

        // CONTACTS
        Integer totalContacts = [SELECT COUNT() FROM Contact];

        // ORDERS
        Integer totalOrders  = [SELECT COUNT() FROM Order];
        Integer activeOrders = [SELECT COUNT() FROM Order WHERE Status = 'Activated'];

        // CASES
        Integer openCases = [SELECT COUNT() FROM Case WHERE IsClosed = false];

        // COMPLAINTS
        Integer totalComplaints = 0;
        Integer openComplaints  = 0;
        try {
            totalComplaints = Database.countQuery('SELECT COUNT() FROM Complaint__c');
            openComplaints  = Database.countQuery(
                'SELECT COUNT() FROM Complaint__c WHERE Status__c != \'Closed\''
            );
        } catch (Exception e) { /* safe fallback */ }

        stats.put('totalLeads',        totalLeads);
        stats.put('convertedLeads',    convertedLeads);
        stats.put('newLeadsMonth',     newLeadsMonth);
        stats.put('conversionRate',    convRate);
        stats.put('totalAccounts',     totalAccounts);
        stats.put('newAccountsQuarter',newAcctsQuarter);
        stats.put('totalOpps',         totalOpps);
        stats.put('openOpps',          openOpps);
        stats.put('wonOpps',           wonOpps);
        stats.put('pipelineValue',     pipelineValue);
        stats.put('totalContacts',     totalContacts);
        stats.put('totalOrders',       totalOrders);
        stats.put('activeOrders',      activeOrders);
        stats.put('openCases',         openCases);
        stats.put('totalComplaints',   totalComplaints);
        stats.put('openComplaints',    openComplaints);

        return stats;
    }
}