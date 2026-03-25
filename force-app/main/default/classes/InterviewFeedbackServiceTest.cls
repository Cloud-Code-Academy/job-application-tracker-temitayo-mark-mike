/**
 * @description Comprehensive test class for InterviewFeedbackService
 * @author System Generated
 * @date 2025
 */
@IsTest
private inherited sharing class InterviewFeedbackServiceTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test Job Application
        Job_Application__c jobApp = InterviewFeedbackTestDataFactory.createJobApplication();
        insert jobApp;
        
        // Create test Feedback Template
        Feedback_Template__c template = InterviewFeedbackTestDataFactory.createFeedbackTemplate();
        insert template;
    }
    
    @IsTest
    static void testCreateFeedback_Success() {
        // Given
        Job_Application__c jobApp = [SELECT Id FROM Job_Application__c LIMIT 1];
        List<Interview_Feedback__c> feedbackList = new List<Interview_Feedback__c>{
            InterviewFeedbackTestDataFactory.createInterviewFeedback(jobApp.Id)
        };
        
        // When
        Test.startTest();
        List<Interview_Feedback__c> result = InterviewFeedbackService.createFeedback(feedbackList);
        Test.stopTest();
        
        // Then
        System.assertEquals(1, result.size(), 'Should return one created feedback record');
        System.assertNotEquals(null, result[0].Id, 'Created record should have an ID');
        
        // Verify the record was actually created
        Interview_Feedback__c created = [
            SELECT Id, Overall_Rating__c, Feedback_Status__c, Interview_Date__c
            FROM Interview_Feedback__c 
            WHERE Id = :result[0].Id
        ];
        System.assertEquals('Draft', created.Feedback_Status__c, 'Default status should be Draft');
        System.assertEquals(Date.today(), created.Interview_Date__c, 'Default date should be today');
        System.assertNotEquals(null, created.Overall_Rating__c, 'Overall rating should be calculated');
    }
    
    @IsTest
    static void testCreateFeedback_BulkOperation() {
        // Given
        Job_Application__c jobApp = [SELECT Id FROM Job_Application__c LIMIT 1];
        List<Interview_Feedback__c> feedbackList = new List<Interview_Feedback__c>();
        
        // Create 200 feedback records for bulk testing
        for (Integer i = 0; i < 200; i++) {
            Interview_Feedback__c feedback = InterviewFeedbackTestDataFactory.createInterviewFeedback(jobApp.Id);
            feedback.Interview_Round__c = 'Round ' + i;
            feedbackList.add(feedback);
        }
        
        // When
        Test.startTest();
        List<Interview_Feedback__c> result = InterviewFeedbackService.createFeedback(feedbackList);
        Test.stopTest();
        
        // Then
        System.assertEquals(200, result.size(), 'Should create all 200 feedback records');
        
        // Verify all records were created
        List<Interview_Feedback__c> created = [
            SELECT Id FROM Interview_Feedback__c 
            WHERE Job_Application__c = :jobApp.Id
        ];
        System.assertEquals(200, created.size(), 'All records should be in database');
    }
    
    @IsTest
    static void testCreateFeedback_NullInput() {
        // When/Then
        try {
            InterviewFeedbackService.createFeedback(null);
            System.assert(false, 'Should throw exception for null input');
        } catch (InterviewFeedbackService.FeedbackValidationException e) {
            System.assertEquals('Feedback records cannot be null or empty', e.getMessage());
        }
    }
    
    @IsTest
    static void testCreateFeedback_EmptyList() {
        // When/Then
        try {
            InterviewFeedbackService.createFeedback(new List<Interview_Feedback__c>());
            System.assert(false, 'Should throw exception for empty list');
        } catch (InterviewFeedbackService.FeedbackValidationException e) {
            System.assertEquals('Feedback records cannot be null or empty', e.getMessage());
        }
    }
    
    @IsTest
    static void testCreateFeedback_ValidationFailure() {
        // Given - feedback without required Job Application
        Interview_Feedback__c feedback = new Interview_Feedback__c(
            Interview_Round__c = 'Technical',
            Overall_Rating__c = 4
        );
        
        // When/Then
        try {
            InterviewFeedbackService.createFeedback(new List<Interview_Feedback__c>{feedback});
            System.assert(false, 'Should throw exception for missing Job Application');
        } catch (InterviewFeedbackService.FeedbackValidationException e) {
            System.assert(e.getMessage().contains('Job Application is required'), 
                         'Should indicate Job Application is required');
        }
    }
    
    @IsTest
    static void testCreateFeedback_InvalidRating() {
        // Given
        Job_Application__c jobApp = [SELECT Id FROM Job_Application__c LIMIT 1];
        Interview_Feedback__c feedback = InterviewFeedbackTestDataFactory.createInterviewFeedback(jobApp.Id);
        feedback.Technical_Rating__c = 6; // Invalid rating > 5
        
        // When/Then
        try {
            InterviewFeedbackService.createFeedback(new List<Interview_Feedback__c>{feedback});
            System.assert(false, 'Should throw exception for invalid rating');
        } catch (InterviewFeedbackService.FeedbackValidationException e) {
            System.assert(e.getMessage().contains('Technical Rating must be between 1 and 5'), 
                         'Should indicate rating range validation');
        }
    }
    
    @IsTest
    static void testCreateFeedback_InvalidStatus() {
        // Given
        Job_Application__c jobApp = [SELECT Id FROM Job_Application__c LIMIT 1];
        Interview_Feedback__c feedback = InterviewFeedbackTestDataFactory.createInterviewFeedback(jobApp.Id);
        feedback.Feedback_Status__c = 'Invalid Status';
        
        // When/Then
        try {
            InterviewFeedbackService.createFeedback(new List<Interview_Feedback__c>{feedback});
            System.assert(false, 'Should throw exception for invalid status');
        } catch (InterviewFeedbackService.FeedbackValidationException e) {
            System.assert(e.getMessage().contains('Invalid feedback status'), 
                         'Should indicate invalid status');
        }
    }
    
    @IsTest
    static void testUpdateFeedback_Success() {
        // Given
        Job_Application__c jobApp = [SELECT Id FROM Job_Application__c LIMIT 1];
        Interview_Feedback__c feedback = InterviewFeedbackTestDataFactory.createInterviewFeedback(jobApp.Id);
        insert feedback;
        
        // Modify the feedback
        feedback.Technical_Rating__c = 5;
        feedback.Feedback_Status__c = 'Submitted';
        
        // When
        Test.startTest();
        List<Interview_Feedback__c> result = InterviewFeedbackService.updateFeedback(
            new List<Interview_Feedback__c>{feedback}
        );
        Test.stopTest();
        
        // Then
        System.assertEquals(1, result.size(), 'Should return one updated record');
        
        // Verify the update
        Interview_Feedback__c updated = [
            SELECT Id, Technical_Rating__c, Feedback_Status__c, Overall_Rating__c
            FROM Interview_Feedback__c 
            WHERE Id = :feedback.Id
        ];
        System.assertEquals(5, updated.Technical_Rating__c, 'Technical rating should be updated');
        System.assertEquals('Submitted', updated.Feedback_Status__c, 'Status should be updated');
        System.assertNotEquals(null, updated.Overall_Rating__c, 'Overall rating should be recalculated');
    }
    
    @IsTest
    static void testCalculateAggregateScores_Success() {
        // Given
        Job_Application__c jobApp = [SELECT Id FROM Job_Application__c LIMIT 1];
        
        // Create multiple feedback records with different ratings
        List<Interview_Feedback__c> feedbackList = new List<Interview_Feedback__c>();
        for (Integer i = 1; i <= 3; i++) {
            Interview_Feedback__c feedback = InterviewFeedbackTestDataFactory.createInterviewFeedback(jobApp.Id);
            feedback.Technical_Rating__c = i + 1; // 2, 3, 4
            feedback.Communication_Rating__c = i + 2; // 3, 4, 5
            feedback.Cultural_Fit_Rating__c = i; // 1, 2, 3
            feedback.Feedback_Status__c = 'Submitted';
            feedback.Interview_Round__c = 'Round ' + i;
            feedbackList.add(feedback);
        }
        insert feedbackList;
        
        // When
        Test.startTest();
        InterviewFeedbackService.AggregateScores result = 
            InterviewFeedbackService.calculateAggregateScores(jobApp.Id);
        Test.stopTest();
        
        // Then
        System.assertEquals(3, result.totalFeedbackCount, 'Should count all feedback records');
        System.assertEquals(3.0, result.technicalAverage, 'Technical average should be 3.0 (2+3+4)/3');
        System.assertEquals(4.0, result.communicationAverage, 'Communication average should be 4.0 (3+4+5)/3');
        System.assertEquals(2.0, result.culturalFitAverage, 'Cultural fit average should be 2.0 (1+2+3)/3');
        System.assertNotEquals(null, result.latestFeedbackDate, 'Should have latest feedback date');
    }
    
    @IsTest
    static void testCalculateAggregateScores_NoFeedback() {
        // Given
        Job_Application__c jobApp = [SELECT Id FROM Job_Application__c LIMIT 1];
        
        // When
        Test.startTest();
        InterviewFeedbackService.AggregateScores result = 
            InterviewFeedbackService.calculateAggregateScores(jobApp.Id);
        Test.stopTest();
        
        // Then
        System.assertEquals(0, result.totalFeedbackCount, 'Should have zero feedback count');
        System.assertEquals(null, result.overallAverage, 'Overall average should be null');
        System.assertEquals(null, result.technicalAverage, 'Technical average should be null');
        System.assertEquals(null, result.communicationAverage, 'Communication average should be null');
        System.assertEquals(null, result.culturalFitAverage, 'Cultural fit average should be null');
    }
    
    @IsTest
    static void testCalculateAggregateScores_NullJobApplicationId() {
        // When/Then
        try {
            InterviewFeedbackService.calculateAggregateScores(null);
            System.assert(false, 'Should throw exception for null Job Application ID');
        } catch (InterviewFeedbackService.FeedbackValidationException e) {
            System.assertEquals('Job Application ID cannot be null', e.getMessage());
        }
    }
    
    @IsTest
    static void testOverallRatingCalculation() {
        // Given
        Job_Application__c jobApp = [SELECT Id FROM Job_Application__c LIMIT 1];
        Interview_Feedback__c feedback = new Interview_Feedback__c(
            Job_Application__c = jobApp.Id,
            Interview_Round__c = 'Technical',
            Technical_Rating__c = 4,
            Communication_Rating__c = 5,
            Cultural_Fit_Rating__c = 3
        );
        
        // When
        Test.startTest();
        List<Interview_Feedback__c> result = InterviewFeedbackService.createFeedback(
            new List<Interview_Feedback__c>{feedback}
        );
        Test.stopTest();
        
        // Then
        Interview_Feedback__c created = [
            SELECT Overall_Rating__c FROM Interview_Feedback__c WHERE Id = :result[0].Id
        ];
        System.assertEquals(4.0, created.Overall_Rating__c, 'Overall rating should be average of 4, 5, 3 = 4.0');
    }
    
    @IsTest
    static void testPartialRatingCalculation() {
        // Given - feedback with only some ratings
        Job_Application__c jobApp = [SELECT Id FROM Job_Application__c LIMIT 1];
        Interview_Feedback__c feedback = new Interview_Feedback__c(
            Job_Application__c = jobApp.Id,
            Interview_Round__c = 'Technical',
            Technical_Rating__c = 4,
            Communication_Rating__c = 5
            // No Cultural_Fit_Rating__c
        );
        
        // When
        Test.startTest();
        List<Interview_Feedback__c> result = InterviewFeedbackService.createFeedback(
            new List<Interview_Feedback__c>{feedback}
        );
        Test.stopTest();
        
        // Then
        Interview_Feedback__c created = [
            SELECT Overall_Rating__c FROM Interview_Feedback__c WHERE Id = :result[0].Id
        ];
        System.assertEquals(4.5, created.Overall_Rating__c, 'Overall rating should be average of 4, 5 = 4.5');
    }
    
    @IsTest
    static void testValidateRatingField_MinValue() {
        // Given
        Job_Application__c jobApp = [SELECT Id FROM Job_Application__c LIMIT 1];
        Interview_Feedback__c feedback = InterviewFeedbackTestDataFactory.createInterviewFeedback(jobApp.Id);
        feedback.Technical_Rating__c = 0; // Below minimum
        
        // When/Then
        try {
            InterviewFeedbackService.createFeedback(new List<Interview_Feedback__c>{feedback});
            System.assert(false, 'Should throw exception for rating below minimum');
        } catch (InterviewFeedbackService.FeedbackValidationException e) {
            System.assert(e.getMessage().contains('Technical Rating must be between 1 and 5'));
        }
    }
    
    @IsTest
    static void testValidateJobApplicationAccess_NotFound() {
        // Given - feedback with non-existent Job Application ID
        Interview_Feedback__c feedback = new Interview_Feedback__c(
            Job_Application__c = '001000000000000', // Non-existent ID
            Interview_Round__c = 'Technical',
            Technical_Rating__c = 4
        );
        
        // When/Then
        try {
            InterviewFeedbackService.createFeedback(new List<Interview_Feedback__c>{feedback});
            System.assert(false, 'Should throw exception for non-existent Job Application');
        } catch (InterviewFeedbackService.FeedbackValidationException e) {
            System.assert(e.getMessage().contains('Job Applications not found or not accessible'));
        }
    }
    
    @IsTest
    static void testAggregateScoresWrapper() {
        // Test the AggregateScores wrapper class
        InterviewFeedbackService.AggregateScores scores = new InterviewFeedbackService.AggregateScores();
        
        // Verify default values
        System.assertEquals(0, scores.totalFeedbackCount, 'Default count should be 0');
        System.assertEquals(null, scores.overallAverage, 'Default average should be null');
        System.assertEquals(null, scores.technicalAverage, 'Default technical average should be null');
        System.assertEquals(null, scores.communicationAverage, 'Default communication average should be null');
        System.assertEquals(null, scores.culturalFitAverage, 'Default cultural fit average should be null');
        System.assertEquals(null, scores.latestFeedbackDate, 'Default date should be null');
        
        // Test setters
        scores.overallAverage = 4.5;
        scores.totalFeedbackCount = 10;
        scores.latestFeedbackDate = DateTime.now();
        
        System.assertEquals(4.5, scores.overallAverage, 'Should set overall average');
        System.assertEquals(10, scores.totalFeedbackCount, 'Should set total count');
        System.assertNotEquals(null, scores.latestFeedbackDate, 'Should set latest date');
    }
    
    @IsTest
    static void testFeedbackValidationException() {
        // Test custom exception
        try {
            throw new InterviewFeedbackService.FeedbackValidationException('Test message');
        } catch (InterviewFeedbackService.FeedbackValidationException e) {
            System.assertEquals('Test message', e.getMessage(), 'Should preserve exception message');
        }
    }
}