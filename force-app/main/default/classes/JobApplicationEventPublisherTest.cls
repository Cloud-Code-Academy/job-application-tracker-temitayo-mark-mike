/**
 * @description Test class for JobApplicationEventPublisher
 * @author Learning Journey - Task 7.2
 * @date 2025-01-08
 */
@IsTest
public class JobApplicationEventPublisherTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test Job Application records
        List<Job_Application__c> jobApps = TestDataFactory.createJobApplications(3, 'Applied', true);
    }
    
    @IsTest
    static void testPublishEvent() {
        Job_Application__c jobApp = [SELECT Id FROM Job_Application__c LIMIT 1];
        
        Map<String, Object> eventData = new Map<String, Object>();
        eventData.put('source', 'TestClass');
        eventData.put('timestamp', DateTime.now().getTime());
        
        Test.startTest();
        Boolean result = JobApplicationEventPublisher.publishEvent(
            jobApp.Id,
            JobApplicationEventPublisher.EventType.CREATED,
            eventData
        );
        Test.stopTest();
        
        System.assert(result, 'Event should be published successfully');
    }
    
    @IsTest
    static void testPublishStatusChangedEvent() {
        Job_Application__c jobApp = [SELECT Id FROM Job_Application__c LIMIT 1];
        
        Test.startTest();
        Boolean result = JobApplicationEventPublisher.publishStatusChangedEvent(
            jobApp.Id,
            'Applied',
            'Interviewing'
        );
        Test.stopTest();
        
        System.assert(result, 'Status changed event should be published successfully');
    }
    
    @IsTest
    static void testPublishSalaryUpdatedEvent() {
        Job_Application__c jobApp = [SELECT Id FROM Job_Application__c LIMIT 1];
        
        Test.startTest();
        Boolean result = JobApplicationEventPublisher.publishSalaryUpdatedEvent(
            jobApp.Id,
            100000,
            110000
        );
        Test.stopTest();
        
        System.assert(result, 'Salary updated event should be published successfully');
    }
    
    @IsTest
    static void testPublishInterviewScheduledEvent() {
        Job_Application__c jobApp = [SELECT Id FROM Job_Application__c LIMIT 1];
        
        Test.startTest();
        Boolean result = JobApplicationEventPublisher.publishInterviewScheduledEvent(
            jobApp.Id,
            DateTime.now().addDays(7),
            'Technical Interview',
            'Video Conference'
        );
        Test.stopTest();
        
        System.assert(result, 'Interview scheduled event should be published successfully');
    }
    
    @IsTest
    static void testPublishOfferReceivedEvent() {
        Job_Application__c jobApp = [SELECT Id FROM Job_Application__c LIMIT 1];
        
        Test.startTest();
        Boolean result = JobApplicationEventPublisher.publishOfferReceivedEvent(
            jobApp.Id,
            120000,
            Date.today().addDays(14)
        );
        Test.stopTest();
        
        System.assert(result, 'Offer received event should be published successfully');
    }
    
    @IsTest
    static void testPublishEventsInBulk() {
        List<Job_Application__c> jobApps = [SELECT Id FROM Job_Application__c];
        
        List<JobApplicationEventPublisher.EventRequest> eventRequests = 
            new List<JobApplicationEventPublisher.EventRequest>();
        
        for (Job_Application__c jobApp : jobApps) {
            Map<String, Object> eventData = new Map<String, Object>();
            eventData.put('source', 'BulkTest');
            eventData.put('batchId', 'BATCH_001');
            
            eventRequests.add(new JobApplicationEventPublisher.EventRequest(
                jobApp.Id,
                JobApplicationEventPublisher.EventType.UPDATED,
                eventData
            ));
        }
        
        Test.startTest();
        Map<Integer, Boolean> results = JobApplicationEventPublisher.publishEvents(eventRequests);
        Test.stopTest();
        
        System.assertEquals(jobApps.size(), results.size(), 'Should return result for each event');
        
        for (Boolean result : results.values()) {
            System.assert(result, 'All bulk events should be published successfully');
        }
    }
    
    @IsTest
    static void testPublishEventWithNullJobAppId() {
        Map<String, Object> eventData = new Map<String, Object>();
        eventData.put('source', 'NullIdTest');
        
        Test.startTest();
        Boolean result = JobApplicationEventPublisher.publishEvent(
            null,
            JobApplicationEventPublisher.EventType.CREATED,
            eventData
        );
        Test.stopTest();
        
        System.assert(!result, 'Should return false for null Job Application ID');
    }
    
    @IsTest
    static void testPublishEventWithNullEventType() {
        Job_Application__c jobApp = [SELECT Id FROM Job_Application__c LIMIT 1];
        
        Map<String, Object> eventData = new Map<String, Object>();
        eventData.put('source', 'NullTypeTest');
        
        Test.startTest();
        Boolean result = JobApplicationEventPublisher.publishEvent(
            jobApp.Id,
            null,
            eventData
        );
        Test.stopTest();
        
        System.assert(!result, 'Should return false for null event type');
    }
}