/**
 * @description Test class for FeedbackGDPRComplianceService
 * Tests GDPR compliance features including data access, rectification, erasure, and portability
 * @author Kiro AI Assistant
 * @date 2025
 */
@IsTest
private class FeedbackGDPRComplianceServiceTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test user
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        User testUser = new User(
            FirstName = 'GDPR',
            LastName = 'TestUser',
            Email = 'gdprtest@example.com',
            Username = 'gdprtest@feedbacktest.com',
            Alias = 'gdpr',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = standardProfile.Id
        );
        insert testUser;
        
        // Create test Job Application
        Job_Application__c testJobApp = new Job_Application__c(
            Company_Name__c = 'GDPR Test Company',
            Position_Title__c = 'Privacy Officer',
            Status__c = 'Applied',
            OwnerId = testUser.Id
        );
        insert testJobApp;
        
        // Create test Interview Feedback records
        List<Interview_Feedback__c> testFeedbacks = new List<Interview_Feedback__c>();
        
        Interview_Feedback__c feedback1 = new Interview_Feedback__c(
            Job_Application__c = testJobApp.Id,
            Interview_Type__c = 'Technical',
            Interview_Round__c = 'GDPR Round 1',
            Interviewer_Name__c = 'John Privacy',
            Interviewer_Email__c = 'john.privacy@gdprtest.com',
            Overall_Rating__c = 4,
            Technical_Rating__c = 4,
            Communication_Rating__c = 3,
            Cultural_Fit_Rating__c = 5,
            Detailed_Feedback__c = 'GDPR test feedback details',
            Strengths__c = 'Strong privacy knowledge',
            Areas_For_Improvement__c = 'Technical skills',
            Recommendation__c = 'Hire',
            Feedback_Source__c = 'Self',
            Is_Confidential__c = true,
            Feedback_Status__c = 'Submitted',
            OwnerId = testUser.Id
        );
        testFeedbacks.add(feedback1);
        
        Interview_Feedback__c feedback2 = new Interview_Feedback__c(
            Job_Application__c = testJobApp.Id,
            Interview_Type__c = 'Behavioral',
            Interview_Round__c = 'GDPR Round 2',
            Interviewer_Name__c = 'Jane Compliance',
            Interviewer_Email__c = 'jane.compliance@gdprtest.com',
            Overall_Rating__c = 3,
            Technical_Rating__c = 3,
            Communication_Rating__c = 4,
            Cultural_Fit_Rating__c = 4,
            Detailed_Feedback__c = 'GDPR behavioral feedback',
            Strengths__c = 'Good compliance understanding',
            Areas_For_Improvement__c = 'Leadership skills',
            Recommendation__c = 'Maybe',
            Feedback_Source__c = 'Interviewer',
            Is_Confidential__c = false,
            Feedback_Status__c = 'Submitted',
            OwnerId = testUser.Id
        );
        testFeedbacks.add(feedback2);
        
        insert testFeedbacks;
        
        // Create test sharing records
        Feedback_Share__c testShare = new Feedback_Share__c(
            Interview_Feedback__c = feedback1.Id,
            Shared_With_Email__c = 'mentor@gdprtest.com',
            Share_Token__c = 'gdpr-test-token-123',
            Expiration_Date__c = System.now().addDays(30),
            Access_Level__c = 'Read Only',
            Is_Active__c = true,
            Access_Count__c = 5
        );
        insert testShare;
        
        // Create test audit records
        Interview_Feedback_Audit__c testAudit = new Interview_Feedback_Audit__c(
            Event_Type__c = 'DATA_ACCESS',
            Event_Details__c = 'GDPR test audit event',
            User_Id__c = testUser.Id,
            Username__c = testUser.Username,
            Session_Id__c = 'gdpr-session-123',
            IP_Address__c = '192.168.1.100',
            Timestamp__c = System.now()
        );
        insert testAudit;
    }
    
    @IsTest
    static void testHandleDataAccessRequest_Success() {
        User testUser = [SELECT Id FROM User WHERE Username = 'gdprtest@feedbacktest.com' LIMIT 1];
        
        Test.startTest();
        
        // Test data access request
        FeedbackGDPRComplianceService.GDPRDataExport dataExport = 
            FeedbackGDPRComplianceService.handleDataAccessRequest(testUser.Id);
        
        Test.stopTest();
        
        // Verify data export was created
        System.assertNotEquals(null, dataExport, 'Data export should not be null');
        System.assertEquals(testUser.Id, dataExport.userId, 'User ID should match');
        System.assertNotEquals(null, dataExport.requestDate, 'Request date should be set');
        System.assertEquals('JSON', dataExport.exportFormat, 'Export format should be JSON');
        
        // Verify feedback data was exported
        System.assertNotEquals(null, dataExport.feedbackData, 'Feedback data should not be null');
        System.assertEquals(2, dataExport.feedbackData.size(), 'Should export 2 feedback records');
        
        // Verify sharing data was exported
        System.assertNotEquals(null, dataExport.sharingData, 'Sharing data should not be null');
        System.assertEquals(1, dataExport.sharingData.size(), 'Should export 1 sharing record');
        
        // Verify audit data was exported
        System.assertNotEquals(null, dataExport.auditData, 'Audit data should not be null');
        System.assert(dataExport.auditData.size() >= 1, 'Should export at least 1 audit record');
        
        // Verify audit logs were created
        List<Interview_Feedback_Audit__c> auditLogs = [
            SELECT Id, Event_Type__c
            FROM Interview_Feedback_Audit__c
            WHERE Event_Type__c IN ('GDPR_ACCESS_REQUEST', 'GDPR_ACCESS_COMPLETE')
        ];
        
        System.assert(!auditLogs.isEmpty(), 'GDPR access audit logs should be created');
    }
    
    @IsTest
    static void testHandleDataAccessRequest_InvalidUser() {
        Test.startTest();
        
        try {
            // Test with invalid user ID
            FeedbackGDPRComplianceService.handleDataAccessRequest('invalid_user_id');
            System.assert(false, 'Should throw exception for invalid user');
        } catch (FeedbackGDPRComplianceService.GDPRException e) {
            System.assert(e.getMessage().contains('Invalid GDPR access request'), 'Should throw GDPR exception');
        }
        
        Test.stopTest();
        
        // Verify error audit log was created
        List<Interview_Feedback_Audit__c> errorLogs = [
            SELECT Id, Event_Type__c
            FROM Interview_Feedback_Audit__c
            WHERE Event_Type__c = 'GDPR_ACCESS_ERROR'
        ];
        
        System.assert(!errorLogs.isEmpty(), 'Error audit log should be created');
    }
    
    @IsTest
    static void testHandleDataRectificationRequest_Success() {
        User testUser = [SELECT Id FROM User WHERE Username = 'gdprtest@feedbacktest.com' LIMIT 1];
        
        // Prepare rectification data
        Map<String, Object> rectificationData = new Map<String, Object>();
        rectificationData.put('Interviewer_Name__c', 'Corrected Interviewer Name');
        rectificationData.put('Interviewer_Email__c', 'corrected@gdprtest.com');
        rectificationData.put('Detailed_Feedback__c', 'Corrected feedback details');
        
        Test.startTest();
        
        // Test data rectification request
        Boolean success = FeedbackGDPRComplianceService.handleDataRectificationRequest(
            testUser.Id, 
            rectificationData
        );
        
        Test.stopTest();
        
        // Verify rectification was successful
        System.assert(success, 'Data rectification should succeed');
        
        // Verify data was actually corrected
        List<Interview_Feedback__c> correctedFeedbacks = [
            SELECT Id, Interviewer_Name__c, Interviewer_Email__c, Detailed_Feedback__c
            FROM Interview_Feedback__c
            WHERE CreatedById = :testUser.Id
        ];
        
        Boolean foundCorrectedRecord = false;
        for (Interview_Feedback__c feedback : correctedFeedbacks) {
            if (feedback.Interviewer_Name__c == 'Corrected Interviewer Name') {
                foundCorrectedRecord = true;
                System.assertEquals('corrected@gdprtest.com', feedback.Interviewer_Email__c, 'Email should be corrected');
                System.assertEquals('Corrected feedback details', feedback.Detailed_Feedback__c, 'Feedback should be corrected');
                break;
            }
        }
        
        System.assert(foundCorrectedRecord, 'At least one record should be corrected');
        
        // Verify audit logs were created
        List<Interview_Feedback_Audit__c> auditLogs = [
            SELECT Id, Event_Type__c
            FROM Interview_Feedback_Audit__c
            WHERE Event_Type__c IN ('GDPR_RECTIFICATION_REQUEST', 'GDPR_RECTIFICATION_COMPLETE', 'GDPR_FIELD_RECTIFICATION')
        ];
        
        System.assert(!auditLogs.isEmpty(), 'Rectification audit logs should be created');
    }
    
    @IsTest
    static void testHandleDataRectificationRequest_EmptyData() {
        User testUser = [SELECT Id FROM User WHERE Username = 'gdprtest@feedbacktest.com' LIMIT 1];
        
        Test.startTest();
        
        // Test with empty rectification data
        Boolean success = FeedbackGDPRComplianceService.handleDataRectificationRequest(
            testUser.Id, 
            new Map<String, Object>()
        );
        
        Test.stopTest();
        
        // Verify rectification failed
        System.assert(!success, 'Rectification should fail with empty data');
    }
    
    @IsTest
    static void testHandleDataErasureRequest_Anonymize() {
        User testUser = [SELECT Id FROM User WHERE Username = 'gdprtest@feedbacktest.com' LIMIT 1];
        
        Test.startTest();
        
        // Test data erasure with anonymization
        Boolean success = FeedbackGDPRComplianceService.handleDataErasureRequest(
            testUser.Id, 
            'ANONYMIZE'
        );
        
        Test.stopTest();
        
        // Verify erasure was successful
        System.assert(success, 'Data erasure should succeed');
        
        // Verify data was anonymized
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
        
        // Verify audit logs were created
        List<Interview_Feedback_Audit__c> auditLogs = [
            SELECT Id, Event_Type__c
            FROM Interview_Feedback_Audit__c
            WHERE Event_Type__c IN ('GDPR_ERASURE_REQUEST', 'GDPR_ERASURE_COMPLETE')
        ];
        
        System.assert(!auditLogs.isEmpty(), 'Erasure audit logs should be created');
    }
    
    @IsTest
    static void testHandleDataErasureRequest_Delete() {
        User testUser = [SELECT Id FROM User WHERE Username = 'gdprtest@feedbacktest.com' LIMIT 1];
        
        // Count records before deletion
        Integer feedbackCountBefore = [SELECT COUNT() FROM Interview_Feedback__c WHERE CreatedById = :testUser.Id];
        Integer shareCountBefore = [SELECT COUNT() FROM Feedback_Share__c WHERE CreatedById = :testUser.Id];
        
        Test.startTest();
        
        // Test data erasure with deletion
        Boolean success = FeedbackGDPRComplianceService.handleDataErasureRequest(
            testUser.Id, 
            'DELETE'
        );
        
        Test.stopTest();
        
        // Verify erasure was successful
        System.assert(success, 'Data deletion should succeed');
        
        // Verify records were deleted
        Integer feedbackCountAfter = [SELECT COUNT() FROM Interview_Feedback__c WHERE CreatedById = :testUser.Id];
        Integer shareCountAfter = [SELECT COUNT() FROM Feedback_Share__c WHERE CreatedById = :testUser.Id];
        
        System.assertEquals(0, feedbackCountAfter, 'All feedback records should be deleted');
        System.assertEquals(0, shareCountAfter, 'All sharing records should be deleted');
        
        // Verify we had records to delete
        System.assert(feedbackCountBefore > 0, 'Should have had feedback records to delete');
        System.assert(shareCountBefore > 0, 'Should have had sharing records to delete');
    }
    
    @IsTest
    static void testHandleDataErasureRequest_InvalidType() {
        User testUser = [SELECT Id FROM User WHERE Username = 'gdprtest@feedbacktest.com' LIMIT 1];
        
        Test.startTest();
        
        try {
            // Test with invalid erasure type
            FeedbackGDPRComplianceService.handleDataErasureRequest(testUser.Id, 'INVALID_TYPE');
            System.assert(false, 'Should throw exception for invalid erasure type');
        } catch (FeedbackGDPRComplianceService.GDPRException e) {
            System.assert(e.getMessage().contains('Invalid erasure type'), 'Should throw GDPR exception');
        }
        
        Test.stopTest();
        
        // Verify error audit log was created
        List<Interview_Feedback_Audit__c> errorLogs = [
            SELECT Id, Event_Type__c
            FROM Interview_Feedback_Audit__c
            WHERE Event_Type__c = 'GDPR_ERASURE_ERROR'
        ];
        
        System.assert(!errorLogs.isEmpty(), 'Error audit log should be created');
    }
    
    @IsTest
    static void testHandleDataPortabilityRequest_Success() {
        User testUser = [SELECT Id FROM User WHERE Username = 'gdprtest@feedbacktest.com' LIMIT 1];
        
        Test.startTest();
        
        // Test data portability request
        String portableData = FeedbackGDPRComplianceService.handleDataPortabilityRequest(testUser.Id);
        
        Test.stopTest();
        
        // Verify portable data was generated
        System.assertNotEquals(null, portableData, 'Portable data should not be null');
        System.assert(portableData.length() > 0, 'Portable data should not be empty');
        
        // Verify it's valid JSON
        try {
            Object parsedData = JSON.deserializeUntyped(portableData);
            System.assertNotEquals(null, parsedData, 'Should be valid JSON');
        } catch (Exception e) {
            System.assert(false, 'Portable data should be valid JSON: ' + e.getMessage());
        }
        
        // Verify audit log was created
        List<Interview_Feedback_Audit__c> auditLogs = [
            SELECT Id, Event_Type__c
            FROM Interview_Feedback_Audit__c
            WHERE Event_Type__c = 'GDPR_PORTABILITY_REQUEST'
        ];
        
        System.assert(!auditLogs.isEmpty(), 'Portability audit log should be created');
    }
    
    @IsTest
    static void testGDPRComplianceService_BulkOperations() {
        // Create additional test user with bulk data
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        User bulkTestUser = new User(
            FirstName = 'Bulk',
            LastName = 'GDPRUser',
            Email = 'bulkgdpr@example.com',
            Username = 'bulkgdpr@feedbacktest.com',
            Alias = 'bgdpr',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = standardProfile.Id
        );
        insert bulkTestUser;
        
        // Create bulk test data
        Job_Application__c bulkJobApp = new Job_Application__c(
            Company_Name__c = 'Bulk GDPR Company',
            Position_Title__c = 'Data Processor',
            Status__c = 'Applied',
            OwnerId = bulkTestUser.Id
        );
        insert bulkJobApp;
        
        List<Interview_Feedback__c> bulkFeedbacks = new List<Interview_Feedback__c>();
        for (Integer i = 0; i < 50; i++) {
            Interview_Feedback__c feedback = new Interview_Feedback__c(
                Job_Application__c = bulkJobApp.Id,
                Interview_Type__c = 'Technical',
                Interview_Round__c = 'Bulk Round ' + i,
                Interviewer_Name__c = 'Bulk Interviewer ' + i,
                Interviewer_Email__c = 'bulk' + i + '@gdprtest.com',
                Overall_Rating__c = Math.mod(i, 5) + 1,
                Detailed_Feedback__c = 'Bulk feedback details ' + i,
                Strengths__c = 'Bulk strengths ' + i,
                Areas_For_Improvement__c = 'Bulk improvements ' + i,
                Is_Confidential__c = Math.mod(i, 2) == 0,
                Feedback_Status__c = 'Submitted',
                OwnerId = bulkTestUser.Id
            );
            bulkFeedbacks.add(feedback);
        }
        insert bulkFeedbacks;
        
        Test.startTest();
        
        // Test bulk data access request
        FeedbackGDPRComplianceService.GDPRDataExport bulkDataExport = 
            FeedbackGDPRComplianceService.handleDataAccessRequest(bulkTestUser.Id);
        
        // Test bulk data anonymization
        Boolean anonymizeSuccess = FeedbackGDPRComplianceService.handleDataErasureRequest(
            bulkTestUser.Id, 
            'ANONYMIZE'
        );
        
        Test.stopTest();
        
        // Verify bulk operations completed successfully
        System.assertNotEquals(null, bulkDataExport, 'Bulk data export should not be null');
        System.assertEquals(50, bulkDataExport.feedbackData.size(), 'Should export all 50 feedback records');
        System.assert(anonymizeSuccess, 'Bulk anonymization should succeed');
        
        // Verify bulk anonymization worked
        List<Interview_Feedback__c> anonymizedBulkFeedbacks = [
            SELECT Id, Detailed_Feedback__c, Strengths__c, Areas_For_Improvement__c
            FROM Interview_Feedback__c
            WHERE CreatedById = :bulkTestUser.Id
        ];
        
        for (Interview_Feedback__c feedback : anonymizedBulkFeedbacks) {
            System.assertEquals('[ANONYMIZED]', feedback.Detailed_Feedback__c, 'Bulk feedback should be anonymized');
            System.assertEquals('[ANONYMIZED]', feedback.Strengths__c, 'Bulk strengths should be anonymized');
            System.assertEquals('[ANONYMIZED]', feedback.Areas_For_Improvement__c, 'Bulk improvements should be anonymized');
        }
    }
}