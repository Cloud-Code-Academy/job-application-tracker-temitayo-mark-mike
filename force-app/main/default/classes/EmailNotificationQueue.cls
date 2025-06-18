/**
 * @description Queueable job for sending asynchronous email notifications
 * @author Temitayo Oluwalade
 * @date 2024
 */
public class EmailNotificationQueue implements Queueable, Database.AllowsCallouts {
    
    private List<EmailNotification> notifications;
    private static final Integer MAX_EMAILS_PER_EXECUTION = 100;
    
    /**
     * @description Constructor
     * @param notifications List of email notifications to send
     */
    public EmailNotificationQueue(List<EmailNotification> notifications) {
        this.notifications = notifications != null ? notifications : new List<EmailNotification>();
    }
    
    /**
     * @description Execute method for queueable job
     * @param context QueueableContext
     */
    public void execute(QueueableContext context) {
        System.debug('Executing email notification queue with ' + notifications.size() + ' notifications');
        
        if (notifications.isEmpty()) {
            System.debug('No notifications to process');
            return;
        }
        
        List<EmailNotification> currentBatch = new List<EmailNotification>();
        List<EmailNotification> remainingNotifications = new List<EmailNotification>();
        
        // Split notifications into current batch and remaining
        for (Integer i = 0; i < notifications.size(); i++) {
            if (i < MAX_EMAILS_PER_EXECUTION) {
                currentBatch.add(notifications[i]);
            } else {
                remainingNotifications.add(notifications[i]);
            }
        }
        
        // Process current batch
        processEmailBatch(currentBatch);
        
        // Chain next batch if there are remaining notifications
        if (!remainingNotifications.isEmpty()) {
            System.enqueueJob(new EmailNotificationQueue(remainingNotifications));
        }
    }
    
    /**
     * @description Processes a batch of email notifications
     * @param batch List of notifications to process
     */
    private void processEmailBatch(List<EmailNotification> batch) {
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        
        for (EmailNotification notification : batch) {
            try {
                Messaging.SingleEmailMessage email = buildEmail(notification);
                if (email != null) {
                    emails.add(email);
                }
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Error building email for notification: ' + e.getMessage());
            }
        }
        
        // Send emails in bulk
        if (!emails.isEmpty()) {
            sendEmails(emails);
        }
    }
    
    /**
     * @description Builds an email message from notification data
     * @param notification EmailNotification object
     * @return Messaging.SingleEmailMessage
     */
    private Messaging.SingleEmailMessage buildEmail(EmailNotification notification) {
        if (String.isBlank(notification.recipientEmail)) {
            System.debug('No recipient email provided for notification');
            return null;
        }
        
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        
        // Set recipient
        email.setToAddresses(new List<String>{notification.recipientEmail});
        
        // Set sender (use org-wide email address if available)
        if (String.isNotBlank(notification.senderEmail)) {
            email.setReplyTo(notification.senderEmail);
        }
        
        // Set subject and body
        email.setSubject(notification.subject);
        
        if (notification.isHtml) {
            email.setHtmlBody(notification.body);
        } else {
            email.setPlainTextBody(notification.body);
        }
        
        // Set related record ID if provided
        if (String.isNotBlank(notification.relatedRecordId)) {
            email.setWhatId(notification.relatedRecordId);
        }
        
        // Set template if provided
        if (String.isNotBlank(notification.templateId)) {
            email.setTemplateId(notification.templateId);
        }
        
        return email;
    }
    
    /**
     * @description Sends emails using Messaging.sendEmail
     * @param emails List of email messages to send
     */
    private void sendEmails(List<Messaging.SingleEmailMessage> emails) {
        try {
            List<Messaging.SendEmailResult> results = Messaging.sendEmail(emails);
            
            // Log results
            for (Integer i = 0; i < results.size(); i++) {
                Messaging.SendEmailResult result = results[i];
                if (result.isSuccess()) {
                    System.debug('Email sent successfully to: ' + emails[i].getToAddresses()[0]);
                } else {
                    for (Messaging.SendEmailError error : result.getErrors()) {
                        System.debug(LoggingLevel.ERROR, 'Email send error: ' + error.getMessage());
                    }
                }
            }
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error sending emails: ' + e.getMessage());
        }
    }
    
    /**
     * @description Static method to enqueue job application status notifications
     * @param jobApplicationIds List of Job Application IDs
     * @param notificationType Type of notification to send
     */
    public static void enqueueJobApplicationNotifications(List<Id> jobApplicationIds, String notificationType) {
        if (jobApplicationIds == null || jobApplicationIds.isEmpty()) {
            return;
        }
        
        List<EmailNotification> notifications = buildJobApplicationNotifications(jobApplicationIds, notificationType);
        
        if (!notifications.isEmpty()) {
            System.enqueueJob(new EmailNotificationQueue(notifications));
        }
    }
    
    /**
     * @description Builds email notifications for job applications
     * @param jobApplicationIds List of Job Application IDs
     * @param notificationType Type of notification
     * @return List of EmailNotification objects
     */
    private static List<EmailNotification> buildJobApplicationNotifications(List<Id> jobApplicationIds, String notificationType) {
        List<EmailNotification> notifications = new List<EmailNotification>();
        
        // Query job applications with owner information
        List<Job_Application__c> jobApps = [
            SELECT Id, Name, Company_Name__c, Position_Title__c, Status__c, 
                   Owner.Email, Owner.Name, Salary__c, Market_Salary_Median__c,
                   Salary_Competitiveness__c
            FROM Job_Application__c 
            WHERE Id IN :jobApplicationIds
            AND Owner.Email != null
        ];
        
        for (Job_Application__c app : jobApps) {
            EmailNotification notification = buildNotificationForType(app, notificationType);
            if (notification != null) {
                notifications.add(notification);
            }
        }
        
        return notifications;
    }
    
    /**
     * @description Builds notification based on type
     * @param app Job Application record
     * @param notificationType Type of notification
     * @return EmailNotification object
     */
    private static EmailNotification buildNotificationForType(Job_Application__c app, String notificationType) {
        switch on notificationType {
            when 'MARKET_ANALYSIS_COMPLETE' {
                return buildMarketAnalysisNotification(app);
            }
            when 'STATUS_REMINDER' {
                return buildStatusReminderNotification(app);
            }
            when 'SALARY_ALERT' {
                return buildSalaryAlertNotification(app);
            }
            when else {
                return null;
            }
        }
    }
    
    /**
     * @description Builds market analysis completion notification
     * @param app Job Application record
     * @return EmailNotification object
     */
    private static EmailNotification buildMarketAnalysisNotification(Job_Application__c app) {
        String subject = 'Market Analysis Complete: ' + app.Position_Title__c + ' at ' + app.Company_Name__c;
        
        String body = 'Hi ' + app.Owner.Name + ',\n\n' +
                     'We\'ve completed the market analysis for your job application:\n\n' +
                     'Position: ' + app.Position_Title__c + '\n' +
                     'Company: ' + app.Company_Name__c + '\n' +
                     'Your Offer: $' + (app.Salary__c != null ? app.Salary__c.format() : 'Not specified') + '\n' +
                     'Market Median: $' + (app.Market_Salary_Median__c != null ? app.Market_Salary_Median__c.format() : 'N/A') + '\n' +
                     'Competitiveness: ' + (app.Salary_Competitiveness__c != null ? app.Salary_Competitiveness__c : 'Unknown') + '\n\n' +
                     'View the full analysis in Salesforce.\n\n' +
                     'Best regards,\n' +
                     'Job Application Tracker';
        
        return new EmailNotification(
            app.Owner.Email,
            subject,
            body,
            false,
            app.Id,
            null,
            null
        );
    }
    
    /**
     * @description Builds status reminder notification
     * @param app Job Application record
     * @return EmailNotification object
     */
    private static EmailNotification buildStatusReminderNotification(Job_Application__c app) {
        String subject = 'Follow-up Reminder: ' + app.Position_Title__c + ' at ' + app.Company_Name__c;
        
        String body = 'Hi ' + app.Owner.Name + ',\n\n' +
                     'This is a friendly reminder about your job application:\n\n' +
                     'Position: ' + app.Position_Title__c + '\n' +
                     'Company: ' + app.Company_Name__c + '\n' +
                     'Current Status: ' + app.Status__c + '\n\n' +
                     'Consider following up if you haven\'t heard back recently.\n\n' +
                     'Best regards,\n' +
                     'Job Application Tracker';
        
        return new EmailNotification(
            app.Owner.Email,
            subject,
            body,
            false,
            app.Id,
            null,
            null
        );
    }
    
    /**
     * @description Builds salary alert notification
     * @param app Job Application record
     * @return EmailNotification object
     */
    private static EmailNotification buildSalaryAlertNotification(Job_Application__c app) {
        if (app.Salary_Competitiveness__c != 'Below Market') {
            return null; // Only send alerts for below market offers
        }
        
        String subject = 'Salary Alert: Below Market Offer - ' + app.Position_Title__c;
        
        String body = 'Hi ' + app.Owner.Name + ',\n\n' +
                     'Our analysis indicates that the salary offer for this position may be below market rate:\n\n' +
                     'Position: ' + app.Position_Title__c + '\n' +
                     'Company: ' + app.Company_Name__c + '\n' +
                     'Offered Salary: $' + (app.Salary__c != null ? app.Salary__c.format() : 'Not specified') + '\n' +
                     'Market Median: $' + (app.Market_Salary_Median__c != null ? app.Market_Salary_Median__c.format() : 'N/A') + '\n\n' +
                     'Consider negotiating for a higher salary based on market data.\n\n' +
                     'Best regards,\n' +
                     'Job Application Tracker';
        
        return new EmailNotification(
            app.Owner.Email,
            subject,
            body,
            false,
            app.Id,
            null,
            null
        );
    }
    
    /**
     * @description Inner class to hold email notification data
     */
    public class EmailNotification {
        public String recipientEmail;
        public String subject;
        public String body;
        public Boolean isHtml;
        public String relatedRecordId;
        public String templateId;
        public String senderEmail;
        
        public EmailNotification(String email, String subj, String bod, Boolean html, 
                               String recordId, String template, String sender) {
            this.recipientEmail = email;
            this.subject = subj;
            this.body = bod;
            this.isHtml = html != null ? html : false;
            this.relatedRecordId = recordId;
            this.templateId = template;
            this.senderEmail = sender;
        }
    }
}
