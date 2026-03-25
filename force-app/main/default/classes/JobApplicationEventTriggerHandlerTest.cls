/**
 * @description Test class for JobApplicationEventTriggerHandler
 * @author Learning Journey
 * @date 2025-01-08
 */
@IsTest
public inherited sharing class JobApplicationEventTriggerHandlerTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test Job Application records
        List<Job_Application__c> jobApps = new List<Job_Application__c>();
        
        jobApps.add(new Job_Application__c(
            Company_Name__c = 'Handler Test Corp',
            Position_Title__c = 'Platform Developer',
            Status__c = 'Applied',
            Salary__c = 115000,
            Location__c = 'Portland, OR',
            Application_Date__c = Date.today(),
            Job_URL__c = 'https://example.com/job1'
        ));
        
        jobApps.add(new Job_Application__c(
            Company_Name__c = 'Handler Test Inc',
            Position_Title__c = 'Software Engineer',
            Status__c = 'Applied',
            Salary__c = 95000,
            Location__c = 'Boston, MA',
            Application_Date__c = Date.today().addDays(-1),
            Job_URL__c = 'https://example.com/job2'
        ));
        
        insert jobApps;
    }
    
    @IsTest
    static void testHandleAfterInsert() {
        // Get existing count to account for setup data
        Integer initialCount = [SELECT COUNT() FROM Job_Application__c];
        
        List<Job_Application__c> newJobApps = new List<Job_Application__c>();
        newJobApps.add(new Job_Application__c(
            Company_Name__c = 'Insert Test Corp',
            Position_Title__c = 'Event Test Engineer',
            Status__c = 'Applied',
            Salary__c = 125000,
            Location__c = 'Chicago, IL',
            Application_Date__c = Date.today()
        ));
        
        Test.startTest();
        insert newJobApps;
        Test.stopTest();
        
        // Verify record was inserted
        Integer finalCount = [SELECT COUNT() FROM Job_Application__c];
        System.assertEquals(initialCount + 1, finalCount, 'Should have inserted one new record');
        
        // In a real scenario, you would verify that Platform Events were published
        // This would require checking event bus or using Test.getEventBus().deliver()
    }
    
    @IsTest
    static void testHandleAfterUpdateStatusChange() {
        Job_Application__c jobApp = [SELECT Id, Status__c FROM Job_Application__c LIMIT 1];
        String originalStatus = jobApp.Status__c;
        
        Test.startTest();
        jobApp.Status__c = 'Interviewing';
        update jobApp;
        Test.stopTest();
        
        // Verify status was updated
        Job_Application__c updatedJobApp = [SELECT Id, Status__c FROM Job_Application__c WHERE Id = :jobApp.Id];
        System.assertEquals('Interviewing', updatedJobApp.Status__c, 'Status should be updated');
        System.assertNotEquals(originalStatus, updatedJobApp.Status__c, 'Status should have changed');
    }
    
    @IsTest
    static void testHandleAfterUpdateSalaryChange() {
        Job_Application__c jobApp = [SELECT Id, Salary__c FROM Job_Application__c LIMIT 1];
        Decimal originalSalary = jobApp.Salary__c;
        
        Test.startTest();
        jobApp.Salary__c = originalSalary + 10000;
        update jobApp;
        Test.stopTest();
        
        // Verify salary was updated
        Job_Application__c updatedJobApp = [SELECT Id, Salary__c FROM Job_Application__c WHERE Id = :jobApp.Id];
        System.assertEquals(originalSalary + 10000, updatedJobApp.Salary__c, 'Salary should be updated');
        System.assertNotEquals(originalSalary, updatedJobApp.Salary__c, 'Salary should have changed');
    }
    
    @IsTest
    static void testHandleAfterUpdateMultipleChanges() {
        Job_Application__c jobApp = [SELECT Id, Status__c, Salary__c, Company_Name__c, Position_Title__c FROM Job_Application__c LIMIT 1];
        
        Test.startTest();
        jobApp.Status__c = 'Offer Received';
        jobApp.Salary__c = jobApp.Salary__c + 15000;
        jobApp.Company_Name__c = 'Updated Company Name';
        jobApp.Position_Title__c = 'Updated Position Title';
        update jobApp;
        Test.stopTest();
        
        // Verify multiple fields were updated
        Job_Application__c updatedJobApp = [SELECT Id, Status__c, Salary__c, Company_Name__c, Position_Title__c FROM Job_Application__c WHERE Id = :jobApp.Id];
        System.assertEquals('Offer Received', updatedJobApp.Status__c, 'Status should be updated');
        System.assertEquals('Updated Company Name', updatedJobApp.Company_Name__c, 'Company name should be updated');
        System.assertEquals('Updated Position Title', updatedJobApp.Position_Title__c, 'Position title should be updated');
    }
    
    @IsTest
    static void testHandleAfterUpdateNoSignificantChanges() {
        Job_Application__c jobApp = [SELECT Id, Notes__c FROM Job_Application__c LIMIT 1];
        
        Test.startTest();
        // Update a field that's not considered "significant"
        jobApp.Notes__c = 'Updated notes - not significant change';
        update jobApp;
        Test.stopTest();
        
        // Verify update was successful
        Job_Application__c updatedJobApp = [SELECT Id, Notes__c FROM Job_Application__c WHERE Id = :jobApp.Id];
        System.assertEquals('Updated notes - not significant change', updatedJobApp.Notes__c, 'Notes should be updated');
    }
    
    @IsTest
    static void testHandleAfterDelete() {
        Job_Application__c jobApp = [SELECT Id, Status__c FROM Job_Application__c LIMIT 1];
        Id jobAppId = jobApp.Id;
        String finalStatus = jobApp.Status__c;
        
        Test.startTest();
        delete jobApp;
        Test.stopTest();
        
        // Verify record was deleted
        List<Job_Application__c> deletedJobApps = [SELECT Id FROM Job_Application__c WHERE Id = :jobAppId];
        System.assert(deletedJobApps.isEmpty(), 'Job Application should be deleted');
    }
    
    @IsTest
    static void testPublishInterviewScheduledEvent() {
        Job_Application__c jobApp = [SELECT Id FROM Job_Application__c LIMIT 1];
        DateTime interviewDate = DateTime.now().addDays(7);
        
        Test.startTest();
        Boolean result = JobApplicationEventTriggerHandler.publishInterviewScheduledEvent(
            jobApp.Id, 
            interviewDate, 
            'Technical Interview', 
            'Conference Room A'
        );
        Test.stopTest();
        
        System.assert(result, 'Interview scheduled event should be published successfully');
    }
    
    @IsTest
    static void testPublishOfferReceivedEvent() {
        Job_Application__c jobApp = [SELECT Id FROM Job_Application__c LIMIT 1];
        Date offerDeadline = Date.today().addDays(14);
        
        Test.startTest();
        Boolean result = JobApplicationEventTriggerHandler.publishOfferReceivedEvent(
            jobApp.Id, 
            135000, 
            offerDeadline
        );
        Test.stopTest();
        
        System.assert(result, 'Offer received event should be published successfully');
    }
    
    @IsTest
    static void testPublishCustomEventCreated() {
        Job_Application__c jobApp = [SELECT Id FROM Job_Application__c LIMIT 1];
        
        Map<String, Object> eventData = new Map<String, Object>();
        eventData.put('customField', 'customValue');
        eventData.put('source', 'CustomEventTest');
        
        Test.startTest();
        Boolean result = JobApplicationEventTriggerHandler.publishCustomEvent(
            jobApp.Id, 
            'created', 
            eventData
        );
        Test.stopTest();
        
        System.assert(result, 'Custom created event should be published successfully');
    }
    
    @IsTest
    static void testPublishCustomEventStatusChanged() {
        Job_Application__c jobApp = [SELECT Id FROM Job_Application__c LIMIT 1];
        
        Map<String, Object> eventData = new Map<String, Object>();
        eventData.put('previousStatus', 'Applied');
        eventData.put('currentStatus', 'Interviewing');
        
        Test.startTest();
        Boolean result = JobApplicationEventTriggerHandler.publishCustomEvent(
            jobApp.Id, 
            'status_changed', 
            eventData
        );
        Test.stopTest();
        
        System.assert(result, 'Custom status changed event should be published successfully');
    }
    
    @IsTest
    static void testPublishCustomEventSalaryUpdated() {
        Job_Application__c jobApp = [SELECT Id FROM Job_Application__c LIMIT 1];
        
        Map<String, Object> eventData = new Map<String, Object>();
        eventData.put('previousSalary', 100000);
        eventData.put('currentSalary', 120000);
        
        Test.startTest();
        Boolean result = JobApplicationEventTriggerHandler.publishCustomEvent(
            jobApp.Id, 
            'salary_updated', 
            eventData
        );
        Test.stopTest();
        
        System.assert(result, 'Custom salary updated event should be published successfully');
    }
    
    @IsTest
    static void testPublishCustomEventInterviewScheduled() {
        Job_Application__c jobApp = [SELECT Id FROM Job_Application__c LIMIT 1];
        
        Map<String, Object> eventData = new Map<String, Object>();
        eventData.put('interviewDate', DateTime.now().addDays(5).format());
        eventData.put('interviewType', 'Panel Interview');
        
        Test.startTest();
        Boolean result = JobApplicationEventTriggerHandler.publishCustomEvent(
            jobApp.Id, 
            'interview_scheduled', 
            eventData
        );
        Test.stopTest();
        
        System.assert(result, 'Custom interview scheduled event should be published successfully');
    }
    
    @IsTest
    static void testPublishCustomEventOfferReceived() {
        Job_Application__c jobApp = [SELECT Id FROM Job_Application__c LIMIT 1];
        
        Map<String, Object> eventData = new Map<String, Object>();
        eventData.put('offerAmount', 140000);
        eventData.put('offerDeadline', Date.today().addDays(10).format());
        
        Test.startTest();
        Boolean result = JobApplicationEventTriggerHandler.publishCustomEvent(
            jobApp.Id, 
            'offer_received', 
            eventData
        );
        Test.stopTest();
        
        System.assert(result, 'Custom offer received event should be published successfully');
    }
    
    @IsTest
    static void testPublishCustomEventApplicationWithdrawn() {
        Job_Application__c jobApp = [SELECT Id FROM Job_Application__c LIMIT 1];
        
        Map<String, Object> eventData = new Map<String, Object>();
        eventData.put('reason', 'Accepted another position');
        eventData.put('withdrawnBy', UserInfo.getUserId());
        
        Test.startTest();
        Boolean result = JobApplicationEventTriggerHandler.publishCustomEvent(
            jobApp.Id, 
            'application_withdrawn', 
            eventData
        );
        Test.stopTest();
        
        System.assert(result, 'Custom application withdrawn event should be published successfully');
    }
    
    @IsTest
    static void testPublishCustomEventInvalidType() {
        Job_Application__c jobApp = [SELECT Id FROM Job_Application__c LIMIT 1];
        
        Map<String, Object> eventData = new Map<String, Object>();
        eventData.put('test', 'data');
        
        Test.startTest();
        Boolean result = JobApplicationEventTriggerHandler.publishCustomEvent(
            jobApp.Id, 
            'invalid_event_type', 
            eventData
        );
        Test.stopTest();
        
        System.assert(result, 'Invalid event type should default to updated event and still succeed');
    }
    
    @IsTest
    static void testPublishCustomEventWithNullJobAppId() {
        Map<String, Object> eventData = new Map<String, Object>();
        eventData.put('test', 'data');
        
        Test.startTest();
        Boolean result = JobApplicationEventTriggerHandler.publishCustomEvent(
            null, 
            'created', 
            eventData
        );
        Test.stopTest();
        
        System.assert(!result, 'Event should fail with null Job Application ID');
    }
    
    @IsTest
    static void testPublishCustomEventWithNullEventType() {
        Job_Application__c jobApp = [SELECT Id FROM Job_Application__c LIMIT 1];
        
        Map<String, Object> eventData = new Map<String, Object>();
        eventData.put('test', 'data');
        
        Test.startTest();
        Boolean result = JobApplicationEventTriggerHandler.publishCustomEvent(
            jobApp.Id, 
            null, 
            eventData
        );
        Test.stopTest();
        
        System.assert(result, 'Null event type should default to updated event and still succeed');
    }
    
    @IsTest
    static void testPublishCustomEventWithNullEventData() {
        Job_Application__c jobApp = [SELECT Id FROM Job_Application__c LIMIT 1];
        
        Test.startTest();
        Boolean result = JobApplicationEventTriggerHandler.publishCustomEvent(
            jobApp.Id, 
            'created', 
            null
        );
        Test.stopTest();
        
        System.assert(result, 'Event should succeed even with null event data');
    }
    
    @IsTest
    static void testBulkInsertOperations() {
        List<Job_Application__c> bulkJobApps = new List<Job_Application__c>();
        
        for (Integer i = 0; i < 200; i++) {
            bulkJobApps.add(new Job_Application__c(
                Company_Name__c = 'Bulk Test Corp ' + i,
                Position_Title__c = 'Bulk Engineer ' + i,
                Status__c = 'Applied',
                Salary__c = 100000 + (i * 1000),
                Location__c = 'Remote',
                Application_Date__c = Date.today()
            ));
        }
        
        Test.startTest();
        insert bulkJobApps;
        Test.stopTest();
        
        // Verify all records were inserted
        List<Job_Application__c> insertedRecords = [SELECT Id FROM Job_Application__c WHERE Company_Name__c LIKE 'Bulk Test Corp%'];
        System.assertEquals(200, insertedRecords.size(), 'Should have inserted 200 bulk records');
    }
    
    @IsTest
    static void testBulkUpdateOperations() {
        List<Job_Application__c> jobApps = [SELECT Id, Status__c FROM Job_Application__c];
        
        Test.startTest();
        for (Job_Application__c jobApp : jobApps) {
            jobApp.Status__c = 'Interviewing';
        }
        update jobApps;
        Test.stopTest();
        
        // Verify all records were updated
        List<Job_Application__c> updatedRecords = [SELECT Id, Status__c FROM Job_Application__c WHERE Status__c = 'Interviewing'];
        System.assertEquals(jobApps.size(), updatedRecords.size(), 'All records should be updated to Interviewing status');
    }
    
    @IsTest
    static void testBulkDeleteOperations() {
        List<Job_Application__c> jobApps = [SELECT Id FROM Job_Application__c];
        Integer initialCount = jobApps.size();
        
        Test.startTest();
        delete jobApps;
        Test.stopTest();
        
        // Verify all records were deleted
        List<Job_Application__c> remainingRecords = [SELECT Id FROM Job_Application__c];
        System.assert(remainingRecords.isEmpty(), 'All Job Applications should be deleted');
    }
}