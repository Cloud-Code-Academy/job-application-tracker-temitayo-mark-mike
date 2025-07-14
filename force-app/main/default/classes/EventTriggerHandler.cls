public with sharing class EventTriggerHandler {

    // BEFORE INSERT
    public static void onBeforeInsert(List<Event> newEvents) {
        checkForDuplicateStartTimes(newEvents);
    }

    // BEFORE UPDATE
    public static void onBeforeUpdate(List<Event> updatedEvents) {
        checkForDuplicateStartTimes(updatedEvents);
    }

    // AFTER INSERT
    public static void onAfterInsert(List<Event> newEvents) {
        enqueueInterviewReminders(newEvents);
    }

    // AFTER UPDATE
    public static void onAfterUpdate(List<Event> updatedEvents) {
        enqueueInterviewReminders(updatedEvents);
    }

    // DUPLICATE CHECKER
    private static void checkForDuplicateStartTimes(List<Event> events) {
        Set<Datetime> startTimes = new Set<Datetime>();
        Map<Id, Event> newEventMap = new Map<Id, Event>();

        for (Event e : events) {
            if (e.StartDateTime != null) {
                startTimes.add(e.StartDateTime);
                if (e.Id != null) {
                    newEventMap.put(e.Id, e);
                }
            }
        }

        if (startTimes.isEmpty()) return;

        List<Event> existing = [
            SELECT Id, StartDateTime 
            FROM Event 
            WHERE StartDateTime IN :startTimes
            AND Id NOT IN :newEventMap.keySet()
        ];

        for (Event e : events) {
            for (Event dup : existing) {
                if (e.StartDateTime == dup.StartDateTime) {
                    e.addError('Another Event already exists with the same Start Date/Time.');
                    break;
                }
            }
        }
    }

    // REMINDER QUEUEING
    private static void enqueueInterviewReminders(List<Event> events) {
        List<Id> eventIdsToNotify = new List<Id>();

        for (Event e : events) {
            if (
                e.StartDateTime != null &&
                DateTime.now().addDays(1).date() == e.StartDateTime.date() &&
                e.WhoId != null
            ) {
                eventIdsToNotify.add(e.Id);
            }
        }

        if (!eventIdsToNotify.isEmpty()) {
            System.enqueueJob(
                new EmailNotificationQueueable(
                    eventIdsToNotify,
                    EmailNotificationQueueable.EmailType.INTERVIEW_REMINDER
                )
            );
        }
    }
}
