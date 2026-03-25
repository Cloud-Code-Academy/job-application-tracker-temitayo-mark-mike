/**
 * @description Service for publishing Job Application Platform Events
 * @author Learning Journey
 * @date 2025-01-08
 */
public inherited sharing class JobApplicationEventPublisher {
    
    // Event types enum for type safety
    public enum EventType {
        CREATED,
        UPDATED,
        STATUS_CHANGED,
        SALARY_UPDATED,
        INTERVIEW_SCHEDULED,
        OFFER_RECEIVED,
        APPLICATION_WITHDRAWN
    }
    
    // Configuration for event publishing
    private static final Boolean ENABLE_DEBUG_LOGGING = true;
    private static final Integer MAX_EVENTS_PER_TRANSACTION = 100;
    
    /**
     * @description Publish a single Job Application event
     * @param jobAppId Job Application record ID
     * @param eventType Type of event that occurred
     * @param eventData Additional event data as JSON
     * @return True if event was published successfully
     */
    public static Boolean publishEvent(Id jobAppId, EventType eventType, Map<String, Object> eventData) {
        if (jobAppId == null || eventType == null) {
            System.debug(LoggingLevel.ERROR, 'JobAppId and EventType are required for event publishing');
            return false;
        }
        
        try {
            // Get Job Application details
            Job_Application__c jobApp = getJobApplicationDetails(jobAppId);
            if (jobApp == null) {
                System.debug(LoggingLevel.ERROR, 'Job Application not found: ' + jobAppId);
                return false;
            }
            
            // Create Platform Event
            Job_Application_Event__e event = buildPlatformEvent(jobApp, eventType, eventData);
            
            // Publish event
            Database.SaveResult result = EventBus.publish(event);
            
            if (result.isSuccess()) {
                logEventPublished(event, eventType);
                return true;
            } else {
                logEventError(result.getErrors(), eventType, jobAppId);
                return false;
            }
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error publishing event: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());
            return false;
        }
    }
    
    /**
     * @description Publish multiple Job Application events in bulk
     * @param eventRequests List of event requests to publish
     * @return Map of request index to success status
     */
    public static Map<Integer, Boolean> publishEvents(List<EventRequest> eventRequests) {
        Map<Integer, Boolean> results = new Map<Integer, Boolean>();
        
        if (eventRequests == null || eventRequests.isEmpty()) {
            return results;
        }
        
        // Limit to prevent governor limit issues
        if (eventRequests.size() > MAX_EVENTS_PER_TRANSACTION) {
            System.debug(LoggingLevel.WARN, 'Too many events requested: ' + eventRequests.size() + 
                        '. Limiting to ' + MAX_EVENTS_PER_TRANSACTION);
            List<EventRequest> limitedRequests = new List<EventRequest>();
            for (Integer i = 0; i < MAX_EVENTS_PER_TRANSACTION; i++) {
                limitedRequests.add(eventRequests[i]);
            }
            eventRequests = limitedRequests;
        }
        
        try {
            // Get all Job Application details in bulk
            Set<Id> jobAppIds = new Set<Id>();
            for (EventRequest request : eventRequests) {
                if (request.jobAppId != null) {
                    jobAppIds.add(request.jobAppId);
                }
            }
            
            Map<Id, Job_Application__c> jobAppMap = getJobApplicationDetailsMap(jobAppIds);
            
            // Build Platform Events
            List<Job_Application_Event__e> events = new List<Job_Application_Event__e>();
            Map<Integer, EventRequest> indexToRequestMap = new Map<Integer, EventRequest>();
            
            for (Integer i = 0; i < eventRequests.size(); i++) {
                EventRequest request = eventRequests[i];
                
                if (request.jobAppId == null || request.eventType == null) {
                    results.put(i, false);
                    continue;
                }
                
                Job_Application__c jobApp = jobAppMap.get(request.jobAppId);
                if (jobApp == null) {
                    results.put(i, false);
                    continue;
                }
                
                Job_Application_Event__e event = buildPlatformEvent(jobApp, request.eventType, request.eventData);
                events.add(event);
                indexToRequestMap.put(events.size() - 1, request);
            }
            
            // Publish events in bulk
            List<Database.SaveResult> publishResults = EventBus.publish(events);
            
            // Process results
            for (Integer i = 0; i < publishResults.size(); i++) {
                Database.SaveResult result = publishResults[i];
                EventRequest originalRequest = indexToRequestMap.get(i);
                Integer originalIndex = eventRequests.indexOf(originalRequest);
                
                if (result.isSuccess()) {
                    results.put(originalIndex, true);
                    if (ENABLE_DEBUG_LOGGING) {
                        logEventPublished(events[i], originalRequest.eventType);
                    }
                } else {
                    results.put(originalIndex, false);
                    logEventError(result.getErrors(), originalRequest.eventType, originalRequest.jobAppId);
                }
            }
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error publishing bulk events: ' + e.getMessage());
            // Mark all as failed
            for (Integer i = 0; i < eventRequests.size(); i++) {
                results.put(i, false);
            }
        }
        
        return results;
    }
    
    /**
     * @description Publish event for Job Application creation
     * @param jobAppId Job Application record ID
     * @param additionalData Additional data to include in event
     * @return True if event was published successfully
     */
    public static Boolean publishCreatedEvent(Id jobAppId, Map<String, Object> additionalData) {
        Map<String, Object> eventData = additionalData != null ? additionalData : new Map<String, Object>();
        eventData.put('timestamp', DateTime.now().getTime());
        eventData.put('source', 'JobApplicationEventPublisher');
        
        return publishEvent(jobAppId, EventType.CREATED, eventData);
    }
    
    /**
     * @description Publish event for Job Application status change
     * @param jobAppId Job Application record ID
     * @param previousStatus Previous status value
     * @param currentStatus Current status value
     * @return True if event was published successfully
     */
    public static Boolean publishStatusChangedEvent(Id jobAppId, String previousStatus, String currentStatus) {
        Map<String, Object> eventData = new Map<String, Object>();
        eventData.put('previousStatus', previousStatus);
        eventData.put('currentStatus', currentStatus);
        eventData.put('timestamp', DateTime.now().getTime());
        eventData.put('source', 'StatusChangeHandler');
        
        return publishEvent(jobAppId, JobApplicationEventPublisher.EventType.STATUS_CHANGED, eventData);
    }
    
    /**
     * @description Publish event for salary update
     * @param jobAppId Job Application record ID
     * @param previousSalary Previous salary value
     * @param currentSalary Current salary value
     * @return True if event was published successfully
     */
    public static Boolean publishSalaryUpdatedEvent(Id jobAppId, Decimal previousSalary, Decimal currentSalary) {
        Map<String, Object> eventData = new Map<String, Object>();
        eventData.put('previousSalary', previousSalary);
        eventData.put('currentSalary', currentSalary);
        eventData.put('salaryChange', currentSalary != null && previousSalary != null ? 
                     currentSalary - previousSalary : null);
        eventData.put('timestamp', DateTime.now().getTime());
        eventData.put('source', 'SalaryUpdateHandler');
        
        return publishEvent(jobAppId, EventType.SALARY_UPDATED, eventData);
    }
    
    /**
     * @description Publish event for interview scheduling
     * @param jobAppId Job Application record ID
     * @param interviewDate Date and time of interview
     * @param interviewType Type of interview (phone, video, in-person)
     * @param location Interview location or meeting details
     * @return True if event was published successfully
     */
    public static Boolean publishInterviewScheduledEvent(Id jobAppId, DateTime interviewDate, 
                                                        String interviewType, String location) {
        Map<String, Object> eventData = new Map<String, Object>();
        eventData.put('interviewDate', interviewDate != null ? interviewDate.getTime() : null);
        eventData.put('interviewType', interviewType);
        eventData.put('location', location);
        eventData.put('timestamp', DateTime.now().getTime());
        eventData.put('source', 'InterviewScheduler');
        
        return publishEvent(jobAppId, EventType.INTERVIEW_SCHEDULED, eventData);
    }
    
    /**
     * @description Publish event for offer received
     * @param jobAppId Job Application record ID
     * @param offerAmount Salary offer amount
     * @param offerDeadline Deadline to respond to offer
     * @return True if event was published successfully
     */
    public static Boolean publishOfferReceivedEvent(Id jobAppId, Decimal offerAmount, Date offerDeadline) {
        Map<String, Object> eventData = new Map<String, Object>();
        eventData.put('offerAmount', offerAmount);
        eventData.put('offerDeadline', offerDeadline != null ? offerDeadline.format() : null);
        eventData.put('timestamp', DateTime.now().getTime());
        eventData.put('source', 'OfferManager');
        
        return publishEvent(jobAppId, EventType.OFFER_RECEIVED, eventData);
    }
    
    /**
     * @description Get Job Application details for event publishing
     * @param jobAppId Job Application record ID
     * @return Job Application record with required fields
     */
    private static Job_Application__c getJobApplicationDetails(Id jobAppId) {
        try {
            return [SELECT Id, Company_Name__c, Position_Title__c, Status__c, Salary__c, 
                          Application_Date__c, Location__c
                   FROM Job_Application__c 
                   WHERE Id = :jobAppId LIMIT 1];
        } catch (QueryException e) {
            System.debug(LoggingLevel.ERROR, 'Error querying Job Application: ' + e.getMessage());
            return null;
        }
    }
    
    /**
     * @description Get Job Application details for multiple records
     * @param jobAppIds Set of Job Application record IDs
     * @return Map of Job Application records
     */
    private static Map<Id, Job_Application__c> getJobApplicationDetailsMap(Set<Id> jobAppIds) {
        try {
            return new Map<Id, Job_Application__c>([
                SELECT Id, Company_Name__c, Position_Title__c, Status__c, Salary__c, 
                       Application_Date__c, Location__c
                FROM Job_Application__c 
                WHERE Id IN :jobAppIds
            ]);
        } catch (QueryException e) {
            System.debug(LoggingLevel.ERROR, 'Error querying Job Applications: ' + e.getMessage());
            return new Map<Id, Job_Application__c>();
        }
    }
    
    /**
     * @description Build Platform Event from Job Application and event data
     * @param jobApp Job Application record
     * @param eventType Type of event
     * @param eventData Additional event data
     * @return Configured Platform Event
     */
    private static Job_Application_Event__e buildPlatformEvent(Job_Application__c jobApp, 
                                                              EventType eventType, 
                                                              Map<String, Object> eventData) {
        Job_Application_Event__e event = new Job_Application_Event__e();
        
        // Set required fields
        event.Job_Application_Id__c = jobApp.Id;
        event.Event_Type__c = getEventTypeString(eventType);
        
        // Set Job Application details
        event.Company_Name__c = jobApp.Company_Name__c;
        event.Position_Title__c = jobApp.Position_Title__c;
        event.Current_Status__c = jobApp.Status__c;
        
        // Set previous status for status change events
        if (eventType == JobApplicationEventPublisher.EventType.STATUS_CHANGED && eventData != null) {
            event.Previous_Status__c = (String) eventData.get('previousStatus');
        }
        
        // Set event data as JSON
        if (eventData != null && !eventData.isEmpty()) {
            try {
                event.Event_Data__c = JSON.serialize(eventData);
            } catch (Exception e) {
                System.debug(LoggingLevel.WARN, 'Error serializing event data: ' + e.getMessage());
                event.Event_Data__c = '{"error": "Failed to serialize event data"}';
            }
        }
        
        return event;
    }
    
    /**
     * @description Convert EventType enum to string
     * @param eventType EventType enum value
     * @return String representation for Platform Event
     */
    private static String getEventTypeString(EventType eventType) {
        switch on eventType {
            when CREATED { return 'Created'; }
            when UPDATED { return 'Updated'; }
            when STATUS_CHANGED { return 'Status_Changed'; }
            when SALARY_UPDATED { return 'Salary_Updated'; }
            when INTERVIEW_SCHEDULED { return 'Interview_Scheduled'; }
            when OFFER_RECEIVED { return 'Offer_Received'; }
            when APPLICATION_WITHDRAWN { return 'Application_Withdrawn'; }
            when else { return 'Updated'; }
        }
    }
    
    /**
     * @description Log successful event publication
     * @param event Published Platform Event
     * @param eventType Event type that was published
     */
    private static void logEventPublished(Job_Application_Event__e event, EventType eventType) {
        if (ENABLE_DEBUG_LOGGING) {
            System.debug('=== PLATFORM EVENT PUBLISHED ===');
            System.debug('Event Type: ' + eventType);
            System.debug('Job Application ID: ' + event.Job_Application_Id__c);
            System.debug('Company: ' + event.Company_Name__c);
            System.debug('Position: ' + event.Position_Title__c);
            System.debug('Status: ' + event.Current_Status__c);
            if (String.isNotBlank(event.Event_Data__c)) {
                System.debug('Event Data: ' + event.Event_Data__c);
            }
        }
    }
    
    /**
     * @description Log event publication errors
     * @param errors List of database errors
     * @param eventType Event type that failed
     * @param jobAppId Job Application ID
     */
    private static void logEventError(List<Database.Error> errors, EventType eventType, Id jobAppId) {
        System.debug(LoggingLevel.ERROR, '=== PLATFORM EVENT ERROR ===');
        System.debug(LoggingLevel.ERROR, 'Event Type: ' + eventType);
        System.debug(LoggingLevel.ERROR, 'Job Application ID: ' + jobAppId);
        
        for (Database.Error error : errors) {
            System.debug(LoggingLevel.ERROR, 'Error: ' + error.getMessage());
            System.debug(LoggingLevel.ERROR, 'Status Code: ' + error.getStatusCode());
            if (error.getFields() != null && !error.getFields().isEmpty()) {
                System.debug(LoggingLevel.ERROR, 'Fields: ' + error.getFields());
            }
        }
    }
    
    /**
     * @description Wrapper class for bulk event publishing requests
     */
    public class EventRequest {
        public Id jobAppId { get; set; }
        public EventType eventType { get; set; }
        public Map<String, Object> eventData { get; set; }
        
        public EventRequest(Id jobAppId, EventType eventType) {
            this.jobAppId = jobAppId;
            this.eventType = eventType;
            this.eventData = new Map<String, Object>();
        }
        
        public EventRequest(Id jobAppId, EventType eventType, Map<String, Object> eventData) {
            this.jobAppId = jobAppId;
            this.eventType = eventType;
            this.eventData = eventData != null ? eventData : new Map<String, Object>();
        }
    }
}