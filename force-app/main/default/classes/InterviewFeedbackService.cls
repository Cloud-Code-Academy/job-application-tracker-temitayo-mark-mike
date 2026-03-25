/**
 * @description Core business logic service for Interview Feedback management
 * @author System Generated
 * @date 2025
 */
public inherited sharing class InterviewFeedbackService {
    
    // Constants for validation and business rules
    private static final Integer MAX_RATING_VALUE = 5;
    private static final Integer MIN_RATING_VALUE = 1;
    private static final Set<String> VALID_FEEDBACK_STATUSES = new Set<String>{
        'Draft', 'Submitted', 'Reviewed', 'Archived'
    };
    
    /**
     * @description Creates interview feedback records with validation
     * @param feedbackRecords List of Interview_Feedback__c records to create
     * @return List<Interview_Feedback__c> Created feedback records with IDs
     * @throws FeedbackValidationException for validation failures
     */
    @AuraEnabled
    public static List<Interview_Feedback__c> createFeedback(List<Interview_Feedback__c> feedbackRecords) {
        if (feedbackRecords == null || feedbackRecords.isEmpty()) {
            throw new FeedbackValidationException('Feedback records cannot be null or empty');
        }
        
        // Validate all records before processing
        validateFeedbackRecords(feedbackRecords);
        
        // Set default values and perform business logic
        for (Interview_Feedback__c feedback : feedbackRecords) {
            setDefaultValues(feedback);
            calculateOverallRating(feedback);
        }
        
        try {
            // Bulk insert with proper error handling
            Database.SaveResult[] results = Database.insert(feedbackRecords, false);
            
            // Process results and handle partial failures
            List<Interview_Feedback__c> successfulRecords = new List<Interview_Feedback__c>();
            List<String> errors = new List<String>();
            
            for (Integer i = 0; i < results.size(); i++) {
                if (results[i].isSuccess()) {
                    successfulRecords.add(feedbackRecords[i]);
                } else {
                    String errorMsg = 'Record ' + i + ': ';
                    for (Database.Error error : results[i].getErrors()) {
                        errorMsg += error.getMessage() + '; ';
                    }
                    errors.add(errorMsg);
                }
            }
            
            if (!errors.isEmpty()) {
                System.debug(LoggingLevel.ERROR, 'Feedback creation errors: ' + String.join(errors, '\n'));
                throw new FeedbackValidationException('Some feedback records failed to create: ' + String.join(errors, '\n'));
            }
            
            return successfulRecords;
            
        } catch (DmlException e) {
            System.debug(LoggingLevel.ERROR, 'DML Exception in createFeedback: ' + e.getMessage());
            throw new FeedbackValidationException('Failed to create feedback records: ' + e.getMessage());
        }
    }
    
    /**
     * @description Updates interview feedback records with validation
     * @param feedbackRecords List of Interview_Feedback__c records to update
     * @return List<Interview_Feedback__c> Updated feedback records
     */
    public static List<Interview_Feedback__c> updateFeedback(List<Interview_Feedback__c> feedbackRecords) {
        if (feedbackRecords == null || feedbackRecords.isEmpty()) {
            throw new FeedbackValidationException('Feedback records cannot be null or empty');
        }
        
        // Validate security access
        if (!Schema.sObjectType.Interview_Feedback__c.isUpdateable()) {
            throw new FeedbackValidationException('Insufficient permissions to update feedback records');
        }
        
        // Validate all records before processing
        validateFeedbackRecords(feedbackRecords);
        
        // Recalculate ratings for updated records
        for (Interview_Feedback__c feedback : feedbackRecords) {
            calculateOverallRating(feedback);
        }
        
        try {
            Database.SaveResult[] results = Database.update(feedbackRecords, false);
            
            List<Interview_Feedback__c> successfulRecords = new List<Interview_Feedback__c>();
            List<String> errors = new List<String>();
            
            for (Integer i = 0; i < results.size(); i++) {
                if (results[i].isSuccess()) {
                    successfulRecords.add(feedbackRecords[i]);
                } else {
                    String errorMsg = 'Record ' + feedbackRecords[i].Id + ': ';
                    for (Database.Error error : results[i].getErrors()) {
                        errorMsg += error.getMessage() + '; ';
                    }
                    errors.add(errorMsg);
                }
            }
            
            if (!errors.isEmpty()) {
                throw new FeedbackValidationException('Some feedback records failed to update: ' + String.join(errors, '\n'));
            }
            
            return successfulRecords;
            
        } catch (DmlException e) {
            throw new FeedbackValidationException('Failed to update feedback records: ' + e.getMessage());
        }
    }
    
    /**
     * @description Calculates aggregate scores across multiple feedback records
     * @param jobApplicationId ID of the Job Application to calculate scores for
     * @return AggregateScores Calculated aggregate scores and statistics
     */
    public static AggregateScores calculateAggregateScores(Id jobApplicationId) {
        if (jobApplicationId == null) {
            throw new FeedbackValidationException('Job Application ID cannot be null');
        }
        
        // Query all feedback for the job application
        List<Interview_Feedback__c> feedbackRecords = [
            SELECT Id, Overall_Rating__c, Technical_Rating__c, Communication_Rating__c, 
                   Cultural_Fit_Rating__c, Interview_Round__c, Interview_Type__c,
                   Feedback_Status__c, CreatedDate
            FROM Interview_Feedback__c 
            WHERE Job_Application__c = :jobApplicationId 
            AND Feedback_Status__c = 'Submitted'
            ORDER BY CreatedDate ASC
        ];
        
        if (feedbackRecords.isEmpty()) {
            return new AggregateScores();
        }
        
        return calculateScoreStatistics(feedbackRecords);
    }
    
    /**
     * @description Validates feedback data integrity and business rules
     * @param feedbackRecords List of feedback records to validate
     * @throws FeedbackValidationException for validation failures
     */
    private static void validateFeedbackRecords(List<Interview_Feedback__c> feedbackRecords) {
        Set<Id> jobApplicationIds = new Set<Id>();
        
        for (Interview_Feedback__c feedback : feedbackRecords) {
            // Validate required fields
            if (feedback.Job_Application__c == null) {
                throw new FeedbackValidationException('Job Application is required for feedback');
            }
            
            if (String.isBlank(feedback.Interview_Round__c)) {
                throw new FeedbackValidationException('Interview Round is required');
            }
            
            // Validate rating ranges
            validateRatingField(feedback.Overall_Rating__c, 'Overall Rating');
            validateRatingField(feedback.Technical_Rating__c, 'Technical Rating');
            validateRatingField(feedback.Communication_Rating__c, 'Communication Rating');
            validateRatingField(feedback.Cultural_Fit_Rating__c, 'Cultural Fit Rating');
            
            // Validate status
            if (String.isNotBlank(feedback.Feedback_Status__c) && 
                !VALID_FEEDBACK_STATUSES.contains(feedback.Feedback_Status__c)) {
                throw new FeedbackValidationException('Invalid feedback status: ' + feedback.Feedback_Status__c);
            }
            
            jobApplicationIds.add(feedback.Job_Application__c);
        }
        
        // Validate Job Application exists and is accessible
        validateJobApplicationAccess(jobApplicationIds);
    }
    
    /**
     * @description Validates individual rating field values
     * @param ratingValue The rating value to validate
     * @param fieldName Name of the field for error messages
     */
    private static void validateRatingField(Decimal ratingValue, String fieldName) {
        if (ratingValue != null && 
            (ratingValue < MIN_RATING_VALUE || ratingValue > MAX_RATING_VALUE)) {
            throw new FeedbackValidationException(
                fieldName + ' must be between ' + MIN_RATING_VALUE + ' and ' + MAX_RATING_VALUE
            );
        }
    }
    
    /**
     * @description Validates Job Application access and existence
     * @param jobApplicationIds Set of Job Application IDs to validate
     */
    private static void validateJobApplicationAccess(Set<Id> jobApplicationIds) {
        if (jobApplicationIds.isEmpty()) {
            return;
        }
        
        List<Job_Application__c> jobApps = [
            SELECT Id FROM Job_Application__c 
            WHERE Id IN :jobApplicationIds
        ];
        
        if (jobApps.size() != jobApplicationIds.size()) {
            throw new FeedbackValidationException('One or more Job Applications not found or not accessible');
        }
    }
    
    /**
     * @description Sets default values for new feedback records
     * @param feedback The feedback record to set defaults for
     */
    private static void setDefaultValues(Interview_Feedback__c feedback) {
        if (String.isBlank(feedback.Feedback_Status__c)) {
            feedback.Feedback_Status__c = 'Draft';
        }
        
        if (feedback.Interview_Date__c == null) {
            feedback.Interview_Date__c = Date.today();
        }
    }
    
    /**
     * @description Calculates overall rating based on individual ratings
     * @param feedback The feedback record to calculate overall rating for
     */
    private static void calculateOverallRating(Interview_Feedback__c feedback) {
        List<Decimal> ratings = new List<Decimal>();
        
        if (feedback.Technical_Rating__c != null) {
            ratings.add(feedback.Technical_Rating__c);
        }
        if (feedback.Communication_Rating__c != null) {
            ratings.add(feedback.Communication_Rating__c);
        }
        if (feedback.Cultural_Fit_Rating__c != null) {
            ratings.add(feedback.Cultural_Fit_Rating__c);
        }
        
        if (!ratings.isEmpty()) {
            Decimal sum = 0;
            for (Decimal rating : ratings) {
                sum += rating;
            }
            feedback.Overall_Rating__c = sum / ratings.size();
        }
    }
    
    /**
     * @description Calculates statistical analysis of feedback scores
     * @param feedbackRecords List of feedback records to analyze
     * @return AggregateScores Statistical analysis results
     */
    private static AggregateScores calculateScoreStatistics(List<Interview_Feedback__c> feedbackRecords) {
        AggregateScores scores = new AggregateScores();
        
        List<Decimal> overallRatings = new List<Decimal>();
        List<Decimal> technicalRatings = new List<Decimal>();
        List<Decimal> communicationRatings = new List<Decimal>();
        List<Decimal> culturalFitRatings = new List<Decimal>();
        
        // Collect all ratings
        for (Interview_Feedback__c feedback : feedbackRecords) {
            if (feedback.Overall_Rating__c != null) {
                overallRatings.add(feedback.Overall_Rating__c);
            }
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
        
        // Calculate statistics
        scores.overallAverage = calculateAverage(overallRatings);
        scores.technicalAverage = calculateAverage(technicalRatings);
        scores.communicationAverage = calculateAverage(communicationRatings);
        scores.culturalFitAverage = calculateAverage(culturalFitRatings);
        
        scores.totalFeedbackCount = feedbackRecords.size();
        scores.latestFeedbackDate = feedbackRecords[feedbackRecords.size() - 1].CreatedDate;
        
        return scores;
    }
    
    /**
     * @description Calculates average of a list of decimal values
     * @param values List of decimal values
     * @return Decimal Average value or null if list is empty
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
     * @description Custom exception for feedback validation errors
     */
    public class FeedbackValidationException extends Exception {}
    
    /**
     * @description Wrapper class for aggregate score calculations
     */
    public class AggregateScores {
        public Decimal overallAverage { get; set; }
        public Decimal technicalAverage { get; set; }
        public Decimal communicationAverage { get; set; }
        public Decimal culturalFitAverage { get; set; }
        public Integer totalFeedbackCount { get; set; }
        public DateTime latestFeedbackDate { get; set; }
        
        public AggregateScores() {
            this.totalFeedbackCount = 0;
        }
    }
}