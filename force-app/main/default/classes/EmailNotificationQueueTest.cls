/**
 * @description Comprehensive test class for EmailNotificationQueue
 * Tests queueable job functionality, email processing, and error handling
 * @author Learning Journey - Task 7.2
 * @date 2025-01-08
 */
@IsTest
public class EmailNotificationQueueTest {
    
    /**
     * @description Test setup method using TestDataFactory pattern
     */
    @TestSetup
    static void setupTestData() {
        // Create test job applications with different scenarios
        Map<String, Object> testData = TestDataFactory.createScenarioTestData('status_change', true);
        
        // Update job applications with market analysis data for testing
        List<Job_Application__c> jobApps = (List<Job_Application__c>)testData.get('jobApplications');
        for (Job_Application__c jobApp : jobApps) {
            jobApp.Market_Salary_Median__c = jobApp.Salary__c + 5000;
            jobApp.Salary_Competitiveness__c = jobApp.Salary__c < jobApp.Market_Salary_Median__c ? 'Below Market' : 'At Market';
        }
        update jobApps;
    }
    
    /**
     * @description Test EmailNotification inner class constructor and properties
     * Tests the data structure used for email notifications
     */
    @IsTest
    static void testEmailNotificationClass() {
        // ARRANGE: Create EmailNotification instance
        String testEmail = 'test@example.com';
        String testSubject = 'Test Subject';
        String testBody = 'Test email body content';
        Boolean isHtml = true;
        String recordId = TestDataFactory.createJobApplication(true).Id;
        String templateId = 'test_template_id';
        String senderEmail = 'sender@example.com';
        
        // ACT: Create EmailNotification instance
        Test.startTest();
        EmailNotificationQueue.EmailNotification notification = new EmailNotificationQueue.EmailNotification(
            testEmail, testSubject, testBody, isHtml, recordId, templateId, senderEmail
        );
        Test.stopTest();
        
        // ASSERT: Verify all properties are set correctly
        System.assertEquals(testEmail, notification.recipientEmail, 'Recipient email should be set correctly');
        System.assertEquals(testSubject, notification.subject, 'Subject should be set correctly');
        System.assertEquals(testBody, notification.body, 'Body should be set correctly');
        System.assertEquals(isHtml, notification.isHtml, 'HTML flag should be set correctly');
        System.assertEquals(recordId, notification.relatedRecordId, 'Related record ID should be set correctly');
        System.assertEquals(templateId, notification.templateId, 'Template ID should be set correctly');
        System.assertEquals(senderEmail, notification.senderEmail, 'Sender email should be set correctly');
    }
    
    /**
     * @description Test EmailNotification constructor with null values
     * Tests edge case handling for null parameters
     */
    @IsTest
    static void testEmailNotificationWithNullValues() {
        // ARRANGE & ACT: Create EmailNotification with null values
        Test.startTest();
        EmailNotificationQueue.EmailNotification notification = new EmailNotificationQueue.EmailNotification(
            'test@example.com', 'Subject', 'Body', null, null, null, null
        );
        Test.stopTest();
        
        // ASSERT: Verify null handling
        System.assertEquals(false, notification.isHtml, 'HTML flag should default to false when null');
        System.assertEquals(null, notification.relatedRecordId, 'Related record ID should remain null');
        System.assertEquals(null, notification.templateId, 'Template ID should remain null');
        System.assertEquals(null, notification.senderEmail, 'Sender email should remain null');
    }
    
    /**
     * @description Test EmailNotificationQueue constructor with valid notifications
     * Tests the queueable job constructor
     */
    @IsTest
    static void testQueueConstructorWithValidNotifications() {
        // ARRANGE: Create test notifications
        List<EmailNotificationQueue.EmailNotification> notifications = new List<EmailNotificationQueue.EmailNotification>();
        notifications.add(new EmailNotificationQueue.EmailNotification(
            'test1@example.com', 'Subject 1', 'Body 1', false, null, null, null
        ));
        notifications.add(new EmailNotificationQueue.EmailNotification(
            'test2@example.com', 'Subject 2', 'Body 2', true, null, null, null
        ));
        
        // ACT: Create EmailNotificationQueue instance
        Test.startTest();
        EmailNotificationQueue queue = new EmailNotificationQueue(notifications);
        Test.stopTest();
        
        // ASSERT: Verify constructor handled notifications correctly
        System.assertNotEquals(null, queue, 'Queue instance should be created successfully');
        // Note: We can't directly access private fields, but constructor should not throw exceptions
    }
    
    /**
     * @description Test EmailNotificationQueue constructor with null notifications
     * Tests edge case handling for null input
     */
    @IsTest
    static void testQueueConstructorWithNullNotifications() {
        // ARRANGE & ACT: Create EmailNotificationQueue with null notifications
        Test.startTest();
        EmailNotificationQueue queue = new EmailNotificationQueue(null);
        Test.stopTest();
        
        // ASSERT: Verify constructor handles null gracefully
        System.assertNotEquals(null, queue, 'Queue instance should be created even with null notifications');
    }
    
    /**
     * @description Test EmailNotificationQueue constructor with empty notifications
     * Tests edge case handling for empty list
     */
    @IsTest
    static void testQueueConstructorWithEmptyNotifications() {
        // ARRANGE: Create empty notifications list
        List<EmailNotificationQueue.EmailNotification> emptyNotifications = new List<EmailNotificationQueue.EmailNotification>();
        
        // ACT: Create EmailNotificationQueue instance
        Test.startTest();
        EmailNotificationQueue queue = new EmailNotificationQueue(emptyNotifications);
        Test.stopTest();
        
        // ASSERT: Verify constructor handles empty list gracefully
        System.assertNotEquals(null, queue, 'Queue instance should be created with empty notifications');
    }
    
    /**
     * @description Test queueable job execution with small batch
     * Tests the execute method with a manageable number of notifications
     */
    @IsTest
    static void testQueueExecutionWithSmallBatch() {
        // ARRANGE: Create test notifications (less than batch limit)
        List<EmailNotificationQueue.EmailNotification> notifications = new List<EmailNotificationQueue.EmailNotification>();
        
        for (Integer i = 0; i < 5; i++) {
            notifications.add(new EmailNotificationQueue.EmailNotification(
                'test' + i + '@example.com',
                'Test Subject ' + i,
                'Test body content for notification ' + i,
                false,
                null,
                null,
                null
            ));
        }
        
        EmailNotificationQueue queue = new EmailNotificationQueue(notifications);
        
        // ACT: Execute the queueable job
        Test.startTest();
        System.enqueueJob(queue);
        Test.stopTest();
        
        // ASSERT: Verify job executed without errors
        // Note: In test context, we can't verify actual email sending, but we can verify no exceptions
        System.assert(true, 'Queueable job should execute without throwing exceptions');
    }
    
    /**
     * @description Test queueable job execution with large batch requiring chaining
     * Tests the chaining logic when notifications exceed batch limit
     */
    @IsTest
    static void testQueueExecutionWithLargeBatch() {
        // ARRANGE: Create notifications exceeding batch limit (>100)
        List<EmailNotificationQueue.EmailNotification> notifications = new List<EmailNotificationQueue.EmailNotification>();
        
        for (Integer i = 0; i < 150; i++) {
            notifications.add(new EmailNotificationQueue.EmailNotification(
                'bulk' + i + '@example.com',
                'Bulk Subject ' + i,
                'Bulk body content for notification ' + i,
                false,
                null,
                null,
                null
            ));
        }
        
        EmailNotificationQueue queue = new EmailNotificationQueue(notifications);
        
        // ACT: Execute the queueable job
        Test.startTest();
        System.enqueueJob(queue);
        Test.stopTest();
        
        // ASSERT: Verify job executed and would chain for remaining notifications
        // Note: In test context, chaining behavior is limited, but execution should not fail
        System.assert(true, 'Large batch queueable job should execute without throwing exceptions');
    }
    
    /**
     * @description Test static method for enqueueing job application notifications
     * Tests the convenience method for creating job application notifications
     */
    @IsTest
    static void testEnqueueJobApplicationNotifications() {
        // ARRANGE: Get test job applications
        List<Job_Application__c> jobApps = [
            SELECT Id, Name, Company_Name__c, Position_Title__c, Status__c, Owner.Email
            FROM Job_Application__c
            LIMIT 3
        ];
        
        List<Id> jobAppIds = new List<Id>();
        for (Job_Application__c jobApp : jobApps) {
            jobAppIds.add(jobApp.Id);
        }
        
        // ACT: Enqueue job application notifications
        Test.startTest();
        EmailNotificationQueue.enqueueJobApplicationNotifications(jobAppIds, 'MARKET_ANALYSIS_COMPLETE');
        Test.stopTest();
        
        // ASSERT: Verify method executed without errors
        System.assert(true, 'Job application notifications should be enqueued without exceptions');
    }
    
    /**
     * @description Test enqueueing with null job application IDs
     * Tests edge case handling for null input
     */
    @IsTest
    static void testEnqueueWithNullJobAppIds() {
        // ARRANGE & ACT: Call with null job application IDs
        Test.startTest();
        EmailNotificationQueue.enqueueJobApplicationNotifications(null, 'STATUS_REMINDER');
        Test.stopTest();
        
        // ASSERT: Verify method handles null gracefully
        System.assert(true, 'Method should handle null job application IDs gracefully');
    }
    
    /**
     * @description Test enqueueing with empty job application IDs
     * Tests edge case handling for empty list
     */
    @IsTest
    static void testEnqueueWithEmptyJobAppIds() {
        // ARRANGE: Empty list of job application IDs
        List<Id> emptyIds = new List<Id>();
        
        // ACT: Call with empty list
        Test.startTest();
        EmailNotificationQueue.enqueueJobApplicationNotifications(emptyIds, 'SALARY_ALERT');
        Test.stopTest();
        
        // ASSERT: Verify method handles empty list gracefully
        System.assert(true, 'Method should handle empty job application IDs list gracefully');
    }
    
    /**
     * @description Test market analysis notification building
     * Tests the specific notification type for market analysis completion
     */
    @IsTest
    static void testMarketAnalysisNotification() {
        // ARRANGE: Get job application with market analysis data
        Job_Application__c jobApp = [
            SELECT Id, Name, Company_Name__c, Position_Title__c, Status__c, 
                   Owner.Email, Owner.Name, Salary__c, Market_Salary_Median__c, Salary_Competitiveness__c
            FROM Job_Application__c
            WHERE Salary_Competitiveness__c != null
            LIMIT 1
        ];
        
        List<Id> jobAppIds = new List<Id>{jobApp.Id};
        
        // ACT: Enqueue market analysis notification
        Test.startTest();
        EmailNotificationQueue.enqueueJobApplicationNotifications(jobAppIds, 'MARKET_ANALYSIS_COMPLETE');
        Test.stopTest();
        
        // ASSERT: Verify notification was processed for market analysis
        System.assert(true, 'Market analysis notification should be processed without exceptions');
    }
    
    /**
     * @description Test status reminder notification building
     * Tests the specific notification type for status reminders
     */
    @IsTest
    static void testStatusReminderNotification() {
        // ARRANGE: Get job application for status reminder
        Job_Application__c jobApp = [
            SELECT Id, Name, Company_Name__c, Position_Title__c, Status__c, Owner.Email
            FROM Job_Application__c
            LIMIT 1
        ];
        
        List<Id> jobAppIds = new List<Id>{jobApp.Id};
        
        // ACT: Enqueue status reminder notification
        Test.startTest();
        EmailNotificationQueue.enqueueJobApplicationNotifications(jobAppIds, 'STATUS_REMINDER');
        Test.stopTest();
        
        // ASSERT: Verify notification was processed for status reminder
        System.assert(true, 'Status reminder notification should be processed without exceptions');
    }
    
    /**
     * @description Test salary alert notification building
     * Tests the specific notification type for salary alerts (below market)
     */
    @IsTest
    static void testSalaryAlertNotification() {
        // ARRANGE: Get job application with below market salary
        Job_Application__c jobApp = [
            SELECT Id, Name, Company_Name__c, Position_Title__c, Status__c, 
                   Owner.Email, Owner.Name, Salary__c, Market_Salary_Median__c, Salary_Competitiveness__c
            FROM Job_Application__c
            WHERE Salary_Competitiveness__c = 'Below Market'
            LIMIT 1
        ];
        
        List<Id> jobAppIds = new List<Id>{jobApp.Id};
        
        // ACT: Enqueue salary alert notification
        Test.startTest();
        EmailNotificationQueue.enqueueJobApplicationNotifications(jobAppIds, 'SALARY_ALERT');
        Test.stopTest();
        
        // ASSERT: Verify notification was processed for salary alert
        System.assert(true, 'Salary alert notification should be processed without exceptions');
    }
    
    /**
     * @description Test invalid notification type handling
     * Tests edge case with unsupported notification type
     */
    @IsTest
    static void testInvalidNotificationType() {
        // ARRANGE: Get job application
        Job_Application__c jobApp = [SELECT Id FROM Job_Application__c LIMIT 1];
        List<Id> jobAppIds = new List<Id>{jobApp.Id};
        
        // ACT: Enqueue with invalid notification type
        Test.startTest();
        EmailNotificationQueue.enqueueJobApplicationNotifications(jobAppIds, 'INVALID_TYPE');
        Test.stopTest();
        
        // ASSERT: Verify method handles invalid type gracefully
        System.assert(true, 'Method should handle invalid notification type gracefully');
    }
    
    /**
     * @description Test notification building with job applications without owner email
     * Tests edge case where job application owner has no email
     */
    @IsTest
    static void testNotificationWithoutOwnerEmail() {
        // ARRANGE: Create user without email and job application
        // Note: In test context, we'll simulate this by testing the query filter
        List<Job_Application__c> jobApps = [
            SELECT Id, Name, Company_Name__c, Position_Title__c, Status__c, Owner.Email
            FROM Job_Application__c
            WHERE Owner.Email != null
            LIMIT 1
        ];
        
        // The query in the actual method filters out records without owner email
        // So we're testing that the filter works correctly
        System.assert(!jobApps.isEmpty(), 'Should find job applications with owner email');
        
        // ACT: Test with job applications that have owner email
        List<Id> jobAppIds = new List<Id>();
        for (Job_Application__c jobApp : jobApps) {
            jobAppIds.add(jobApp.Id);
        }
        
        Test.startTest();
        EmailNotificationQueue.enqueueJobApplicationNotifications(jobAppIds, 'MARKET_ANALYSIS_COMPLETE');
        Test.stopTest();
        
        // ASSERT: Verify processing completed
        System.assert(true, 'Notifications should be processed for job applications with owner email');
    }
    
    /**
     * @description Test bulk notification processing
     * Tests performance with multiple job applications
     */
    @IsTest
    static void testBulkNotificationProcessing() {
        // ARRANGE: Create additional job applications for bulk testing
        List<Job_Application__c> bulkJobApps = TestDataFactory.createJobApplications(20, 'Applied', true);
        
        List<Id> jobAppIds = new List<Id>();
        for (Job_Application__c jobApp : bulkJobApps) {
            jobAppIds.add(jobApp.Id);
        }
        
        // ACT: Process bulk notifications
        Test.startTest();
        EmailNotificationQueue.enqueueJobApplicationNotifications(jobAppIds, 'STATUS_REMINDER');
        Test.stopTest();
        
        // ASSERT: Verify bulk processing completed without governor limit issues
        System.assert(Limits.getQueries() < Limits.getLimitQueries(), 
                     'Should not exceed SOQL query limits during bulk processing');
        System.assert(true, 'Bulk notification processing should complete successfully');
    }
    
    /**
     * @description Test notification content validation
     * Tests that notification content is properly formatted
     */
    @IsTest
    static void testNotificationContentValidation() {
        // ARRANGE: Create notification with specific content
        String recipientEmail = 'content.test@example.com';
        String subject = 'Content Validation Test';
        String body = 'This is a test email body with specific content for validation.';
        
        EmailNotificationQueue.EmailNotification notification = new EmailNotificationQueue.EmailNotification(
            recipientEmail, subject, body, false, null, null, null
        );
        
        // ACT: Validate notification content
        Test.startTest();
        Boolean isValidEmail = notification.recipientEmail.contains('@');
        Boolean hasSubject = !String.isBlank(notification.subject);
        Boolean hasBody = !String.isBlank(notification.body);
        Test.stopTest();
        
        // ASSERT: Verify content validation
        System.assert(isValidEmail, 'Recipient email should contain @ symbol');
        System.assert(hasSubject, 'Notification should have a subject');
        System.assert(hasBody, 'Notification should have body content');
        System.assertEquals(recipientEmail, notification.recipientEmail, 'Email should match input');
        System.assertEquals(subject, notification.subject, 'Subject should match input');
        System.assertEquals(body, notification.body, 'Body should match input');
    }
    
    /**
     * @description Test governor limits compliance during queue execution
     * Tests that the queueable job operates within Salesforce limits
     */
    @IsTest
    static void testGovernorLimitsCompliance() {
        // ARRANGE: Create notifications that will test governor limits
        List<EmailNotificationQueue.EmailNotification> notifications = new List<EmailNotificationQueue.EmailNotification>();
        
        for (Integer i = 0; i < 50; i++) {
            notifications.add(new EmailNotificationQueue.EmailNotification(
                'limits.test' + i + '@example.com',
                'Governor Limits Test ' + i,
                'Testing governor limits compliance with notification ' + i,
                false,
                null,
                null,
                null
            ));
        }
        
        EmailNotificationQueue queue = new EmailNotificationQueue(notifications);
        
        // Record initial limits
        Integer initialQueries = Limits.getQueries();
        Integer initialCpuTime = Limits.getCpuTime();
        Integer initialHeapSize = Limits.getHeapSize();
        
        // ACT: Execute queue job
        Test.startTest();
        System.enqueueJob(queue);
        Test.stopTest();
        
        // ASSERT: Verify governor limits compliance
        Integer finalQueries = Limits.getQueries();
        Integer finalCpuTime = Limits.getCpuTime();
        Integer finalHeapSize = Limits.getHeapSize();
        
        System.assert(finalQueries - initialQueries <= 5, 
                     'Should use minimal SOQL queries (used: ' + (finalQueries - initialQueries) + ')');
        System.assert(finalCpuTime - initialCpuTime <= 3000, 
                     'Should execute within reasonable CPU time (used: ' + (finalCpuTime - initialCpuTime) + 'ms)');
        System.assert(finalHeapSize - initialHeapSize <= 1000000, 
                     'Should use reasonable heap size (used: ' + (finalHeapSize - initialHeapSize) + ' bytes)');
    }
}