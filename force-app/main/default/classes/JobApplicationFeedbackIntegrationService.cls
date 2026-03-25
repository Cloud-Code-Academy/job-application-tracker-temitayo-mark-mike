/**
 * @description Service class for integrating interview feedback with job application workflow
 * Handles automatic updates to job application records based on feedback data
 * @author Temitayo Oluwalade
 * @date 2024
 */
public with sharing class JobApplicationFeedbackIntegrationService {
    
    /**
     * @description Updates job application metrics when feedback is created or updated
     * @param feedbackRecords List of interview feedback records
     */
    public static void updateJobApplicationMetrics(List<Interview_Feedback__c> feedbackRecords) {
        if (feedbackRecords == null || feedbackRecords.isEmpty()) {
            return;
        }
        
        // Get unique job application IDs
        Set<Id> jobApplicationIds = new Set<Id>();
        for (Interview_Feedback__c feedback : feedbackRecords) {
            if (feedback.Job_Application__c != null) {
                jobApplicationIds.add(feedback.Job_Application__c);
            }
        }
        
        if (jobApplicationIds.isEmpty()) {
            return;
        }
        
        // Calculate metrics for each job application
        Map<Id, JobApplicationMetrics> metricsMap = calculateJobApplicationMetrics(jobApplicationIds);
        
        // Update job application records
        List<Job_Application__c> jobAppsToUpdate = new List<Job_Application__c>();
        
        for (Id jobAppId : metricsMap.keySet()) {
            JobApplicationMetrics metrics = metricsMap.get(jobAppId);
            
            Job_Application__c jobApp = new Job_Application__c(
                Id = jobAppId,
                Average_Interview_Rating__c = metrics.averageRating,
                Total_Interview_Count__c = metrics.totalCount,
                Last_Interview_Date__c = metrics.lastInterviewDate,
                Interview_Success_Score__c = metrics.successScore,
                Feedback_Summary__c = metrics.feedbackSummary,
                Next_Steps__c = metrics.nextSteps
            );
            
            jobAppsToUpdate.add(jobApp);
        }
        
        if (!jobAppsToUpdate.isEmpty()) {
            try {
                update jobAppsToUpdate;
                System.debug('Updated ' + jobAppsToUpdate.size() + ' job applications with feedback metrics');
            } catch (Exception e) {
                System.debug('Error updating job applications: ' + e.getMessage());
                throw new JobApplicationIntegrationException('Failed to update job application metrics: ' + e.getMessage());
            }
        }
    }
    
    /**
     * @description Updates job application status based on feedback outcomes
     * @param feedbackRecords List of interview feedback records
     */
    public static void updateJobApplicationStatus(List<Interview_Feedback__c> feedbackRecords) {
        if (feedbackRecords == null || feedbackRecords.isEmpty()) {
            return;
        }
        
        List<Job_Application__c> jobAppsToUpdate = new List<Job_Application__c>();
        
        for (Interview_Feedback__c feedback : feedbackRecords) {
            if (feedback.Job_Application__c == null) {
                continue;
            }
            
            String newStatus = determineStatusFromFeedback(feedback);
            
            if (String.isNotBlank(newStatus)) {
                Job_Application__c jobApp = new Job_Application__c(
                    Id = feedback.Job_Application__c,
                    Status__c = newStatus
                );
                jobAppsToUpdate.add(jobApp);
            }
        }
        
        if (!jobAppsToUpdate.isEmpty()) {
            try {
                update jobAppsToUpdate;
                System.debug('Updated status for ' + jobAppsToUpdate.size() + ' job applications');
            } catch (Exception e) {
                System.debug('Error updating job application status: ' + e.getMessage());
                throw new JobApplicationIntegrationException('Failed to update job application status: ' + e.getMessage());
            }
        }
    }
    
    /**
     * @description Creates follow-up tasks based on feedback analysis
     * @param feedbackRecords List of interview feedback records
     */
    public static void createFollowUpTasks(List<Interview_Feedback__c> feedbackRecords) {
        if (feedbackRecords == null || feedbackRecords.isEmpty()) {
            return;
        }
        
        List<Task> tasksToCreate = new List<Task>();
        
        for (Interview_Feedback__c feedback : feedbackRecords) {
            if (feedback.Job_Application__c == null) {
                continue;
            }
            
            List<Task> feedbackTasks = generateTasksFromFeedback(feedback);
            tasksToCreate.addAll(feedbackTasks);
        }
        
        if (!tasksToCreate.isEmpty()) {
            try {
                insert tasksToCreate;
                System.debug('Created ' + tasksToCreate.size() + ' follow-up tasks from feedback');
            } catch (Exception e) {
                System.debug('Error creating follow-up tasks: ' + e.getMessage());
                throw new JobApplicationIntegrationException('Failed to create follow-up tasks: ' + e.getMessage());
            }
        }
    }
    
    /**
     * @description Calculates comprehensive metrics for job applications
     * @param jobApplicationIds Set of job application IDs
     * @return Map of job application ID to metrics
     */
    private static Map<Id, JobApplicationMetrics> calculateJobApplicationMetrics(Set<Id> jobApplicationIds) {
        Map<Id, JobApplicationMetrics> metricsMap = new Map<Id, JobApplicationMetrics>();
        
        // Query all feedback for the job applications
        List<Interview_Feedback__c> allFeedback = [
            SELECT Id, Job_Application__c, Overall_Rating__c, Interview_Date__c,
                   Strengths__c, Areas_for_Improvement__c, Additional_Comments__c,
                   Interview_Type__c,
                   (SELECT Id, Competency_Name__c, Rating__c FROM Competency_Ratings__r)
            FROM Interview_Feedback__c
            WHERE Job_Application__c IN :jobApplicationIds
            ORDER BY Interview_Date__c DESC
        ];
        
        // Group feedback by job application
        Map<Id, List<Interview_Feedback__c>> feedbackByJobApp = new Map<Id, List<Interview_Feedback__c>>();
        
        for (Interview_Feedback__c feedback : allFeedback) {
            if (!feedbackByJobApp.containsKey(feedback.Job_Application__c)) {
                feedbackByJobApp.put(feedback.Job_Application__c, new List<Interview_Feedback__c>());
            }
            feedbackByJobApp.get(feedback.Job_Application__c).add(feedback);
        }
        
        // Calculate metrics for each job application
        for (Id jobAppId : feedbackByJobApp.keySet()) {
            List<Interview_Feedback__c> feedbackList = feedbackByJobApp.get(jobAppId);
            JobApplicationMetrics metrics = calculateMetricsForJobApp(feedbackList);
            metricsMap.put(jobAppId, metrics);
        }
        
        return metricsMap;
    }
    
    /**
     * @description Calculates metrics for a single job application
     * @param feedbackList List of feedback records for the job application
     * @return JobApplicationMetrics object
     */
    private static JobApplicationMetrics calculateMetricsForJobApp(List<Interview_Feedback__c> feedbackList) {
        JobApplicationMetrics metrics = new JobApplicationMetrics();
        
        if (feedbackList == null || feedbackList.isEmpty()) {
            return metrics;
        }
        
        Decimal totalRating = 0;
        Integer ratingCount = 0;
        DateTime latestDate = null;
        List<String> strengths = new List<String>();
        List<String> improvements = new List<String>();
        
        for (Interview_Feedback__c feedback : feedbackList) {
            // Calculate average rating
            if (feedback.Overall_Rating__c != null) {
                totalRating += feedback.Overall_Rating__c;
                ratingCount++;
            }
            
            // Track latest interview date
            if (feedback.Interview_Date__c != null) {
                if (latestDate == null || feedback.Interview_Date__c > latestDate) {
                    latestDate = feedback.Interview_Date__c;
                }
            }
            
            // Collect feedback text
            if (String.isNotBlank(feedback.Strengths__c)) {
                strengths.add(feedback.Strengths__c);
            }
            if (String.isNotBlank(feedback.Areas_for_Improvement__c)) {
                improvements.add(feedback.Areas_for_Improvement__c);
            }
        }
        
        // Set basic metrics
        metrics.totalCount = feedbackList.size();
        metrics.averageRating = ratingCount > 0 ? (totalRating / ratingCount).setScale(1) : null;
        metrics.lastInterviewDate = latestDate;
        
        // Calculate success score (weighted average with trend analysis)
        metrics.successScore = calculateSuccessScore(feedbackList);
        
        // Generate feedback summary
        metrics.feedbackSummary = generateFeedbackSummary(strengths, improvements);
        
        // Generate next steps
        metrics.nextSteps = generateNextSteps(feedbackList, metrics.averageRating);
        
        return metrics;
    }
    
    /**
     * @description Calculates a comprehensive success score
     * @param feedbackList List of feedback records
     * @return Success score as decimal
     */
    private static Decimal calculateSuccessScore(List<Interview_Feedback__c> feedbackList) {
        if (feedbackList == null || feedbackList.isEmpty()) {
            return null;
        }
        
        Decimal totalScore = 0;
        Integer scoreCount = 0;
        
        // Weight recent feedback more heavily
        for (Integer i = 0; i < feedbackList.size(); i++) {
            Interview_Feedback__c feedback = feedbackList[i];
            if (feedback.Overall_Rating__c != null) {
                // More recent feedback gets higher weight
                Decimal weight = 1.0 + (0.1 * (feedbackList.size() - i));
                totalScore += feedback.Overall_Rating__c * weight;
                scoreCount += Integer.valueOf(weight);
            }
        }
        
        return scoreCount > 0 ? (totalScore / scoreCount * 20).setScale(2) : null; // Scale to 100
    }
    
    /**
     * @description Generates a summary of feedback
     * @param strengths List of strength comments
     * @param improvements List of improvement areas
     * @return Formatted feedback summary
     */
    private static String generateFeedbackSummary(List<String> strengths, List<String> improvements) {
        List<String> summaryParts = new List<String>();
        
        if (!strengths.isEmpty()) {
            summaryParts.add('STRENGTHS:\\n' + String.join(strengths, '\\n• '));
        }
        
        if (!improvements.isEmpty()) {
            summaryParts.add('AREAS FOR IMPROVEMENT:\\n' + String.join(improvements, '\\n• '));
        }
        
        return String.join(summaryParts, '\\n\\n');
    }
    
    /**
     * @description Generates next steps recommendations
     * @param feedbackList List of feedback records
     * @param averageRating Average rating across feedback
     * @return Next steps recommendations
     */
    private static String generateNextSteps(List<Interview_Feedback__c> feedbackList, Decimal averageRating) {
        List<String> nextSteps = new List<String>();
        
        if (averageRating == null) {
            nextSteps.add('• Schedule initial interview to gather feedback');
            return String.join(nextSteps, '\\n');
        }
        
        if (averageRating >= 4.0) {
            nextSteps.add('• Strong performance - prepare for final round or offer negotiation');
            nextSteps.add('• Review compensation package and benefits');
            nextSteps.add('• Prepare references and background check documents');
        } else if (averageRating >= 3.0) {
            nextSteps.add('• Good progress - focus on addressing improvement areas');
            nextSteps.add('• Schedule follow-up interview to demonstrate growth');
            nextSteps.add('• Prepare specific examples addressing feedback points');
        } else {
            nextSteps.add('• Review feedback carefully and develop improvement plan');
            nextSteps.add('• Consider additional preparation or skill development');
            nextSteps.add('• Evaluate if this role aligns with current skill level');
        }
        
        // Add interview-specific recommendations
        Set<String> interviewTypes = new Set<String>();
        for (Interview_Feedback__c feedback : feedbackList) {
            if (String.isNotBlank(feedback.Interview_Type__c)) {
                interviewTypes.add(feedback.Interview_Type__c);
            }
        }
        
        if (!interviewTypes.contains('Technical') && feedbackList.size() < 3) {
            nextSteps.add('• Prepare for technical interview round');
        }
        if (!interviewTypes.contains('Behavioral') && feedbackList.size() < 3) {
            nextSteps.add('• Prepare behavioral interview examples using STAR method');
        }
        
        return String.join(nextSteps, '\\n');
    }
    
    /**
     * @description Determines new status based on feedback
     * @param feedback Interview feedback record
     * @return New status or null if no change needed
     */
    private static String determineStatusFromFeedback(Interview_Feedback__c feedback) {
        if (feedback.Overall_Rating__c == null) {
            return null;
        }
        
        // High rating suggests moving to next stage
        if (feedback.Overall_Rating__c >= 4.5) {
            return 'Interviewing'; // Keep in interviewing until final decision
        }
        
        // Very low rating might indicate rejection
        if (feedback.Overall_Rating__c <= 2.0) {
            return 'Rejected';
        }
        
        // Medium ratings keep status as interviewing
        return 'Interviewing';
    }
    
    /**
     * @description Generates follow-up tasks based on feedback
     * @param feedback Interview feedback record
     * @return List of tasks to create
     */
    private static List<Task> generateTasksFromFeedback(Interview_Feedback__c feedback) {
        List<Task> tasks = new List<Task>();
        
        if (feedback.Overall_Rating__c == null) {
            return tasks;
        }
        
        // High rating tasks
        if (feedback.Overall_Rating__c >= 4.0) {
            Task followUpTask = new Task(
                Subject = 'Follow up on positive interview feedback',
                Description = 'Strong interview performance (Rating: ' + feedback.Overall_Rating__c + '/5). ' +
                             'Consider next steps: final round, offer negotiation, or reference check.',
                WhatId = feedback.Job_Application__c,
                ActivityDate = Date.today().addDays(2),
                Priority = 'High',
                Status = 'Not Started'
            );
            tasks.add(followUpTask);
        }
        
        // Medium rating tasks
        else if (feedback.Overall_Rating__c >= 3.0) {
            Task improvementTask = new Task(
                Subject = 'Address interview feedback points',
                Description = 'Review feedback and prepare improvement plan. Rating: ' + feedback.Overall_Rating__c + '/5. ' +
                             'Focus on areas mentioned in feedback.',
                WhatId = feedback.Job_Application__c,
                ActivityDate = Date.today().addDays(3),
                Priority = 'Normal',
                Status = 'Not Started'
            );
            tasks.add(improvementTask);
        }
        
        // Low rating tasks
        else {
            Task reviewTask = new Task(
                Subject = 'Review interview performance and strategy',
                Description = 'Low interview rating (' + feedback.Overall_Rating__c + '/5). ' +
                             'Analyze feedback and determine if additional preparation is needed.',
                WhatId = feedback.Job_Application__c,
                ActivityDate = Date.today().addDays(1),
                Priority = 'High',
                Status = 'Not Started'
            );
            tasks.add(reviewTask);
        }
        
        return tasks;
    }
    
    /**
     * @description Inner class to hold job application metrics
     */
    private class JobApplicationMetrics {
        public Decimal averageRating;
        public Integer totalCount;
        public DateTime lastInterviewDate;
        public Decimal successScore;
        public String feedbackSummary;
        public String nextSteps;
        
        public JobApplicationMetrics() {
            this.totalCount = 0;
        }
    }
    
    /**
     * @description Custom exception for integration errors
     */
    public class JobApplicationIntegrationException extends Exception {}
}