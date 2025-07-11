public with sharing class EventTriggerHandler {
    public static void checkForDuplicateStartTimes(List<Event> newEvents) {
        Set<Datetime> startTimes = new Set<Datetime>();
        Map<Id, Event> newEventMap = new Map<Id, Event>();

        for (Event e : newEvents) {
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

        for (Event e : newEvents) {
            for (Event dup : existing) {
                if (e.StartDateTime == dup.StartDateTime) {
                    e.addError('Another Event already exists with the same Start Date/Time.');
                    break;
                }
            }
        }
    }
}
