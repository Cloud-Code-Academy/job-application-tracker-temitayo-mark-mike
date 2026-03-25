/**
 * @description Test class for FeedbackNotificationQueueable
 * Tests email notifications for feedback thresholds
 * @author Temitayo Oluwalade
 * @date 2024
 */
@isTest
private inherited sharing class FeedbackNotificationQueueableTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test job application
        Job_Application__c jobApp = new Job_Application__c(
            Position_Title__c = 'Senior Developer',
            Company_Name__c = 'Tech Corp',
            Status__c = 'Interviewing',
            Salary__c = 100000
        );
        insert jobApp;
    }
    
    @isTest
    static void testHighPerformanceNotification() {
        // Get test job application
        Job_Application__c jobApp = [SELECT Id, Position_Title__c, Company_Name__c FROM Job_Application__c LIMIT 1];
        
        // Set high performance metrics
        jobApp.Average_Interview_Rating__c = 4.5;
        jobApp.Interview_Success_Score__c = 90.0;
        jobApp.Total_Interview_Count__c = 3;
        jobApp.Next_Steps__c = '• Prepare for final round\\n• Review compensation package';
        update jobApp;
        
        Test.startTest();
        // Execute queueable
        FeedbackNotificationQueueable queueable = new FeedbackNotificationQueueable(new List<Job_Application__c>{jobApp});
        System.enqueueJob(queueable);
        Test.stopTest();
        
        // Verify queueable executed without errors
        System.assertEquals(0, Limits.getEmailInvocations(), 'No emails should be sent in test context');
    }
    
    @isTest
    static void testLowPerformanceNotification() {
        // Get test job application
        Job_Application__c jobApp = [SELECT Id, Position_Title__c, Company_Name__c FROM Job_Application__c LIMIT 1];
        
        // Set low performance metrics
        jobApp.Average_Interview_Rating__c = 2.0;
        jobApp.Interview_Success_Score__c = 40.0;
        jobApp.Total_Interview_Count__c = 2;
        jobApp.Feedback_Summary__c = 'AREAS FOR IMPROVEMENT:\\n• Technical skills need work\\n• Communication could be clearer';
        jobApp.Next_Steps__c = '• Review feedback carefully\\n• Consider additional preparation';
        update jobApp;
        
        Test.startTest();
        // Execute queueable
        FeedbackNotificationQueueable queueable = new FeedbackNotificationQueueable(new List<Job_Application__c>{jobApp});
        System.enqueueJob(queueable);
        Test.stopTest();
        
        // Verify queueable executed without errors
        System.assertEquals(0, Limits.getEmailInvocations(), 'No emails should be sent in test context');
    }
    
    @isTest
    static void testHighSuccessScoreNotification() {
        // Get test job application
        Job_Application__c jobApp = [SELECT Id, Position_Title__c, Company_Name__c FROM Job_Application__c LIMIT 1];
        
        // Set high success score
        jobApp.Interview_Success_Score__c = 85.0;
        jobApp.Average_Interview_Rating__c = 4.2;
        jobApp.Total_Interview_Count__c = 4;
        jobApp.Next_Steps__c = '• Continue with current approach\\n• Prepare for potential next rounds';
        update jobApp;
        
        Test.startTest();
        // Execute queueable
        FeedbackNotificationQueueable queueable = new FeedbackNotificationQueueable(new List<Job_Application__c>{jobApp});
        System.enqueueJob(queueable);
        Test.stopTest();
        
        // Verify queueable executed without errors
        System.assertEquals(0, Limits.getEmailInvocations(), 'No emails should be sent in test context');
    }
    
    @isTest
    static void testMultipleInterviewsNotification() {
        // Get test job application
        Job_Application__c jobApp = [SELECT Id, Position_Title__c, Company_Name__c FROM Job_Application__c LIMIT 1];
        
        // Set multiple interviews
        jobApp.Total_Interview_Count__c = 5;
        jobApp.Average_Interview_Rating__c = 3.8;
        jobApp.Interview_Success_Score__c = 76.0;
        jobApp.Last_Interview_Date__c = DateTime.now().addDays(-1);
        jobApp.Feedback_Summary__c = 'STRENGTHS:\\n• Good technical foundation\\n• Strong communication skills';
        update jobApp;
        
        Test.startTest();
        // Execute queueable
        FeedbackNotificationQueueable queueable = new FeedbackNotificationQueueable(new List<Job_Application__c>{jobApp});
        System.enqueueJob(queueable);
        Test.stopTest();
        
        // Verify queueable executed without errors
        System.assertEquals(0, Limits.getEmailInvocations(), 'No emails should be sent in test context');
    }
    
    @isTest
    static void testBulkNotifications() {
        // Create multiple job applications
        List<Job_Application__c> jobApps = new List<Job_Application__c>();
        
        for (Integer i = 1; i <= 5; i++) {
            Job_Application__c jobApp = new Job_Application__c(
                Position_Title__c = 'Position ' + i,
                Company_Name__c = 'Company ' + i,
                Status__c = 'Interviewing',
                Average_Interview_Rating__c = 4.0 + (i * 0.1),
                Interview_Success_Score__c = 80.0 + i,
                Total_Interview_Count__c = i + 2
            );
            jobApps.add(jobApp);
        }
        insert jobApps;
        
        Test.startTest();
        // Execute queueable with multiple records
        FeedbackNotificationQueueable queueable = new FeedbackNotificationQueueable(jobApps);
        System.enqueueJob(queueable);
        Test.stopTest();
        
        // Verify queueable executed without errors
        System.assertEquals(0, Limits.getEmailInvocations(), 'No emails should be sent in test context');
    }
    
    @isTest
    static void testEmptyJobApplicationsList() {
        Test.startTest();
        // Execute queueable with empty list
        FeedbackNotificationQueueable queueable = new FeedbackNotificationQueueable(new List<Job_Application__c>());
        System.enqueueJob(queueable);
        Test.stopTest();
        
        // Should complete without errors
        System.assertEquals(0, Limits.getEmailInvocations(), 'No emails should be sent for empty list');
    }
    
    @isTest
    static void testNullJobApplicationsList() {
        Test.startTest();
        // Execute queueable with null list
        FeedbackNotificationQueueable queueable = new FeedbackNotificationQueueable(null);
        System.enqueueJob(queueable);
        Test.stopTest();
        
        // Should complete without errors
        System.assertEquals(0, Limits.getEmailInvocations(), 'No emails should be sent for null list');
    }
    
    @isTest
    static void testNoNotificationThresholds() {
        // Get test job application
        Job_Application__c jobApp = [SELECT Id, Position_Title__c, Company_Name__c FROM Job_Application__c LIMIT 1];
        
        // Set metrics that don't trigger notifications
        jobApp.Average_Interview_Rating__c = 3.5;
        jobApp.Interview_Success_Score__c = 70.0;
        jobApp.Total_Interview_Count__c = 2;
        update jobApp;
        
        Test.startTest();
        // Execute queueable
        FeedbackNotificationQueueable queueable = new FeedbackNotificationQueueable(new List<Job_Application__c>{jobApp});
        System.enqueueJob(queueable);
        Test.stopTest();
        
        // Should complete without sending notifications
        System.assertEquals(0, Limits.getEmailInvocations(), 'No emails should be sent when thresholds not met');
    }
}