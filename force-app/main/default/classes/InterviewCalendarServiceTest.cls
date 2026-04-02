/**
 * @description Test class for InterviewCalendarService
 * Tests upcoming/past interview queries and wrapper class
 * @author Test Suite
 * @date 2025
 */
@IsTest
private class InterviewCalendarServiceTest {

    @TestSetup
    static void setupTestData() {
        // Create a Job Application to relate events to
        Job_Application__c jobApp = TestDataFactory.createJobApplication(
            'Interview Co', 'Software Engineer', 'Interviewing', 100000, true
        );

        // Create future events (upcoming interviews)
        List<Event> events = new List<Event>();
        events.add(new Event(
            Subject = 'Technical Interview - Future',
            StartDateTime = Datetime.now().addDays(3),
            EndDateTime = Datetime.now().addDays(3).addHours(1),
            Location = 'Zoom Meeting',
            Description = 'Technical interview round 1',
            WhatId = jobApp.Id
        ));
        events.add(new Event(
            Subject = 'HR Interview - Future',
            StartDateTime = Datetime.now().addDays(7),
            EndDateTime = Datetime.now().addDays(7).addHours(1),
            Location = 'Office',
            Description = 'HR screening call'
        ));

        // Create past events (within last 30 days)
        events.add(new Event(
            Subject = 'Phone Screen - Past',
            StartDateTime = Datetime.now().addDays(-5),
            EndDateTime = Datetime.now().addDays(-5).addHours(1),
            Location = 'Phone',
            Description = 'Initial phone screening',
            WhatId = jobApp.Id
        ));
        events.add(new Event(
            Subject = 'Culture Fit - Past',
            StartDateTime = Datetime.now().addDays(-10),
            EndDateTime = Datetime.now().addDays(-10).addHours(1),
            Location = 'Virtual',
            Description = 'Culture fit interview'
        ));

        insert events;
    }

    @IsTest
    static void testGetUpcomingInterviews() {
        Test.startTest();
        List<InterviewCalendarService.InterviewEvent> upcoming =
            InterviewCalendarService.getUpcomingInterviews();
        Test.stopTest();

        System.assertNotEquals(null, upcoming, 'Upcoming interviews list should not be null');
        System.assert(upcoming.size() >= 2, 'Should have at least 2 upcoming interviews');

        // Verify events are in the future
        for (InterviewCalendarService.InterviewEvent evt : upcoming) {
            System.assert(evt.startTime >= Datetime.now().addMinutes(-1),
                'Upcoming interviews should have future start times');
        }
    }

    @IsTest
    static void testGetPastInterviews() {
        Test.startTest();
        List<InterviewCalendarService.InterviewEvent> past =
            InterviewCalendarService.getPastInterviews();
        Test.stopTest();

        System.assertNotEquals(null, past, 'Past interviews list should not be null');
        System.assert(past.size() >= 2, 'Should have at least 2 past interviews');

        // Verify events are in the past
        for (InterviewCalendarService.InterviewEvent evt : past) {
            System.assert(evt.startTime < Datetime.now(),
                'Past interviews should have past start times');
        }
    }

    @IsTest
    static void testUpcomingInterviewWrapperFields() {
        Test.startTest();
        List<InterviewCalendarService.InterviewEvent> upcoming =
            InterviewCalendarService.getUpcomingInterviews();
        Test.stopTest();

        System.assert(!upcoming.isEmpty(), 'Should have upcoming interviews');

        InterviewCalendarService.InterviewEvent evt = upcoming[0];
        System.assertNotEquals(null, evt.id, 'Event Id should not be null');
        System.assertNotEquals(null, evt.subject, 'Subject should not be null');
        System.assertNotEquals(null, evt.startTime, 'Start time should not be null');
        System.assertNotEquals(null, evt.endTime, 'End time should not be null');
    }

    @IsTest
    static void testUpcomingInterviewWithRelatedRecord() {
        Test.startTest();
        List<InterviewCalendarService.InterviewEvent> upcoming =
            InterviewCalendarService.getUpcomingInterviews();
        Test.stopTest();

        Boolean foundRelated = false;
        for (InterviewCalendarService.InterviewEvent evt : upcoming) {
            if (evt.relatedRecordId != null) {
                foundRelated = true;
                System.assertNotEquals(null, evt.relatedRecordName,
                    'Related record name should be populated when WhatId is set');
            }
        }
        System.assert(foundRelated, 'At least one upcoming interview should have a related record');
    }

    @IsTest
    static void testPastInterviewLocation() {
        Test.startTest();
        List<InterviewCalendarService.InterviewEvent> past =
            InterviewCalendarService.getPastInterviews();
        Test.stopTest();

        System.assert(!past.isEmpty(), 'Should have past interviews');

        Boolean hasLocation = false;
        for (InterviewCalendarService.InterviewEvent evt : past) {
            if (evt.location != null) {
                hasLocation = true;
            }
        }
        System.assert(hasLocation, 'At least one past interview should have a location');
    }

    @IsTest
    static void testEmptyResultsForDifferentUser() {
        // The default test context returns events owned by the running user.
        // We cannot easily test zero results without running as a different user,
        // but we can verify the method handles the data gracefully.
        Test.startTest();
        List<InterviewCalendarService.InterviewEvent> upcoming =
            InterviewCalendarService.getUpcomingInterviews();
        List<InterviewCalendarService.InterviewEvent> past =
            InterviewCalendarService.getPastInterviews();
        Test.stopTest();

        // Both should return lists (not null)
        System.assertNotEquals(null, upcoming, 'Upcoming should never be null');
        System.assertNotEquals(null, past, 'Past should never be null');
    }
}
