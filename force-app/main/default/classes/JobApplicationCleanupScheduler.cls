/**
 * @description Scheduler class for automating Job Application cleanup batch jobs
 * @author Learning Journey
 * @date 2025-01-08
 */
public inherited sharing class JobApplicationCleanupScheduler implements Schedulable {
    
    private JobApplicationCleanupBatch.CleanupType cleanupType;
    private Integer daysOld;
    private Boolean sendReport;
    private Integer batchSize;
    
    /**
     * @description Constructor with full configuration
     * @param cleanupType Type of cleanup to perform
     * @param daysOld Number of days old for archive operations
     * @param sendReport Whether to send completion report
     * @param batchSize Batch size for processing
     */
    public JobApplicationCleanupScheduler(
        JobApplicationCleanupBatch.CleanupType cleanupType, 
        Integer daysOld, 
        Boolean sendReport,
        Integer batchSize
    ) {
        this.cleanupType = cleanupType;
        this.daysOld = daysOld;
        this.sendReport = sendReport;
        this.batchSize = batchSize != null ? batchSize : 200;
    }
    
    /**
     * @description Constructor with default batch size
     */
    public JobApplicationCleanupScheduler(
        JobApplicationCleanupBatch.CleanupType cleanupType, 
        Integer daysOld, 
        Boolean sendReport
    ) {
        this(cleanupType, daysOld, sendReport, 200);
    }
    
    /**
     * @description Default constructor for full cleanup
     */
    public JobApplicationCleanupScheduler() {
        this(JobApplicationCleanupBatch.CleanupType.FULL_CLEANUP, 365, true, 200);
    }
    
    /**
     * @description Execute method called by the scheduler
     * @param context Schedulable context
     */
    public void execute(SchedulableContext context) {
        System.debug('JobApplicationCleanupScheduler executing with type: ' + cleanupType);
        
        try {
            // Create and execute the batch job
            JobApplicationCleanupBatch batchJob = new JobApplicationCleanupBatch(
                cleanupType, 
                daysOld, 
                sendReport
            );
            
            Id batchJobId = Database.executeBatch(batchJob, batchSize);
            
            System.debug('Batch job started with ID: ' + batchJobId);
            
            // Log the scheduled execution
            logScheduledExecution(context, batchJobId);
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error executing scheduled cleanup: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());
            
            // In a real implementation, you might want to send an alert email
            handleSchedulerError(context, e);
        }
    }
    
    /**
     * @description Log the scheduled execution for monitoring
     * @param context Schedulable context
     * @param batchJobId ID of the batch job that was started
     */
    private void logScheduledExecution(SchedulableContext context, Id batchJobId) {
        System.debug('=== SCHEDULED CLEANUP EXECUTION LOG ===');
        System.debug('Trigger ID: ' + context.getTriggerId());
        System.debug('Cleanup Type: ' + cleanupType);
        System.debug('Days Old: ' + daysOld);
        System.debug('Batch Size: ' + batchSize);
        System.debug('Batch Job ID: ' + batchJobId);
        System.debug('Execution Time: ' + DateTime.now().format());
        
        // In a real implementation, you might create a custom object record
        // to track scheduled executions for monitoring and reporting
    }
    
    /**
     * @description Handle scheduler errors
     * @param context Schedulable context
     * @param error Exception that occurred
     */
    private void handleSchedulerError(SchedulableContext context, Exception error) {
        System.debug('=== SCHEDULER ERROR LOG ===');
        System.debug('Trigger ID: ' + context.getTriggerId());
        System.debug('Error Message: ' + error.getMessage());
        System.debug('Error Type: ' + error.getTypeName());
        System.debug('Stack Trace: ' + error.getStackTraceString());
        System.debug('Error Time: ' + DateTime.now().format());
        
        // In a real implementation, you might:
        // 1. Send an alert email to administrators
        // 2. Create a case or task for investigation
        // 3. Log to a custom error tracking object
        // 4. Retry the operation with different parameters
    }
    
    /**
     * @description Schedule daily cleanup job
     * @param cleanupType Type of cleanup to schedule
     * @param hour Hour to run (0-23)
     * @param minute Minute to run (0-59)
     * @return Scheduled job ID
     */
    public static String scheduleDailyCleanup(
        JobApplicationCleanupBatch.CleanupType cleanupType, 
        Integer hour, 
        Integer minute
    ) {
        // Build cron expression for daily execution
        String cronExpression = '0 ' + minute + ' ' + hour + ' * * ?';
        String jobName = 'Daily Job App Cleanup - ' + cleanupType + ' - ' + hour + ':' + 
                        (minute < 10 ? '0' : '') + minute;
        
        JobApplicationCleanupScheduler scheduler = new JobApplicationCleanupScheduler(
            cleanupType, 365, true, 200
        );
        
        return System.schedule(jobName, cronExpression, scheduler);
    }
    
    /**
     * @description Schedule weekly cleanup job
     * @param cleanupType Type of cleanup to schedule
     * @param dayOfWeek Day of week (1=Sunday, 2=Monday, etc.)
     * @param hour Hour to run (0-23)
     * @param minute Minute to run (0-59)
     * @return Scheduled job ID
     */
    public static String scheduleWeeklyCleanup(
        JobApplicationCleanupBatch.CleanupType cleanupType,
        Integer dayOfWeek,
        Integer hour, 
        Integer minute
    ) {
        // Build cron expression for weekly execution
        String cronExpression = '0 ' + minute + ' ' + hour + ' ? * ' + dayOfWeek;
        String jobName = 'Weekly Job App Cleanup - ' + cleanupType + ' - Day ' + dayOfWeek;
        
        JobApplicationCleanupScheduler scheduler = new JobApplicationCleanupScheduler(
            cleanupType, 365, true, 200
        );
        
        return System.schedule(jobName, cronExpression, scheduler);
    }
    
    /**
     * @description Schedule monthly cleanup job
     * @param cleanupType Type of cleanup to schedule
     * @param dayOfMonth Day of month to run (1-31)
     * @param hour Hour to run (0-23)
     * @param minute Minute to run (0-59)
     * @return Scheduled job ID
     */
    public static String scheduleMonthlyCleanup(
        JobApplicationCleanupBatch.CleanupType cleanupType,
        Integer dayOfMonth,
        Integer hour, 
        Integer minute
    ) {
        // Build cron expression for monthly execution
        String cronExpression = '0 ' + minute + ' ' + hour + ' ' + dayOfMonth + ' * ?';
        String jobName = 'Monthly Job App Cleanup - ' + cleanupType + ' - Day ' + dayOfMonth;
        
        JobApplicationCleanupScheduler scheduler = new JobApplicationCleanupScheduler(
            cleanupType, 365, true, 200
        );
        
        return System.schedule(jobName, cronExpression, scheduler);
    }
    
    /**
     * @description Get all scheduled cleanup jobs
     * @return List of scheduled jobs related to cleanup
     */
    public static List<CronTrigger> getScheduledCleanupJobs() {
        return [
            SELECT Id, CronJobDetail.Name, CronExpression, State, 
                   NextFireTime, PreviousFireTime, CreatedDate
            FROM CronTrigger 
            WHERE CronJobDetail.Name LIKE '%Job App Cleanup%'
            ORDER BY CronJobDetail.Name
        ];
    }
    
    /**
     * @description Cancel all scheduled cleanup jobs
     * @return Number of jobs cancelled
     */
    public static Integer cancelAllScheduledCleanupJobs() {
        List<CronTrigger> scheduledJobs = getScheduledCleanupJobs();
        Integer cancelledCount = 0;
        
        for (CronTrigger job : scheduledJobs) {
            try {
                System.abortJob(job.Id);
                cancelledCount++;
                System.debug('Cancelled scheduled job: ' + job.CronJobDetail.Name);
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Error cancelling job ' + job.Id + ': ' + e.getMessage());
            }
        }
        
        return cancelledCount;
    }
}