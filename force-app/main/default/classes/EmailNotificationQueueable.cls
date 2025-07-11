public with sharing class EmailNotificationQueueable implements Queueable, Database.AllowsCallouts {
    public List<Id> recordIds;
    public EmailType emailType;

    // Enum declaration for each email type
    public enum EmailType {
        INTERVIEW_REMINDER,
        POST_INTERVIEW_THANK_YOU,
        APPLICATION_FOLLOW_UP,
        SELF_NOTIFICATION
    }

    // Constructor takes in the record Ids and the type of email to send
    public EmailNotificationQueueable(List<Id> recordIds, EmailType emailType) {
        this.recordIds = recordIds;
        this.emailType = emailType;
    }

    // Execute method for the queueable
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

    // Shared method to send email templates
    public void sendTemplatedEmails(String templateDeveloperName) {
        List<Event> events = [
            SELECT Id, Subject, StartDateTime, WhoId, WhatId
            FROM Event
            WHERE Id IN :recordIds
        ];

        EmailTemplate template = [
            SELECT Id FROM EmailTemplate WHERE DeveloperName = :templateDeveloperName LIMIT 1
        ];

        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        for (Event e : events) {
            if (e.WhoId != null) {
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setTargetObjectId(e.WhoId);  // Must be Contact or Lead           // Do we want to set the related 'What'?
                email.setTemplateId(template.Id);
                email.setSaveAsActivity(false);
                emails.add(email);
            }
        }

        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }
    }
}