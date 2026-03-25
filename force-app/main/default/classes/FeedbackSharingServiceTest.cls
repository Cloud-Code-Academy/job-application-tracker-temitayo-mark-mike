/**
 * @description Comprehensive test class for FeedbackSharingService
 * @author System Generated
 * @date 2025
 */
@IsTest
private class FeedbackSharingServiceTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test Job Application
        Job_Application__c jobApp = InterviewFeedbackTestDataFactory.createJobApplication();
        insert jobApp;
        
        // Create test Interview Feedback
        Interview_Feedback__c feedback = InterviewFeedbackTestDataFactory.createInterviewFeedback(jobApp.Id);
        feedback.Detailed_Feedback__c = 'Detailed technical feedback with sensitive information';
        feedback.Strengths__c = 'Strong problem-solving skills and technical knowledge';
        feedback.Areas_for_Improvement__c = 'Could improve system design and leadership skills';
        feedback.Is_Confidential__c = false;
        insert feedback;
        
        // Create confidential feedback for masking tests
        Interview_Feedback__c confidentialFeedback = InterviewFeedbackTestDataFactory.createInterviewFeedback(jobApp.Id);
        confidentialFeedback.Interview_Round__c = 'Confidential Round';
        confidentialFeedback.Is_Confidential__c = true;
        confidentialFeedback.Detailed_Feedback__c = 'Confidential feedback that should be masked';
        insert confidentialFeedback;
    }
    
    @IsTest
    static void testCreateShareLink_Success() {
        // Given
        Interview_Feedback__c feedback = [SELECT Id FROM Interview_Feedback__c WHERE Interview_Round__c = 'Technical' LIMIT 1];
        String recipientEmail = 'mentor@example.com';
        String accessLevel = 'Comment';
        Integer expirationDays = 14;
        
        // When
        Test.startTest();
        String shareToken = FeedbackSharingService.createShareLink(
            feedback.Id, recipientEmail, accessLevel, expirationDays
        );
        Test.stopTest();
        
        // Then
        System.assertNotEquals(null, shareToken, 'Share token should not be null');
        System.assertEquals(32, shareToken.length(), 'Share token should be 32 characters long');
        
        // Verify share record was created
        List<Feedback_Share__c> shares = [
            SELECT Id, Interview_Feedback__c, Shared_With_Email__c, Access_Level__c,
                   Share_Token__c, Expiration_Date__c, Is_Active__c, Access_Count__c
            FROM Feedback_Share__c
            WHERE Share_Token__c = :shareToken
        ];
        
        System.assertEquals(1, shares.size(), 'Should create one share record');
        Feedback_Share__c share = shares[0];
        System.assertEquals(feedback.Id, share.Interview_Feedback__c, 'Should link to correct feedback');
        System.assertEquals(recipientEmail, share.Shared_With_Email__c, 'Should set recipient email');
        System.assertEquals(accessLevel, share.Access_Level__c, 'Should set access level');
        System.assertEquals(true, share.Is_Active__c, 'Should be active');
        System.assertEquals(0, share.Access_Count__c, 'Should initialize access count to 0');
        
        // Check expiration date is approximately correct (within 1 day tolerance)
        DateTime expectedExpiration = DateTime.now().addDays(expirationDays);
        System.assert(Math.abs(share.Expiration_Date__c.getTime() - expectedExpiration.getTime()) < 86400000, 
                     'Expiration date should be approximately ' + expirationDays + ' days from now');
    }
    
    @IsTest
    static void testCreateShareLink_ExistingActiveShare() {
        // Given
        Interview_Feedback__c feedback = [SELECT Id FROM Interview_Feedback__c WHERE Interview_Round__c = 'Technical' LIMIT 1];
        String recipientEmail = 'mentor@example.com';
        String accessLevel = 'Read Only';
        
        // Create first share
        String firstToken = FeedbackSharingService.createShareLink(
            feedback.Id, recipientEmail, accessLevel, 7
        );
        
        // When - Create second share for same recipient
        Test.startTest();
        String secondToken = FeedbackSharingService.createShareLink(
            feedback.Id, recipientEmail, 'Comment', 30 // Different access level and longer expiration
        );
        Test.stopTest();
        
        // Then - Should return same token but update the share
        System.assertEquals(firstToken, secondToken, 'Should return existing token');
        
        // Verify share was updated
        Feedback_Share__c share = [
            SELECT Access_Level__c, Expiration_Date__c
            FROM Feedback_Share__c
            WHERE Share_Token__c = :firstToken
        ];
        
        System.assertEquals('Comment', share.Access_Level__c, 'Should update access level');
        // Expiration should be extended to 30 days
        DateTime expectedExpiration = DateTime.now().addDays(30);
        System.assert(Math.abs(share.Expiration_Date__c.getTime() - expectedExpiration.getTime()) < 86400000, 
                     'Should extend expiration date');
    }
    
    @IsTest
    static void testCreateShareLink_ValidationErrors() {
        // Given
        Interview_Feedback__c feedback = [SELECT Id FROM Interview_Feedback__c LIMIT 1];
        
        // Test null feedback ID
        try {
            FeedbackSharingService.createShareLink(null, 'test@example.com', 'Read Only', 7);
            System.assert(false, 'Should throw exception for null feedback ID');
        } catch (FeedbackSharingService.SharingException e) {
            System.assertEquals('Feedback ID cannot be null', e.getMessage());
        }
        
        // Test blank email
        try {
            FeedbackSharingService.createShareLink(feedback.Id, '', 'Read Only', 7);
            System.assert(false, 'Should throw exception for blank email');
        } catch (FeedbackSharingService.SharingException e) {
            System.assertEquals('Recipient email cannot be blank', e.getMessage());
        }
        
        // Test invalid email format
        try {
            FeedbackSharingService.createShareLink(feedback.Id, 'invalid-email', 'Read Only', 7);
            System.assert(false, 'Should throw exception for invalid email');
        } catch (FeedbackSharingService.SharingException e) {
            System.assert(e.getMessage().contains('Invalid email format'), 'Should indicate invalid email format');
        }
        
        // Test invalid access level
        try {
            FeedbackSharingService.createShareLink(feedback.Id, 'test@example.com', 'Invalid Level', 7);
            System.assert(false, 'Should throw exception for invalid access level');
        } catch (FeedbackSharingService.SharingException e) {
            System.assert(e.getMessage().contains('Invalid access level'), 'Should indicate invalid access level');
        }
    }
    
    @IsTest
    static void testValidateAndGetSharedFeedback_Success() {
        // Given
        Interview_Feedback__c feedback = [SELECT Id FROM Interview_Feedback__c WHERE Interview_Round__c = 'Technical' LIMIT 1];
        String shareToken = FeedbackSharingService.createShareLink(
            feedback.Id, 'mentor@example.com', 'Comment', 14
        );
        
        // When
        Test.startTest();
        FeedbackSharingService.SharedFeedbackData sharedData = 
            FeedbackSharingService.validateAndGetSharedFeedback(shareToken);
        Test.stopTest();
        
        // Then
        System.assertNotEquals(null, sharedData, 'Shared data should not be null');
        System.assertEquals(feedback.Id, sharedData.feedbackId, 'Should return correct feedback ID');
        System.assertEquals('Comment', sharedData.accessLevel, 'Should return correct access level');
        System.assertEquals('mentor@example.com', sharedData.recipientEmail, 'Should return recipient email');
        System.assertEquals(1, sharedData.accessCount, 'Should increment access count');
        
        // Verify feedback data is populated
        System.assertNotEquals(null, sharedData.positionTitle, 'Should include position title');
        System.assertNotEquals(null, sharedData.companyName, 'Should include company name');
        System.assertNotEquals(null, sharedData.interviewRound, 'Should include interview round');
        System.assertNotEquals(null, sharedData.detailedFeedback, 'Should include detailed feedback');
        
        // Verify access count was updated in database
        Feedback_Share__c share = [
            SELECT Access_Count__c FROM Feedback_Share__c WHERE Share_Token__c = :shareToken
        ];
        System.assertEquals(1, share.Access_Count__c, 'Should update access count in database');
    }
    
    @IsTest
    static void testValidateAndGetSharedFeedback_DataMasking() {
        // Given - Confidential feedback
        Interview_Feedback__c confidentialFeedback = [
            SELECT Id FROM Interview_Feedback__c WHERE Interview_Round__c = 'Confidential Round' LIMIT 1
        ];
        String shareToken = FeedbackSharingService.createShareLink(
            confidentialFeedback.Id, 'mentor@example.com', 'Read Only', 14
        );
        
        // When
        Test.startTest();
        FeedbackSharingService.SharedFeedbackData sharedData = 
            FeedbackSharingService.validateAndGetSharedFeedback(shareToken);
        Test.stopTest();
        
        // Then - Sensitive data should be masked
        System.assert(sharedData.detailedFeedback.contains('[CONFIDENTIAL]'), 
                     'Detailed feedback should be masked for confidential data');
        System.assert(sharedData.strengths.contains('[CONFIDENTIAL]'), 
                     'Strengths should be masked for confidential data');
        System.assert(sharedData.areasForImprovement.contains('[CONFIDENTIAL]'), 
                     'Areas for improvement should be masked for confidential data');
    }
    
    @IsTest
    static void testValidateAndGetSharedFeedback_InvalidToken() {
        // Test blank token
        try {
            FeedbackSharingService.validateAndGetSharedFeedback('');
            System.assert(false, 'Should throw exception for blank token');
        } catch (FeedbackSharingService.SharingException e) {
            System.assertEquals('Share token cannot be blank', e.getMessage());
        }
        
        // Test invalid token
        try {
            FeedbackSharingService.validateAndGetSharedFeedback('invalid-token-123');
            System.assert(false, 'Should throw exception for invalid token');
        } catch (FeedbackSharingService.SharingException e) {
            System.assertEquals('Invalid or inactive share token', e.getMessage());
        }
    }
    
    @IsTest
    static void testValidateAndGetSharedFeedback_ExpiredToken() {
        // Given - Create share with past expiration
        Interview_Feedback__c feedback = [SELECT Id FROM Interview_Feedback__c LIMIT 1];
        Feedback_Share__c expiredShare = InterviewFeedbackTestDataFactory.createFeedbackShare(feedback.Id);
        expiredShare.Expiration_Date__c = DateTime.now().addDays(-1); // Expired yesterday
        expiredShare.Is_Active__c = true;
        insert expiredShare;
        
        // When/Then
        try {
            FeedbackSharingService.validateAndGetSharedFeedback(expiredShare.Share_Token__c);
            System.assert(false, 'Should throw exception for expired token');
        } catch (FeedbackSharingService.SharingException e) {
            System.assertEquals('Share link has expired', e.getMessage());
        }
    }
    
    @IsTest
    static void testAddMentorComment_Success() {
        // Given
        Interview_Feedback__c feedback = [SELECT Id FROM Interview_Feedback__c LIMIT 1];
        String shareToken = FeedbackSharingService.createShareLink(
            feedback.Id, 'mentor@example.com', 'Comment', 14
        );
        String mentorEmail = 'mentor@example.com';
        String comment = 'Great technical skills demonstrated. Consider working on system design.';
        
        // When
        Test.startTest();
        Id commentId = FeedbackSharingService.addMentorComment(shareToken, mentorEmail, comment);
        Test.stopTest();
        
        // Then
        System.assertNotEquals(null, commentId, 'Should return comment ID');
        
        // Verify comment was created
        List<Task> comments = [
            SELECT Id, WhatId, Subject, Description
            FROM Task
            WHERE Id = :commentId
        ];
        
        System.assertEquals(1, comments.size(), 'Should create comment record');
        Task commentTask = comments[0];
        System.assertEquals(feedback.Id, commentTask.WhatId, 'Should link to feedback record');
        System.assert(commentTask.Subject.contains('Mentor Comment'), 'Should have mentor comment subject');
        System.assertEquals(comment, commentTask.Description, 'Should store comment text');
    }
    
    @IsTest
    static void testAddMentorComment_ValidationErrors() {
        // Given
        Interview_Feedback__c feedback = [SELECT Id FROM Interview_Feedback__c LIMIT 1];
        String shareToken = FeedbackSharingService.createShareLink(
            feedback.Id, 'mentor@example.com', 'Read Only', 14
        );
        
        // Test blank token
        try {
            FeedbackSharingService.addMentorComment('', 'mentor@example.com', 'Comment');
            System.assert(false, 'Should throw exception for blank token');
        } catch (FeedbackSharingService.SharingException e) {
            System.assertEquals('Share token cannot be blank', e.getMessage());
        }
        
        // Test blank mentor email
        try {
            FeedbackSharingService.addMentorComment(shareToken, '', 'Comment');
            System.assert(false, 'Should throw exception for blank mentor email');
        } catch (FeedbackSharingService.SharingException e) {
            System.assertEquals('Mentor email cannot be blank', e.getMessage());
        }
        
        // Test blank comment
        try {
            FeedbackSharingService.addMentorComment(shareToken, 'mentor@example.com', '');
            System.assert(false, 'Should throw exception for blank comment');
        } catch (FeedbackSharingService.SharingException e) {
            System.assertEquals('Comment cannot be blank', e.getMessage());
        }
        
        // Test read-only access
        try {
            FeedbackSharingService.addMentorComment(shareToken, 'mentor@example.com', 'Comment');
            System.assert(false, 'Should throw exception for read-only access');
        } catch (FeedbackSharingService.SharingException e) {
            System.assertEquals('Read Only access does not allow commenting', e.getMessage());
        }
    }
    
    @IsTest
    static void testAddMentorComment_EmailMismatch() {
        // Given
        Interview_Feedback__c feedback = [SELECT Id FROM Interview_Feedback__c LIMIT 1];
        String shareToken = FeedbackSharingService.createShareLink(
            feedback.Id, 'mentor@example.com', 'Comment', 14
        );
        
        // When/Then - Try to comment with different email
        try {
            FeedbackSharingService.addMentorComment(shareToken, 'different@example.com', 'Comment');
            System.assert(false, 'Should throw exception for email mismatch');
        } catch (FeedbackSharingService.SharingException e) {
            System.assertEquals('Mentor email does not match share recipient', e.getMessage());
        }
    }
    
    @IsTest
    static void testRevokeAccess_Success() {
        // Given
        Interview_Feedback__c feedback = [SELECT Id FROM Interview_Feedback__c LIMIT 1];
        String shareToken = FeedbackSharingService.createShareLink(
            feedback.Id, 'mentor@example.com', 'Comment', 14
        );
        
        Feedback_Share__c share = [
            SELECT Id FROM Feedback_Share__c WHERE Share_Token__c = :shareToken
        ];
        
        // When
        Test.startTest();
        FeedbackSharingService.revokeAccess(share.Id);
        Test.stopTest();
        
        // Then
        Feedback_Share__c revokedShare = [
            SELECT Is_Active__c FROM Feedback_Share__c WHERE Id = :share.Id
        ];
        
        System.assertEquals(false, revokedShare.Is_Active__c, 'Should deactivate the share');
        
        // Verify token no longer works
        try {
            FeedbackSharingService.validateAndGetSharedFeedback(shareToken);
            System.assert(false, 'Revoked token should not work');
        } catch (FeedbackSharingService.SharingException e) {
            System.assertEquals('Invalid or inactive share token', e.getMessage());
        }
    }
    
    @IsTest
    static void testRevokeAccess_ValidationErrors() {
        // Test null share ID
        try {
            FeedbackSharingService.revokeAccess(null);
            System.assert(false, 'Should throw exception for null share ID');
        } catch (FeedbackSharingService.SharingException e) {
            System.assertEquals('Share ID cannot be null', e.getMessage());
        }
        
        // Test non-existent share ID
        try {
            FeedbackSharingService.revokeAccess('a001234567890123'); // Fake ID
            System.assert(false, 'Should throw exception for non-existent share');
        } catch (FeedbackSharingService.SharingException e) {
            System.assertEquals('Share record not found', e.getMessage());
        }
    }
    
    @IsTest
    static void testGetActiveShares_Success() {
        // Given
        Interview_Feedback__c feedback = [SELECT Id FROM Interview_Feedback__c LIMIT 1];
        
        // Create multiple shares
        FeedbackSharingService.createShareLink(feedback.Id, 'mentor1@example.com', 'Read Only', 14);
        FeedbackSharingService.createShareLink(feedback.Id, 'mentor2@example.com', 'Comment', 30);
        FeedbackSharingService.createShareLink(feedback.Id, 'mentor3@example.com', 'Full Access', 7);
        
        // When
        Test.startTest();
        List<FeedbackSharingService.ShareSummary> summaries = 
            FeedbackSharingService.getActiveShares(feedback.Id);
        Test.stopTest();
        
        // Then
        System.assertEquals(3, summaries.size(), 'Should return all active shares');
        
        // Verify summary data
        for (FeedbackSharingService.ShareSummary summary : summaries) {
            System.assertNotEquals(null, summary.shareId, 'Should have share ID');
            System.assertNotEquals(null, summary.recipientEmail, 'Should have recipient email');
            System.assertNotEquals(null, summary.accessLevel, 'Should have access level');
            System.assertNotEquals(null, summary.expirationDate, 'Should have expiration date');
            System.assertEquals(0, summary.accessCount, 'Should have zero access count initially');
            System.assertNotEquals(null, summary.createdDate, 'Should have created date');
            System.assertNotEquals(null, summary.createdByName, 'Should have creator name');
        }
    }
    
    @IsTest
    static void testExtendShareExpiration_Success() {
        // Given
        Interview_Feedback__c feedback = [SELECT Id FROM Interview_Feedback__c LIMIT 1];
        String shareToken = FeedbackSharingService.createShareLink(
            feedback.Id, 'mentor@example.com', 'Comment', 7
        );
        
        Feedback_Share__c share = [
            SELECT Id, Expiration_Date__c FROM Feedback_Share__c WHERE Share_Token__c = :shareToken
        ];
        DateTime originalExpiration = share.Expiration_Date__c;
        
        // When
        Test.startTest();
        FeedbackSharingService.extendShareExpiration(share.Id, 14);
        Test.stopTest();
        
        // Then
        Feedback_Share__c extendedShare = [
            SELECT Expiration_Date__c FROM Feedback_Share__c WHERE Id = :share.Id
        ];
        
        DateTime expectedExpiration = originalExpiration.addDays(14);
        System.assert(Math.abs(extendedShare.Expiration_Date__c.getTime() - expectedExpiration.getTime()) < 60000, 
                     'Should extend expiration by 14 days');
    }
    
    @IsTest
    static void testExtendShareExpiration_ValidationErrors() {
        // Test null share ID
        try {
            FeedbackSharingService.extendShareExpiration(null, 7);
            System.assert(false, 'Should throw exception for null share ID');
        } catch (FeedbackSharingService.SharingException e) {
            System.assertEquals('Share ID cannot be null', e.getMessage());
        }
        
        // Test invalid additional days
        try {
            FeedbackSharingService.extendShareExpiration('a001234567890123', 0);
            System.assert(false, 'Should throw exception for zero additional days');
        } catch (FeedbackSharingService.SharingException e) {
            System.assertEquals('Additional days must be positive', e.getMessage());
        }
    }
    
    @IsTest
    static void testTokenUniqueness() {
        // Given
        Interview_Feedback__c feedback = [SELECT Id FROM Interview_Feedback__c LIMIT 1];
        
        // When - Create multiple shares
        Test.startTest();
        Set<String> tokens = new Set<String>();
        for (Integer i = 0; i < 10; i++) {
            String token = FeedbackSharingService.createShareLink(
                feedback.Id, 'mentor' + i + '@example.com', 'Read Only', 7
            );
            tokens.add(token);
        }
        Test.stopTest();
        
        // Then - All tokens should be unique
        System.assertEquals(10, tokens.size(), 'All tokens should be unique');
        
        // Verify all tokens are 32 characters
        for (String token : tokens) {
            System.assertEquals(32, token.length(), 'All tokens should be 32 characters');
        }
    }
    
    @IsTest
    static void testWrapperClasses() {
        // Test SharedFeedbackData
        FeedbackSharingService.SharedFeedbackData sharedData = new FeedbackSharingService.SharedFeedbackData();
        sharedData.shareId = 'a001234567890123';
        sharedData.feedbackId = 'a011234567890123';
        sharedData.accessLevel = 'Comment';
        sharedData.recipientEmail = 'test@example.com';
        sharedData.positionTitle = 'Software Engineer';
        
        System.assertEquals('a001234567890123', sharedData.shareId, 'Should set share ID');
        System.assertEquals('Comment', sharedData.accessLevel, 'Should set access level');
        System.assertEquals('test@example.com', sharedData.recipientEmail, 'Should set recipient email');
        
        // Test ShareSummary
        FeedbackSharingService.ShareSummary summary = new FeedbackSharingService.ShareSummary();
        summary.shareId = 'a001234567890123';
        summary.recipientEmail = 'mentor@example.com';
        summary.accessLevel = 'Full Access';
        summary.accessCount = 5;
        
        System.assertEquals('a001234567890123', summary.shareId, 'Should set share ID');
        System.assertEquals('mentor@example.com', summary.recipientEmail, 'Should set recipient email');
        System.assertEquals('Full Access', summary.accessLevel, 'Should set access level');
        System.assertEquals(5, summary.accessCount, 'Should set access count');
    }
    
    @IsTest
    static void testSharingException() {
        // Test custom exception
        try {
            throw new FeedbackSharingService.SharingException('Test sharing error');
        } catch (FeedbackSharingService.SharingException e) {
            System.assertEquals('Test sharing error', e.getMessage(), 'Should preserve exception message');
        }
    }
    
    @IsTest
    static void testSecurityAndPermissions() {
        // Create a different user to test permissions
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser' + DateTime.now().getTime() + '@example.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;
        
        // Create job application owned by test user
        Job_Application__c otherUserJobApp;
        System.runAs(testUser) {
            otherUserJobApp = InterviewFeedbackTestDataFactory.createJobApplication();
            otherUserJobApp.Position_Title__c = 'Other User Position';
            insert otherUserJobApp;
            
            Interview_Feedback__c otherUserFeedback = InterviewFeedbackTestDataFactory.createInterviewFeedback(otherUserJobApp.Id);
            insert otherUserFeedback;
        }
        
        // Current user should not be able to share other user's feedback
        Interview_Feedback__c otherFeedback = [
            SELECT Id FROM Interview_Feedback__c 
            WHERE Job_Application__r.Position_Title__c = 'Other User Position' 
            LIMIT 1
        ];
        
        try {
            FeedbackSharingService.createShareLink(otherFeedback.Id, 'mentor@example.com', 'Read Only', 7);
            System.assert(false, 'Should not allow sharing other user\'s feedback');
        } catch (FeedbackSharingService.SharingException e) {
            System.assertEquals('Insufficient permissions to access feedback', e.getMessage());
        }
    }
    
    @IsTest
    static void testBulkSharingOperations() {
        // Given - Multiple feedback records
        Job_Application__c jobApp = [SELECT Id FROM Job_Application__c LIMIT 1];
        List<Interview_Feedback__c> feedbackList = InterviewFeedbackTestDataFactory.createMultipleFeedback(jobApp.Id, 5);
        insert feedbackList;
        
        // When - Create shares for all feedback
        Test.startTest();
        List<String> tokens = new List<String>();
        for (Interview_Feedback__c feedback : feedbackList) {
            String token = FeedbackSharingService.createShareLink(
                feedback.Id, 'mentor@example.com', 'Comment', 14
            );
            tokens.add(token);
        }
        Test.stopTest();
        
        // Then - All shares should be created successfully
        System.assertEquals(5, tokens.size(), 'Should create 5 share tokens');
        
        List<Feedback_Share__c> shares = [
            SELECT Id FROM Feedback_Share__c WHERE Share_Token__c IN :tokens
        ];
        System.assertEquals(5, shares.size(), 'Should create 5 share records');
        
        // Test bulk validation
        Integer validTokens = 0;
        for (String token : tokens) {
            try {
                FeedbackSharingService.SharedFeedbackData data = 
                    FeedbackSharingService.validateAndGetSharedFeedback(token);
                if (data != null) {
                    validTokens++;
                }
            } catch (Exception e) {
                // Should not happen for valid tokens
            }
        }
        
        System.assertEquals(5, validTokens, 'All tokens should be valid');
    }
}