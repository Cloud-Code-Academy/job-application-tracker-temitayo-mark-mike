// Test large-scale bulk processing with 200 Job Applications
List<Job_Application__c> largeJobApps = new List<Job_Application__c>();

System.debug('=== Large Scale Bulk Processing Test ===');
System.debug('Creating 200 Job Applications...');

// Create 200 job applications for large-scale bulk testing
for (Integer i = 1; i <= 200; i++) {
    largeJobApps.add(new Job_Application__c(
        Company_Name__c = 'Large Bulk Test Company ' + i,
        Position_Title__c = 'Engineer ' + i,
        Status__c = 'Saved',
        Salary__c = 70000 + (i * 500)
    ));
}

// Track performance
Datetime startTime = Datetime.now();

// Insert all at once - this should trigger bulk task creation
insert largeJobApps;

Datetime endTime = Datetime.now();
Long processingTime = endTime.getTime() - startTime.getTime();

System.debug('Job Applications created in ' + processingTime + ' milliseconds');

// Query to count tasks created
List<Task> allTasks = [SELECT Id, WhatId FROM Task WHERE WhatId IN :largeJobApps];
System.debug('Total tasks created: ' + allTasks.size());
System.debug('Expected tasks: ' + (largeJobApps.size() * 3) + ' (3 tasks per Saved status)');

// Verify bulkification efficiency
System.assertEquals(600, allTasks.size(), 'Should create exactly 600 tasks for 200 Saved applications');

System.debug('=== Performance Metrics ===');
System.debug('Records processed: ' + largeJobApps.size());
System.debug('Tasks created: ' + allTasks.size());
System.debug('Processing time: ' + processingTime + 'ms');
System.debug('Average time per record: ' + (processingTime / largeJobApps.size()) + 'ms');

System.debug('✅ Large-scale bulk processing test completed successfully!');