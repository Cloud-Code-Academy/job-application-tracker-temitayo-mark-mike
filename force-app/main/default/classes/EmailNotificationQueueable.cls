public with sharing class EmailNotificationQueueable implements Queueable, Database.AllowsCallouts {
    public List<Id> recordIds;
    public EmailType emailType;
    public Id overrideTemplateId;

    // Optional test-only override
    public static Boolean skipEmailSend = false;

    public enum EmailType {
        INTERVIEW_REMINDER,
        POST_INTERVIEW_THANK_YOU,
        APPLICATION_FOLLOW_UP,
        SELF_NOTIFICATION
    }

    public EmailNotificationQueueable(List<Id> recordIds, EmailType emailType) {
        this(recordIds, emailType, null);
    }

    public EmailNotificationQueueable(List<Id> recordIds, EmailType emailType, Id overrideTemplateId) {
        this.recordIds = recordIds;
        this.emailType = emailType;
        this.overrideTemplateId = overrideTemplateId;
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
        List<Event> events = [
            SELECT Id, Subject, StartDateTime, WhoId, Reminder_Sent__c
            FROM Event
            WHERE Id IN :recordIds
            AND (Reminder_Sent__c = false OR Reminder_Sent__c = null)
        ];

        if (events.isEmpty()) {
            return;
        }

        EmailTemplate template;
        if (overrideTemplateId != null) {
            template = new EmailTemplate(Id = overrideTemplateId);
        } else {
            template = [
                SELECT Id FROM EmailTemplate
                WHERE DeveloperName = :templateDeveloperName
                LIMIT 1
            ];
        }

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
            // Final failsafe: prevent emails in test context
            if (!Test.isRunningTest() && !skipEmailSend) {
                for (List<Messaging.SingleEmailMessage> batch : splitEmailMessages(emails, 10)) {
                    Messaging.sendEmail(batch);
                }
            }
            update eventsToUpdate;
        }
    }

    private static List<List<Messaging.SingleEmailMessage>> splitEmailMessages(List<Messaging.SingleEmailMessage> allEmails, Integer batchSize) {
        List<List<Messaging.SingleEmailMessage>> batches = new List<List<Messaging.SingleEmailMessage>>();
        Integer total = allEmails.size();

        for (Integer i = 0; i < total; i += batchSize) {
            List<Messaging.SingleEmailMessage> batch = new List<Messaging.SingleEmailMessage>();
            for (Integer j = i; j < Math.min(i + batchSize, total); j++) {
                batch.add(allEmails[j]);
            }
            batches.add(batch);
        }

        return batches;
    }
}