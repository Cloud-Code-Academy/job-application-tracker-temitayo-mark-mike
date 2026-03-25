/**
 * @description Comprehensive test class for ContactAssignmentService
 * Demonstrates professional testing patterns: AAA structure, edge cases, bulk testing
 * @author Learning Journey - Task 7.2
 * @date 2025-01-08
 */
@IsTest
public inherited sharing class ContactAssignmentServiceTest {
    
    /**
     * @description Test setup method using TestDataFactory pattern
     */
    @TestSetup
    static void setupTestData() {
        // Create test accounts with contacts
        List<Account> testAccounts = new List<Account>();
        testAccounts.add(TestDataFactory.createAccount('Tech Solutions Inc', false));
        testAccounts.add(TestDataFactory.createAccount('Innovation Corp', false));
        testAccounts.add(TestDataFactory.createAccount('StartupXYZ', false));
        insert testAccounts;
        
        // Create contacts for each account
        List<Contact> testContacts = new List<Contact>();
        testContacts.add(TestDataFactory.createContact(testAccounts[0].Id, 'Alice', 'Johnson', 'alice@techsolutions.com', false));
        testContacts.add(TestDataFactory.createContact(testAccounts[0].Id, 'Bob', 'Smith', 'bob@techsolutions.com', false));
        testContacts.add(TestDataFactory.createContact(testAccounts[1].Id, 'Carol', 'Davis', 'carol@innovation.com', false));
        testContacts.add(TestDataFactory.createContact(testAccounts[2].Id, 'David', 'Wilson', 'david@startupxyz.com', false));
        insert testContacts;
    }
    
    /**
     * @description Test successful contact assignment for single job application
     * Tests the happy path scenario where matching contacts exist
     */
    @IsTest
    static void testSuccessfulContactAssignment() {
        // ARRANGE: Get test data and create job application without primary contact
        Account testAccount = [SELECT Id, Name FROM Account WHERE Name = 'Tech Solutions Inc' LIMIT 1];
        
        Job_Application__c jobApp = TestDataFactory.createJobApplication(
            testAccount.Name,
            'Senior Developer',
            'Applied',
            120000,
            false
        );
        // Explicitly ensure no primary contact is set
        jobApp.Primary_Contact__c = null;
        
        // Insert the job application first so it has an ID
        insert jobApp;
        
        List<Job_Application__c> jobApps = new List<Job_Application__c>{jobApp};
        
        // ACT: Call the service method
        Test.startTest();
        ContactAssignmentService.assignPrimaryContact(jobApps);
        Test.stopTest();
        
        // ASSERT: Verify contact was assigned (check in-memory record)
        System.assertNotEquals(null, jobApp.Primary_Contact__c, 
                              'Primary contact should be assigned when matching company exists');
        
        // Verify the assigned contact belongs to the correct account
        Contact assignedContact = [
            SELECT Id, AccountId, Account.Name, FirstName, LastName
            FROM Contact
            WHERE Id = :jobApp.Primary_Contact__c
        ];
        
        System.assertEquals(testAccount.Id, assignedContact.AccountId, 
                           'Assigned contact should belong to the matching account');
        System.assertEquals(testAccount.Name, assignedContact.Account.Name, 
                           'Contact account name should match job application company');
    }
    
    /**
     * @description Test contact assignment when no matching company exists
     * Tests edge case where no Account matches the company name
     */
    @IsTest
    static void testNoMatchingCompany() {
        // ARRANGE: Create job application with non-existent company
        Job_Application__c jobApp = TestDataFactory.createJobApplication(
            'Non-Existent Company LLC',
            'Software Engineer',
            'Applied',
            95000,
            false
        );
        jobApp.Primary_Contact__c = null;
        
        List<Job_Application__c> jobApps = new List<Job_Application__c>{jobApp};
        
        // ACT: Call the service method
        Test.startTest();
        ContactAssignmentService.assignPrimaryContact(jobApps);
        Test.stopTest();
        
        // ASSERT: Verify no contact was assigned
        System.assertEquals(null, jobApp.Primary_Contact__c, 
                           'Primary contact should remain null when no matching company exists');
    }
    
    /**
     * @description Test contact assignment when job application already has primary contact
     * Tests that existing contacts are not overwritten
     */
    @IsTest
    static void testExistingPrimaryContactNotOverwritten() {
        // ARRANGE: Get existing contact and create job application with it assigned
        Contact existingContact = [SELECT Id FROM Contact WHERE Email = 'alice@techsolutions.com' LIMIT 1];
        
        Job_Application__c jobApp = TestDataFactory.createJobApplication(
            'Tech Solutions Inc',
            'Lead Developer',
            'Applied',
            130000,
            false
        );
        jobApp.Primary_Contact__c = existingContact.Id;
        
        List<Job_Application__c> jobApps = new List<Job_Application__c>{jobApp};
        
        // ACT: Call the service method
        Test.startTest();
        ContactAssignmentService.assignPrimaryContact(jobApps);
        Test.stopTest();
        
        // ASSERT: Verify existing contact was not changed
        System.assertEquals(existingContact.Id, jobApp.Primary_Contact__c, 
                           'Existing primary contact should not be overwritten');
    }
    
    /**
     * @description Test contact assignment with multiple job applications
     * Tests bulk processing scenario
     */
    @IsTest
    static void testMultipleJobApplications() {
        // ARRANGE: Create multiple job applications for different companies
        List<Job_Application__c> jobApps = new List<Job_Application__c>();
        
        jobApps.add(TestDataFactory.createJobApplication('Tech Solutions Inc', 'Developer 1', 'Applied', 100000, false));
        jobApps.add(TestDataFactory.createJobApplication('Innovation Corp', 'Developer 2', 'Applied', 105000, false));
        jobApps.add(TestDataFactory.createJobApplication('StartupXYZ', 'Developer 3', 'Applied', 95000, false));
        jobApps.add(TestDataFactory.createJobApplication('Unknown Company', 'Developer 4', 'Applied', 90000, false));
        
        // Ensure no primary contacts are set
        for (Job_Application__c jobApp : jobApps) {
            jobApp.Primary_Contact__c = null;
        }
        insert jobApps;
        
        // ACT: Call the service method
        Test.startTest();
        ContactAssignmentService.assignPrimaryContact(jobApps);
        update jobApps; // Update the records after service assigns contacts
        Test.stopTest();
        
        // ASSERT: Verify contacts were assigned appropriately
        Integer assignedCount = 0;
        for (Job_Application__c jobApp : jobApps) {
            if (jobApp.Primary_Contact__c != null) {
                assignedCount++;
            }
        }
        
        System.assertEquals(3, assignedCount, 
                           'Should assign contacts for 3 job applications with matching companies');
        
        // Verify the unknown company job application has no contact assigned
        Job_Application__c unknownCompanyApp = null;
        for (Job_Application__c jobApp : jobApps) {
            if (jobApp.Company_Name__c == 'Unknown Company') {
                unknownCompanyApp = jobApp;
                break;
            }
        }
        
        System.assertEquals(null, unknownCompanyApp.Primary_Contact__c, 
                           'Job application with unknown company should have no contact assigned');
    }
    
    /**
     * @description Test contact assignment with null company name
     * Tests edge case handling for null values
     */
    @IsTest
    static void testNullCompanyName() {
        // ARRANGE: Create job application with null company name
        Job_Application__c jobApp = TestDataFactory.createJobApplication(
            null, // null company name
            'Mystery Developer',
            'Applied',
            85000,
            false
        );
        jobApp.Primary_Contact__c = null;
        
        List<Job_Application__c> jobApps = new List<Job_Application__c>{jobApp};
        
        // ACT: Call the service method
        Test.startTest();
        ContactAssignmentService.assignPrimaryContact(jobApps);
        Test.stopTest();
        
        // ASSERT: Verify no contact was assigned and no exceptions thrown
        System.assertEquals(null, jobApp.Primary_Contact__c, 
                           'Primary contact should remain null when company name is null');
    }
    
    /**
     * @description Test contact assignment with empty job applications list
     * Tests edge case with empty input
     */
    @IsTest
    static void testEmptyJobApplicationsList() {
        // ARRANGE: Empty list
        List<Job_Application__c> emptyJobApps = new List<Job_Application__c>();
        
        // ACT: Call the service method
        Test.startTest();
        ContactAssignmentService.assignPrimaryContact(emptyJobApps);
        Test.stopTest();
        
        // ASSERT: Verify no exceptions thrown (method should handle gracefully)
        System.assert(true, 'Method should handle empty list gracefully without exceptions');
    }
    
    /**
     * @description Test contact assignment with null job applications list
     * Tests edge case with null input
     */
    @IsTest
    static void testNullJobApplicationsList() {
        // ARRANGE: Null list
        List<Job_Application__c> nullJobApps = null;
        
        // ACT & ASSERT: Verify method handles null input gracefully
        Test.startTest();
        try {
            ContactAssignmentService.assignPrimaryContact(nullJobApps);
            System.assert(false, 'Method should handle null input without throwing unhandled exceptions');
        } catch (Exception e) {
            // Expected behavior - method should either handle gracefully or throw appropriate exception
            System.assert(e instanceof NullPointerException, 
                         'Should throw appropriate exception for null input: ' + e.getTypeName());
        }
        Test.stopTest();
    }
    
    /**
     * @description Test contact assignment with multiple contacts per company
     * Tests that the first contact is selected when multiple contacts exist
     */
    @IsTest
    static void testMultipleContactsPerCompany() {
        // ARRANGE: Job application for company with multiple contacts (Tech Solutions Inc has Alice and Bob)
        Job_Application__c jobApp = TestDataFactory.createJobApplication(
            'Tech Solutions Inc',
            'Full Stack Developer',
            'Applied',
            115000,
            false
        );
        jobApp.Primary_Contact__c = null;
        insert jobApp;
        
        List<Job_Application__c> jobApps = new List<Job_Application__c>{jobApp};
        
        // ACT: Call the service method
        Test.startTest();
        ContactAssignmentService.assignPrimaryContact(jobApps);
        update jobApps; // Update the records after service assigns contacts
        Test.stopTest();
        
        // ASSERT: Verify a contact was assigned
        System.assertNotEquals(null, jobApp.Primary_Contact__c, 
                              'Primary contact should be assigned when multiple contacts exist');
        
        // Verify the assigned contact belongs to the correct company
        Contact assignedContact = [
            SELECT Id, Account.Name, FirstName, LastName, CreatedDate
            FROM Contact
            WHERE Id = :jobApp.Primary_Contact__c
        ];
        
        System.assertEquals('Tech Solutions Inc', assignedContact.Account.Name, 
                           'Assigned contact should belong to the correct company');
        
        // The service should assign the first contact (ordered by CreatedDate ASC)
        // Since Alice was created first, she should be assigned
        System.assertEquals('Alice', assignedContact.FirstName, 
                           'Should assign the first contact (by creation date) when multiple exist');
    }
    
    /**
     * @description Test bulk contact assignment with large dataset
     * Tests performance and governor limits with 200 job applications
     */
    @IsTest
    static void testBulkContactAssignment() {
        // ARRANGE: Create additional accounts and contacts for bulk testing
        List<Account> bulkAccounts = new List<Account>();
        for (Integer i = 0; i < 10; i++) {
            bulkAccounts.add(TestDataFactory.createAccount('Bulk Company ' + i, false));
        }
        insert bulkAccounts;
        
        List<Contact> bulkContacts = new List<Contact>();
        for (Account acc : bulkAccounts) {
            bulkContacts.add(TestDataFactory.createContact(acc.Id, 'Contact', 'User', null, false));
        }
        insert bulkContacts;
        
        // Create 200 job applications
        List<Job_Application__c> bulkJobApps = new List<Job_Application__c>();
        for (Integer i = 0; i < 200; i++) {
            String companyName = 'Bulk Company ' + Math.mod(i, 10); // Cycle through companies
            Job_Application__c jobApp = TestDataFactory.createJobApplication(
                companyName,
                'Bulk Developer ' + i,
                'Applied',
                80000 + (i * 100),
                false
            );
            jobApp.Primary_Contact__c = null;
            bulkJobApps.add(jobApp);
        }
        insert bulkJobApps;
        
        // ACT: Call the service method with bulk data
        Test.startTest();
        ContactAssignmentService.assignPrimaryContact(bulkJobApps);
        update bulkJobApps; // Update the records after service assigns contacts
        Test.stopTest();
        
        // ASSERT: Verify all job applications got contacts assigned
        Integer assignedCount = 0;
        for (Job_Application__c jobApp : bulkJobApps) {
            if (jobApp.Primary_Contact__c != null) {
                assignedCount++;
            }
        }
        
        System.assertEquals(200, assignedCount, 
                           'All 200 job applications should have contacts assigned');
        
        // Verify governor limits were not exceeded
        System.assert(Limits.getQueries() < Limits.getLimitQueries(), 
                     'Should not exceed SOQL query limits');
        System.assert(Limits.getQueryRows() < Limits.getLimitQueryRows(), 
                     'Should not exceed query row limits');
    }
    
    /**
     * @description Test contact assignment with mixed scenarios
     * Tests combination of different edge cases in one batch
     */
    @IsTest
    static void testMixedScenarios() {
        // ARRANGE: Create job applications with various scenarios
        Contact existingContact = [SELECT Id FROM Contact WHERE Email = 'carol@innovation.com' LIMIT 1];
        
        List<Job_Application__c> mixedJobApps = new List<Job_Application__c>();
        
        // Scenario 1: Has matching company, no existing contact
        mixedJobApps.add(TestDataFactory.createJobApplication('Tech Solutions Inc', 'Dev 1', 'Applied', 100000, false));
        
        // Scenario 2: No matching company
        mixedJobApps.add(TestDataFactory.createJobApplication('Non-Existent Corp', 'Dev 2', 'Applied', 95000, false));
        
        // Scenario 3: Already has primary contact
        Job_Application__c jobAppWithContact = TestDataFactory.createJobApplication('Innovation Corp', 'Dev 3', 'Applied', 105000, false);
        jobAppWithContact.Primary_Contact__c = existingContact.Id;
        mixedJobApps.add(jobAppWithContact);
        
        // Scenario 4: Company with no matching account
        Job_Application__c jobAppNullCompany = TestDataFactory.createJobApplication('Unknown Corp 1', 'Dev 4', 'Applied', 90000, false);
        mixedJobApps.add(jobAppNullCompany);
        
        // Scenario 5: Another company with no matching account
        Job_Application__c jobAppEmptyCompany = TestDataFactory.createJobApplication('Unknown Corp 2', 'Dev 5', 'Applied', 88000, false);
        mixedJobApps.add(jobAppEmptyCompany);
        
        // Ensure appropriate contacts are null
        mixedJobApps[0].Primary_Contact__c = null; // Scenario 1
        mixedJobApps[1].Primary_Contact__c = null; // Scenario 2
        // mixedJobApps[2] already has contact set // Scenario 3
        mixedJobApps[3].Primary_Contact__c = null; // Scenario 4
        mixedJobApps[4].Primary_Contact__c = null; // Scenario 5
        insert mixedJobApps;
        
        // ACT: Call the service method
        Test.startTest();
        ContactAssignmentService.assignPrimaryContact(mixedJobApps);
        update mixedJobApps; // Update the records after service assigns contacts
        Test.stopTest();
        
        // ASSERT: Verify each scenario behaved correctly
        
        // Scenario 1: Should have contact assigned
        System.assertNotEquals(null, mixedJobApps[0].Primary_Contact__c, 
                              'Job app with matching company should have contact assigned');
        
        // Scenario 2: Should have no contact assigned
        System.assertEquals(null, mixedJobApps[1].Primary_Contact__c, 
                           'Job app with non-existent company should have no contact');
        
        // Scenario 3: Should keep existing contact
        System.assertEquals(existingContact.Id, mixedJobApps[2].Primary_Contact__c, 
                           'Job app with existing contact should keep it');
        
        // Scenario 4: Should have no contact assigned (unknown company)
        System.assertEquals(null, mixedJobApps[3].Primary_Contact__c, 
                           'Job app with unknown company should have no contact');
        
        // Scenario 5: Should have no contact assigned (another unknown company)
        System.assertEquals(null, mixedJobApps[4].Primary_Contact__c, 
                           'Job app with another unknown company should have no contact');
    }
    
    /**
     * @description Test contact assignment performance with governor limits monitoring
     * Tests that the service operates efficiently within Salesforce limits
     */
    @IsTest
    static void testGovernorLimitsCompliance() {
        // ARRANGE: Create test data that will stress governor limits
        Map<String, Object> bulkTestData = TestDataFactory.createBulkTestData(150, true, true);
        List<Job_Application__c> jobApps = (List<Job_Application__c>)bulkTestData.get('jobApplications');
        
        // Clear primary contacts to force assignment logic
        for (Job_Application__c jobApp : jobApps) {
            jobApp.Primary_Contact__c = null;
        }
        
        // Record initial governor limit usage
        Integer initialQueries = Limits.getQueries();
        Integer initialQueryRows = Limits.getQueryRows();
        Integer initialCpuTime = Limits.getCpuTime();
        
        // ACT: Call the service method
        Test.startTest();
        ContactAssignmentService.assignPrimaryContact(jobApps);
        Test.stopTest();
        
        // ASSERT: Verify governor limits compliance
        Integer finalQueries = Limits.getQueries();
        Integer finalQueryRows = Limits.getQueryRows();
        Integer finalCpuTime = Limits.getCpuTime();
        
        System.assert(finalQueries - initialQueries <= 10, 
                     'Should use minimal SOQL queries (used: ' + (finalQueries - initialQueries) + ')');
        System.assert(finalQueryRows - initialQueryRows <= 1000, 
                     'Should retrieve reasonable number of rows (retrieved: ' + (finalQueryRows - initialQueryRows) + ')');
        System.assert(finalCpuTime - initialCpuTime <= 5000, 
                     'Should execute within reasonable CPU time (used: ' + (finalCpuTime - initialCpuTime) + 'ms)');
        
        // Verify the method still worked correctly
        Integer assignedCount = 0;
        for (Job_Application__c jobApp : jobApps) {
            if (jobApp.Primary_Contact__c != null) {
                assignedCount++;
            }
        }
        
        System.assert(assignedCount > 0, 
                     'Should successfully assign contacts even with large dataset');
    }
}