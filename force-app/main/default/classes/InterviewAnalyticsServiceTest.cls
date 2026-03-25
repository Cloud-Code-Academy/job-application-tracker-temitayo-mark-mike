/**
 * @description Test class for InterviewAnalyticsService
 * Tests statistical analysis, trend calculation, and predictive analytics
 * @author Temitayo Oluwalade
 * @date 2024
 */
@isTest
private class InterviewAnalyticsServiceTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test job applications
        List<Job_Application__c> jobApps = new List<Job_Application__c>();
        
        for (Integer i = 1; i <= 5; i++) {
            Job_Application__c jobApp = new Job_Application__c(
                Position_Title__c = 'Test Position ' + i,
                Company_Name__c = 'Test Company ' + i,
                Status__c = 'Applied',
                Salary__c = 80000 + (i * 10000)
            );
            jobApps.add(jobApp);
        }
        
        insert jobApps;
        
        // Create feedback template
        Feedback_Template__c template = new Feedback_Template__c(
            Name = 'Analytics Test Template',
            Interview_Type__c = 'Technical',
            Competency_Areas__c = 'Technical Skills;Communication;Problem Solving'
        );
        insert template;
        
        // Create diverse feedback data for analytics
        List<Interview_Feedback__c> feedbackList = new List<Interview_Feedback__c>();
        
        // Create feedback with different ratings and dates for trend analysis
        for (Integer i = 0; i < 20; i++) {
            Interview_Feedback__c feedback = new Interview_Feedback__c(
                Job_Application__c = jobApps[Math.mod(i, jobApps.size())].Id,
                Interview_Type__c = getInterviewType(i),
                Overall_Rating__c = getRatingForTrend(i),
                Interview_Date__c = DateTime.now().addDays(-i * 2),
                Strengths__c = 'Test strength ' + i,
                Areas_for_Improvement__c = 'Test improvement ' + i,
                Additional_Comments__c = 'Test comment ' + i
            );
            feedbackList.add(feedback);
        }
        
        insert feedbackList;
        
        // Create competency ratings
        List<Competency_Rating__c> competencyRatings = new List<Competency_Rating__c>();
        
        for (Interview_Feedback__c feedback : feedbackList) {
            // Add competency ratings for successful interviews
            if (feedback.Overall_Rating__c >= 4.0) {
                competencyRatings.add(new Competency_Rating__c(
                    Interview_Feedback__c = feedback.Id,
                    Competency_Name__c = 'Technical Skills',
                    Rating__c = 4.5
                ));
                competencyRatings.add(new Competency_Rating__c(
                    Interview_Feedback__c = feedback.Id,
                    Competency_Name__c = 'Communication',
                    Rating__c = 4.2
                ));
            }
        }
        
        insert competencyRatings;
    }
    
    // Helper methods for test data generation
    private static String getInterviewType(Integer index) {
        String[] types = new String[]{'Technical', 'Behavioral', 'System Design', 'Cultural Fit'};
        return types[Math.mod(index, types.size())];
    }
    
    private static Decimal getRatingForTrend(Integer index) {
        // Create an improving trend: lower ratings early, higher ratings later
        if (index < 5) {
            return 2.5 + (Math.mod(index, 3) * 0.3);
        } else if (index < 10) {
            return 3.2 + (Math.mod(index, 3) * 0.3);
        } else if (index < 15) {
            return 3.8 + (Math.mod(index, 3) * 0.3);
        } else {
            return 4.2 + (Math.mod(index, 3) * 0.3);
        }
    }
    
    @isTest
    static void testGenerateComprehensiveReport_WithData() {
        // Test with 30-day date range
        Date startDate = Date.today().addDays(-30);
        Date endDate = Date.today();
        
        Test.startTest();
        InterviewAnalyticsService.AnalyticsReport report = 
            InterviewAnalyticsService.generateComprehensiveReport(startDate, endDate, null);
        Test.stopTest();
        
        // Verify basic metrics
        System.assertNotEquals(null, report.basicMetrics, 'Basic metrics should be calculated');
        System.assert(report.basicMetrics.totalInterviews > 0, 'Should have interview data');
        System.assert(report.basicMetrics.averageRating > 0, 'Should have average rating');
        System.assert(report.basicMetrics.uniqueJobApplications > 0, 'Should have job applications');
        
        // Verify statistical analysis
        System.assertNotEquals(null, report.statisticalAnalysis, 'Statistical analysis should be performed');
        System.assertNotEquals(null, report.statisticalAnalysis.mean, 'Mean should be calculated');
        System.assertNotEquals(null, report.statisticalAnalysis.median, 'Median should be calculated');
        System.assertNotEquals(null, report.statisticalAnalysis.standardDeviation, 'Standard deviation should be calculated');
        
        // Verify trend analysis
        System.assertNotEquals(null, report.trendAnalysis, 'Trend analysis should be performed');
        System.assertNotEquals(null, report.trendAnalysis.trendDirection, 'Trend direction should be determined');
        
        // Verify benchmark comparison
        System.assertNotEquals(null, report.benchmarkComparison, 'Benchmark comparison should be generated');
        
        // Verify predictive analytics
        System.assertNotEquals(null, report.predictiveAnalytics, 'Predictive analytics should be calculated');
        System.assert(report.predictiveAnalytics.overallSuccessProbability >= 0, 'Success probability should be non-negative');
        
        // Verify insights
        System.assertNotEquals(null, report.insights, 'Insights should be generated');
    }
    
    @isTest
    static void testGenerateComprehensiveReport_WithUserFilter() {
        // Get a specific user
        User testUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        
        Date startDate = Date.today().addDays(-30);
        Date endDate = Date.today();
        
        Test.startTest();
        InterviewAnalyticsService.AnalyticsReport report = 
            InterviewAnalyticsService.generateComprehensiveReport(startDate, endDate, testUser.Id);
        Test.stopTest();
        
        // Should return report even if no data for specific user
        System.assertNotEquals(null, report, 'Report should be generated');
        System.assertNotEquals(null, report.basicMetrics, 'Basic metrics should exist');
    }
    
    @isTest
    static void testGenerateComprehensiveReport_NoData() {
        // Test with future date range (no data)
        Date startDate = Date.today().addDays(10);
        Date endDate = Date.today().addDays(20);
        
        Test.startTest();
        InterviewAnalyticsService.AnalyticsReport report = 
            InterviewAnalyticsService.generateComprehensiveReport(startDate, endDate, null);
        Test.stopTest();
        
        // Should handle empty data gracefully
        System.assertNotEquals(null, report, 'Report should be generated even with no data');
        System.assertEquals(0, report.basicMetrics.totalInterviews, 'Should show zero interviews');
        System.assertEquals(0, report.basicMetrics.averageRating, 'Should show zero average rating');
    }
    
    @isTest
    static void testBasicMetricsCalculation() {
        // Get test feedback data
        List<Interview_Feedback__c> feedbackData = [
            SELECT Id, Job_Application__c, Interview_Type__c, Overall_Rating__c, Interview_Date__c
            FROM Interview_Feedback__c
            LIMIT 10
        ];
        
        Test.startTest();
        // Use reflection to test private method (in real implementation, we'd make it public for testing)
        InterviewAnalyticsService.AnalyticsReport report = 
            InterviewAnalyticsService.generateComprehensiveReport(Date.today().addDays(-30), Date.today(), null);
        Test.stopTest();
        
        // Verify basic metrics are reasonable
        System.assert(report.basicMetrics.totalInterviews <= 20, 'Total interviews should not exceed test data');
        System.assert(report.basicMetrics.averageRating >= 1.0 && report.basicMetrics.averageRating <= 5.0, 
                     'Average rating should be within valid range');
        
        // Verify interview type metrics
        if (report.basicMetrics.interviewTypeMetrics != null) {
            for (InterviewAnalyticsService.InterviewTypeMetric metric : report.basicMetrics.interviewTypeMetrics) {
                System.assert(metric.count > 0, 'Interview type count should be positive');
                System.assert(metric.averageRating >= 1.0 && metric.averageRating <= 5.0, 
                             'Type average rating should be within valid range');
            }
        }
    }
    
    @isTest
    static void testStatisticalAnalysis() {
        Date startDate = Date.today().addDays(-30);
        Date endDate = Date.today();
        
        Test.startTest();
        InterviewAnalyticsService.AnalyticsReport report = 
            InterviewAnalyticsService.generateComprehensiveReport(startDate, endDate, null);
        Test.stopTest();
        
        InterviewAnalyticsService.StatisticalAnalysis stats = report.statisticalAnalysis;
        
        // Verify statistical measures are reasonable
        System.assert(stats.mean >= 1.0 && stats.mean <= 5.0, 'Mean should be within rating range');
        System.assert(stats.median >= 1.0 && stats.median <= 5.0, 'Median should be within rating range');
        System.assert(stats.standardDeviation >= 0, 'Standard deviation should be non-negative');
        
        // Verify confidence intervals
        System.assert(stats.confidenceInterval95Lower <= stats.mean, 'Lower CI should be <= mean');
        System.assert(stats.confidenceInterval95Upper >= stats.mean, 'Upper CI should be >= mean');
        System.assert(stats.confidenceInterval95Lower < stats.confidenceInterval95Upper, 'CI should be valid range');
    }
    
    @isTest
    static void testTrendAnalysis() {
        Date startDate = Date.today().addDays(-40);
        Date endDate = Date.today();
        
        Test.startTest();
        InterviewAnalyticsService.AnalyticsReport report = 
            InterviewAnalyticsService.generateComprehensiveReport(startDate, endDate, null);
        Test.stopTest();
        
        InterviewAnalyticsService.TrendAnalysis trend = report.trendAnalysis;
        
        // Verify trend analysis results
        System.assertNotEquals(null, trend.trendDirection, 'Trend direction should be determined');
        System.assert(
            trend.trendDirection == 'Improving' || 
            trend.trendDirection == 'Declining' || 
            trend.trendDirection == 'Stable' ||
            trend.trendDirection == 'Insufficient Data',
            'Trend direction should be valid value'
        );
        
        if (trend.trendDirection != 'Insufficient Data') {
            System.assertNotEquals(null, trend.trendStrength, 'Trend strength should be determined');
            System.assert(
                trend.trendStrength == 'Strong' || 
                trend.trendStrength == 'Moderate' || 
                trend.trendStrength == 'Weak',
                'Trend strength should be valid value'
            );
        }
    }
    
    @isTest
    static void testBenchmarkComparison() {
        Date startDate = Date.today().addDays(-30);
        Date endDate = Date.today();
        
        Test.startTest();
        InterviewAnalyticsService.AnalyticsReport report = 
            InterviewAnalyticsService.generateComprehensiveReport(startDate, endDate, null);
        Test.stopTest();
        
        InterviewAnalyticsService.BenchmarkComparison benchmark = report.benchmarkComparison;
        
        // Verify benchmark comparisons
        System.assertNotEquals(null, benchmark.comparisons, 'Benchmark comparisons should exist');
        
        if (benchmark.comparisons != null && !benchmark.comparisons.isEmpty()) {
            for (InterviewAnalyticsService.BenchmarkComparison.TypeComparison comp : benchmark.comparisons) {
                System.assertNotEquals(null, comp.interviewType, 'Interview type should be specified');
                System.assert(comp.userAverage >= 1.0 && comp.userAverage <= 5.0, 'User average should be valid');
                System.assert(comp.industryBenchmark >= 1.0 && comp.industryBenchmark <= 5.0, 'Benchmark should be valid');
                System.assertNotEquals(null, comp.performanceLevel, 'Performance level should be determined');
                System.assert(
                    comp.performanceLevel == 'Excellent' ||
                    comp.performanceLevel == 'Above Average' ||
                    comp.performanceLevel == 'Average' ||
                    comp.performanceLevel == 'Below Average',
                    'Performance level should be valid'
                );
            }
        }
    }
    
    @isTest
    static void testPredictiveAnalytics() {
        Date startDate = Date.today().addDays(-30);
        Date endDate = Date.today();
        
        Test.startTest();
        InterviewAnalyticsService.AnalyticsReport report = 
            InterviewAnalyticsService.generateComprehensiveReport(startDate, endDate, null);
        Test.stopTest();
        
        InterviewAnalyticsService.PredictiveAnalytics prediction = report.predictiveAnalytics;
        
        // Verify predictive analytics
        System.assert(prediction.overallSuccessProbability >= 0 && prediction.overallSuccessProbability <= 100,
                     'Success probability should be valid percentage');
        
        if (prediction.typeSuccessProbabilities != null) {
            for (InterviewAnalyticsService.PredictiveAnalytics.TypeProbability typeProb : prediction.typeSuccessProbabilities) {
                System.assertNotEquals(null, typeProb.interviewType, 'Interview type should be specified');
                System.assert(typeProb.successProbability >= 0 && typeProb.successProbability <= 100,
                             'Type success probability should be valid percentage');
                System.assert(typeProb.sampleSize > 0, 'Sample size should be positive');
            }
        }
        
        System.assertNotEquals(null, prediction.successFactors, 'Success factors should be generated');
    }
    
    @isTest
    static void testInsightGeneration() {
        Date startDate = Date.today().addDays(-30);
        Date endDate = Date.today();
        
        Test.startTest();
        InterviewAnalyticsService.AnalyticsReport report = 
            InterviewAnalyticsService.generateComprehensiveReport(startDate, endDate, null);
        Test.stopTest();
        
        // Verify insights are generated
        System.assertNotEquals(null, report.insights, 'Insights should be generated');
        
        // Insights should be meaningful strings
        if (report.insights != null && !report.insights.isEmpty()) {
            for (String insight : report.insights) {
                System.assert(String.isNotBlank(insight), 'Insights should not be blank');
                System.assert(insight.length() > 10, 'Insights should be meaningful');
            }
        }
    }
    
    @isTest
    static void testEdgeCases() {
        // Test with single data point
        Job_Application__c singleApp = new Job_Application__c(
            Position_Title__c = 'Single Test',
            Company_Name__c = 'Single Company',
            Status__c = 'Applied'
        );
        insert singleApp;
        
        Interview_Feedback__c singleFeedback = new Interview_Feedback__c(
            Job_Application__c = singleApp.Id,
            Interview_Type__c = 'Technical',
            Overall_Rating__c = 4.0,
            Interview_Date__c = DateTime.now()
        );
        insert singleFeedback;
        
        Test.startTest();
        InterviewAnalyticsService.AnalyticsReport report = 
            InterviewAnalyticsService.generateComprehensiveReport(Date.today(), Date.today(), null);
        Test.stopTest();
        
        // Should handle single data point gracefully
        System.assertNotEquals(null, report, 'Report should be generated with single data point');
        System.assertEquals(1, report.basicMetrics.totalInterviews, 'Should show one interview');
        System.assertEquals(4.0, report.basicMetrics.averageRating, 'Should show correct average');
    }
    
    @isTest
    static void testPerformanceWithLargeDataset() {
        // Create additional data for performance testing
        List<Job_Application__c> perfApps = new List<Job_Application__c>();
        for (Integer i = 0; i < 10; i++) {
            perfApps.add(new Job_Application__c(
                Position_Title__c = 'Perf Test ' + i,
                Company_Name__c = 'Perf Company ' + i,
                Status__c = 'Applied'
            ));
        }
        insert perfApps;
        
        List<Interview_Feedback__c> perfFeedback = new List<Interview_Feedback__c>();
        for (Job_Application__c app : perfApps) {
            for (Integer j = 0; j < 10; j++) {
                perfFeedback.add(new Interview_Feedback__c(
                    Job_Application__c = app.Id,
                    Interview_Type__c = 'Technical',
                    Overall_Rating__c = 3.0 + (Math.mod(j, 3) * 0.5),
                    Interview_Date__c = DateTime.now().addDays(-j)
                ));
            }
        }
        insert perfFeedback;
        
        Test.startTest();
        Long startTime = System.currentTimeMillis();
        
        InterviewAnalyticsService.AnalyticsReport report = 
            InterviewAnalyticsService.generateComprehensiveReport(Date.today().addDays(-30), Date.today(), null);
        
        Long endTime = System.currentTimeMillis();
        Test.stopTest();
        
        // Verify performance is reasonable (should complete within test limits)
        System.assert(endTime - startTime < 10000, 'Analytics should complete within reasonable time');
        System.assertNotEquals(null, report, 'Report should be generated with large dataset');
        System.assert(report.basicMetrics.totalInterviews > 100, 'Should process large dataset');
    }
}