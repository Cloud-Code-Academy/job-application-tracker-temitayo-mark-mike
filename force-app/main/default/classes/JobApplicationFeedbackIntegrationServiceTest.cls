/**
 * @description Test class for JobApplicationFeedbackIntegrationService
 * Tests integration between interview feedback and job application workflow
 * @author Temitayo Oluwalade
 * @date 2024
 */
@isTest
private inherited sharing class JobApplicationFeedbackIntegrationServiceTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test job applications
        List<Job_Application__c> jobApps = new List<Job_Application__c>();
        
        for (Integer i = 1; i <= 3; i++) {
            Job_Application__c jobApp = new Job_Application__c(
                Position_Title__c = 'Test Position ' + i,
                Company_Name__c = 'Test Company ' + i,
                Status__c = 'Applied',
                Salary__c = 80000 + (i * 10000)
            );
            jobApps.add(jobApp);
        }
        
        insert jobApps;
        
        // Create feedback template
        Feedback_Template__c template = new Feedback_Template__c(
            Name = 'Test Template',
            Interview_Type__c = 'Technical',
            Competency_Areas__c = 'Technical Skills;Communication;Problem Solving'
        );
        insert template;
    }
    
    @isTest
    static void testUpdateJobApplicationMetrics_SingleFeedback() {
        // Get test job application
        Job_Application__c jobApp = [SELECT Id FROM Job_Application__c LIMIT 1];
        
        // Create interview feedback
        Interview_Feedback__c feedback = InterviewFeedbackTestDataFactory.createInterviewFeedback(
            jobApp.Id, 'Technical', 4.5
        );
        insert feedback;
        
        // Create competency ratings
        List<Competency_Rating__c> ratings = new List<Competency_Rating__c>{
            new Competency_Rating__c(
                Interview_Feedback__c = feedback.Id,
                Competency_Name__c = 'Technical Skills',
                Rating__c = 4.5
            ),
            new Competency_Rating__c(
                Interview_Feedback__c = feedback.Id,
                Competency_Name__c = 'Communication',
                Rating__c = 4.0
            )
        };
        insert ratings;
        
        Test.startTest();
        JobApplicationFeedbackIntegrationService.updateJobApplicationMetrics(new List<Interview_Feedback__c>{feedback});
        Test.stopTest();
        
        // Verify job application was updated
        Job_Application__c updatedJobApp = [
            SELECT Id, Average_Interview_Rating__c, Total_Interview_Count__c, 
                   Interview_Success_Score__c, Feedback_Summary__c, Next_Steps__c
            FROM Job_Application__c 
            WHERE Id = :jobApp.Id
        ];
        
        System.assertEquals(4.5, updatedJobApp.Average_Interview_Rating__c, 'Average rating should be 4.5');
        System.assertEquals(1, updatedJobApp.Total_Interview_Count__c, 'Interview count should be 1');
        System.assertNotEquals(null, updatedJobApp.Interview_Success_Score__c, 'Success score should be calculated');
        System.assert(updatedJobApp.Interview_Success_Score__c > 80, 'Success score should be high for good rating');
    }
    
    @isTest
    static void testUpdateJobApplicationMetrics_MultipleFeedback() {
        // Get test job application
        Job_Application__c jobApp = [SELECT Id FROM Job_Application__c LIMIT 1];
        
        // Create multiple interview feedback records
        List<Interview_Feedback__c> feedbackList = new List<Interview_Feedback__c>();
        
        for (Integer i = 1; i <= 3; i++) {
            Interview_Feedback__c feedback = InterviewFeedbackTestDataFactory.createInterviewFeedback(
                jobApp.Id, 'Technical', 3.0 + i * 0.5
            );
            feedback.Interview_Date__c = DateTime.now().addDays(-i);
            feedback.Strengths__c = 'Strength ' + i;
            feedback.Areas_for_Improvement__c = 'Improvement ' + i;
            feedbackList.add(feedback);
        }
        
        insert feedbackList;
        
        Test.startTest();
        JobApplicationFeedbackIntegrationService.updateJobApplicationMetrics(feedbackList);
        Test.stopTest();
        
        // Verify job application was updated
        Job_Application__c updatedJobApp = [
            SELECT Id, Average_Interview_Rating__c, Total_Interview_Count__c, 
                   Interview_Success_Score__c, Feedback_Summary__c, Next_Steps__c
            FROM Job_Application__c 
            WHERE Id = :jobApp.Id
        ];
        
        System.assertEquals(4.0, updatedJobApp.Average_Interview_Rating__c, 'Average rating should be 4.0');
        System.assertEquals(3, updatedJobApp.Total_Interview_Count__c, 'Interview count should be 3');
        System.assertNotEquals(null, updatedJobApp.Feedback_Summary__c, 'Feedback summary should be generated');
        System.assert(updatedJobApp.Feedback_Summary__c.contains('STRENGTHS'), 'Summary should contain strengths');
        System.assert(updatedJobApp.Feedback_Summary__c.contains('AREAS FOR IMPROVEMENT'), 'Summary should contain improvements');
    }
    
    @isTest
    static void testUpdateJobApplicationStatus_HighRating() {
        // Get test job application
        Job_Application__c jobApp = [SELECT Id FROM Job_Application__c LIMIT 1];
        
        // Create high-rating feedback
        Interview_Feedback__c feedback = InterviewFeedbackTestDataFactory.createInterviewFeedback(
            jobApp.Id, 'Technical', 4.8
        );
        insert feedback;
        
        Test.startTest();
        JobApplicationFeedbackIntegrationService.updateJobApplicationStatus(new List<Interview_Feedback__c>{feedback});
        Test.stopTest();
        
        // Verify status was updated
        Job_Application__c updatedJobApp = [SELECT Id, Status__c FROM Job_Application__c WHERE Id = :jobApp.Id];
        System.assertEquals('Interviewing', updatedJobApp.Status__c, 'Status should be updated to Interviewing');
    }
    
    @isTest
    static void testUpdateJobApplicationStatus_LowRating() {
        // Get test job application
        Job_Application__c jobApp = [SELECT Id FROM Job_Application__c LIMIT 1];
        
        // Create low-rating feedback
        Interview_Feedback__c feedback = InterviewFeedbackTestDataFactory.createInterviewFeedback(
            jobApp.Id, 'Technical', 1.5
        );
        insert feedback;
        
        Test.startTest();
        JobApplicationFeedbackIntegrationService.updateJobApplicationStatus(new List<Interview_Feedback__c>{feedback});
        Test.stopTest();
        
        // Verify status was updated
        Job_Application__c updatedJobApp = [SELECT Id, Status__c FROM Job_Application__c WHERE Id = :jobApp.Id];
        System.assertEquals('Rejected', updatedJobApp.Status__c, 'Status should be updated to Rejected');
    }
    
    @isTest
    static void testCreateFollowUpTasks_HighRating() {
        // Get test job application
        Job_Application__c jobApp = [SELECT Id FROM Job_Application__c LIMIT 1];
        
        // Create high-rating feedback
        Interview_Feedback__c feedback = InterviewFeedbackTestDataFactory.createInterviewFeedback(
            jobApp.Id, 'Technical', 4.5
        );
        insert feedback;
        
        Test.startTest();
        JobApplicationFeedbackIntegrationService.createFollowUpTasks(new List<Interview_Feedback__c>{feedback});
        Test.stopTest();
        
        // Verify task was created
        List<Task> createdTasks = [SELECT Id, Subject, Priority, WhatId FROM Task WHERE WhatId = :jobApp.Id];
        System.assertEquals(1, createdTasks.size(), 'One task should be created');
        System.assertEquals('High', createdTasks[0].Priority, 'Task should have high priority');
        System.assert(createdTasks[0].Subject.contains('positive'), 'Task subject should mention positive feedback');
    }
    
    @isTest
    static void testCreateFollowUpTasks_LowRating() {
        // Get test job application
        Job_Application__c jobApp = [SELECT Id FROM Job_Application__c LIMIT 1];
        
        // Create low-rating feedback
        Interview_Feedback__c feedback = InterviewFeedbackTestDataFactory.createInterviewFeedback(
            jobApp.Id, 'Technical', 2.0
        );
        insert feedback;
        
        Test.startTest();
        JobApplicationFeedbackIntegrationService.createFollowUpTasks(new List<Interview_Feedback__c>{feedback});
        Test.stopTest();
        
        // Verify task was created
        List<Task> createdTasks = [SELECT Id, Subject, Priority, WhatId FROM Task WHERE WhatId = :jobApp.Id];
        System.assertEquals(1, createdTasks.size(), 'One task should be created');
        System.assertEquals('High', createdTasks[0].Priority, 'Task should have high priority');
        System.assert(createdTasks[0].Subject.contains('Review'), 'Task subject should mention review');
    }
    
    @isTest
    static void testCreateFollowUpTasks_MediumRating() {
        // Get test job application
        Job_Application__c jobApp = [SELECT Id FROM Job_Application__c LIMIT 1];
        
        // Create medium-rating feedback
        Interview_Feedback__c feedback = InterviewFeedbackTestDataFactory.createInterviewFeedback(
            jobApp.Id, 'Technical', 3.5
        );
        insert feedback;
        
        Test.startTest();
        JobApplicationFeedbackIntegrationService.createFollowUpTasks(new List<Interview_Feedback__c>{feedback});
        Test.stopTest();
        
        // Verify task was created
        List<Task> createdTasks = [SELECT Id, Subject, Priority, WhatId FROM Task WHERE WhatId = :jobApp.Id];
        System.assertEquals(1, createdTasks.size(), 'One task should be created');
        System.assertEquals('Normal', createdTasks[0].Priority, 'Task should have normal priority');
        System.assert(createdTasks[0].Subject.contains('Address'), 'Task subject should mention addressing feedback');
    }
    
    @isTest
    static void testBulkOperations() {
        // Get test job applications
        List<Job_Application__c> jobApps = [SELECT Id FROM Job_Application__c];
        
        // Create bulk feedback records
        List<Interview_Feedback__c> feedbackList = new List<Interview_Feedback__c>();
        
        for (Job_Application__c jobApp : jobApps) {
            for (Integer i = 1; i <= 5; i++) {
                Interview_Feedback__c feedback = InterviewFeedbackTestDataFactory.createInterviewFeedback(
                    jobApp.Id, 'Technical', 3.0 + (Math.mod(i, 3) * 0.5)
                );
                feedback.Interview_Date__c = DateTime.now().addDays(-i);
                feedbackList.add(feedback);
            }
        }
        
        insert feedbackList;
        
        Test.startTest();
        JobApplicationFeedbackIntegrationService.updateJobApplicationMetrics(feedbackList);
        JobApplicationFeedbackIntegrationService.updateJobApplicationStatus(feedbackList);
        JobApplicationFeedbackIntegrationService.createFollowUpTasks(feedbackList);
        Test.stopTest();
        
        // Verify all job applications were updated
        List<Job_Application__c> updatedJobApps = [
            SELECT Id, Average_Interview_Rating__c, Total_Interview_Count__c
            FROM Job_Application__c
            WHERE Id IN :jobApps
        ];
        
        for (Job_Application__c jobApp : updatedJobApps) {
            System.assertEquals(5, jobApp.Total_Interview_Count__c, 'Each job app should have 5 interviews');
            System.assertNotEquals(null, jobApp.Average_Interview_Rating__c, 'Average rating should be calculated');
        }
        
        // Verify tasks were created
        List<Task> createdTasks = [SELECT Id, WhatId FROM Task WHERE WhatId IN :jobApps];
        System.assertEquals(15, createdTasks.size(), 'Should create 15 tasks (5 per job app)');
    }
    
    @isTest
    static void testErrorHandling_InvalidJobApplication() {
        // Create feedback with invalid job application ID
        Interview_Feedback__c feedback = new Interview_Feedback__c(
            Job_Application__c = null,
            Interview_Type__c = 'Technical',
            Overall_Rating__c = 4.0,
            Interview_Date__c = DateTime.now()
        );
        
        Test.startTest();
        // Should not throw exception with null job application
        JobApplicationFeedbackIntegrationService.updateJobApplicationMetrics(new List<Interview_Feedback__c>{feedback});
        JobApplicationFeedbackIntegrationService.updateJobApplicationStatus(new List<Interview_Feedback__c>{feedback});
        JobApplicationFeedbackIntegrationService.createFollowUpTasks(new List<Interview_Feedback__c>{feedback});
        Test.stopTest();
        
        // No assertions needed - just verify no exceptions are thrown
        System.assert(true, 'Methods should handle null job application gracefully');
    }
    
    @isTest
    static void testErrorHandling_EmptyList() {
        Test.startTest();
        // Should handle empty lists gracefully
        JobApplicationFeedbackIntegrationService.updateJobApplicationMetrics(new List<Interview_Feedback__c>());
        JobApplicationFeedbackIntegrationService.updateJobApplicationStatus(new List<Interview_Feedback__c>());
        JobApplicationFeedbackIntegrationService.createFollowUpTasks(new List<Interview_Feedback__c>());
        
        // Should handle null lists gracefully
        JobApplicationFeedbackIntegrationService.updateJobApplicationMetrics(null);
        JobApplicationFeedbackIntegrationService.updateJobApplicationStatus(null);
        JobApplicationFeedbackIntegrationService.createFollowUpTasks(null);
        Test.stopTest();
        
        System.assert(true, 'Methods should handle empty and null lists gracefully');
    }
    
    @isTest
    static void testSuccessScoreCalculation() {
        // Get test job application
        Job_Application__c jobApp = [SELECT Id FROM Job_Application__c LIMIT 1];
        
        // Create feedback with improving trend
        List<Interview_Feedback__c> feedbackList = new List<Interview_Feedback__c>();
        
        // Older feedback with lower rating
        Interview_Feedback__c oldFeedback = InterviewFeedbackTestDataFactory.createInterviewFeedback(
            jobApp.Id, 'Technical', 3.0
        );
        oldFeedback.Interview_Date__c = DateTime.now().addDays(-5);
        feedbackList.add(oldFeedback);
        
        // Recent feedback with higher rating
        Interview_Feedback__c recentFeedback = InterviewFeedbackTestDataFactory.createInterviewFeedback(
            jobApp.Id, 'Behavioral', 4.5
        );
        recentFeedback.Interview_Date__c = DateTime.now().addDays(-1);
        feedbackList.add(recentFeedback);
        
        insert feedbackList;
        
        Test.startTest();
        JobApplicationFeedbackIntegrationService.updateJobApplicationMetrics(feedbackList);
        Test.stopTest();
        
        // Verify success score reflects improvement trend
        Job_Application__c updatedJobApp = [
            SELECT Id, Interview_Success_Score__c, Average_Interview_Rating__c
            FROM Job_Application__c 
            WHERE Id = :jobApp.Id
        ];
        
        System.assertNotEquals(null, updatedJobApp.Interview_Success_Score__c, 'Success score should be calculated');
        // Success score should be higher than simple average due to recent improvement
        Decimal expectedSimpleScore = updatedJobApp.Average_Interview_Rating__c * 20;
        System.assert(updatedJobApp.Interview_Success_Score__c >= expectedSimpleScore, 
                     'Success score should account for improvement trend');
    }
}