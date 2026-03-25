// Cancel all scheduled jobs to allow deployment
System.debug('Cancelling all scheduled jobs...');

try {
    SalaryMarketAnalysisScheduler.cancelAllJobs();
    System.debug('✅ Successfully cancelled scheduled jobs');
} catch (Exception e) {
    System.debug('❌ Error cancelling jobs: ' + e.getMessage());
}

// Also cancel any other scheduled jobs that might be blocking
List<CronTrigger> allJobs = [
    SELECT Id, CronJobDetail.Name, State
    FROM CronTrigger 
    WHERE State IN ('WAITING', 'ACQUIRED', 'EXECUTING')
];

System.debug('Found ' + allJobs.size() + ' scheduled jobs to cancel');

for (CronTrigger job : allJobs) {
    try {
        System.abortJob(job.Id);
        System.debug('Cancelled job: ' + job.CronJobDetail.Name);
    } catch (Exception e) {
        System.debug('Failed to cancel job ' + job.Id + ': ' + e.getMessage());
    }
}

System.debug('Job cancellation complete');
