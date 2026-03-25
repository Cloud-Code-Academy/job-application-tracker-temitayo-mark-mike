/**
 * @description Queueable class for sending feedback-related notifications
 * Handles email notifications when interview feedback reaches certain thresholds
 * @author Temitayo Oluwalade
 * @date 2024
 */
public inherited sharing class FeedbackNotificationQueueable implements Queueable {
    
    private List<Job_Application__c> jobApplications;
    
    /**
     * @description Constructor
     * @param jobApplications List of job applications that need notifications
     */
    public FeedbackNotificationQueueable(List<Job_Application__c> jobApplications) {
        this.jobApplications = jobApplications;
    }
    
    /**
     * @description Execute method for queueable interface
     * @param context Queueable context
     */
    public void execute(QueueableContext context) {
        if (jobApplications == null || jobApplications.isEmpty()) {
            return;
        }
        
        try {
            sendFeedbackNotifications();
        } catch (Exception e) {
            System.debug('Error sending feedback notifications: ' + e.getMessage());
            // Log error but don't throw to avoid breaking the queue
        }
    }
    
    /**
     * @description Sends email notifications based on feedback thresholds
     */
    private void sendFeedbackNotifications() {
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
        
        // Get current user for notifications
        User currentUser = [SELECT Id, Email FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        
        for (Job_Application__c jobApp : jobApplications) {
            Messaging.SingleEmailMessage email = createNotificationEmail(jobApp, currentUser);
            if (email != null) {
                emailsToSend.add(email);
            }
        }
        
        if (!emailsToSend.isEmpty() && !Test.isRunningTest()) {
            try {
                Messaging.sendEmail(emailsToSend);
                System.debug('Sent ' + emailsToSend.size() + ' feedback notification emails');
            } catch (Exception e) {
                System.debug('Error sending emails: ' + e.getMessage());
            }
        }
    }
    
    /**
     * @description Creates notification email for job application
     * @param jobApp Job application record
     * @param recipient User to receive notification
     * @return Email message or null if no notification needed
     */
    private Messaging.SingleEmailMessage createNotificationEmail(Job_Application__c jobApp, User recipient) {
        String subject = '';
        String body = '';
        
        // Determine notification type and content
        if (jobApp.Average_Interview_Rating__c != null && jobApp.Average_Interview_Rating__c >= 4.0) {
            subject = 'Excellent Interview Performance - ' + jobApp.Position_Title__c;
            body = buildHighPerformanceEmailBody(jobApp);
        } else if (jobApp.Average_Interview_Rating__c != null && jobApp.Average_Interview_Rating__c <= 2.5) {
            subject = 'Interview Performance Review Needed - ' + jobApp.Position_Title__c;
            body = buildLowPerformanceEmailBody(jobApp);
        } else if (jobApp.Interview_Success_Score__c != null && jobApp.Interview_Success_Score__c >= 80.0) {
            subject = 'High Success Score Achieved - ' + jobApp.Position_Title__c;
            body = buildHighSuccessScoreEmailBody(jobApp);
        } else if (jobApp.Total_Interview_Count__c != null) {
            Integer count = Integer.valueOf(jobApp.Total_Interview_Count__c);
            if (count >= 3) {
                subject = 'Multiple Interviews Completed - ' + jobApp.Position_Title__c;
                body = buildMultipleInterviewsEmailBody(jobApp, count);
            }
        }
        
        if (String.isBlank(subject) || String.isBlank(body)) {
            return null;
        }
        
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new String[] { recipient.Email });
        email.setSubject(subject);
        email.setHtmlBody(body);
        email.setSaveAsActivity(false);
        
        return email;
    }
    
    /**
     * @description Builds email body for high performance notification
     * @param jobApp Job application record
     * @return HTML email body
     */
    private String buildHighPerformanceEmailBody(Job_Application__c jobApp) {
        return '<html><body>' +
               '<h2>🎉 Excellent Interview Performance!</h2>' +
               '<p>Great news! Your interview performance for <strong>' + jobApp.Position_Title__c + '</strong> ' +
               'at <strong>' + jobApp.Company_Name__c + '</strong> has been outstanding.</p>' +
               '<h3>Performance Summary:</h3>' +
               '<ul>' +
               '<li><strong>Average Rating:</strong> ' + jobApp.Average_Interview_Rating__c + '/5.0</li>' +
               '<li><strong>Success Score:</strong> ' + (jobApp.Interview_Success_Score__c != null ? jobApp.Interview_Success_Score__c + '/100' : 'N/A') + '</li>' +
               '<li><strong>Total Interviews:</strong> ' + (jobApp.Total_Interview_Count__c != null ? jobApp.Total_Interview_Count__c : '0') + '</li>' +
               '</ul>' +
               '<h3>Recommended Next Steps:</h3>' +
               '<div style="background-color: #f0f9ff; padding: 15px; border-left: 4px solid #0ea5e9;">' +
               (String.isNotBlank(jobApp.Next_Steps__c) ? jobApp.Next_Steps__c.replace('\\n', '<br>') : 'Review next steps in your job application record.') +
               '</div>' +
               '<p>Keep up the excellent work!</p>' +
               '</body></html>';
    }
    
    /**
     * @description Builds email body for low performance notification
     * @param jobApp Job application record
     * @return HTML email body
     */
    private String buildLowPerformanceEmailBody(Job_Application__c jobApp) {
        return '<html><body>' +
               '<h2>📋 Interview Performance Review</h2>' +
               '<p>Your recent interview performance for <strong>' + jobApp.Position_Title__c + '</strong> ' +
               'at <strong>' + jobApp.Company_Name__c + '</strong> may benefit from some attention.</p>' +
               '<h3>Performance Summary:</h3>' +
               '<ul>' +
               '<li><strong>Average Rating:</strong> ' + jobApp.Average_Interview_Rating__c + '/5.0</li>' +
               '<li><strong>Total Interviews:</strong> ' + (jobApp.Total_Interview_Count__c != null ? jobApp.Total_Interview_Count__c : '0') + '</li>' +
               '</ul>' +
               '<h3>Feedback Summary:</h3>' +
               '<div style="background-color: #fef3c7; padding: 15px; border-left: 4px solid #f59e0b;">' +
               (String.isNotBlank(jobApp.Feedback_Summary__c) ? jobApp.Feedback_Summary__c.replace('\\n', '<br>') : 'Review detailed feedback in your job application record.') +
               '</div>' +
               '<h3>Recommended Actions:</h3>' +
               '<div style="background-color: #f0f9ff; padding: 15px; border-left: 4px solid #0ea5e9;">' +
               (String.isNotBlank(jobApp.Next_Steps__c) ? jobApp.Next_Steps__c.replace('\\n', '<br>') : 'Review recommended next steps in your job application record.') +
               '</div>' +
               '<p>Consider this an opportunity for growth and improvement!</p>' +
               '</body></html>';
    }
    
    /**
     * @description Builds email body for high success score notification
     * @param jobApp Job application record
     * @return HTML email body
     */
    private String buildHighSuccessScoreEmailBody(Job_Application__c jobApp) {
        return '<html><body>' +
               '<h2>🚀 High Success Score Achieved!</h2>' +
               '<p>Congratulations! You\'ve achieved a high success score for <strong>' + jobApp.Position_Title__c + '</strong> ' +
               'at <strong>' + jobApp.Company_Name__c + '</strong>.</p>' +
               '<h3>Performance Metrics:</h3>' +
               '<ul>' +
               '<li><strong>Success Score:</strong> ' + jobApp.Interview_Success_Score__c + '/100</li>' +
               '<li><strong>Average Rating:</strong> ' + (jobApp.Average_Interview_Rating__c != null ? jobApp.Average_Interview_Rating__c + '/5.0' : 'N/A') + '</li>' +
               '<li><strong>Total Interviews:</strong> ' + (jobApp.Total_Interview_Count__c != null ? jobApp.Total_Interview_Count__c : '0') + '</li>' +
               '</ul>' +
               '<p>This high score indicates strong interview performance and positive feedback trends. ' +
               'You\'re well-positioned for success with this opportunity!</p>' +
               '<h3>Next Steps:</h3>' +
               '<div style="background-color: #f0fdf4; padding: 15px; border-left: 4px solid #22c55e;">' +
               (String.isNotBlank(jobApp.Next_Steps__c) ? jobApp.Next_Steps__c.replace('\\n', '<br>') : 'Continue with your current approach and prepare for potential next rounds.') +
               '</div>' +
               '</body></html>';
    }
    
    /**
     * @description Builds email body for multiple interviews notification
     * @param jobApp Job application record
     * @param interviewCount Number of interviews completed
     * @return HTML email body
     */
    private String buildMultipleInterviewsEmailBody(Job_Application__c jobApp, Integer interviewCount) {
        return '<html><body>' +
               '<h2>📊 Interview Progress Update</h2>' +
               '<p>You\'ve now completed <strong>' + interviewCount + ' interviews</strong> for <strong>' + jobApp.Position_Title__c + '</strong> ' +
               'at <strong>' + jobApp.Company_Name__c + '</strong>.</p>' +
               '<h3>Progress Summary:</h3>' +
               '<ul>' +
               '<li><strong>Total Interviews:</strong> ' + interviewCount + '</li>' +
               '<li><strong>Average Rating:</strong> ' + (jobApp.Average_Interview_Rating__c != null ? jobApp.Average_Interview_Rating__c + '/5.0' : 'N/A') + '</li>' +
               '<li><strong>Success Score:</strong> ' + (jobApp.Interview_Success_Score__c != null ? jobApp.Interview_Success_Score__c + '/100' : 'N/A') + '</li>' +
               '<li><strong>Last Interview:</strong> ' + (jobApp.Last_Interview_Date__c != null ? jobApp.Last_Interview_Date__c.format() : 'N/A') + '</li>' +
               '</ul>' +
               '<h3>Performance Trends:</h3>' +
               '<div style="background-color: #f8fafc; padding: 15px; border-left: 4px solid #64748b;">' +
               (String.isNotBlank(jobApp.Feedback_Summary__c) ? jobApp.Feedback_Summary__c.replace('\\n', '<br>') : 'Review detailed feedback trends in your job application record.') +
               '</div>' +
               '<p>Multiple interviews indicate strong mutual interest. Keep up the momentum!</p>' +
               '</body></html>';
    }
}