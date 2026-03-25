/**
 * @description Query optimization service for Interview Feedback Tracker
 * Implements caching strategies, efficient SOQL patterns, and performance monitoring
 * @author Salesforce Developer
 * @date 2024
 */
public inherited sharing class FeedbackQueryOptimizationService {
    
    // Cache partition for feedback data
    private static final String CACHE_PARTITION = 'FeedbackCache';
    private static final Integer CACHE_TTL_HOURS = 2;
    
    // Query optimization constants
    private static final Integer MAX_QUERY_RESULTS = 2000;
    private static final Integer BATCH_SIZE = 200;
    
    /**
     * @description Optimized query for dashboard data with caching
     * @param userId User ID for dashboard data
     * @return Dashboard data with performance metrics
     */
    public static FeedbackAnalyticsService.DashboardData getDashboardDataOptimized(Id userId) {
        String cacheKey = 'dashboard_' + userId + '_' + Date.today().format();
        
        // Try to get from cache first
        FeedbackAnalyticsService.DashboardData cachedData = 
            (FeedbackAnalyticsService.DashboardData) Cache.Org.get(CACHE_PARTITION + '.' + cacheKey);
        
        if (cachedData != null) {
            System.debug('Dashboard data retrieved from cache for user: ' + userId);
            return cachedData;
        }
        
        // If not in cache, generate and cache the data
        Datetime queryStart = System.now();
        
        // Optimized query with selective fields and proper indexing
        List<Interview_Feedback__c> feedbacks = [
            SELECT Id, Job_Application__c, Overall_Rating__c, Technical_Rating__c, 
                   Communication_Rating__c, Cultural_Fit_Rating__c, Interview_Type__c,
                   Interview_Date__c, CreatedDate,
                   (SELECT Id, Competency_Name__c, Rating__c 
                    FROM Competency_Ratings__r 
                    ORDER BY Competency_Name__c)
            FROM Interview_Feedback__c 
            WHERE CreatedById = :userId 
            AND CreatedDate = LAST_N_DAYS:90
            ORDER BY Interview_Date__c DESC 
            LIMIT :MAX_QUERY_RESULTS
        ];
        
        Datetime queryEnd = System.now();
        Long queryDuration = queryEnd.getTime() - queryStart.getTime();
        
        System.debug('Dashboard query executed in: ' + queryDuration + 'ms for ' + feedbacks.size() + ' records');
        
        // Generate dashboard data
        FeedbackAnalyticsService.DashboardData dashboardData = 
            FeedbackAnalyticsService.generateDashboardFromFeedbacks(feedbacks);
        
        // Add performance metrics
        dashboardData.queryPerformance = new Map<String, Object>{
            'query_duration_ms' => queryDuration,
            'records_processed' => feedbacks.size(),
            'cache_hit' => false,
            'generated_at' => System.now()
        };
        
        // Cache the result
        Cache.Org.put(CACHE_PARTITION + '.' + cacheKey, dashboardData, CACHE_TTL_HOURS * 3600);
        
        return dashboardData;
    }
    
    /**
     * @description Optimized bulk feedback processing with batching
     * @param feedbacks List of feedback records to process
     */
    public static void processFeedbacksBulkOptimized(List<Interview_Feedback__c> feedbacks) {
        if (feedbacks.isEmpty()) {
            return;
        }
        
        Datetime processStart = System.now();
        
        // Group feedbacks by Job Application for efficient processing
        Map<Id, List<Interview_Feedback__c>> feedbacksByJobApp = groupFeedbacksByJobApplication(feedbacks);
        
        // Process in batches to respect governor limits
        List<Id> jobAppIds = new List<Id>(feedbacksByJobApp.keySet());
        List<Job_Application__c> jobAppsToUpdate = new List<Job_Application__c>();
        
        for (Integer i = 0; i < jobAppIds.size(); i += BATCH_SIZE) {
            Integer endIndex = Math.min(i + BATCH_SIZE, jobAppIds.size());
            List<Id> batchJobAppIds = new List<Id>();
            
            for (Integer j = i; j < endIndex; j++) {
                batchJobAppIds.add(jobAppIds[j]);
            }
            
            // Process batch with optimized queries
            List<Job_Application__c> batchUpdates = processFeedbackBatch(batchJobAppIds, feedbacksByJobApp);
            jobAppsToUpdate.addAll(batchUpdates);
        }
        
        // Bulk update Job Applications
        if (!jobAppsToUpdate.isEmpty()) {
            Database.SaveResult[] updateResults = Database.update(jobAppsToUpdate, false);
            logBulkOperationResults(updateResults, 'Job Application Updates');
        }
        
        Datetime processEnd = System.now();
        Long processDuration = processEnd.getTime() - processStart.getTime();
        
        System.debug('Bulk feedback processing completed in: ' + processDuration + 'ms for ' + feedbacks.size() + ' records');
        
        // Clear related cache entries
        invalidateRelatedCache(feedbacksByJobApp.keySet());
    }
    
    /**
     * @description Optimized competency analysis with selective queries
     * @param jobApplicationId Job Application ID
     * @param daysPeriod Number of days to analyze
     * @return Competency analysis results
     */
    public static FeedbackAnalyticsService.CompetencyAnalysis getCompetencyAnalysisOptimized(
        Id jobApplicationId, Integer daysPeriod) {
        
        String cacheKey = 'competency_' + jobApplicationId + '_' + daysPeriod + '_' + Date.today().format();
        
        // Check cache first
        FeedbackAnalyticsService.CompetencyAnalysis cachedAnalysis = 
            (FeedbackAnalyticsService.CompetencyAnalysis) Cache.Org.get(CACHE_PARTITION + '.' + cacheKey);
        
        if (cachedAnalysis != null) {
            return cachedAnalysis;
        }
        
        Datetime queryStart = System.now();
        
        // Optimized query with date filtering and selective fields
        List<Interview_Feedback__c> feedbacks = [
            SELECT Id, Overall_Rating__c, Technical_Rating__c, Communication_Rating__c, 
                   Cultural_Fit_Rating__c, Interview_Type__c, Interview_Date__c,
                   (SELECT Id, Competency_Name__c, Rating__c, Comments__c 
                    FROM Competency_Ratings__r)
            FROM Interview_Feedback__c 
            WHERE Job_Application__c = :jobApplicationId 
            AND Interview_Date__c >= :Date.today().addDays(-daysPeriod)
            ORDER BY Interview_Date__c DESC
        ];
        
        Datetime queryEnd = System.now();
        Long queryDuration = queryEnd.getTime() - queryStart.getTime();
        
        // Generate analysis
        FeedbackAnalyticsService.CompetencyAnalysis analysis = 
            FeedbackAnalyticsService.analyzeCompetencies(feedbacks);
        
        // Add performance metrics
        analysis.performanceMetrics = new Map<String, Object>{
            'query_duration_ms' => queryDuration,
            'feedbacks_analyzed' => feedbacks.size(),
            'cache_hit' => false
        };
        
        // Cache the result
        Cache.Org.put(CACHE_PARTITION + '.' + cacheKey, analysis, CACHE_TTL_HOURS * 3600);
        
        return analysis;
    }
    
    /**
     * @description Optimized trend calculation with aggregation
     * @param jobApplicationId Job Application ID
     * @param daysPeriod Number of days for trend analysis
     * @return Performance trend data
     */
    public static FeedbackAnalyticsService.PerformanceTrend getTrendAnalysisOptimized(
        Id jobApplicationId, Integer daysPeriod) {
        
        String cacheKey = 'trend_' + jobApplicationId + '_' + daysPeriod + '_' + Date.today().format();
        
        // Check cache first
        FeedbackAnalyticsService.PerformanceTrend cachedTrend = 
            (FeedbackAnalyticsService.PerformanceTrend) Cache.Org.get(CACHE_PARTITION + '.' + cacheKey);
        
        if (cachedTrend != null) {
            return cachedTrend;
        }
        
        // Use aggregate query for better performance
        List<AggregateResult> trendData = [
            SELECT CALENDAR_WEEK(Interview_Date__c) week,
                   AVG(Overall_Rating__c) avgOverall,
                   AVG(Technical_Rating__c) avgTechnical,
                   AVG(Communication_Rating__c) avgCommunication,
                   COUNT(Id) feedbackCount
            FROM Interview_Feedback__c 
            WHERE Job_Application__c = :jobApplicationId 
            AND Interview_Date__c >= :Date.today().addDays(-daysPeriod)
            GROUP BY CALENDAR_WEEK(Interview_Date__c)
            ORDER BY CALENDAR_WEEK(Interview_Date__c)
        ];
        
        // Generate trend analysis from aggregated data
        FeedbackAnalyticsService.PerformanceTrend trend = 
            FeedbackAnalyticsService.generateTrendFromAggregates(trendData);
        
        // Cache the result
        Cache.Org.put(CACHE_PARTITION + '.' + cacheKey, trend, CACHE_TTL_HOURS * 3600);
        
        return trend;
    }
    
    /**
     * @description Optimized sharing data retrieval
     * @param feedbackIds List of feedback IDs
     * @return Map of feedback ID to sharing data
     */
    public static Map<Id, List<Feedback_Share__c>> getSharingDataOptimized(List<Id> feedbackIds) {
        if (feedbackIds.isEmpty()) {
            return new Map<Id, List<Feedback_Share__c>>();
        }
        
        // Use efficient query with proper indexing
        List<Feedback_Share__c> shares = [
            SELECT Id, Interview_Feedback__c, Shared_With_Email__c, Access_Level__c,
                   Expiration_Date__c, Is_Active__c, Access_Count__c
            FROM Feedback_Share__c 
            WHERE Interview_Feedback__c IN :feedbackIds 
            AND Is_Active__c = true 
            AND Expiration_Date__c > :System.now()
            ORDER BY Interview_Feedback__c, CreatedDate DESC
        ];
        
        // Group by feedback ID
        Map<Id, List<Feedback_Share__c>> sharesByFeedback = new Map<Id, List<Feedback_Share__c>>();
        
        for (Feedback_Share__c share : shares) {
            if (!sharesByFeedback.containsKey(share.Interview_Feedback__c)) {
                sharesByFeedback.put(share.Interview_Feedback__c, new List<Feedback_Share__c>());
            }
            sharesByFeedback.get(share.Interview_Feedback__c).add(share);
        }
        
        return sharesByFeedback;
    }
    
    /**
     * @description Monitor and log query performance
     * @param queryName Name of the query being monitored
     * @param startTime Query start time
     * @param recordCount Number of records processed
     */
    public static void logQueryPerformance(String queryName, Datetime startTime, Integer recordCount) {
        Long duration = System.now().getTime() - startTime.getTime();
        
        // Log performance metrics
        System.debug('Query Performance - ' + queryName + ': ' + duration + 'ms for ' + recordCount + ' records');
        
        // Create performance log record for monitoring
        try {
            Interview_Feedback_Performance_Log__c perfLog = new Interview_Feedback_Performance_Log__c(
                Query_Name__c = queryName,
                Duration_Ms__c = duration,
                Record_Count__c = recordCount,
                Execution_Date__c = System.now(),
                User_Id__c = UserInfo.getUserId()
            );
            
            Database.insert(perfLog, false);
        } catch (Exception e) {
            System.debug('Performance logging error: ' + e.getMessage());
        }
    }
    
    /**
     * @description Clear cache for specific keys
     * @param cacheKeys List of cache keys to clear
     */
    public static void clearCache(List<String> cacheKeys) {
        for (String key : cacheKeys) {
            Cache.Org.remove(CACHE_PARTITION + '.' + key);
        }
        System.debug('Cleared cache for ' + cacheKeys.size() + ' keys');
    }
    
    /**
     * @description Get cache statistics
     * @return Map of cache statistics
     */
    public static Map<String, Object> getCacheStatistics() {
        return new Map<String, Object>{
            'partition_name' => CACHE_PARTITION,
            'ttl_hours' => CACHE_TTL_HOURS,
            'max_query_results' => MAX_QUERY_RESULTS,
            'batch_size' => BATCH_SIZE,
            'cache_usage' => Cache.Org.getCapacity(),
            'available_capacity' => Cache.Org.getAvailableCapacity()
        };
    }
    
    // Private helper methods
    
    /**
     * @description Group feedbacks by Job Application for efficient processing
     */
    private static Map<Id, List<Interview_Feedback__c>> groupFeedbacksByJobApplication(
        List<Interview_Feedback__c> feedbacks) {
        
        Map<Id, List<Interview_Feedback__c>> feedbacksByJobApp = new Map<Id, List<Interview_Feedback__c>>();
        
        for (Interview_Feedback__c feedback : feedbacks) {
            if (!feedbacksByJobApp.containsKey(feedback.Job_Application__c)) {
                feedbacksByJobApp.put(feedback.Job_Application__c, new List<Interview_Feedback__c>());
            }
            feedbacksByJobApp.get(feedback.Job_Application__c).add(feedback);
        }
        
        return feedbacksByJobApp;
    }
    
    /**
     * @description Process a batch of Job Applications with their feedbacks
     */
    private static List<Job_Application__c> processFeedbackBatch(
        List<Id> jobAppIds, 
        Map<Id, List<Interview_Feedback__c>> feedbacksByJobApp) {
        
        // Get Job Applications with current values
        Map<Id, Job_Application__c> jobAppsMap = new Map<Id, Job_Application__c>([
            SELECT Id, Interview_Count__c, Average_Interview_Rating__c, 
                   Last_Interview_Date__c, Interview_Success_Rate__c
            FROM Job_Application__c 
            WHERE Id IN :jobAppIds
        ]);
        
        List<Job_Application__c> jobAppsToUpdate = new List<Job_Application__c>();
        
        for (Id jobAppId : jobAppIds) {
            Job_Application__c jobApp = jobAppsMap.get(jobAppId);
            List<Interview_Feedback__c> feedbacks = feedbacksByJobApp.get(jobAppId);
            
            if (jobApp != null && feedbacks != null && !feedbacks.isEmpty()) {
                // Calculate aggregates efficiently
                Decimal totalRating = 0;
                Date latestInterviewDate = null;
                Integer successfulInterviews = 0;
                
                for (Interview_Feedback__c feedback : feedbacks) {
                    if (feedback.Overall_Rating__c != null) {
                        totalRating += feedback.Overall_Rating__c;
                    }
                    
                    if (feedback.Interview_Date__c != null) {
                        Date feedbackDate = feedback.Interview_Date__c.date();
                        if (latestInterviewDate == null || feedbackDate > latestInterviewDate) {
                            latestInterviewDate = feedbackDate;
                        }
                    }
                    
                    if (feedback.Overall_Rating__c != null && feedback.Overall_Rating__c >= 4) {
                        successfulInterviews++;
                    }
                }
                
                // Update Job Application fields
                jobApp.Interview_Count__c = feedbacks.size();
                jobApp.Average_Interview_Rating__c = feedbacks.size() > 0 ? totalRating / feedbacks.size() : 0;
                jobApp.Last_Interview_Date__c = latestInterviewDate;
                jobApp.Interview_Success_Rate__c = feedbacks.size() > 0 ? 
                    (Decimal.valueOf(successfulInterviews) / feedbacks.size()) * 100 : 0;
                
                jobAppsToUpdate.add(jobApp);
            }
        }
        
        return jobAppsToUpdate;
    }
    
    /**
     * @description Log results of bulk operations
     */
    private static void logBulkOperationResults(Database.SaveResult[] results, String operationType) {
        Integer successCount = 0;
        Integer errorCount = 0;
        
        for (Database.SaveResult result : results) {
            if (result.isSuccess()) {
                successCount++;
            } else {
                errorCount++;
                for (Database.Error error : result.getErrors()) {
                    System.debug(operationType + ' Error: ' + error.getMessage());
                }
            }
        }
        
        System.debug(operationType + ' Results - Success: ' + successCount + ', Errors: ' + errorCount);
    }
    
    /**
     * @description Invalidate cache entries related to specific Job Applications
     */
    private static void invalidateRelatedCache(Set<Id> jobApplicationIds) {
        List<String> cacheKeysToInvalidate = new List<String>();
        
        for (Id jobAppId : jobApplicationIds) {
            // Invalidate dashboard cache for users who might have this data
            cacheKeysToInvalidate.add('dashboard_*'); // Wildcard pattern
            cacheKeysToInvalidate.add('competency_' + jobAppId + '_*');
            cacheKeysToInvalidate.add('trend_' + jobAppId + '_*');
        }
        
        // Clear cache entries (simplified - in real implementation would use pattern matching)
        for (String keyPattern : cacheKeysToInvalidate) {
            try {
                Cache.Org.remove(CACHE_PARTITION + '.' + keyPattern);
            } catch (Exception e) {
                System.debug('Cache invalidation error for pattern ' + keyPattern + ': ' + e.getMessage());
            }
        }
    }
    
    /**
     * @description Wrapper class for query performance metrics
     */
    public class QueryPerformanceMetrics {
        public Long queryDurationMs;
        public Integer recordsProcessed;
        public Boolean cacheHit;
        public Datetime executionTime;
        public String queryType;
        
        public QueryPerformanceMetrics(String queryType, Long duration, Integer records, Boolean cached) {
            this.queryType = queryType;
            this.queryDurationMs = duration;
            this.recordsProcessed = records;
            this.cacheHit = cached;
            this.executionTime = System.now();
        }
    }
}