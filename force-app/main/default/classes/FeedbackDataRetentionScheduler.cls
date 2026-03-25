/**
 * @description Scheduler class for automated data retention batch processing
 * Runs monthly to enforce data retention policies on Interview Feedback records
 * @author Kiro AI Assistant
 * @date 2025
 */
public class FeedbackDataRetentionScheduler implements Schedulable {
    
    /**
     * @description Execute method called by the scheduler
     * @param sc Schedulable context
     */
    public void execute(SchedulableContext sc) {
        try {
            // Log scheduled execution
            FeedbackSecurityService.createAuditLog(
                'SCHEDULED_RETENTION',
                'Starting scheduled data retention batch execution'
            );
            
            // Execute the retention batch with default settings
            FeedbackDataRetentionBatch retentionBatch = new FeedbackDataRetentionBatch();
            Database.executeBatch(retentionBatch, 200);
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error executing scheduled retention batch: ' + e.getMessage());
            
            FeedbackSecurityService.createAuditLog(
                'SCHEDULED_RETENTION_ERROR',
                'Failed to execute scheduled retention batch: ' + e.getMessage()
            );
        }
    }
}