/**
 * @description Comprehensive test class for FeedbackAnalyticsService
 * @author System Generated
 * @date 2025
 */
@IsTest
private class FeedbackAnalyticsServiceTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test Job Application
        Job_Application__c jobApp = InterviewFeedbackTestDataFactory.createJobApplication();
        insert jobApp;
        
        // Create test Feedback Template
        Feedback_Template__c template = InterviewFeedbackTestDataFactory.createFeedbackTemplate();
        insert template;
        
        // Create multiple feedback records with varying ratings to test trends
        List<Interview_Feedback__c> feedbackList = new List<Interview_Feedback__c>();
        
        // Create feedback with improving trend (ratings: 2, 3, 4, 5)
        for (Integer i = 0; i < 4; i++) {
            Interview_Feedback__c feedback = InterviewFeedbackTestDataFactory.createInterviewFeedback(jobApp.Id);
            feedback.Overall_Rating__c = i + 2; // 2, 3, 4, 5
            feedback.Technical_Rating__c = i + 2;
            feedback.Communication_Rating__c = i + 1.5; // 1.5, 2.5, 3.5, 4.5
            feedback.Cultural_Fit_Rating__c = i + 2.5; // 2.5, 3.5, 4.5, 5.5 (capped at 5)
            if (feedback.Cultural_Fit_Rating__c > 5) {
                feedback.Cultural_Fit_Rating__c = 5;
            }
            feedback.Interview_Round__c = 'Round ' + (i + 1);
            feedback.Interview_Type__c = i == 0 ? 'Technical' : (i == 1 ? 'Behavioral' : 'System Design');
            feedback.Feedback_Status__c = 'Submitted';
            feedback.Strengths__c = 'Problem solving, analytical thinking, communication skills';
            feedback.Areas_for_Improvement__c = 'System design, leadership, presentation skills';
            feedback.Interview_Date__c = Date.today().addDays(-(10 - i * 2)); // Spread over time
            feedbackList.add(feedback);
        }
        
        insert feedbackList;
        
        // Create competency ratings for detailed analysis
        List<Competency_Rating__c> competencyRatings = new List<Competency_Rating__c>();
        for (Interview_Feedback__c feedback : feedbackList) {
            // Add competency ratings
            Competency_Rating__c rating1 = InterviewFeedbackTestDataFactory.createCompetencyRating(feedback.Id);
            rating1.Competency_Name__c = 'Problem Solving';
            rating1.Rating__c = feedback.Technical_Rating__c;
            competencyRatings.add(rating1);
            
            Competency_Rating__c rating2 = InterviewFeedbackTestDataFactory.createCompetencyRating(feedback.Id);
            rating2.Competency_Name__c = 'Communication';
            rating2.Rating__c = feedback.Communication_Rating__c;
            competencyRatings.add(rating2);
        }
        
        insert competencyRatings;
    }
    
    @IsTest
    static void testCalculatePerformanceTrends_ImprovingTrend() {
        // Given
        Job_Application__c jobApp = [SELECT Id FROM Job_Application__c LIMIT 1];
        
        // When
        Test.startTest();
        FeedbackAnalyticsService.PerformanceTrend trend = 
            FeedbackAnalyticsService.calculatePerformanceTrends(jobApp.Id, 30);
        Test.stopTest();
        
        // Then
        System.assertNotEquals(null, trend, 'Trend should not be null');
        System.assertEquals('Improving', trend.trendDirection, 'Should detect improving trend');
        System.assertEquals(4, trend.dataPoints, 'Should have 4 data points');
        System.assertNotEquals(null, trend.averageRating, 'Should calculate average rating');
        System.assertEquals(5, trend.latestRating, 'Latest rating should be 5');
        System.assertEquals(2, trend.earliestRating, 'Earliest rating should be 2');
        System.assert(trend.trendStrength > 0, 'Trend strength should be positive');
    }
    
    @IsTest
    static void testCalculatePerformanceTrends_InsufficientData() {
        // Given - Create job app with no feedback
        Job_Application__c jobApp = InterviewFeedbackTestDataFactory.createJobApplication();
        jobApp.Position_Title__c = 'Test Position No Feedback';
        insert jobApp;
        
        // When
        Test.startTest();
        FeedbackAnalyticsService.PerformanceTrend trend = 
            FeedbackAnalyticsService.calculatePerformanceTrends(jobApp.Id, 30);
        Test.stopTest();
        
        // Then
        System.assertEquals('Insufficient Data', trend.trendDirection, 'Should indicate insufficient data');
        System.assertEquals(0, trend.dataPoints, 'Should have 0 data points');
    }
    
    @IsTest
    static void testCalculatePerformanceTrends_NullJobApplicationId() {
        // When/Then
        try {
            FeedbackAnalyticsService.calculatePerformanceTrends(null, 30);
            System.assert(false, 'Should throw exception for null Job Application ID');
        } catch (FeedbackAnalyticsService.AnalyticsException e) {
            System.assertEquals('Job Application ID cannot be null', e.getMessage());
        }
    }
    
    @IsTest
    static void testAnalyzeCompetencies_Success() {
        // Given
        Job_Application__c jobApp = [SELECT Id FROM Job_Application__c LIMIT 1];
        
        // When
        Test.startTest();
        FeedbackAnalyticsService.CompetencyAnalysis analysis = 
            FeedbackAnalyticsService.analyzeCompetencies(jobApp.Id);
        Test.stopTest();
        
        // Then
        System.assertNotEquals(null, analysis, 'Analysis should not be null');
        System.assertNotEquals(null, analysis.averageTechnicalRating, 'Should calculate technical average');
        System.assertNotEquals(null, analysis.averageCommunicationRating, 'Should calculate communication average');
        System.assertNotEquals(null, analysis.averageCulturalFitRating, 'Should calculate cultural fit average');
        
        // Check that averages are reasonable (should be around 3.5 for our test data)
        System.assert(analysis.averageTechnicalRating >= 2 && analysis.averageTechnicalRating <= 5, 
                     'Technical average should be in valid range');
        System.assert(analysis.averageCommunicationRating >= 1 && analysis.averageCommunicationRating <= 5, 
                     'Communication average should be in valid range');
        
        // Should have competency analysis
        System.assertNotEquals(null, analysis.strongestCompetencies, 'Should have strongest competencies list');
        System.assertNotEquals(null, analysis.weakestCompetencies, 'Should have weakest competencies list');
        System.assertNotEquals(null, analysis.commonStrengths, 'Should have common strengths list');
        System.assertNotEquals(null, analysis.commonImprovementAreas, 'Should have improvement areas list');
    }
    
    @IsTest
    static void testAnalyzeCompetencies_NullJobApplicationId() {
        // When/Then
        try {
            FeedbackAnalyticsService.analyzeCompetencies(null);
            System.assert(false, 'Should throw exception for null Job Application ID');
        } catch (FeedbackAnalyticsService.AnalyticsException e) {
            System.assertEquals('Job Application ID cannot be null', e.getMessage());
        }
    }
    
    @IsTest
    static void testGenerateRecommendations_Success() {
        // Given
        Job_Application__c jobApp = [SELECT Id FROM Job_Application__c LIMIT 1];
        
        // When
        Test.startTest();
        List<String> recommendations = FeedbackAnalyticsService.generateRecommendations(jobApp.Id);
        Test.stopTest();
        
        // Then
        System.assertNotEquals(null, recommendations, 'Recommendations should not be null');
        System.assert(!recommendations.isEmpty(), 'Should generate at least one recommendation');
        
        // Should contain actionable advice
        Boolean hasActionableAdvice = false;
        for (String recommendation : recommendations) {
            if (recommendation.contains('improving') || recommendation.contains('progress') || 
                recommendation.contains('practice') || recommendation.contains('consider')) {
                hasActionableAdvice = true;
                break;
            }
        }
        System.assert(hasActionableAdvice, 'Should contain actionable advice');
    }
    
    @IsTest
    static void testGenerateRecommendations_NullJobApplicationId() {
        // When/Then
        try {
            FeedbackAnalyticsService.generateRecommendations(null);
            System.assert(false, 'Should throw exception for null Job Application ID');
        } catch (FeedbackAnalyticsService.AnalyticsException e) {
            System.assertEquals('Job Application ID cannot be null', e.getMessage());
        }
    }
    
    @IsTest
    static void testGenerateDashboardData_Success() {
        // Given
        User testUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        
        // When
        Test.startTest();
        FeedbackAnalyticsService.DashboardData dashboardData = 
            FeedbackAnalyticsService.generateDashboardData(testUser.Id);
        Test.stopTest();
        
        // Then
        System.assertNotEquals(null, dashboardData, 'Dashboard data should not be null');
        System.assertEquals(1, dashboardData.totalApplicationsWithFeedback, 'Should have 1 application with feedback');
        System.assertEquals(4, dashboardData.totalFeedbackRecords, 'Should have 4 feedback records');
        System.assertNotEquals(null, dashboardData.averageOverallRating, 'Should calculate average rating');
        System.assert(dashboardData.averageOverallRating > 0, 'Average rating should be positive');
        System.assert(dashboardData.successRate >= 0 && dashboardData.successRate <= 100, 
                     'Success rate should be between 0 and 100');
        
        // Check dashboard components
        System.assertNotEquals(null, dashboardData.competencyBreakdown, 'Should have competency breakdown');
        System.assertNotEquals(null, dashboardData.performanceTrendData, 'Should have trend data');
        System.assertNotEquals(null, dashboardData.recentFeedback, 'Should have recent feedback');
        
        // Should have competency data
        System.assert(!dashboardData.competencyBreakdown.isEmpty(), 'Should have competency breakdown data');
        System.assert(!dashboardData.performanceTrendData.isEmpty(), 'Should have trend chart data');
        System.assert(!dashboardData.recentFeedback.isEmpty(), 'Should have recent activity data');
    }
    
    @IsTest
    static void testGenerateDashboardData_NullUserId() {
        // When/Then
        try {
            FeedbackAnalyticsService.generateDashboardData(null);
            System.assert(false, 'Should throw exception for null User ID');
        } catch (FeedbackAnalyticsService.AnalyticsException e) {
            System.assertEquals('User ID cannot be null', e.getMessage());
        }
    }
    
    @IsTest
    static void testPerformanceTrendWrapperClass() {
        // Test the PerformanceTrend wrapper class
        FeedbackAnalyticsService.PerformanceTrend trend = new FeedbackAnalyticsService.PerformanceTrend();
        
        // Verify default values
        System.assertEquals(0, trend.dataPoints, 'Default data points should be 0');
        
        // Test setters
        trend.trendDirection = 'Improving';
        trend.trendStrength = 1.5;
        trend.averageRating = 4.2;
        trend.latestRating = 4.5;
        trend.earliestRating = 3.8;
        
        System.assertEquals('Improving', trend.trendDirection, 'Should set trend direction');
        System.assertEquals(1.5, trend.trendStrength, 'Should set trend strength');
        System.assertEquals(4.2, trend.averageRating, 'Should set average rating');
        System.assertEquals(4.5, trend.latestRating, 'Should set latest rating');
        System.assertEquals(3.8, trend.earliestRating, 'Should set earliest rating');
    }
    
    @IsTest
    static void testCompetencyAnalysisWrapperClass() {
        // Test the CompetencyAnalysis wrapper class
        FeedbackAnalyticsService.CompetencyAnalysis analysis = new FeedbackAnalyticsService.CompetencyAnalysis();
        
        // Verify default values
        System.assertNotEquals(null, analysis.strongestCompetencies, 'Should initialize strongest competencies list');
        System.assertNotEquals(null, analysis.weakestCompetencies, 'Should initialize weakest competencies list');
        System.assertNotEquals(null, analysis.commonStrengths, 'Should initialize common strengths list');
        System.assertNotEquals(null, analysis.commonImprovementAreas, 'Should initialize improvement areas list');
        
        // Test setters
        analysis.averageTechnicalRating = 4.0;
        analysis.averageCommunicationRating = 3.5;
        analysis.averageCulturalFitRating = 4.2;
        
        System.assertEquals(4.0, analysis.averageTechnicalRating, 'Should set technical rating');
        System.assertEquals(3.5, analysis.averageCommunicationRating, 'Should set communication rating');
        System.assertEquals(4.2, analysis.averageCulturalFitRating, 'Should set cultural fit rating');
    }
    
    @IsTest
    static void testCompetencyScoreComparable() {
        // Test the CompetencyScore comparable implementation
        FeedbackAnalyticsService.CompetencyScore score1 = new FeedbackAnalyticsService.CompetencyScore();
        score1.competencyName = 'Technical Skills';
        score1.averageScore = 4.5;
        score1.feedbackCount = 3;
        
        FeedbackAnalyticsService.CompetencyScore score2 = new FeedbackAnalyticsService.CompetencyScore();
        score2.competencyName = 'Communication';
        score2.averageScore = 3.8;
        score2.feedbackCount = 4;
        
        FeedbackAnalyticsService.CompetencyScore score3 = new FeedbackAnalyticsService.CompetencyScore();
        score3.competencyName = 'Leadership';
        score3.averageScore = 4.5;
        score3.feedbackCount = 2;
        
        // Test comparison
        System.assertEquals(-1, score1.compareTo(score2), 'Higher score should come first');
        System.assertEquals(1, score2.compareTo(score1), 'Lower score should come second');
        System.assertEquals(0, score1.compareTo(score3), 'Equal scores should return 0');
        
        // Test sorting
        List<FeedbackAnalyticsService.CompetencyScore> scores = new List<FeedbackAnalyticsService.CompetencyScore>{
            score2, score1, score3
        };
        scores.sort();
        
        System.assertEquals(4.5, scores[0].averageScore, 'First item should have highest score');
        System.assertEquals(4.5, scores[1].averageScore, 'Second item should have equal highest score');
        System.assertEquals(3.8, scores[2].averageScore, 'Third item should have lowest score');
    }
    
    @IsTest
    static void testDashboardDataWrapperClass() {
        // Test the DashboardData wrapper class
        FeedbackAnalyticsService.DashboardData data = new FeedbackAnalyticsService.DashboardData();
        
        // Verify default values
        System.assertEquals(0, data.totalApplicationsWithFeedback, 'Default applications should be 0');
        System.assertEquals(0, data.totalFeedbackRecords, 'Default feedback records should be 0');
        System.assertEquals(0, data.averageOverallRating, 'Default average rating should be 0');
        System.assertEquals(0, data.successRate, 'Default success rate should be 0');
        System.assertNotEquals(null, data.competencyBreakdown, 'Should initialize competency breakdown');
        System.assertNotEquals(null, data.performanceTrendData, 'Should initialize trend data');
        System.assertNotEquals(null, data.recentFeedback, 'Should initialize recent feedback');
        
        // Test setters
        data.totalApplicationsWithFeedback = 5;
        data.totalFeedbackRecords = 20;
        data.averageOverallRating = 4.2;
        data.successRate = 75.5;
        
        System.assertEquals(5, data.totalApplicationsWithFeedback, 'Should set total applications');
        System.assertEquals(20, data.totalFeedbackRecords, 'Should set total feedback records');
        System.assertEquals(4.2, data.averageOverallRating, 'Should set average rating');
        System.assertEquals(75.5, data.successRate, 'Should set success rate');
    }
    
    @IsTest
    static void testChartDataPointAndRecentActivity() {
        // Test ChartDataPoint
        FeedbackAnalyticsService.ChartDataPoint chartPoint = new FeedbackAnalyticsService.ChartDataPoint();
        chartPoint.label = '01/15';
        chartPoint.value = 4.2;
        
        System.assertEquals('01/15', chartPoint.label, 'Should set chart label');
        System.assertEquals(4.2, chartPoint.value, 'Should set chart value');
        
        // Test RecentActivity
        FeedbackAnalyticsService.RecentActivity activity = new FeedbackAnalyticsService.RecentActivity();
        activity.feedbackId = 'a001234567890123';
        activity.interviewType = 'Technical';
        activity.rating = 4.5;
        activity.date = DateTime.now();
        
        System.assertEquals('a001234567890123', activity.feedbackId, 'Should set feedback ID');
        System.assertEquals('Technical', activity.interviewType, 'Should set interview type');
        System.assertEquals(4.5, activity.rating, 'Should set rating');
        System.assertNotEquals(null, activity.date, 'Should set date');
    }
    
    @IsTest
    static void testFeedbackComparators() {
        // Create test feedback records
        Interview_Feedback__c feedback1 = new Interview_Feedback__c();
        feedback1.Interview_Date__c = Date.today().addDays(-2);
        feedback1.CreatedDate = DateTime.now().addDays(-2);
        
        Interview_Feedback__c feedback2 = new Interview_Feedback__c();
        feedback2.Interview_Date__c = Date.today().addDays(-1);
        feedback2.CreatedDate = DateTime.now().addDays(-1);
        
        // Test FeedbackDateComparator
        FeedbackAnalyticsService.FeedbackDateComparator dateComparator = 
            new FeedbackAnalyticsService.FeedbackDateComparator();
        
        System.assertEquals(-1, dateComparator.compare(feedback1, feedback2), 
                           'Earlier date should come first');
        System.assertEquals(1, dateComparator.compare(feedback2, feedback1), 
                           'Later date should come second');
        System.assertEquals(0, dateComparator.compare(feedback1, feedback1), 
                           'Same date should return 0');
        
        // Test FeedbackCreatedDateComparator
        FeedbackAnalyticsService.FeedbackCreatedDateComparator createdDateComparator = 
            new FeedbackAnalyticsService.FeedbackCreatedDateComparator();
        
        System.assertEquals(1, createdDateComparator.compare(feedback1, feedback2), 
                           'Earlier created date should come second (descending)');
        System.assertEquals(-1, createdDateComparator.compare(feedback2, feedback1), 
                           'Later created date should come first (descending)');
        System.assertEquals(0, createdDateComparator.compare(feedback1, feedback1), 
                           'Same created date should return 0');
    }
    
    @IsTest
    static void testAnalyticsException() {
        // Test custom exception
        try {
            throw new FeedbackAnalyticsService.AnalyticsException('Test analytics error');
        } catch (FeedbackAnalyticsService.AnalyticsException e) {
            System.assertEquals('Test analytics error', e.getMessage(), 'Should preserve exception message');
        }
    }
    
    @IsTest
    static void testCachingBehavior() {
        // Given
        Job_Application__c jobApp = [SELECT Id FROM Job_Application__c LIMIT 1];
        
        // When - First call should calculate and cache
        Test.startTest();
        FeedbackAnalyticsService.PerformanceTrend trend1 = 
            FeedbackAnalyticsService.calculatePerformanceTrends(jobApp.Id, 30);
        
        // Second call should use cache (we can't directly test cache hit, but ensure consistency)
        FeedbackAnalyticsService.PerformanceTrend trend2 = 
            FeedbackAnalyticsService.calculatePerformanceTrends(jobApp.Id, 30);
        Test.stopTest();
        
        // Then - Results should be consistent
        System.assertEquals(trend1.trendDirection, trend2.trendDirection, 'Cached result should match');
        System.assertEquals(trend1.dataPoints, trend2.dataPoints, 'Cached data points should match');
        System.assertEquals(trend1.averageRating, trend2.averageRating, 'Cached average should match');
    }
    
    @IsTest
    static void testLargeDatasetPerformance() {
        // Given - Create job app with many feedback records
        Job_Application__c jobApp = InterviewFeedbackTestDataFactory.createJobApplication();
        jobApp.Position_Title__c = 'Performance Test Position';
        insert jobApp;
        
        // Create 50 feedback records for performance testing
        List<Interview_Feedback__c> largeFeedbackList = 
            InterviewFeedbackTestDataFactory.createMultipleFeedback(jobApp.Id, 50);
        insert largeFeedbackList;
        
        // When
        Test.startTest();
        FeedbackAnalyticsService.PerformanceTrend trend = 
            FeedbackAnalyticsService.calculatePerformanceTrends(jobApp.Id, 90);
        FeedbackAnalyticsService.CompetencyAnalysis analysis = 
            FeedbackAnalyticsService.analyzeCompetencies(jobApp.Id);
        List<String> recommendations = FeedbackAnalyticsService.generateRecommendations(jobApp.Id);
        Test.stopTest();
        
        // Then - Should handle large dataset efficiently
        System.assertNotEquals(null, trend, 'Should handle large dataset for trends');
        System.assertEquals(50, trend.dataPoints, 'Should process all 50 records');
        System.assertNotEquals(null, analysis, 'Should handle large dataset for analysis');
        System.assertNotEquals(null, recommendations, 'Should generate recommendations for large dataset');
        System.assert(!recommendations.isEmpty(), 'Should have recommendations for large dataset');
    }
}