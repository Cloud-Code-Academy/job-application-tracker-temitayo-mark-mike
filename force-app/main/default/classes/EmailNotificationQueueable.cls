public with sharing class EmailNotificationQueueable implements Queueable, Database.AllowsCallouts {
    public List<Id> recordIds;
    public EmailType emailType;

    public enum EmailType {
        INTERVIEW_REMINDER,
        POST_INTERVIEW_THANK_YOU,
        APPLICATION_FOLLOW_UP,
        SELF_NOTIFICATION
    }

    public EmailNotificationQueueable(List<Id> recordIds, EmailType emailType) {
        this.recordIds = recordIds;
        this.emailType = emailType;
    }

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

    public void sendTemplatedEmails(String templateDeveloperName) {
        // Only query Events that haven't already had reminders sent
        List<Event> events = [
            SELECT Id, Subject, StartDateTime, WhoId, Reminder_Sent__c
            FROM Event
            WHERE Id IN :recordIds
            AND (Reminder_Sent__c = false OR Reminder_Sent__c = null)
        ];

        if (events.isEmpty()) {
            return;
        }

        EmailTemplate template = [
            SELECT Id FROM EmailTemplate
            WHERE DeveloperName = :templateDeveloperName
            LIMIT 1
        ];

        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        List<Event> eventsToUpdate = new List<Event>();

        for (Event e : events) {
            if (e.WhoId != null) {
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setTargetObjectId(e.WhoId);
                email.setWhatId(e.Id);
                email.setTemplateId(template.Id);
                email.setSaveAsActivity(false);
                emails.add(email);

                eventsToUpdate.add(new Event(
                    Id = e.Id,
                    Reminder_Sent__c = true
                ));
            }
        }

        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
            update eventsToUpdate;
        }
    }
}
