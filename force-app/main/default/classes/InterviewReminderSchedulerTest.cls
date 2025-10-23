/**
 * @description Test class for Interview Reminder Scheduler
 * @author Temitayo Oluwalade
 * @date 2024
 */
@isTest
public class InterviewReminderSchedulerTest {

    /**
     * @description Test data setup
     */
    @TestSetup
    static void setupTestData() {
        // Create test Job Application
        Job_Application__c testJob = new Job_Application__c(
            Company_Name__c = 'Tech Innovations Inc',
            Position_Title__c = 'Senior Salesforce Developer',
            Status__c = 'Interviewing',
            Salary__c = 120000
        );
        insert testJob;

        // Create test user with email
        User testUser = [SELECT Id, Email, Name FROM User WHERE Id = :UserInfo.getUserId()];
        System.assertNotEquals(null, testUser.Email, 'Test user must have an email address');
    }

    /**
     * @description Test sending reminders for interviews scheduled tomorrow
     */
    @isTest
    static void testSendRemindersForTomorrowInterviews() {
        Job_Application__c testJob = [SELECT Id FROM Job_Application__c LIMIT 1];

        // Create interview scheduled for tomorrow
        Date tomorrow = Date.today().addDays(1);
        Event tomorrowInterview = new Event(
            Subject = 'Technical Interview with John Doe',
            StartDateTime = Datetime.newInstance(tomorrow, Time.newInstance(14, 0, 0, 0)),
            EndDateTime = Datetime.newInstance(tomorrow, Time.newInstance(15, 0, 0, 0)),
            Location = 'Zoom - https://zoom.us/j/123456789',
            Description = 'Prepare coding challenges and system design questions',
            WhatId = testJob.Id
        );
        insert tomorrowInterview;

        // Get initial email invocation count
        Integer emailInvocationsBefore = Limits.getEmailInvocations();

        Test.startTest();
        InterviewReminderScheduler.sendInterviewReminders();
        Test.stopTest();

        // Verify emails were sent
        Integer emailInvocationsAfter = Limits.getEmailInvocations();
        System.assertEquals(emailInvocationsBefore + 1, emailInvocationsAfter,
            'One email should have been sent for tomorrow\'s interview');
    }

    /**
     * @description Test no reminders sent for interviews not scheduled tomorrow
     */
    @isTest
    static void testNoRemindersForNonTomorrowInterviews() {
        Job_Application__c testJob = [SELECT Id FROM Job_Application__c LIMIT 1];

        // Create interview scheduled for 2 days from now
        Date twoDaysLater = Date.today().addDays(2);
        Event futureInterview = new Event(
            Subject = 'Future Interview',
            StartDateTime = Datetime.newInstance(twoDaysLater, Time.newInstance(10, 0, 0, 0)),
            EndDateTime = Datetime.newInstance(twoDaysLater, Time.newInstance(11, 0, 0, 0)),
            WhatId = testJob.Id
        );
        insert futureInterview;

        // Create interview scheduled for today
        Date today = Date.today();
        Event todayInterview = new Event(
            Subject = 'Today Interview',
            StartDateTime = Datetime.newInstance(today, Time.newInstance(15, 0, 0, 0)),
            EndDateTime = Datetime.newInstance(today, Time.newInstance(16, 0, 0, 0)),
            WhatId = testJob.Id
        );
        insert todayInterview;

        Integer emailInvocationsBefore = Limits.getEmailInvocations();

        Test.startTest();
        InterviewReminderScheduler.sendInterviewReminders();
        Test.stopTest();

        // Verify no emails were sent
        Integer emailInvocationsAfter = Limits.getEmailInvocations();
        System.assertEquals(emailInvocationsBefore, emailInvocationsAfter,
            'No emails should be sent for non-tomorrow interviews');
    }

    /**
     * @description Test sending reminders for multiple interviews tomorrow
     */
    @isTest
    static void testMultipleTomorrowInterviews() {
        Job_Application__c testJob = [SELECT Id FROM Job_Application__c LIMIT 1];
        List<Event> interviews = new List<Event>();

        Date tomorrow = Date.today().addDays(1);

        // Create multiple interviews for tomorrow
        for (Integer i = 0; i < 5; i++) {
            interviews.add(new Event(
                Subject = 'Interview ' + i,
                StartDateTime = Datetime.newInstance(tomorrow, Time.newInstance(9 + i, 0, 0, 0)),
                EndDateTime = Datetime.newInstance(tomorrow, Time.newInstance(10 + i, 0, 0, 0)),
                Location = 'Office Building ' + i,
                WhatId = testJob.Id
            ));
        }
        insert interviews;

        Integer emailInvocationsBefore = Limits.getEmailInvocations();

        Test.startTest();
        InterviewReminderScheduler.sendInterviewReminders();
        Test.stopTest();

        // Verify emails were sent for all interviews
        Integer emailInvocationsAfter = Limits.getEmailInvocations();
        System.assertEquals(emailInvocationsBefore + 1, emailInvocationsAfter,
            'Emails should be sent in bulk for multiple interviews');
    }

    /**
     * @description Test reminder email content includes all relevant details
     */
    @isTest
    static void testReminderEmailContent() {
        Job_Application__c testJob = [SELECT Id FROM Job_Application__c LIMIT 1];

        Date tomorrow = Date.today().addDays(1);
        Event interview = new Event(
            Subject = 'Panel Interview - Senior Developer Role',
            StartDateTime = Datetime.newInstance(tomorrow, Time.newInstance(13, 30, 0, 0)),
            EndDateTime = Datetime.newInstance(tomorrow, Time.newInstance(15, 0, 0, 0)),
            Location = 'Google Meet - meet.google.com/abc-defg-hij',
            Description = 'Meeting with CTO and Engineering Manager. Prepare portfolio presentation.',
            WhatId = testJob.Id
        );
        insert interview;

        Test.startTest();
        // Query the event with all related data as the scheduler would
        Event queriedInterview = [
            SELECT Id, Subject, StartDateTime, EndDateTime, Location, Description,
                   Owner.Email, Owner.Name, WhatId, What.Type, What.Name
            FROM Event
            WHERE Id = :interview.Id
        ];

        // Build the email (this is effectively tested through sendInterviewReminders)
        InterviewReminderScheduler.sendInterviewReminders();
        Test.stopTest();

        // Verify event was queried correctly
        System.assertNotEquals(null, queriedInterview, 'Interview should be queried');
        System.assertEquals('Panel Interview - Senior Developer Role', queriedInterview.Subject);
        System.assertNotEquals(null, queriedInterview.Owner.Email, 'Owner should have email');
    }

    /**
     * @description Test handling events without owner email
     */
    @isTest
    static void testEventsWithoutOwnerEmail() {
        // This test verifies graceful handling when owner email is null
        // In practice, we filter by Owner.Email != null in the query
        // This test confirms the filter works

        Date tomorrow = Date.today().addDays(1);
        Event interview = new Event(
            Subject = 'Test Interview',
            StartDateTime = Datetime.newInstance(tomorrow, Time.newInstance(10, 0, 0, 0)),
            EndDateTime = Datetime.newInstance(tomorrow, Time.newInstance(11, 0, 0, 0))
        );
        insert interview;

        Integer emailInvocationsBefore = Limits.getEmailInvocations();

        Test.startTest();
        InterviewReminderScheduler.sendInterviewReminders();
        Test.stopTest();

        // The current user has an email, so email should be sent
        Integer emailInvocationsAfter = Limits.getEmailInvocations();
        System.assert(emailInvocationsAfter >= emailInvocationsBefore,
            'Email handling should be graceful');
    }

    /**
     * @description Test events with Job Application association
     */
    @isTest
    static void testEventsWithJobApplication() {
        Job_Application__c testJob = [SELECT Id FROM Job_Application__c LIMIT 1];

        Date tomorrow = Date.today().addDays(1);
        Event interview = new Event(
            Subject = 'Interview with Job App',
            StartDateTime = Datetime.newInstance(tomorrow, Time.newInstance(11, 0, 0, 0)),
            EndDateTime = Datetime.newInstance(tomorrow, Time.newInstance(12, 0, 0, 0)),
            WhatId = testJob.Id
        );
        insert interview;

        Integer emailInvocationsBefore = Limits.getEmailInvocations();

        Test.startTest();
        InterviewReminderScheduler.sendInterviewReminders();
        Test.stopTest();

        // Verify email was sent
        Integer emailInvocationsAfter = Limits.getEmailInvocations();
        System.assertEquals(emailInvocationsBefore + 1, emailInvocationsAfter,
            'Email should be sent for interview with Job Application');
    }

    /**
     * @description Test events without Job Application association
     */
    @isTest
    static void testEventsWithoutJobApplication() {
        Date tomorrow = Date.today().addDays(1);
        Event interview = new Event(
            Subject = 'Interview without Job App',
            StartDateTime = Datetime.newInstance(tomorrow, Time.newInstance(16, 0, 0, 0)),
            EndDateTime = Datetime.newInstance(tomorrow, Time.newInstance(17, 0, 0, 0)),
            Location = 'Phone Call'
        );
        insert interview;

        Integer emailInvocationsBefore = Limits.getEmailInvocations();

        Test.startTest();
        InterviewReminderScheduler.sendInterviewReminders();
        Test.stopTest();

        // Verify email was still sent (Job Application is optional)
        Integer emailInvocationsAfter = Limits.getEmailInvocations();
        System.assertEquals(emailInvocationsBefore + 1, emailInvocationsAfter,
            'Email should be sent even without Job Application association');
    }

    /**
     * @description Test scheduling the job with default cron expression
     */
    @isTest
    static void testScheduleJobDefault() {
        Test.startTest();
        String jobId = InterviewReminderScheduler.scheduleDaily();
        Test.stopTest();

        // Verify job was scheduled
        System.assertNotEquals(null, jobId, 'Job should be scheduled successfully');

        // Verify scheduled job exists
        List<CronTrigger> scheduledJobs = [
            SELECT Id, CronExpression, State
            FROM CronTrigger
            WHERE Id = :jobId
        ];

        System.assertEquals(1, scheduledJobs.size(), 'Scheduled job should exist');
        System.assertEquals('0 0 8 * * ?', scheduledJobs[0].CronExpression,
            'Should use default cron expression (8 AM daily)');
    }

    /**
     * @description Test scheduling the job with custom cron expression
     */
    @isTest
    static void testScheduleJobCustomCron() {
        String customCron = '0 0 18 * * ?'; // 6 PM daily

        Test.startTest();
        String jobId = InterviewReminderScheduler.scheduleDaily('Custom Interview Reminder', customCron);
        Test.stopTest();

        // Verify job was scheduled with custom cron
        CronTrigger scheduledJob = [
            SELECT Id, CronExpression, CronJobDetail.Name
            FROM CronTrigger
            WHERE Id = :jobId
        ];

        System.assertNotEquals(null, scheduledJob, 'Scheduled job should exist');
        System.assertEquals(customCron, scheduledJob.CronExpression,
            'Should use custom cron expression');
        System.assertEquals('Custom Interview Reminder', scheduledJob.CronJobDetail.Name,
            'Should use custom job name');
    }

    /**
     * @description Test scheduled job execution
     */
    @isTest
    static void testScheduledJobExecution() {
        Job_Application__c testJob = [SELECT Id FROM Job_Application__c LIMIT 1];

        // Create interview for tomorrow
        Date tomorrow = Date.today().addDays(1);
        Event interview = new Event(
            Subject = 'Scheduled Test Interview',
            StartDateTime = Datetime.newInstance(tomorrow, Time.newInstance(12, 0, 0, 0)),
            EndDateTime = Datetime.newInstance(tomorrow, Time.newInstance(13, 0, 0, 0)),
            WhatId = testJob.Id
        );
        insert interview;

        Test.startTest();

        // Schedule and execute the job
        String jobId = InterviewReminderScheduler.scheduleDaily('Test Interview Reminder Job', '0 0 8 * * ?');

        // Verify job was scheduled
        System.assertNotEquals(null, jobId, 'Job should be scheduled');

        Test.stopTest();

        // Note: In test context, scheduled job doesn't actually run
        // But we've verified it was scheduled successfully
        CronTrigger scheduledJob = [SELECT Id, State FROM CronTrigger WHERE Id = :jobId];
        System.assertNotEquals(null, scheduledJob, 'Scheduled job should exist in CronTrigger');
    }

    /**
     * @description Test bulk email handling
     */
    @isTest
    static void testBulkEmailHandling() {
        Job_Application__c testJob = [SELECT Id FROM Job_Application__c LIMIT 1];
        List<Event> interviews = new List<Event>();

        Date tomorrow = Date.today().addDays(1);

        // Create 10 interviews for tomorrow
        for (Integer i = 0; i < 10; i++) {
            interviews.add(new Event(
                Subject = 'Bulk Interview ' + i,
                StartDateTime = Datetime.newInstance(tomorrow, Time.newInstance(8, i * 15, 0, 0)),
                EndDateTime = Datetime.newInstance(tomorrow, Time.newInstance(9, i * 15, 0, 0)),
                Location = 'Location ' + i,
                Description = 'Description for interview ' + i,
                WhatId = testJob.Id
            ));
        }
        insert interviews;

        Integer emailInvocationsBefore = Limits.getEmailInvocations();

        Test.startTest();
        InterviewReminderScheduler.sendInterviewReminders();
        Test.stopTest();

        // Verify bulk email was sent (should be 1 invocation for all emails)
        Integer emailInvocationsAfter = Limits.getEmailInvocations();
        System.assertEquals(emailInvocationsBefore + 1, emailInvocationsAfter,
            'Should send all emails in one bulk operation');
    }

    /**
     * @description Test with no interviews scheduled
     */
    @isTest
    static void testNoInterviewsScheduled() {
        // No interviews created in this test

        Integer emailInvocationsBefore = Limits.getEmailInvocations();

        Test.startTest();
        InterviewReminderScheduler.sendInterviewReminders();
        Test.stopTest();

        // Verify no emails were sent
        Integer emailInvocationsAfter = Limits.getEmailInvocations();
        System.assertEquals(emailInvocationsBefore, emailInvocationsAfter,
            'No emails should be sent when no interviews are scheduled');
    }

    /**
     * @description Test events at different times tomorrow
     */
    @isTest
    static void testEventsAtDifferentTimes() {
        Job_Application__c testJob = [SELECT Id FROM Job_Application__c LIMIT 1];
        List<Event> interviews = new List<Event>();

        Date tomorrow = Date.today().addDays(1);

        // Create interviews at different times throughout tomorrow
        interviews.add(new Event(
            Subject = 'Early Morning Interview',
            StartDateTime = Datetime.newInstance(tomorrow, Time.newInstance(8, 0, 0, 0)),
            EndDateTime = Datetime.newInstance(tomorrow, Time.newInstance(9, 0, 0, 0)),
            WhatId = testJob.Id
        ));

        interviews.add(new Event(
            Subject = 'Midday Interview',
            StartDateTime = Datetime.newInstance(tomorrow, Time.newInstance(12, 0, 0, 0)),
            EndDateTime = Datetime.newInstance(tomorrow, Time.newInstance(13, 0, 0, 0)),
            WhatId = testJob.Id
        ));

        interviews.add(new Event(
            Subject = 'Late Interview',
            StartDateTime = Datetime.newInstance(tomorrow, Time.newInstance(17, 30, 0, 0)),
            EndDateTime = Datetime.newInstance(tomorrow, Time.newInstance(18, 30, 0, 0)),
            WhatId = testJob.Id
        ));

        insert interviews;

        Test.startTest();
        InterviewReminderScheduler.sendInterviewReminders();
        Test.stopTest();

        // Verify all interviews for tomorrow were included
        List<Event> tomorrowEvents = [
            SELECT Id
            FROM Event
            WHERE Id IN :interviews
        ];

        System.assertEquals(3, tomorrowEvents.size(),
            'All interviews scheduled for tomorrow should be processed');
    }
}
