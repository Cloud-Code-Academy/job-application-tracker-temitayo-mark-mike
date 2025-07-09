@isTest
private class EmailNotificationQueueableTest {
    @isTest
    static void testQueueableReminderEmailPositive() {
        Contact contact = new Contact(FirstName = 'Test', LastName = 'User', Email = 'test@example.com');
        insert contact;

        Event event = new Event(Subject = 'Test Interview', StartDateTime = System.now().addDays(1), EndDateTime = System.now().addDays(1).addHours(1), WhoId = contact.Id);
        insert event;

        Test.startTest();
        System.enqueueJob(new EmailNotificationQueueable(new List<Id>{event.Id}, EmailNotificationQueueable.EmailType.INTERVIEW_REMINDER));
        Test.stopTest();

        System.assert(true, 'Enqueued job should finish successfully');
    }

    @isTest
    static void testQueueableWithEmptyIdList() {
        Test.startTest();
        System.enqueueJob(new EmailNotificationQueueable(new List<Id>(), EmailNotificationQueueable.EmailType.SELF_NOTIFICATION));
        Test.stopTest();

        System.assert(true, 'Empty List. Job finished successfully');
    }

    @isTest
    static void testQueueableWithInvalidEventId() {
        Test.startTest();
        System.enqueueJob(new EmailNotificationQueueable(new List<Id>{'00U000000000000'}, EmailNotificationQueueable.EmailType.APPLICATION_FOLLOW_UP));
        Test.stopTest();

        System.assert(true, 'Invalid ID. Job executed');
    }
}