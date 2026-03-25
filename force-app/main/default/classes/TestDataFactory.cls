/**
 * @description Test Data Factory for creating reusable test data across all test classes
 * Implements the Test Data Factory pattern for maintainable, consistent test data
 * @author Learning Journey - Task 7.2
 * @date 2025-01-08
 */
@IsTest
public inherited sharing class TestDataFactory {
    
    // Constants for consistent test data
    public static final String TEST_COMPANY_NAME = 'Test Company Inc';
    public static final String TEST_POSITION_TITLE = 'Software Developer';
    public static final String TEST_CONTACT_EMAIL = 'test.contact@testcompany.com';
    public static final Decimal TEST_SALARY = 100000;
    
    /**
     * @description Creates a single Job Application record
     * @param companyName Company name (optional, uses default if null)
     * @param positionTitle Position title (optional, uses default if null)
     * @param status Application status (optional, uses 'Applied' if null)
     * @param salary Salary amount (optional, uses default if null)
     * @param doInsert Whether to insert the record (default: false)
     * @return Job_Application__c record
     */
    public static Job_Application__c createJobApplication(String companyName, String positionTitle, 
                                                         String status, Decimal salary, Boolean doInsert) {
        Job_Application__c jobApp = new Job_Application__c(
            Company_Name__c = companyName != null ? companyName : TEST_COMPANY_NAME,
            Position_Title__c = positionTitle != null ? positionTitle : TEST_POSITION_TITLE,
            Status__c = status != null ? status : 'Applied',
            Salary__c = salary != null ? salary : TEST_SALARY,
            Application_Date__c = Date.today(),
            Job_URL__c = 'https://example.com/job-posting',
            Location__c = 'Remote',
            Notes__c = 'Test job application created by TestDataFactory'
        );
        
        if (doInsert != null && doInsert) {
            insert jobApp;
        }
        
        return jobApp;
    }
    
    /**
     * @description Creates a single Job Application record with default values
     * @param doInsert Whether to insert the record (default: false)
     * @return Job_Application__c record
     */
    public static Job_Application__c createJobApplication(Boolean doInsert) {
        return createJobApplication(null, null, null, null, doInsert);
    }
    
    /**
     * @description Creates a single Job Application record (not inserted)
     * @return Job_Application__c record
     */
    public static Job_Application__c createJobApplication() {
        return createJobApplication(false);
    }
    
    /**
     * @description Creates multiple Job Application records
     * @param count Number of records to create
     * @param status Status for all records (optional)
     * @param doInsert Whether to insert the records (default: false)
     * @return List of Job_Application__c records
     */
    public static List<Job_Application__c> createJobApplications(Integer count, String status, Boolean doInsert) {
        List<Job_Application__c> jobApps = new List<Job_Application__c>();
        
        for (Integer i = 0; i < count; i++) {
            jobApps.add(createJobApplication(
                TEST_COMPANY_NAME + ' ' + i,
                TEST_POSITION_TITLE + ' ' + i,
                status,
                TEST_SALARY + (i * 1000),
                false
            ));
        }
        
        if (doInsert != null && doInsert) {
            insert jobApps;
        }
        
        return jobApps;
    }
    
    /**
     * @description Creates multiple Job Application records with default status
     * @param count Number of records to create
     * @param doInsert Whether to insert the records (default: false)
     * @return List of Job_Application__c records
     */
    public static List<Job_Application__c> createJobApplications(Integer count, Boolean doInsert) {
        return createJobApplications(count, null, doInsert);
    }
    
    /**
     * @description Creates a test Account record
     * @param accountName Account name (optional, uses default if null)
     * @param doInsert Whether to insert the record (default: false)
     * @return Account record
     */
    public static Account createAccount(String accountName, Boolean doInsert) {
        Account testAccount = new Account(
            Name = accountName != null ? accountName : TEST_COMPANY_NAME,
            Industry = 'Technology',
            Type = 'Customer',
            Phone = '(555) 123-4567',
            Website = 'https://www.testcompany.com'
        );
        
        if (doInsert != null && doInsert) {
            insert testAccount;
        }
        
        return testAccount;
    }
    
    /**
     * @description Creates a test Account record with default values
     * @param doInsert Whether to insert the record (default: false)
     * @return Account record
     */
    public static Account createAccount(Boolean doInsert) {
        return createAccount(null, doInsert);
    }
    
    /**
     * @description Creates a test Contact record
     * @param accountId Related Account ID (optional)
     * @param firstName First name (optional, uses default if null)
     * @param lastName Last name (optional, uses default if null)
     * @param email Email address (optional, uses default if null)
     * @param doInsert Whether to insert the record (default: false)
     * @return Contact record
     */
    public static Contact createContact(Id accountId, String firstName, String lastName, 
                                       String email, Boolean doInsert) {
        Contact testContact = new Contact(
            AccountId = accountId,
            FirstName = firstName != null ? firstName : 'John',
            LastName = lastName != null ? lastName : 'Doe',
            Email = email != null ? email : TEST_CONTACT_EMAIL,
            Title = 'Hiring Manager',
            Phone = '(555) 987-6543'
        );
        
        if (doInsert != null && doInsert) {
            insert testContact;
        }
        
        return testContact;
    }
    
    /**
     * @description Creates a test Contact record with default values
     * @param accountId Related Account ID (optional)
     * @param doInsert Whether to insert the record (default: false)
     * @return Contact record
     */
    public static Contact createContact(Id accountId, Boolean doInsert) {
        return createContact(accountId, null, null, null, doInsert);
    }
    
    /**
     * @description Creates a test Task record
     * @param whatId Related record ID (Job Application)
     * @param subject Task subject (optional, uses default if null)
     * @param priority Task priority (optional, uses 'Normal' if null)
     * @param status Task status (optional, uses 'Not Started' if null)
     * @param doInsert Whether to insert the record (default: false)
     * @return Task record
     */
    public static Task createTask(Id whatId, String subject, String priority, String status, Boolean doInsert) {
        Task testTask = new Task(
            WhatId = whatId,
            Subject = subject != null ? subject : 'Test Task',
            Priority = priority != null ? priority : 'Normal',
            Status = status != null ? status : 'Not Started',
            ActivityDate = Date.today().addDays(7),
            Description = 'Test task created by TestDataFactory'
        );
        
        if (doInsert != null && doInsert) {
            insert testTask;
        }
        
        return testTask;
    }
    
    /**
     * @description Creates multiple test Task records
     * @param whatId Related record ID (Job Application)
     * @param count Number of tasks to create
     * @param doInsert Whether to insert the records (default: false)
     * @return List of Task records
     */
    public static List<Task> createTasks(Id whatId, Integer count, Boolean doInsert) {
        List<Task> tasks = new List<Task>();
        
        for (Integer i = 0; i < count; i++) {
            tasks.add(createTask(
                whatId,
                'Test Task ' + i,
                i == 0 ? 'High' : 'Normal',
                'Not Started',
                false
            ));
        }
        
        if (doInsert != null && doInsert) {
            insert tasks;
        }
        
        return tasks;
    }
    
    /**
     * @description Creates a test User record (for testing user-specific functionality)
     * @param profileName Profile name (optional, uses 'Standard User' if null)
     * @param firstName First name (optional, uses default if null)
     * @param lastName Last name (optional, uses default if null)
     * @param email Email address (optional, uses default if null)
     * @param doInsert Whether to insert the record (default: false)
     * @return User record
     */
    public static User createUser(String profileName, String firstName, String lastName, 
                                 String email, Boolean doInsert) {
        Profile testProfile = [SELECT Id FROM Profile WHERE Name = :profileName LIMIT 1];
        
        String uniqueId = String.valueOf(System.currentTimeMillis());
        
        User testUser = new User(
            ProfileId = testProfile.Id,
            FirstName = firstName != null ? firstName : 'Test',
            LastName = lastName != null ? lastName : 'User',
            Email = email != null ? email : 'testuser' + uniqueId + '@test.com',
            Username = 'testuser' + uniqueId + '@test.com.test',
            Alias = 'tuser' + uniqueId.substring(uniqueId.length() - 4),
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        
        if (doInsert != null && doInsert) {
            insert testUser;
        }
        
        return testUser;
    }
    
    /**
     * @description Creates test data for bulk processing scenarios
     * @param recordCount Number of Job Applications to create
     * @param includeRelatedData Whether to create related Accounts and Contacts
     * @param doInsert Whether to insert all records (default: false)
     * @return Map containing all created test data
     */
    public static Map<String, Object> createBulkTestData(Integer recordCount, Boolean includeRelatedData, Boolean doInsert) {
        Map<String, Object> testData = new Map<String, Object>();
        
        List<Account> accounts = new List<Account>();
        List<Contact> contacts = new List<Contact>();
        List<Job_Application__c> jobApps = new List<Job_Application__c>();
        List<Task> tasks = new List<Task>();
        
        // Create accounts if requested
        if (includeRelatedData != null && includeRelatedData) {
            for (Integer i = 0; i < Math.min(recordCount, 10); i++) { // Limit accounts to 10
                accounts.add(createAccount('Bulk Test Company ' + i, false));
            }
            
            if (doInsert != null && doInsert) {
                insert accounts;
            }
            
            // Create contacts for accounts
            for (Account acc : accounts) {
                contacts.add(createContact(acc.Id, 'Contact', 'User ' + contacts.size(), null, false));
            }
            
            if (doInsert != null && doInsert) {
                insert contacts;
            }
        }
        
        // Create job applications
        for (Integer i = 0; i < recordCount; i++) {
            Job_Application__c jobApp = createJobApplication(
                'Bulk Test Company ' + Math.mod(i, 10),
                'Bulk Test Position ' + i,
                i < recordCount / 2 ? 'Applied' : 'Interviewing',
                75000 + (i * 500),
                false
            );
            
            // Assign primary contact if available
            if (!contacts.isEmpty()) {
                jobApp.Primary_Contact__c = contacts[Math.mod(i, contacts.size())].Id;
            }
            
            jobApps.add(jobApp);
        }
        
        if (doInsert != null && doInsert) {
            insert jobApps;
            
            // Create tasks for job applications
            for (Job_Application__c jobApp : jobApps) {
                tasks.addAll(createTasks(jobApp.Id, 3, false));
            }
            
            if (!tasks.isEmpty()) {
                insert tasks;
            }
        }
        
        testData.put('accounts', accounts);
        testData.put('contacts', contacts);
        testData.put('jobApplications', jobApps);
        testData.put('tasks', tasks);
        testData.put('recordCount', recordCount);
        
        return testData;
    }
    
    /**
     * @description Creates test data for specific scenarios
     * @param scenario Scenario name ('salary_calculation', 'status_change', 'bulk_processing', etc.)
     * @param doInsert Whether to insert the records (default: false)
     * @return Map containing scenario-specific test data
     */
    public static Map<String, Object> createScenarioTestData(String scenario, Boolean doInsert) {
        Map<String, Object> testData = new Map<String, Object>();
        
        switch on scenario {
            when 'salary_calculation' {
                List<Job_Application__c> salaryApps = new List<Job_Application__c>();
                
                // Different salary ranges for testing tax calculations
                salaryApps.add(createJobApplication('Low Salary Company', 'Entry Level', 'Applied', 35000, false));
                salaryApps.add(createJobApplication('Mid Salary Company', 'Mid Level', 'Applied', 75000, false));
                salaryApps.add(createJobApplication('High Salary Company', 'Senior Level', 'Applied', 150000, false));
                salaryApps.add(createJobApplication('Executive Company', 'Executive Level', 'Applied', 250000, false));
                
                if (doInsert != null && doInsert) {
                    insert salaryApps;
                }
                
                testData.put('jobApplications', salaryApps);
            }
            
            when 'status_change' {
                List<Job_Application__c> statusApps = new List<Job_Application__c>();
                
                // Different statuses for testing task creation
                statusApps.add(createJobApplication('Saved Company', 'Position 1', 'Saved', 80000, false));
                statusApps.add(createJobApplication('Applying Company', 'Position 2', 'Applying', 85000, false));
                statusApps.add(createJobApplication('Applied Company', 'Position 3', 'Applied', 90000, false));
                statusApps.add(createJobApplication('Interviewing Company', 'Position 4', 'Interviewing', 95000, false));
                statusApps.add(createJobApplication('Negotiating Company', 'Position 5', 'Negotiating', 100000, false));
                
                if (doInsert != null && doInsert) {
                    insert statusApps;
                }
                
                testData.put('jobApplications', statusApps);
            }
            
            when 'bulk_processing' {
                testData = createBulkTestData(200, true, doInsert);
            }
            
            when 'api_integration' {
                Job_Application__c apiApp = createJobApplication('API Test Company', 'API Developer', 'Applied', 120000, doInsert);
                testData.put('jobApplication', apiApp);
                testData.put('testApiEndpoint', 'https://api.example.com/test');
                testData.put('testApiResponse', '{"status": "success", "data": {"salary": 120000}}');
            }
            
            when 'platform_events' {
                Job_Application__c eventApp = createJobApplication('Event Test Company', 'Event Developer', 'Applied', 110000, doInsert);
                testData.put('jobApplication', eventApp);
                testData.put('eventType', 'CREATED');
                testData.put('eventData', '{"source": "TestDataFactory", "timestamp": ' + DateTime.now().getTime() + '}');
            }
            
            when else {
                // Default scenario - basic test data
                testData.put('jobApplication', createJobApplication(doInsert));
                testData.put('account', createAccount(doInsert));
                testData.put('contact', createContact(null, doInsert));
            }
        }
        
        return testData;
    }
    
    /**
     * @description Utility method to clean up test data (for use in tearDown methods)
     * @param testData Map containing test data to clean up
     */
    public static void cleanupTestData(Map<String, Object> testData) {
        try {
            // Clean up in reverse order of dependencies
            if (testData.containsKey('tasks')) {
                List<Task> tasks = (List<Task>)testData.get('tasks');
                if (tasks != null && !tasks.isEmpty()) {
                    delete tasks;
                }
            }
            
            if (testData.containsKey('jobApplications')) {
                List<Job_Application__c> jobApps = (List<Job_Application__c>)testData.get('jobApplications');
                if (jobApps != null && !jobApps.isEmpty()) {
                    delete jobApps;
                }
            }
            
            if (testData.containsKey('jobApplication')) {
                Job_Application__c jobApp = (Job_Application__c)testData.get('jobApplication');
                if (jobApp != null && jobApp.Id != null) {
                    delete jobApp;
                }
            }
            
            if (testData.containsKey('contacts')) {
                List<Contact> contacts = (List<Contact>)testData.get('contacts');
                if (contacts != null && !contacts.isEmpty()) {
                    delete contacts;
                }
            }
            
            if (testData.containsKey('accounts')) {
                List<Account> accounts = (List<Account>)testData.get('accounts');
                if (accounts != null && !accounts.isEmpty()) {
                    delete accounts;
                }
            }
            
        } catch (Exception e) {
            System.debug('Error cleaning up test data: ' + e.getMessage());
        }
    }
}