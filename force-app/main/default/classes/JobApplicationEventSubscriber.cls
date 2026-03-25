/**
 * @description Service for subscribing to and handling Job Application Platform Events
 * @author Learning Journey
 * @date 2025-01-08
 */
public inherited sharing class JobApplicationEventSubscriber {
    
    // Configuration
    private static final Boolean ENABLE_DEBUG_LOGGING = true;
    private static final Integer MAX_RETRY_ATTEMPTS = 3;
    
    // Track failed events for monitoring
    @TestVisible
    private static List<FailedEventRecord> failedEvents = new List<FailedEventRecord>();
    
    /**
     * @description Handle Job Application events from Platform Event trigger
     * @param events List of Job Application events to process
     */
    public static void handleEvents(List<Job_Application_Event__e> events) {
        if (events == null || events.isEmpty()) {
            return;
        }
        
        System.debug('Processing ' + events.size() + ' Job Application events');
        
        // Group events by type for efficient processing
        Map<String, List<Job_Application_Event__e>> eventsByType = groupEventsByType(events);
        
        // Process each event type
        for (String eventType : eventsByType.keySet()) {
            List<Job_Application_Event__e> typeEvents = eventsByType.get(eventType);
            
            try {
                switch on eventType {
                    when 'Created' {
                        handleCreatedEvents(typeEvents);
                    }
                    when 'Status_Changed' {
                        handleStatusChangedEvents(typeEvents);
                    }
                    when 'Salary_Updated' {
                        handleSalaryUpdatedEvents(typeEvents);
                    }
                    when 'Interview_Scheduled' {
                        handleInterviewScheduledEvents(typeEvents);
                    }
                    when 'Offer_Received' {
                        handleOfferReceivedEvents(typeEvents);
                    }
                    when 'Application_Withdrawn' {
                        handleApplicationWithdrawnEvents(typeEvents);
                    }
                    when else {
                        handleGenericEvents(typeEvents);
                    }
                }
                
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Error processing ' + eventType + ' events: ' + e.getMessage());
                System.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());
                
                // Log failed events for retry
                logFailedEvents(typeEvents, e.getMessage());
            }
        }
    }
    
    /**
     * @description Handle Job Application created events
     * @param events List of created events
     */
    private static void handleCreatedEvents(List<Job_Application_Event__e> events) {
        System.debug('Handling ' + events.size() + ' created events');
        
        List<String> notifications = new List<String>();
        List<Map<String, Object>> analyticsEvents = new List<Map<String, Object>>();
        
        for (Job_Application_Event__e event : events) {
            try {
                // Send welcome notification
                String notification = buildWelcomeNotification(event);
                notifications.add(notification);
                
                // Track analytics
                Map<String, Object> analyticsData = buildAnalyticsData(event, 'application_created');
                analyticsEvents.add(analyticsData);
                
                // Log event processing
                if (ENABLE_DEBUG_LOGGING) {
                    System.debug('Processed created event for Job App: ' + event.Job_Application_Id__c);
                }
                
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Error processing created event: ' + e.getMessage());
            }
        }
        
        // Send notifications in bulk
        if (!notifications.isEmpty()) {
            sendNotifications(notifications, 'welcome');
        }
        
        // Send analytics in bulk
        if (!analyticsEvents.isEmpty()) {
            sendAnalyticsEvents(analyticsEvents);
        }
    }
    
    /**
     * @description Handle Job Application status changed events
     * @param events List of status changed events
     */
    private static void handleStatusChangedEvents(List<Job_Application_Event__e> events) {
        System.debug('Handling ' + events.size() + ' status changed events');
        
        List<String> notifications = new List<String>();
        List<Task> tasksToCreate = new List<Task>();
        
        for (Job_Application_Event__e event : events) {
            try {
                // Parse event data
                Map<String, Object> eventData = parseEventData(event.Event_Data__c);
                
                // Send status change notification
                String notification = buildStatusChangeNotification(event, eventData);
                notifications.add(notification);
                
                // Create follow-up tasks based on new status
                List<Task> newTasks = createFollowUpTasks(event, eventData);
                tasksToCreate.addAll(newTasks);
                
                // Update application metrics
                updateApplicationMetrics(event.Job_Application_Id__c, event.Current_Status__c);
                
                if (ENABLE_DEBUG_LOGGING) {
                    System.debug('Processed status change event: ' + event.Previous_Status__c + 
                               ' → ' + event.Current_Status__c);
                }
                
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Error processing status change event: ' + e.getMessage());
            }
        }
        
        // Send notifications
        if (!notifications.isEmpty()) {
            sendNotifications(notifications, 'status_change');
        }
        
        // Create tasks
        if (!tasksToCreate.isEmpty()) {
            try {
                insert tasksToCreate;
                System.debug('Created ' + tasksToCreate.size() + ' follow-up tasks');
            } catch (DmlException e) {
                System.debug(LoggingLevel.ERROR, 'Error creating follow-up tasks: ' + e.getMessage());
            }
        }
    }
    
    /**
     * @description Handle salary updated events
     * @param events List of salary updated events
     */
    private static void handleSalaryUpdatedEvents(List<Job_Application_Event__e> events) {
        System.debug('Handling ' + events.size() + ' salary updated events');
        
        List<Id> jobAppIds = new List<Id>();
        
        for (Job_Application_Event__e event : events) {
            try {
                // Parse event data
                Map<String, Object> eventData = parseEventData(event.Event_Data__c);
                
                // Trigger salary analysis
                triggerSalaryAnalysis(event.Job_Application_Id__c, eventData);
                
                // Update tax calculations
                triggerTaxCalculation(event.Job_Application_Id__c, eventData);
                
                // Send salary update notification
                sendSalaryUpdateNotification(event, eventData);
                
                jobAppIds.add(event.Job_Application_Id__c);
                
                if (ENABLE_DEBUG_LOGGING) {
                    System.debug('Processed salary update event for Job App: ' + event.Job_Application_Id__c);
                }
                
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Error processing salary update event: ' + e.getMessage());
            }
        }
        
        // Trigger batch market analysis for updated salaries
        if (!jobAppIds.isEmpty()) {
            triggerMarketAnalysis(jobAppIds);
        }
    }
    
    /**
     * @description Handle interview scheduled events
     * @param events List of interview scheduled events
     */
    private static void handleInterviewScheduledEvents(List<Job_Application_Event__e> events) {
        System.debug('Handling ' + events.size() + ' interview scheduled events');
        
        List<Event> calendarEvents = new List<Event>();
        List<String> notifications = new List<String>();
        
        for (Job_Application_Event__e event : events) {
            try {
                // Parse event data
                Map<String, Object> eventData = parseEventData(event.Event_Data__c);
                
                // Create calendar event
                Event calendarEvent = createCalendarEvent(event, eventData);
                if (calendarEvent != null) {
                    calendarEvents.add(calendarEvent);
                }
                
                // Send interview confirmation
                String notification = buildInterviewNotification(event, eventData);
                notifications.add(notification);
                
                // Schedule interview reminders
                scheduleInterviewReminders(event, eventData);
                
                if (ENABLE_DEBUG_LOGGING) {
                    System.debug('Processed interview scheduled event for Job App: ' + event.Job_Application_Id__c);
                }
                
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Error processing interview scheduled event: ' + e.getMessage());
            }
        }
        
        // Create calendar events
        if (!calendarEvents.isEmpty()) {
            try {
                insert calendarEvents;
                System.debug('Created ' + calendarEvents.size() + ' calendar events');
            } catch (DmlException e) {
                System.debug(LoggingLevel.ERROR, 'Error creating calendar events: ' + e.getMessage());
            }
        }
        
        // Send notifications
        if (!notifications.isEmpty()) {
            sendNotifications(notifications, 'interview_scheduled');
        }
    }
    
    /**
     * @description Handle offer received events
     * @param events List of offer received events
     */
    private static void handleOfferReceivedEvents(List<Job_Application_Event__e> events) {
        System.debug('Handling ' + events.size() + ' offer received events');
        
        for (Job_Application_Event__e event : events) {
            try {
                // Parse event data
                Map<String, Object> eventData = parseEventData(event.Event_Data__c);
                
                // Send congratulations notification
                sendOfferReceivedNotification(event, eventData);
                
                // Create offer evaluation tasks
                createOfferEvaluationTasks(event, eventData);
                
                // Trigger salary comparison analysis
                triggerOfferAnalysis(event.Job_Application_Id__c, eventData);
                
                // Schedule offer deadline reminder
                scheduleOfferDeadlineReminder(event, eventData);
                
                if (ENABLE_DEBUG_LOGGING) {
                    System.debug('Processed offer received event for Job App: ' + event.Job_Application_Id__c);
                }
                
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Error processing offer received event: ' + e.getMessage());
            }
        }
    }
    
    /**
     * @description Handle application withdrawn events
     * @param events List of application withdrawn events
     */
    private static void handleApplicationWithdrawnEvents(List<Job_Application_Event__e> events) {
        System.debug('Handling ' + events.size() + ' application withdrawn events');
        
        for (Job_Application_Event__e event : events) {
            try {
                // Cancel related calendar events
                cancelRelatedCalendarEvents(event.Job_Application_Id__c);
                
                // Archive application data
                archiveApplicationData(event.Job_Application_Id__c);
                
                // Send withdrawal confirmation
                sendWithdrawalNotification(event);
                
                // Update analytics
                updateWithdrawalAnalytics(event);
                
                if (ENABLE_DEBUG_LOGGING) {
                    System.debug('Processed withdrawal event for Job App: ' + event.Job_Application_Id__c);
                }
                
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Error processing withdrawal event: ' + e.getMessage());
            }
        }
    }
    
    /**
     * @description Handle generic events (fallback)
     * @param events List of generic events
     */
    private static void handleGenericEvents(List<Job_Application_Event__e> events) {
        System.debug('Handling ' + events.size() + ' generic events');
        
        for (Job_Application_Event__e event : events) {
            try {
                // Log event for monitoring
                logGenericEvent(event);
                
                // Send generic notification
                sendGenericNotification(event);
                
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Error processing generic event: ' + e.getMessage());
            }
        }
    }
    
    /**
     * @description Group events by type for efficient processing
     * @param events List of events to group
     * @return Map of event type to events
     */
    private static Map<String, List<Job_Application_Event__e>> groupEventsByType(List<Job_Application_Event__e> events) {
        Map<String, List<Job_Application_Event__e>> eventsByType = new Map<String, List<Job_Application_Event__e>>();
        
        for (Job_Application_Event__e event : events) {
            String eventType = event.Event_Type__c;
            
            if (!eventsByType.containsKey(eventType)) {
                eventsByType.put(eventType, new List<Job_Application_Event__e>());
            }
            
            eventsByType.get(eventType).add(event);
        }
        
        return eventsByType;
    }
    
    /**
     * @description Parse event data JSON
     * @param eventDataJson JSON string from event
     * @return Parsed event data map
     */
    private static Map<String, Object> parseEventData(String eventDataJson) {
        if (String.isBlank(eventDataJson)) {
            return new Map<String, Object>();
        }
        
        try {
            return (Map<String, Object>) JSON.deserializeUntyped(eventDataJson);
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'Error parsing event data JSON: ' + e.getMessage());
            return new Map<String, Object>();
        }
    }
    
    /**
     * @description Build welcome notification for new applications
     * @param event Job Application event
     * @return Notification message
     */
    private static String buildWelcomeNotification(Job_Application_Event__e event) {
        return 'Welcome! Your application to ' + event.Company_Name__c + 
               ' for ' + event.Position_Title__c + ' has been created and is being tracked.';
    }
    
    /**
     * @description Build status change notification
     * @param event Job Application event
     * @param eventData Parsed event data
     * @return Notification message
     */
    private static String buildStatusChangeNotification(Job_Application_Event__e event, Map<String, Object> eventData) {
        String previousStatus = (String) eventData.get('previousStatus');
        return 'Status Update: Your application to ' + event.Company_Name__c + 
               ' has changed from "' + previousStatus + '" to "' + event.Current_Status__c + '"';
    }
    
    /**
     * @description Build interview notification
     * @param event Job Application event
     * @param eventData Parsed event data
     * @return Notification message
     */
    private static String buildInterviewNotification(Job_Application_Event__e event, Map<String, Object> eventData) {
        String interviewType = (String) eventData.get('interviewType');
        return 'Interview Scheduled: ' + (interviewType != null ? interviewType : 'Interview') + 
               ' scheduled for your application to ' + event.Company_Name__c;
    }
    
    /**
     * @description Send notifications (mock implementation)
     * @param notifications List of notification messages
     * @param notificationType Type of notification
     */
    private static void sendNotifications(List<String> notifications, String notificationType) {
        System.debug('=== SENDING NOTIFICATIONS ===');
        System.debug('Type: ' + notificationType);
        System.debug('Count: ' + notifications.size());
        
        for (String notification : notifications) {
            System.debug('Notification: ' + notification);
        }
        
        // In a real implementation, you would:
        // 1. Send email notifications
        // 2. Send push notifications to mobile app
        // 3. Post to Slack/Teams
        // 4. Create in-app notifications
    }
    
    /**
     * @description Send analytics events (mock implementation)
     * @param analyticsEvents List of analytics events
     */
    private static void sendAnalyticsEvents(List<Map<String, Object>> analyticsEvents) {
        System.debug('=== SENDING ANALYTICS EVENTS ===');
        System.debug('Count: ' + analyticsEvents.size());
        
        for (Map<String, Object> analyticsEvent : analyticsEvents) {
            System.debug('Analytics Event: ' + JSON.serialize(analyticsEvent));
        }
        
        // In a real implementation, you would:
        // 1. Send to Google Analytics
        // 2. Send to Salesforce Analytics
        // 3. Send to custom analytics platform
    }
    
    /**
     * @description Build analytics data for tracking
     * @param event Job Application event
     * @param eventName Analytics event name
     * @return Analytics data map
     */
    private static Map<String, Object> buildAnalyticsData(Job_Application_Event__e event, String eventName) {
        Map<String, Object> analyticsData = new Map<String, Object>();
        analyticsData.put('event', eventName);
        analyticsData.put('jobApplicationId', event.Job_Application_Id__c);
        analyticsData.put('company', event.Company_Name__c);
        analyticsData.put('position', event.Position_Title__c);
        analyticsData.put('timestamp', DateTime.now().getTime());
        
        return analyticsData;
    }
    
    /**
     * @description Create follow-up tasks based on status change
     * @param event Job Application event
     * @param eventData Parsed event data
     * @return List of tasks to create
     */
    private static List<Task> createFollowUpTasks(Job_Application_Event__e event, Map<String, Object> eventData) {
        List<Task> tasks = new List<Task>();
        String currentStatus = event.Current_Status__c;
        
        // Create status-specific tasks
        if (currentStatus == 'Applied') {
            tasks.add(new Task(
                Subject = 'Follow up on application to ' + event.Company_Name__c,
                Description = 'Follow up on your application after 1 week if no response',
                WhatId = event.Job_Application_Id__c,
                ActivityDate = Date.today().addDays(7),
                Priority = 'Normal',
                Status = 'Not Started'
            ));
        } else if (currentStatus == 'Interviewing') {
            tasks.add(new Task(
                Subject = 'Prepare for interview with ' + event.Company_Name__c,
                Description = 'Research company, prepare questions, and review job requirements',
                WhatId = event.Job_Application_Id__c,
                ActivityDate = Date.today().addDays(1),
                Priority = 'High',
                Status = 'Not Started'
            ));
        } else if (currentStatus == 'Offer') {
            tasks.add(new Task(
                Subject = 'Evaluate offer from ' + event.Company_Name__c,
                Description = 'Review offer details, compare with market rates, and make decision',
                WhatId = event.Job_Application_Id__c,
                ActivityDate = Date.today().addDays(3),
                Priority = 'High',
                Status = 'Not Started'
            ));
        }
        
        return tasks;
    }
    
    /**
     * @description Mock implementations for various event handling methods
     */
    private static void updateApplicationMetrics(Id jobAppId, String status) {
        System.debug('Updating metrics for Job App: ' + jobAppId + ', Status: ' + status);
    }
    
    private static void triggerSalaryAnalysis(Id jobAppId, Map<String, Object> eventData) {
        System.debug('Triggering salary analysis for Job App: ' + jobAppId);
    }
    
    private static void triggerTaxCalculation(Id jobAppId, Map<String, Object> eventData) {
        System.debug('Triggering tax calculation for Job App: ' + jobAppId);
    }
    
    private static void sendSalaryUpdateNotification(Job_Application_Event__e event, Map<String, Object> eventData) {
        System.debug('Sending salary update notification for Job App: ' + event.Job_Application_Id__c);
    }
    
    private static void triggerMarketAnalysis(List<Id> jobAppIds) {
        System.debug('Triggering market analysis for ' + jobAppIds.size() + ' Job Applications');
    }
    
    private static Event createCalendarEvent(Job_Application_Event__e event, Map<String, Object> eventData) {
        Long interviewTimestamp = (Long) eventData.get('interviewDate');
        if (interviewTimestamp == null) {
            return null;
        }
        
        DateTime interviewDate = DateTime.newInstance(interviewTimestamp);
        
        return new Event(
            Subject = 'Interview: ' + event.Position_Title__c + ' at ' + event.Company_Name__c,
            StartDateTime = interviewDate,
            EndDateTime = interviewDate.addHours(1),
            Description = 'Interview for ' + event.Position_Title__c + ' position',
            Location = (String) eventData.get('location'),
            WhatId = event.Job_Application_Id__c
        );
    }
    
    private static void scheduleInterviewReminders(Job_Application_Event__e event, Map<String, Object> eventData) {
        System.debug('Scheduling interview reminders for Job App: ' + event.Job_Application_Id__c);
    }
    
    private static void sendOfferReceivedNotification(Job_Application_Event__e event, Map<String, Object> eventData) {
        System.debug('Sending offer received notification for Job App: ' + event.Job_Application_Id__c);
    }
    
    private static void createOfferEvaluationTasks(Job_Application_Event__e event, Map<String, Object> eventData) {
        System.debug('Creating offer evaluation tasks for Job App: ' + event.Job_Application_Id__c);
    }
    
    private static void triggerOfferAnalysis(Id jobAppId, Map<String, Object> eventData) {
        System.debug('Triggering offer analysis for Job App: ' + jobAppId);
    }
    
    private static void scheduleOfferDeadlineReminder(Job_Application_Event__e event, Map<String, Object> eventData) {
        System.debug('Scheduling offer deadline reminder for Job App: ' + event.Job_Application_Id__c);
    }
    
    private static void cancelRelatedCalendarEvents(Id jobAppId) {
        System.debug('Canceling calendar events for Job App: ' + jobAppId);
    }
    
    private static void archiveApplicationData(Id jobAppId) {
        System.debug('Archiving data for Job App: ' + jobAppId);
    }
    
    private static void sendWithdrawalNotification(Job_Application_Event__e event) {
        System.debug('Sending withdrawal notification for Job App: ' + event.Job_Application_Id__c);
    }
    
    private static void updateWithdrawalAnalytics(Job_Application_Event__e event) {
        System.debug('Updating withdrawal analytics for Job App: ' + event.Job_Application_Id__c);
    }
    
    private static void logGenericEvent(Job_Application_Event__e event) {
        System.debug('Generic event logged for Job App: ' + event.Job_Application_Id__c + 
                    ', Type: ' + event.Event_Type__c);
    }
    
    private static void sendGenericNotification(Job_Application_Event__e event) {
        System.debug('Sending generic notification for Job App: ' + event.Job_Application_Id__c);
    }
    
    private static void logFailedEvents(List<Job_Application_Event__e> events, String errorMessage) {
        System.debug(LoggingLevel.ERROR, '=== FAILED EVENT PROCESSING ===');
        System.debug(LoggingLevel.ERROR, 'Error: ' + errorMessage);
        System.debug(LoggingLevel.ERROR, 'Failed Events Count: ' + events.size());
        
        for (Job_Application_Event__e event : events) {
            System.debug(LoggingLevel.ERROR, 'Failed Event - Job App: ' + event.Job_Application_Id__c + 
                        ', Type: ' + event.Event_Type__c);
            
            // Track failed events for retry/monitoring
            failedEvents.add(new FailedEventRecord(
                event.Job_Application_Id__c,
                event.Event_Type__c,
                errorMessage,
                event.ReplayId
            ));
        }
    }

    /**
     * @description Gets failed events for monitoring/retry purposes
     * @return List of failed event records from the current transaction
     */
    public static List<FailedEventRecord> getFailedEvents() {
        return failedEvents;
    }

    /**
     * @description Wrapper for tracking failed platform events with replay capability
     */
    public class FailedEventRecord {
        public String jobApplicationId { get; set; }
        public String eventType { get; set; }
        public String errorMessage { get; set; }
        public String replayId { get; set; }
        public Datetime failedAt { get; set; }

        public FailedEventRecord(String jobAppId, String evtType, String error, String replay) {
            this.jobApplicationId = jobAppId;
            this.eventType = evtType;
            this.errorMessage = error;
            this.replayId = replay;
            this.failedAt = Datetime.now();
        }
    }
}