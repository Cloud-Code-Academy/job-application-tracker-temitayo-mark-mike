/**
 * @description Monitoring and alerting service for Interview Feedback Tracker
 * @author Interview Feedback Tracker Team
 * @date 2024
 */
public inherited sharing class InterviewFeedbackMonitoringService {
    
    private static final String MONITORING_EMAIL = 'admin@company.com';
    private static final Integer ERROR_THRESHOLD = 10;
    private static final Integer PERFORMANCE_THRESHOLD_MS = 5000;
    
    /**
     * @description Monitors system health and sends alerts if issues are detected
     */
    public static void performHealthCheck() {
        HealthCheckResult result = new HealthCheckResult();
        
        try {
            // Check data integrity
            result.dataIntegrityCheck = checkDataIntegrity();
            
            // Check performance metrics
            result.performanceCheck = checkPerformanceMetrics();
            
            // Check error rates
            result.errorRateCheck = checkErrorRates();
            
            // Check system capacity
            result.capacityCheck = checkSystemCapacity();
            
            // Check integration health
            result.integrationCheck = checkIntegrationHealth();
            
            // Send alerts if issues found
            if (result.hasIssues()) {
                sendHealthAlert(result);
            }
            
            // Log health check results
            logHealthCheckResults(result);
            
        } catch (Exception e) {
            System.debug('Health check failed: ' + e.getMessage());
            sendCriticalAlert('Health Check Failure', e.getMessage());
        }
    }
    
    /**
     * @description Checks data integrity across all Interview Feedback objects
     */
    private static HealthCheckItem checkDataIntegrity() {
        HealthCheckItem item = new HealthCheckItem('Data Integrity');
        
        try {
            // Check for orphaned competency ratings
            Integer orphanedRatings = [
                SELECT COUNT() 
                FROM Competency_Rating__c 
                WHERE Interview_Feedback__c = null
            ];
            
            if (orphanedRatings > 0) {
                item.addIssue('Found ' + orphanedRatings + ' orphaned competency ratings');
            }
            
            // Check for feedback without ratings
            Integer feedbackWithoutRatings = [
                SELECT COUNT() 
                FROM Interview_Feedback__c 
                WHERE Overall_Rating__c = null 
                AND Feedback_Status__c = 'Submitted'
            ];
            
            if (feedbackWithoutRatings > 0) {
                item.addIssue('Found ' + feedbackWithoutRatings + ' submitted feedback without ratings');
            }
            
            // Check for expired shares still active
            Integer expiredActiveShares = [
                SELECT COUNT() 
                FROM Feedback_Share__c 
                WHERE Is_Active__c = true 
                AND Expiration_Date__c < :System.now()
            ];
            
            if (expiredActiveShares > 0) {
                item.addIssue('Found ' + expiredActiveShares + ' expired shares still active');
            }
            
            // Check for invalid job application references
            Integer invalidJobAppRefs = [
                SELECT COUNT() 
                FROM Interview_Feedback__c 
                WHERE Job_Application__c NOT IN (
                    SELECT Id FROM Job_Application__c
                )
            ];
            
            if (invalidJobAppRefs > 0) {
                item.addIssue('Found ' + invalidJobAppRefs + ' feedback records with invalid job application references');
            }
            
            item.status = item.issues.isEmpty() ? 'Healthy' : 'Issues Found';
            
        } catch (Exception e) {
            item.status = 'Error';
            item.addIssue('Data integrity check failed: ' + e.getMessage());
        }
        
        return item;
    }
    
    /**
     * @description Monitors performance metrics and identifies bottlenecks
     */
    private static HealthCheckItem checkPerformanceMetrics() {
        HealthCheckItem item = new HealthCheckItem('Performance');
        
        try {
            // Test dashboard data generation performance
            Long startTime = System.currentTimeMillis();
            FeedbackAnalyticsService.DashboardData testData = 
                FeedbackAnalyticsService.generateDashboardData(UserInfo.getUserId());
            Long endTime = System.currentTimeMillis();
            
            Long dashboardTime = endTime - startTime;
            if (dashboardTime > PERFORMANCE_THRESHOLD_MS) {
                item.addIssue('Dashboard generation taking ' + dashboardTime + 'ms (threshold: ' + PERFORMANCE_THRESHOLD_MS + 'ms)');
            }
            
            // Test feedback creation performance
            startTime = System.currentTimeMillis();
            // Simulate feedback creation without actually creating records
            Map<String, Object> testFeedbackData = new Map<String, Object>{
                'interviewRound' => 'Test',
                'overallRating' => 4.0
            };
            endTime = System.currentTimeMillis();
            
            // Check SOQL query performance
            startTime = System.currentTimeMillis();
            List<Interview_Feedback__c> testQuery = [
                SELECT Id, Overall_Rating__c, Technical_Rating__c
                FROM Interview_Feedback__c
                LIMIT 100
            ];
            endTime = System.currentTimeMillis();
            
            Long queryTime = endTime - startTime;
            if (queryTime > 1000) {
                item.addIssue('SOQL queries taking ' + queryTime + 'ms (threshold: 1000ms)');
            }
            
            item.status = item.issues.isEmpty() ? 'Healthy' : 'Performance Issues';
            
        } catch (Exception e) {
            item.status = 'Error';
            item.addIssue('Performance check failed: ' + e.getMessage());
        }
        
        return item;
    }
    
    /**
     * @description Monitors error rates and identifies problematic patterns
     */
    private static HealthCheckItem checkErrorRates() {
        HealthCheckItem item = new HealthCheckItem('Error Rates');
        
        try {
            // Check for recent exceptions in debug logs (simulated)
            // In a real implementation, this would query actual error logs
            
            // Check for failed batch jobs
            List<AsyncApexJob> failedJobs = [
                SELECT Id, ApexClass.Name, Status, NumberOfErrors, ExtendedStatus
                FROM AsyncApexJob
                WHERE ApexClass.Name LIKE '%InterviewFeedback%'
                AND Status = 'Failed'
                AND CreatedDate = LAST_N_DAYS:7
            ];
            
            if (!failedJobs.isEmpty()) {
                item.addIssue('Found ' + failedJobs.size() + ' failed batch jobs in the last 7 days');
            }
            
            // Check for validation errors (simulated check)
            Integer recentValidationErrors = 0; // Would be populated from actual error logs
            
            if (recentValidationErrors > ERROR_THRESHOLD) {
                item.addIssue('High validation error rate: ' + recentValidationErrors + ' errors (threshold: ' + ERROR_THRESHOLD + ')');
            }
            
            item.status = item.issues.isEmpty() ? 'Healthy' : 'High Error Rate';
            
        } catch (Exception e) {
            item.status = 'Error';
            item.addIssue('Error rate check failed: ' + e.getMessage());
        }
        
        return item;
    }
    
    /**
     * @description Monitors system capacity and resource utilization
     */
    private static HealthCheckItem checkSystemCapacity() {
        HealthCheckItem item = new HealthCheckItem('System Capacity');
        
        try {
            // Check data storage usage
            Integer totalFeedbackRecords = [SELECT COUNT() FROM Interview_Feedback__c];
            Integer totalCompetencyRatings = [SELECT COUNT() FROM Competency_Rating__c];
            Integer totalShares = [SELECT COUNT() FROM Feedback_Share__c];
            
            // Estimate storage usage (rough calculation)
            Integer estimatedStorageMB = (totalFeedbackRecords * 2) + (totalCompetencyRatings * 1) + (totalShares * 1);
            
            if (estimatedStorageMB > 1000) { // 1GB threshold
                item.addIssue('High storage usage: ~' + estimatedStorageMB + 'MB');
            }
            
            // Check API usage (simulated)
            Integer dailyAPICallsUsed = 0; // Would be populated from actual API usage metrics
            Integer dailyAPICallsLimit = 100000;
            
            if (dailyAPICallsUsed > (dailyAPICallsLimit * 0.8)) {
                item.addIssue('High API usage: ' + dailyAPICallsUsed + '/' + dailyAPICallsLimit + ' daily calls');
            }
            
            // Check concurrent user capacity
            Integer activeUsers = [
                SELECT COUNT(DISTINCT CreatedById)
                FROM Interview_Feedback__c
                WHERE CreatedDate = LAST_N_DAYS:1
            ][0].expr0;
            
            if (activeUsers > 500) { // Threshold for concurrent users
                item.addIssue('High concurrent user count: ' + activeUsers + ' active users');
            }
            
            item.status = item.issues.isEmpty() ? 'Healthy' : 'Capacity Issues';
            
        } catch (Exception e) {
            item.status = 'Error';
            item.addIssue('Capacity check failed: ' + e.getMessage());
        }
        
        return item;
    }
    
    /**
     * @description Checks health of external integrations
     */
    private static HealthCheckItem checkIntegrationHealth() {
        HealthCheckItem item = new HealthCheckItem('Integration Health');
        
        try {
            // Check Job Application Tracker integration
            Integer feedbackWithoutJobApps = [
                SELECT COUNT()
                FROM Interview_Feedback__c
                WHERE Job_Application__c = null
                AND CreatedDate = LAST_N_DAYS:7
            ];
            
            if (feedbackWithoutJobApps > 0) {
                item.addIssue('Found ' + feedbackWithoutJobApps + ' feedback records without job applications');
            }
            
            // Check email notification system
            try {
                // Test email system (without actually sending)
                Messaging.SingleEmailMessage testEmail = new Messaging.SingleEmailMessage();
                testEmail.setToAddresses(new List<String>{'test@example.com'});
                testEmail.setSubject('Test');
                testEmail.setPlainTextBody('Test');
                // Don't actually send: Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{testEmail});
                
            } catch (Exception emailEx) {
                item.addIssue('Email system test failed: ' + emailEx.getMessage());
            }
            
            // Check sharing token generation
            try {
                String testToken = FeedbackSharingService.generateShareToken();
                if (String.isBlank(testToken)) {
                    item.addIssue('Share token generation failed');
                }
            } catch (Exception tokenEx) {
                item.addIssue('Share token generation error: ' + tokenEx.getMessage());
            }
            
            item.status = item.issues.isEmpty() ? 'Healthy' : 'Integration Issues';
            
        } catch (Exception e) {
            item.status = 'Error';
            item.addIssue('Integration health check failed: ' + e.getMessage());
        }
        
        return item;
    }
    
    /**
     * @description Sends health alert email to administrators
     */
    private static void sendHealthAlert(HealthCheckResult result) {
        try {
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new List<String>{MONITORING_EMAIL});
            email.setSubject('Interview Feedback Tracker - Health Alert');
            
            String emailBody = 'Health check detected issues in the Interview Feedback Tracker system:\n\n';
            
            for (HealthCheckItem item : result.getAllItems()) {
                if (!item.issues.isEmpty()) {
                    emailBody += item.checkName + ' (' + item.status + '):\n';
                    for (String issue : item.issues) {
                        emailBody += '- ' + issue + '\n';
                    }
                    emailBody += '\n';
                }
            }
            
            emailBody += 'Please investigate and resolve these issues promptly.\n\n';
            emailBody += 'Timestamp: ' + System.now() + '\n';
            emailBody += 'Org: ' + UserInfo.getOrganizationName();
            
            email.setPlainTextBody(emailBody);
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{email});
            
        } catch (Exception e) {
            System.debug('Failed to send health alert: ' + e.getMessage());
        }
    }
    
    /**
     * @description Sends critical system alert
     */
    private static void sendCriticalAlert(String alertType, String message) {
        try {
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new List<String>{MONITORING_EMAIL});
            email.setSubject('CRITICAL: Interview Feedback Tracker - ' + alertType);
            
            String emailBody = 'CRITICAL ALERT: ' + alertType + '\n\n';
            emailBody += 'Message: ' + message + '\n\n';
            emailBody += 'Immediate attention required.\n\n';
            emailBody += 'Timestamp: ' + System.now() + '\n';
            emailBody += 'Org: ' + UserInfo.getOrganizationName();
            
            email.setPlainTextBody(emailBody);
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{email});
            
        } catch (Exception e) {
            System.debug('Failed to send critical alert: ' + e.getMessage());
        }
    }
    
    /**
     * @description Logs health check results for historical tracking
     */
    private static void logHealthCheckResults(HealthCheckResult result) {
        try {
            // In a real implementation, this would write to a custom logging object
            System.debug('=== Interview Feedback Tracker Health Check ===');
            System.debug('Timestamp: ' + System.now());
            System.debug('Overall Status: ' + (result.hasIssues() ? 'Issues Found' : 'Healthy'));
            
            for (HealthCheckItem item : result.getAllItems()) {
                System.debug(item.checkName + ': ' + item.status);
                for (String issue : item.issues) {
                    System.debug('  - ' + issue);
                }
            }
            System.debug('=== End Health Check ===');
            
        } catch (Exception e) {
            System.debug('Failed to log health check results: ' + e.getMessage());
        }
    }
    
    /**
     * @description Wrapper class for health check results
     */
    public class HealthCheckResult {
        public HealthCheckItem dataIntegrityCheck;
        public HealthCheckItem performanceCheck;
        public HealthCheckItem errorRateCheck;
        public HealthCheckItem capacityCheck;
        public HealthCheckItem integrationCheck;
        
        public Boolean hasIssues() {
            return !dataIntegrityCheck.issues.isEmpty() ||
                   !performanceCheck.issues.isEmpty() ||
                   !errorRateCheck.issues.isEmpty() ||
                   !capacityCheck.issues.isEmpty() ||
                   !integrationCheck.issues.isEmpty();
        }
        
        public List<HealthCheckItem> getAllItems() {
            return new List<HealthCheckItem>{
                dataIntegrityCheck,
                performanceCheck,
                errorRateCheck,
                capacityCheck,
                integrationCheck
            };
        }
    }
    
    /**
     * @description Individual health check item
     */
    public class HealthCheckItem {
        public String checkName;
        public String status;
        public List<String> issues;
        
        public HealthCheckItem(String name) {
            this.checkName = name;
            this.status = 'Unknown';
            this.issues = new List<String>();
        }
        
        public void addIssue(String issue) {
            this.issues.add(issue);
        }
    }
}