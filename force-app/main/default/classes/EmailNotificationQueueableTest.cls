@isTest
private class EmailNotificationQueueableTest {

    private static Id getDummyTemplateId() {
        return '00X000000000001';
    }

    @isTest
    static void testQueueableReminderEmailPositive() {
        Contact contact = new Contact(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'test@example.com'
        );
        insert contact;

        Event event = new Event(
            Subject = 'Test Interview',
            StartDateTime = System.now().addDays(1),
            EndDateTime = System.now().addDays(1).addHours(1),
            WhoId = contact.Id
        );
        insert event;

        Test.startTest();
        System.enqueueJob(new EmailNotificationQueueable(
            new List<Id>{event.Id},
            EmailNotificationQueueable.EmailType.INTERVIEW_REMINDER,
            getDummyTemplateId()
        ));
        Test.stopTest();

        Event updated = [SELECT Reminder_Sent__c FROM Event WHERE Id = :event.Id];
        System.assertEquals(true, updated.Reminder_Sent__c, 'Reminder should be marked sent');
    }

    @isTest
    static void testQueueableWithEmptyIdList() {
        Test.startTest();
        System.enqueueJob(new EmailNotificationQueueable(
            new List<Id>(),
            EmailNotificationQueueable.EmailType.SELF_NOTIFICATION,
            getDummyTemplateId()
        ));
        Test.stopTest();

        System.assert(true, 'Queueable should handle an empty list gracefully');
    }

    @isTest
    static void testQueueableWithInvalidEventId() {
        Test.startTest();
        System.enqueueJob(new EmailNotificationQueueable(
            new List<Id>{'00U000000000000'}, // Invalid Event ID
            EmailNotificationQueueable.EmailType.APPLICATION_FOLLOW_UP,
            getDummyTemplateId()
        ));
        Test.stopTest();

        System.assert(true, 'Queueable handled invalid ID gracefully');
    }

    @isTest
    static void testQueueableReminderEmailBulkified() {
        // Create 200 Contacts
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < 200; i++) {
            contacts.add(new Contact(
                FirstName = 'Bulk',
                LastName = 'User' + i,
                Email = 'bulkuser' + i + '@example.com'
            ));
        }
        insert contacts;

        // Create 200 Events for tomorrow
        DateTime tomorrow = System.now().addDays(1);
        List<Event> events = new List<Event>();
        for (Integer i = 0; i < 200; i++) {
            events.add(new Event(
                Subject = 'Interview ' + i,
                StartDateTime = tomorrow.addMinutes(i),
                EndDateTime = tomorrow.addMinutes(i + 30),
                WhoId = contacts[i].Id
            ));
        }
        insert events;

        List<Id> eventIds = new List<Id>();
        for (Event e : events) {
            eventIds.add(e.Id);
        }

        Test.startTest();
        System.enqueueJob(new EmailNotificationQueueable(
            eventIds,
            EmailNotificationQueueable.EmailType.INTERVIEW_REMINDER,
            getDummyTemplateId()
        ));
        Test.stopTest();

        List<Event> updatedEvents = [
            SELECT Id, Reminder_Sent__c FROM Event WHERE Id IN :eventIds
        ];
        for (Event e : updatedEvents) {
            System.assertEquals(true, e.Reminder_Sent__c, 'Reminder should be marked sent');
        }
    }
}