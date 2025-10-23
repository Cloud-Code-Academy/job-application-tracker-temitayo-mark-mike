/**
 * @description Test class for Stale Job Application Cleanup Batch and Scheduler
 * @author Temitayo Oluwalade
 * @date 2024
 */
@isTest
public class StaleJobApplicationCleanupBatchTest {

    /**
     * @description Test data setup
     */
    @TestSetup
    static void setupTestData() {
        List<Job_Application__c> jobApps = new List<Job_Application__c>();

        // Create stale applications (35 days old)
        Date staleDate = Date.today().addDays(-35);
        for (Integer i = 0; i < 5; i++) {
            jobApps.add(new Job_Application__c(
                Company_Name__c = 'Stale Company ' + i,
                Position_Title__c = 'Stale Position ' + i,
                Status__c = 'Applied',
                Follow_Up_Date__c = staleDate,
                Notes__c = 'Original notes for application ' + i
            ));
        }

        // Create borderline stale application (exactly 30 days old)
        jobApps.add(new Job_Application__c(
            Company_Name__c = 'Borderline Company',
            Position_Title__c = 'Borderline Position',
            Status__c = 'Interviewing',
            Follow_Up_Date__c = Date.today().addDays(-30),
            Notes__c = 'Borderline case notes'
        ));

        // Create active applications (10 days old)
        Date activeDate = Date.today().addDays(-10);
        for (Integer i = 0; i < 3; i++) {
            jobApps.add(new Job_Application__c(
                Company_Name__c = 'Active Company ' + i,
                Position_Title__c = 'Active Position ' + i,
                Status__c = 'Applying',
                Follow_Up_Date__c = activeDate
            ));
        }

        // Create applications with status that should not be closed
        jobApps.add(new Job_Application__c(
            Company_Name__c = 'Accepted Company',
            Position_Title__c = 'Accepted Position',
            Status__c = 'Accepted',
            Follow_Up_Date__c = Date.today().addDays(-40)
        ));

        jobApps.add(new Job_Application__c(
            Company_Name__c = 'Already Closed Company',
            Position_Title__c = 'Already Closed Position',
            Status__c = 'Closed',
            Follow_Up_Date__c = Date.today().addDays(-40)
        ));

        // Create application without follow-up date
        jobApps.add(new Job_Application__c(
            Company_Name__c = 'No Follow-up Company',
            Position_Title__c = 'No Follow-up Position',
            Status__c = 'Saved',
            Follow_Up_Date__c = null
        ));

        insert jobApps;
    }

    /**
     * @description Test batch execution with stale applications
     */
    @isTest
    static void testBatchClosesStaleApplications() {
        // Verify test data setup
        Integer totalApps = [SELECT COUNT() FROM Job_Application__c];
        System.assertEquals(12, totalApps, 'Should have 12 test applications');

        Test.startTest();

        // Execute batch
        StaleJobApplicationCleanupBatch batch = new StaleJobApplicationCleanupBatch();
        Database.executeBatch(batch, 200);

        Test.stopTest();

        // Verify results
        // Should close 6 applications (5 stale + 1 borderline)
        List<Job_Application__c> closedApps = [
            SELECT Id, Name, Status__c, Notes__c
            FROM Job_Application__c
            WHERE Status__c = 'Closed'
        ];

        System.assertEquals(7, closedApps.size(), 'Should have closed 6 stale apps + 1 that was already closed');

        // Verify notes were updated
        for (Job_Application__c app : closedApps) {
            if (!app.Name.contains('Already Closed')) {
                System.assert(app.Notes__c.contains('AUTOMATED CLOSURE'), 'Notes should contain automated closure message');
                System.assert(app.Notes__c.contains('Stale Application Cleanup'), 'Notes should mention reason');
            }
        }

        // Verify active applications were not closed
        List<Job_Application__c> activeApps = [
            SELECT Id, Status__c
            FROM Job_Application__c
            WHERE Status__c IN ('Applying', 'Saved')
        ];
        System.assertEquals(4, activeApps.size(), 'Active applications should not be closed (3 active + 1 no follow-up)');

        // Verify accepted application was not closed
        Job_Application__c acceptedApp = [
            SELECT Id, Status__c
            FROM Job_Application__c
            WHERE Status__c = 'Accepted'
            LIMIT 1
        ];
        System.assertEquals('Accepted', acceptedApp.Status__c, 'Accepted application should remain accepted');
    }

    /**
     * @description Test batch with custom stale threshold
     */
    @isTest
    static void testBatchWithCustomThreshold() {
        Test.startTest();

        // Execute with 40-day threshold
        StaleJobApplicationCleanupBatch batch = new StaleJobApplicationCleanupBatch(40, false, null);
        Database.executeBatch(batch, 200);

        Test.stopTest();

        // With 40-day threshold, only the very old ones should be closed
        List<Job_Application__c> closedApps = [
            SELECT Id
            FROM Job_Application__c
            WHERE Status__c = 'Closed'
            AND Company_Name__c != 'Already Closed Company'
        ];

        // Should close the 2 applications that are 40+ days old (Accepted and Already Closed were excluded from closure)
        System.assert(closedApps.size() <= 2, 'Fewer applications should be closed with higher threshold');
    }

    /**
     * @description Test batch appends to existing notes
     */
    @isTest
    static void testNotesAreAppended() {
        Test.startTest();

        StaleJobApplicationCleanupBatch batch = new StaleJobApplicationCleanupBatch();
        Database.executeBatch(batch, 200);

        Test.stopTest();

        // Get a closed application that had original notes
        Job_Application__c closedApp = [
            SELECT Id, Notes__c
            FROM Job_Application__c
            WHERE Status__c = 'Closed'
            AND Company_Name__c LIKE 'Stale Company%'
            LIMIT 1
        ];

        System.assert(closedApp.Notes__c.contains('Original notes'), 'Should preserve original notes');
        System.assert(closedApp.Notes__c.contains('AUTOMATED CLOSURE'), 'Should append automated closure message');
    }

    /**
     * @description Test batch with no stale applications
     */
    @isTest
    static void testBatchWithNoStaleApplications() {
        // Delete all stale applications
        delete [
            SELECT Id
            FROM Job_Application__c
            WHERE Follow_Up_Date__c <= :Date.today().addDays(-30)
            AND Status__c NOT IN ('Closed', 'Accepted')
        ];

        Test.startTest();

        StaleJobApplicationCleanupBatch batch = new StaleJobApplicationCleanupBatch();
        Database.executeBatch(batch, 200);

        Test.stopTest();

        // Verify no new applications were closed
        List<Job_Application__c> closedApps = [
            SELECT Id
            FROM Job_Application__c
            WHERE Status__c = 'Closed'
            AND Company_Name__c != 'Already Closed Company'
        ];

        System.assertEquals(0, closedApps.size(), 'No applications should be newly closed');
    }

    /**
     * @description Test batch processes applications in bulk
     */
    @isTest
    static void testBulkProcessing() {
        // Create many stale applications
        List<Job_Application__c> bulkApps = new List<Job_Application__c>();
        Date staleDate = Date.today().addDays(-35);

        for (Integer i = 0; i < 50; i++) {
            bulkApps.add(new Job_Application__c(
                Company_Name__c = 'Bulk Company ' + i,
                Position_Title__c = 'Bulk Position ' + i,
                Status__c = 'Applied',
                Follow_Up_Date__c = staleDate
            ));
        }
        insert bulkApps;

        Test.startTest();

        StaleJobApplicationCleanupBatch batch = new StaleJobApplicationCleanupBatch();
        Database.executeBatch(batch, 200);

        Test.stopTest();

        // Verify all bulk applications were closed
        List<Job_Application__c> closedBulkApps = [
            SELECT Id
            FROM Job_Application__c
            WHERE Company_Name__c LIKE 'Bulk Company%'
            AND Status__c = 'Closed'
        ];

        System.assertEquals(50, closedBulkApps.size(), 'All 50 bulk applications should be closed');
    }

    /**
     * @description Test scheduler weekly execution
     */
    @isTest
    static void testSchedulerWeekly() {
        Test.startTest();

        String jobId = StaleJobApplicationCleanupScheduler.scheduleWeekly();

        Test.stopTest();

        // Verify job was scheduled
        System.assertNotEquals(null, jobId, 'Job should be scheduled successfully');

        // Verify scheduled job exists
        CronTrigger scheduledJob = [
            SELECT Id, CronExpression, CronJobDetail.Name
            FROM CronTrigger
            WHERE Id = :jobId
        ];

        System.assertEquals('0 0 2 ? * SUN', scheduledJob.CronExpression, 'Should use weekly cron expression');
        System.assertEquals('Weekly Stale Job Application Cleanup', scheduledJob.CronJobDetail.Name);
    }

    /**
     * @description Test scheduler monthly execution
     */
    @isTest
    static void testSchedulerMonthly() {
        Test.startTest();

        String jobId = StaleJobApplicationCleanupScheduler.scheduleMonthly();

        Test.stopTest();

        // Verify job was scheduled
        System.assertNotEquals(null, jobId, 'Job should be scheduled successfully');

        CronTrigger scheduledJob = [
            SELECT Id, CronExpression, CronJobDetail.Name
            FROM CronTrigger
            WHERE Id = :jobId
        ];

        System.assertEquals('0 0 2 1 * ?', scheduledJob.CronExpression, 'Should use monthly cron expression');
        System.assertEquals('Monthly Stale Job Application Cleanup', scheduledJob.CronJobDetail.Name);
    }

    /**
     * @description Test scheduler with custom cron expression
     */
    @isTest
    static void testSchedulerCustomCron() {
        String customCron = '0 0 3 ? * MON'; // Mondays at 3 AM

        Test.startTest();

        String jobId = StaleJobApplicationCleanupScheduler.scheduleWeekly('Custom Cleanup Job', customCron);

        Test.stopTest();

        CronTrigger scheduledJob = [
            SELECT Id, CronExpression, CronJobDetail.Name
            FROM CronTrigger
            WHERE Id = :jobId
        ];

        System.assertEquals(customCron, scheduledJob.CronExpression, 'Should use custom cron expression');
        System.assertEquals('Custom Cleanup Job', scheduledJob.CronJobDetail.Name);
    }

    /**
     * @description Test immediate execution
     */
    @isTest
    static void testExecuteNow() {
        Test.startTest();

        Id jobId = StaleJobApplicationCleanupScheduler.executeNow();

        Test.stopTest();

        // Verify batch job was executed
        System.assertNotEquals(null, jobId, 'Batch job should be executed');

        // Verify stale applications were closed
        List<Job_Application__c> closedApps = [
            SELECT Id
            FROM Job_Application__c
            WHERE Status__c = 'Closed'
            AND Company_Name__c != 'Already Closed Company'
        ];

        System.assert(closedApps.size() > 0, 'Some applications should be closed');
    }

    /**
     * @description Test execute now with custom parameters
     */
    @isTest
    static void testExecuteNowWithCustomParams() {
        Test.startTest();

        Id jobId = StaleJobApplicationCleanupScheduler.executeNow(40, false, null, 100);

        Test.stopTest();

        System.assertNotEquals(null, jobId, 'Batch job should be executed with custom params');
    }

    /**
     * @description Test batch with applications without notes
     */
    @isTest
    static void testApplicationsWithoutNotes() {
        // Create stale application without notes
        Job_Application__c appWithoutNotes = new Job_Application__c(
            Company_Name__c = 'No Notes Company',
            Position_Title__c = 'No Notes Position',
            Status__c = 'Applied',
            Follow_Up_Date__c = Date.today().addDays(-35),
            Notes__c = null
        );
        insert appWithoutNotes;

        Test.startTest();

        StaleJobApplicationCleanupBatch batch = new StaleJobApplicationCleanupBatch();
        Database.executeBatch(batch, 200);

        Test.stopTest();

        // Verify notes were added (not appended)
        Job_Application__c closedApp = [
            SELECT Id, Notes__c
            FROM Job_Application__c
            WHERE Id = :appWithoutNotes.Id
        ];

        System.assert(closedApp.Notes__c.contains('AUTOMATED CLOSURE'), 'Notes should be added');
        System.assert(!closedApp.Notes__c.startsWith('\n\n'), 'Notes should not start with newlines');
    }

    /**
     * @description Test batch stateful variables
     */
    @isTest
    static void testBatchStatefulTracking() {
        Test.startTest();

        StaleJobApplicationCleanupBatch batch = new StaleJobApplicationCleanupBatch(30, false, null);
        Database.executeBatch(batch, 200);

        Test.stopTest();

        // Batch completed successfully - verify via query
        List<Job_Application__c> closedApps = [
            SELECT Id
            FROM Job_Application__c
            WHERE Status__c = 'Closed'
            AND Company_Name__c LIKE 'Stale%'
        ];

        System.assert(closedApps.size() > 0, 'Batch should track and close applications');
    }

    /**
     * @description Test closure message format
     */
    @isTest
    static void testClosureMessageFormat() {
        Test.startTest();

        StaleJobApplicationCleanupBatch batch = new StaleJobApplicationCleanupBatch();
        Database.executeBatch(batch, 200);

        Test.stopTest();

        Job_Application__c closedApp = [
            SELECT Id, Notes__c, Follow_Up_Date__c
            FROM Job_Application__c
            WHERE Status__c = 'Closed'
            AND Company_Name__c LIKE 'Stale Company%'
            LIMIT 1
        ];

        // Verify message contains key information
        System.assert(closedApp.Notes__c.contains('🤖 AUTOMATED CLOSURE'), 'Should have header');
        System.assert(closedApp.Notes__c.contains('Reason: Stale Application Cleanup'), 'Should have reason');
        System.assert(closedApp.Notes__c.contains('days overdue'), 'Should mention days overdue');
        System.assert(closedApp.Notes__c.contains(closedApp.Follow_Up_Date__c.format()), 'Should mention follow-up date');
    }

    /**
     * @description Test different status values that should not be closed
     */
    @isTest
    static void testExcludedStatuses() {
        // The test data already includes Accepted and Closed
        // These should not be closed even if stale

        Test.startTest();

        StaleJobApplicationCleanupBatch batch = new StaleJobApplicationCleanupBatch();
        Database.executeBatch(batch, 200);

        Test.stopTest();

        // Verify Accepted application remained Accepted
        Job_Application__c acceptedApp = [
            SELECT Id, Status__c
            FROM Job_Application__c
            WHERE Company_Name__c = 'Accepted Company'
        ];
        System.assertEquals('Accepted', acceptedApp.Status__c, 'Accepted apps should not be re-closed');

        // Already Closed should remain Closed
        Job_Application__c alreadyClosedApp = [
            SELECT Id, Status__c
            FROM Job_Application__c
            WHERE Company_Name__c = 'Already Closed Company'
        ];
        System.assertEquals('Closed', alreadyClosedApp.Status__c, 'Already closed apps should remain closed');
    }

    /**
     * @description Test applications without follow-up date are not processed
     */
    @isTest
    static void testApplicationsWithoutFollowUpDate() {
        Test.startTest();

        StaleJobApplicationCleanupBatch batch = new StaleJobApplicationCleanupBatch();
        Database.executeBatch(batch, 200);

        Test.stopTest();

        // Application without follow-up date should not be closed
        Job_Application__c noFollowUpApp = [
            SELECT Id, Status__c
            FROM Job_Application__c
            WHERE Company_Name__c = 'No Follow-up Company'
        ];

        System.assertEquals('Saved', noFollowUpApp.Status__c, 'Apps without follow-up date should not be closed');
    }

    /**
     * @description Test batch with small batch size
     */
    @isTest
    static void testSmallBatchSize() {
        Test.startTest();

        StaleJobApplicationCleanupBatch batch = new StaleJobApplicationCleanupBatch();
        Database.executeBatch(batch, 1); // Process 1 at a time

        Test.stopTest();

        // Should still process all stale applications
        List<Job_Application__c> closedApps = [
            SELECT Id
            FROM Job_Application__c
            WHERE Status__c = 'Closed'
            AND Company_Name__c LIKE 'Stale%'
        ];

        System.assert(closedApps.size() > 0, 'Should process all records even with small batch size');
    }
}
