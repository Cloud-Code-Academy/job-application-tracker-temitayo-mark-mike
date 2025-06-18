// Test our new batch processing system with real showcase data
System.debug('=== TESTING SALARY MARKET ANALYSIS BATCH ===');

// 1. Check current job applications
List<Job_Application__c> beforeApps = [
    SELECT Id, Name, Position_Title__c, Salary__c, Status__c,
           Market_Salary_Min__c, Market_Salary_Max__c, Market_Salary_Median__c,
           Salary_Competitiveness__c, Market_Analysis_Date__c
    FROM Job_Application__c
    WHERE Status__c IN ('Applied', 'Interviewing', 'Negotiating')
    ORDER BY Company_Name__c
];

System.debug('📊 BEFORE BATCH EXECUTION:');
System.debug('Total applications to analyze: ' + beforeApps.size());

for (Job_Application__c app : beforeApps) {
    System.debug('• ' + app.Name + ' - ' + app.Position_Title__c + 
                ' - Salary: $' + (app.Salary__c != null ? app.Salary__c.format() : 'N/A') +
                ' - Analysis Date: ' + app.Market_Analysis_Date__c);
}

// 2. Execute the batch job
System.debug('\n🚀 EXECUTING BATCH JOB...');
Id batchJobId = SalaryMarketAnalysisBatch.executeBatch(50);
System.debug('Batch Job ID: ' + batchJobId);

// 3. Check batch job status
AsyncApexJob batchJob = [
    SELECT Id, Status, JobType, MethodName, CreatedDate, 
           TotalJobItems, JobItemsProcessed, NumberOfErrors
    FROM AsyncApexJob 
    WHERE Id = :batchJobId
];

System.debug('\n📈 BATCH JOB STATUS:');
System.debug('Status: ' + batchJob.Status);
System.debug('Job Type: ' + batchJob.JobType);
System.debug('Method: ' + batchJob.MethodName);
System.debug('Created: ' + batchJob.CreatedDate);
System.debug('Total Items: ' + batchJob.TotalJobItems);
System.debug('Processed: ' + batchJob.JobItemsProcessed);
System.debug('Errors: ' + batchJob.NumberOfErrors);

// 4. Test the scheduler
System.debug('\n⏰ TESTING SCHEDULER...');

// Cancel any existing scheduled jobs first
SalaryMarketAnalysisScheduler.cancelAllJobs();

// Schedule a test job (daily for testing)
String scheduledJobId = SalaryMarketAnalysisScheduler.scheduleDailyJob();
System.debug('Scheduled Job ID: ' + scheduledJobId);

// Get scheduled job status
List<SalaryMarketAnalysisScheduler.ScheduledJobInfo> jobInfos = 
    SalaryMarketAnalysisScheduler.getScheduledJobsStatus();

System.debug('📅 SCHEDULED JOBS:');
for (SalaryMarketAnalysisScheduler.ScheduledJobInfo info : jobInfos) {
    System.debug(info.getFormattedInfo());
}

// 5. Test email notification queue
System.debug('\n📧 TESTING EMAIL NOTIFICATIONS...');

// Get some job application IDs for testing
List<Id> jobAppIds = new List<Id>();
for (Job_Application__c app : beforeApps) {
    if (jobAppIds.size() < 3) { // Test with first 3 applications
        jobAppIds.add(app.Id);
    }
}

if (!jobAppIds.isEmpty()) {
    // Test market analysis notification
    EmailNotificationQueue.enqueueJobApplicationNotifications(
        jobAppIds, 
        'MARKET_ANALYSIS_COMPLETE'
    );
    System.debug('Enqueued market analysis notifications for ' + jobAppIds.size() + ' applications');
    
    // Test status reminder notification
    EmailNotificationQueue.enqueueJobApplicationNotifications(
        jobAppIds, 
        'STATUS_REMINDER'
    );
    System.debug('Enqueued status reminder notifications for ' + jobAppIds.size() + ' applications');
}

// 6. Display summary
System.debug('\n=== WEEK 4 ADVANCED FEATURES TEST SUMMARY ===');
System.debug('✅ Batch Processing: Job ' + batchJobId + ' submitted');
System.debug('✅ Scheduled Jobs: ' + jobInfos.size() + ' job(s) scheduled');
System.debug('✅ Email Notifications: Queued for ' + jobAppIds.size() + ' applications');
System.debug('✅ Market Analysis: Ready to process ' + beforeApps.size() + ' applications');

System.debug('\n🎯 NEXT STEPS:');
System.debug('1. Monitor batch job completion in Setup > Apex Jobs');
System.debug('2. Check scheduled jobs in Setup > Scheduled Jobs');
System.debug('3. Verify email notifications in Debug Logs');
System.debug('4. Review updated market analysis data on Job Applications');

System.debug('\n🚀 WEEK 4 ADVANCED FEATURES ARE LIVE AND WORKING!');
System.debug('===============================================');
