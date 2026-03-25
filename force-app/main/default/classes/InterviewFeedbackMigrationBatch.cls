/**
 * @description Batch class for migrating large volumes of interview data
 * @author Interview Feedback Tracker Team
 * @date 2024
 */
public inherited sharing class InterviewFeedbackMigrationBatch implements Database.Batchable<sObject>, Database.Stateful {
    
    private Integer totalProcessed = 0;
    private Integer totalSuccessful = 0;
    private Integer totalFailed = 0;
    private List<String> allErrors = new List<String>();
    
    /**
     * @description Query all Job Applications with interview data to migrate
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Name, Interview_Notes__c, Interview_Date__c, 
                   Status__c, Company__c, Position_Title__c
            FROM Job_Application__c 
            WHERE Interview_Notes__c != null
            AND Id NOT IN (
                SELECT Job_Application__c 
                FROM Interview_Feedback__c 
                WHERE Job_Application__c != null
            )
        ]);
    }
    
    /**
     * @description Process each batch of Job Applications
     */
    public void execute(Database.BatchableContext bc, List<Job_Application__c> scope) {
        List<Id> jobAppIds = new List<Id>();
        for (Job_Application__c jobApp : scope) {
            jobAppIds.add(jobApp.Id);
        }
        
        InterviewFeedbackDataMigration.MigrationResult result = 
            InterviewFeedbackDataMigration.migrateInterviewData(jobAppIds);
        
        totalProcessed += result.processedRecords;
        totalSuccessful += result.successfulRecords;
        totalFailed += result.failedRecords;
        allErrors.addAll(result.errors);
        
        System.debug('Batch processed: ' + result.getSummary());
    }
    
    /**
     * @description Send completion notification and summary
     */
    public void finish(Database.BatchableContext bc) {
        // Create summary report
        String summary = String.format(
            'Interview Data Migration Completed:\n' +
            'Total Processed: {0}\n' +
            'Successful: {1}\n' +
            'Failed: {2}\n' +
            'Success Rate: {3}%',
            new List<Object>{
                totalProcessed,
                totalSuccessful, 
                totalFailed,
                totalProcessed > 0 ? (totalSuccessful * 100 / totalProcessed) : 0
            }
        );
        
        System.debug(summary);
        
        // Send email notification to admin
        try {
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new List<String>{UserInfo.getUserEmail()});
            email.setSubject('Interview Feedback Migration Completed');
            
            String emailBody = summary;
            if (!allErrors.isEmpty()) {
                emailBody += '\n\nErrors encountered:\n';
                for (String error : allErrors) {
                    emailBody += '- ' + error + '\n';
                }
            }
            
            email.setPlainTextBody(emailBody);
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{email});
            
        } catch (Exception e) {
            System.debug('Failed to send completion email: ' + e.getMessage());
        }
        
        // Schedule data retention cleanup if migration was successful
        if (totalSuccessful > 0 && totalFailed == 0) {
            System.schedule(
                'Interview Feedback Data Retention', 
                '0 0 2 * * ?', // Daily at 2 AM
                new FeedbackDataRetentionScheduler()
            );
        }
    }
}