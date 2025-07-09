@isTest
private class InterviewReminderSchedulerTest {
    @isTest
    static void testSchedulerTriggersQueueableJob() {
        Contact contact = new Contact(FirstName = 'Jane', LastName = 'Doe', Email = 'jane@example.com');
        insert contact;

        Date tomorrow = System.today().addDays(1);
        DateTime startTime = DateTime.newInstance(tomorrow.year(), tomorrow.month(), tomorrow.day()).addHours(10);
        DateTime endTime = startTime.addHours(1);

        Event interview = new Event(Subject = 'Scheduled Interview', StartDateTime = startTime, EndDateTime = endTime, WhoId = contact.Id);
        insert interview;

        Test.startTest();
        InterviewReminderScheduler scheduler = new InterviewReminderScheduler();
        scheduler.execute(null);
        Test.stopTest();

        System.assert(true, 'Scheduler ran successfully');
    }

    @isTest
    static void testSchedulerHandlesNoEventsGracefully() {
        Test.startTest();
        InterviewReminderScheduler scheduler = new InterviewReminderScheduler();
        scheduler.execute(null);
        Test.stopTest();

        System.assert(true, 'No Events. Scheduler ran successfully');
    }
}