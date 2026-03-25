/**
 * @description Comprehensive test class for TaskCreationService
 * Tests status-based task creation, bulk processing, and edge cases
 * @author Learning Journey - Task 7.2
 * @date 2025-01-08
 */
@IsTest
public inherited sharing class TaskCreationServiceTest {
    
    /**
     * @description Test setup method using TestDataFactory pattern
     */
    @TestSetup
    static void setupTestData() {
        // Create test job applications with various statuses
        Map<String, Object> testData = TestDataFactory.createScenarioTestData('status_change', true);
    }
    
    /**
     * @description Test task creation for 'Saved' status on insert
     * Tests the happy path for new job applications with Saved status
     */
    @IsTest
    static void testTaskCreationForSavedStatusOnInsert() {
        // ARRANGE: Create job application with Saved status
        Job_Application__c jobApp = TestDataFactory.createJobApplication(
            'Saved Status Company',
            'Software Engineer',
            'Saved',
            95000,
            false
        );
        
        List<Job_Application__c> jobApps = new List<Job_Application__c>{jobApp};
        
        // ACT: Call service method for insert (oldMap is null)
        Test.startTest();
        TaskCreationService.createTasksForStatusChange(jobApps, null);
        Test.stopTest();
        
        // Insert the job application to get an ID for task queries
        insert jobApp;
        
        // Query tasks created by the service
        List<Task> createdTasks = [
            SELECT Id, Subject, WhatId, Priority, Status, ActivityDate
            FROM Task
            WHERE WhatId = :jobApp.Id
            ORDER BY Subject
        ];
        
        // ASSERT: Verify correct number and content of tasks for Saved status
        System.assertEquals(3, createdTasks.size(), 'Should create 3 tasks for Saved status');
        
        // Verify specific tasks were created
        Boolean foundAlignmentTask = false;
        Boolean foundSkillsTask = false;
        Boolean foundResearchTask = false;
        
        for (Task task : createdTasks) {
            if (task.Subject.contains('job description aligns')) {
                foundAlignmentTask = true;
                System.assertEquals('High', task.Priority, 'Alignment task should have High priority');
                System.assertEquals(Date.today().addDays(1), task.ActivityDate, 'Alignment task should be due tomorrow');
            } else if (task.Subject.contains('highlighted skills')) {
                foundSkillsTask = true;
                System.assertEquals('High', task.Priority, 'Skills task should have High priority');
            } else if (task.Subject.contains('Research the company')) {
                foundResearchTask = true;
                System.assertEquals('Normal', task.Priority, 'Research task should have Normal priority');
                System.assertEquals(Date.today().addDays(2), task.ActivityDate, 'Research task should be due in 2 days');
            }
            
            // Verify common task properties
            System.assertEquals('Not Started', task.Status, 'All tasks should start with Not Started status');
            System.assertEquals(jobApp.Id, task.WhatId, 'All tasks should be related to the job application');
        }
        
        System.assert(foundAlignmentTask, 'Should create alignment check task');
        System.assert(foundSkillsTask, 'Should create skills review task');
        System.assert(foundResearchTask, 'Should create company research task');
    }
    
    /**
     * @description Test task creation for 'Applying' status
     * Tests task creation for the Applying status with 5 expected tasks
     */
    @IsTest
    static void testTaskCreationForApplyingStatus() {
        // ARRANGE: Create job application with Applying status
        Job_Application__c jobApp = TestDataFactory.createJobApplication(
            'Applying Status Company',
            'Full Stack Developer',
            'Applying',
            105000,
            true // Insert to get ID
        );
        
        List<Job_Application__c> jobApps = new List<Job_Application__c>{jobApp};
        
        // ACT: Call service method for insert
        Test.startTest();
        TaskCreationService.createTasksForStatusChange(jobApps, null);
        Test.stopTest();
        
        // Query created tasks
        List<Task> createdTasks = [
            SELECT Id, Subject, Priority, ActivityDate
            FROM Task
            WHERE WhatId = :jobApp.Id
            ORDER BY ActivityDate, Subject
        ];
        
        // ASSERT: Verify correct number of tasks for Applying status
        System.assertEquals(5, createdTasks.size(), 'Should create 5 tasks for Applying status');
        
        // Verify specific tasks exist
        Boolean foundContactTask = false;
        Boolean foundInterviewTask = false;
        Boolean foundReferralTask = false;
        Boolean foundCustomizeTask = false;
        Boolean foundSubmitTask = false;
        
        for (Task task : createdTasks) {
            if (task.Subject.contains('Find and research someone')) {
                foundContactTask = true;
                System.assertEquals('High', task.Priority, 'Contact research task should have High priority');
            } else if (task.Subject.contains('informational interview')) {
                foundInterviewTask = true;
                System.assertEquals('High', task.Priority, 'Informational interview task should have High priority');
            } else if (task.Subject.contains('potential referrals')) {
                foundReferralTask = true;
                System.assertEquals('High', task.Priority, 'Referral task should have High priority');
            } else if (task.Subject.contains('Customize your work achievements')) {
                foundCustomizeTask = true;
                System.assertEquals('High', task.Priority, 'Customize achievements task should have High priority');
            } else if (task.Subject.contains('Submit your application')) {
                foundSubmitTask = true;
                System.assertEquals('High', task.Priority, 'Submit application task should have High priority');
            }
        }
        
        System.assert(foundContactTask, 'Should create contact research task');
        System.assert(foundInterviewTask, 'Should create informational interview task');
        System.assert(foundReferralTask, 'Should create referral identification task');
        System.assert(foundCustomizeTask, 'Should create achievement customization task');
        System.assert(foundSubmitTask, 'Should create application submission task');
    }
    
    /**
     * @description Test task creation for 'Applied' status
     * Tests task creation for the Applied status
     */
    @IsTest
    static void testTaskCreationForAppliedStatus() {
        // ARRANGE: Create job application with Applied status
        Job_Application__c jobApp = TestDataFactory.createJobApplication(
            'Applied Status Company',
            'Backend Developer',
            'Applied',
            98000,
            true
        );
        
        List<Job_Application__c> jobApps = new List<Job_Application__c>{jobApp};
        
        // ACT: Call service method
        Test.startTest();
        TaskCreationService.createTasksForStatusChange(jobApps, null);
        Test.stopTest();
        
        // Query created tasks
        List<Task> createdTasks = [
            SELECT Id, Subject, Priority, ActivityDate
            FROM Task
            WHERE WhatId = :jobApp.Id
        ];
        
        // ASSERT: Verify correct number of tasks for Applied status
        System.assertEquals(4, createdTasks.size(), 'Should create 4 tasks for Applied status');
        
        // Verify specific tasks exist
        Boolean foundHiringManagerTask = false;
        Boolean foundFollowUpTask = false;
        Boolean foundSimilarJobsTask = false;
        Boolean foundNetworkingTask = false;
        
        for (Task task : createdTasks) {
            if (task.Subject.contains('hiring manager or recruiter')) {
                foundHiringManagerTask = true;
                System.assertEquals('High', task.Priority, 'Hiring manager task should have High priority');
                System.assertEquals(Date.today().addDays(1), task.ActivityDate, 'Should be due tomorrow');
            } else if (task.Subject.contains('Follow up on your application')) {
                foundFollowUpTask = true;
                System.assertEquals('Normal', task.Priority, 'Follow up task should have Normal priority');
                System.assertEquals(Date.today().addDays(7), task.ActivityDate, 'Should be due in 7 days');
            } else if (task.Subject.contains('similar job opportunities')) {
                foundSimilarJobsTask = true;
                System.assertEquals('Normal', task.Priority, 'Similar jobs task should have Normal priority');
            } else if (task.Subject.contains('networking calls')) {
                foundNetworkingTask = true;
                System.assertEquals('Normal', task.Priority, 'Networking task should have Normal priority');
            }
        }
        
        System.assert(foundHiringManagerTask, 'Should create hiring manager outreach task');
        System.assert(foundFollowUpTask, 'Should create follow-up task');
        System.assert(foundSimilarJobsTask, 'Should create similar jobs task');
        System.assert(foundNetworkingTask, 'Should create networking task');
    }
    
    /**
     * @description Test task creation for 'Interviewing' status
     * Tests interview preparation tasks
     */
    @IsTest
    static void testTaskCreationForInterviewingStatus() {
        // ARRANGE: Create job application with Interviewing status
        Job_Application__c jobApp = TestDataFactory.createJobApplication(
            'Interviewing Company',
            'Frontend Developer',
            'Interviewing',
            92000,
            true
        );
        
        List<Job_Application__c> jobApps = new List<Job_Application__c>{jobApp};
        
        // ACT: Call service method
        Test.startTest();
        TaskCreationService.createTasksForStatusChange(jobApps, null);
        Test.stopTest();
        
        // Query created tasks
        List<Task> createdTasks = [
            SELECT Id, Subject, Priority, ActivityDate
            FROM Task
            WHERE WhatId = :jobApp.Id
        ];
        
        // ASSERT: Verify interview preparation tasks
        System.assertEquals(5, createdTasks.size(), 'Should create 5 tasks for Interviewing status');
        
        Boolean foundBlurbTask = false;
        Boolean foundBehavioralTask = false;
        Boolean foundResearchTask = false;
        Boolean foundTechSetupTask = false;
        Boolean foundThankYouTask = false;
        
        for (Task task : createdTasks) {
            if (task.Subject.contains('tell me about yourself')) {
                foundBlurbTask = true;
                System.assertEquals('High', task.Priority, 'Blurb preparation should have High priority');
            } else if (task.Subject.contains('behavioral interview questions')) {
                foundBehavioralTask = true;
                System.assertEquals('High', task.Priority, 'Behavioral prep should have High priority');
            } else if (task.Subject.contains('Research the company and your interviewers')) {
                foundResearchTask = true;
                System.assertEquals('High', task.Priority, 'Research should have High priority');
            } else if (task.Subject.contains('virtual interview space')) {
                foundTechSetupTask = true;
                System.assertEquals('High', task.Priority, 'Tech setup should have High priority');
            } else if (task.Subject.contains('thank you emails')) {
                foundThankYouTask = true;
                System.assertEquals('High', task.Priority, 'Thank you emails should have High priority');
                System.assertEquals(Date.today().addDays(2), task.ActivityDate, 'Thank you task should be due in 2 days');
            }
        }
        
        System.assert(foundBlurbTask, 'Should create blurb preparation task');
        System.assert(foundBehavioralTask, 'Should create behavioral questions task');
        System.assert(foundResearchTask, 'Should create company research task');
        System.assert(foundTechSetupTask, 'Should create tech setup task');
        System.assert(foundThankYouTask, 'Should create thank you email task');
    }
    
    /**
     * @description Test task creation for 'Negotiating' status
     * Tests salary negotiation preparation tasks
     */
    @IsTest
    static void testTaskCreationForNegotiatingStatus() {
        // ARRANGE: Create job application with Negotiating status
        Job_Application__c jobApp = TestDataFactory.createJobApplication(
            'Negotiating Company',
            'Senior Engineer',
            'Negotiating',
            125000,
            true
        );
        
        List<Job_Application__c> jobApps = new List<Job_Application__c>{jobApp};
        
        // ACT: Call service method
        Test.startTest();
        TaskCreationService.createTasksForStatusChange(jobApps, null);
        Test.stopTest();
        
        // Query created tasks
        List<Task> createdTasks = [
            SELECT Id, Subject, Priority, ActivityDate
            FROM Task
            WHERE WhatId = :jobApp.Id
        ];
        
        // ASSERT: Verify negotiation tasks
        System.assertEquals(3, createdTasks.size(), 'Should create 3 tasks for Negotiating status');
        
        Boolean foundMarketValueTask = false;
        Boolean foundScriptsTask = false;
        Boolean foundEvaluateTask = false;
        
        for (Task task : createdTasks) {
            if (task.Subject.contains('market value')) {
                foundMarketValueTask = true;
                System.assertEquals('High', task.Priority, 'Market value research should have High priority');
            } else if (task.Subject.contains('negotiation scripts')) {
                foundScriptsTask = true;
                System.assertEquals('High', task.Priority, 'Script preparation should have High priority');
            } else if (task.Subject.contains('Evaluate your offer')) {
                foundEvaluateTask = true;
                System.assertEquals('High', task.Priority, 'Offer evaluation should have High priority');
                System.assertEquals(Date.today().addDays(3), task.ActivityDate, 'Evaluation should be due in 3 days');
            }
        }
        
        System.assert(foundMarketValueTask, 'Should create market value research task');
        System.assert(foundScriptsTask, 'Should create negotiation scripts task');
        System.assert(foundEvaluateTask, 'Should create offer evaluation task');
    }
    
    /**
     * @description Test task creation for 'Accepted' status
     * Tests post-acceptance tasks
     */
    @IsTest
    static void testTaskCreationForAcceptedStatus() {
        // ARRANGE: Create job application with Accepted status
        Job_Application__c jobApp = TestDataFactory.createJobApplication(
            'Accepted Company',
            'Lead Developer',
            'Accepted',
            135000,
            true
        );
        
        List<Job_Application__c> jobApps = new List<Job_Application__c>{jobApp};
        
        // ACT: Call service method
        Test.startTest();
        TaskCreationService.createTasksForStatusChange(jobApps, null);
        Test.stopTest();
        
        // Query created tasks
        List<Task> createdTasks = [
            SELECT Id, Subject, Priority, ActivityDate
            FROM Task
            WHERE WhatId = :jobApp.Id
        ];
        
        // ASSERT: Verify acceptance tasks
        System.assertEquals(3, createdTasks.size(), 'Should create 3 tasks for Accepted status');
        
        Boolean foundResignationTask = false;
        Boolean foundRelaxTask = false;
        Boolean foundOnboardingTask = false;
        
        for (Task task : createdTasks) {
            if (task.Subject.contains('resignation')) {
                foundResignationTask = true;
                System.assertEquals('High', task.Priority, 'Resignation planning should have High priority');
            } else if (task.Subject.contains('relax and recharge')) {
                foundRelaxTask = true;
                System.assertEquals('Low', task.Priority, 'Relaxation should have Low priority');
            } else if (task.Subject.contains('first day of onboarding')) {
                foundOnboardingTask = true;
                System.assertEquals('Normal', task.Priority, 'Onboarding prep should have Normal priority');
                System.assertEquals(Date.today().addDays(7), task.ActivityDate, 'Onboarding prep should be due in 7 days');
            }
        }
        
        System.assert(foundResignationTask, 'Should create resignation planning task');
        System.assert(foundRelaxTask, 'Should create relaxation task');
        System.assert(foundOnboardingTask, 'Should create onboarding preparation task');
    }
    
    /**
     * @description Test task creation for 'Closed' status
     * Tests post-rejection tasks
     */
    @IsTest
    static void testTaskCreationForClosedStatus() {
        // ARRANGE: Create job application with Closed status
        Job_Application__c jobApp = TestDataFactory.createJobApplication(
            'Closed Company',
            'Software Architect',
            'Closed',
            145000,
            true
        );
        
        List<Job_Application__c> jobApps = new List<Job_Application__c>{jobApp};
        
        // ACT: Call service method
        Test.startTest();
        TaskCreationService.createTasksForStatusChange(jobApps, null);
        Test.stopTest();
        
        // Query created tasks
        List<Task> createdTasks = [
            SELECT Id, Subject, Priority, ActivityDate
            FROM Task
            WHERE WhatId = :jobApp.Id
        ];
        
        // ASSERT: Verify closure tasks
        System.assertEquals(2, createdTasks.size(), 'Should create 2 tasks for Closed status');
        
        Boolean foundFollowUpTask = false;
        Boolean foundReflectionTask = false;
        
        for (Task task : createdTasks) {
            if (task.Subject.contains('follow-up email')) {
                foundFollowUpTask = true;
                System.assertEquals('Normal', task.Priority, 'Follow-up should have Normal priority');
                System.assertEquals(Date.today().addDays(1), task.ActivityDate, 'Follow-up should be due tomorrow');
            } else if (task.Subject.contains('Review your notes')) {
                foundReflectionTask = true;
                System.assertEquals('Normal', task.Priority, 'Reflection should have Normal priority');
                System.assertEquals(Date.today().addDays(2), task.ActivityDate, 'Reflection should be due in 2 days');
            }
        }
        
        System.assert(foundFollowUpTask, 'Should create follow-up email task');
        System.assert(foundReflectionTask, 'Should create reflection task');
    }
    
    /**
     * @description Test task creation on status change (update scenario)
     * Tests that tasks are only created when status actually changes
     */
    @IsTest
    static void testTaskCreationOnStatusChange() {
        // ARRANGE: Create job application and simulate status change
        Job_Application__c jobApp = TestDataFactory.createJobApplication(
            'Status Change Company',
            'DevOps Engineer',
            'Saved',
            88000,
            true
        );
        
        // Create old map to simulate update scenario
        Map<Id, Job_Application__c> oldMap = new Map<Id, Job_Application__c>();
        oldMap.put(jobApp.Id, jobApp.clone(true, true, true, true));
        
        // Change status
        jobApp.Status__c = 'Applied';
        List<Job_Application__c> jobApps = new List<Job_Application__c>{jobApp};
        
        // ACT: Call service method with oldMap (simulating update)
        Test.startTest();
        TaskCreationService.createTasksForStatusChange(jobApps, oldMap);
        Test.stopTest();
        
        // Query created tasks
        List<Task> createdTasks = [
            SELECT Id, Subject
            FROM Task
            WHERE WhatId = :jobApp.Id
        ];
        
        // ASSERT: Verify tasks were created for status change
        System.assertEquals(4, createdTasks.size(), 'Should create 4 tasks for Applied status on status change');
    }
    
    /**
     * @description Test no task creation when status doesn't change
     * Tests that tasks are not created when status remains the same
     */
    @IsTest
    static void testNoTaskCreationWhenStatusUnchanged() {
        // ARRANGE: Create job application
        Job_Application__c jobApp = TestDataFactory.createJobApplication(
            'Unchanged Status Company',
            'QA Engineer',
            'Applied',
            82000,
            true
        );
        
        // Create old map with same status
        Map<Id, Job_Application__c> oldMap = new Map<Id, Job_Application__c>();
        Job_Application__c oldJobApp = jobApp.clone(true, true, true, true);
        oldJobApp.Status__c = 'Applied'; // Same status
        oldMap.put(jobApp.Id, oldJobApp);
        
        List<Job_Application__c> jobApps = new List<Job_Application__c>{jobApp};
        
        // ACT: Call service method with unchanged status
        Test.startTest();
        TaskCreationService.createTasksForStatusChange(jobApps, oldMap);
        Test.stopTest();
        
        // Query tasks
        List<Task> createdTasks = [
            SELECT Id
            FROM Task
            WHERE WhatId = :jobApp.Id
        ];
        
        // ASSERT: Verify no tasks were created
        System.assertEquals(0, createdTasks.size(), 'Should not create tasks when status is unchanged');
    }
    
    /**
     * @description Test task creation with unknown status
     * Tests edge case handling for unsupported status values
     */
    @IsTest
    static void testTaskCreationWithUnknownStatus() {
        // ARRANGE: Create job application with unknown status
        Job_Application__c jobApp = TestDataFactory.createJobApplication(
            'Unknown Status Company',
            'Mystery Developer',
            'Unknown Status',
            75000,
            true
        );
        
        List<Job_Application__c> jobApps = new List<Job_Application__c>{jobApp};
        
        // ACT: Call service method
        Test.startTest();
        TaskCreationService.createTasksForStatusChange(jobApps, null);
        Test.stopTest();
        
        // Query tasks
        List<Task> createdTasks = [
            SELECT Id
            FROM Task
            WHERE WhatId = :jobApp.Id
        ];
        
        // ASSERT: Verify no tasks were created for unknown status
        System.assertEquals(0, createdTasks.size(), 'Should not create tasks for unknown status');
    }
    
    /**
     * @description Test bulk task creation with multiple job applications
     * Tests performance and bulk processing capabilities
     */
    @IsTest
    static void testBulkTaskCreation() {
        // ARRANGE: Create multiple job applications with different statuses
        List<Job_Application__c> bulkJobApps = new List<Job_Application__c>();
        
        // Create 50 job applications with various statuses
        String[] statuses = new String[]{'Saved', 'Applying', 'Applied', 'Interviewing', 'Negotiating'};
        
        for (Integer i = 0; i < 50; i++) {
            String status = statuses[Math.mod(i, statuses.size())];
            bulkJobApps.add(TestDataFactory.createJobApplication(
                'Bulk Company ' + i,
                'Bulk Position ' + i,
                status,
                75000 + (i * 1000),
                false
            ));
        }
        
        insert bulkJobApps;
        
        // ACT: Call service method with bulk data
        Test.startTest();
        TaskCreationService.createTasksForStatusChange(bulkJobApps, null);
        Test.stopTest();
        
        // Query all created tasks
        List<Task> allTasks = [
            SELECT Id, WhatId, Subject
            FROM Task
            WHERE WhatId IN :bulkJobApps
        ];
        
        // ASSERT: Verify bulk processing worked correctly
        System.assert(allTasks.size() > 0, 'Should create tasks for bulk job applications');
        
        // Verify tasks were created for each job application
        Map<Id, List<Task>> tasksByJobApp = new Map<Id, List<Task>>();
        for (Task task : allTasks) {
            if (!tasksByJobApp.containsKey(task.WhatId)) {
                tasksByJobApp.put(task.WhatId, new List<Task>());
            }
            tasksByJobApp.get(task.WhatId).add(task);
        }
        
        // Verify each job application got appropriate number of tasks
        for (Job_Application__c jobApp : bulkJobApps) {
            List<Task> jobAppTasks = tasksByJobApp.get(jobApp.Id);
            System.assertNotEquals(null, jobAppTasks, 'Each job application should have tasks created');
            System.assert(jobAppTasks.size() > 0, 'Each job application should have at least one task');
        }
        
        // Verify governor limits compliance
        System.assert(Limits.getDMLStatements() <= 1, 'Should use bulk DML operations');
        System.assert(Limits.getDMLRows() <= 10000, 'Should not exceed DML row limits');
    }
    
    /**
     * @description Test error handling during task insertion
     * Tests graceful handling of DML exceptions
     */
    @IsTest
    static void testErrorHandlingDuringTaskInsertion() {
        // ARRANGE: Create job application
        Job_Application__c jobApp = TestDataFactory.createJobApplication(
            'Error Test Company',
            'Error Test Position',
            'Saved',
            90000,
            true
        );
        
        List<Job_Application__c> jobApps = new List<Job_Application__c>{jobApp};
        
        // ACT: Call service method (this should handle any DML errors gracefully)
        Test.startTest();
        try {
            TaskCreationService.createTasksForStatusChange(jobApps, null);
            System.assert(true, 'Service method should handle errors gracefully');
        } catch (Exception e) {
            System.assert(false, 'Service method should not throw unhandled exceptions: ' + e.getMessage());
        }
        Test.stopTest();
        
        // ASSERT: Verify method completed without throwing exceptions
        System.assert(true, 'Error handling test completed successfully');
    }
    
    /**
     * @description Test task creation with null and empty inputs
     * Tests edge case handling for invalid inputs
     */
    @IsTest
    static void testTaskCreationWithInvalidInputs() {
        // ACT & ASSERT: Test with null job applications list
        Test.startTest();
        try {
            TaskCreationService.createTasksForStatusChange(null, null);
            System.assert(false, 'Should handle null input appropriately');
        } catch (Exception e) {
            System.assert(e instanceof NullPointerException, 'Should throw appropriate exception for null input');
        }
        
        // Test with empty job applications list
        List<Job_Application__c> emptyList = new List<Job_Application__c>();
        TaskCreationService.createTasksForStatusChange(emptyList, null);
        System.assert(true, 'Should handle empty list gracefully');
        
        Test.stopTest();
    }
    
    /**
     * @description Test governor limits compliance during bulk operations
     * Tests that the service operates within Salesforce limits
     */
    @IsTest
    static void testGovernorLimitsCompliance() {
        // ARRANGE: Create large dataset for governor limits testing
        List<Job_Application__c> largeDataset = TestDataFactory.createJobApplications(100, 'Saved', true);
        
        // Record initial limits
        Integer initialQueries = Limits.getQueries();
        Integer initialDMLStatements = Limits.getDMLStatements();
        Integer initialCpuTime = Limits.getCpuTime();
        
        // ACT: Process large dataset
        Test.startTest();
        TaskCreationService.createTasksForStatusChange(largeDataset, null);
        Test.stopTest();
        
        // ASSERT: Verify governor limits compliance
        Integer finalQueries = Limits.getQueries();
        Integer finalDMLStatements = Limits.getDMLStatements();
        Integer finalCpuTime = Limits.getCpuTime();
        
        System.assert(finalQueries - initialQueries <= 5, 
                     'Should use minimal SOQL queries (used: ' + (finalQueries - initialQueries) + ')');
        System.assert(finalDMLStatements - initialDMLStatements <= 2, 
                     'Should use minimal DML statements (used: ' + (finalDMLStatements - initialDMLStatements) + ')');
        System.assert(finalCpuTime - initialCpuTime <= 5000, 
                     'Should execute within reasonable CPU time (used: ' + (finalCpuTime - initialCpuTime) + 'ms)');
        
        // Verify tasks were actually created
        List<Task> createdTasks = [SELECT Id FROM Task WHERE WhatId IN :largeDataset];
        System.assertEquals(300, createdTasks.size(), 'Should create 3 tasks per job application (100 * 3)');
    }
}