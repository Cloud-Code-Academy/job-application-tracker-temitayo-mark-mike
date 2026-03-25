/**
 * @description Performance tests for Interview Feedback Tracker with large datasets
 * Tests scalability with 1000+ feedback records and concurrent operations
 * @author Salesforce Developer
 * @date 2024
 */
@IsTest
public class InterviewFeedbackPerformanceTest {
    
    private static final Integer LARGE_DATASET_SIZE = 1000;
    private static final Integer BULK_OPERATION_SIZE = 200;
    
    @TestSetup
    static void setupLargeDataset() {
        // Create job applications for performance testing
        List<Job_Application__c> jobApps = InterviewFeedbackTestDataFactory.createJobApplications(10);
        insert jobApps;
        
        // Create feedback templates
        List<Feedback_Template__c> templates = InterviewFeedbackTestDataFactory.createFeedbackTemplates(5);
        insert templates;
    }
    
    /**
     * @description Test performance with 1000+ feedback records
     * Requirements: 10.1, 10.2
     */
    @IsTest
    static void testLargeDatasetPerformance() {
        List<Job_Application__c> jobApps = [SELECT Id FROM Job_Application__c];
        
        Test.startTest();
        
        // Create large dataset of feedback records
        List<Interview_Feedback__c> largeFeedbackSet = new List<Interview_Feedback__c>();
        
        for (Integer i = 0; i < LARGE_DATASET_SIZE; i++) {
            Job_Application__c jobApp = jobApps[Math.mod(i, jobApps.size())];
            largeFeedbackSet.add(new Interview_Feedback__c(
                Job_Application__c = jobApp.Id,
                Interview_Type__c = getRandomInterviewType(i),
                Interviewer_Name__c = 'Interviewer ' + i,
                Interviewer_Email__c = 'interviewer' + i + '@company.com',
                Overall_Rating__c = Math.mod(i, 5) + 1,
                Technical_Rating__c = Math.mod(i, 5) + 1,
                Communication_Rating__c = Math.mod(i, 5) + 1,
                Cultural_Fit_Rating__c = Math.mod(i, 5) + 1,
                Interview_Date__c = System.now().addDays(-Math.mod(i, 365)),
                Detailed_Feedback__c = 'Performance test feedback record ' + i,
                Strengths__c = 'Test strengths for record ' + i,
                Areas_For_Improvement__c = 'Test improvements for record ' + i
            ));
        }
        
        // Measure insert performance
        Datetime insertStart = System.now();
        Database.SaveResult[] insertResults = Database.insert(largeFeedbackSet, false);
        Datetime insertEnd = System.now();
        
        Long insertDuration = insertEnd.getTime() - insertStart.getTime();
        System.debug('Large dataset insert duration: ' + insertDuration + 'ms');
        
        // Verify insert success rate
        Integer successCount = 0;
        for (Database.SaveResult result : insertResults) {
            if (result.isSuccess()) {
                successCount++;
            }
        }
        
        System.assert(successCount >= (LARGE_DATASET_SIZE * 0.95), 
                     'At least 95% of records should be inserted successfully');
        
        // Test analytics performance with large dataset
        Datetime analyticsStart = System.now();
        
        for (Job_Application__c jobApp : jobApps) {
            FeedbackAnalyticsService.DashboardData dashboardData = 
                FeedbackAnalyticsService.generateDashboardData(jobApp.Id);
            
            System.assertNotEquals(null, dashboardData, 'Dashboard data should be generated for large dataset');
        }
        
        Datetime analyticsEnd = System.now();
        Long analyticsDuration = analyticsEnd.getTime() - analyticsStart.getTime();
        System.debug('Analytics calculation duration: ' + analyticsDuration + 'ms');
        
        // Performance assertion - should complete within reasonable time
        System.assert(analyticsDuration < 10000, 'Analytics should complete within 10 seconds');
        
        Test.stopTest();
    }
    
    /**
     * @description Test bulk operations performance and governor limits
     * Requirements: 10.1, 10.3
     */
    @IsTest
    static void testBulkOperationsGovernorLimits() {
        List<Job_Application__c> jobApps = [SELECT Id FROM Job_Application__c];
        
        Test.startTest();
        
        // Track governor limits before operations
        Integer soqlQueriesBefore = Limits.getQueries();
        Integer dmlStatementsBefore = Limits.getDmlStatements();
        Integer cpuTimeBefore = Limits.getCpuTime();
        Integer heapSizeBefore = Limits.getHeapSize();
        
        // Perform bulk operations
        List<Interview_Feedback__c> bulkFeedbacks = new List<Interview_Feedback__c>();
        
        for (Integer i = 0; i < BULK_OPERATION_SIZE; i++) {
            Job_Application__c jobApp = jobApps[Math.mod(i, jobApps.size())];
            bulkFeedbacks.add(new Interview_Feedback__c(
                Job_Application__c = jobApp.Id,
                Interview_Type__c = 'Technical',
                Interviewer_Name__c = 'Bulk Interviewer ' + i,
                Overall_Rating__c = Math.mod(i, 5) + 1,
                Technical_Rating__c = Math.mod(i, 5) + 1,
                Communication_Rating__c = Math.mod(i, 5) + 1,
                Interview_Date__c = System.now().addDays(-i)
            ));
        }
        
        // Bulk insert
        insert bulkFeedbacks;
        
        // Create competency ratings for bulk feedback
        List<Competency_Rating__c> bulkCompetencies = new List<Competency_Rating__c>();
        for (Interview_Feedback__c feedback : bulkFeedbacks) {
            bulkCompetencies.add(new Competency_Rating__c(
                Interview_Feedback__c = feedback.Id,
                Competency_Name__c = 'Problem Solving',
                Rating__c = 4,
                Comments__c = 'Bulk test competency'
            ));
        }
        
        insert bulkCompetencies;
        
        // Bulk analytics processing
        InterviewFeedbackService.processFeedbackBatch(bulkFeedbacks);
        
        // Check governor limits after operations
        Integer soqlQueriesAfter = Limits.getQueries();
        Integer dmlStatementsAfter = Limits.getDmlStatements();
        Integer cpuTimeAfter = Limits.getCpuTime();
        Integer heapSizeAfter = Limits.getHeapSize();
        
        // Assert governor limits are within acceptable ranges
        System.assert((soqlQueriesAfter - soqlQueriesBefore) < 50, 
                     'SOQL queries should be optimized for bulk operations');
        System.assert((dmlStatementsAfter - dmlStatementsBefore) < 10, 
                     'DML statements should be bulkified');
        System.assert((cpuTimeAfter - cpuTimeBefore) < 5000, 
                     'CPU time should be within limits');
        System.assert((heapSizeAfter - heapSizeBefore) < 3000000, 
                     'Heap size should be managed efficiently');
        
        Test.stopTest();
    }
    
    /**
     * @description Test concurrent user access simulation
     * Requirements: 10.4
     */
    @IsTest
    static void testConcurrentUserAccess() {
        List<Job_Application__c> jobApps = [SELECT Id FROM Job_Application__c];
        List<User> testUsers = InterviewFeedbackTestDataFactory.createTestUsers(5);
        insert testUsers;
        
        Test.startTest();
        
        // Simulate concurrent feedback creation by multiple users
        List<Interview_Feedback__c> concurrentFeedbacks = new List<Interview_Feedback__c>();
        
        for (Integer userIndex = 0; userIndex < testUsers.size(); userIndex++) {
            User testUser = testUsers[userIndex];
            
            System.runAs(testUser) {
                for (Integer i = 0; i < 20; i++) {
                    Job_Application__c jobApp = jobApps[Math.mod(i, jobApps.size())];
                    concurrentFeedbacks.add(new Interview_Feedback__c(
                        Job_Application__c = jobApp.Id,
                        Interview_Type__c = 'Behavioral',
                        Interviewer_Name__c = 'Concurrent User ' + userIndex + ' Interview ' + i,
                        Overall_Rating__c = Math.mod(i, 5) + 1,
                        Technical_Rating__c = Math.mod(i, 5) + 1,
                        Communication_Rating__c = Math.mod(i, 5) + 1,
                        Interview_Date__c = System.now().addHours(-i),
                        OwnerId = testUser.Id
                    ));
                }
            }
        }
        
        // Insert all concurrent feedback records
        Database.SaveResult[] results = Database.insert(concurrentFeedbacks, false);
        
        // Verify concurrent operations succeeded
        Integer successCount = 0;
        for (Database.SaveResult result : results) {
            if (result.isSuccess()) {
                successCount++;
            }
        }
        
        System.assert(successCount >= (concurrentFeedbacks.size() * 0.9), 
                     'At least 90% of concurrent operations should succeed');
        
        // Test concurrent analytics access
        for (User testUser : testUsers) {
            System.runAs(testUser) {
                FeedbackAnalyticsService.DashboardData userData = 
                    FeedbackAnalyticsService.generateDashboardData(testUser.Id);
                
                System.assertNotEquals(null, userData, 
                                     'Each user should get their dashboard data');
            }
        }
        
        Test.stopTest();
    }
    
    /**
     * @description Test query optimization and caching performance
     * Requirements: 8.1, 8.2
     */
    @IsTest
    static void testQueryOptimizationAndCaching() {
        Job_Application__c jobApp = [SELECT Id FROM Job_Application__c LIMIT 1];
        
        // Create test feedback records
        List<Interview_Feedback__c> feedbacks = InterviewFeedbackTestDataFactory.createInterviewFeedbacks(
            new List<Id>{jobApp.Id}, 50
        );
        insert feedbacks;
        
        Test.startTest();
        
        // Test query optimization - first call
        Datetime firstCallStart = System.now();
        FeedbackAnalyticsService.DashboardData firstCall = 
            FeedbackAnalyticsService.generateDashboardData(UserInfo.getUserId());
        Datetime firstCallEnd = System.now();
        
        Long firstCallDuration = firstCallEnd.getTime() - firstCallStart.getTime();
        
        // Test caching - second call should be faster
        Datetime secondCallStart = System.now();
        FeedbackAnalyticsService.DashboardData secondCall = 
            FeedbackAnalyticsService.generateDashboardData(UserInfo.getUserId());
        Datetime secondCallEnd = System.now();
        
        Long secondCallDuration = secondCallEnd.getTime() - secondCallStart.getTime();
        
        // Verify caching improves performance
        System.debug('First call duration: ' + firstCallDuration + 'ms');
        System.debug('Second call duration: ' + secondCallDuration + 'ms');
        
        // Second call should be significantly faster due to caching
        System.assert(secondCallDuration <= firstCallDuration, 
                     'Cached call should be faster or equal');
        
        // Verify data consistency between calls
        System.assertEquals(firstCall.totalFeedbacks, secondCall.totalFeedbacks, 
                          'Cached data should be consistent');
        
        Test.stopTest();
    }
    
    /**
     * @description Helper method to get random interview types for test data
     */
    private static String getRandomInterviewType(Integer seed) {
        List<String> types = new List<String>{'Technical', 'Behavioral', 'Leadership', 'Cultural Fit', 'Final Round'};
        return types[Math.mod(seed, types.size())];
    }
    
    /**
     * @description Test memory usage optimization with large datasets
     * Requirements: 10.2, 10.5
     */
    @IsTest
    static void testMemoryOptimization() {
        List<Job_Application__c> jobApps = [SELECT Id FROM Job_Application__c];
        
        Test.startTest();
        
        // Track initial heap size
        Integer initialHeapSize = Limits.getHeapSize();
        
        // Process large dataset in chunks to test memory optimization
        for (Integer chunk = 0; chunk < 5; chunk++) {
            List<Interview_Feedback__c> chunkFeedbacks = new List<Interview_Feedback__c>();
            
            for (Integer i = 0; i < 100; i++) {
                Job_Application__c jobApp = jobApps[Math.mod(i, jobApps.size())];
                chunkFeedbacks.add(new Interview_Feedback__c(
                    Job_Application__c = jobApp.Id,
                    Interview_Type__c = 'Technical',
                    Interviewer_Name__c = 'Memory Test ' + chunk + '_' + i,
                    Overall_Rating__c = Math.mod(i, 5) + 1,
                    Detailed_Feedback__c = 'Memory optimization test feedback with sufficient content to test heap usage patterns and memory management efficiency in bulk operations'
                ));
            }
            
            insert chunkFeedbacks;
            
            // Process analytics for chunk
            InterviewFeedbackService.processFeedbackBatch(chunkFeedbacks);
            
            // Check heap size after each chunk
            Integer currentHeapSize = Limits.getHeapSize();
            System.assert(currentHeapSize < 4000000, 
                         'Heap size should remain manageable during chunk processing');
        }
        
        Integer finalHeapSize = Limits.getHeapSize();
        System.debug('Initial heap: ' + initialHeapSize + ', Final heap: ' + finalHeapSize);
        
        // Memory should be managed efficiently
        System.assert(finalHeapSize < 5000000, 
                     'Final heap size should be within acceptable limits');
        
        Test.stopTest();
    }
}