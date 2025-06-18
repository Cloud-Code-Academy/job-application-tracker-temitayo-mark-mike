/**
 * @description Service class for providing job application analytics data
 * @author Temitayo Oluwalade
 * @date 2024
 */
public with sharing class ApplicationAnalyticsService {
    
    /**
     * @description Gets comprehensive analytics data for job applications
     * @return Map containing all analytics data
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getApplicationAnalytics() {
        try {
            Map<String, Object> analytics = new Map<String, Object>();
            
            // Get all job applications for the current user
            List<Job_Application__c> applications = [
                SELECT Id, Name, Company_Name__c, Position_Title__c, Status__c, 
                       Application_Date__c, Salary__c, LastModifiedDate, CreatedDate
                FROM Job_Application__c
                WHERE OwnerId = :UserInfo.getUserId()
                ORDER BY LastModifiedDate DESC
            ];
            
            // Calculate basic metrics
            analytics.put('totalApplications', applications.size());
            analytics.put('activeApplications', getActiveApplicationsCount(applications));
            analytics.put('interviewRate', calculateInterviewRate(applications));
            analytics.put('successRate', calculateSuccessRate(applications));
            
            // Status breakdown
            analytics.put('statusBreakdown', getStatusBreakdown(applications));
            
            // Recent activity
            analytics.put('recentActivity', getRecentActivity(applications));
            
            // Pipeline data
            analytics.put('pipeline', getPipelineData(applications));
            
            // Salary analytics
            Map<String, Object> salaryData = getSalaryAnalytics(applications);
            analytics.putAll(salaryData);
            
            return analytics;
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in getApplicationAnalytics: ' + e.getMessage());
            throw new AuraHandledException('Failed to load analytics data: ' + e.getMessage());
        }
    }
    
    /**
     * @description Counts active applications (not closed)
     * @param applications List of job applications
     * @return Number of active applications
     */
    private static Integer getActiveApplicationsCount(List<Job_Application__c> applications) {
        Integer count = 0;
        for (Job_Application__c app : applications) {
            if (app.Status__c != 'Closed') {
                count++;
            }
        }
        return count;
    }
    
    /**
     * @description Calculates interview rate percentage
     * @param applications List of job applications
     * @return Interview rate as percentage
     */
    private static Decimal calculateInterviewRate(List<Job_Application__c> applications) {
        if (applications.isEmpty()) {
            return 0;
        }
        
        Integer interviewingCount = 0;
        for (Job_Application__c app : applications) {
            if (app.Status__c == 'Interviewing' || app.Status__c == 'Negotiating' || 
                app.Status__c == 'Accepted') {
                interviewingCount++;
            }
        }
        
        return (Decimal.valueOf(interviewingCount) / applications.size()) * 100;
    }
    
    /**
     * @description Calculates success rate percentage
     * @param applications List of job applications
     * @return Success rate as percentage
     */
    private static Decimal calculateSuccessRate(List<Job_Application__c> applications) {
        if (applications.isEmpty()) {
            return 0;
        }
        
        Integer successCount = 0;
        for (Job_Application__c app : applications) {
            if (app.Status__c == 'Accepted') {
                successCount++;
            }
        }
        
        return (Decimal.valueOf(successCount) / applications.size()) * 100;
    }
    
    /**
     * @description Gets status breakdown data
     * @param applications List of job applications
     * @return List of status breakdown objects
     */
    private static List<Map<String, Object>> getStatusBreakdown(List<Job_Application__c> applications) {
        Map<String, Integer> statusCounts = new Map<String, Integer>();
        
        // Count applications by status
        for (Job_Application__c app : applications) {
            String status = app.Status__c;
            statusCounts.put(status, statusCounts.containsKey(status) ? statusCounts.get(status) + 1 : 1);
        }
        
        // Convert to list format
        List<Map<String, Object>> breakdown = new List<Map<String, Object>>();
        for (String status : statusCounts.keySet()) {
            breakdown.add(new Map<String, Object>{
                'label' => status,
                'count' => statusCounts.get(status)
            });
        }
        
        return breakdown;
    }
    
    /**
     * @description Gets recent activity data
     * @param applications List of job applications
     * @return List of recent activity objects
     */
    private static List<Map<String, Object>> getRecentActivity(List<Job_Application__c> applications) {
        List<Map<String, Object>> activities = new List<Map<String, Object>>();
        
        // Get the 5 most recently modified applications
        Integer count = 0;
        for (Job_Application__c app : applications) {
            if (count >= 5) break;
            
            activities.add(new Map<String, Object>{
                'id' => app.Id,
                'title' => app.Company_Name__c,
                'subtitle' => app.Position_Title__c,
                'status' => app.Status__c,
                'lastModified' => app.LastModifiedDate
            });
            
            count++;
        }
        
        return activities;
    }
    
    /**
     * @description Gets pipeline data organized by status
     * @param applications List of job applications
     * @return List of pipeline stage objects
     */
    private static List<Map<String, Object>> getPipelineData(List<Job_Application__c> applications) {
        Map<String, List<Job_Application__c>> appsByStatus = new Map<String, List<Job_Application__c>>();
        
        // Group applications by status
        for (Job_Application__c app : applications) {
            String status = app.Status__c;
            if (!appsByStatus.containsKey(status)) {
                appsByStatus.put(status, new List<Job_Application__c>());
            }
            appsByStatus.get(status).add(app);
        }
        
        // Define status order for pipeline
        List<String> statusOrder = new List<String>{'Applied', 'Interviewing', 'Negotiating', 'Accepted', 'Closed'};
        
        List<Map<String, Object>> pipeline = new List<Map<String, Object>>();
        
        for (String status : statusOrder) {
            List<Job_Application__c> statusApps = appsByStatus.get(status);
            if (statusApps == null) {
                statusApps = new List<Job_Application__c>();
            }
            
            List<Map<String, Object>> appData = new List<Map<String, Object>>();
            for (Job_Application__c app : statusApps) {
                appData.add(new Map<String, Object>{
                    'id' => app.Id,
                    'company' => app.Company_Name__c,
                    'position' => app.Position_Title__c,
                    'applicationDate' => app.Application_Date__c,
                    'salary' => app.Salary__c
                });
            }
            
            pipeline.add(new Map<String, Object>{
                'name' => status,
                'count' => statusApps.size(),
                'applications' => appData
            });
        }
        
        return pipeline;
    }
    
    /**
     * @description Gets salary analytics data
     * @param applications List of job applications
     * @return Map containing salary analytics
     */
    private static Map<String, Object> getSalaryAnalytics(List<Job_Application__c> applications) {
        List<Decimal> salaries = new List<Decimal>();
        
        // Collect all non-null salaries
        for (Job_Application__c app : applications) {
            if (app.Salary__c != null && app.Salary__c > 0) {
                salaries.add(app.Salary__c);
            }
        }
        
        Map<String, Object> salaryData = new Map<String, Object>();
        
        if (salaries.isEmpty()) {
            salaryData.put('averageSalary', 0);
            salaryData.put('highestSalary', 0);
            salaryData.put('minSalary', 0);
            salaryData.put('maxSalary', 0);
        } else {
            // Calculate average
            Decimal total = 0;
            Decimal min = salaries[0];
            Decimal max = salaries[0];
            
            for (Decimal salary : salaries) {
                total += salary;
                if (salary < min) min = salary;
                if (salary > max) max = salary;
            }
            
            salaryData.put('averageSalary', total / salaries.size());
            salaryData.put('highestSalary', max);
            salaryData.put('minSalary', min);
            salaryData.put('maxSalary', max);
        }
        
        return salaryData;
    }
    
    /**
     * @description Gets application trends over time
     * @param timeframe Number of months to analyze
     * @return List of trend data points
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getApplicationTrends(Integer timeframe) {
        try {
            if (timeframe == null || timeframe <= 0) {
                timeframe = 6; // Default to 6 months
            }
            
            Date startDate = Date.today().addMonths(-timeframe);
            
            List<Job_Application__c> applications = [
                SELECT Id, Application_Date__c, Status__c, CreatedDate
                FROM Job_Application__c
                WHERE OwnerId = :UserInfo.getUserId()
                AND (Application_Date__c >= :startDate OR CreatedDate >= :startDate)
                ORDER BY Application_Date__c ASC
            ];
            
            // Group by month
            Map<String, Integer> monthlyData = new Map<String, Integer>();
            
            for (Job_Application__c app : applications) {
                Date appDate = app.Application_Date__c != null ? app.Application_Date__c : app.CreatedDate.date();
                String monthKey = appDate.year() + '-' + String.valueOf(appDate.month()).leftPad(2, '0');
                
                monthlyData.put(monthKey, monthlyData.containsKey(monthKey) ? monthlyData.get(monthKey) + 1 : 1);
            }
            
            // Convert to list format
            List<Map<String, Object>> trends = new List<Map<String, Object>>();
            for (String monthKey : monthlyData.keySet()) {
                trends.add(new Map<String, Object>{
                    'month' => monthKey,
                    'count' => monthlyData.get(monthKey)
                });
            }
            
            return trends;
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in getApplicationTrends: ' + e.getMessage());
            throw new AuraHandledException('Failed to load trend data: ' + e.getMessage());
        }
    }
    
    /**
     * @description Gets performance metrics for a specific time period
     * @param startDate Start date for analysis
     * @param endDate End date for analysis
     * @return Map containing performance metrics
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getPerformanceMetrics(Date startDate, Date endDate) {
        try {
            if (startDate == null) {
                startDate = Date.today().addMonths(-3);
            }
            if (endDate == null) {
                endDate = Date.today();
            }
            
            List<Job_Application__c> applications = [
                SELECT Id, Status__c, Application_Date__c, Salary__c
                FROM Job_Application__c
                WHERE OwnerId = :UserInfo.getUserId()
                AND Application_Date__c >= :startDate
                AND Application_Date__c <= :endDate
            ];
            
            Map<String, Object> metrics = new Map<String, Object>();
            
            metrics.put('totalApplications', applications.size());
            metrics.put('interviewRate', calculateInterviewRate(applications));
            metrics.put('successRate', calculateSuccessRate(applications));
            metrics.put('averageResponseTime', calculateAverageResponseTime(applications));
            
            return metrics;
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in getPerformanceMetrics: ' + e.getMessage());
            throw new AuraHandledException('Failed to load performance metrics: ' + e.getMessage());
        }
    }
    
    /**
     * @description Calculates average response time (placeholder implementation)
     * @param applications List of job applications
     * @return Average response time in days
     */
    private static Decimal calculateAverageResponseTime(List<Job_Application__c> applications) {
        // This is a simplified implementation
        // In a real scenario, you'd track when responses were received
        return 7.5; // Placeholder: 7.5 days average
    }
}
