/**
 * @description Test class for SalaryMarketAnalysisScheduler
 * @author Test Coverage
 * @date 2024
 */
@IsTest
private inherited sharing class SalaryMarketAnalysisSchedulerTest {

    @TestSetup
    static void setupTestData() {
        TestDataFactory.createJobApplications(3, 'Applied', true);
    }

    /**
     * @description Test scheduling a job with a custom cron expression and job name
     */
    @IsTest
    static void testScheduleJob() {
        String cronExpression = '0 0 6 ? * MON';
        String jobName = 'Test Salary Analysis Job';

        Test.startTest();
        String jobId = SalaryMarketAnalysisScheduler.scheduleJob(cronExpression, jobName);
        Test.stopTest();

        System.assertNotEquals(null, jobId, 'Scheduled job ID should not be null');

        List<CronTrigger> triggers = [
            SELECT Id, CronExpression, CronJobDetail.Name
            FROM CronTrigger
            WHERE Id = :jobId
        ];
        System.assertEquals(1, triggers.size(), 'Should find exactly one CronTrigger');
        System.assertEquals(cronExpression, triggers[0].CronExpression, 'Cron expression should match');
    }

    /**
     * @description Test scheduleWeeklyJob static method
     */
    @IsTest
    static void testScheduleWeeklyJob() {
        Test.startTest();
        String jobId = SalaryMarketAnalysisScheduler.scheduleWeeklyJob();
        Test.stopTest();

        System.assertNotEquals(null, jobId, 'Weekly job ID should not be null');

        List<CronTrigger> triggers = [
            SELECT Id, CronExpression
            FROM CronTrigger
            WHERE Id = :jobId
        ];
        System.assertEquals(1, triggers.size(), 'Should find the weekly CronTrigger');
        System.assertEquals('0 0 6 ? * MON', triggers[0].CronExpression, 'Should use Monday 6 AM cron');
    }

    /**
     * @description Test scheduleDailyJob static method
     */
    @IsTest
    static void testScheduleDailyJob() {
        Test.startTest();
        String jobId = SalaryMarketAnalysisScheduler.scheduleDailyJob();
        Test.stopTest();

        System.assertNotEquals(null, jobId, 'Daily job ID should not be null');

        List<CronTrigger> triggers = [
            SELECT Id, CronExpression, CronJobDetail.Name
            FROM CronTrigger
            WHERE Id = :jobId
        ];
        System.assertEquals(1, triggers.size(), 'Should find the daily CronTrigger');
        System.assertEquals('0 0 2 * * ?', triggers[0].CronExpression, 'Should use daily 2 AM cron');
    }

    /**
     * @description Test cancelAllJobs method
     */
    @IsTest
    static void testCancelAllJobs() {
        // First schedule some jobs
        Test.startTest();
        SalaryMarketAnalysisScheduler.scheduleWeeklyJob();
        SalaryMarketAnalysisScheduler.scheduleDailyJob();

        // Now cancel all
        SalaryMarketAnalysisScheduler.cancelAllJobs();
        Test.stopTest();

        // Verify no active jobs remain
        List<CronTrigger> remainingJobs = [
            SELECT Id
            FROM CronTrigger
            WHERE CronJobDetail.Name LIKE '%Salary Market Analysis%'
            AND State IN ('WAITING', 'ACQUIRED', 'EXECUTING')
        ];
        System.assertEquals(0, remainingJobs.size(), 'All scheduled jobs should be cancelled');
    }

    /**
     * @description Test getScheduledJobsStatus method
     */
    @IsTest
    static void testGetScheduledJobsStatus() {
        Test.startTest();
        // Schedule a job first
        SalaryMarketAnalysisScheduler.scheduleWeeklyJob();

        // Get the status
        List<SalaryMarketAnalysisScheduler.ScheduledJobInfo> jobInfos =
            SalaryMarketAnalysisScheduler.getScheduledJobsStatus();
        Test.stopTest();

        System.assert(jobInfos.size() > 0, 'Should find at least one scheduled job');
        System.assertNotEquals(null, jobInfos[0].jobId, 'Job ID should not be null');
        System.assertNotEquals(null, jobInfos[0].jobName, 'Job name should not be null');
        System.assertNotEquals(null, jobInfos[0].cronExpression, 'Cron expression should not be null');
        System.assertNotEquals(null, jobInfos[0].state, 'State should not be null');
    }

    /**
     * @description Test ScheduledJobInfo wrapper class and getFormattedInfo method
     */
    @IsTest
    static void testScheduledJobInfoWrapper() {
        Test.startTest();
        // Schedule a job to get a real CronTrigger
        String jobId = SalaryMarketAnalysisScheduler.scheduleWeeklyJob();

        CronTrigger trigger = [
            SELECT Id, CronJobDetail.Name, CronExpression, State,
                   NextFireTime, PreviousFireTime, StartTime, EndTime
            FROM CronTrigger
            WHERE Id = :jobId
        ];

        SalaryMarketAnalysisScheduler.ScheduledJobInfo info =
            new SalaryMarketAnalysisScheduler.ScheduledJobInfo(trigger);
        Test.stopTest();

        System.assertEquals(trigger.Id, info.jobId, 'Job ID should match');
        System.assertEquals(trigger.CronJobDetail.Name, info.jobName, 'Job name should match');
        System.assertEquals(trigger.CronExpression, info.cronExpression, 'Cron expression should match');
        System.assertEquals(trigger.State, info.state, 'State should match');
        System.assertEquals(trigger.NextFireTime, info.nextFireTime, 'Next fire time should match');
        System.assertEquals(trigger.StartTime, info.startTime, 'Start time should match');

        // Test getFormattedInfo
        String formattedInfo = info.getFormattedInfo();
        System.assertNotEquals(null, formattedInfo, 'Formatted info should not be null');
        System.assert(formattedInfo.contains('Job:'), 'Formatted info should contain Job label');
        System.assert(formattedInfo.contains('State:'), 'Formatted info should contain State label');
    }

    /**
     * @description Test scheduleJob with blank job name uses default
     */
    @IsTest
    static void testScheduleJobWithBlankName() {
        String cronExpression = '0 0 12 * * ?';

        Test.startTest();
        String jobId = SalaryMarketAnalysisScheduler.scheduleJob(cronExpression, '');
        Test.stopTest();

        System.assertNotEquals(null, jobId, 'Job ID should not be null even with blank name');
    }
}
