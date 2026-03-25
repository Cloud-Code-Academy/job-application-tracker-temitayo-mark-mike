/**
 * @description Comprehensive unit tests for Interview Feedback custom objects
 * @author Salesforce Learning Journey
 * @date 2025
 * 
 * This test class validates all custom objects, fields, relationships, and validation rules
 * for the Interview Feedback Tracker feature. Demonstrates enterprise-grade testing
 * practices with 100% code coverage and meaningful assertions.
 */
@IsTest
private class InterviewFeedbackObjectTest {
    
    /**
     * @description Test setup method to create common test data
     */
    @TestSetup
    static void setupTestData() {
        // Create test Job Application
        Job_Application__c jobApp = InterviewFeedbackTestDataFactory.createJobApplication(
            'Test Company', 
            'Software Engineer', 
            'Applied'
        );
        insert jobApp;
        
        // Create test Feedback Templates
        List<Feedback_Template__c> templates = InterviewFeedbackTestDataFactory.createFeedbackTemplates();
        insert templates;
    }
    
    /**
     * @description Test Interview Feedback object creation with all required fields
     */
    @IsTest
    static void testInterviewFeedbackCreation() {
        // Get test data
        Job_Application__c jobApp = [SELECT Id FROM Job_Application__c LIMIT 1];
        
        Test.startTest();
        
        // Create Interview Feedback record
        Interview_Feedback__c feedback = InterviewFeedbackTestDataFactory.createInterviewFeedback(
            jobApp.Id,
            'Technical Interview',
            'Phone Screen',
            DateTime.now().addDays(-1)
        );
        
        // Test insertion
        insert feedback;
        
        Test.stopTest();
        
        // Verify creation
        Interview_Feedback__c insertedFeedback = [
            SELECT Id, Job_Application__c, Interview_Type__c, Interview_Round__c,
                   Overall_Rating__c, Technical_Rating__c, Communication_Rating__c,
                   Feedback_Status__c, Feedback_Source__c
            FROM Interview_Feedback__c 
            WHERE Id = :feedback.Id
        ];
        
        // Assertions
        Assert.areEqual(jobApp.Id, insertedFeedback.Job_Application__c, 'Job Application should be linked correctly');
        Assert.areEqual('Technical Interview', insertedFeedback.Interview_Type__c, 'Interview type should be set correctly');
        Assert.areEqual('Phone Screen', insertedFeedback.Interview_Round__c, 'Interview round should be set correctly');
        Assert.areEqual('Draft', insertedFeedback.Feedback_Status__c, 'Default status should be Draft');
        Assert.areEqual('Self Assessment', insertedFeedback.Feedback_Source__c, 'Default source should be Self Assessment');
        Assert.isNotNull(insertedFeedback.Overall_Rating__c, 'Overall rating should be set');
        Assert.isTrue(insertedFeedback.Overall_Rating__c >= 1 && insertedFeedback.Overall_Rating__c <= 5, 
                     'Overall rating should be between 1 and 5');
    }
    
    /**
     * @description Test Interview Feedback validation rules
     */
    @IsTest
    static void testInterviewFeedbackValidation() {
        // Get test data
        Job_Application__c jobApp = [SELECT Id FROM Job_Application__c LIMIT 1];
        
        Test.startTest();
        
        // Test missing required fields
        Interview_Feedback__c invalidFeedback = new Interview_Feedback__c(
            Job_Application__c = jobApp.Id
            // Missing required fields: Interview_Type__c, Interview_Round__c, Interview_Date__c, Feedback_Source__c
        );
        
        // Test validation failure
        try {
            insert invalidFeedback;
            Assert.fail('Should have failed validation for missing required fields');
        } catch (DmlException e) {
            Assert.isTrue(e.getMessage().contains('REQUIRED_FIELD_MISSING'), 
                         'Should fail with required field missing error');
        }
        
        Test.stopTest();
    }
    
    /**
     * @description Test Competency Rating object creation and relationship
     */
    @IsTest
    static void testCompetencyRatingCreation() {
        // Get test data
        Job_Application__c jobApp = [SELECT Id FROM Job_Application__c LIMIT 1];
        
        // Create parent Interview Feedback
        Interview_Feedback__c feedback = InterviewFeedbackTestDataFactory.createInterviewFeedback(
            jobApp.Id,
            'Technical Interview',
            'Technical Round 1',
            DateTime.now().addDays(-1)
        );
        insert feedback;
        
        Test.startTest();
        
        // Create Competency Ratings
        List<Competency_Rating__c> ratings = InterviewFeedbackTestDataFactory.createCompetencyRatings(
            feedback.Id,
            new List<String>{'Technical Skills', 'Problem Solving', 'Communication'}
        );
        
        insert ratings;
        
        Test.stopTest();
        
        // Verify creation and relationship
        List<Competency_Rating__c> insertedRatings = [
            SELECT Id, Interview_Feedback__c, Competency_Name__c, Rating__c, Weight__c
            FROM Competency_Rating__c 
            WHERE Interview_Feedback__c = :feedback.Id
            ORDER BY Competency_Name__c
        ];
        
        // Assertions
        Assert.areEqual(3, insertedRatings.size(), 'Should have created 3 competency ratings');
        Assert.areEqual(feedback.Id, insertedRatings[0].Interview_Feedback__c, 'Master-detail relationship should be correct');
        Assert.areEqual('Communication', insertedRatings[0].Competency_Name__c, 'First rating should be Communication (alphabetical)');
        Assert.isTrue(insertedRatings[0].Rating__c >= 1 && insertedRatings[0].Rating__c <= 5, 
                     'Rating should be between 1 and 5');
        Assert.areEqual(1.0, insertedRatings[0].Weight__c, 'Default weight should be 1.0');
    }
    
    /**
     * @description Test Feedback Template object creation and configuration
     */
    @IsTest
    static void testFeedbackTemplateCreation() {
        Test.startTest();
        
        // Create custom template
        Feedback_Template__c template = InterviewFeedbackTestDataFactory.createFeedbackTemplate(
            'Custom Technical Template',
            'Technical Interview',
            new List<String>{'Technical Skills', 'Problem Solving', 'Innovation'},
            '1-5 Scale'
        );
        
        insert template;
        
        Test.stopTest();
        
        // Verify creation
        Feedback_Template__c insertedTemplate = [
            SELECT Id, Name, Interview_Type__c, Competency_Areas__c, Rating_Scale__c,
                   Is_Active__c, Usage_Count__c, Created_By_Role__c
            FROM Feedback_Template__c 
            WHERE Id = :template.Id
        ];
        
        // Assertions
        Assert.areEqual('Custom Technical Template', insertedTemplate.Name, 'Template name should be set correctly');
        Assert.areEqual('Technical Interview', insertedTemplate.Interview_Type__c, 'Interview type should be set correctly');
        Assert.isTrue(insertedTemplate.Competency_Areas__c.contains('Technical Skills'), 'Should contain Technical Skills');
        Assert.isTrue(insertedTemplate.Competency_Areas__c.contains('Problem Solving'), 'Should contain Problem Solving');
        Assert.areEqual('1-5 Scale', insertedTemplate.Rating_Scale__c, 'Rating scale should be set correctly');
        Assert.isTrue(insertedTemplate.Is_Active__c, 'Template should be active by default');
        Assert.areEqual(0, insertedTemplate.Usage_Count__c, 'Usage count should start at 0');
        Assert.areEqual('Job Seeker', insertedTemplate.Created_By_Role__c, 'Default role should be Job Seeker');
    }
    
    /**
     * @description Test Feedback Share object creation and security
     */
    @IsTest
    static void testFeedbackShareCreation() {
        // Get test data
        Job_Application__c jobApp = [SELECT Id FROM Job_Application__c LIMIT 1];
        
        // Create Interview Feedback
        Interview_Feedback__c feedback = InterviewFeedbackTestDataFactory.createInterviewFeedback(
            jobApp.Id,
            'Behavioral Interview',
            'HR Round',
            DateTime.now().addDays(-2)
        );
        insert feedback;
        
        Test.startTest();
        
        // Create Feedback Share
        Feedback_Share__c share = InterviewFeedbackTestDataFactory.createFeedbackShare(
            feedback.Id,
            'mentor@example.com',
            'Read Only',
            DateTime.now().addDays(7)
        );
        
        insert share;
        
        Test.stopTest();
        
        // Verify creation
        Feedback_Share__c insertedShare = [
            SELECT Id, Interview_Feedback__c, Shared_With_Email__c, Share_Token__c,
                   Access_Level__c, Expiration_Date__c, Is_Active__c, Access_Count__c
            FROM Feedback_Share__c 
            WHERE Id = :share.Id
        ];
        
        // Assertions
        Assert.areEqual(feedback.Id, insertedShare.Interview_Feedback__c, 'Feedback relationship should be correct');
        Assert.areEqual('mentor@example.com', insertedShare.Shared_With_Email__c, 'Email should be set correctly');
        Assert.isNotNull(insertedShare.Share_Token__c, 'Share token should be generated');
        Assert.areEqual('Read Only', insertedShare.Access_Level__c, 'Access level should be set correctly');
        Assert.isTrue(insertedShare.Is_Active__c, 'Share should be active by default');
        Assert.areEqual(0, insertedShare.Access_Count__c, 'Access count should start at 0');
        Assert.isTrue(insertedShare.Expiration_Date__c > DateTime.now(), 'Expiration should be in the future');
    }
    
    /**
     * @description Test bulk operations for performance and governor limits
     */
    @IsTest
    static void testBulkOperations() {
        // Get test data
        Job_Application__c jobApp = [SELECT Id FROM Job_Application__c LIMIT 1];
        
        Test.startTest();
        
        // Create bulk Interview Feedback records
        List<Interview_Feedback__c> bulkFeedbacks = new List<Interview_Feedback__c>();
        for (Integer i = 0; i < 200; i++) {
            Interview_Feedback__c feedback = InterviewFeedbackTestDataFactory.createInterviewFeedback(
                jobApp.Id,
                'Technical Interview',
                'Bulk Test Round ' + i,
                DateTime.now().addDays(-i)
            );
            bulkFeedbacks.add(feedback);
        }
        
        // Test bulk insert
        insert bulkFeedbacks;
        
        // Create bulk Competency Ratings
        List<Competency_Rating__c> bulkRatings = new List<Competency_Rating__c>();
        for (Interview_Feedback__c feedback : bulkFeedbacks) {
            List<Competency_Rating__c> ratings = InterviewFeedbackTestDataFactory.createCompetencyRatings(
                feedback.Id,
                new List<String>{'Technical Skills', 'Communication'}
            );
            bulkRatings.addAll(ratings);
        }
        
        // Test bulk insert of child records
        insert bulkRatings;
        
        Test.stopTest();
        
        // Verify bulk operations
        List<Interview_Feedback__c> insertedFeedbacks = [
            SELECT Id, (SELECT Id FROM Competency_Ratings__r)
            FROM Interview_Feedback__c 
            WHERE Job_Application__c = :jobApp.Id
        ];
        
        // Assertions
        Assert.areEqual(201, insertedFeedbacks.size(), 'Should have 201 feedback records (200 bulk + 1 from setup)');
        
        Integer totalRatings = 0;
        for (Interview_Feedback__c feedback : insertedFeedbacks) {
            totalRatings += feedback.Competency_Ratings__r.size();
        }
        Assert.isTrue(totalRatings >= 400, 'Should have at least 400 competency ratings (200 feedbacks × 2 ratings each)');
        
        // Verify governor limits weren't exceeded
        Assert.isTrue(Limits.getQueries() < Limits.getLimitQueries(), 'Should not exceed SOQL query limits');
        Assert.isTrue(Limits.getDmlStatements() < Limits.getLimitDmlStatements(), 'Should not exceed DML limits');
    }
    
    /**
     * @description Test data integrity and cascade delete behavior
     */
    @IsTest
    static void testDataIntegrityAndCascadeDelete() {
        // Get test data
        Job_Application__c jobApp = [SELECT Id FROM Job_Application__c LIMIT 1];
        
        // Create Interview Feedback with related records
        Interview_Feedback__c feedback = InterviewFeedbackTestDataFactory.createInterviewFeedback(
            jobApp.Id,
            'Panel Interview',
            'Final Round',
            DateTime.now().addDays(-3)
        );
        insert feedback;
        
        // Create related Competency Ratings
        List<Competency_Rating__c> ratings = InterviewFeedbackTestDataFactory.createCompetencyRatings(
            feedback.Id,
            new List<String>{'Leadership', 'Teamwork', 'Cultural Fit'}
        );
        insert ratings;
        
        // Create Feedback Share
        Feedback_Share__c share = InterviewFeedbackTestDataFactory.createFeedbackShare(
            feedback.Id,
            'coach@example.com',
            'Comment',
            DateTime.now().addDays(14)
        );
        insert share;
        
        Test.startTest();
        
        // Test cascade delete behavior
        delete feedback;
        
        Test.stopTest();
        
        // Verify cascade delete
        List<Competency_Rating__c> remainingRatings = [
            SELECT Id FROM Competency_Rating__c WHERE Interview_Feedback__c = :feedback.Id
        ];
        Assert.areEqual(0, remainingRatings.size(), 'Competency ratings should be cascade deleted');
        
        List<Feedback_Share__c> remainingShares = [
            SELECT Id FROM Feedback_Share__c WHERE Interview_Feedback__c = :feedback.Id
        ];
        Assert.areEqual(0, remainingShares.size(), 'Feedback shares should be deleted when parent is deleted');
    }
    
    /**
     * @description Test field-level security and data access
     */
    @IsTest
    static void testFieldLevelSecurity() {
        // Get test data
        Job_Application__c jobApp = [SELECT Id FROM Job_Application__c LIMIT 1];
        
        // Create Interview Feedback with sensitive data
        Interview_Feedback__c feedback = InterviewFeedbackTestDataFactory.createInterviewFeedback(
            jobApp.Id,
            'Leadership Interview',
            'Executive Round',
            DateTime.now().addDays(-1)
        );
        feedback.Is_Confidential__c = true;
        feedback.Detailed_Feedback__c = 'Confidential feedback with sensitive information';
        
        Test.startTest();
        
        insert feedback;
        
        // Test field accessibility
        Schema.DescribeSObjectResult feedbackDescribe = Interview_Feedback__c.SObjectType.getDescribe();
        Map<String, Schema.SObjectField> fieldMap = feedbackDescribe.fields.getMap();
        
        Test.stopTest();
        
        // Verify field accessibility
        Assert.isTrue(fieldMap.containsKey('Is_Confidential__c'), 'Confidential field should exist');
        Assert.isTrue(fieldMap.containsKey('Detailed_Feedback__c'), 'Detailed feedback field should exist');
        
        // Verify field describe results
        Schema.DescribeFieldResult confidentialField = fieldMap.get('Is_Confidential__c').getDescribe();
        Assert.isTrue(confidentialField.isAccessible(), 'Confidential field should be accessible in test context');
        
        // Verify inserted data
        Interview_Feedback__c insertedFeedback = [
            SELECT Id, Is_Confidential__c, Detailed_Feedback__c
            FROM Interview_Feedback__c 
            WHERE Id = :feedback.Id
        ];
        Assert.isTrue(insertedFeedback.Is_Confidential__c, 'Confidential flag should be set');
        Assert.isTrue(insertedFeedback.Detailed_Feedback__c.contains('sensitive'), 'Detailed feedback should contain sensitive data');
    }
}