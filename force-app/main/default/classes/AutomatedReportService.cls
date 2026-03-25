/**
 * @description Service for automated report generation and email delivery
 * Handles scheduled report generation and distribution
 * @author Temitayo Oluwalade
 * @date 2024
 */
public with sharing class AutomatedReportService implements Schedulable {
    
    /**
     * @description Schedulable execute method
     * @param context Scheduled execution context
     */
    public void execute(SchedulableContext context) {
        generateAndSendWeeklyReports();
    }
    
    /**
     * @description Generates and sends weekly performance reports
     */
    public static void generateAndSendWeeklyReports() {
        try {
            // Get all active users who have interview feedback
            List<User> activeUsers = getActiveUsersWithFeedback();
            
            for (User user : activeUsers) {
                generateUserReport(user.Id, 'weekly');
            }
            
            System.debug('Generated weekly reports for ' + activeUsers.size() + ' users');
            
        } catch (Exception e) {
            System.debug('Error generating weekly reports: ' + e.getMessage());
        }
    }
    
    /**
     * @description Generates and sends monthly performance reports
     */
    public static void generateAndSendMonthlyReports() {
        try {
            // Get all active users who have interview feedback
            List<User> activeUsers = getActiveUsersWithFeedback();
            
            for (User user : activeUsers) {
                generateUserReport(user.Id, 'monthly');
            }
            
            System.debug('Generated monthly reports for ' + activeUsers.size() + ' users');
            
        } catch (Exception e) {
            System.debug('Error generating monthly reports: ' + e.getMessage());
        }
    }
    
    /**
     * @description Generates a comprehensive report for a specific user
     * @param userId User ID to generate report for
     * @param reportType Type of report (weekly, monthly, quarterly)
     */
    public static void generateUserReport(Id userId, String reportType) {
        try {
            // Determine date range based on report type
            Date startDate, endDate;
            String reportTitle;
            
            switch on reportType.toLowerCase() {
                when 'weekly' {
                    startDate = Date.today().addDays(-7);
                    endDate = Date.today();
                    reportTitle = 'Weekly Interview Performance Report';
                }
                when 'monthly' {
                    startDate = Date.today().addDays(-30);
                    endDate = Date.today();
                    reportTitle = 'Monthly Interview Performance Report';
                }
                when 'quarterly' {
                    startDate = Date.today().addDays(-90);
                    endDate = Date.today();
                    reportTitle = 'Quarterly Interview Performance Report';
                }
                when else {
                    startDate = Date.today().addDays(-30);
                    endDate = Date.today();
                    reportTitle = 'Interview Performance Report';
                }
            }
            
            // Generate analytics report
            InterviewAnalyticsService.AnalyticsReport analyticsReport = 
                InterviewAnalyticsService.generateComprehensiveReport(startDate, endDate, userId);
            
            // Skip if no data
            if (analyticsReport.basicMetrics.totalInterviews == 0) {
                System.debug('No interview data found for user: ' + userId);
                return;
            }
            
            // Get user details
            User user = [SELECT Id, Email, FirstName, LastName FROM User WHERE Id = :userId LIMIT 1];
            
            // Generate and send email report
            sendEmailReport(user, analyticsReport, reportTitle, reportType);
            
            // Create report record for tracking
            createReportRecord(userId, analyticsReport, reportType);
            
        } catch (Exception e) {
            System.debug('Error generating report for user ' + userId + ': ' + e.getMessage());
        }
    }
    
    /**
     * @description Sends email report to user
     * @param user User to send report to
     * @param report Analytics report data
     * @param title Report title
     * @param reportType Type of report
     */
    private static void sendEmailReport(User user, InterviewAnalyticsService.AnalyticsReport report, 
                                       String title, String reportType) {
        
        if (Test.isRunningTest()) {
            return; // Skip email sending in tests
        }
        
        try {
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new String[] { user.Email });
            email.setSubject(title + ' - ' + Date.today().format());
            email.setHtmlBody(generateEmailBody(user, report, title, reportType));
            email.setSaveAsActivity(false);
            
            // Add CSV attachment
            Messaging.EmailFileAttachment csvAttachment = generateCSVAttachment(report, reportType);
            email.setFileAttachments(new Messaging.EmailFileAttachment[] { csvAttachment });
            
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
            
        } catch (Exception e) {
            System.debug('Error sending email report: ' + e.getMessage());
        }
    }
    
    /**
     * @description Generates HTML email body for report
     * @param user User receiving the report
     * @param report Analytics report data
     * @param title Report title
     * @param reportType Type of report
     * @return HTML email body
     */
    private static String generateEmailBody(User user, InterviewAnalyticsService.AnalyticsReport report, 
                                           String title, String reportType) {
        
        String body = '<html><body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">';
        
        // Header
        body += '<div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px; border-radius: 8px; margin-bottom: 20px;">';
        body += '<h1 style="margin: 0; font-size: 24px;">' + title + '</h1>';
        body += '<p style="margin: 5px 0 0 0; opacity: 0.9;">Hello ' + user.FirstName + ', here\'s your interview performance summary</p>';
        body += '</div>';
        
        // Key Metrics Section
        body += '<div style="background: #f8f9fa; padding: 20px; border-radius: 8px; margin-bottom: 20px;">';
        body += '<h2 style="color: #495057; margin-top: 0;">📊 Key Metrics</h2>';
        body += '<div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px;">';
        
        body += '<div style="background: white; padding: 15px; border-radius: 6px; text-align: center; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">';
        body += '<div style="font-size: 28px; font-weight: bold; color: #28a745;">' + report.basicMetrics.averageRating + '/5.0</div>';
        body += '<div style="color: #6c757d; font-size: 14px;">Average Rating</div>';
        body += '</div>';
        
        body += '<div style="background: white; padding: 15px; border-radius: 6px; text-align: center; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">';
        body += '<div style="font-size: 28px; font-weight: bold; color: #007bff;">' + report.basicMetrics.totalInterviews + '</div>';
        body += '<div style="color: #6c757d; font-size: 14px;">Total Interviews</div>';
        body += '</div>';
        
        body += '<div style="background: white; padding: 15px; border-radius: 6px; text-align: center; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">';
        body += '<div style="font-size: 28px; font-weight: bold; color: #6f42c1;">' + report.basicMetrics.uniqueJobApplications + '</div>';
        body += '<div style="color: #6c757d; font-size: 14px;">Job Applications</div>';
        body += '</div>';
        
        if (report.predictiveAnalytics != null) {
            body += '<div style="background: white; padding: 15px; border-radius: 6px; text-align: center; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">';
            body += '<div style="font-size: 28px; font-weight: bold; color: #fd7e14;">' + report.predictiveAnalytics.overallSuccessProbability + '%</div>';
            body += '<div style="color: #6c757d; font-size: 14px;">Success Rate</div>';
            body += '</div>';
        }
        
        body += '</div></div>';
        
        // Performance by Interview Type
        if (report.basicMetrics.interviewTypeMetrics != null && !report.basicMetrics.interviewTypeMetrics.isEmpty()) {
            body += '<div style="background: white; padding: 20px; border-radius: 8px; margin-bottom: 20px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">';
            body += '<h2 style="color: #495057; margin-top: 0;">🎯 Performance by Interview Type</h2>';
            body += '<table style="width: 100%; border-collapse: collapse;">';
            body += '<thead><tr style="background: #e9ecef;">';
            body += '<th style="padding: 12px; text-align: left; border-bottom: 2px solid #dee2e6;">Interview Type</th>';
            body += '<th style="padding: 12px; text-align: center; border-bottom: 2px solid #dee2e6;">Count</th>';
            body += '<th style="padding: 12px; text-align: center; border-bottom: 2px solid #dee2e6;">Average Rating</th>';
            body += '</tr></thead><tbody>';
            
            for (InterviewAnalyticsService.InterviewTypeMetric metric : report.basicMetrics.interviewTypeMetrics) {
                String ratingColor = metric.averageRating >= 4.0 ? '#28a745' : 
                                   metric.averageRating >= 3.0 ? '#ffc107' : '#dc3545';
                body += '<tr>';
                body += '<td style="padding: 12px; border-bottom: 1px solid #dee2e6;">' + metric.interviewType + '</td>';
                body += '<td style="padding: 12px; text-align: center; border-bottom: 1px solid #dee2e6;">' + metric.count + '</td>';
                body += '<td style="padding: 12px; text-align: center; border-bottom: 1px solid #dee2e6; color: ' + ratingColor + '; font-weight: bold;">' + metric.averageRating + '/5.0</td>';
                body += '</tr>';
            }
            body += '</tbody></table></div>';
        }
        
        // Trend Analysis
        if (report.trendAnalysis != null) {
            body += '<div style="background: white; padding: 20px; border-radius: 8px; margin-bottom: 20px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">';
            body += '<h2 style="color: #495057; margin-top: 0;">📈 Trend Analysis</h2>';
            
            String trendIcon = report.trendAnalysis.trendDirection == 'Improving' ? '📈' : 
                              report.trendAnalysis.trendDirection == 'Declining' ? '📉' : '➡️';
            String trendColor = report.trendAnalysis.trendDirection == 'Improving' ? '#28a745' : 
                               report.trendAnalysis.trendDirection == 'Declining' ? '#dc3545' : '#6c757d';
            
            body += '<div style="display: flex; align-items: center; margin-bottom: 15px;">';
            body += '<span style="font-size: 24px; margin-right: 10px;">' + trendIcon + '</span>';
            body += '<div>';
            body += '<div style="font-size: 18px; font-weight: bold; color: ' + trendColor + ';">' + report.trendAnalysis.trendDirection + '</div>';
            body += '<div style="color: #6c757d; font-size: 14px;">Trend Strength: ' + report.trendAnalysis.trendStrength + '</div>';
            body += '</div></div>';
            body += '</div>';
        }
        
        // Insights
        if (report.insights != null && !report.insights.isEmpty()) {
            body += '<div style="background: #e3f2fd; padding: 20px; border-radius: 8px; margin-bottom: 20px; border-left: 4px solid #2196f3;">';
            body += '<h2 style="color: #1976d2; margin-top: 0;">💡 Key Insights</h2>';
            body += '<ul style="margin: 0; padding-left: 20px;">';
            for (String insight : report.insights) {
                body += '<li style="margin-bottom: 8px; color: #424242;">' + insight + '</li>';
            }
            body += '</ul></div>';
        }
        
        // Benchmark Comparison
        if (report.benchmarkComparison != null && report.benchmarkComparison.comparisons != null) {
            body += '<div style="background: white; padding: 20px; border-radius: 8px; margin-bottom: 20px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">';
            body += '<h2 style="color: #495057; margin-top: 0;">🏆 Industry Benchmark Comparison</h2>';
            
            for (InterviewAnalyticsService.BenchmarkComparison.TypeComparison comp : report.benchmarkComparison.comparisons) {
                String performanceColor = comp.performanceLevel == 'Excellent' ? '#28a745' :
                                        comp.performanceLevel == 'Above Average' ? '#17a2b8' :
                                        comp.performanceLevel == 'Average' ? '#ffc107' : '#dc3545';
                
                body += '<div style="margin-bottom: 15px; padding: 15px; background: #f8f9fa; border-radius: 6px;">';
                body += '<div style="display: flex; justify-content: space-between; align-items: center;">';
                body += '<div>';
                body += '<div style="font-weight: bold; color: #495057;">' + comp.interviewType + '</div>';
                body += '<div style="font-size: 14px; color: #6c757d;">Your: ' + comp.userAverage + ' | Industry: ' + comp.industryBenchmark + '</div>';
                body += '</div>';
                body += '<div style="background: ' + performanceColor + '; color: white; padding: 5px 10px; border-radius: 15px; font-size: 12px; font-weight: bold;">';
                body += comp.performanceLevel;
                body += '</div></div></div>';
            }
            body += '</div>';
        }
        
        // Footer
        body += '<div style="background: #6c757d; color: white; padding: 15px; border-radius: 8px; text-align: center; font-size: 14px;">';
        body += '<p style="margin: 0;">This report was automatically generated on ' + DateTime.now().format() + '</p>';
        body += '<p style="margin: 5px 0 0 0; opacity: 0.8;">Keep up the great work with your interview preparation! 🚀</p>';
        body += '</div>';
        
        body += '</body></html>';
        
        return body;
    }
    
    /**
     * @description Generates CSV attachment for report data
     * @param report Analytics report data
     * @param reportType Type of report
     * @return Email file attachment
     */
    private static Messaging.EmailFileAttachment generateCSVAttachment(InterviewAnalyticsService.AnalyticsReport report, 
                                                                      String reportType) {
        
        List<String> csvLines = new List<String>();
        
        // Header
        csvLines.add('Interview Performance Report - ' + reportType.toUpperCase());
        csvLines.add('Generated on: ' + DateTime.now().format());
        csvLines.add('');
        
        // Basic Metrics
        csvLines.add('BASIC METRICS');
        csvLines.add('Total Interviews,' + report.basicMetrics.totalInterviews);
        csvLines.add('Average Rating,' + report.basicMetrics.averageRating);
        csvLines.add('Unique Job Applications,' + report.basicMetrics.uniqueJobApplications);
        csvLines.add('');
        
        // Interview Type Performance
        if (report.basicMetrics.interviewTypeMetrics != null) {
            csvLines.add('PERFORMANCE BY INTERVIEW TYPE');
            csvLines.add('Interview Type,Count,Average Rating');
            for (InterviewAnalyticsService.InterviewTypeMetric metric : report.basicMetrics.interviewTypeMetrics) {
                csvLines.add(metric.interviewType + ',' + metric.count + ',' + metric.averageRating);
            }
            csvLines.add('');
        }
        
        // Statistical Analysis
        if (report.statisticalAnalysis != null) {
            csvLines.add('STATISTICAL ANALYSIS');
            csvLines.add('Mean,' + report.statisticalAnalysis.mean);
            csvLines.add('Median,' + report.statisticalAnalysis.median);
            csvLines.add('Standard Deviation,' + report.statisticalAnalysis.standardDeviation);
            csvLines.add('95% Confidence Interval,' + report.statisticalAnalysis.confidenceInterval95Lower + 
                        ' - ' + report.statisticalAnalysis.confidenceInterval95Upper);
            csvLines.add('');
        }
        
        // Trend Analysis
        if (report.trendAnalysis != null) {
            csvLines.add('TREND ANALYSIS');
            csvLines.add('Trend Direction,' + report.trendAnalysis.trendDirection);
            csvLines.add('Trend Strength,' + report.trendAnalysis.trendStrength);
            csvLines.add('R-Squared,' + report.trendAnalysis.rSquared);
            csvLines.add('');
        }
        
        String csvContent = String.join(csvLines, '\n');
        
        Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
        attachment.setFileName('interview_performance_' + reportType + '_' + Date.today().format() + '.csv');
        attachment.setBody(Blob.valueOf(csvContent));
        attachment.setContentType('text/csv');
        
        return attachment;
    }
    
    /**
     * @description Creates a report record for tracking
     * @param userId User ID the report was generated for
     * @param report Analytics report data
     * @param reportType Type of report
     */
    private static void createReportRecord(Id userId, InterviewAnalyticsService.AnalyticsReport report, String reportType) {
        // This would create a custom object record to track generated reports
        // For now, we'll just log it
        System.debug('Report generated for user ' + userId + ': ' + reportType + 
                    ' - ' + report.basicMetrics.totalInterviews + ' interviews analyzed');
    }
    
    /**
     * @description Gets active users who have interview feedback
     * @return List of users with recent feedback activity
     */
    private static List<User> getActiveUsersWithFeedback() {
        // Get users who have created feedback in the last 30 days
        Set<Id> userIds = new Set<Id>();
        
        for (Interview_Feedback__c feedback : [
            SELECT CreatedById 
            FROM Interview_Feedback__c 
            WHERE CreatedDate >= :DateTime.now().addDays(-30)
        ]) {
            userIds.add(feedback.CreatedById);
        }
        
        return [
            SELECT Id, Email, FirstName, LastName 
            FROM User 
            WHERE Id IN :userIds AND IsActive = true
            ORDER BY LastName, FirstName
        ];
    }
    
    /**
     * @description Schedules weekly report generation
     * @return Scheduled job ID
     */
    public static String scheduleWeeklyReports() {
        String cronExpression = '0 0 8 ? * MON'; // Every Monday at 8 AM
        return System.schedule('Weekly Interview Reports', cronExpression, new AutomatedReportService());
    }
    
    /**
     * @description Schedules monthly report generation
     * @return Scheduled job ID
     */
    public static String scheduleMonthlyReports() {
        String cronExpression = '0 0 8 1 * ?'; // First day of every month at 8 AM
        return System.schedule('Monthly Interview Reports', cronExpression, new MonthlyReportScheduler());
    }
    
    /**
     * @description Inner class for monthly report scheduling
     */
    public class MonthlyReportScheduler implements Schedulable {
        public void execute(SchedulableContext context) {
            generateAndSendMonthlyReports();
        }
    }
}