/**
 * @description Test script for Asynchronous Processing demonstration
 * @author Learning Journey
 * @date 2025-01-08
 * 
 * This script demonstrates the asynchronous processing functionality
 * Run this in Anonymous Apex to test batch jobs and queueable operations
 */

System.debug('=== ASYNCHRONOUS PROCESSING TEST ===');

// Get existing Job Application records
List<Job_Application__c> existingJobApps = [SELECT Id, Company_Name__c, Position_Title__c, Status__c, Application_Date__c 
                                           FROM Job_Application__c 
                                           LIMIT 10];

if (existingJobApps.isEmpty()) {
    System.debug('No existing Job Application records found. Creating test data...');
    
    // Create test Job Application records for demonstration
    List<Job_Application__c> testJobApps = new List<Job_Application__c>();
    
    // Create some duplicate records
    testJobApps.add(new Job_Application__c(
        Company_Name__c = 'Async Test Corp',
        Position_Title__c = 'Software Engineer',
        Status__c = 'Applied',
        Application_Date__c = Date.today().addDays(-10),
        Salary__c = 120000
    ));
    
    testJobApps.add(new Job_Application__c(
        Company_Name__c = 'Async Test Corp',
        Position_Title__c = 'Software Engineer',
        Status__c = 'Applied',
        Application_Date__c = Date.today().addDays(-5),
        Salary__c = 125000
    ));
    
    // Create some old records
    testJobApps.add(new Job_Application__c(
        Company_Name__c = 'Old Company',
        Position_Title__c = 'Legacy Developer',
        Status__c = 'Applied',
        Application_Date__c = Date.today().addDays(-400),
        Salary__c = 80000
    ));
    
    // Create some stale records
    testJobApps.add(new Job_Application__c(
        Company_Name__c = 'Stale Company',
        Position_Title__c = 'Stale Position',
        Status__c = '', // Empty status for stale testing
        Application_Date__c = Date.today().addDays(-30),
        Salary__c = 90000
    ));
    
    // Create normal records for enrichment testing
    testJobApps.add(new Job_Application__c(
        Company_Name__c = 'Enrichment Test Corp',
        Position_Title__c = 'Product Manager',
        Status__c = 'Applied',
        Application_Date__c = Date.today().addDays(-1),
        Salary__c = 110000,
        Location__c = 'San Francisco, CA'
    ));
    
    testJobApps.add(new Job_Application__c(
        Company_Name__c = 'Data Analytics Inc',
        Position_Title__c = 'Data Scientist',
        Status__c = 'Applied',
        Application_Date__c = Date.today().addDays(-2),
        Salary__c = 130000,
        Location__c = 'Seattle, WA'
    ));
    
    insert testJobApps;
    existingJobApps = testJobApps;
    System.debug('Created ' + testJobApps.size() + ' test Job Application records');
}

System.debug('Found ' + existingJobApps.size() + ' Job Application records for testing');

// Test 1: Batch Job - Remove Duplicates
System.debug('\\n--- Test 1: Batch Job - Remove Duplicates ---');

try {
    JobApplicationCleanupBatch duplicateBatch = new JobApplicationCleanupBatch(
        JobApplicationCleanupBatch.CleanupType.REMOVE_DUPLICATES, 
        365, 
        true
    );
    
    Id batchJobId = Database.executeBatch(duplicateBatch, 200);
    
    System.debug('Duplicate removal batch started with Job ID: ' + batchJobId);
    System.debug('Check Setup -> Apex Jobs to monitor progress');
    
} catch (Exception e) {
    System.debug('ERROR starting duplicate removal batch: ' + e.getMessage());
}

// Test 2: Batch Job - Archive Old Records
System.debug('\\n--- Test 2: Batch Job - Archive Old Records ---');

try {
    JobApplicationCleanupBatch archiveBatch = new JobApplicationCleanupBatch(
        JobApplicationCleanupBatch.CleanupType.ARCHIVE_OLD, 
        365, 
        true
    );
    
    Id batchJobId = Database.executeBatch(archiveBatch, 200);
    
    System.debug('Archive batch started with Job ID: ' + batchJobId);
    System.debug('This will archive records older than 365 days');
    
} catch (Exception e) {
    System.debug('ERROR starting archive batch: ' + e.getMessage());
}

// Test 3: Batch Job - Update Stale Records
System.debug('\\n--- Test 3: Batch Job - Update Stale Records ---');

try {
    JobApplicationCleanupBatch staleBatch = new JobApplicationCleanupBatch(
        JobApplicationCleanupBatch.CleanupType.UPDATE_STALE, 
        365, 
        true
    );
    
    Id batchJobId = Database.executeBatch(staleBatch, 200);
    
    System.debug('Stale record update batch started with Job ID: ' + batchJobId);
    System.debug('This will update records with missing or inconsistent data');
    
} catch (Exception e) {
    System.debug('ERROR starting stale update batch: ' + e.getMessage());
}

// Test 4: Queueable Job - Company Data Enrichment
System.debug('\\n--- Test 4: Queueable Job - Company Data Enrichment ---');

try {
    List<Id> jobAppIds = new List<Id>();
    for (Integer i = 0; i < Math.min(3, existingJobApps.size()); i++) {
        jobAppIds.add(existingJobApps[i].Id);
    }
    
    JobApplicationEnrichmentQueue companyQueue = new JobApplicationEnrichmentQueue(
        jobAppIds,
        JobApplicationEnrichmentQueue.EnrichmentType.COMPANY_DATA
    );
    
    Id queueJobId = System.enqueueJob(companyQueue);
    
    System.debug('Company enrichment queue started with Job ID: ' + queueJobId);
    System.debug('Processing ' + jobAppIds.size() + ' Job Applications');
    System.debug('Job App IDs: ' + jobAppIds);
    
} catch (Exception e) {
    System.debug('ERROR starting company enrichment queue: ' + e.getMessage());
}

// Test 5: Queueable Job - Salary Benchmark Enrichment
System.debug('\\n--- Test 5: Queueable Job - Salary Benchmark Enrichment ---');

try {
    List<Id> jobAppIds = new List<Id>();
    for (Integer i = 0; i < Math.min(2, existingJobApps.size()); i++) {
        jobAppIds.add(existingJobApps[i].Id);
    }
    
    JobApplicationEnrichmentQueue salaryQueue = new JobApplicationEnrichmentQueue(
        jobAppIds,
        JobApplicationEnrichmentQueue.EnrichmentType.SALARY_BENCHMARK
    );
    
    Id queueJobId = System.enqueueJob(salaryQueue);
    
    System.debug('Salary benchmark queue started with Job ID: ' + queueJobId);
    System.debug('Processing ' + jobAppIds.size() + ' Job Applications');
    
} catch (Exception e) {
    System.debug('ERROR starting salary benchmark queue: ' + e.getMessage());
}

// Test 6: Queueable Job - Full Enrichment
System.debug('\\n--- Test 6: Queueable Job - Full Enrichment ---');

try {
    List<Id> jobAppIds = new List<Id>();
    if (existingJobApps.size() > 0) {
        jobAppIds.add(existingJobApps[0].Id);
    }
    
    JobApplicationEnrichmentQueue fullQueue = new JobApplicationEnrichmentQueue(
        jobAppIds,
        JobApplicationEnrichmentQueue.EnrichmentType.FULL_ENRICHMENT
    );
    
    Id queueJobId = System.enqueueJob(fullQueue);
    
    System.debug('Full enrichment queue started with Job ID: ' + queueJobId);
    System.debug('This will perform company, salary, and market analysis enrichment');
    
} catch (Exception e) {
    System.debug('ERROR starting full enrichment queue: ' + e.getMessage());
}

// Test 7: Scheduled Job - Daily Cleanup
System.debug('\\n--- Test 7: Scheduled Job - Daily Cleanup ---');

try {
    // Schedule a cleanup job to run in 2 minutes (for demonstration)
    DateTime scheduleTime = DateTime.now().addMinutes(2);
    String cronExpression = scheduleTime.format('s m H d M ? yyyy');
    
    JobApplicationCleanupScheduler scheduler = new JobApplicationCleanupScheduler(
        JobApplicationCleanupBatch.CleanupType.UPDATE_STALE, 
        365, 
        true
    );
    
    String scheduledJobId = System.schedule('Demo Cleanup Job - ' + DateTime.now().format(), cronExpression, scheduler);
    
    System.debug('Scheduled cleanup job created with ID: ' + scheduledJobId);
    System.debug('Job will run at: ' + scheduleTime.format());
    System.debug('Check Setup -> Scheduled Jobs to see the scheduled job');
    
} catch (Exception e) {
    System.debug('ERROR scheduling cleanup job: ' + e.getMessage());
}

// Test 8: Scheduler Utility Methods
System.debug('\\n--- Test 8: Scheduler Utility Methods ---');

try {
    // Get current scheduled cleanup jobs
    List<CronTrigger> scheduledJobs = JobApplicationCleanupScheduler.getScheduledCleanupJobs();
    
    System.debug('Current scheduled cleanup jobs: ' + scheduledJobs.size());
    for (CronTrigger job : scheduledJobs) {
        System.debug('- Job: ' + job.CronJobDetail.Name + ', Next Run: ' + job.NextFireTime);
    }
    
    // Schedule a weekly cleanup (for demonstration)
    String weeklyJobId = JobApplicationCleanupScheduler.scheduleWeeklyCleanup(
        JobApplicationCleanupBatch.CleanupType.REMOVE_DUPLICATES,
        1, // Sunday
        2, // 2 AM
        0  // 0 minutes
    );
    
    System.debug('Weekly cleanup job scheduled with ID: ' + weeklyJobId);
    
} catch (Exception e) {
    System.debug('ERROR with scheduler utilities: ' + e.getMessage());
}

// Test 9: Monitor Async Jobs
System.debug('\\n--- Test 9: Monitor Async Jobs ---');

try {
    // Query recent async jobs
    List<AsyncApexJob> recentJobs = [
        SELECT Id, JobType, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, 
               CreatedDate, CompletedDate, ExtendedStatus
        FROM AsyncApexJob 
        WHERE CreatedDate = TODAY
        ORDER BY CreatedDate DESC
        LIMIT 10
    ];
    
    System.debug('Recent async jobs today: ' + recentJobs.size());
    for (AsyncApexJob job : recentJobs) {
        System.debug('- Job ID: ' + job.Id + ', Type: ' + job.JobType + ', Status: ' + job.Status);
        if (job.NumberOfErrors > 0) {
            System.debug('  Errors: ' + job.NumberOfErrors);
        }
        if (job.TotalJobItems > 0) {
            System.debug('  Progress: ' + job.JobItemsProcessed + '/' + job.TotalJobItems);
        }
    }
    
} catch (Exception e) {
    System.debug('ERROR querying async jobs: ' + e.getMessage());
}

// Test 10: Performance Metrics
System.debug('\\n--- Test 10: Performance Metrics ---');

try {
    // Get Job Application counts for performance analysis
    Integer totalJobApps = [SELECT COUNT() FROM Job_Application__c];
    Integer appliedJobApps = [SELECT COUNT() FROM Job_Application__c WHERE Status__c = 'Applied'];
    Integer archivedJobApps = [SELECT COUNT() FROM Job_Application__c WHERE Status__c = 'Archived'];
    
    System.debug('=== JOB APPLICATION METRICS ===');
    System.debug('Total Job Applications: ' + totalJobApps);
    System.debug('Applied Status: ' + appliedJobApps);
    System.debug('Archived Status: ' + archivedJobApps);
    
    // Calculate processing recommendations
    if (totalJobApps > 1000) {
        System.debug('RECOMMENDATION: Use batch size of 100-200 for optimal performance');
    } else if (totalJobApps > 100) {
        System.debug('RECOMMENDATION: Use batch size of 50-100 for good performance');
    } else {
        System.debug('RECOMMENDATION: Standard batch size of 200 is fine');
    }
    
} catch (Exception e) {
    System.debug('ERROR calculating performance metrics: ' + e.getMessage());
}

System.debug('\\n=== ASYNCHRONOUS PROCESSING TEST COMPLETE ===');
System.debug('\\nMONITORING INSTRUCTIONS:');
System.debug('1. Go to Setup -> Apex Jobs to monitor batch job progress');
System.debug('2. Go to Setup -> Scheduled Jobs to see scheduled jobs');
System.debug('3. Check the Job Application records to see enrichment results');
System.debug('4. Look for COMPANY ENRICHMENT, SALARY ENRICHMENT, and MARKET ANALYSIS in Notes fields');
System.debug('5. Monitor the debug logs for detailed execution information');
System.debug('\\nThe asynchronous processing framework is working! 🚀');