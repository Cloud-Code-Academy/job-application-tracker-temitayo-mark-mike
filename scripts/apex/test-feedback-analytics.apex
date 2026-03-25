// Test script for FeedbackAnalyticsService
System.debug('Starting FeedbackAnalyticsService test...');

try {
    // Create test Job Application
    Job_Application__c jobApp = new Job_Application__c(
        Position_Title__c = 'Senior Software Engineer',
        Company_Name__c = 'Analytics Test Company',
        Status__c = 'Applied',
        Salary__c = 120000,
        Application_Date__c = Date.today().addDays(-30),
        Description__c = 'Test job for analytics service',
        Location__c = 'San Francisco, CA'
    );
    insert jobApp;
    System.debug('Created Job Application: ' + jobApp.Id);
    
    // Create multiple feedback records with improving trend
    List<Interview_Feedback__c> feedbackList = new List<Interview_Feedback__c>();
    
    for (Integer i = 0; i < 4; i++) {
        Interview_Feedback__c feedback = new Interview_Feedback__c(
            Job_Application__c = jobApp.Id,
            Interview_Round__c = 'Round ' + (i + 1),
            Interview_Type__c = 'Technical',
            Interviewer_Name__c = 'Test Interviewer ' + (i + 1),
            Interview_Date__c = Date.today().addDays(-(10 - i * 2)),
            Technical_Rating__c = i + 2, // 2, 3, 4, 5 - improving trend
            Communication_Rating__c = i + 2.5, // 2.5, 3.5, 4.5, 5.5 (capped at 5)
            Cultural_Fit_Rating__c = i + 1.5, // 1.5, 2.5, 3.5, 4.5
            Detailed_Feedback__c = 'Test feedback for round ' + (i + 1),
            Feedback_Status__c = 'Submitted',
            Strengths__c = 'Problem solving, analytical thinking',
            Areas_for_Improvement__c = 'System design, leadership skills'
        );
        
        // Cap ratings at 5
        if (feedback.Communication_Rating__c > 5) {
            feedback.Communication_Rating__c = 5;
        }
        
        feedbackList.add(feedback);
    }
    
    // Use InterviewFeedbackService to create feedback (this will calculate overall ratings)
    List<Interview_Feedback__c> createdFeedback = InterviewFeedbackService.createFeedback(feedbackList);
    System.debug('Created ' + createdFeedback.size() + ' feedback records');
    
    // Test performance trend analysis
    FeedbackAnalyticsService.PerformanceTrend trend = 
        FeedbackAnalyticsService.calculatePerformanceTrends(jobApp.Id, 30);
    
    System.debug('=== PERFORMANCE TREND ANALYSIS ===');
    System.debug('Trend Direction: ' + trend.trendDirection);
    System.debug('Trend Strength: ' + trend.trendStrength);
    System.debug('Data Points: ' + trend.dataPoints);
    System.debug('Average Rating: ' + trend.averageRating);
    System.debug('Latest Rating: ' + trend.latestRating);
    System.debug('Earliest Rating: ' + trend.earliestRating);
    
    // Test competency analysis
    FeedbackAnalyticsService.CompetencyAnalysis analysis = 
        FeedbackAnalyticsService.analyzeCompetencies(jobApp.Id);
    
    System.debug('=== COMPETENCY ANALYSIS ===');
    System.debug('Average Technical Rating: ' + analysis.averageTechnicalRating);
    System.debug('Average Communication Rating: ' + analysis.averageCommunicationRating);
    System.debug('Average Cultural Fit Rating: ' + analysis.averageCulturalFitRating);
    System.debug('Common Strengths: ' + analysis.commonStrengths);
    System.debug('Common Improvement Areas: ' + analysis.commonImprovementAreas);
    
    // Test recommendations generation
    List<String> recommendations = FeedbackAnalyticsService.generateRecommendations(jobApp.Id);
    
    System.debug('=== RECOMMENDATIONS ===');
    for (String recommendation : recommendations) {
        System.debug('- ' + recommendation);
    }
    
    // Test dashboard data generation
    FeedbackAnalyticsService.DashboardData dashboardData = 
        FeedbackAnalyticsService.generateDashboardData(UserInfo.getUserId());
    
    System.debug('=== DASHBOARD DATA ===');
    System.debug('Total Applications with Feedback: ' + dashboardData.totalApplicationsWithFeedback);
    System.debug('Total Feedback Records: ' + dashboardData.totalFeedbackRecords);
    System.debug('Average Overall Rating: ' + dashboardData.averageOverallRating);
    System.debug('Success Rate: ' + dashboardData.successRate + '%');
    System.debug('Competency Breakdown: ' + dashboardData.competencyBreakdown);
    System.debug('Recent Feedback Count: ' + dashboardData.recentFeedback.size());
    System.debug('Trend Data Points: ' + dashboardData.performanceTrendData.size());
    
    System.debug('FeedbackAnalyticsService test completed successfully!');
    
} catch (Exception e) {
    System.debug(LoggingLevel.ERROR, 'Test failed: ' + e.getMessage());
    System.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());
}