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
    }

    @IsTest
    static void testStaleJobAppIsClosed() {
        Job_Application__c staleApp = new Job_Application__c(
            Status__c = 'Applied',
            Follow_up_Date__c = Date.today().addDays(-45),
            Notes__c = 'Waiting',
            Company_Name__c = 'Fake Company',
            Position_Title__c = 'Senior Engineer'
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
        Job_Application__c freshApp = new Job_Application__c(
            Status__c = 'Applied',
            Follow_up_Date__c = Date.today().addDays(-5),
            Notes__c = 'Still valid',
            Company_Name__c = 'Faker Company',
            Position_Title__c = 'Junior Engineer'
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
        Job_Application__c closedApp = new Job_Application__c(
            Status__c = 'Closed',
            Follow_up_Date__c = Date.today().addDays(-60),
            Notes__c = 'Already closed',
            Company_Name__c = 'Fakest Company',
            Position_Title__c = 'QA Engineer'
        );
        insert closedApp;

        Test.startTest();
        System.enqueueJob(new CloseStaleJobApplicationsQueueable());
        Test.stopTest();

        Job_Application__c result = [SELECT Status__c FROM Job_Application__c WHERE Id = :closedApp.Id];
        System.assertEquals('Closed', result.Status__c, 'Should remain unchanged'); // Should remain unchanged
    }
}


