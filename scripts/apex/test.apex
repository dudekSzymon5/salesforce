Date today = Date.today();
System.debug('Today: ' + today);

Discount__c hej = [SELECT Id, Name, Type__c, Start_Date__c, End_Date__c FROM Discount__c WHERE Name = 'Hej' LIMIT 1];
System.debug('Start: ' + hej.Start_Date__c);
System.debug('End: ' + hej.End_Date__c);
System.debug('Today >= Start: ' + (today >= hej.Start_Date__c));
System.debug('Today <= End: ' + (today <= hej.End_Date__c));