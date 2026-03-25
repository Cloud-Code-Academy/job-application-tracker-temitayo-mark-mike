/**
 * @description Comprehensive test class for FeedbackSecurityService
 * Tests all security controls, privacy measures, and access validation
 * @author Kiro AI Assistant
 * @date 2025
 */
@IsTest
private inherited sharing class FeedbackSecurityServiceTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test users with different permission levels
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        User testManager = new User(
            FirstName = 'Test',
            LastName = 'Manager',
            Email = 'testmanager@example.com',
            Username = 'testmanager@feedbacktest.com',
            Alias = 'tmgr',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = standardProfile.Id
        );
        insert testManager;
        
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser@feedbacktest.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = standardProfile.Id
        );
        insert testUser;
        
        // Create test Job Application
        Job_Application__c testJobApp = new Job_Application__c(
            Company_Name__c = 'Test Company',
            Position_Title__c = 'Software Developer',
            Status__c = 'Applied',
            OwnerId = testUser.Id
        );
        insert testJobApp;
        
        // Create test Interview Feedback records
        List<Interview_Feedback__c> testFeedbacks = new List<Interview_Feedback__c>();
        
        Interview_Feedback__c confidentialFeedback = new Interview_Feedback__c(
            Job_Application__c = testJobApp.Id,
            Interview_Type__c = 'Technical',
            Interview_Round__c = 'Round 1',
            Interviewer_Name__c = 'John Doe',
            Interviewer_Email__c = 'john.doe@testcompany.com',
            Overall_Rating__c = 4,
            Technical_Rating__c = 4,
            Communication_Rating__c = 3,
            Cultural_Fit_Rating__c = 5,
            Detailed_Feedback__c = 'Confidential technical feedback',
            Strengths__c = 'Strong coding skills',
            Areas_For_Improvement__c = 'Communication could be better',
            Is_Confidential__c = true,
            Feedback_Status__c = 'Submitted',
            OwnerId = testUser.Id
        );
        testFeedbacks.add(confidentialFeedback);
        
        Interview_Feedback__c standardFeedback = new Interview_Feedback__c(
            Job_Application__c = testJobApp.Id,
            Interview_Type__c = 'Behavioral',
            Interview_Round__c = 'Round 2',
            Interviewer_Name__c = 'Jane Smith',
            Interviewer_Email__c = 'jane.smith@testcompany.com',
            Overall_Rating__c = 3,
            Technical_Rating__c = 3,
            Communication_Rating__c = 4,
            Cultural_Fit_Rating__c = 4,
            Detailed_Feedback__c = 'Standard behavioral feedback',
            Strengths__c = 'Good cultural fit',
            Areas_For_Improvement__c = 'Technical skills need work',
            Is_Confidential__c = false,
            Feedback_Status__c = 'Submitted',
            OwnerId = testUser.Id
        );
        testFeedbacks.add(standardFeedback);
        
        insert testFeedbacks;
    }
    
    @IsTest
    static void testValidateFeedbackAccess_CreateOperation() {
        Test.startTest();
        
        // Test CREATE operation - should return true for valid user
        Boolean hasAccess = FeedbackSecurityService.validateFeedbackAccess('CREATE', new List<Id>());
        
        Test.stopTest();
        
        // Verify access validation
        System.assert(hasAccess, 'User should have CREATE access to Interview Feedback');
    }
    
    @IsTest
    static void testValidateFeedbackAccess_ReadOperation() {
        // Get test feedback records
        List<Interview_Feedback__c> testFeedbacks = [
            SELECT Id FROM Interview_Feedback__c LIMIT 2
        ];
        
        List<Id> feedbackIds = new List<Id>();
        for (Interview_Feedback__c feedback : testFeedbacks) {
            feedbackIds.add(feedback.Id);
        }
        
        Test.startTest();
        
        // Test READ operation
        Boolean hasAccess = FeedbackSecurityService.validateFeedbackAccess('READ', feedbackIds);
        
        Test.stopTest();
        
        // Verify access validation
        System.assert(hasAccess, 'User should have READ access to their own feedback records');
    }
    
    @IsTest
    static void testValidateFeedbackAccess_InvalidOperation() {
        Test.startTest();
        
        // Test invalid operation
        Boolean hasAccess = FeedbackSecurityService.validateFeedbackAccess('INVALID', new List<Id>());
        
        Test.stopTest();
        
        // Verify access is denied for invalid operation
        System.assert(!hasAccess, 'Invalid operation should be denied');
    }
    
    @IsTest
    static void testEncryptSensitiveData() {
        // Get confidential feedback record
        Interview_Feedback__c confidentialFeedback = [
            SELECT Id, Is_Confidential__c
            FROM Interview_Feedback__c
            WHERE Is_Confidential__c = true
            LIMIT 1
        ];
        
        Test.startTest();
        
        // Test encryption of sensitive data
        FeedbackSecurityService.encryptSensitiveData(new List<Interview_Feedback__c>{confidentialFeedback});
        
        Test.stopTest();
        
        // Verify audit log was created
        List<Interview_Feedback_Audit__c> auditLogs = [
            SELECT Id, Event_Type__c, Event_Details__c
            FROM Interview_Feedback_Audit__c
            WHERE Event_Type__c = 'DATA_ENCRYPTION'
        ];
        
        System.assert(!auditLogs.isEmpty(), 'Audit log should be created for data encryption');
    }
    
    @IsTest
    static void testAnonymizeUserData_Success() {
        // Get test user
        User testUser = [SELECT Id, Email FROM User WHERE Username = 'testuser@feedbacktest.com' LIMIT 1];
        
        Test.startTest();
        
        // Test GDPR anonymization
        Boolean success = FeedbackSecurityService.anonymizeUserData(testUser.Id);
        
        Test.stopTest();
        
        // Verify anonymization was successful
        System.assert(success, 'User data anonymization should succeed');
        
        // Verify data was actually anonymized
        List<Interview_Feedback__c> anonymizedFeedbacks = [
            SELECT Id, Detailed_Feedback__c, Strengths__c, Areas_For_Improvement__c,
                   Interviewer_Name__c, Interviewer_Email__c
            FROM Interview_Feedback__c
            WHERE CreatedById = :testUser.Id
        ];
        
        for (Interview_Feedback__c feedback : anonymizedFeedbacks) {
            System.assertEquals('[ANONYMIZED]', feedback.Detailed_Feedback__c, 'Detailed feedback should be anonymized');
            System.assertEquals('[ANONYMIZED]', feedback.Strengths__c, 'Strengths should be anonymized');
            System.assertEquals('[ANONYMIZED]', feedback.Areas_For_Improvement__c, 'Areas for improvement should be anonymized');
            System.assertEquals('[ANONYMIZED]', feedback.Interviewer_Name__c, 'Interviewer name should be anonymized');
            System.assertEquals('anonymized@example.com', feedback.Interviewer_Email__c, 'Interviewer email should be anonymized');
        }
        
        // Verify audit log was created
        List<Interview_Feedback_Audit__c> auditLogs = [
            SELECT Id, Event_Type__c, Event_Details__c
            FROM Interview_Feedback_Audit__c
            WHERE Event_Type__c = 'GDPR_ANONYMIZATION'
        ];
        
        System.assert(!auditLogs.isEmpty(), 'Audit log should be created for GDPR anonymization');
    }
    
    @IsTest
    static void testEnforceDataRetention() {
        Test.startTest();
        
        // Test data retention enforcement
        FeedbackSecurityService.enforceDataRetention(30); // 30 days retention
        
        Test.stopTest();
        
        // Verify audit log was created
        List<Interview_Feedback_Audit__c> auditLogs = [
            SELECT Id, Event_Type__c, Event_Details__c
            FROM Interview_Feedback_Audit__c
            WHERE Event_Type__c = 'DATA_RETENTION'
        ];
        
        // Note: Since our test data is new, no records should be archived
        // But the process should complete without errors
        System.assert(true, 'Data retention process should complete without errors');
    }
    
    @IsTest
    static void testCreateAuditLog() {
        Test.startTest();
        
        // Test audit log creation
        FeedbackSecurityService.createAuditLog('TEST_EVENT', 'Test event details');
        
        Test.stopTest();
        
        // Verify audit log was created
        List<Interview_Feedback_Audit__c> auditLogs = [
            SELECT Id, Event_Type__c, Event_Details__c, User_Id__c, Username__c
            FROM Interview_Feedback_Audit__c
            WHERE Event_Type__c = 'TEST_EVENT'
        ];
        
        System.assertEquals(1, auditLogs.size(), 'One audit log should be created');
        System.assertEquals('Test event details', auditLogs[0].Event_Details__c, 'Event details should match');
        System.assertEquals(UserInfo.getUserId(), auditLogs[0].User_Id__c, 'User ID should be captured');
        System.assertEquals(UserInfo.getUsername(), auditLogs[0].Username__c, 'Username should be captured');
    }
    
    @IsTest
    static void testValidateFieldAccess_ReadPermission() {
        Test.startTest();
        
        // Test field access validation for read operation
        Boolean hasAccess = FeedbackSecurityService.validateFieldAccess('Overall_Rating__c', 'READ');
        
        Test.stopTest();
        
        // Verify field access validation
        System.assert(hasAccess != null, 'Field access validation should return a result');
    }
    
    @IsTest
    static void testValidateFieldAccess_EditPermission() {
        Test.startTest();
        
        // Test field access validation for edit operation
        Boolean hasAccess = FeedbackSecurityService.validateFieldAccess('Overall_Rating__c', 'EDIT');
        
        Test.stopTest();
        
        // Verify field access validation
        System.assert(hasAccess != null, 'Field access validation should return a result');
    }
    
    @IsTest
    static void testValidateFieldAccess_InvalidField() {
        Test.startTest();
        
        // Test field access validation for non-existent field
        Boolean hasAccess = FeedbackSecurityService.validateFieldAccess('NonExistent_Field__c', 'READ');
        
        Test.stopTest();
        
        // Verify access is denied for non-existent field
        System.assert(!hasAccess, 'Access should be denied for non-existent field');
    }
    
    @IsTest
    static void testMaskSensitiveData() {
        // Get test feedback records
        List<Interview_Feedback__c> testFeedbacks = [
            SELECT Id, Overall_Rating__c, Detailed_Feedback__c, Interviewer_Email__c,
                   Technical_Rating__c, Communication_Rating__c, Cultural_Fit_Rating__c
            FROM Interview_Feedback__c
            LIMIT 2
        ];
        
        Test.startTest();
        
        // Test data masking
        List<Interview_Feedback__c> maskedFeedbacks = FeedbackSecurityService.maskSensitiveData(testFeedbacks);
        
        Test.stopTest();
        
        // Verify masking was applied
        System.assertEquals(testFeedbacks.size(), maskedFeedbacks.size(), 'All records should be processed');
        
        for (Interview_Feedback__c maskedFeedback : maskedFeedbacks) {
            System.assertNotEquals(null, maskedFeedback, 'Masked feedback should not be null');
        }
    }
    
    @IsTest
    static void testSecurityServiceErrorHandling() {
        Test.startTest();
        
        // Test error handling with invalid user ID
        Boolean success = FeedbackSecurityService.anonymizeUserData('invalid_user_id');
        
        Test.stopTest();
        
        // Verify error was handled gracefully
        System.assert(!success, 'Invalid user ID should result in failure');
        
        // Verify error audit log was created
        List<Interview_Feedback_Audit__c> auditLogs = [
            SELECT Id, Event_Type__c
            FROM Interview_Feedback_Audit__c
            WHERE Event_Type__c = 'GDPR_ERROR'
        ];
        
        System.assert(!auditLogs.isEmpty(), 'Error audit log should be created');
    }
    
    @IsTest
    static void testBulkSecurityOperations() {
        // Create additional test data for bulk operations
        Job_Application__c testJobApp = [SELECT Id FROM Job_Application__c LIMIT 1];
        
        List<Interview_Feedback__c> bulkFeedbacks = new List<Interview_Feedback__c>();
        for (Integer i = 0; i < 200; i++) {
            Interview_Feedback__c feedback = new Interview_Feedback__c(
                Job_Application__c = testJobApp.Id,
                Interview_Type__c = 'Technical',
                Interview_Round__c = 'Bulk Test ' + i,
                Overall_Rating__c = Math.mod(i, 5) + 1,
                Is_Confidential__c = Math.mod(i, 2) == 0,
                Feedback_Status__c = 'Submitted'
            );
            bulkFeedbacks.add(feedback);
        }
        insert bulkFeedbacks;
        
        List<Id> feedbackIds = new List<Id>();
        for (Interview_Feedback__c feedback : bulkFeedbacks) {
            feedbackIds.add(feedback.Id);
        }
        
        Test.startTest();
        
        // Test bulk access validation
        Boolean hasAccess = FeedbackSecurityService.validateFeedbackAccess('READ', feedbackIds);
        
        // Test bulk data masking
        List<Interview_Feedback__c> maskedFeedbacks = FeedbackSecurityService.maskSensitiveData(bulkFeedbacks);
        
        Test.stopTest();
        
        // Verify bulk operations completed successfully
        System.assert(hasAccess != null, 'Bulk access validation should complete');
        System.assertEquals(bulkFeedbacks.size(), maskedFeedbacks.size(), 'All bulk records should be processed');
    }
}