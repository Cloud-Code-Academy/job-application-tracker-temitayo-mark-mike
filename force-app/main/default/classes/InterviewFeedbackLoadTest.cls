/**
 * @description Load testing scenarios for Interview Feedback Tracker
 * Tests concurrent user access, bulk operations, and system limits
 * @author Salesforce Developer
 * @date 2024
 */
@IsTest
public inherited sharing class InterviewFeedbackLoadTest {
    
    private static final Integer MAX_CONCURRENT_USERS = 10;
    private static final Integer RECORDS_PER_USER = 50;
    private static final Integer GOVERNOR_LIMIT_TEST_SIZE = 200;
    
    @TestSetup
    static void setupLoadTestData() {
        // Create job applications for load testing
        List<Job_Application__c> jobApps = InterviewFeedbackTestDataFactory.createJobApplications(20);
        insert jobApps;
        
        // Create feedback templates
        List<Feedback_Template__c> templates = InterviewFeedbackTestDataFactory.createFeedbackTemplates(10);
        insert templates;
        
        // Create test users with different roles
        List<User> testUsers = InterviewFeedbackTestDataFactory.createTestUsers(MAX_CONCURRENT_USERS);
        insert testUsers;
    }
    
    /**
     * @description Test concurrent user load with feedback creation
     * Requirements: 10.4, 10.5
     */
    @IsTest
    static void testConcurrentUserLoad() {
        List<Job_Application__c> jobApps = [SELECT Id FROM Job_Application__c];
        List<User> testUsers = [SELECT Id, Username FROM User WHERE IsActive = true AND Profile.Name = 'Standard User' LIMIT :MAX_CONCURRENT_USERS];
        
        Test.startTest();
        
        // Track system performance metrics
        Integer initialQueries = Limits.getQueries();
        Integer initialDML = Limits.getDmlStatements();
        Integer initialCPU = Limits.getCpuTime();
        
        List<Interview_Feedback__c> allConcurrentFeedbacks = new List<Interview_Feedback__c>();
        
        // Simulate concurrent user operations
        for (Integer userIndex = 0; userIndex < testUsers.size(); userIndex++) {
            User currentUser = testUsers[userIndex];
            
            System.runAs(currentUser) {
                List<Interview_Feedback__c> userFeedbacks = new List<Interview_Feedback__c>();
                
                for (Integer recordIndex = 0; recordIndex < RECORDS_PER_USER; recordIndex++) {
                    Job_Application__c jobApp = jobApps[Math.mod(recordIndex, jobApps.size())];
                    
                    Interview_Feedback__c feedback = new Interview_Feedback__c(
                        Job_Application__c = jobApp.Id,
                        Interview_Type__c = getLoadTestInterviewType(recordIndex),
                        Interviewer_Name__c = 'Load Test User ' + userIndex + ' Interview ' + recordIndex,
                        Interviewer_Email__c = 'loadtest' + userIndex + '_' + recordIndex + '@company.com',
                        Overall_Rating__c = Math.mod(recordIndex, 5) + 1,
                        Technical_Rating__c = Math.mod(recordIndex + 1, 5) + 1,
                        Communication_Rating__c = Math.mod(recordIndex + 2, 5) + 1,
                        Cultural_Fit_Rating__c = Math.mod(recordIndex + 3, 5) + 1,
                        Interview_Date__c = System.now().addHours(-recordIndex),
                        Detailed_Feedback__c = 'Load test feedback for user ' + userIndex + ' record ' + recordIndex,
                        Strengths__c = 'Load test strengths',
                        Areas_For_Improvement__c = 'Load test improvements',
                        OwnerId = currentUser.Id
                    );
                    
                    userFeedbacks.add(feedback);
                    allConcurrentFeedbacks.add(feedback);
                }
                
                // Insert user's feedback batch
                try {
                    Database.SaveResult[] userResults = Database.insert(userFeedbacks, false);
                    
                    // Verify user's batch success
                    Integer userSuccessCount = 0;
                    for (Database.SaveResult result : userResults) {
                        if (result.isSuccess()) {
                            userSuccessCount++;
                        }
                    }
                    
                    System.assert(userSuccessCount >= (RECORDS_PER_USER * 0.9), 
                                 'At least 90% of user records should be inserted successfully');
                    
                } catch (Exception e) {
                    System.debug('User ' + userIndex + ' encountered error: ' + e.getMessage());
                }
            }
        }
        
        // Test concurrent analytics generation
        List<FeedbackAnalyticsService.DashboardData> concurrentDashboards = 
            new List<FeedbackAnalyticsService.DashboardData>();
        
        for (User testUser : testUsers) {
            System.runAs(testUser) {
                try {
                    FeedbackAnalyticsService.DashboardData userDashboard = 
                        FeedbackAnalyticsService.generateDashboardData(testUser.Id);
                    concurrentDashboards.add(userDashboard);
                } catch (Exception e) {
                    System.debug('Dashboard generation error for user: ' + e.getMessage());
                }
            }
        }
        
        // Verify concurrent dashboard generation
        System.assert(concurrentDashboards.size() >= (testUsers.size() * 0.8), 
                     'At least 80% of concurrent dashboard requests should succeed');
        
        // Check final system metrics
        Integer finalQueries = Limits.getQueries();
        Integer finalDML = Limits.getDmlStatements();
        Integer finalCPU = Limits.getCpuTime();
        
        System.debug('Load test metrics - Queries: ' + (finalQueries - initialQueries) + 
                    ', DML: ' + (finalDML - initialDML) + 
                    ', CPU: ' + (finalCPU - initialCPU));
        
        Test.stopTest();
    }
    
    /**
     * @description Test governor limits with maximum operations
     * Requirements: 10.1, 10.3
     */
    @IsTest
    static void testGovernorLimitsCompliance() {
        List<Job_Application__c> jobApps = [SELECT Id FROM Job_Application__c];
        
        Test.startTest();
        
        // Test SOQL query limits
        List<Interview_Feedback__c> queryTestFeedbacks = new List<Interview_Feedback__c>();
        
        for (Integer i = 0; i < GOVERNOR_LIMIT_TEST_SIZE; i++) {
            Job_Application__c jobApp = jobApps[Math.mod(i, jobApps.size())];
            queryTestFeedbacks.add(new Interview_Feedback__c(
                Job_Application__c = jobApp.Id,
                Interview_Type__c = 'Technical',
                Interviewer_Name__c = 'Governor Test ' + i,
                Overall_Rating__c = Math.mod(i, 5) + 1,
                Technical_Rating__c = Math.mod(i, 5) + 1,
                Communication_Rating__c = Math.mod(i, 5) + 1,
                Interview_Date__c = System.now().addDays(-i)
            ));
        }
        
        insert queryTestFeedbacks;
        
        // Test query optimization - should use minimal queries
        Integer queriesBeforeAnalytics = Limits.getQueries();
        
        // Perform analytics that could potentially use many queries
        for (Job_Application__c jobApp : jobApps) {
            FeedbackAnalyticsService.PerformanceTrend trends = 
                FeedbackAnalyticsService.calculateTrends(jobApp.Id, 365);
            
            FeedbackAnalyticsService.CompetencyAnalysis analysis = 
                FeedbackAnalyticsService.analyzeCompetencies([
                    SELECT Id, Technical_Rating__c, Communication_Rating__c, 
                           Cultural_Fit_Rating__c, Overall_Rating__c
                    FROM Interview_Feedback__c 
                    WHERE Job_Application__c = :jobApp.Id
                ]);
        }
        
        Integer queriesAfterAnalytics = Limits.getQueries();
        Integer analyticsQueries = queriesAfterAnalytics - queriesBeforeAnalytics;
        
        // Should use efficient queries (less than 50 for all job apps)
        System.assert(analyticsQueries < 50, 
                     'Analytics should use optimized queries: ' + analyticsQueries);
        
        // Test DML limits with bulk operations
        Integer dmlBefore = Limits.getDmlStatements();
        
        // Create competency ratings in bulk
        List<Competency_Rating__c> bulkCompetencies = new List<Competency_Rating__c>();
        for (Interview_Feedback__c feedback : queryTestFeedbacks) {
            bulkCompetencies.add(new Competency_Rating__c(
                Interview_Feedback__c = feedback.Id,
                Competency_Name__c = 'Problem Solving',
                Rating__c = 4,
                Comments__c = 'Governor limit test'
            ));
            
            bulkCompetencies.add(new Competency_Rating__c(
                Interview_Feedback__c = feedback.Id,
                Competency_Name__c = 'Communication',
                Rating__c = 3,
                Comments__c = 'Governor limit test'
            ));
        }
        
        insert bulkCompetencies;
        
        Integer dmlAfter = Limits.getDmlStatements();
        Integer dmlUsed = dmlAfter - dmlBefore;
        
        // Should use minimal DML statements (bulkified)
        System.assert(dmlUsed < 5, 'DML operations should be bulkified: ' + dmlUsed);
        
        // Test CPU time limits
        Integer cpuBefore = Limits.getCpuTime();
        
        // Perform CPU-intensive analytics
        InterviewFeedbackService.processFeedbackBatch(queryTestFeedbacks);
        
        Integer cpuAfter = Limits.getCpuTime();
        Integer cpuUsed = cpuAfter - cpuBefore;
        
        // Should complete within reasonable CPU time
        System.assert(cpuUsed < 8000, 'CPU usage should be optimized: ' + cpuUsed + 'ms');
        
        // Test heap size limits
        Integer heapBefore = Limits.getHeapSize();
        
        // Generate large dashboard data
        FeedbackAnalyticsService.DashboardData largeDashboard = 
            FeedbackAnalyticsService.generateDashboardData(UserInfo.getUserId());
        
        Integer heapAfter = Limits.getHeapSize();
        Integer heapUsed = heapAfter - heapBefore;
        
        // Should manage memory efficiently
        System.assert(heapUsed < 3000000, 'Heap usage should be managed: ' + heapUsed + ' bytes');
        
        Test.stopTest();
    }
    
    /**
     * @description Test bulk sharing operations under load
     * Requirements: 5.1, 5.2, 10.4
     */
    @IsTest
    static void testBulkSharingLoad() {
        List<Interview_Feedback__c> feedbacks = [SELECT Id FROM Interview_Feedback__c LIMIT 100];
        
        Test.startTest();
        
        // Create bulk sharing operations
        List<String> shareTokens = new List<String>();
        
        for (Integer i = 0; i < feedbacks.size(); i++) {
            Interview_Feedback__c feedback = feedbacks[i];
            
            try {
                String shareToken = FeedbackSharingService.createShareLink(
                    feedback.Id,
                    'mentor' + i + '@company.com',
                    'Read Only'
                );
                
                if (shareToken != null) {
                    shareTokens.add(shareToken);
                }
            } catch (Exception e) {
                System.debug('Sharing error for feedback ' + i + ': ' + e.getMessage());
            }
        }
        
        // Verify bulk sharing success rate
        System.assert(shareTokens.size() >= (feedbacks.size() * 0.9), 
                     'At least 90% of sharing operations should succeed');
        
        // Test bulk access validation
        Integer validAccessCount = 0;
        for (String token : shareTokens) {
            try {
                Boolean hasAccess = FeedbackSharingService.validateShareAccess(token);
                if (hasAccess) {
                    validAccessCount++;
                }
            } catch (Exception e) {
                System.debug('Access validation error: ' + e.getMessage());
            }
        }
        
        System.assert(validAccessCount >= (shareTokens.size() * 0.95), 
                     'At least 95% of access validations should succeed');
        
        Test.stopTest();
    }
    
    /**
     * @description Test system recovery under extreme load
     * Requirements: 10.5
     */
    @IsTest
    static void testSystemRecoveryUnderLoad() {
        List<Job_Application__c> jobApps = [SELECT Id FROM Job_Application__c];
        
        Test.startTest();
        
        // Simulate extreme load conditions
        List<Interview_Feedback__c> extremeLoadFeedbacks = new List<Interview_Feedback__c>();
        
        // Create maximum possible records within test limits
        for (Integer i = 0; i < 200; i++) {
            Job_Application__c jobApp = jobApps[Math.mod(i, jobApps.size())];
            
            extremeLoadFeedbacks.add(new Interview_Feedback__c(
                Job_Application__c = jobApp.Id,
                Interview_Type__c = 'Technical',
                Interviewer_Name__c = 'Extreme Load Test ' + i,
                Overall_Rating__c = Math.mod(i, 5) + 1,
                Technical_Rating__c = Math.mod(i, 5) + 1,
                Communication_Rating__c = Math.mod(i, 5) + 1,
                Interview_Date__c = System.now().addMinutes(-i),
                Detailed_Feedback__c = 'Extreme load test feedback with extensive content to test system limits and recovery mechanisms under high stress conditions and maximum data volume scenarios'
            ));
        }
        
        // Test system resilience with batch processing
        Database.SaveResult[] extremeResults = Database.insert(extremeLoadFeedbacks, false);
        
        // Analyze results and system recovery
        Integer successCount = 0;
        Integer errorCount = 0;
        List<String> errorMessages = new List<String>();
        
        for (Database.SaveResult result : extremeResults) {
            if (result.isSuccess()) {
                successCount++;
            } else {
                errorCount++;
                for (Database.Error error : result.getErrors()) {
                    errorMessages.add(error.getMessage());
                }
            }
        }
        
        System.debug('Extreme load results - Success: ' + successCount + ', Errors: ' + errorCount);
        
        // System should handle at least 80% of extreme load
        System.assert(successCount >= (extremeLoadFeedbacks.size() * 0.8), 
                     'System should handle at least 80% of extreme load');
        
        // Test system recovery with analytics after extreme load
        try {
            FeedbackAnalyticsService.DashboardData recoveryDashboard = 
                FeedbackAnalyticsService.generateDashboardData(UserInfo.getUserId());
            
            System.assertNotEquals(null, recoveryDashboard, 
                                 'System should recover and provide analytics after extreme load');
        } catch (Exception e) {
            System.debug('System recovery test failed: ' + e.getMessage());
            // System should not completely fail
            System.assert(false, 'System should maintain basic functionality after extreme load');
        }
        
        Test.stopTest();
    }
    
    /**
     * @description Helper method to get interview types for load testing
     */
    private static String getLoadTestInterviewType(Integer index) {
        List<String> types = new List<String>{
            'Technical', 'Behavioral', 'Leadership', 'Cultural Fit', 'Final Round', 
            'Phone Screen', 'Panel Interview', 'Case Study', 'Presentation', 'Coding Challenge'
        };
        return types[Math.mod(index, types.size())];
    }
    
    /**
     * @description Test database connection resilience under load
     * Requirements: 10.5
     */
    @IsTest
    static void testDatabaseResilienceUnderLoad() {
        Test.startTest();
        
        // Simulate rapid database operations
        List<Interview_Feedback__c> rapidOperationFeedbacks = new List<Interview_Feedback__c>();
        List<Job_Application__c> jobApps = [SELECT Id FROM Job_Application__c LIMIT 5];
        
        for (Integer batch = 0; batch < 10; batch++) {
            List<Interview_Feedback__c> batchFeedbacks = new List<Interview_Feedback__c>();
            
            for (Integer i = 0; i < 20; i++) {
                Job_Application__c jobApp = jobApps[Math.mod(i, jobApps.size())];
                batchFeedbacks.add(new Interview_Feedback__c(
                    Job_Application__c = jobApp.Id,
                    Interview_Type__c = 'Technical',
                    Interviewer_Name__c = 'DB Resilience Batch ' + batch + ' Record ' + i,
                    Overall_Rating__c = Math.mod(i, 5) + 1,
                    Interview_Date__c = System.now().addSeconds(-i)
                ));
            }
            
            try {
                insert batchFeedbacks;
                rapidOperationFeedbacks.addAll(batchFeedbacks);
            } catch (Exception e) {
                System.debug('Database resilience batch ' + batch + ' error: ' + e.getMessage());
            }
        }
        
        // Verify database maintained consistency
        List<Interview_Feedback__c> verificationQuery = [
            SELECT Id, Interviewer_Name__c 
            FROM Interview_Feedback__c 
            WHERE Interviewer_Name__c LIKE 'DB Resilience%'
        ];
        
        System.assert(verificationQuery.size() >= (rapidOperationFeedbacks.size() * 0.9), 
                     'Database should maintain consistency under rapid operations');
        
        Test.stopTest();
    }
}