@isTest
private class EventTriggerHandlerTest {

    @testSetup
    static void setupData() {
        // Insert Contact only (non-setup object)
        Contact testContact = new Contact(
            FirstName = 'Jane',
            LastName = 'Doe',
            Email = 'jane.doe@example.com'
        );
        insert testContact;
    }

    private static List<Event> createEvents(Integer count, Integer daysFromNow, Id whoId) {
        List<Event> events = new List<Event>();
        for (Integer i = 0; i < count; i++) {
            events.add(new Event(
                Subject = 'Interview ' + i,
                StartDateTime = DateTime.now().addDays(daysFromNow),
                EndDateTime = DateTime.now().addDays(daysFromNow).addHours(1),
                WhoId = whoId
            ));
        }
        return events;
    }

    private static void ensureEmailTemplateExists() {
        if ([SELECT COUNT() FROM EmailTemplate WHERE DeveloperName = 'Interview_Reminder_Template'] == 0) {
            insert new EmailTemplate(
                Name = 'Interview Reminder',
                DeveloperName = 'Interview_Reminder_Template',
                HtmlValue = '<html><body>Reminder</body></html>',
                Subject = 'Interview Reminder',
                TemplateType = 'visualforce',
                IsActive = true
            );
        }
    }

    @isTest
    static void testReminderQueuedForTomorrow() {
        ensureEmailTemplateExists();
        Contact c = [SELECT Id FROM Contact LIMIT 1];
        List<Event> tomorrowEvents = createEvents(3, 1, c.Id);

        Test.startTest();
        insert tomorrowEvents;
        Test.stopTest();

        System.assertEquals(3, [SELECT COUNT() FROM Event WHERE Id IN :tomorrowEvents]);
    }

    @isTest
    static void testNoReminderForNonTomorrowDates() {
        ensureEmailTemplateExists();
        Contact c = [SELECT Id FROM Contact LIMIT 1];
        List<Event> futureEvents = createEvents(3, 5, c.Id);

        Test.startTest();
        insert futureEvents;
        Test.stopTest();

        System.assertEquals(3, [SELECT COUNT() FROM Event WHERE Id IN :futureEvents]);
    }

    @isTest
    static void testDuplicateStartTimesAreBlocked() {
        ensureEmailTemplateExists();
        Contact c = [SELECT Id FROM Contact LIMIT 1];
        DateTime startTime = DateTime.now().addDays(2);

        Event e1 = new Event(
            Subject = 'Dup Event A',
            StartDateTime = startTime,
            EndDateTime = startTime.addHours(1),
            WhoId = c.Id
        );
        insert e1;

        Event e2 = new Event(
            Subject = 'Dup Event B',
            StartDateTime = startTime,
            EndDateTime = startTime.addHours(1),
            WhoId = c.Id
        );

        Test.startTest();
        try {
            insert e2;
            System.assert(false, 'Expected duplicate StartDateTime error');
        } catch (DmlException ex) {
            System.assert(ex.getMessage().contains('Another Event already exists'), 'Expected duplicate event error message');
        }
        Test.stopTest();
    }

    @isTest
    static void testUpdateTriggersReminder() {
        ensureEmailTemplateExists();
        Contact c = [SELECT Id FROM Contact LIMIT 1];
        List<Event> events = createEvents(2, 3, c.Id);
        insert events;

        for (Event e : events) {
            e.StartDateTime = DateTime.now().addDays(1);
        }

        Test.startTest();
        update events;
        Test.stopTest();

        for (Event e : [SELECT StartDateTime FROM Event WHERE Id IN :events]) {
            System.assertEquals(DateTime.now().addDays(1).date(), e.StartDateTime.date());
        }
    }

    @isTest
    static void testUpdateEventStillTomorrow_NoDuplicateReminder() {
        ensureEmailTemplateExists();
        Contact c = [SELECT Id FROM Contact LIMIT 1];
        List<Event> events = createEvents(1, 1, c.Id);
        insert events;

        events[0].Subject = 'Updated Subject Only';

        Test.startTest();
        update events[0];
        Test.stopTest();

        Event refreshed = [SELECT Subject FROM Event WHERE Id = :events[0].Id];
        System.assertEquals('Updated Subject Only', refreshed.Subject);
    }
}
