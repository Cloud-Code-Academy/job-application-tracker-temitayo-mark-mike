/**
 * @description Advanced analytics service for interview feedback reporting and predictive analysis
 * Provides statistical analysis, trend significance, and benchmark comparisons
 * @author Temitayo Oluwalade
 * @date 2024
 */
public with sharing class InterviewAnalyticsService {
    
    /**
     * @description Generates comprehensive analytics report for a date range
     * @param startDate Start date for analysis
     * @param endDate End date for analysis
     * @param userId Optional user ID to filter results
     * @return AnalyticsReport containing all metrics and insights
     */
    public static AnalyticsReport generateComprehensiveReport(Date startDate, Date endDate, Id userId) {
        AnalyticsReport report = new AnalyticsReport();
        
        // Build base query conditions
        String whereClause = 'Interview_Date__c >= :startDate AND Interview_Date__c <= :endDate';
        Map<String, Object> bindVars = new Map<String, Object>{
            'startDate' => DateTime.newInstance(startDate, Time.newInstance(0, 0, 0, 0)),
            'endDate' => DateTime.newInstance(endDate, Time.newInstance(23, 59, 59, 999))
        };
        
        if (userId != null) {
            whereClause += ' AND CreatedById = :userId';
            bindVars.put('userId', userId);
        }
        
        // Get all feedback data for the period
        String query = 'SELECT Id, Job_Application__c, Interview_Type__c, Overall_Rating__c, ' +
                      'Interview_Date__c, Job_Application__r.Position_Title__c, ' +
                      'Job_Application__r.Company_Name__c, Job_Application__r.Status__c, ' +
                      'Job_Application__r.Salary__c, ' +
                      '(SELECT Id, Competency_Name__c, Rating__c FROM Competency_Ratings__r) ' +
                      'FROM Interview_Feedback__c WHERE ' + whereClause + ' ORDER BY Interview_Date__c';
        
        List<Interview_Feedback__c> feedbackData = Database.query(query);
        
        // Calculate basic metrics
        report.basicMetrics = calculateBasicMetrics(feedbackData);
        
        // Perform statistical analysis
        report.statisticalAnalysis = performStatisticalAnalysis(feedbackData);
        
        // Calculate trend significance
        report.trendAnalysis = calculateTrendSignificance(feedbackData);
        
        // Generate benchmark comparisons
        report.benchmarkComparison = generateBenchmarkComparison(feedbackData);
        
        // Calculate predictive analytics
        report.predictiveAnalytics = calculatePredictiveAnalytics(feedbackData);
        
        // Generate insights and recommendations
        report.insights = generateInsights(report);
        
        return report;
    }
    
    /**
     * @description Calculates basic metrics from feedback data
     * @param feedbackData List of interview feedback records
     * @return BasicMetrics object
     */
    private static BasicMetrics calculateBasicMetrics(List<Interview_Feedback__c> feedbackData) {
        BasicMetrics metrics = new BasicMetrics();
        
        if (feedbackData.isEmpty()) {
            return metrics;
        }
        
        Decimal totalRating = 0;
        Integer ratingCount = 0;
        Map<String, Integer> typeCount = new Map<String, Integer>();
        Map<String, Decimal> typeRatingSum = new Map<String, Decimal>();
        Set<Id> uniqueJobApps = new Set<Id>();
        
        for (Interview_Feedback__c feedback : feedbackData) {
            if (feedback.Overall_Rating__c != null) {
                totalRating += feedback.Overall_Rating__c;
                ratingCount++;
            }
            
            String type = feedback.Interview_Type__c;
            if (String.isNotBlank(type)) {
                typeCount.put(type, typeCount.containsKey(type) ? typeCount.get(type) + 1 : 1);
                if (feedback.Overall_Rating__c != null) {
                    typeRatingSum.put(type, typeRatingSum.containsKey(type) ? 
                                     typeRatingSum.get(type) + feedback.Overall_Rating__c : 
                                     feedback.Overall_Rating__c);
                }
            }
            
            if (feedback.Job_Application__c != null) {
                uniqueJobApps.add(feedback.Job_Application__c);
            }
        }
        
        metrics.totalInterviews = feedbackData.size();
        metrics.averageRating = ratingCount > 0 ? (totalRating / ratingCount).setScale(2) : 0;
        metrics.uniqueJobApplications = uniqueJobApps.size();
        
        // Calculate type-specific metrics
        metrics.interviewTypeMetrics = new List<InterviewTypeMetric>();
        for (String type : typeCount.keySet()) {
            InterviewTypeMetric typeMetric = new InterviewTypeMetric();
            typeMetric.interviewType = type;
            typeMetric.count = typeCount.get(type);
            typeMetric.averageRating = typeRatingSum.containsKey(type) ? 
                                     (typeRatingSum.get(type) / typeCount.get(type)).setScale(2) : 0;
            metrics.interviewTypeMetrics.add(typeMetric);
        }
        
        return metrics;
    }
    
    /**
     * @description Performs statistical analysis on feedback data
     * @param feedbackData List of interview feedback records
     * @return StatisticalAnalysis object
     */
    private static StatisticalAnalysis performStatisticalAnalysis(List<Interview_Feedback__c> feedbackData) {
        StatisticalAnalysis analysis = new StatisticalAnalysis();
        
        if (feedbackData.isEmpty()) {
            return analysis;
        }
        
        List<Decimal> ratings = new List<Decimal>();
        for (Interview_Feedback__c feedback : feedbackData) {
            if (feedback.Overall_Rating__c != null) {
                ratings.add(feedback.Overall_Rating__c);
            }
        }
        
        if (ratings.isEmpty()) {
            return analysis;
        }
        
        // Sort ratings for median calculation
        ratings.sort();
        
        // Calculate mean
        Decimal sum = 0;
        for (Decimal rating : ratings) {
            sum += rating;
        }
        analysis.mean = (sum / ratings.size()).setScale(2);
        
        // Calculate median
        Integer size = ratings.size();
        if (Math.mod(size, 2) == 0) {
            analysis.median = ((ratings[size/2 - 1] + ratings[size/2]) / 2).setScale(2);
        } else {
            analysis.median = ratings[size/2];
        }
        
        // Calculate mode
        Map<Decimal, Integer> frequency = new Map<Decimal, Integer>();
        for (Decimal rating : ratings) {
            frequency.put(rating, frequency.containsKey(rating) ? frequency.get(rating) + 1 : 1);
        }
        
        Integer maxFreq = 0;
        for (Decimal rating : frequency.keySet()) {
            if (frequency.get(rating) > maxFreq) {
                maxFreq = frequency.get(rating);
                analysis.mode = rating;
            }
        }
        
        // Calculate standard deviation
        Decimal variance = 0;
        for (Decimal rating : ratings) {
            variance += Math.pow(rating - analysis.mean, 2);
        }
        variance = variance / ratings.size();
        analysis.standardDeviation = Math.sqrt(variance).setScale(2);
        
        // Calculate confidence intervals (95%)
        Decimal marginOfError = 1.96 * (analysis.standardDeviation / Math.sqrt(ratings.size()));
        analysis.confidenceInterval95Lower = (analysis.mean - marginOfError).setScale(2);
        analysis.confidenceInterval95Upper = (analysis.mean + marginOfError).setScale(2);
        
        return analysis;
    }
    
    /**
     * @description Calculates trend significance over time
     * @param feedbackData List of interview feedback records
     * @return TrendAnalysis object
     */
    private static TrendAnalysis calculateTrendSignificance(List<Interview_Feedback__c> feedbackData) {
        TrendAnalysis trend = new TrendAnalysis();
        
        if (feedbackData.size() < 3) {
            trend.trendDirection = 'Insufficient Data';
            return trend;
        }
        
        // Group by month for trend analysis
        Map<String, List<Decimal>> monthlyRatings = new Map<String, List<Decimal>>();
        
        for (Interview_Feedback__c feedback : feedbackData) {
            if (feedback.Overall_Rating__c != null && feedback.Interview_Date__c != null) {
                String monthKey = feedback.Interview_Date__c.format('yyyy-MM');
                if (!monthlyRatings.containsKey(monthKey)) {
                    monthlyRatings.put(monthKey, new List<Decimal>());
                }
                monthlyRatings.get(monthKey).add(feedback.Overall_Rating__c);
            }
        }
        
        // Calculate monthly averages
        List<String> months = new List<String>(monthlyRatings.keySet());
        months.sort();
        
        List<Decimal> monthlyAverages = new List<Decimal>();
        for (String month : months) {
            Decimal sum = 0;
            for (Decimal rating : monthlyRatings.get(month)) {
                sum += rating;
            }
            monthlyAverages.add(sum / monthlyRatings.get(month).size());
        }
        
        // Calculate linear regression for trend
        if (monthlyAverages.size() >= 2) {
            Decimal slope = calculateSlope(monthlyAverages);
            trend.slope = slope.setScale(4);
            
            if (Math.abs(slope) < 0.01) {
                trend.trendDirection = 'Stable';
            } else if (slope > 0) {
                trend.trendDirection = 'Improving';
            } else {
                trend.trendDirection = 'Declining';
            }
            
            // Calculate R-squared for trend strength
            trend.rSquared = calculateRSquared(monthlyAverages).setScale(4);
            
            if (trend.rSquared > 0.7) {
                trend.trendStrength = 'Strong';
            } else if (trend.rSquared > 0.3) {
                trend.trendStrength = 'Moderate';
            } else {
                trend.trendStrength = 'Weak';
            }
        }
        
        return trend;
    }
    
    /**
     * @description Generates benchmark comparison against industry standards
     * @param feedbackData List of interview feedback records
     * @return BenchmarkComparison object
     */
    private static BenchmarkComparison generateBenchmarkComparison(List<Interview_Feedback__c> feedbackData) {
        BenchmarkComparison benchmark = new BenchmarkComparison();
        
        // Industry benchmarks (these would typically come from external data)
        Map<String, Decimal> industryBenchmarks = new Map<String, Decimal>{
            'Technical' => 3.6,
            'Behavioral' => 3.8,
            'System Design' => 3.4,
            'Cultural Fit' => 4.0,
            'Final Round' => 3.9
        };
        
        // Calculate user performance by interview type
        Map<String, List<Decimal>> userPerformance = new Map<String, List<Decimal>>();
        
        for (Interview_Feedback__c feedback : feedbackData) {
            if (feedback.Overall_Rating__c != null && String.isNotBlank(feedback.Interview_Type__c)) {
                String type = feedback.Interview_Type__c;
                if (!userPerformance.containsKey(type)) {
                    userPerformance.put(type, new List<Decimal>());
                }
                userPerformance.get(type).add(feedback.Overall_Rating__c);
            }
        }
        
        // Generate comparisons
        benchmark.comparisons = new List<BenchmarkComparison.TypeComparison>();
        
        for (String type : userPerformance.keySet()) {
            BenchmarkComparison.TypeComparison comparison = new BenchmarkComparison.TypeComparison();
            comparison.interviewType = type;
            
            // Calculate user average
            Decimal sum = 0;
            for (Decimal rating : userPerformance.get(type)) {
                sum += rating;
            }
            comparison.userAverage = (sum / userPerformance.get(type).size()).setScale(2);
            
            // Get industry benchmark
            comparison.industryBenchmark = industryBenchmarks.containsKey(type) ? 
                                         industryBenchmarks.get(type) : 3.5;
            
            // Calculate difference
            comparison.difference = (comparison.userAverage - comparison.industryBenchmark).setScale(2);
            
            // Determine performance level
            if (comparison.difference >= 0.5) {
                comparison.performanceLevel = 'Excellent';
            } else if (comparison.difference >= 0.2) {
                comparison.performanceLevel = 'Above Average';
            } else if (comparison.difference >= -0.2) {
                comparison.performanceLevel = 'Average';
            } else {
                comparison.performanceLevel = 'Below Average';
            }
            
            benchmark.comparisons.add(comparison);
        }
        
        return benchmark;
    }
    
    /**
     * @description Calculates predictive analytics for interview success
     * @param feedbackData List of interview feedback records
     * @return PredictiveAnalytics object
     */
    private static PredictiveAnalytics calculatePredictiveAnalytics(List<Interview_Feedback__c> feedbackData) {
        PredictiveAnalytics prediction = new PredictiveAnalytics();
        
        if (feedbackData.isEmpty()) {
            return prediction;
        }
        
        // Analyze success patterns
        Integer totalInterviews = 0;
        Integer successfulInterviews = 0;
        Map<String, Integer> typeSuccessCount = new Map<String, Integer>();
        Map<String, Integer> typeTotalCount = new Map<String, Integer>();
        
        for (Interview_Feedback__c feedback : feedbackData) {
            if (feedback.Overall_Rating__c != null) {
                totalInterviews++;
                
                String type = feedback.Interview_Type__c;
                if (String.isNotBlank(type)) {
                    typeTotalCount.put(type, typeTotalCount.containsKey(type) ? 
                                      typeTotalCount.get(type) + 1 : 1);
                }
                
                // Consider rating >= 4.0 as successful
                if (feedback.Overall_Rating__c >= 4.0) {
                    successfulInterviews++;
                    
                    if (String.isNotBlank(type)) {
                        typeSuccessCount.put(type, typeSuccessCount.containsKey(type) ? 
                                           typeSuccessCount.get(type) + 1 : 1);
                    }
                }
            }
        }
        
        // Calculate overall success probability
        prediction.overallSuccessProbability = totalInterviews > 0 ? 
            ((Decimal)successfulInterviews / totalInterviews * 100).setScale(1) : 0;
        
        // Calculate type-specific success probabilities
        prediction.typeSuccessProbabilities = new List<PredictiveAnalytics.TypeProbability>();
        
        for (String type : typeTotalCount.keySet()) {
            PredictiveAnalytics.TypeProbability typeProb = new PredictiveAnalytics.TypeProbability();
            typeProb.interviewType = type;
            typeProb.successProbability = typeSuccessCount.containsKey(type) ? 
                ((Decimal)typeSuccessCount.get(type) / typeTotalCount.get(type) * 100).setScale(1) : 0;
            typeProb.sampleSize = typeTotalCount.get(type);
            
            prediction.typeSuccessProbabilities.add(typeProb);
        }
        
        // Generate success factors
        prediction.successFactors = generateSuccessFactors(feedbackData);
        
        return prediction;
    }
    
    /**
     * @description Generates insights based on analytics results
     * @param report Complete analytics report
     * @return List of insights
     */
    private static List<String> generateInsights(AnalyticsReport report) {
        List<String> insights = new List<String>();
        
        // Performance insights
        if (report.basicMetrics.averageRating >= 4.0) {
            insights.add('Excellent overall performance with ' + report.basicMetrics.averageRating + '/5.0 average rating');
        } else if (report.basicMetrics.averageRating <= 3.0) {
            insights.add('Performance below average - focus on improvement areas');
        }
        
        // Trend insights
        if (report.trendAnalysis.trendDirection == 'Improving' && report.trendAnalysis.trendStrength == 'Strong') {
            insights.add('Strong upward trend detected - performance is consistently improving');
        } else if (report.trendAnalysis.trendDirection == 'Declining') {
            insights.add('Declining trend detected - review recent feedback for improvement areas');
        }
        
        // Benchmark insights
        if (report.benchmarkComparison.comparisons != null) {
            for (BenchmarkComparison.TypeComparison comp : report.benchmarkComparison.comparisons) {
                if (comp.performanceLevel == 'Excellent') {
                    insights.add(comp.interviewType + ' interviews: Excellent performance, ' + 
                               comp.difference + ' points above industry average');
                } else if (comp.performanceLevel == 'Below Average') {
                    insights.add(comp.interviewType + ' interviews: Below industry average, ' + 
                               'focus on improvement');
                }
            }
        }
        
        // Predictive insights
        if (report.predictiveAnalytics.overallSuccessProbability >= 70) {
            insights.add('High success probability (' + report.predictiveAnalytics.overallSuccessProbability + 
                        '%) - strong interview performance pattern');
        }
        
        return insights;
    }
    
    // Helper methods for statistical calculations
    private static Decimal calculateSlope(List<Decimal> values) {
        if (values.size() < 2) return 0;
        
        Decimal n = values.size();
        Decimal sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
        
        for (Integer i = 0; i < values.size(); i++) {
            Decimal x = i + 1;
            Decimal y = values[i];
            sumX += x;
            sumY += y;
            sumXY += x * y;
            sumX2 += x * x;
        }
        
        return (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    }
    
    private static Decimal calculateRSquared(List<Decimal> values) {
        if (values.size() < 2) return 0;
        
        Decimal slope = calculateSlope(values);
        Decimal mean = 0;
        for (Decimal value : values) {
            mean += value;
        }
        mean = mean / values.size();
        
        Decimal ssRes = 0, ssTot = 0;
        for (Integer i = 0; i < values.size(); i++) {
            Decimal predicted = slope * (i + 1) + (mean - slope * (values.size() + 1) / 2);
            ssRes += Math.pow(values[i] - predicted, 2);
            ssTot += Math.pow(values[i] - mean, 2);
        }
        
        return ssTot != 0 ? 1 - (ssRes / ssTot) : 0;
    }
    
    private static List<String> generateSuccessFactors(List<Interview_Feedback__c> feedbackData) {
        List<String> factors = new List<String>();
        
        // Analyze competency ratings for successful interviews
        Map<String, List<Decimal>> competencyRatings = new Map<String, List<Decimal>>();
        
        for (Interview_Feedback__c feedback : feedbackData) {
            if (feedback.Overall_Rating__c >= 4.0 && feedback.Competency_Ratings__r != null) {
                for (Competency_Rating__c rating : feedback.Competency_Ratings__r) {
                    String competency = rating.Competency_Name__c;
                    if (!competencyRatings.containsKey(competency)) {
                        competencyRatings.put(competency, new List<Decimal>());
                    }
                    competencyRatings.get(competency).add(rating.Rating__c);
                }
            }
        }
        
        // Identify top competencies
        for (String competency : competencyRatings.keySet()) {
            Decimal sum = 0;
            for (Decimal rating : competencyRatings.get(competency)) {
                sum += rating;
            }
            Decimal average = sum / competencyRatings.get(competency).size();
            
            if (average >= 4.0) {
                factors.add(competency + ' (avg: ' + average.setScale(1) + '/5.0)');
            }
        }
        
        return factors;
    }
    
    // Data classes for analytics results
    public class AnalyticsReport {
        public BasicMetrics basicMetrics;
        public StatisticalAnalysis statisticalAnalysis;
        public TrendAnalysis trendAnalysis;
        public BenchmarkComparison benchmarkComparison;
        public PredictiveAnalytics predictiveAnalytics;
        public List<String> insights;
    }
    
    public class BasicMetrics {
        public Integer totalInterviews = 0;
        public Decimal averageRating = 0;
        public Integer uniqueJobApplications = 0;
        public List<InterviewTypeMetric> interviewTypeMetrics;
    }
    
    public class InterviewTypeMetric {
        public String interviewType;
        public Integer count;
        public Decimal averageRating;
    }
    
    public class StatisticalAnalysis {
        public Decimal mean;
        public Decimal median;
        public Decimal mode;
        public Decimal standardDeviation;
        public Decimal confidenceInterval95Lower;
        public Decimal confidenceInterval95Upper;
    }
    
    public class TrendAnalysis {
        public String trendDirection;
        public String trendStrength;
        public Decimal slope;
        public Decimal rSquared;
    }
    
    public class BenchmarkComparison {
        public List<TypeComparison> comparisons;
        
        public class TypeComparison {
            public String interviewType;
            public Decimal userAverage;
            public Decimal industryBenchmark;
            public Decimal difference;
            public String performanceLevel;
        }
    }
    
    public class PredictiveAnalytics {
        public Decimal overallSuccessProbability;
        public List<TypeProbability> typeSuccessProbabilities;
        public List<String> successFactors;
        
        public class TypeProbability {
            public String interviewType;
            public Decimal successProbability;
            public Integer sampleSize;
        }
    }
}