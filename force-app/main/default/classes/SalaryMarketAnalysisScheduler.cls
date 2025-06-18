/**
 * @description Scheduler class for automated salary market analysis
 * @author Temitayo Oluwalade
 * @date 2024
 */
public class SalaryMarketAnalysisScheduler implements Schedulable {
    
    private static final String JOB_NAME = 'Weekly Salary Market Analysis';
    private static final Integer DEFAULT_BATCH_SIZE = 200;
    
    /**
     * @description Execute method called by the scheduler
     * @param sc SchedulableContext
     */
    public void execute(SchedulableContext sc) {
        System.debug('Executing scheduled salary market analysis');
        
        try {
            // Execute the batch job
            Id batchJobId = SalaryMarketAnalysisBatch.executeBatch(DEFAULT_BATCH_SIZE);
            
            System.debug('Scheduled batch job started with ID: ' + batchJobId);
            
            // Log the execution
            logScheduledExecution(sc, batchJobId);
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Failed to execute scheduled batch job: ' + e.getMessage());
            
            // In production, send alert notification
            handleSchedulerError(sc, e);
        }
    }
    
    /**
     * @description Schedules the salary market analysis job
     * @param cronExpression Cron expression for scheduling
     * @param jobName Optional custom job name
     * @return Scheduled job ID
     */
    public static String scheduleJob(String cronExpression, String jobName) {
        if (String.isBlank(jobName)) {
            jobName = JOB_NAME + ' - ' + Datetime.now().format('yyyy-MM-dd HH:mm:ss');
        }
        
        SalaryMarketAnalysisScheduler scheduler = new SalaryMarketAnalysisScheduler();
        return System.schedule(jobName, cronExpression, scheduler);
    }
    
    /**
     * @description Schedules weekly job with default settings
     * @return Scheduled job ID
     */
    public static String scheduleWeeklyJob() {
        // Every Monday at 6:00 AM
        String cronExpression = '0 0 6 ? * MON';
        return scheduleJob(cronExpression, null);
    }
    
    /**
     * @description Schedules daily job for testing/development
     * @return Scheduled job ID
     */
    public static String scheduleDailyJob() {
        // Every day at 2:00 AM
        String cronExpression = '0 0 2 * * ?';
        return scheduleJob(cronExpression, 'Daily Salary Market Analysis - DEV');
    }
    
    /**
     * @description Cancels all scheduled jobs for this class
     */
    public static void cancelAllJobs() {
        List<CronTrigger> scheduledJobs = [
            SELECT Id, CronJobDetail.Name, State
            FROM CronTrigger 
            WHERE CronJobDetail.Name LIKE '%Salary Market Analysis%'
            AND State IN ('WAITING', 'ACQUIRED', 'EXECUTING')
        ];
        
        for (CronTrigger job : scheduledJobs) {
            try {
                System.abortJob(job.Id);
                System.debug('Cancelled scheduled job: ' + job.CronJobDetail.Name);
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Failed to cancel job ' + job.Id + ': ' + e.getMessage());
            }
        }
    }
    
    /**
     * @description Gets status of all scheduled jobs
     * @return List of job status information
     */
    public static List<ScheduledJobInfo> getScheduledJobsStatus() {
        List<ScheduledJobInfo> jobInfos = new List<ScheduledJobInfo>();
        
        List<CronTrigger> scheduledJobs = [
            SELECT Id, CronJobDetail.Name, CronExpression, State, 
                   NextFireTime, PreviousFireTime, StartTime, EndTime
            FROM CronTrigger 
            WHERE CronJobDetail.Name LIKE '%Salary Market Analysis%'
            ORDER BY NextFireTime ASC
        ];
        
        for (CronTrigger job : scheduledJobs) {
            jobInfos.add(new ScheduledJobInfo(job));
        }
        
        return jobInfos;
    }
    
    /**
     * @description Logs the scheduled execution
     * @param sc SchedulableContext
     * @param batchJobId ID of the started batch job
     */
    private void logScheduledExecution(SchedulableContext sc, Id batchJobId) {
        System.debug('=== SCHEDULED JOB EXECUTION LOG ===');
        System.debug('Trigger ID: ' + sc.getTriggerId());
        System.debug('Execution Time: ' + Datetime.now());
        System.debug('Batch Job ID: ' + batchJobId);
        System.debug('===================================');
    }
    
    /**
     * @description Handles scheduler errors
     * @param sc SchedulableContext
     * @param e Exception that occurred
     */
    private void handleSchedulerError(SchedulableContext sc, Exception e) {
        System.debug(LoggingLevel.ERROR, '=== SCHEDULER ERROR ===');
        System.debug(LoggingLevel.ERROR, 'Trigger ID: ' + sc.getTriggerId());
        System.debug(LoggingLevel.ERROR, 'Error Time: ' + Datetime.now());
        System.debug(LoggingLevel.ERROR, 'Error Message: ' + e.getMessage());
        System.debug(LoggingLevel.ERROR, 'Stack Trace: ' + e.getStackTraceString());
        System.debug(LoggingLevel.ERROR, '======================');
        
        // In production, send email alert or create case
        // sendErrorNotification(sc, e);
    }
    
    /**
     * @description Inner class to hold scheduled job information
     */
    public class ScheduledJobInfo {
        public String jobId;
        public String jobName;
        public String cronExpression;
        public String state;
        public Datetime nextFireTime;
        public Datetime previousFireTime;
        public Datetime startTime;
        public Datetime endTime;
        
        public ScheduledJobInfo(CronTrigger job) {
            this.jobId = job.Id;
            this.jobName = job.CronJobDetail.Name;
            this.cronExpression = job.CronExpression;
            this.state = job.State;
            this.nextFireTime = job.NextFireTime;
            this.previousFireTime = job.PreviousFireTime;
            this.startTime = job.StartTime;
            this.endTime = job.EndTime;
        }
        
        public String getFormattedInfo() {
            return String.format(
                'Job: {0}\nState: {1}\nNext Run: {2}\nLast Run: {3}',
                new List<Object>{jobName, state, nextFireTime, previousFireTime}
            );
        }
    }
}
