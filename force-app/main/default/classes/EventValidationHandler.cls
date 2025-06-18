/**
 * @description Handler class for Event validation trigger
 * Manages calendar validation logic including double-booking prevention
 * @author Temitayo Oluwalade
 * @date 2024
 */
public with sharing class EventValidationHandler {
    
    /**
     * @description Handles before insert logic
     * @param newEvents List of new Event records
     */
    public void beforeInsert(List<Event> newEvents) {
        validateEventScheduling(newEvents, null);
    }
    
    /**
     * @description Handles before update logic
     * @param newEvents List of updated Event records
     * @param oldMap Map of old Event records
     */
    public void beforeUpdate(List<Event> newEvents, Map<Id, Event> oldMap) {
        validateEventScheduling(newEvents, oldMap);
    }
    
    /**
     * @description Validates event scheduling rules
     * @param events List of Event records to validate
     * @param oldMap Map of old Event records (null for insert)
     */
    private void validateEventScheduling(List<Event> events, Map<Id, Event> oldMap) {
        List<Event> eventsToValidate = new List<Event>();
        
        // Filter events that need validation
        for (Event evt : events) {
            // Skip validation if event doesn't have required fields
            if (evt.StartDateTime == null || evt.EndDateTime == null) {
                continue;
            }
            
            // Skip validation if this is an update and times haven't changed
            if (oldMap != null) {
                Event oldEvent = oldMap.get(evt.Id);
                if (oldEvent.StartDateTime == evt.StartDateTime && 
                    oldEvent.EndDateTime == evt.EndDateTime &&
                    oldEvent.OwnerId == evt.OwnerId) {
                    continue;
                }
            }
            
            eventsToValidate.add(evt);
        }
        
        if (eventsToValidate.isEmpty()) {
            return;
        }
        
        // Perform validations
        validateWeekendMeetings(eventsToValidate);
        validateDoubleBooking(eventsToValidate, oldMap);
        validateBusinessHours(eventsToValidate);
        validateEventDuration(eventsToValidate);
    }
    
    /**
     * @description Validates that meetings are not scheduled on weekends
     * @param events List of Event records to validate
     */
    private void validateWeekendMeetings(List<Event> events) {
        for (Event evt : events) {
            if (evt.StartDateTime == null) continue;
            
            // Get day of week (1 = Sunday, 7 = Saturday)
            Date eventDate = evt.StartDateTime.date();
            Datetime eventDateTime = Datetime.newInstance(eventDate.year(), eventDate.month(), eventDate.day());
            String dayOfWeek = eventDateTime.format('EEEE');
            
            if (dayOfWeek == 'Saturday' || dayOfWeek == 'Sunday') {
                evt.addError('🚫 Weekend meetings are not allowed. Please schedule during business days (Monday-Friday).');
            }
        }
    }
    
    /**
     * @description Validates that events don't overlap with existing events
     * @param events List of Event records to validate
     * @param oldMap Map of old Event records (null for insert)
     */
    private void validateDoubleBooking(List<Event> events, Map<Id, Event> oldMap) {
        // Collect owner IDs and time ranges for validation
        Set<Id> ownerIds = new Set<Id>();
        Map<Id, List<Event>> ownerToEvents = new Map<Id, List<Event>>();
        
        for (Event evt : events) {
            ownerIds.add(evt.OwnerId);
            
            if (!ownerToEvents.containsKey(evt.OwnerId)) {
                ownerToEvents.put(evt.OwnerId, new List<Event>());
            }
            ownerToEvents.get(evt.OwnerId).add(evt);
        }
        
        // Query existing events for the same owners
        List<Event> existingEvents = [
            SELECT Id, OwnerId, StartDateTime, EndDateTime, Subject
            FROM Event
            WHERE OwnerId IN :ownerIds
            AND StartDateTime != null
            AND EndDateTime != null
            AND (Id NOT IN :events OR Id = null)
        ];
        
        // Group existing events by owner
        Map<Id, List<Event>> ownerToExistingEvents = new Map<Id, List<Event>>();
        for (Event existingEvent : existingEvents) {
            if (!ownerToExistingEvents.containsKey(existingEvent.OwnerId)) {
                ownerToExistingEvents.put(existingEvent.OwnerId, new List<Event>());
            }
            ownerToExistingEvents.get(existingEvent.OwnerId).add(existingEvent);
        }
        
        // Check for overlaps
        for (Event newEvent : events) {
            List<Event> ownerExistingEvents = ownerToExistingEvents.get(newEvent.OwnerId);
            if (ownerExistingEvents == null) continue;
            
            for (Event existingEvent : ownerExistingEvents) {
                // Skip if this is the same event (for updates)
                if (oldMap != null && existingEvent.Id == newEvent.Id) {
                    continue;
                }
                
                // Check for time overlap
                if (eventsOverlap(newEvent, existingEvent)) {
                    String conflictMessage = String.format(
                        '⚠️ Time conflict detected! This event overlaps with "{0}" scheduled from {1} to {2}. Please choose a different time.',
                        new List<String>{
                            existingEvent.Subject,
                            existingEvent.StartDateTime.format('MMM d, yyyy h:mm a'),
                            existingEvent.EndDateTime.format('h:mm a')
                        }
                    );
                    newEvent.addError(conflictMessage);
                }
            }
        }
    }
    
    /**
     * @description Validates that events are scheduled during business hours
     * @param events List of Event records to validate
     */
    private void validateBusinessHours(List<Event> events) {
        for (Event evt : events) {
            if (evt.StartDateTime == null || evt.EndDateTime == null) continue;
            
            // Get hour of day (0-23)
            Integer startHour = evt.StartDateTime.hour();
            Integer endHour = evt.EndDateTime.hour();
            
            // Business hours: 8 AM to 6 PM
            if (startHour < 8 || startHour >= 18 || endHour > 18) {
                evt.addError('🕐 Events should be scheduled during business hours (8:00 AM - 6:00 PM). For after-hours meetings, please get manager approval.');
            }
        }
    }
    
    /**
     * @description Validates event duration constraints
     * @param events List of Event records to validate
     */
    private void validateEventDuration(List<Event> events) {
        for (Event evt : events) {
            if (evt.StartDateTime == null || evt.EndDateTime == null) continue;
            
            // Calculate duration in minutes
            Long durationMinutes = (evt.EndDateTime.getTime() - evt.StartDateTime.getTime()) / (1000 * 60);
            
            // Validate minimum duration (15 minutes)
            if (durationMinutes < 15) {
                evt.addError('⏱️ Events must be at least 15 minutes long.');
            }
            
            // Validate maximum duration (8 hours)
            if (durationMinutes > 480) {
                evt.addError('⏱️ Events cannot be longer than 8 hours. For longer events, please create multiple sessions.');
            }
            
            // Validate end time is after start time
            if (evt.EndDateTime <= evt.StartDateTime) {
                evt.addError('⏰ Event end time must be after start time.');
            }
        }
    }
    
    /**
     * @description Checks if two events overlap in time
     * @param event1 First event
     * @param event2 Second event
     * @return True if events overlap, false otherwise
     */
    private Boolean eventsOverlap(Event event1, Event event2) {
        // Events overlap if:
        // event1 starts before event2 ends AND event1 ends after event2 starts
        return (event1.StartDateTime < event2.EndDateTime && 
                event1.EndDateTime > event2.StartDateTime);
    }
}
