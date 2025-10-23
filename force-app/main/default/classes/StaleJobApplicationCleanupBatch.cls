/**
 * @description Batch class to clean up stale job applications
 * Identifies and closes job applications that have been inactive for 30+ days
 * @author Temitayo Oluwalade
 * @date 2024
 */
public class StaleJobApplicationCleanupBatch implements Database.Batchable<SObject>, Database.Stateful {

    // Stateful variables to track batch execution results
    private Integer recordsProcessed = 0;
    private Integer recordsClosed = 0;
    private Integer recordsFailed = 0;
    private List<String> errorMessages = new List<String>();

    // Configuration
    private Integer staleDaysThreshold;
    private Boolean sendSummaryEmail;
    private String summaryEmailRecipient;

    /**
     * @description Default constructor with 30-day threshold
     */
    public StaleJobApplicationCleanupBatch() {
        this(30, true, UserInfo.getUserEmail());
    }

    /**
     * @description Constructor with custom parameters
     * @param staleDays Number of days to consider an application stale
     * @param sendEmail Whether to send summary email
     * @param emailRecipient Email address for summary
     */
    public StaleJobApplicationCleanupBatch(Integer staleDays, Boolean sendEmail, String emailRecipient) {
        this.staleDaysThreshold = staleDays != null && staleDays > 0 ? staleDays : 30;
        this.sendSummaryEmail = sendEmail != null ? sendEmail : true;
        this.summaryEmailRecipient = String.isNotBlank(emailRecipient) ? emailRecipient : UserInfo.getUserEmail();
    }

    /**
     * @description Start method to query stale job applications
     * @param bc BatchableContext
     * @return Database.QueryLocator
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        System.debug('Starting Stale Job Application Cleanup Batch');
        System.debug('Stale threshold: ' + staleDaysThreshold + ' days');

        // Calculate the cutoff date (30 days ago from today)
        Date cutoffDate = Date.today().addDays(-staleDaysThreshold);

        System.debug('Cutoff date: ' + cutoffDate);

        // Query job applications that are stale
        // Criteria:
        // 1. Status is not 'Closed' or 'Accepted'
        // 2. Follow_Up_Date__c is 30+ days old (or older than cutoff date)
        String query =
            'SELECT Id, Name, Company_Name__c, Position_Title__c, Status__c, ' +
            '       Follow_Up_Date__c, Notes__c, OwnerId, Owner.Name, Owner.Email ' +
            'FROM Job_Application__c ' +
            'WHERE Status__c NOT IN (\'Closed\', \'Accepted\') ' +
            'AND Follow_Up_Date__c != null ' +
            'AND Follow_Up_Date__c <= :cutoffDate ' +
            'ORDER BY Follow_Up_Date__c ASC';

        return Database.getQueryLocator(query);
    }

    /**
     * @description Execute method to process each batch of stale applications
     * @param bc BatchableContext
     * @param scope List of Job_Application__c records to process
     */
    public void execute(Database.BatchableContext bc, List<Job_Application__c> scope) {
        System.debug('Processing batch of ' + scope.size() + ' stale job applications');

        List<Job_Application__c> applicationsToUpdate = new List<Job_Application__c>();

        for (Job_Application__c app : scope) {
            recordsProcessed++;

            try {
                // Calculate how many days stale
                Integer daysStale = app.Follow_Up_Date__c.daysBetween(Date.today());

                // Update status to Closed
                app.Status__c = 'Closed';

                // Append automated closure message to notes
                String automatedMessage = buildClosureMessage(app, daysStale);

                if (String.isBlank(app.Notes__c)) {
                    app.Notes__c = automatedMessage;
                } else {
                    app.Notes__c = app.Notes__c + '\n\n' + automatedMessage;
                }

                applicationsToUpdate.add(app);

                System.debug('Marked for closure: ' + app.Name + ' (' + app.Company_Name__c + ')');

            } catch (Exception e) {
                recordsFailed++;
                String errorMsg = 'Error processing application ' + app.Name + ': ' + e.getMessage();
                errorMessages.add(errorMsg);
                System.debug(LoggingLevel.ERROR, errorMsg);
            }
        }

        // Update all applications in bulk
        if (!applicationsToUpdate.isEmpty()) {
            List<Database.SaveResult> results = Database.update(applicationsToUpdate, false);

            // Process results
            for (Integer i = 0; i < results.size(); i++) {
                Database.SaveResult result = results[i];
                if (result.isSuccess()) {
                    recordsClosed++;
                } else {
                    recordsFailed++;
                    String errorMsg = 'Failed to close application ' + applicationsToUpdate[i].Name + ': ';
                    for (Database.Error error : result.getErrors()) {
                        errorMsg += error.getMessage() + '; ';
                    }
                    errorMessages.add(errorMsg);
                    System.debug(LoggingLevel.ERROR, errorMsg);
                }
            }
        }

        System.debug('Batch execution complete. Closed: ' + recordsClosed + ', Failed: ' + recordsFailed);
    }

    /**
     * @description Finish method to send summary email and log results
     * @param bc BatchableContext
     */
    public void finish(Database.BatchableContext bc) {
        System.debug('Finishing Stale Job Application Cleanup Batch');
        System.debug('Total processed: ' + recordsProcessed);
        System.debug('Total closed: ' + recordsClosed);
        System.debug('Total failed: ' + recordsFailed);

        // Send summary email if configured
        if (sendSummaryEmail && String.isNotBlank(summaryEmailRecipient)) {
            sendSummaryEmail(bc);
        }

        // Log batch execution summary
        logBatchExecution(bc);
    }

    /**
     * @description Builds the automated closure message for notes field
     * @param app Job Application record
     * @param daysStale Number of days the application has been stale
     * @return Formatted closure message
     */
    private String buildClosureMessage(Job_Application__c app, Integer daysStale) {
        String message = '═══════════════════════════════════════\n';
        message += '🤖 AUTOMATED CLOSURE\n';
        message += '═══════════════════════════════════════\n';
        message += 'Date: ' + Datetime.now().format('MMMM d, yyyy \'at\' h:mm a') + '\n';
        message += 'Reason: Stale Application Cleanup\n';
        message += 'Follow-up date was ' + daysStale + ' days overdue\n';
        message += 'Previous Status: ' + app.Status__c + '\n';
        message += '\nThis job application was automatically closed because the follow-up date (' +
                   app.Follow_Up_Date__c.format() + ') was more than ' + staleDaysThreshold + ' days ago.\n';
        message += '\nIf you\'d like to continue pursuing this opportunity, please update the status and follow-up date.';

        return message;
    }

    /**
     * @description Sends summary email to configured recipient
     * @param bc BatchableContext
     */
    private void sendSummaryEmail(Database.BatchableContext bc) {
        try {
            AsyncApexJob jobInfo = [
                SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems,
                       CreatedDate, CompletedDate
                FROM AsyncApexJob
                WHERE Id = :bc.getJobId()
            ];

            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new List<String>{summaryEmailRecipient});
            email.setSubject('Stale Job Application Cleanup - Execution Summary');

            // Build HTML email
            String htmlBody = buildSummaryEmailHtml(jobInfo);
            email.setHtmlBody(htmlBody);

            // Build plain text email
            String plainBody = buildSummaryEmailText(jobInfo);
            email.setPlainTextBody(plainBody);

            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{email});

            System.debug('Summary email sent to: ' + summaryEmailRecipient);

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error sending summary email: ' + e.getMessage());
        }
    }

    /**
     * @description Builds HTML summary email body
     * @param jobInfo AsyncApexJob information
     * @return HTML formatted email body
     */
    private String buildSummaryEmailHtml(AsyncApexJob jobInfo) {
        String html = '<html><body style="font-family: Arial, sans-serif; color: #333;">';
        html += '<div style="max-width: 600px; margin: 0 auto; padding: 20px; background-color: #f9f9f9; border-radius: 8px;">';

        // Header
        html += '<h2 style="color: #0070d2; border-bottom: 3px solid #0070d2; padding-bottom: 10px;">🧹 Stale Job Application Cleanup</h2>';
        html += '<p style="font-size: 14px; color: #666;">Execution Summary</p>';

        // Summary Stats
        html += '<div style="background-color: white; padding: 20px; margin: 20px 0; border-radius: 4px;">';
        html += '<h3 style="margin-top: 0; color: #0070d2;">Summary</h3>';
        html += '<table style="width: 100%; border-collapse: collapse;">';
        html += '<tr><td style="padding: 8px 0; border-bottom: 1px solid #eee;"><strong>Applications Processed:</strong></td><td style="padding: 8px 0; border-bottom: 1px solid #eee; text-align: right;">' + recordsProcessed + '</td></tr>';
        html += '<tr><td style="padding: 8px 0; border-bottom: 1px solid #eee;"><strong>Successfully Closed:</strong></td><td style="padding: 8px 0; border-bottom: 1px solid #eee; text-align: right; color: green;"><strong>' + recordsClosed + '</strong></td></tr>';
        html += '<tr><td style="padding: 8px 0; border-bottom: 1px solid #eee;"><strong>Failed:</strong></td><td style="padding: 8px 0; border-bottom: 1px solid #eee; text-align: right; color: red;">' + recordsFailed + '</td></tr>';
        html += '<tr><td style="padding: 8px 0;"><strong>Stale Threshold:</strong></td><td style="padding: 8px 0; text-align: right;">' + staleDaysThreshold + ' days</td></tr>';
        html += '</table>';
        html += '</div>';

        // Job Info
        html += '<div style="background-color: #e8f4f8; padding: 15px; margin: 20px 0; border-radius: 4px;">';
        html += '<strong>Batch Job Details:</strong><br/>';
        html += 'Status: ' + jobInfo.Status + '<br/>';
        html += 'Started: ' + jobInfo.CreatedDate.format('MMMM d, yyyy \'at\' h:mm a') + '<br/>';
        if (jobInfo.CompletedDate != null) {
            html += 'Completed: ' + jobInfo.CompletedDate.format('MMMM d, yyyy \'at\' h:mm a') + '<br/>';
        }
        html += 'Batches Processed: ' + jobInfo.JobItemsProcessed + ' / ' + jobInfo.TotalJobItems;
        html += '</div>';

        // Errors
        if (!errorMessages.isEmpty()) {
            html += '<div style="background-color: #fff3cd; padding: 15px; margin: 20px 0; border-radius: 4px; border-left: 4px solid #ffc107;">';
            html += '<strong>⚠️ Errors (' + errorMessages.size() + '):</strong><br/>';
            html += '<ul style="margin: 10px 0; font-size: 12px;">';
            for (String error : errorMessages) {
                html += '<li>' + error + '</li>';
            }
            html += '</ul>';
            html += '</div>';
        }

        html += '<p style="font-size: 12px; color: #666; margin-top: 30px; border-top: 1px solid #ddd; padding-top: 15px;">';
        html += 'This is an automated email from the Stale Job Application Cleanup process.';
        html += '</p>';

        html += '</div></body></html>';

        return html;
    }

    /**
     * @description Builds plain text summary email body
     * @param jobInfo AsyncApexJob information
     * @return Plain text formatted email body
     */
    private String buildSummaryEmailText(AsyncApexJob jobInfo) {
        String body = '** STALE JOB APPLICATION CLEANUP - EXECUTION SUMMARY **\n\n';
        body += 'SUMMARY\n';
        body += '═══════════════════════════════════════\n';
        body += 'Applications Processed: ' + recordsProcessed + '\n';
        body += 'Successfully Closed: ' + recordsClosed + '\n';
        body += 'Failed: ' + recordsFailed + '\n';
        body += 'Stale Threshold: ' + staleDaysThreshold + ' days\n\n';

        body += 'BATCH JOB DETAILS\n';
        body += '───────────────────────────────────────\n';
        body += 'Status: ' + jobInfo.Status + '\n';
        body += 'Started: ' + jobInfo.CreatedDate.format('MMMM d, yyyy \'at\' h:mm a') + '\n';
        if (jobInfo.CompletedDate != null) {
            body += 'Completed: ' + jobInfo.CompletedDate.format('MMMM d, yyyy \'at\' h:mm a') + '\n';
        }
        body += 'Batches Processed: ' + jobInfo.JobItemsProcessed + ' / ' + jobInfo.TotalJobItems + '\n\n';

        if (!errorMessages.isEmpty()) {
            body += 'ERRORS (' + errorMessages.size() + ')\n';
            body += '───────────────────────────────────────\n';
            for (String error : errorMessages) {
                body += '• ' + error + '\n';
            }
            body += '\n';
        }

        body += '---\n';
        body += 'This is an automated email from the Stale Job Application Cleanup process.\n';

        return body;
    }

    /**
     * @description Logs batch execution details to debug logs
     * @param bc BatchableContext
     */
    private void logBatchExecution(Database.BatchableContext bc) {
        System.debug('═══════════════════════════════════════');
        System.debug('BATCH EXECUTION SUMMARY');
        System.debug('═══════════════════════════════════════');
        System.debug('Job ID: ' + bc.getJobId());
        System.debug('Applications Processed: ' + recordsProcessed);
        System.debug('Successfully Closed: ' + recordsClosed);
        System.debug('Failed: ' + recordsFailed);
        System.debug('Stale Threshold: ' + staleDaysThreshold + ' days');

        if (!errorMessages.isEmpty()) {
            System.debug('Errors:');
            for (String error : errorMessages) {
                System.debug('  - ' + error);
            }
        }

        System.debug('═══════════════════════════════════════');
    }
}
