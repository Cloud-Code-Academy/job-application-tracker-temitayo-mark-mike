/**
 * @description Test class for Event validation handler
 * @author Temitayo Oluwalade
 * @date 2024
 */
@isTest
public class EventValidationHandlerTest {
    
    /**
     * @description Test data setup method
     */
    @TestSetup
    static void setupTestData() {
        // Create test user for event ownership
        User testUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        
        // Create test job application
        Job_Application__c testJob = new Job_Application__c(
            Company_Name__c = 'Test Company',
            Position_Title__c = 'Software Developer',
            Status__c = 'Interviewing'
        );
        insert testJob;
    }
    
    /**
     * @description Test weekend meeting validation
     */
    @isTest
    static void testWeekendMeetingValidation() {
        // Get next Saturday
        Date today = Date.today();
        Date nextSaturday = today.addDays((7 - Math.mod(today.toStartOfWeek().daysBetween(today), 7) + 6));
        
        Event weekendEvent = new Event(
            Subject = 'Weekend Interview',
            StartDateTime = Datetime.newInstance(nextSaturday, Time.newInstance(10, 0, 0, 0)),
            EndDateTime = Datetime.newInstance(nextSaturday, Time.newInstance(11, 0, 0, 0))
        );
        
        Test.startTest();
        try {
            insert weekendEvent;
            System.assert(false, 'Should have failed due to weekend validation');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Weekend meetings are not allowed'), 
                         'Should contain weekend validation message');
        }
        Test.stopTest();
    }
    
    /**
     * @description Test business hours validation
     */
    @isTest
    static void testBusinessHoursValidation() {
        Date tomorrow = Date.today().addDays(1);
        
        // Test early morning event (before 8 AM)
        Event earlyEvent = new Event(
            Subject = 'Early Morning Interview',
            StartDateTime = Datetime.newInstance(tomorrow, Time.newInstance(7, 0, 0, 0)),
            EndDateTime = Datetime.newInstance(tomorrow, Time.newInstance(8, 0, 0, 0))
        );
        
        Test.startTest();
        try {
            insert earlyEvent;
            System.assert(false, 'Should have failed due to business hours validation');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('business hours'), 
                         'Should contain business hours validation message');
        }
        Test.stopTest();
    }
    
    /**
     * @description Test event duration validation
     */
    @isTest
    static void testEventDurationValidation() {
        Date tomorrow = Date.today().addDays(1);
        
        // Test very short event (less than 15 minutes)
        Event shortEvent = new Event(
            Subject = 'Short Interview',
            StartDateTime = Datetime.newInstance(tomorrow, Time.newInstance(10, 0, 0, 0)),
            EndDateTime = Datetime.newInstance(tomorrow, Time.newInstance(10, 10, 0, 0))
        );
        
        Test.startTest();
        try {
            insert shortEvent;
            System.assert(false, 'Should have failed due to duration validation');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('15 minutes'), 
                         'Should contain minimum duration validation message');
        }
        Test.stopTest();
    }
    
    /**
     * @description Test double booking validation
     */
    @isTest
    static void testDoubleBookingValidation() {
        Date tomorrow = Date.today().addDays(1);
        Datetime startTime = Datetime.newInstance(tomorrow, Time.newInstance(10, 0, 0, 0));
        Datetime endTime = Datetime.newInstance(tomorrow, Time.newInstance(11, 0, 0, 0));
        
        // Create first event
        Event firstEvent = new Event(
            Subject = 'First Interview',
            StartDateTime = startTime,
            EndDateTime = endTime
        );
        insert firstEvent;
        
        // Try to create overlapping event
        Event overlappingEvent = new Event(
            Subject = 'Overlapping Interview',
            StartDateTime = startTime.addMinutes(30),
            EndDateTime = endTime.addMinutes(30)
        );
        
        Test.startTest();
        try {
            insert overlappingEvent;
            System.assert(false, 'Should have failed due to double booking validation');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Time conflict'), 
                         'Should contain time conflict validation message');
        }
        Test.stopTest();
    }
    
    /**
     * @description Test valid event creation
     */
    @isTest
    static void testValidEventCreation() {
        Date tomorrow = Date.today().addDays(1);
        
        // Skip weekend
        while (tomorrow.toStartOfWeek().daysBetween(tomorrow) >= 5) {
            tomorrow = tomorrow.addDays(1);
        }
        
        Event validEvent = new Event(
            Subject = 'Valid Interview',
            StartDateTime = Datetime.newInstance(tomorrow, Time.newInstance(10, 0, 0, 0)),
            EndDateTime = Datetime.newInstance(tomorrow, Time.newInstance(11, 0, 0, 0))
        );
        
        Test.startTest();
        insert validEvent;
        Test.stopTest();
        
        // Verify event was created successfully
        Event insertedEvent = [SELECT Id, Subject FROM Event WHERE Id = :validEvent.Id];
        System.assertEquals('Valid Interview', insertedEvent.Subject, 'Event should be created successfully');
    }
    
    /**
     * @description Test event update validation
     */
    @isTest
    static void testEventUpdateValidation() {
        Date tomorrow = Date.today().addDays(1);
        
        // Skip weekend
        while (tomorrow.toStartOfWeek().daysBetween(tomorrow) >= 5) {
            tomorrow = tomorrow.addDays(1);
        }
        
        // Create valid event
        Event validEvent = new Event(
            Subject = 'Valid Interview',
            StartDateTime = Datetime.newInstance(tomorrow, Time.newInstance(10, 0, 0, 0)),
            EndDateTime = Datetime.newInstance(tomorrow, Time.newInstance(11, 0, 0, 0))
        );
        insert validEvent;
        
        // Try to update to weekend
        Date nextSaturday = tomorrow.addDays((7 - Math.mod(tomorrow.toStartOfWeek().daysBetween(tomorrow), 7) + 6));
        validEvent.StartDateTime = Datetime.newInstance(nextSaturday, Time.newInstance(10, 0, 0, 0));
        validEvent.EndDateTime = Datetime.newInstance(nextSaturday, Time.newInstance(11, 0, 0, 0));
        
        Test.startTest();
        try {
            update validEvent;
            System.assert(false, 'Should have failed due to weekend validation');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Weekend meetings'), 
                         'Should contain weekend validation message');
        }
        Test.stopTest();
    }
    
    /**
     * @description Test bulk event processing
     */
    @isTest
    static void testBulkEventProcessing() {
        List<Event> events = new List<Event>();
        Date tomorrow = Date.today().addDays(1);
        
        // Skip weekend
        while (tomorrow.toStartOfWeek().daysBetween(tomorrow) >= 5) {
            tomorrow = tomorrow.addDays(1);
        }
        
        // Create multiple valid events (skip weekends)
        Integer daysAdded = 0;
        for (Integer i = 0; i < 20; i++) { // Reduced to 20 to avoid too many weekend skips
            Date eventDate = tomorrow.addDays(daysAdded);

            // Skip weekends - check day of week (1=Sunday, 7=Saturday)
            Datetime eventDateTime = Datetime.newInstance(eventDate.year(), eventDate.month(), eventDate.day());
            String dayOfWeek = eventDateTime.format('EEEE');

            while (dayOfWeek == 'Saturday' || dayOfWeek == 'Sunday') {
                daysAdded++;
                eventDate = tomorrow.addDays(daysAdded);
                eventDateTime = Datetime.newInstance(eventDate.year(), eventDate.month(), eventDate.day());
                dayOfWeek = eventDateTime.format('EEEE');
            }

            Integer hourOffset = Math.mod(i, 8);
            events.add(new Event(
                Subject = 'Bulk Interview ' + i,
                StartDateTime = Datetime.newInstance(eventDate, Time.newInstance(10 + hourOffset, 0, 0, 0)), // Vary hours to avoid conflicts
                EndDateTime = Datetime.newInstance(eventDate, Time.newInstance(11 + hourOffset, 0, 0, 0))
            ));

            daysAdded++;
        }
        
        Test.startTest();
        insert events;
        Test.stopTest();
        
        // Verify all events were created
        List<Event> insertedEvents = [SELECT Id FROM Event WHERE Id IN :events];
        System.assertEquals(20, insertedEvents.size(), 'All bulk events should be created');
    }
    
    /**
     * @description Test events overlap utility method
     */
    @isTest
    static void testEventsOverlapLogic() {
        Date tomorrow = Date.today().addDays(1);
        
        Event event1 = new Event(
            Subject = 'Event 1',
            StartDateTime = Datetime.newInstance(tomorrow, Time.newInstance(10, 0, 0, 0)),
            EndDateTime = Datetime.newInstance(tomorrow, Time.newInstance(11, 0, 0, 0))
        );
        
        Event event2 = new Event(
            Subject = 'Event 2',
            StartDateTime = Datetime.newInstance(tomorrow, Time.newInstance(10, 30, 0, 0)),
            EndDateTime = Datetime.newInstance(tomorrow, Time.newInstance(11, 30, 0, 0))
        );
        
        Event event3 = new Event(
            Subject = 'Event 3',
            StartDateTime = Datetime.newInstance(tomorrow, Time.newInstance(12, 0, 0, 0)),
            EndDateTime = Datetime.newInstance(tomorrow, Time.newInstance(13, 0, 0, 0))
        );
        
        // Test through trigger (indirect test of overlap logic)
        insert event1;
        
        Test.startTest();
        
        // This should fail due to overlap
        try {
            insert event2;
            System.assert(false, 'Should have failed due to overlap');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Time conflict'), 'Should detect overlap');
        }
        
        // This should succeed (no overlap)
        insert event3;
        
        Test.stopTest();
        
        // Verify non-overlapping event was created
        Event insertedEvent3 = [SELECT Id, Subject FROM Event WHERE Id = :event3.Id];
        System.assertEquals('Event 3', insertedEvent3.Subject, 'Non-overlapping event should be created');
    }
    
    /**
     * @description Test edge case: events with null datetime fields
     */
    @isTest
    static void testNullDateTimeFields() {
        Event eventWithNullFields = new Event(
            Subject = 'Event with null fields',
            ActivityDateTime = Datetime.now().addDays(1),  // Required field for Event
            DurationInMinutes = 60
            // StartDateTime and EndDateTime are null - should not trigger our custom validation
        );

        Test.startTest();
        // Should not trigger validation errors for null datetime fields
        insert eventWithNullFields;
        Test.stopTest();

        // Verify event was created (validation should be skipped for null fields)
        Event insertedEvent = [SELECT Id, Subject FROM Event WHERE Id = :eventWithNullFields.Id];
        System.assertEquals('Event with null fields', insertedEvent.Subject, 'Event with null fields should be created');
    }
}
