public with sharing class EmailNotificationQueueable implements Queueable, Database.AllowsCallouts {
    public List<Id> recordIds;
    public EmailType emailType;

    // Enum for email types
    public enum EmailType {
        INTERVIEW_REMINDER,
        POST_INTERVIEW_THANK_YOU,
        APPLICATION_FOLLOW_UP,
        SELF_NOTIFICATION
    }

    // Constructor
    public EmailNotificationQueueable(List<Id> recordIds, EmailType emailType) {
        this.recordIds = recordIds;
        this.emailType = emailType;
    }

    // Execute method
    public void execute(QueueableContext context) {
        switch on emailType {
            when INTERVIEW_REMINDER {
                sendTemplatedEmails('Interview_Reminder_Template');
            }
            when POST_INTERVIEW_THANK_YOU {
                sendTemplatedEmails('Thank_You_Template');
            }
            when APPLICATION_FOLLOW_UP {
                sendTemplatedEmails('Application_Follow_Up_Template');
            }
            when SELF_NOTIFICATION {
                sendTemplatedEmails('Self_Notification_Template');
            }
        }
    }

    // Email sending logic using Visualforce template
    public void sendTemplatedEmails(String templateDeveloperName) {
        List<Event> events = [
            SELECT Id, Subject, StartDateTime, WhoId
            FROM Event
            WHERE Id IN :recordIds
        ];

        EmailTemplate template = [
            SELECT Id FROM EmailTemplate
            WHERE DeveloperName = :templateDeveloperName
            LIMIT 1
        ];

        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        for (Event e : events) {
            if (e.WhoId != null) {
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setTargetObjectId(e.WhoId);  // Contact or Lead
                email.setWhatId(e.Id);             // Required for VF template to access Event
                email.setTemplateId(template.Id);
                email.setSaveAsActivity(false);
                emails.add(email);
            } else {
                System.debug('Skipped Event with no WhoId: ' + e.Id);
            }
        }

        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
            System.debug('Sent ' + emails.size() + ' email(s).');
        } else {
            System.debug('No emails to send.');
        }
    }
}
