// Test script for Performance Dashboard functionality
// This script tests the dashboard data generation and chart rendering

// Create test data for dashboard
System.debug('=== Testing Performance Dashboard ===');

// Create test job application
Job_Application__c testApp = new Job_Application__c(
    Position_Title__c = 'Senior Software Engineer',
    Company_Name__c = 'Tech Corp',
    Application_Status__c = 'Interview',
    Salary_Offered__c = 120000
);
insert testApp;

// Create test feedback template
Feedback_Template__c template = new Feedback_Template__c(
    Name = 'Technical Interview Template',
    Interview_Type__c = 'Technical',
    Competency_Areas__c = 'Technical Skills;Problem Solving;Communication'
);
insert template;

// Create multiple interview feedback records with different ratings and dates
List<Interview_Feedback__c> feedbackList = new List<Interview_Feedback__c>();

// Create feedback for different months to test trend analysis
Date baseDate = Date.today().addDays(-90);

for (Integer i = 0; i < 15; i++) {
    Interview_Feedback__c feedback = new Interview_Feedback__c(
        Job_Application__c = testApp.Id,
        Interview_Type__c = (Math.mod(i, 3) == 0) ? 'Technical' : 
                           (Math.mod(i, 3) == 1) ? 'Behavioral' : 'System Design',
        Overall_Rating__c = 3 + Math.mod(i, 3), // Ratings between 3-5
        Interview_Date__c = baseDate.addDays(i * 6), // Spread over 90 days
        Feedback_Template__c = template.Id,
        Strengths__c = 'Strong technical skills, good communication',
        Areas_for_Improvement__c = 'Could improve system design thinking',
        Additional_Comments__c = 'Overall positive interview experience'
    );
    feedbackList.add(feedback);
}

insert feedbackList;

// Create competency ratings for detailed analysis
List<Competency_Rating__c> competencyRatings = new List<Competency_Rating__c>();

for (Interview_Feedback__c feedback : feedbackList) {
    // Technical Skills rating
    competencyRatings.add(new Competency_Rating__c(
        Interview_Feedback__c = feedback.Id,
        Competency_Name__c = 'Technical Skills',
        Rating__c = 3 + Math.mod(Integer.valueOf(feedback.Overall_Rating__c), 3)
    ));
    
    // Problem Solving rating
    competencyRatings.add(new Competency_Rating__c(
        Interview_Feedback__c = feedback.Id,
        Competency_Name__c = 'Problem Solving',
        Rating__c = 3 + Math.mod(Integer.valueOf(feedback.Overall_Rating__c) + 1, 3)
    ));
    
    // Communication rating
    competencyRatings.add(new Competency_Rating__c(
        Interview_Feedback__c = feedback.Id,
        Competency_Name__c = 'Communication',
        Rating__c = 3 + Math.mod(Integer.valueOf(feedback.Overall_Rating__c) + 2, 3)
    ));
}

insert competencyRatings;

System.debug('Created ' + feedbackList.size() + ' feedback records');
System.debug('Created ' + competencyRatings.size() + ' competency ratings');

// Test dashboard data generation
try {
    System.debug('\\n=== Testing Dashboard Data Generation ===');
    
    // Test with different date ranges
    String[] dateRanges = new String[]{'30', '90', '180', 'all'};
    
    for (String dateRange : dateRanges) {
        System.debug('\\nTesting date range: ' + dateRange + ' days');
        
        FeedbackAnalyticsService.DashboardData dashboardData = 
            FeedbackAnalyticsService.generateDashboardData(dateRange, '', testApp.Id);
        
        System.debug('Average Overall Rating: ' + dashboardData.averageOverallRating);
        System.debug('Total Feedback Records: ' + dashboardData.totalFeedbackRecords);
        System.debug('Success Rate: ' + dashboardData.successRate + '%');
        System.debug('Applications with Feedback: ' + dashboardData.totalApplicationsWithFeedback);
        
        // Test performance trend
        if (dashboardData.performanceTrend != null) {
            System.debug('Performance Trend Change: ' + dashboardData.performanceTrend.percentageChange + '%');
            System.debug('Monthly Data Points: ' + dashboardData.performanceTrend.monthlyData.size());
        }
        
        // Test competency breakdown
        if (dashboardData.competencyBreakdown != null) {
            System.debug('Competency Areas: ' + dashboardData.competencyBreakdown.size());
            for (FeedbackAnalyticsService.CompetencyData comp : dashboardData.competencyBreakdown) {
                System.debug('  ' + comp.competency + ': ' + comp.averageRating);
            }
        }
        
        // Test interview type distribution
        if (dashboardData.interviewTypeDistribution != null) {
            System.debug('Interview Types: ' + dashboardData.interviewTypeDistribution.size());
            for (FeedbackAnalyticsService.InterviewTypeData type : dashboardData.interviewTypeDistribution) {
                System.debug('  ' + type.type + ': ' + type.count + ' interviews');
            }
        }
        
        // Test rating distribution
        if (dashboardData.ratingDistribution != null) {
            System.debug('Rating Distribution: ' + dashboardData.ratingDistribution.size());
            for (FeedbackAnalyticsService.RatingData rating : dashboardData.ratingDistribution) {
                System.debug('  ' + rating.rating + ' stars: ' + rating.count + ' interviews');
            }
        }
        
        // Test recent feedback
        if (dashboardData.recentFeedback != null) {
            System.debug('Recent Feedback: ' + dashboardData.recentFeedback.size() + ' records');
        }
    }
    
    // Test with interview type filter
    System.debug('\\n=== Testing Interview Type Filtering ===');
    
    String[] interviewTypes = new String[]{'Technical', 'Behavioral', 'System Design'};
    
    for (String interviewType : interviewTypes) {
        System.debug('\\nTesting interview type: ' + interviewType);
        
        FeedbackAnalyticsService.DashboardData filteredData = 
            FeedbackAnalyticsService.generateDashboardData('90', interviewType, testApp.Id);
        
        System.debug('Filtered Records: ' + filteredData.totalFeedbackRecords);
        System.debug('Average Rating: ' + filteredData.averageOverallRating);
    }
    
} catch (Exception e) {
    System.debug('Error testing dashboard data: ' + e.getMessage());
    System.debug('Stack trace: ' + e.getStackTraceString());
}

// Test recommendations generation
try {
    System.debug('\\n=== Testing Recommendations Generation ===');
    
    List<FeedbackAnalyticsService.RecommendationData> recommendations = 
        FeedbackAnalyticsService.generateRecommendations('90', '', testApp.Id);
    
    System.debug('Generated ' + recommendations.size() + ' recommendations:');
    for (FeedbackAnalyticsService.RecommendationData rec : recommendations) {
        System.debug('  - ' + rec.message);
        if (String.isNotBlank(rec.actionLabel)) {
            System.debug('    Action: ' + rec.actionLabel);
        }
    }
    
} catch (Exception e) {
    System.debug('Error testing recommendations: ' + e.getMessage());
    System.debug('Stack trace: ' + e.getStackTraceString());
}

// Test performance trends calculation
try {
    System.debug('\\n=== Testing Performance Trends ===');
    
    FeedbackAnalyticsService.PerformanceTrendData trendData = 
        FeedbackAnalyticsService.calculatePerformanceTrends('180', '', testApp.Id);
    
    if (trendData != null) {
        System.debug('Trend Percentage Change: ' + trendData.percentageChange + '%');
        System.debug('Monthly Data Points: ' + trendData.monthlyData.size());
        
        for (FeedbackAnalyticsService.MonthlyPerformanceData monthly : trendData.monthlyData) {
            System.debug('  ' + monthly.month + ': ' + monthly.averageRating + ' avg rating, ' + 
                        monthly.feedbackCount + ' interviews');
        }
    }
    
} catch (Exception e) {
    System.debug('Error testing performance trends: ' + e.getMessage());
    System.debug('Stack trace: ' + e.getStackTraceString());
}

// Test dashboard with no data
try {
    System.debug('\\n=== Testing Dashboard with No Data ===');
    
    // Create a job application with no feedback
    Job_Application__c emptyApp = new Job_Application__c(
        Position_Title__c = 'Empty Position',
        Company_Name__c = 'Empty Corp',
        Application_Status__c = 'Applied'
    );
    insert emptyApp;
    
    FeedbackAnalyticsService.DashboardData emptyData = 
        FeedbackAnalyticsService.generateDashboardData('90', '', emptyApp.Id);
    
    System.debug('Empty Dashboard - Total Records: ' + emptyData.totalFeedbackRecords);
    System.debug('Empty Dashboard - Average Rating: ' + emptyData.averageOverallRating);
    System.debug('Empty Dashboard - Success Rate: ' + emptyData.successRate);
    
} catch (Exception e) {
    System.debug('Error testing empty dashboard: ' + e.getMessage());
}

// Test error handling
try {
    System.debug('\\n=== Testing Error Handling ===');
    
    // Test with invalid job application ID
    FeedbackAnalyticsService.DashboardData errorData = 
        FeedbackAnalyticsService.generateDashboardData('90', '', 'invalid_id');
    
    System.debug('Error handling test completed');
    
} catch (Exception e) {
    System.debug('Expected error caught: ' + e.getMessage());
}

// Performance testing
try {
    System.debug('\\n=== Performance Testing ===');
    
    Long startTime = System.currentTimeMillis();
    
    // Generate dashboard data multiple times
    for (Integer i = 0; i < 5; i++) {
        FeedbackAnalyticsService.generateDashboardData('90', '', testApp.Id);
    }
    
    Long endTime = System.currentTimeMillis();
    Long executionTime = endTime - startTime;
    
    System.debug('Dashboard generation (5x): ' + executionTime + 'ms');
    System.debug('Average per call: ' + (executionTime / 5) + 'ms');
    
} catch (Exception e) {
    System.debug('Performance test error: ' + e.getMessage());
}

System.debug('\\n=== Performance Dashboard Testing Complete ===');

// Query final state for verification
List<Interview_Feedback__c> finalFeedback = [
    SELECT Id, Interview_Type__c, Overall_Rating__c, Interview_Date__c,
           Job_Application__r.Position_Title__c
    FROM Interview_Feedback__c 
    WHERE Job_Application__c = :testApp.Id
    ORDER BY Interview_Date__c DESC
];

System.debug('\\nFinal verification - Total feedback records: ' + finalFeedback.size());

// Display summary statistics
Map<String, Integer> typeCount = new Map<String, Integer>();
Decimal totalRating = 0;

for (Interview_Feedback__c feedback : finalFeedback) {
    String type = feedback.Interview_Type__c;
    typeCount.put(type, typeCount.containsKey(type) ? typeCount.get(type) + 1 : 1);
    totalRating += feedback.Overall_Rating__c;
}

System.debug('Interview type distribution:');
for (String type : typeCount.keySet()) {
    System.debug('  ' + type + ': ' + typeCount.get(type));
}

if (finalFeedback.size() > 0) {
    Decimal avgRating = totalRating / finalFeedback.size();
    System.debug('Overall average rating: ' + avgRating.setScale(2));
}

System.debug('\\n=== Test Data Created Successfully ===');
System.debug('Job Application ID: ' + testApp.Id);
System.debug('Use this ID to test the Performance Dashboard component');
System.debug('Navigate to the Job Application record and add the Performance Dashboard component');