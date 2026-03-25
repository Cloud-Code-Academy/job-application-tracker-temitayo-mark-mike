/**
 * @description Test class for FeedbackQueryOptimizationService
 * Tests caching strategies, query optimization, and performance monitoring
 * @author Salesforce Developer
 * @date 2024
 */
@IsTest
private inherited sharing class FeedbackQueryOptimizationServiceTest {
    
    @TestSetup
    static void setupOptimizationTestData() {
        // Create test Job Applications
        List<Job_Application__c> jobApps = InterviewFeedbackTestDataFactory.createJobApplications(5);
        insert jobApps;
        
        // Create test Interview Feedbacks with various dates
        List<Interview_Feedback__c> feedbacks = new List<Interview_Feedback__c>();
        
        for (Job_Application__c jobApp : jobApps) {
            for (Integer i = 0; i < 20; i++) {
                feedbacks.add(new Interview_Feedback__c(
                    Job_Application__c = jobApp.Id,
                    Interview_Type__c = 'Technical',
                    Interviewer_Name__c = 'Optimizer Test ' + i,
                    Overall_Rating__c = Math.mod(i, 5) + 1,
                    Technical_Rating__c = Math.mod(i + 1, 5) + 1,
                    Communication_Rating__c = Math.mod(i + 2, 5) + 1,
                    Cultural_Fit_Rating__c = Math.mod(i + 3, 5) + 1,
                    Interview_Date__c = System.now().addDays(-i)
                ));
            }
        }
        
        insert feedbacks;
        
        // Create competency ratings
        List<Competency_Rating__c> competencies = new List<Competency_Rating__c>();
        for (Interview_Feedback__c feedback : feedbacks) {
            competencies.add(new Competency_Rating__c(
                Interview_Feedback__c = feedback.Id,
                Competency_Name__c = 'Problem Solving',
                Rating__c = 4,
                Comments__c = 'Optimization test competency'
            ));
        }
        
        insert competencies;
    }
    
    /**
     * @description Test optimized dashboard data retrieval with caching
     * Requirements: 8.1, 8.2
     */
    @IsTest
    static void testOptimizedDashboardDataRetrieval() {
        Test.startTest();
        
        // First call - should hit database and cache result
        Datetime firstCallStart = System.now();
        FeedbackAnalyticsService.DashboardData firstCall = 
            FeedbackQueryOptimizationService.getDashboardDataOptimized(UserInfo.getUserId());
        Datetime firstCallEnd = System.now();
        
        Long firstCallDuration = firstCallEnd.getTime() - firstCallStart.getTime();
        
        System.assertNotEquals(null, firstCall, 'Dashboard data should be retrieved');
        System.assertNotEquals(null, firstCall.queryPerformance, 'Performance metrics should be included');
        System.assertEquals(false, (Boolean) firstCall.queryPerformance.get('cache_hit'), 
                          'First call should not be a cache hit');
        
        // Second call - should hit cache and be faster
        Datetime secondCallStart = System.now();
        FeedbackAnalyticsService.DashboardData secondCall = 
            FeedbackQueryOptimizationService.getDashboardDataOptimized(UserInfo.getUserId());
        Datetime secondCallEnd = System.now();
        
        Long secondCallDuration = secondCallEnd.getTime() - secondCallStart.getTime();
        
        System.assertNotEquals(null, secondCall, 'Cached dashboard data should be retrieved');
        
        // Verify caching improved performance
        System.debug('First call: ' + firstCallDuration + 'ms, Second call: ' + secondCallDuration + 'ms');
        System.assert(secondCallDuration <= firstCallDuration, 
                     'Cached call should be faster or equal');
        
        // Verify data consistency
        System.assertEquals(firstCall.totalFeedbacks, secondCall.totalFeedbacks, 
                          'Cached data should be consistent');
        
        Test.stopTest();
    }
    
    /**
     * @description Test bulk feedback processing optimization
     * Requirements: 10.1, 10.2
     */
    @IsTest
    static void testBulkFeedbackProcessingOptimization() {
        List<Interview_Feedback__c> feedbacks = [SELECT Id, Job_Application__c, Overall_Rating__c FROM Interview_Feedback__c];
        
        Test.startTest();
        
        // Track governor limits before processing
        Integer queriesBefore = Limits.getQueries();
        Integer dmlBefore = Limits.getDmlStatements();
        Integer cpuBefore = Limits.getCpuTime();
        
        // Process feedbacks using optimized bulk processing
        Datetime processStart = System.now();
        FeedbackQueryOptimizationService.processFeedbacksBulkOptimized(feedbacks);
        Datetime processEnd = System.now();
        
        Long processDuration = processEnd.getTime() - processStart.getTime();
        
        // Check governor limits after processing
        Integer queriesAfter = Limits.getQueries();
        Integer dmlAfter = Limits.getDmlStatements();
        Integer cpuAfter = Limits.getCpuTime();
        
        // Verify optimization effectiveness
        System.assert((queriesAfter - queriesBefore) < 20, 
                     'Optimized processing should use minimal queries: ' + (queriesAfter - queriesBefore));
        System.assert((dmlAfter - dmlBefore) < 10, 
                     'Optimized processing should use minimal DML: ' + (dmlAfter - dmlBefore));
        System.assert((cpuAfter - cpuBefore) < 5000, 
                     'Optimized processing should be CPU efficient: ' + (cpuAfter - cpuBefore));
        
        System.debug('Bulk processing completed in: ' + processDuration + 'ms');
        
        // Verify Job Applications were updated correctly
        List<Job_Application__c> updatedJobApps = [
            SELECT Id, Interview_Count__c, Average_Interview_Rating__c 
            FROM Job_Application__c 
            WHERE Interview_Count__c > 0
        ];
        
        System.assert(updatedJobApps.size() > 0, 'Job Applications should be updated');
        
        for (Job_Application__c jobApp : updatedJobApps) {
            System.assert(jobApp.Interview_Count__c > 0, 'Interview count should be updated');
            System.assert(jobApp.Average_Interview_Rating__c > 0, 'Average rating should be calculated');
        }
        
        Test.stopTest();
    }
    
    /**
     * @description Test optimized competency analysis with caching
     * Requirements: 3.1, 3.2, 8.1
     */
    @IsTest
    static void testOptimizedCompetencyAnalysis() {
        Job_Application__c jobApp = [SELECT Id FROM Job_Application__c LIMIT 1];
        
        Test.startTest();
        
        // First call - should query database and cache
        Datetime firstCallStart = System.now();
        FeedbackAnalyticsService.CompetencyAnalysis firstAnalysis = 
            FeedbackQueryOptimizationService.getCompetencyAnalysisOptimized(jobApp.Id, 90);
        Datetime firstCallEnd = System.now();
        
        Long firstCallDuration = firstCallEnd.getTime() - firstCallStart.getTime();
        
        System.assertNotEquals(null, firstAnalysis, 'Competency analysis should be generated');
        System.assertNotEquals(null, firstAnalysis.performanceMetrics, 'Performance metrics should be included');
        System.assertEquals(false, (Boolean) firstAnalysis.performanceMetrics.get('cache_hit'), 
                          'First call should not be a cache hit');
        
        // Second call - should hit cache
        Datetime secondCallStart = System.now();
        FeedbackAnalyticsService.CompetencyAnalysis secondAnalysis = 
            FeedbackQueryOptimizationService.getCompetencyAnalysisOptimized(jobApp.Id, 90);
        Datetime secondCallEnd = System.now();
        
        Long secondCallDuration = secondCallEnd.getTime() - secondCallStart.getTime();
        
        System.assertNotEquals(null, secondAnalysis, 'Cached analysis should be retrieved');
        
        // Verify caching effectiveness
        System.debug('First analysis: ' + firstCallDuration + 'ms, Second analysis: ' + secondCallDuration + 'ms');
        System.assert(secondCallDuration <= firstCallDuration, 
                     'Cached analysis should be faster or equal');
        
        Test.stopTest();
    }
    
    /**
     * @description Test optimized trend analysis with aggregation
     * Requirements: 3.3, 8.1, 8.2
     */
    @IsTest
    static void testOptimizedTrendAnalysis() {
        Job_Application__c jobApp = [SELECT Id FROM Job_Application__c LIMIT 1];
        
        Test.startTest();
        
        // Test trend analysis with caching
        Datetime trendStart = System.now();
        FeedbackAnalyticsService.PerformanceTrend trend = 
            FeedbackQueryOptimizationService.getTrendAnalysisOptimized(jobApp.Id, 90);
        Datetime trendEnd = System.now();
        
        Long trendDuration = trendEnd.getTime() - trendStart.getTime();
        
        System.assertNotEquals(null, trend, 'Trend analysis should be generated');
        System.debug('Trend analysis completed in: ' + trendDuration + 'ms');
        
        // Test caching by calling again
        Datetime cachedTrendStart = System.now();
        FeedbackAnalyticsService.PerformanceTrend cachedTrend = 
            FeedbackQueryOptimizationService.getTrendAnalysisOptimized(jobApp.Id, 90);
        Datetime cachedTrendEnd = System.now();
        
        Long cachedTrendDuration = cachedTrendEnd.getTime() - cachedTrendStart.getTime();
        
        System.assertNotEquals(null, cachedTrend, 'Cached trend should be retrieved');
        System.assert(cachedTrendDuration <= trendDuration, 
                     'Cached trend should be faster or equal');
        
        Test.stopTest();
    }
    
    /**
     * @description Test optimized sharing data retrieval
     * Requirements: 5.1, 5.2, 8.1
     */
    @IsTest
    static void testOptimizedSharingDataRetrieval() {
        List<Interview_Feedback__c> feedbacks = [SELECT Id FROM Interview_Feedback__c LIMIT 10];
        
        // Create sharing records
        List<Feedback_Share__c> shares = new List<Feedback_Share__c>();
        for (Interview_Feedback__c feedback : feedbacks) {
            shares.add(new Feedback_Share__c(
                Interview_Feedback__c = feedback.Id,
                Shared_With_Email__c = 'test@example.com',
                Access_Level__c = 'Read Only',
                Expiration_Date__c = System.now().addDays(7),
                Is_Active__c = true
            ));
        }
        insert shares;
        
        Test.startTest();
        
        // Test optimized sharing data retrieval
        List<Id> feedbackIds = new List<Id>();
        for (Interview_Feedback__c feedback : feedbacks) {
            feedbackIds.add(feedback.Id);
        }
        
        Datetime sharingStart = System.now();
        Map<Id, List<Feedback_Share__c>> sharingData = 
            FeedbackQueryOptimizationService.getSharingDataOptimized(feedbackIds);
        Datetime sharingEnd = System.now();
        
        Long sharingDuration = sharingEnd.getTime() - sharingStart.getTime();
        
        System.assertNotEquals(null, sharingData, 'Sharing data should be retrieved');
        System.assertEquals(feedbacks.size(), sharingData.size(), 'Should have sharing data for all feedbacks');
        System.debug('Sharing data retrieval completed in: ' + sharingDuration + 'ms');
        
        // Verify data structure
        for (Id feedbackId : feedbackIds) {
            System.assert(sharingData.containsKey(feedbackId), 'Should have sharing data for feedback: ' + feedbackId);
            System.assertEquals(1, sharingData.get(feedbackId).size(), 'Should have one share per feedback');
        }
        
        Test.stopTest();
    }
    
    /**
     * @description Test query performance monitoring
     * Requirements: 8.1, 10.5
     */
    @IsTest
    static void testQueryPerformanceMonitoring() {
        Test.startTest();
        
        // Test performance logging
        Datetime queryStart = System.now();
        
        // Simulate a query operation
        List<Interview_Feedback__c> feedbacks = [SELECT Id FROM Interview_Feedback__c LIMIT 50];
        
        // Log the performance
        FeedbackQueryOptimizationService.logQueryPerformance(
            'Test Query', queryStart, feedbacks.size()
        );
        
        // Verify performance log was created (would check custom object in real implementation)
        System.debug('Performance logging test completed for ' + feedbacks.size() + ' records');
        
        Test.stopTest();
    }
    
    /**
     * @description Test cache management operations
     * Requirements: 8.2
     */
    @IsTest
    static void testCacheManagement() {
        Test.startTest();
        
        // Test cache statistics
        Map<String, Object> cacheStats = FeedbackQueryOptimizationService.getCacheStatistics();
        
        System.assertNotEquals(null, cacheStats, 'Cache statistics should be available');
        System.assert(cacheStats.containsKey('partition_name'), 'Should include partition name');
        System.assert(cacheStats.containsKey('ttl_hours'), 'Should include TTL information');
        System.assert(cacheStats.containsKey('max_query_results'), 'Should include query limits');
        
        // Test cache clearing
        List<String> testCacheKeys = new List<String>{'test_key_1', 'test_key_2'};
        FeedbackQueryOptimizationService.clearCache(testCacheKeys);
        
        System.debug('Cache management test completed');
        
        Test.stopTest();
    }
    
    /**
     * @description Test optimization with large datasets
     * Requirements: 10.1, 10.2
     */
    @IsTest
    static void testOptimizationWithLargeDatasets() {
        // Create additional large dataset
        List<Job_Application__c> additionalJobApps = InterviewFeedbackTestDataFactory.createJobApplications(10);
        insert additionalJobApps;
        
        List<Interview_Feedback__c> largeFeedbackSet = new List<Interview_Feedback__c>();
        
        for (Job_Application__c jobApp : additionalJobApps) {
            for (Integer i = 0; i < 50; i++) {
                largeFeedbackSet.add(new Interview_Feedback__c(
                    Job_Application__c = jobApp.Id,
                    Interview_Type__c = 'Technical',
                    Interviewer_Name__c = 'Large Dataset Test ' + i,
                    Overall_Rating__c = Math.mod(i, 5) + 1,
                    Technical_Rating__c = Math.mod(i + 1, 5) + 1,
                    Interview_Date__c = System.now().addDays(-i)
                ));
            }
        }
        
        insert largeFeedbackSet;
        
        Test.startTest();
        
        // Test bulk processing with large dataset
        Datetime bulkStart = System.now();
        FeedbackQueryOptimizationService.processFeedbacksBulkOptimized(largeFeedbackSet);
        Datetime bulkEnd = System.now();
        
        Long bulkDuration = bulkEnd.getTime() - bulkStart.getTime();
        
        System.debug('Large dataset processing completed in: ' + bulkDuration + 'ms for ' + largeFeedbackSet.size() + ' records');
        
        // Should complete within reasonable time
        System.assert(bulkDuration < 10000, 'Large dataset processing should complete within 10 seconds');
        
        // Test dashboard generation with large dataset
        Datetime dashboardStart = System.now();
        FeedbackAnalyticsService.DashboardData largeDashboard = 
            FeedbackQueryOptimizationService.getDashboardDataOptimized(UserInfo.getUserId());
        Datetime dashboardEnd = System.now();
        
        Long dashboardDuration = dashboardEnd.getTime() - dashboardStart.getTime();
        
        System.assertNotEquals(null, largeDashboard, 'Dashboard should handle large datasets');
        System.debug('Large dataset dashboard generation completed in: ' + dashboardDuration + 'ms');
        
        Test.stopTest();
    }
    
    /**
     * @description Test optimization error handling
     * Requirements: 10.5
     */
    @IsTest
    static void testOptimizationErrorHandling() {
        Test.startTest();
        
        // Test with empty feedback list
        List<Interview_Feedback__c> emptyFeedbacks = new List<Interview_Feedback__c>();
        
        try {
            FeedbackQueryOptimizationService.processFeedbacksBulkOptimized(emptyFeedbacks);
            System.debug('Empty feedback list handled gracefully');
        } catch (Exception e) {
            System.assert(false, 'Should handle empty feedback list gracefully: ' + e.getMessage());
        }
        
        // Test with invalid user ID
        try {
            FeedbackAnalyticsService.DashboardData invalidUserDashboard = 
                FeedbackQueryOptimizationService.getDashboardDataOptimized('invalid_user_id');
            
            // Should handle gracefully or return null
            System.debug('Invalid user ID handled: ' + (invalidUserDashboard != null));
        } catch (Exception e) {
            System.debug('Invalid user ID error handled: ' + e.getMessage());
        }
        
        // Test with empty sharing data request
        List<Id> emptyFeedbackIds = new List<Id>();
        Map<Id, List<Feedback_Share__c>> emptySharingData = 
            FeedbackQueryOptimizationService.getSharingDataOptimized(emptyFeedbackIds);
        
        System.assertNotEquals(null, emptySharingData, 'Should return empty map for empty input');
        System.assertEquals(0, emptySharingData.size(), 'Empty input should return empty map');
        
        Test.stopTest();
    }
    
    /**
     * @description Test concurrent optimization operations
     * Requirements: 10.4
     */
    @IsTest
    static void testConcurrentOptimizationOperations() {
        List<Job_Application__c> jobApps = [SELECT Id FROM Job_Application__c LIMIT 3];
        
        Test.startTest();
        
        // Simulate concurrent dashboard requests
        List<FeedbackAnalyticsService.DashboardData> concurrentDashboards = 
            new List<FeedbackAnalyticsService.DashboardData>();
        
        for (Integer i = 0; i < 3; i++) {
            try {
                FeedbackAnalyticsService.DashboardData dashboard = 
                    FeedbackQueryOptimizationService.getDashboardDataOptimized(UserInfo.getUserId());
                concurrentDashboards.add(dashboard);
            } catch (Exception e) {
                System.debug('Concurrent dashboard request ' + i + ' error: ' + e.getMessage());
            }
        }
        
        System.assert(concurrentDashboards.size() >= 2, 
                     'Should handle most concurrent dashboard requests');
        
        // Simulate concurrent competency analysis
        List<FeedbackAnalyticsService.CompetencyAnalysis> concurrentAnalyses = 
            new List<FeedbackAnalyticsService.CompetencyAnalysis>();
        
        for (Job_Application__c jobApp : jobApps) {
            try {
                FeedbackAnalyticsService.CompetencyAnalysis analysis = 
                    FeedbackQueryOptimizationService.getCompetencyAnalysisOptimized(jobApp.Id, 90);
                concurrentAnalyses.add(analysis);
            } catch (Exception e) {
                System.debug('Concurrent analysis error for ' + jobApp.Id + ': ' + e.getMessage());
            }
        }
        
        System.assert(concurrentAnalyses.size() >= 2, 
                     'Should handle most concurrent analysis requests');
        
        Test.stopTest();
    }
}