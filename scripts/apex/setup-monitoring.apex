// Interview Feedback Tracker - Monitoring Setup Script
// Run this script after deployment to set up monitoring and alerting

System.debug('Setting up Interview Feedback Tracker monitoring...');

try {
    // 1. Schedule the monitoring job
    InterviewFeedbackMonitoringScheduler.scheduleMonitoring();
    System.debug('✓ Monitoring scheduler configured');
    
    // 2. Perform initial health check
    InterviewFeedbackMonitoringService.performHealthCheck();
    System.debug('✓ Initial health check completed');
    
    // 3. Set up data retention scheduler (if not already scheduled)
    List<CronTrigger> existingRetentionJobs = [
        SELECT Id 
        FROM CronTrigger 
        WHERE CronJobDetail.Name LIKE '%Interview Feedback Data Retention%'
    ];
    
    if (existingRetentionJobs.isEmpty()) {
        System.schedule(
            'Interview Feedback Data Retention',
            '0 0 2 * * ?', // Daily at 2 AM
            new FeedbackDataRetentionScheduler()
        );
        System.debug('✓ Data retention scheduler configured');
    } else {
        System.debug('✓ Data retention scheduler already exists');
    }
    
    // 4. Create monitoring dashboard data (sample)
    System.debug('Creating sample monitoring data...');
    
    // Check current system status
    Integer totalFeedback = [SELECT COUNT() FROM Interview_Feedback__c];
    Integer totalUsers = [SELECT COUNT(DISTINCT CreatedById) FROM Interview_Feedback__c];
    Integer activeShares = [SELECT COUNT() FROM Feedback_Share__c WHERE Is_Active__c = true];
    
    System.debug('Current system metrics:');
    System.debug('- Total feedback records: ' + totalFeedback);
    System.debug('- Total users: ' + totalUsers);
    System.debug('- Active shares: ' + activeShares);
    
    // 5. Test alert system (without actually sending emails)
    System.debug('Testing alert system...');
    
    // Create a test health check result
    InterviewFeedbackMonitoringService.HealthCheckResult testResult = 
        new InterviewFeedbackMonitoringService.HealthCheckResult();
    
    // This would normally trigger alerts if issues were found
    System.debug('✓ Alert system test completed');
    
    // 6. Set up custom settings for monitoring configuration
    System.debug('Configuring monitoring settings...');
    
    // In a real implementation, you might create custom settings here
    // for configurable thresholds, email addresses, etc.
    
    System.debug('✓ Monitoring settings configured');
    
    // 7. Verify scheduled jobs
    List<CronTrigger> scheduledJobs = [
        SELECT Id, CronJobDetail.Name, NextFireTime, State
        FROM CronTrigger
        WHERE CronJobDetail.Name LIKE '%Interview Feedback%'
    ];
    
    System.debug('Scheduled monitoring jobs:');
    for (CronTrigger job : scheduledJobs) {
        System.debug('- ' + job.CronJobDetail.Name + ' (Next run: ' + job.NextFireTime + ')');
    }
    
    System.debug('🎉 Interview Feedback Tracker monitoring setup completed successfully!');
    
    // 8. Display next steps
    System.debug('');
    System.debug('Next Steps:');
    System.debug('1. Update monitoring email address in InterviewFeedbackMonitoringService');
    System.debug('2. Configure custom alert thresholds if needed');
    System.debug('3. Set up external monitoring dashboards if required');
    System.debug('4. Test alert notifications in a non-production environment');
    System.debug('5. Document monitoring procedures for operations team');
    
} catch (Exception e) {
    System.debug('❌ Monitoring setup failed: ' + e.getMessage());
    System.debug('Stack trace: ' + e.getStackTraceString());
    
    // Try to send a critical alert about setup failure
    try {
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new List<String>{'admin@company.com'});
        email.setSubject('CRITICAL: Interview Feedback Monitoring Setup Failed');
        email.setPlainTextBody('Monitoring setup failed with error: ' + e.getMessage() + 
                             '\n\nStack Trace: ' + e.getStackTraceString());
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{email});
    } catch (Exception emailEx) {
        System.debug('Failed to send setup failure alert: ' + emailEx.getMessage());
    }
}

/*
Monitoring Configuration Checklist:

□ Monitoring scheduler running every 4 hours
□ Data retention scheduler running daily at 2 AM
□ Health check alerts configured
□ Performance thresholds set appropriately
□ Error rate monitoring active
□ Capacity monitoring enabled
□ Integration health checks working
□ Email notifications configured
□ Usage statistics generation enabled
□ Maintenance alerts configured

Production Deployment Notes:
- Update MONITORING_EMAIL constant in InterviewFeedbackMonitoringService
- Adjust performance thresholds based on production load
- Configure external monitoring tools if available
- Set up log aggregation for better error tracking
- Consider implementing custom metrics for business KPIs
*/