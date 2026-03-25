/**
 * @description Enhanced trigger handler that publishes Platform Events for Job Application changes
 * @author Learning Journey
 * @date 2025-01-08
 */
public class JobApplicationEventTriggerHandler {
    
    /**
     * @description Publish interview scheduled event (called from external processes)
     * @param jobAppId Job Application ID
     * @param interviewDate Interview date and time
     * @param interviewType Type of interview
     * @param location Interview location
     * @return True if event published successfully
     */
    public static Boolean publishInterviewScheduledEvent(Id jobAppId, DateTime interviewDate, 
                                                        String interviewType, String location) {
        return JobApplicationEventPublisher.publishInterviewScheduledEvent(
            jobAppId, interviewDate, interviewType, location
        );
    }
    
    /**
     * @description Publish offer received event (called from external processes)
     * @param jobAppId Job Application ID
     * @param offerAmount Offer salary amount
     * @param offerDeadline Deadline to respond
     * @return True if event published successfully
     */
    public static Boolean publishOfferReceivedEvent(Id jobAppId, Decimal offerAmount, Date offerDeadline) {
        return JobApplicationEventPublisher.publishOfferReceivedEvent(
            jobAppId, offerAmount, offerDeadline
        );
    }
    
    /**
     * @description Publish custom event with flexible data
     * @param jobAppId Job Application ID
     * @param eventType Type of event to publish
     * @param eventData Custom event data
     * @return True if event published successfully
     */
    public static Boolean publishCustomEvent(Id jobAppId, String eventType, Map<String, Object> eventData) {
        try {
            JobApplicationEventPublisher.EventType publisherEventType;
            
            // Map string to enum
            switch on eventType.toLowerCase() {
                when 'created' { publisherEventType = JobApplicationEventPublisher.EventType.CREATED; }
                when 'updated' { publisherEventType = JobApplicationEventPublisher.EventType.UPDATED; }
                when 'status_changed' { publisherEventType = JobApplicationEventPublisher.EventType.STATUS_CHANGED; }
                when 'salary_updated' { publisherEventType = JobApplicationEventPublisher.EventType.SALARY_UPDATED; }
                when 'interview_scheduled' { publisherEventType = JobApplicationEventPublisher.EventType.INTERVIEW_SCHEDULED; }
                when 'offer_received' { publisherEventType = JobApplicationEventPublisher.EventType.OFFER_RECEIVED; }
                when 'application_withdrawn' { publisherEventType = JobApplicationEventPublisher.EventType.APPLICATION_WITHDRAWN; }
                when else { publisherEventType = JobApplicationEventPublisher.EventType.UPDATED; }
            }
            
            return JobApplicationEventPublisher.publishEvent(jobAppId, publisherEventType, eventData);
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error publishing custom event: ' + e.getMessage());
            return false;
        }
    }
}