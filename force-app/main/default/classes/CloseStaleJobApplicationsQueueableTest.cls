@IsTest
private class CloseStaleJobApplicationsQueueableTest {

    @testSetup
    static void setup() {
        // Globally bypass validations for the test context
        ValidationControl__c settings = new ValidationControl__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            Bypass_Validations__c = true
        );
        insert settings;

        List<Account> accList = new List<Account>();
        Account acc = new Account(Name = 'testEmployer');
        accList.add(acc);
       
        TriggerHandler.bypass('AccountTriggerHandler');
        insert accList;      
        TriggerHandler.clearBypass('AccountTriggerHandler');

        acc = [SELECT Id FROM Account LIMIT 1];
        Contact cont = new Contact(LastName = '<unknown_contact>', AccountId = acc.Id);
        insert cont;
    
        Job__c job = new Job__c();
        job.Employer__c = acc.Id;
        job.Primary_Contact__c = cont.Id;
        job.JoobleId__c = '12345';
        insert job;

    }

    @IsTest
    static void testStaleJobAppIsClosed() {
        
        Job__c job = [SELECT Id FROM Job__c LIMIT 1];

        Job_Application__c staleApp = new Job_Application__c(
            Status__c = 'Applied',
            Follow_up_Date__c = Date.today().addDays(-45),
            Notes__c = 'Waiting',
            Company_Name__c = 'Fake Company',
            Position_Title__c = 'Senior Engineer',
            Job__c = job.Id //'a03ak00000UnVW8AAN'
        );
        insert staleApp;

        Test.startTest();
        System.enqueueJob(new CloseStaleJobApplicationsQueueable());
        Test.stopTest();

        Job_Application__c result = [SELECT Status__c, Notes__c FROM Job_Application__c WHERE Id = :staleApp.Id];
        System.assertEquals('Closed', result.Status__c, 'This job app should be closed');
        System.assert(result.Notes__c.contains('Closed automatically'));
    }

    @IsTest
    static void testFreshJobAppIsNotClosed() {
        
        Job__c job = [SELECT Id FROM Job__c LIMIT 1];
        
        Job_Application__c freshApp = new Job_Application__c(
            Status__c = 'Applied',
            Follow_up_Date__c = Date.today().addDays(-5),
            Notes__c = 'Still valid',
            Company_Name__c = 'Faker Company',
            Position_Title__c = 'Junior Engineer',
            Job__c = job.Id //'a03ak00000UnVW8AAN'
        );
        insert freshApp;

        Test.startTest();
        System.enqueueJob(new CloseStaleJobApplicationsQueueable());
        Test.stopTest();

        Job_Application__c result = [SELECT Status__c FROM Job_Application__c WHERE Id = :freshApp.Id];
        System.assertEquals('Applied', result.Status__c, 'This application should not be changed'); // Should NOT be changed
    }

    @IsTest
    static void testClosedJobAppIsNotTouched() {
        
        Job__c job = [SELECT Id FROM Job__c LIMIT 1];
        
        Job_Application__c closedApp = new Job_Application__c(
            Status__c = 'Closed',
            Follow_up_Date__c = Date.today().addDays(-60),
            Notes__c = 'Already closed',
            Company_Name__c = 'Fakest Company',
            Position_Title__c = 'QA Engineer',
            Job__c = job.Id //'a03ak00000UnVW8AAN'
        );
        insert closedApp;

        Test.startTest();
        System.enqueueJob(new CloseStaleJobApplicationsQueueable());
        Test.stopTest();

        Job_Application__c result = [SELECT Status__c FROM Job_Application__c WHERE Id = :closedApp.Id];
        System.assertEquals('Closed', result.Status__c, 'Should remain unchanged'); // Should remain unchanged

    }
}