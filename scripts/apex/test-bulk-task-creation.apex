// Test bulk task creation with multiple Job Applications
List<Job_Application__c> bulkJobApps = new List<Job_Application__c>();

// Create 10 job applications for bulk testing
for (Integer i = 1; i <= 10; i++) {
    bulkJobApps.add(new Job_Application__c(
        Company_Name__c = 'Bulk Test Company ' + i,
        Position_Title__c = 'Developer ' + i,
        Status__c = 'Saved',
        Salary__c = 75000 + (i * 5000)
    ));
}

System.debug('Creating ' + bulkJobApps.size() + ' Job Applications...');

// Insert all at once - this should trigger bulk task creation
insert bulkJobApps;

System.debug('Job Applications created successfully!');

// Query to count tasks created
List<Task> allTasks = [SELECT Id, WhatId FROM Task WHERE WhatId IN :bulkJobApps];
System.debug('Total tasks created: ' + allTasks.size());
System.debug('Expected tasks: ' + (bulkJobApps.size() * 3) + ' (3 tasks per Saved status)');

// Verify bulkification - should be exactly 30 tasks (10 apps × 3 tasks each)
System.assertEquals(30, allTasks.size(), 'Should create exactly 30 tasks for 10 Saved applications');