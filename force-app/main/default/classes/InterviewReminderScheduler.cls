/**
 * @description Schedulable class to send interview reminder emails
 * Runs daily to send reminders for interviews scheduled the next day
 * @author Temitayo Oluwalade
 * @date 2024
 */
public class InterviewReminderScheduler implements Schedulable {

    /**
     * @description Execute method for scheduled job
     * @param sc SchedulableContext
     */
    public void execute(SchedulableContext sc) {
        System.debug('Executing Interview Reminder Scheduler');
        sendInterviewReminders();
    }

    /**
     * @description Main method to send interview reminders
     * Queries events scheduled for tomorrow and sends email reminders
     */
    public static void sendInterviewReminders() {
        // Calculate tomorrow's date range (00:00 to 23:59)
        Date tomorrow = Date.today().addDays(1);
        Datetime tomorrowStart = Datetime.newInstance(tomorrow, Time.newInstance(0, 0, 0, 0));
        Datetime tomorrowEnd = Datetime.newInstance(tomorrow, Time.newInstance(23, 59, 59, 0));

        System.debug('Searching for interviews between ' + tomorrowStart + ' and ' + tomorrowEnd);

        // Query events scheduled for tomorrow
        List<Event> upcomingInterviews = [
            SELECT Id, Subject, StartDateTime, EndDateTime, Location, Description,
                   Owner.Email, Owner.Name, WhatId, What.Type,
                   What.Name  // Job Application name if WhatId is set
            FROM Event
            WHERE StartDateTime >= :tomorrowStart
            AND StartDateTime <= :tomorrowEnd
            AND Owner.Email != null
            AND IsDeleted = false
            ORDER BY StartDateTime ASC
        ];

        System.debug('Found ' + upcomingInterviews.size() + ' interviews scheduled for tomorrow');

        if (upcomingInterviews.isEmpty()) {
            System.debug('No interviews scheduled for tomorrow. No reminders to send.');
            return;
        }

        // Send reminder emails
        Integer emailsSent = 0;
        Integer emailsFailed = 0;
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        for (Event interview : upcomingInterviews) {
            try {
                Messaging.SingleEmailMessage email = buildReminderEmail(interview);
                if (email != null) {
                    emails.add(email);
                }
            } catch (Exception e) {
                emailsFailed++;
                System.debug(LoggingLevel.ERROR, 'Error building reminder for event ' + interview.Id + ': ' + e.getMessage());
            }
        }

        // Send all emails in bulk
        if (!emails.isEmpty()) {
            try {
                List<Messaging.SendEmailResult> results = Messaging.sendEmail(emails);

                // Log results
                for (Integer i = 0; i < results.size(); i++) {
                    Messaging.SendEmailResult result = results[i];
                    if (result.isSuccess()) {
                        emailsSent++;
                        System.debug('Interview reminder sent successfully for event: ' + upcomingInterviews[i].Subject);
                    } else {
                        emailsFailed++;
                        for (Messaging.SendEmailError error : result.getErrors()) {
                            System.debug(LoggingLevel.ERROR, 'Email send error: ' + error.getMessage());
                        }
                    }
                }

                System.debug('Interview reminders sent: ' + emailsSent + ' succeeded, ' + emailsFailed + ' failed');

            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Error sending interview reminder emails: ' + e.getMessage());
            }
        }
    }

    /**
     * @description Builds a reminder email for an interview
     * @param interview Event record representing the interview
     * @return Messaging.SingleEmailMessage configured with reminder content
     */
    private static Messaging.SingleEmailMessage buildReminderEmail(Event interview) {
        if (String.isBlank(interview.Owner.Email)) {
            System.debug('No email address for event owner: ' + interview.Owner.Name);
            return null;
        }

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

        // Set recipient
        email.setToAddresses(new List<String>{interview.Owner.Email});

        // Set subject
        String subject = '🗓️ Interview Reminder: ' + interview.Subject + ' Tomorrow';
        email.setSubject(subject);

        // Build email body (HTML)
        String htmlBody = buildHtmlEmailBody(interview);
        email.setHtmlBody(htmlBody);

        // Set plain text body as fallback
        String plainTextBody = buildPlainTextEmailBody(interview);
        email.setPlainTextBody(plainTextBody);

        // Link email to the Event record
        email.setWhatId(interview.Id);

        // Save email as activity
        email.setSaveAsActivity(true);

        return email;
    }

    /**
     * @description Builds HTML email body for interview reminder
     * @param interview Event record
     * @return HTML formatted email body
     */
    private static String buildHtmlEmailBody(Event interview) {
        String interviewDate = interview.StartDateTime.format('EEEE, MMMM d, yyyy');
        String startTime = interview.StartDateTime.format('h:mm a');
        String endTime = interview.EndDateTime.format('h:mm a');

        String html = '<html><body style="font-family: Arial, sans-serif; color: #333;">';
        html += '<div style="max-width: 600px; margin: 0 auto; padding: 20px; background-color: #f9f9f9; border-radius: 8px;">';

        // Header
        html += '<h2 style="color: #0070d2; border-bottom: 3px solid #0070d2; padding-bottom: 10px;">📅 Interview Reminder</h2>';

        // Greeting
        html += '<p style="font-size: 16px;">Hi ' + interview.Owner.Name + ',</p>';
        html += '<p style="font-size: 14px;">This is a friendly reminder about your upcoming interview tomorrow:</p>';

        // Interview Details Box
        html += '<div style="background-color: white; padding: 20px; margin: 20px 0; border-left: 4px solid #0070d2; border-radius: 4px;">';
        html += '<h3 style="margin-top: 0; color: #0070d2;">' + interview.Subject + '</h3>';

        html += '<table style="width: 100%; border-collapse: collapse;">';
        html += '<tr><td style="padding: 8px 0;"><strong>📅 Date:</strong></td><td style="padding: 8px 0;">' + interviewDate + '</td></tr>';
        html += '<tr><td style="padding: 8px 0;"><strong>🕒 Time:</strong></td><td style="padding: 8px 0;">' + startTime + ' - ' + endTime + '</td></tr>';

        if (String.isNotBlank(interview.Location)) {
            html += '<tr><td style="padding: 8px 0;"><strong>📍 Location:</strong></td><td style="padding: 8px 0;">' + interview.Location + '</td></tr>';
        }

        // Job Application details if available
        if (interview.WhatId != null && interview.What.Type == 'Job_Application__c') {
            html += '<tr><td style="padding: 8px 0;"><strong>💼 Job Application:</strong></td><td style="padding: 8px 0;">' + interview.What.Name + '</td></tr>';
        }

        html += '</table>';
        html += '</div>';

        // Additional Notes
        if (String.isNotBlank(interview.Description)) {
            html += '<div style="background-color: #fffaf0; padding: 15px; margin: 20px 0; border-radius: 4px; border: 1px solid #ffd966;">';
            html += '<strong>📝 Notes:</strong><br/>';
            html += '<p style="margin: 10px 0 0 0;">' + interview.Description.replaceAll('\n', '<br/>') + '</p>';
            html += '</div>';
        }

        // Preparation Tips
        html += '<div style="background-color: #e8f4f8; padding: 15px; margin: 20px 0; border-radius: 4px;">';
        html += '<strong>💡 Preparation Tips:</strong>';
        html += '<ul style="margin: 10px 0;">';
        html += '<li>Review the job description and your application</li>';
        html += '<li>Prepare examples of your relevant experience</li>';
        html += '<li>Research the company and interviewer</li>';
        html += '<li>Test your technology if it\'s a virtual interview</li>';
        html += '<li>Prepare thoughtful questions to ask</li>';
        html += '</ul>';
        html += '</div>';

        // Closing
        html += '<p style="font-size: 14px; margin-top: 30px;">Good luck with your interview! 🍀</p>';
        html += '<p style="font-size: 12px; color: #666; margin-top: 30px; border-top: 1px solid #ddd; padding-top: 15px;">';
        html += 'This is an automated reminder from your Job Application Tracker.<br/>';
        html += 'View this interview in Salesforce for more details.';
        html += '</p>';

        html += '</div></body></html>';

        return html;
    }

    /**
     * @description Builds plain text email body for interview reminder
     * @param interview Event record
     * @return Plain text formatted email body
     */
    private static String buildPlainTextEmailBody(Event interview) {
        String interviewDate = interview.StartDateTime.format('EEEE, MMMM d, yyyy');
        String startTime = interview.StartDateTime.format('h:mm a');
        String endTime = interview.EndDateTime.format('h:mm a');

        String body = '** INTERVIEW REMINDER **\n\n';
        body += 'Hi ' + interview.Owner.Name + ',\n\n';
        body += 'This is a friendly reminder about your upcoming interview tomorrow:\n\n';

        body += '═══════════════════════════════════════\n';
        body += interview.Subject + '\n';
        body += '═══════════════════════════════════════\n\n';

        body += 'Date: ' + interviewDate + '\n';
        body += 'Time: ' + startTime + ' - ' + endTime + '\n';

        if (String.isNotBlank(interview.Location)) {
            body += 'Location: ' + interview.Location + '\n';
        }

        if (interview.WhatId != null && interview.What.Type == 'Job_Application__c') {
            body += 'Job Application: ' + interview.What.Name + '\n';
        }

        if (String.isNotBlank(interview.Description)) {
            body += '\nNotes:\n' + interview.Description + '\n';
        }

        body += '\n───────────────────────────────────────\n';
        body += 'PREPARATION TIPS:\n';
        body += '───────────────────────────────────────\n';
        body += '• Review the job description and your application\n';
        body += '• Prepare examples of your relevant experience\n';
        body += '• Research the company and interviewer\n';
        body += '• Test your technology if it\'s a virtual interview\n';
        body += '• Prepare thoughtful questions to ask\n\n';

        body += 'Good luck with your interview!\n\n';
        body += '---\n';
        body += 'This is an automated reminder from your Job Application Tracker.\n';
        body += 'View this interview in Salesforce for more details.\n';

        return body;
    }

    /**
     * @description Schedules the interview reminder job to run daily
     * @param jobName Name for the scheduled job
     * @param cronExpression Cron expression for scheduling (default: daily at 8 AM)
     * @return Scheduled job ID
     */
    public static String scheduleDaily(String jobName, String cronExpression) {
        // Default cron expression: Run daily at 8:00 AM
        // Format: Seconds Minutes Hours Day_of_month Month Day_of_week optional_year
        String cron = String.isNotBlank(cronExpression) ? cronExpression : '0 0 8 * * ?';

        InterviewReminderScheduler scheduler = new InterviewReminderScheduler();
        return System.schedule(jobName, cron, scheduler);
    }

    /**
     * @description Convenience method to schedule with default settings
     * @return Scheduled job ID
     */
    public static String scheduleDaily() {
        return scheduleDaily('Daily Interview Reminder Job', '0 0 8 * * ?');
    }
}
