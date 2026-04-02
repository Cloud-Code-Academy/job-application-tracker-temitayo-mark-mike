/**
 * @description Test class for JobApplicationCleanupScheduler
 * @author Test Coverage
 * @date 2024
 */
@IsTest
private inherited sharing class JobApplicationCleanupSchedulerTest {

    @TestSetup
    static void setupTestData() {
        TestDataFactory.createJobApplications(5, 'Applied', true);
    }

    /**
     * @description Test scheduling via default constructor
     */
    @IsTest
    static void testScheduleWithDefaultConstructor() {
        String cronExpression = '0 0 2 * * ?';

        Test.startTest();
        String jobId = System.schedule(
            'Test Default Cleanup Scheduler',
            cronExpression,
            new JobApplicationCleanupScheduler()
        );
        Test.stopTest();

        System.assertNotEquals(null, jobId, 'Scheduled job ID should not be null');

        List<CronTrigger> triggers = [
            SELECT Id, CronExpression, State
            FROM CronTrigger
            WHERE Id = :jobId
        ];
        System.assertEquals(1, triggers.size(), 'Should find exactly one CronTrigger');
        System.assertEquals(cronExpression, triggers[0].CronExpression, 'Cron expression should match');
    }

    /**
     * @description Test scheduling via parameterized constructor
     */
    @IsTest
    static void testScheduleWithParameterizedConstructor() {
        String cronExpression = '0 30 1 * * ?';

        Test.startTest();
        JobApplicationCleanupScheduler scheduler = new JobApplicationCleanupScheduler(
            JobApplicationCleanupBatch.CleanupType.ARCHIVE_OLD,
            180,
            true,
            100
        );
        String jobId = System.schedule('Test Parameterized Cleanup', cronExpression, scheduler);
        Test.stopTest();

        System.assertNotEquals(null, jobId, 'Scheduled job ID should not be null');
    }

    /**
     * @description Test scheduleDailyCleanup static method
     */
    @IsTest
    static void testScheduleDailyCleanup() {
        Test.startTest();
        String jobId = JobApplicationCleanupScheduler.scheduleDailyCleanup(
            JobApplicationCleanupBatch.CleanupType.UPDATE_STALE, 3, 0
        );
        Test.stopTest();

        System.assertNotEquals(null, jobId, 'Daily cleanup job ID should not be null');

        List<CronTrigger> triggers = [
            SELECT Id, CronJobDetail.Name
            FROM CronTrigger
            WHERE Id = :jobId
        ];
        System.assertEquals(1, triggers.size(), 'Should find the scheduled daily cleanup job');
    }

    /**
     * @description Test scheduleWeeklyCleanup static method
     */
    @IsTest
    static void testScheduleWeeklyCleanup() {
        Test.startTest();
        String jobId = JobApplicationCleanupScheduler.scheduleWeeklyCleanup(
            JobApplicationCleanupBatch.CleanupType.REMOVE_DUPLICATES, 2, 4, 30
        );
        Test.stopTest();

        System.assertNotEquals(null, jobId, 'Weekly cleanup job ID should not be null');

        List<CronTrigger> triggers = [
            SELECT Id, CronJobDetail.Name
            FROM CronTrigger
            WHERE Id = :jobId
        ];
        System.assertEquals(1, triggers.size(), 'Should find the scheduled weekly cleanup job');
    }

    /**
     * @description Test scheduleMonthlyCleanup static method
     */
    @IsTest
    static void testScheduleMonthlyCleanup() {
        Test.startTest();
        String jobId = JobApplicationCleanupScheduler.scheduleMonthlyCleanup(
            JobApplicationCleanupBatch.CleanupType.FULL_CLEANUP, 1, 5, 0
        );
        Test.stopTest();

        System.assertNotEquals(null, jobId, 'Monthly cleanup job ID should not be null');

        List<CronTrigger> triggers = [
            SELECT Id, CronJobDetail.Name
            FROM CronTrigger
            WHERE Id = :jobId
        ];
        System.assertEquals(1, triggers.size(), 'Should find the scheduled monthly cleanup job');
    }

    /**
     * @description Test getScheduledCleanupJobs and cancelAllScheduledCleanupJobs
     */
    @IsTest
    static void testGetAndCancelScheduledJobs() {
        // Schedule some jobs first
        Test.startTest();
        JobApplicationCleanupScheduler.scheduleDailyCleanup(
            JobApplicationCleanupBatch.CleanupType.FULL_CLEANUP, 6, 0
        );
        JobApplicationCleanupScheduler.scheduleWeeklyCleanup(
            JobApplicationCleanupBatch.CleanupType.ARCHIVE_OLD, 1, 7, 0
        );

        // Get scheduled jobs
        List<CronTrigger> scheduledJobs = JobApplicationCleanupScheduler.getScheduledCleanupJobs();
        System.assert(scheduledJobs.size() >= 2, 'Should find at least 2 scheduled cleanup jobs');

        // Cancel all scheduled jobs
        Integer cancelledCount = JobApplicationCleanupScheduler.cancelAllScheduledCleanupJobs();
        System.assert(cancelledCount >= 2, 'Should cancel at least 2 jobs');
        Test.stopTest();

        // Verify jobs are cancelled
        List<CronTrigger> remainingJobs = JobApplicationCleanupScheduler.getScheduledCleanupJobs();
        System.assertEquals(0, remainingJobs.size(), 'No cleanup jobs should remain after cancellation');
    }

    /**
     * @description Test constructor with 3-parameter overload (without batchSize)
     */
    @IsTest
    static void testThreeParamConstructor() {
        String cronExpression = '0 0 3 * * ?';

        Test.startTest();
        JobApplicationCleanupScheduler scheduler = new JobApplicationCleanupScheduler(
            JobApplicationCleanupBatch.CleanupType.UPDATE_STALE,
            90,
            false
        );
        String jobId = System.schedule('Test 3-Param Cleanup', cronExpression, scheduler);
        Test.stopTest();

        System.assertNotEquals(null, jobId, 'Scheduled job ID should not be null');
    }
}
