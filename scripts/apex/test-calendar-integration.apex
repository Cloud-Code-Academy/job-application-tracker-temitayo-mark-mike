// Test calendar integration functionality
// Create a Job Application for testing the calendar component

Job_Application__c testJobApp = new Job_Application__c(
    Company_Name__c = 'Calendar Test Company',
    Position_Title__c = 'Senior Developer',
    Status__c = 'Interviewing',
    Salary__c = 120000
);

insert testJobApp;

System.debug('=== Calendar Integration Test ===');
System.debug('Created Job Application: ' + testJobApp.Id);
System.debug('Company: ' + testJobApp.Company_Name__c);
System.debug('Position: ' + testJobApp.Position_Title__c);
System.debug('Status: ' + testJobApp.Status__c);

// Create a test Event to simulate calendar integration (during business hours)
DateTime tomorrow = DateTime.now().addDays(1);
DateTime businessHourStart = DateTime.newInstance(tomorrow.date(), Time.newInstance(10, 0, 0, 0)); // 10 AM
DateTime businessHourEnd = businessHourStart.addHours(1); // 11 AM

Event testEvent = new Event(
    Subject = 'Technical Interview - Senior Developer at Calendar Test Company',
    StartDateTime = businessHourStart,
    EndDateTime = businessHourEnd,
    Description = 'Interview scheduled via Calendar Integration component\n\nJob Application Details:\nCompany: Calendar Test Company\nPosition: Senior Developer\nStatus: Interviewing\n\nInterview Type: Technical Interview',
    Location = 'Zoom',
    WhatId = testJobApp.Id
);

insert testEvent;

System.debug('Created Event: ' + testEvent.Id);
System.debug('Event Subject: ' + testEvent.Subject);
System.debug('Start Time: ' + testEvent.StartDateTime);
System.debug('End Time: ' + testEvent.EndDateTime);
System.debug('Location: ' + testEvent.Location);

// Query to verify the relationship
List<Event> relatedEvents = [
    SELECT Id, Subject, StartDateTime, EndDateTime, Location, Description, WhatId
    FROM Event 
    WHERE WhatId = :testJobApp.Id
];

System.debug('=== Related Events Query ===');
System.debug('Found ' + relatedEvents.size() + ' events related to Job Application');

for (Event evt : relatedEvents) {
    System.debug('Event: ' + evt.Subject + ' at ' + evt.StartDateTime);
}

System.debug('✅ Calendar integration test completed successfully!');