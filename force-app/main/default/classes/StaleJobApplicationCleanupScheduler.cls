/**
 * @description Schedulable class to run stale job application cleanup batch
 * Executes periodically to identify and close inactive job applications
 * @author Temitayo Oluwalade
 * @date 2024
 */
public class StaleJobApplicationCleanupScheduler implements Schedulable {

    private Integer staleDaysThreshold;
    private Boolean sendSummaryEmail;
    private String summaryEmailRecipient;
    private Integer batchSize;

    /**
     * @description Default constructor
     */
    public StaleJobApplicationCleanupScheduler() {
        this(30, true, UserInfo.getUserEmail(), 200);
    }

    /**
     * @description Constructor with custom parameters
     * @param staleDays Number of days to consider an application stale
     * @param sendEmail Whether to send summary email
     * @param emailRecipient Email address for summary
     * @param batchSize Size of batches to process
     */
    public StaleJobApplicationCleanupScheduler(Integer staleDays, Boolean sendEmail, String emailRecipient, Integer batchSize) {
        this.staleDaysThreshold = staleDays != null && staleDays > 0 ? staleDays : 30;
        this.sendSummaryEmail = sendEmail != null ? sendEmail : true;
        this.summaryEmailRecipient = String.isNotBlank(emailRecipient) ? emailRecipient : UserInfo.getUserEmail();
        this.batchSize = batchSize != null && batchSize > 0 ? batchSize : 200;
    }

    /**
     * @description Execute method for scheduled job
     * @param sc SchedulableContext
     */
    public void execute(SchedulableContext sc) {
        System.debug('Executing Stale Job Application Cleanup Scheduler');
        executeCleanup();
    }

    /**
     * @description Executes the cleanup batch job
     */
    public void executeCleanup() {
        StaleJobApplicationCleanupBatch batch = new StaleJobApplicationCleanupBatch(
            staleDaysThreshold,
            sendSummaryEmail,
            summaryEmailRecipient
        );

        Database.executeBatch(batch, batchSize);
        System.debug('Stale Job Application Cleanup batch started with batch size: ' + batchSize);
    }

    /**
     * @description Schedules the cleanup job to run weekly
     * @param jobName Name for the scheduled job
     * @param cronExpression Cron expression for scheduling (default: weekly on Sunday at 2 AM)
     * @return Scheduled job ID
     */
    public static String scheduleWeekly(String jobName, String cronExpression) {
        // Default cron expression: Run weekly on Sunday at 2:00 AM
        // Format: Seconds Minutes Hours Day_of_month Month Day_of_week optional_year
        String cron = String.isNotBlank(cronExpression) ? cronExpression : '0 0 2 ? * SUN';

        StaleJobApplicationCleanupScheduler scheduler = new StaleJobApplicationCleanupScheduler();
        return System.schedule(jobName, cron, scheduler);
    }

    /**
     * @description Schedules the cleanup job to run monthly
     * @param jobName Name for the scheduled job
     * @param cronExpression Cron expression for scheduling (default: monthly on 1st at 2 AM)
     * @return Scheduled job ID
     */
    public static String scheduleMonthly(String jobName, String cronExpression) {
        // Default cron expression: Run monthly on the 1st at 2:00 AM
        String cron = String.isNotBlank(cronExpression) ? cronExpression : '0 0 2 1 * ?';

        StaleJobApplicationCleanupScheduler scheduler = new StaleJobApplicationCleanupScheduler();
        return System.schedule(jobName, cron, scheduler);
    }

    /**
     * @description Convenience method to schedule weekly with default settings
     * @return Scheduled job ID
     */
    public static String scheduleWeekly() {
        return scheduleWeekly('Weekly Stale Job Application Cleanup', '0 0 2 ? * SUN');
    }

    /**
     * @description Convenience method to schedule monthly with default settings
     * @return Scheduled job ID
     */
    public static String scheduleMonthly() {
        return scheduleMonthly('Monthly Stale Job Application Cleanup', '0 0 2 1 * ?');
    }

    /**
     * @description Executes the cleanup immediately (for manual execution)
     * @return Batch job ID
     */
    public static Id executeNow() {
        StaleJobApplicationCleanupBatch batch = new StaleJobApplicationCleanupBatch();
        return Database.executeBatch(batch, 200);
    }

    /**
     * @description Executes the cleanup with custom parameters
     * @param staleDays Number of days to consider an application stale
     * @param sendEmail Whether to send summary email
     * @param emailRecipient Email address for summary
     * @param batchSize Size of batches to process
     * @return Batch job ID
     */
    public static Id executeNow(Integer staleDays, Boolean sendEmail, String emailRecipient, Integer batchSize) {
        StaleJobApplicationCleanupBatch batch = new StaleJobApplicationCleanupBatch(
            staleDays,
            sendEmail,
            emailRecipient
        );
        return Database.executeBatch(batch, batchSize);
    }
}
