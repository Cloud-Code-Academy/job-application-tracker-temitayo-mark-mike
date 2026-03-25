/**
 * @description Scheduler for automated monitoring of Interview Feedback Tracker system
 * @author Interview Feedback Tracker Team
 * @date 2024
 */
public inherited sharing class InterviewFeedbackMonitoringScheduler implements Schedulable {
    
    /**
     * @description Executes scheduled monitoring tasks
     */
    public void execute(SchedulableContext sc) {
        try {
            // Perform comprehensive health check
            InterviewFeedbackMonitoringService.performHealthCheck();
            
            // Clean up expired shares
            cleanupExpiredShares();
            
            // Generate usage statistics
            generateUsageStatistics();
            
            // Check for system maintenance needs
            checkMaintenanceNeeds();
            
        } catch (Exception e) {
            System.debug('Monitoring scheduler failed: ' + e.getMessage());
            
            // Send critical alert about scheduler failure
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new List<String>{'admin@company.com'});
            email.setSubject('CRITICAL: Interview Feedback Monitoring Scheduler Failed');
            email.setPlainTextBody('The monitoring scheduler encountered an error: ' + e.getMessage() + 
                                 '\n\nStack Trace: ' + e.getStackTraceString());
            
            try {
                Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{email});
            } catch (Exception emailEx) {
                System.debug('Failed to send scheduler failure alert: ' + emailEx.getMessage());
            }
        }
    }
    
    /**
     * @description Cleans up expired sharing links
     */
    private void cleanupExpiredShares() {
        try {
            List<Feedback_Share__c> expiredShares = [
                SELECT Id, Is_Active__c
                FROM Feedback_Share__c
                WHERE Is_Active__c = true
                AND Expiration_Date__c < :System.now()
                LIMIT 200
            ];
            
            if (!expiredShares.isEmpty()) {
                for (Feedback_Share__c share : expiredShares) {
                    share.Is_Active__c = false;
                }
                
                update expiredShares;
                System.debug('Cleaned up ' + expiredShares.size() + ' expired shares');
            }
            
        } catch (Exception e) {
            System.debug('Failed to cleanup expired shares: ' + e.getMessage());
        }
    }
    
    /**
     * @description Generates and logs system usage statistics
     */
    private void generateUsageStatistics() {
        try {
            // Calculate usage metrics
            Map<String, Integer> stats = new Map<String, Integer>();
            
            stats.put('totalFeedbackRecords', [SELECT COUNT() FROM Interview_Feedback__c]);
            stats.put('feedbackLast7Days', [SELECT COUNT() FROM Interview_Feedback__c WHERE CreatedDate = LAST_N_DAYS:7]);
            stats.put('feedbackLast30Days', [SELECT COUNT() FROM Interview_Feedback__c WHERE CreatedDate = LAST_N_DAYS:30]);
            stats.put('activeShares', [SELECT COUNT() FROM Feedback_Share__c WHERE Is_Active__c = true]);
            stats.put('totalCompetencyRatings', [SELECT COUNT() FROM Competency_Rating__c]);
            
            // Active users in last 30 days
            Integer activeUsers = [
                SELECT COUNT(DISTINCT CreatedById)
                FROM Interview_Feedback__c
                WHERE CreatedDate = LAST_N_DAYS:30
            ][0].expr0;
            stats.put('activeUsersLast30Days', activeUsers);
            
            // Average ratings
            AggregateResult avgRating = [
                SELECT AVG(Overall_Rating__c) avgRating
                FROM Interview_Feedback__c
                WHERE Overall_Rating__c != null
                AND CreatedDate = LAST_N_DAYS:30
            ][0];
            
            Decimal averageRating = (Decimal)avgRating.get('avgRating');
            
            // Log statistics
            System.debug('=== Interview Feedback Tracker Usage Statistics ===');
            System.debug('Date: ' + System.now());
            for (String metric : stats.keySet()) {
                System.debug(metric + ': ' + stats.get(metric));
            }
            System.debug('averageRatingLast30Days: ' + (averageRating != null ? averageRating.setScale(2) : 'N/A'));
            System.debug('=== End Usage Statistics ===');
            
            // Send weekly summary email (if it's Monday)
            if (System.now().format('E') == 'Mon') {
                sendWeeklyUsageSummary(stats, averageRating);
            }
            
        } catch (Exception e) {
            System.debug('Failed to generate usage statistics: ' + e.getMessage());
        }
    }
    
    /**
     * @description Checks if system maintenance is needed
     */
    private void checkMaintenanceNeeds() {
        try {
            List<String> maintenanceNeeds = new List<String>();
            
            // Check for old audit records that need archiving
            Integer oldAuditRecords = [
                SELECT COUNT()
                FROM Interview_Feedback_Audit__c
                WHERE CreatedDate < LAST_N_DAYS:365
            ];
            
            if (oldAuditRecords > 1000) {
                maintenanceNeeds.add('Archive ' + oldAuditRecords + ' old audit records');
            }
            
            // Check for orphaned competency ratings
            Integer orphanedRatings = [
                SELECT COUNT()
                FROM Competency_Rating__c
                WHERE Interview_Feedback__c = null
            ];
            
            if (orphanedRatings > 0) {
                maintenanceNeeds.add('Clean up ' + orphanedRatings + ' orphaned competency ratings');
            }
            
            // Check for inactive templates
            Integer inactiveTemplates = [
                SELECT COUNT()
                FROM Feedback_Template__c
                WHERE Is_Active__c = false
                AND LastModifiedDate < LAST_N_DAYS:90
            ];
            
            if (inactiveTemplates > 10) {
                maintenanceNeeds.add('Review ' + inactiveTemplates + ' inactive templates for deletion');
            }
            
            // Send maintenance alert if needed
            if (!maintenanceNeeds.isEmpty()) {
                sendMaintenanceAlert(maintenanceNeeds);
            }
            
        } catch (Exception e) {
            System.debug('Failed to check maintenance needs: ' + e.getMessage());
        }
    }
    
    /**
     * @description Sends weekly usage summary email
     */
    private void sendWeeklyUsageSummary(Map<String, Integer> stats, Decimal averageRating) {
        try {
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new List<String>{'admin@company.com'});
            email.setSubject('Interview Feedback Tracker - Weekly Usage Summary');
            
            String emailBody = 'Weekly Usage Summary for Interview Feedback Tracker:\n\n';
            emailBody += 'System Activity:\n';
            emailBody += '- New feedback records (last 7 days): ' + stats.get('feedbackLast7Days') + '\n';
            emailBody += '- New feedback records (last 30 days): ' + stats.get('feedbackLast30Days') + '\n';
            emailBody += '- Active users (last 30 days): ' + stats.get('activeUsersLast30Days') + '\n';
            emailBody += '- Average rating (last 30 days): ' + (averageRating != null ? averageRating.setScale(2) : 'N/A') + '\n\n';
            
            emailBody += 'System Totals:\n';
            emailBody += '- Total feedback records: ' + stats.get('totalFeedbackRecords') + '\n';
            emailBody += '- Total competency ratings: ' + stats.get('totalCompetencyRatings') + '\n';
            emailBody += '- Active shares: ' + stats.get('activeShares') + '\n\n';
            
            emailBody += 'Generated: ' + System.now() + '\n';
            emailBody += 'Org: ' + UserInfo.getOrganizationName();
            
            email.setPlainTextBody(emailBody);
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{email});
            
        } catch (Exception e) {
            System.debug('Failed to send weekly usage summary: ' + e.getMessage());
        }
    }
    
    /**
     * @description Sends maintenance alert email
     */
    private void sendMaintenanceAlert(List<String> maintenanceNeeds) {
        try {
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new List<String>{'admin@company.com'});
            email.setSubject('Interview Feedback Tracker - Maintenance Required');
            
            String emailBody = 'The following maintenance tasks are recommended for the Interview Feedback Tracker:\n\n';
            
            for (String need : maintenanceNeeds) {
                emailBody += '- ' + need + '\n';
            }
            
            emailBody += '\nPlease schedule these maintenance tasks during the next maintenance window.\n\n';
            emailBody += 'Generated: ' + System.now() + '\n';
            emailBody += 'Org: ' + UserInfo.getOrganizationName();
            
            email.setPlainTextBody(emailBody);
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{email});
            
        } catch (Exception e) {
            System.debug('Failed to send maintenance alert: ' + e.getMessage());
        }
    }
    
    /**
     * @description Schedules the monitoring job to run every 4 hours
     */
    public static void scheduleMonitoring() {
        try {
            // Delete existing scheduled jobs
            List<CronTrigger> existingJobs = [
                SELECT Id 
                FROM CronTrigger 
                WHERE CronJobDetail.Name LIKE '%InterviewFeedbackMonitoring%'
            ];
            
            for (CronTrigger job : existingJobs) {
                System.abortJob(job.Id);
            }
            
            // Schedule new monitoring job every 4 hours
            String cronExpression = '0 0 */4 * * ?'; // Every 4 hours
            System.schedule(
                'Interview Feedback Monitoring - Every 4 Hours',
                cronExpression,
                new InterviewFeedbackMonitoringScheduler()
            );
            
            System.debug('Interview Feedback monitoring scheduled successfully');
            
        } catch (Exception e) {
            System.debug('Failed to schedule monitoring: ' + e.getMessage());
        }
    }
}