/**
 * Service class providing interview event data for the calendar integration LWC.
 * Queries standard Event records related to Job Applications.
 */
public inherited sharing class InterviewCalendarService {

    /**
     * Returns upcoming interview events for the current user.
     * @return List of upcoming events with related job application info
     */
    @AuraEnabled(cacheable=true)
    public static List<InterviewEvent> getUpcomingInterviews() {
        List<InterviewEvent> interviews = new List<InterviewEvent>();

        List<Event> events = [
            SELECT Id, Subject, StartDateTime, EndDateTime, Location,
                   Description, What.Name, WhatId
            FROM Event
            WHERE StartDateTime >= :Datetime.now()
              AND OwnerId = :UserInfo.getUserId()
            ORDER BY StartDateTime ASC
            LIMIT 50
        ];

        for (Event evt : events) {
            interviews.add(new InterviewEvent(evt));
        }
        return interviews;
    }

    /**
     * Returns past interview events (last 30 days) for the current user.
     * @return List of past events
     */
    @AuraEnabled(cacheable=true)
    public static List<InterviewEvent> getPastInterviews() {
        List<InterviewEvent> interviews = new List<InterviewEvent>();

        List<Event> events = [
            SELECT Id, Subject, StartDateTime, EndDateTime, Location,
                   Description, What.Name, WhatId
            FROM Event
            WHERE StartDateTime < :Datetime.now()
              AND StartDateTime >= :Datetime.now().addDays(-30)
              AND OwnerId = :UserInfo.getUserId()
            ORDER BY StartDateTime DESC
            LIMIT 20
        ];

        for (Event evt : events) {
            interviews.add(new InterviewEvent(evt));
        }
        return interviews;
    }

    /**
     * Wrapper class for serializing Event data to the LWC.
     */
    public class InterviewEvent {
        @AuraEnabled public String id;
        @AuraEnabled public String subject;
        @AuraEnabled public Datetime startTime;
        @AuraEnabled public Datetime endTime;
        @AuraEnabled public String location;
        @AuraEnabled public String description;
        @AuraEnabled public String relatedRecordName;
        @AuraEnabled public String relatedRecordId;

        public InterviewEvent(Event evt) {
            this.id = evt.Id;
            this.subject = evt.Subject;
            this.startTime = evt.StartDateTime;
            this.endTime = evt.EndDateTime;
            this.location = evt.Location;
            this.description = evt.Description;
            this.relatedRecordName = evt.What != null ? evt.What.Name : null;
            this.relatedRecordId = evt.WhatId;
        }
    }
}
