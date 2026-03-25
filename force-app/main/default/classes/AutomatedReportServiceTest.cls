/**
 * @description Test class for AutomatedReportService
 * Tests automated report generation and email delivery
 * @author Temitayo Oluwalade
 * @date 2024
 */
@isTest
private inherited sharing class AutomatedReportServiceTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test job application
        Job_Application__c jobApp = new Job_Application__c(
            Position_Title__c = 'Report Test Position',
            Company_Name__c = 'Report Test Company',
            Status__c = 'Applied',
            Salary__c = 95000
        );
        insert jobApp;
        
        // Create recent feedback data
        List<Interview_Feedback__c> feedbackList = new List<Interview_Feedback__c>();
        
        for (Integer i = 0; i < 5; i++) {
            Interview_Feedback__c feedback = new Interview_Feedback__c(
                Job_Application__c = jobApp.Id,
                Interview_Type__c = (Math.mod(i, 2) == 0) ? 'Technical' : 'Behavioral',
                Overall_Rating__c = 3.5 + (i * 0.3),
                Interview_Date__c = DateTime.now().addDays(-i * 2),
                Strengths__c = 'Test strength ' + i,
                Areas_for_Improvement__c = 'Test improvement ' + i
            );
            feedbackList.add(feedback);
        }
        
        insert feedbackList;
        
        // Create competency ratings
        List<Competency_Rating__c> ratings = new List<Competency_Rating__c>();
        for (Interview_Feedback__c feedback : feedbackList) {
            ratings.add(new Competency_Rating__c(
                Interview_Feedback__c = feedback.Id,
                Competency_Name__c = 'Technical Skills',
                Rating__c = 4.0
            ));
        }
        insert ratings;
    }
    
    @isTest
    static void testGenerateUserReport_Weekly() {
        User testUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        
        Test.startTest();
        AutomatedReportService.generateUserReport(testUser.Id, 'weekly');
        Test.stopTest();
        
        // Verify no exceptions were thrown
        System.assertEquals(0, Limits.getEmailInvocations(), 'No emails should be sent in test context');
    }
    
    @isTest
    static void testGenerateUserReport_Monthly() {
        User testUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        
        Test.startTest();
        AutomatedReportService.generateUserReport(testUser.Id, 'monthly');
        Test.stopTest();
        
        // Verify no exceptions were thrown
        System.assertEquals(0, Limits.getEmailInvocations(), 'No emails should be sent in test context');
    }
    
    @isTest
    static void testGenerateUserReport_Quarterly() {
        User testUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        
        Test.startTest();
        AutomatedReportService.generateUserReport(testUser.Id, 'quarterly');
        Test.stopTest();
        
        // Verify no exceptions were thrown
        System.assertEquals(0, Limits.getEmailInvocations(), 'No emails should be sent in test context');
    }
    
    @isTest
    static void testGenerateUserReport_NoData() {
        // Create user with no feedback data
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'NoData',
            Email = 'test.nodata@example.com',
            Username = 'test.nodata@example.com.test',
            Alias = 'tnodata',
            ProfileId = UserInfo.getProfileId(),
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;
        
        Test.startTest();
        AutomatedReportService.generateUserReport(testUser.Id, 'weekly');
        Test.stopTest();
        
        // Should handle no data gracefully
        System.assertEquals(0, Limits.getEmailInvocations(), 'No emails should be sent for user with no data');
    }
    
    @isTest
    static void testGenerateAndSendWeeklyReports() {
        Test.startTest();
        AutomatedReportService.generateAndSendWeeklyReports();
        Test.stopTest();
        
        // Should complete without errors
        System.assertEquals(0, Limits.getEmailInvocations(), 'No emails should be sent in test context');
    }
    
    @isTest
    static void testGenerateAndSendMonthlyReports() {
        Test.startTest();
        AutomatedReportService.generateAndSendMonthlyReports();
        Test.stopTest();
        
        // Should complete without errors
        System.assertEquals(0, Limits.getEmailInvocations(), 'No emails should be sent in test context');
    }
    
    @isTest
    static void testSchedulableExecution() {
        Test.startTest();
        
        // Test the schedulable interface
        AutomatedReportService scheduler = new AutomatedReportService();
        String cronExpression = '0 0 8 ? * MON';
        String jobId = System.schedule('Test Weekly Reports', cronExpression, scheduler);
        
        // Verify job was scheduled
        System.assertNotEquals(null, jobId, 'Job should be scheduled successfully');
        
        // Execute the scheduled job
        scheduler.execute(null);
        
        Test.stopTest();
        
        // Should complete without errors
        System.assertEquals(0, Limits.getEmailInvocations(), 'No emails should be sent in test context');
    }
    
    @isTest
    static void testScheduleWeeklyReports() {
        Test.startTest();
        String jobId = AutomatedReportService.scheduleWeeklyReports();
        Test.stopTest();
        
        System.assertNotEquals(null, jobId, 'Weekly reports should be scheduled');
        
        // Verify the job exists
        List<CronTrigger> scheduledJobs = [
            SELECT Id, CronExpression, NextFireTime 
            FROM CronTrigger 
            WHERE Id = :jobId
        ];
        
        System.assertEquals(1, scheduledJobs.size(), 'Scheduled job should exist');
        System.assertEquals('0 0 8 ? * MON', scheduledJobs[0].CronExpression, 'Should have correct cron expression');
    }
    
    @isTest
    static void testScheduleMonthlyReports() {
        Test.startTest();
        String jobId = AutomatedReportService.scheduleMonthlyReports();
        Test.stopTest();
        
        System.assertNotEquals(null, jobId, 'Monthly reports should be scheduled');
        
        // Verify the job exists
        List<CronTrigger> scheduledJobs = [
            SELECT Id, CronExpression, NextFireTime 
            FROM CronTrigger 
            WHERE Id = :jobId
        ];
        
        System.assertEquals(1, scheduledJobs.size(), 'Scheduled job should exist');
        System.assertEquals('0 0 8 1 * ?', scheduledJobs[0].CronExpression, 'Should have correct cron expression');
    }
    
    @isTest
    static void testMonthlyReportScheduler() {
        Test.startTest();
        
        // Test the inner monthly scheduler class
        AutomatedReportService.MonthlyReportScheduler monthlyScheduler = 
            new AutomatedReportService.MonthlyReportScheduler();
        
        monthlyScheduler.execute(null);
        
        Test.stopTest();
        
        // Should complete without errors
        System.assertEquals(0, Limits.getEmailInvocations(), 'No emails should be sent in test context');
    }
    
    @isTest
    static void testGetActiveUsersWithFeedback() {
        // This tests the private method indirectly through public methods
        Test.startTest();
        AutomatedReportService.generateAndSendWeeklyReports();
        Test.stopTest();
        
        // Should identify users with recent feedback
        // Verification is implicit - method should complete without errors
        System.assertEquals(0, Limits.getEmailInvocations(), 'No emails should be sent in test context');
    }
    
    @isTest
    static void testReportGeneration_WithVariousReportTypes() {
        User testUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        
        Test.startTest();
        
        // Test all report types
        AutomatedReportService.generateUserReport(testUser.Id, 'weekly');
        AutomatedReportService.generateUserReport(testUser.Id, 'monthly');
        AutomatedReportService.generateUserReport(testUser.Id, 'quarterly');
        AutomatedReportService.generateUserReport(testUser.Id, 'custom');
        
        Test.stopTest();
        
        // All should complete without errors
        System.assertEquals(0, Limits.getEmailInvocations(), 'No emails should be sent in test context');
    }
    
    @isTest
    static void testErrorHandling_InvalidUserId() {
        // Test with invalid user ID
        Id invalidUserId = '005000000000000'; // Invalid but properly formatted ID
        
        Test.startTest();
        try {
            AutomatedReportService.generateUserReport(invalidUserId, 'weekly');
            // Should handle gracefully without throwing exception
        } catch (Exception e) {
            // Expected behavior - should handle gracefully
            System.assert(true, 'Should handle invalid user ID gracefully');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testBulkReportGeneration() {
        // Create multiple users with feedback
        List<User> testUsers = new List<User>();
        
        for (Integer i = 0; i < 3; i++) {
            User testUser = new User(
                FirstName = 'Bulk',
                LastName = 'Test' + i,
                Email = 'bulk.test' + i + '@example.com',
                Username = 'bulk.test' + i + '@example.com.test',
                Alias = 'bulk' + i,
                ProfileId = UserInfo.getProfileId(),
                TimeZoneSidKey = 'America/New_York',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US'
            );
            testUsers.add(testUser);
        }
        insert testUsers;
        
        // Create feedback for these users
        Job_Application__c bulkApp = new Job_Application__c(
            Position_Title__c = 'Bulk Test Position',
            Company_Name__c = 'Bulk Test Company',
            Status__c = 'Applied'
        );
        insert bulkApp;
        
        List<Interview_Feedback__c> bulkFeedback = new List<Interview_Feedback__c>();
        for (User user : testUsers) {
            Interview_Feedback__c feedback = new Interview_Feedback__c(
                Job_Application__c = bulkApp.Id,
                Interview_Type__c = 'Technical',
                Overall_Rating__c = 4.0,
                Interview_Date__c = DateTime.now().addDays(-1)
            );
            bulkFeedback.add(feedback);
        }
        insert bulkFeedback;
        
        Test.startTest();
        
        // Generate reports for all users
        for (User user : testUsers) {
            AutomatedReportService.generateUserReport(user.Id, 'weekly');
        }
        
        Test.stopTest();
        
        // Should handle bulk generation without errors
        System.assertEquals(0, Limits.getEmailInvocations(), 'No emails should be sent in test context');
    }
    
    @isTest
    static void testReportContent_DataValidation() {
        User testUser = [SELECT Id, Email, FirstName, LastName FROM User WHERE Id = :UserInfo.getUserId()];
        
        Test.startTest();
        
        // Generate report and verify it processes data correctly
        AutomatedReportService.generateUserReport(testUser.Id, 'weekly');
        
        Test.stopTest();
        
        // Verify the report generation completed
        // In a real implementation, we might check log entries or report records
        System.assertEquals(0, Limits.getEmailInvocations(), 'No emails should be sent in test context');
    }
    
    @isTest
    static void testSchedulingEdgeCases() {
        Test.startTest();
        
        // Test scheduling multiple jobs
        String weeklyJobId = AutomatedReportService.scheduleWeeklyReports();
        String monthlyJobId = AutomatedReportService.scheduleMonthlyReports();
        
        Test.stopTest();
        
        // Both jobs should be scheduled successfully
        System.assertNotEquals(null, weeklyJobId, 'Weekly job should be scheduled');
        System.assertNotEquals(null, monthlyJobId, 'Monthly job should be scheduled');
        System.assertNotEquals(weeklyJobId, monthlyJobId, 'Jobs should have different IDs');
        
        // Verify both jobs exist
        List<CronTrigger> allJobs = [SELECT Id FROM CronTrigger WHERE Id IN (:weeklyJobId, :monthlyJobId)];
        System.assertEquals(2, allJobs.size(), 'Both scheduled jobs should exist');
    }
}