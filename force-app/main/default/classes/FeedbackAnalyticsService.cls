/**
 * @description Advanced analytics service for Interview Feedback analysis
 * @author System Generated
 * @date 2025
 */
public with sharing class FeedbackAnalyticsService {
    
    // Constants for analytics calculations
    private static final Integer DEFAULT_TREND_PERIOD_DAYS = 90;
    private static final Integer MIN_FEEDBACK_FOR_TRENDS = 3;
    private static final Decimal IMPROVEMENT_THRESHOLD = 0.5;
    private static final Decimal DECLINE_THRESHOLD = -0.5;
    
    // Cache partition for performance optimization
    private static final String CACHE_PARTITION = 'FeedbackAnalytics';
    private static final Integer CACHE_TTL_SECONDS = 3600; // 1 hour
    
    /**
     * @description Calculates performance trends over time for a job application
     * @param jobApplicationId ID of the Job Application to analyze
     * @param daysPeriod Number of days to analyze (default 90)
     * @return PerformanceTrend Trend analysis results
     */
    public static PerformanceTrend calculatePerformanceTrends(Id jobApplicationId, Integer daysPeriod) {
        if (jobApplicationId == null) {
            throw new AnalyticsException('Job Application ID cannot be null');
        }
        
        Integer period = daysPeriod != null ? daysPeriod : DEFAULT_TREND_PERIOD_DAYS;
        String cacheKey = 'trends_' + jobApplicationId + '_' + period;
        
        // Check cache first
        PerformanceTrend cachedTrend = getCachedTrend(cacheKey);
        if (cachedTrend != null) {
            return cachedTrend;
        }
        
        // Query feedback data for the specified period
        Date startDate = Date.today().addDays(-period);
        List<Interview_Feedback__c> feedbackRecords = [
            SELECT Id, Overall_Rating__c, Technical_Rating__c, Communication_Rating__c,
                   Cultural_Fit_Rating__c, Interview_Date__c, Interview_Type__c,
                   CreatedDate
            FROM Interview_Feedback__c
            WHERE Job_Application__c = :jobApplicationId
            AND Feedback_Status__c = 'Submitted'
            AND CreatedDate >= :startDate
            ORDER BY CreatedDate ASC
        ];
        
        PerformanceTrend trend = analyzeTrendData(feedbackRecords);
        
        // Cache the result
        cacheTrend(cacheKey, trend);
        
        return trend;
    }
    
    /**
     * @description Analyzes competencies to identify strengths and improvement areas
     * @param jobApplicationId ID of the Job Application to analyze
     * @return CompetencyAnalysis Detailed competency analysis
     */
    public static CompetencyAnalysis analyzeCompetencies(Id jobApplicationId) {
        if (jobApplicationId == null) {
            throw new AnalyticsException('Job Application ID cannot be null');
        }
        
        String cacheKey = 'competency_' + jobApplicationId;
        CompetencyAnalysis cachedAnalysis = getCachedCompetencyAnalysis(cacheKey);
        if (cachedAnalysis != null) {
            return cachedAnalysis;
        }
        
        // Query feedback and competency ratings
        List<Interview_Feedback__c> feedbackRecords = [
            SELECT Id, Overall_Rating__c, Technical_Rating__c, Communication_Rating__c,
                   Cultural_Fit_Rating__c, Strengths__c, Areas_for_Improvement__c,
                   (SELECT Competency_Name__c, Rating__c, Comments__c, Weight__c 
                    FROM Competency_Ratings__r)
            FROM Interview_Feedback__c
            WHERE Job_Application__c = :jobApplicationId
            AND Feedback_Status__c = 'Submitted'
            ORDER BY CreatedDate DESC
        ];
        
        CompetencyAnalysis analysis = performCompetencyAnalysis(feedbackRecords);
        
        // Cache the result
        cacheCompetencyAnalysis(cacheKey, analysis);
        
        return analysis;
    }
    
    /**
     * @description Generates actionable recommendations based on feedback patterns
     * @param jobApplicationId ID of the Job Application to analyze
     * @return List<String> List of actionable recommendations
     */
    public static List<String> generateRecommendations(Id jobApplicationId) {
        if (jobApplicationId == null) {
            throw new AnalyticsException('Job Application ID cannot be null');
        }
        
        CompetencyAnalysis competencyAnalysis = analyzeCompetencies(jobApplicationId);
        PerformanceTrend performanceTrend = calculatePerformanceTrends(jobApplicationId, null);
        
        List<String> recommendations = new List<String>();
        
        // Generate recommendations based on competency analysis
        if (competencyAnalysis.weakestCompetencies != null && !competencyAnalysis.weakestCompetencies.isEmpty()) {
            for (CompetencyScore weakness : competencyAnalysis.weakestCompetencies) {
                if (weakness.averageScore < 3.0) {
                    recommendations.add('Focus on improving ' + weakness.competencyName + 
                                     ' skills. Current average: ' + weakness.averageScore.format() + '/5.0');
                }
            }
        }
        
        // Generate recommendations based on performance trends
        if (performanceTrend.trendDirection == 'Declining') {
            recommendations.add('Your interview performance has been declining. Consider practicing with mock interviews or seeking feedback from mentors.');
        } else if (performanceTrend.trendDirection == 'Improving') {
            recommendations.add('Great progress! Your interview performance is improving. Keep up the current preparation strategy.');
        }
        
        // Generate specific recommendations based on patterns
        if (competencyAnalysis.averageTechnicalRating != null && competencyAnalysis.averageTechnicalRating < 3.5) {
            recommendations.add('Consider strengthening technical skills through coding practice, system design study, or technical courses.');
        }
        
        if (competencyAnalysis.averageCommunicationRating != null && competencyAnalysis.averageCommunicationRating < 3.5) {
            recommendations.add('Work on communication skills through presentation practice, storytelling workshops, or public speaking groups.');
        }
        
        if (competencyAnalysis.averageCulturalFitRating != null && competencyAnalysis.averageCulturalFitRating < 3.5) {
            recommendations.add('Research company cultures more thoroughly and practice aligning your values with potential employers.');
        }
        
        // Add general recommendations if no specific issues found
        if (recommendations.isEmpty()) {
            recommendations.add('Your interview performance is solid. Continue practicing and consider expanding to more challenging interview types.');
        }
        
        return recommendations;
    }
    
    /**
     * @description Generates comprehensive dashboard data for performance visualization
     * @param userId User ID to generate dashboard data for
     * @return DashboardData Complete dashboard data structure
     */
    public static DashboardData generateDashboardData(Id userId) {
        if (userId == null) {
            throw new AnalyticsException('User ID cannot be null');
        }
        
        String cacheKey = 'dashboard_' + userId;
        DashboardData cachedData = getCachedDashboardData(cacheKey);
        if (cachedData != null) {
            return cachedData;
        }
        
        DashboardData dashboardData = new DashboardData();
        
        // Query all job applications for the user
        List<Job_Application__c> jobApplications = [
            SELECT Id, Position_Title__c, Company_Name__c, Status__c,
                   (SELECT Id, Overall_Rating__c, Technical_Rating__c, Communication_Rating__c,
                           Cultural_Fit_Rating__c, Interview_Date__c, Interview_Type__c,
                           Feedback_Status__c, CreatedDate
                    FROM Interview_Feedbacks__r
                    WHERE Feedback_Status__c = 'Submitted'
                    ORDER BY CreatedDate DESC)
            FROM Job_Application__c
            WHERE OwnerId = :userId
            AND Id IN (SELECT Job_Application__c FROM Interview_Feedback__c WHERE Feedback_Status__c = 'Submitted')
            ORDER BY CreatedDate DESC
        ];
        
        // Calculate overall statistics
        dashboardData.totalApplicationsWithFeedback = jobApplications.size();
        dashboardData.totalFeedbackRecords = 0;
        dashboardData.averageOverallRating = 0;
        
        List<Decimal> allRatings = new List<Decimal>();
        List<Interview_Feedback__c> allFeedback = new List<Interview_Feedback__c>();
        
        for (Job_Application__c jobApp : jobApplications) {
            dashboardData.totalFeedbackRecords += jobApp.Interview_Feedbacks__r.size();
            for (Interview_Feedback__c feedback : jobApp.Interview_Feedbacks__r) {
                if (feedback.Overall_Rating__c != null) {
                    allRatings.add(feedback.Overall_Rating__c);
                }
                allFeedback.add(feedback);
            }
        }
        
        if (!allRatings.isEmpty()) {
            Decimal sum = 0;
            for (Decimal rating : allRatings) {
                sum += rating;
            }
            dashboardData.averageOverallRating = sum / allRatings.size();
        }
        
        // Calculate success rate (ratings >= 4.0)
        Integer successfulInterviews = 0;
        for (Decimal rating : allRatings) {
            if (rating >= 4.0) {
                successfulInterviews++;
            }
        }
        dashboardData.successRate = allRatings.isEmpty() ? 0 : (successfulInterviews * 100.0) / allRatings.size();
        
        // Generate competency breakdown
        dashboardData.competencyBreakdown = generateCompetencyBreakdown(allFeedback);
        
        // Generate trend data for charts
        dashboardData.performanceTrendData = generateTrendChartData(allFeedback);
        
        // Generate recent activity
        dashboardData.recentFeedback = generateRecentActivity(allFeedback, 5);
        
        // Cache the result
        cacheDashboardData(cacheKey, dashboardData);
        
        return dashboardData;
    }
    
    /**
     * @description Analyzes trend data to determine performance direction
     * @param feedbackRecords List of feedback records to analyze
     * @return PerformanceTrend Trend analysis results
     */
    private static PerformanceTrend analyzeTrendData(List<Interview_Feedback__c> feedbackRecords) {
        PerformanceTrend trend = new PerformanceTrend();
        
        if (feedbackRecords.size() < MIN_FEEDBACK_FOR_TRENDS) {
            trend.trendDirection = 'Insufficient Data';
            trend.trendStrength = 0;
            trend.dataPoints = feedbackRecords.size();
            return trend;
        }
        
        // Calculate linear regression for trend analysis
        List<Decimal> ratings = new List<Decimal>();
        List<Integer> timePoints = new List<Integer>();
        
        for (Integer i = 0; i < feedbackRecords.size(); i++) {
            Interview_Feedback__c feedback = feedbackRecords[i];
            if (feedback.Overall_Rating__c != null) {
                ratings.add(feedback.Overall_Rating__c);
                timePoints.add(i);
            }
        }
        
        if (ratings.size() < 2) {
            trend.trendDirection = 'Insufficient Data';
            trend.trendStrength = 0;
            trend.dataPoints = ratings.size();
            return trend;
        }
        
        // Simple linear regression calculation
        Decimal slope = calculateSlope(timePoints, ratings);
        
        trend.dataPoints = ratings.size();
        trend.trendStrength = Math.abs(slope);
        
        if (slope > IMPROVEMENT_THRESHOLD) {
            trend.trendDirection = 'Improving';
        } else if (slope < DECLINE_THRESHOLD) {
            trend.trendDirection = 'Declining';
        } else {
            trend.trendDirection = 'Consistent';
        }
        
        // Calculate additional statistics
        trend.averageRating = calculateAverage(ratings);
        trend.latestRating = ratings[ratings.size() - 1];
        trend.earliestRating = ratings[0];
        
        return trend;
    }
    
    /**
     * @description Performs detailed competency analysis
     * @param feedbackRecords List of feedback records with competency ratings
     * @return CompetencyAnalysis Detailed analysis results
     */
    private static CompetencyAnalysis performCompetencyAnalysis(List<Interview_Feedback__c> feedbackRecords) {
        CompetencyAnalysis analysis = new CompetencyAnalysis();
        
        if (feedbackRecords.isEmpty()) {
            return analysis;
        }
        
        // Calculate average ratings for main competencies
        List<Decimal> technicalRatings = new List<Decimal>();
        List<Decimal> communicationRatings = new List<Decimal>();
        List<Decimal> culturalFitRatings = new List<Decimal>();
        
        Map<String, List<Decimal>> competencyRatings = new Map<String, List<Decimal>>();
        List<String> allStrengths = new List<String>();
        List<String> allImprovements = new List<String>();
        
        for (Interview_Feedback__c feedback : feedbackRecords) {
            if (feedback.Technical_Rating__c != null) {
                technicalRatings.add(feedback.Technical_Rating__c);
            }
            if (feedback.Communication_Rating__c != null) {
                communicationRatings.add(feedback.Communication_Rating__c);
            }
            if (feedback.Cultural_Fit_Rating__c != null) {
                culturalFitRatings.add(feedback.Cultural_Fit_Rating__c);
            }
            
            // Collect detailed competency ratings
            for (Competency_Rating__c competencyRating : feedback.Competency_Ratings__r) {
                String competencyName = competencyRating.Competency_Name__c;
                if (!competencyRatings.containsKey(competencyName)) {
                    competencyRatings.put(competencyName, new List<Decimal>());
                }
                if (competencyRating.Rating__c != null) {
                    competencyRatings.get(competencyName).add(competencyRating.Rating__c);
                }
            }
            
            // Collect qualitative feedback
            if (String.isNotBlank(feedback.Strengths__c)) {
                allStrengths.add(feedback.Strengths__c);
            }
            if (String.isNotBlank(feedback.Areas_for_Improvement__c)) {
                allImprovements.add(feedback.Areas_for_Improvement__c);
            }
        }
        
        // Calculate averages
        analysis.averageTechnicalRating = calculateAverage(technicalRatings);
        analysis.averageCommunicationRating = calculateAverage(communicationRatings);
        analysis.averageCulturalFitRating = calculateAverage(culturalFitRatings);
        
        // Analyze detailed competencies
        analysis.strongestCompetencies = new List<CompetencyScore>();
        analysis.weakestCompetencies = new List<CompetencyScore>();
        
        for (String competencyName : competencyRatings.keySet()) {
            List<Decimal> ratings = competencyRatings.get(competencyName);
            Decimal average = calculateAverage(ratings);
            
            CompetencyScore score = new CompetencyScore();
            score.competencyName = competencyName;
            score.averageScore = average;
            score.feedbackCount = ratings.size();
            
            if (average >= 4.0) {
                analysis.strongestCompetencies.add(score);
            } else if (average <= 2.5) {
                analysis.weakestCompetencies.add(score);
            }
        }
        
        // Sort competencies by score
        analysis.strongestCompetencies.sort();
        analysis.weakestCompetencies.sort();
        
        // Analyze qualitative patterns
        analysis.commonStrengths = analyzeTextPatterns(allStrengths);
        analysis.commonImprovementAreas = analyzeTextPatterns(allImprovements);
        
        return analysis;
    }
    
    /**
     * @description Calculates slope for linear regression
     * @param xValues X coordinates (time points)
     * @param yValues Y coordinates (ratings)
     * @return Decimal Slope of the trend line
     */
    private static Decimal calculateSlope(List<Integer> xValues, List<Decimal> yValues) {
        if (xValues.size() != yValues.size() || xValues.size() < 2) {
            return 0;
        }
        
        Integer n = xValues.size();
        Decimal sumX = 0, sumY = 0, sumXY = 0, sumXX = 0;
        
        for (Integer i = 0; i < n; i++) {
            sumX += xValues[i];
            sumY += yValues[i];
            sumXY += xValues[i] * yValues[i];
            sumXX += xValues[i] * xValues[i];
        }
        
        Decimal denominator = n * sumXX - sumX * sumX;
        if (denominator == 0) {
            return 0;
        }
        
        return (n * sumXY - sumX * sumY) / denominator;
    }
    
    /**
     * @description Calculates average of decimal values
     * @param values List of decimal values
     * @return Decimal Average value or null if empty
     */
    private static Decimal calculateAverage(List<Decimal> values) {
        if (values.isEmpty()) {
            return null;
        }
        
        Decimal sum = 0;
        for (Decimal value : values) {
            sum += value;
        }
        
        return sum / values.size();
    }
    
    /**
     * @description Analyzes text patterns to identify common themes
     * @param textList List of text strings to analyze
     * @return List<String> Common patterns found
     */
    private static List<String> analyzeTextPatterns(List<String> textList) {
        Map<String, Integer> wordCount = new Map<String, Integer>();
        
        for (String text : textList) {
            if (String.isNotBlank(text)) {
                List<String> words = text.toLowerCase().split('\\W+');
                for (String word : words) {
                    if (word.length() > 3) { // Only consider meaningful words
                        Integer count = wordCount.get(word);
                        wordCount.put(word, count == null ? 1 : count + 1);
                    }
                }
            }
        }
        
        // Return most common words (appearing more than once)
        List<String> commonPatterns = new List<String>();
        for (String word : wordCount.keySet()) {
            if (wordCount.get(word) > 1) {
                commonPatterns.add(word + ' (' + wordCount.get(word) + ' mentions)');
            }
        }
        
        return commonPatterns;
    }
    
    /**
     * @description Generates competency breakdown for dashboard
     * @param feedbackRecords All feedback records
     * @return Map<String, Decimal> Competency averages
     */
    private static Map<String, Decimal> generateCompetencyBreakdown(List<Interview_Feedback__c> feedbackRecords) {
        Map<String, Decimal> breakdown = new Map<String, Decimal>();
        
        List<Decimal> technicalRatings = new List<Decimal>();
        List<Decimal> communicationRatings = new List<Decimal>();
        List<Decimal> culturalFitRatings = new List<Decimal>();
        
        for (Interview_Feedback__c feedback : feedbackRecords) {
            if (feedback.Technical_Rating__c != null) {
                technicalRatings.add(feedback.Technical_Rating__c);
            }
            if (feedback.Communication_Rating__c != null) {
                communicationRatings.add(feedback.Communication_Rating__c);
            }
            if (feedback.Cultural_Fit_Rating__c != null) {
                culturalFitRatings.add(feedback.Cultural_Fit_Rating__c);
            }
        }
        
        if (!technicalRatings.isEmpty()) {
            breakdown.put('Technical', calculateAverage(technicalRatings));
        }
        if (!communicationRatings.isEmpty()) {
            breakdown.put('Communication', calculateAverage(communicationRatings));
        }
        if (!culturalFitRatings.isEmpty()) {
            breakdown.put('Cultural Fit', calculateAverage(culturalFitRatings));
        }
        
        return breakdown;
    }
    
    /**
     * @description Generates trend chart data for visualization
     * @param feedbackRecords All feedback records
     * @return List<ChartDataPoint> Chart data points
     */
    private static List<ChartDataPoint> generateTrendChartData(List<Interview_Feedback__c> feedbackRecords) {
        List<ChartDataPoint> chartData = new List<ChartDataPoint>();
        
        // Sort by date
        feedbackRecords.sort(new FeedbackDateComparator());
        
        for (Interview_Feedback__c feedback : feedbackRecords) {
            if (feedback.Overall_Rating__c != null) {
                ChartDataPoint point = new ChartDataPoint();
                point.label = feedback.Interview_Date__c != null ? 
                    feedback.Interview_Date__c.format('MM/dd') : 
                    feedback.CreatedDate.format('MM/dd');
                point.value = feedback.Overall_Rating__c;
                chartData.add(point);
            }
        }
        
        return chartData;
    }
    
    /**
     * @description Generates recent activity summary
     * @param feedbackRecords All feedback records
     * @param maxRecords Maximum number of recent records to return
     * @return List<RecentActivity> Recent activity items
     */
    private static List<RecentActivity> generateRecentActivity(List<Interview_Feedback__c> feedbackRecords, Integer maxRecords) {
        List<RecentActivity> recentActivity = new List<RecentActivity>();
        
        // Sort by creation date descending
        feedbackRecords.sort(new FeedbackCreatedDateComparator());
        
        Integer count = 0;
        for (Interview_Feedback__c feedback : feedbackRecords) {
            if (count >= maxRecords) break;
            
            RecentActivity activity = new RecentActivity();
            activity.feedbackId = feedback.Id;
            activity.interviewType = feedback.Interview_Type__c;
            activity.rating = feedback.Overall_Rating__c;
            activity.date = feedback.CreatedDate;
            
            recentActivity.add(activity);
            count++;
        }
        
        return recentActivity;
    }
    
    // Cache helper methods
    private static PerformanceTrend getCachedTrend(String cacheKey) {
        try {
            return (PerformanceTrend) Cache.Org.get(CACHE_PARTITION + '.' + cacheKey);
        } catch (Exception e) {
            return null;
        }
    }
    
    private static void cacheTrend(String cacheKey, PerformanceTrend trend) {
        try {
            Cache.Org.put(CACHE_PARTITION + '.' + cacheKey, trend, CACHE_TTL_SECONDS);
        } catch (Exception e) {
            // Cache failure should not break functionality
            System.debug('Cache put failed: ' + e.getMessage());
        }
    }
    
    private static CompetencyAnalysis getCachedCompetencyAnalysis(String cacheKey) {
        try {
            return (CompetencyAnalysis) Cache.Org.get(CACHE_PARTITION + '.' + cacheKey);
        } catch (Exception e) {
            return null;
        }
    }
    
    private static void cacheCompetencyAnalysis(String cacheKey, CompetencyAnalysis analysis) {
        try {
            Cache.Org.put(CACHE_PARTITION + '.' + cacheKey, analysis, CACHE_TTL_SECONDS);
        } catch (Exception e) {
            System.debug('Cache put failed: ' + e.getMessage());
        }
    }
    
    private static DashboardData getCachedDashboardData(String cacheKey) {
        try {
            return (DashboardData) Cache.Org.get(CACHE_PARTITION + '.' + cacheKey);
        } catch (Exception e) {
            return null;
        }
    }
    
    private static void cacheDashboardData(String cacheKey, DashboardData data) {
        try {
            Cache.Org.put(CACHE_PARTITION + '.' + cacheKey, data, CACHE_TTL_SECONDS);
        } catch (Exception e) {
            System.debug('Cache put failed: ' + e.getMessage());
        }
    }
    
    /**
     * @description Custom exception for analytics errors
     */
    public class AnalyticsException extends Exception {}
    
    /**
     * @description Wrapper class for performance trend analysis
     */
    public class PerformanceTrend {
        public String trendDirection { get; set; }
        public Decimal trendStrength { get; set; }
        public Integer dataPoints { get; set; }
        public Decimal averageRating { get; set; }
        public Decimal latestRating { get; set; }
        public Decimal earliestRating { get; set; }
        
        public PerformanceTrend() {
            this.dataPoints = 0;
        }
    }
    
    /**
     * @description Wrapper class for competency analysis
     */
    public class CompetencyAnalysis {
        public Decimal averageTechnicalRating { get; set; }
        public Decimal averageCommunicationRating { get; set; }
        public Decimal averageCulturalFitRating { get; set; }
        public List<CompetencyScore> strongestCompetencies { get; set; }
        public List<CompetencyScore> weakestCompetencies { get; set; }
        public List<String> commonStrengths { get; set; }
        public List<String> commonImprovementAreas { get; set; }
        
        public CompetencyAnalysis() {
            this.strongestCompetencies = new List<CompetencyScore>();
            this.weakestCompetencies = new List<CompetencyScore>();
            this.commonStrengths = new List<String>();
            this.commonImprovementAreas = new List<String>();
        }
    }
    
    /**
     * @description Wrapper class for individual competency scores
     */
    public class CompetencyScore implements Comparable {
        public String competencyName { get; set; }
        public Decimal averageScore { get; set; }
        public Integer feedbackCount { get; set; }
        
        public Integer compareTo(Object compareTo) {
            CompetencyScore compareToScore = (CompetencyScore) compareTo;
            if (averageScore == compareToScore.averageScore) return 0;
            if (averageScore > compareToScore.averageScore) return -1;
            return 1;
        }
    }
    
    /**
     * @description Wrapper class for dashboard data
     */
    public class DashboardData {
        public Integer totalApplicationsWithFeedback { get; set; }
        public Integer totalFeedbackRecords { get; set; }
        public Decimal averageOverallRating { get; set; }
        public Decimal successRate { get; set; }
        public Map<String, Decimal> competencyBreakdown { get; set; }
        public List<ChartDataPoint> performanceTrendData { get; set; }
        public List<RecentActivity> recentFeedback { get; set; }
        
        public DashboardData() {
            this.totalApplicationsWithFeedback = 0;
            this.totalFeedbackRecords = 0;
            this.averageOverallRating = 0;
            this.successRate = 0;
            this.competencyBreakdown = new Map<String, Decimal>();
            this.performanceTrendData = new List<ChartDataPoint>();
            this.recentFeedback = new List<RecentActivity>();
        }
    }
    
    /**
     * @description Chart data point for visualizations
     */
    public class ChartDataPoint {
        public String label { get; set; }
        public Decimal value { get; set; }
    }
    
    /**
     * @description Recent activity item
     */
    public class RecentActivity {
        public Id feedbackId { get; set; }
        public String interviewType { get; set; }
        public Decimal rating { get; set; }
        public DateTime date { get; set; }
    }
    
    /**
     * @description Comparator for sorting feedback by date
     */
    public class FeedbackDateComparator implements Comparator<Interview_Feedback__c> {
        public Integer compare(Interview_Feedback__c f1, Interview_Feedback__c f2) {
            Date date1 = f1.Interview_Date__c != null ? f1.Interview_Date__c : f1.CreatedDate.date();
            Date date2 = f2.Interview_Date__c != null ? f2.Interview_Date__c : f2.CreatedDate.date();
            
            if (date1 == date2) return 0;
            if (date1 > date2) return 1;
            return -1;
        }
    }
    
    /**
     * @description Comparator for sorting feedback by creation date descending
     */
    public class FeedbackCreatedDateComparator implements Comparator<Interview_Feedback__c> {
        public Integer compare(Interview_Feedback__c f1, Interview_Feedback__c f2) {
            if (f1.CreatedDate == f2.CreatedDate) return 0;
            if (f1.CreatedDate > f2.CreatedDate) return -1;
            return 1;
        }
    }
}