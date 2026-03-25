/**
 * @description Data migration utility for converting existing interview data to Interview Feedback Tracker structure
 * @author Interview Feedback Tracker Team
 * @date 2024
 */
public inherited sharing class InterviewFeedbackDataMigration {
    
    /**
     * @description Migrates existing interview notes from Job Applications to structured feedback records
     * @param jobApplicationIds List of Job Application IDs to migrate
     * @return MigrationResult containing success/failure statistics
     */
    public static MigrationResult migrateInterviewData(List<Id> jobApplicationIds) {
        MigrationResult result = new MigrationResult();
        
        try {
            // Query existing Job Applications with interview data
            List<Job_Application__c> jobApps = [
                SELECT Id, Name, Interview_Notes__c, Interview_Date__c, 
                       Status__c, Company__c, Position_Title__c
                FROM Job_Application__c 
                WHERE Id IN :jobApplicationIds 
                AND Interview_Notes__c != null
                LIMIT 200
            ];
            
            List<Interview_Feedback__c> feedbackRecords = new List<Interview_Feedback__c>();
            List<Competency_Rating__c> competencyRatings = new List<Competency_Rating__c>();
            
            for (Job_Application__c jobApp : jobApps) {
                try {
                    // Parse existing interview notes and create structured feedback
                    Interview_Feedback__c feedback = createFeedbackFromNotes(jobApp);
                    feedbackRecords.add(feedback);
                    result.processedRecords++;
                    
                } catch (Exception e) {
                    result.failedRecords++;
                    result.errors.add('Failed to migrate Job Application ' + jobApp.Id + ': ' + e.getMessage());
                }
            }
            
            // Insert feedback records
            if (!feedbackRecords.isEmpty()) {
                Database.SaveResult[] saveResults = Database.insert(feedbackRecords, false);
                
                for (Integer i = 0; i < saveResults.size(); i++) {
                    if (saveResults[i].isSuccess()) {
                        result.successfulRecords++;
                        
                        // Create default competency ratings
                        List<Competency_Rating__c> ratings = createDefaultCompetencyRatings(
                            saveResults[i].getId(), 
                            feedbackRecords[i]
                        );
                        competencyRatings.addAll(ratings);
                        
                    } else {
                        result.failedRecords++;
                        for (Database.Error error : saveResults[i].getErrors()) {
                            result.errors.add('Insert failed: ' + error.getMessage());
                        }
                    }
                }
            }
            
            // Insert competency ratings
            if (!competencyRatings.isEmpty()) {
                Database.insert(competencyRatings, false);
            }
            
        } catch (Exception e) {
            result.errors.add('Migration failed: ' + e.getMessage());
        }
        
        return result;
    }
    
    /**
     * @description Creates Interview Feedback record from existing Job Application data
     */
    private static Interview_Feedback__c createFeedbackFromNotes(Job_Application__c jobApp) {
        Interview_Feedback__c feedback = new Interview_Feedback__c();
        feedback.Job_Application__c = jobApp.Id;
        feedback.Interview_Round__c = 'Round 1';
        feedback.Interview_Type__c = 'General';
        feedback.Interview_Date__c = jobApp.Interview_Date__c != null ? 
            jobApp.Interview_Date__c : System.now();
        feedback.Duration_Minutes__c = 60; // Default duration
        feedback.Detailed_Feedback__c = jobApp.Interview_Notes__c;
        feedback.Feedback_Source__c = 'Self';
        feedback.Feedback_Status__c = 'Submitted';
        
        // Parse notes for ratings (basic keyword analysis)
        feedback.Overall_Rating__c = parseRatingFromNotes(jobApp.Interview_Notes__c, 'overall');
        feedback.Technical_Rating__c = parseRatingFromNotes(jobApp.Interview_Notes__c, 'technical');
        feedback.Communication_Rating__c = parseRatingFromNotes(jobApp.Interview_Notes__c, 'communication');
        feedback.Cultural_Fit_Rating__c = parseRatingFromNotes(jobApp.Interview_Notes__c, 'culture');
        
        // Set recommendation based on job application status
        if (jobApp.Status__c == 'Offer Received' || jobApp.Status__c == 'Accepted') {
            feedback.Recommendation__c = 'Hire';
        } else if (jobApp.Status__c == 'Rejected') {
            feedback.Recommendation__c = 'No Hire';
        } else {
            feedback.Recommendation__c = 'Maybe';
        }
        
        return feedback;
    }
    
    /**
     * @description Parses rating from interview notes using keyword analysis
     */
    private static Decimal parseRatingFromNotes(String notes, String category) {
        if (String.isBlank(notes)) return 3.0; // Default neutral rating
        
        String lowerNotes = notes.toLowerCase();
        
        // Look for explicit ratings
        Pattern ratingPattern = Pattern.compile(category + '.*?(\\d+)\\s*(?:out of|/|-)\\s*(\\d+)');
        Matcher matcher = ratingPattern.matcher(lowerNotes);
        if (matcher.find()) {
            try {
                Decimal rating = Decimal.valueOf(matcher.group(1));
                Decimal scale = Decimal.valueOf(matcher.group(2));
                return (rating / scale) * 5; // Convert to 5-point scale
            } catch (Exception e) {
                // Continue to sentiment analysis
            }
        }
        
        // Sentiment-based rating
        List<String> positiveKeywords = new List<String>{
            'excellent', 'outstanding', 'great', 'strong', 'impressive', 'good'
        };
        List<String> negativeKeywords = new List<String>{
            'poor', 'weak', 'lacking', 'needs improvement', 'struggled', 'difficult'
        };
        
        Integer positiveCount = 0;
        Integer negativeCount = 0;
        
        for (String keyword : positiveKeywords) {
            if (lowerNotes.contains(keyword)) positiveCount++;
        }
        for (String keyword : negativeKeywords) {
            if (lowerNotes.contains(keyword)) negativeCount++;
        }
        
        if (positiveCount > negativeCount) return 4.0;
        if (negativeCount > positiveCount) return 2.0;
        return 3.0; // Neutral
    }
    
    /**
     * @description Creates default competency ratings for migrated feedback
     */
    private static List<Competency_Rating__c> createDefaultCompetencyRatings(
        Id feedbackId, 
        Interview_Feedback__c feedback
    ) {
        List<Competency_Rating__c> ratings = new List<Competency_Rating__c>();
        
        Map<String, Decimal> competencies = new Map<String, Decimal>{
            'Technical Skills' => feedback.Technical_Rating__c,
            'Communication' => feedback.Communication_Rating__c,
            'Problem Solving' => feedback.Overall_Rating__c,
            'Cultural Fit' => feedback.Cultural_Fit_Rating__c,
            'Leadership' => feedback.Overall_Rating__c
        };
        
        for (String competency : competencies.keySet()) {
            Competency_Rating__c rating = new Competency_Rating__c();
            rating.Interview_Feedback__c = feedbackId;
            rating.Competency_Name__c = competency;
            rating.Rating__c = competencies.get(competency);
            rating.Weight__c = 1.0;
            rating.Comments__c = 'Migrated from legacy interview notes';
            ratings.add(rating);
        }
        
        return ratings;
    }
    
    /**
     * @description Batch migration for large datasets
     */
    public static void startBatchMigration() {
        InterviewFeedbackMigrationBatch batch = new InterviewFeedbackMigrationBatch();
        Database.executeBatch(batch, 50);
    }
    
    /**
     * @description Migration result wrapper class
     */
    public class MigrationResult {
        public Integer processedRecords = 0;
        public Integer successfulRecords = 0;
        public Integer failedRecords = 0;
        public List<String> errors = new List<String>();
        
        public String getSummary() {
            return String.format(
                'Migration completed: {0} processed, {1} successful, {2} failed',
                new List<Object>{processedRecords, successfulRecords, failedRecords}
            );
        }
    }
}