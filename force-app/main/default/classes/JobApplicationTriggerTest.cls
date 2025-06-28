/**
 * @description Test class for Job Application trigger and related services
 * @author Temitayo Oluwalade
 * @date 2024
 */
@isTest
public class JobApplicationTriggerTest {
    
    /**
     * @description Test data setup method
     */
    @TestSetup
    static void setupTestData() {
        // Create test account
        Account testAccount = new Account(
            Name = 'Test Company Inc'
        );
        insert testAccount;
        
        // Create test contact
        Contact testContact = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'john.doe@testcompany.com',
            AccountId = testAccount.Id
        );
        insert testContact;
    }
    
    /**
     * @description Test task creation on job application insert
     */
    @isTest
    static void testTaskCreationOnInsert() {
        // Test data
        Job_Application__c jobApp = new Job_Application__c(
            Company_Name__c = 'Test Company Inc',
            Position_Title__c = 'Software Developer',
            Status__c = 'Saved',
            Salary__c = 75000
        );
        
        Test.startTest();
        insert jobApp;
        Test.stopTest();
        
        // Verify tasks were created
        List<Task> createdTasks = [
            SELECT Id, Subject, WhatId, Priority, Status
            FROM Task
            WHERE WhatId = :jobApp.Id
        ];
        
        System.assert(!createdTasks.isEmpty(), 'Tasks should be created for new job application');
        System.assertEquals(3, createdTasks.size(), 'Should create 3 tasks for Saved status');
        
        // Verify task details
        Boolean foundAlignmentTask = false;
        for (Task t : createdTasks) {
            if (t.Subject.contains('job description aligns')) {
                foundAlignmentTask = true;
                System.assertEquals('High', t.Priority, 'Alignment task should have High priority');
            }
        }
        System.assert(foundAlignmentTask, 'Should create alignment check task');
    }
    
    /**
     * @description Test task creation on status change
     */
    @isTest
    static void testTaskCreationOnStatusChange() {
        // Create job application
        Job_Application__c jobApp = new Job_Application__c(
            Company_Name__c = 'Test Company Inc',
            Position_Title__c = 'Software Developer',
            Status__c = 'Saved',
            Salary__c = 75000
        );
        insert jobApp;
        
        // Delete initial tasks to test status change
        delete [SELECT Id FROM Task WHERE WhatId = :jobApp.Id];
        
        Test.startTest();
        // Change status to Applying
        jobApp.Status__c = 'Applying';
        update jobApp;
        Test.stopTest();
        
        // Verify new tasks were created
        List<Task> createdTasks = [
            SELECT Id, Subject, WhatId, Priority
            FROM Task
            WHERE WhatId = :jobApp.Id
        ];
        
        System.assert(!createdTasks.isEmpty(), 'Tasks should be created for status change');
        System.assertEquals(5, createdTasks.size(), 'Should create 5 tasks for Applying status');
        
        // Verify specific task exists
        Boolean foundResearchTask = false;
        for (Task t : createdTasks) {
            if (t.Subject.contains('Find and research someone')) {
                foundResearchTask = true;
            }
        }
        System.assert(foundResearchTask, 'Should create research task for Applying status');
    }
    
    /**
     * @description Test salary calculation on insert
     */
    @isTest
    static void testSalaryCalculationOnInsert() {
        Job_Application__c jobApp = new Job_Application__c(
            Company_Name__c = 'Test Company Inc',
            Position_Title__c = 'Software Developer',
            Status__c = 'Saved',
            Salary__c = 100000
        );
        
        Test.startTest();
        insert jobApp;
        Test.stopTest();
        
        // Retrieve updated record
        Job_Application__c updatedJobApp = [
            SELECT Id, Salary__c, Federal_Tax__c, Social_Security_Tax__c, 
                   Medicare_Tax__c, Take_Home_Pay_Yearly__c, Take_Home_Pay_Monthly__c
            FROM Job_Application__c
            WHERE Id = :jobApp.Id
        ];
        
        // Verify calculations were performed
        System.assertNotEquals(null, updatedJobApp.Federal_Tax__c, 'Federal tax should be calculated');
        System.assertNotEquals(null, updatedJobApp.Social_Security_Tax__c, 'Social Security tax should be calculated');
        System.assertNotEquals(null, updatedJobApp.Medicare_Tax__c, 'Medicare tax should be calculated');
        System.assertNotEquals(null, updatedJobApp.Take_Home_Pay_Yearly__c, 'Yearly take-home pay should be calculated');
        System.assertNotEquals(null, updatedJobApp.Take_Home_Pay_Monthly__c, 'Monthly take-home pay should be calculated');
        
        // Verify take-home pay is less than gross salary
        System.assert(updatedJobApp.Take_Home_Pay_Yearly__c < updatedJobApp.Salary__c, 
                     'Take-home pay should be less than gross salary');
    }
    
    /**
     * @description Test salary calculation on update
     */
    @isTest
    static void testSalaryCalculationOnUpdate() {
        Job_Application__c jobApp = new Job_Application__c(
            Company_Name__c = 'Test Company Inc',
            Position_Title__c = 'Software Developer',
            Status__c = 'Saved',
            Salary__c = 75000
        );
        insert jobApp;
        
        Test.startTest();
        // Update salary
        jobApp.Salary__c = 85000;
        update jobApp;
        Test.stopTest();
        
        // Retrieve updated record
        Job_Application__c updatedJobApp = [
            SELECT Id, Salary__c, Take_Home_Pay_Yearly__c
            FROM Job_Application__c
            WHERE Id = :jobApp.Id
        ];
        
        // Verify calculations were updated
        System.assertNotEquals(null, updatedJobApp.Take_Home_Pay_Yearly__c, 
                              'Take-home pay should be recalculated');
    }
    
    /**
     * @description Test bulk processing
     */
    @isTest
    static void testBulkProcessing() {
        List<Job_Application__c> jobApps = new List<Job_Application__c>();
        
        for (Integer i = 0; i < 200; i++) {
            jobApps.add(new Job_Application__c(
                Company_Name__c = 'Test Company ' + i,
                Position_Title__c = 'Developer ' + i,
                Status__c = 'Saved',
                Salary__c = 75000 + (i * 1000)
            ));
        }
        
        Test.startTest();
        insert jobApps;
        Test.stopTest();
        
        // Verify all records were processed
        List<Task> allTasks = [SELECT Id FROM Task WHERE WhatId IN :jobApps];
        System.assertEquals(600, allTasks.size(), 'Should create 3 tasks per job application (200 * 3)');
        
        // Verify salary calculations
        List<Job_Application__c> updatedJobApps = [
            SELECT Id, Take_Home_Pay_Yearly__c
            FROM Job_Application__c
            WHERE Id IN :jobApps
            AND Take_Home_Pay_Yearly__c != null
        ];
        System.assertEquals(200, updatedJobApps.size(), 'All job applications should have calculated take-home pay');
    }

    /**
     * @description Test the new LWC-specific salary breakdown method
     */
    @isTest
    static void testSalaryBreakdownForLWC() {
        Test.startTest();

        // Test with valid salary
        Map<String, Decimal> result = SalaryCalculationService.calculateSalaryBreakdown(100000);

        Test.stopTest();

        // Verify all expected keys are present
        System.assert(result.containsKey('federalTax'), 'Should contain federal tax');
        System.assert(result.containsKey('socialSecurityTax'), 'Should contain social security tax');
        System.assert(result.containsKey('medicareTax'), 'Should contain medicare tax');
        System.assert(result.containsKey('totalTax'), 'Should contain total tax');
        System.assert(result.containsKey('takeHomeYearly'), 'Should contain yearly take-home');
        System.assert(result.containsKey('takeHomeMonthly'), 'Should contain monthly take-home');
        System.assert(result.containsKey('takeHomeBiWeekly'), 'Should contain bi-weekly take-home');
        System.assert(result.containsKey('takeHomeWeekly'), 'Should contain weekly take-home');

        // Verify calculations are reasonable
        System.assert(result.get('federalTax') > 0, 'Federal tax should be calculated');
        System.assert(result.get('socialSecurityTax') > 0, 'Social Security tax should be calculated');
        System.assert(result.get('medicareTax') > 0, 'Medicare tax should be calculated');
        System.assert(result.get('takeHomeYearly') < 100000, 'Take-home should be less than gross');
        // Check monthly calculation with proper decimal precision
        Decimal expectedMonthly = (result.get('takeHomeYearly') / 12).setScale(2);
        Decimal actualMonthly = result.get('takeHomeMonthly');
        System.assertEquals(expectedMonthly, actualMonthly, 'Monthly should be yearly/12 with proper rounding');

        // Test with zero salary
        Map<String, Decimal> zeroResult = SalaryCalculationService.calculateSalaryBreakdown(0);
        System.assertEquals(0, zeroResult.get('takeHomeYearly'), 'Zero salary should result in zero take-home');

        // Test with null salary
        Map<String, Decimal> nullResult = SalaryCalculationService.calculateSalaryBreakdown(null);
        System.assertEquals(0, nullResult.get('takeHomeYearly'), 'Null salary should result in zero take-home');
    }
}
