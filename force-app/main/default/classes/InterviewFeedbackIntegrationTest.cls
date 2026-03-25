/**
 * @description Comprehensive integration tests for Interview Feedback Tracker
 * Tests complete end-to-end workflows from feedback creation to analytics
 * @author Salesforce Developer
 * @date 2024
 */
@IsTest
public inherited sharing class InterviewFeedbackIntegrationTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test Job Applications
        List<Job_Application__c> jobApps = InterviewFeedbackTestDataFactory.createJobApplications(5);
        insert jobApps;
        
        // Create test Feedback Templates
        List<Feedback_Template__c> templates = InterviewFeedbackTestDataFactory.createFeedbackTemplates(3);
        insert templates;
        
        // Create test users with different permission levels
        List<User> testUsers = InterviewFeedbackTestDataFactory.createTestUsers(3);
        insert testUsers;
    }
    
    /**
     * @description Test complete feedback creation to analytics workflow
     * Requirements: 1.1, 1.2, 3.1, 3.2, 4.1, 4.2
     */
    @IsTest
    static void testEndToEndFeedbackWorkflow() {
        // Get test data
        Job_Application__c jobApp = [SELECT Id FROM Job_Application__c LIMIT 1];
        Feedback_Template__c template = [SELECT Id FROM Feedback_Template__c LIMIT 1];
        
        Test.startTest();
        
        // Step 1: Create interview feedback
        Interview_Feedback__c feedback = InterviewFeedbackService.createFeedback(
            jobApp.Id,
            'Technical',
            new Map<String, Object>{
                'interviewer_name' => 'John Smith',
                'interviewer_email' => 'john.smith@company.com',
                'overall_rating' => 4,
                'technical_rating' => 4,
                'communication_rating' => 3,
                'detailed_feedback' => 'Strong technical skills, good problem solving'
            }
        );
        
        System.assertNotEquals(null, feedback.Id, 'Feedback should be created successfully');
        
        // Step 2: Add competency ratings
        List<Competency_Rating__c> competencies = new List<Competency_Rating__c>{
            new Competency_Rating__c(
                Interview_Feedback__c = feedback.Id,
                Competency_Name__c = 'Problem Solving',
                Rating__c = 4,
                Comments__c = 'Excellent analytical thinking'
            ),
            new Competency_Rating__c(
                Interview_Feedback__c = feedback.Id,
                Competency_Name__c = 'Communication',
                Rating__c = 3,
                Comments__c = 'Clear but could be more concise'
            )
        };
        insert competencies;
        
        // Step 3: Generate analytics
        FeedbackAnalyticsService.PerformanceTrend trends = 
            FeedbackAnalyticsService.calculateTrends(jobApp.Id, 90);
        
        System.assertNotEquals(null, trends, 'Performance trends should be calculated');
        
        // Step 4: Generate dashboard data
        FeedbackAnalyticsService.DashboardData dashboardData = 
            FeedbackAnalyticsService.generateDashboardData(UserInfo.getUserId());
        
        System.assertNotEquals(null, dashboardData, 'Dashboard data should be generated');
        System.assert(dashboardData.totalFeedbacks > 0, 'Should have feedback count');
        
        // Step 5: Create sharing link
        String shareLink = FeedbackSharingService.createShareLink(
            feedback.Id,
            'mentor@company.com',
            'Read Only'
        );
        
        System.assertNotEquals(null, shareLink, 'Share link should be created');
        
        Test.stopTest();
        
        // Verify Job Application was updated
        Job_Application__c updatedJobApp = [
            SELECT Id, Interview_Count__c, Average_Interview_Rating__c
            FROM Job_Application__c 
            WHERE Id = :jobApp.Id
        ];
        
        System.assertEquals(1, updatedJobApp.Interview_Count__c, 'Interview count should be updated');
        System.assertEquals(4, updatedJobApp.Average_Interview_Rating__c, 'Average rating should be calculated');
    }
    
    /**
     * @description Test bulk feedback processing workflow
     * Requirements: 10.1, 10.2
     */
    @IsTest
    static void testBulkFeedbackProcessing() {
        List<Job_Application__c> jobApps = [SELECT Id FROM Job_Application__c];
        
        Test.startTest();
        
        // Create bulk feedback records
        List<Interview_Feedback__c> bulkFeedbacks = new List<Interview_Feedback__c>();
        for (Job_Application__c jobApp : jobApps) {
            for (Integer i = 0; i < 50; i++) {
                bulkFeedbacks.add(new Interview_Feedback__c(
                    Job_Application__c = jobApp.Id,
                    Interview_Type__c = 'Technical',
                    Interviewer_Name__c = 'Interviewer ' + i,
                    Overall_Rating__c = Math.mod(i, 5) + 1,
                    Technical_Rating__c = Math.mod(i, 5) + 1,
                    Communication_Rating__c = Math.mod(i, 5) + 1,
                    Interview_Date__c = System.now().addDays(-i)
                ));
            }
        }
        
        // Test bulk insert
        Database.SaveResult[] results = Database.insert(bulkFeedbacks, false);
        
        // Verify all records were processed
        Integer successCount = 0;
        for (Database.SaveResult result : results) {
            if (result.isSuccess()) {
                successCount++;
            }
        }
        
        System.assertEquals(bulkFeedbacks.size(), successCount, 'All bulk records should be processed');
        
        // Test bulk analytics calculation
        for (Job_Application__c jobApp : jobApps) {
            FeedbackAnalyticsService.CompetencyAnalysis analysis = 
                FeedbackAnalyticsService.analyzeCompetencies([
                    SELECT Id, Technical_Rating__c, Communication_Rating__c, Overall_Rating__c
                    FROM Interview_Feedback__c 
                    WHERE Job_Application__c = :jobApp.Id
                ]);
            
            System.assertNotEquals(null, analysis, 'Competency analysis should handle bulk data');
        }
        
        Test.stopTest();
    }
    
    /**
     * @description Test sharing workflow with mentor collaboration
     * Requirements: 5.1, 5.2, 5.3, 5.4
     */
    @IsTest
    static void testSharingCollaborationWorkflow() {
        Interview_Feedback__c feedback = [SELECT Id FROM Interview_Feedback__c LIMIT 1];
        
        Test.startTest();
        
        // Step 1: Create share
        String shareToken = FeedbackSharingService.createShareLink(
            feedback.Id,
            'mentor@company.com',
            'Comment'
        );
        
        System.assertNotEquals(null, shareToken, 'Share token should be created');
        
        // Step 2: Validate access
        Boolean hasAccess = FeedbackSharingService.validateShareAccess(shareToken);
        System.assertEquals(true, hasAccess, 'Share access should be valid');
        
        // Step 3: Add mentor comment
        FeedbackSharingService.addMentorComment(
            shareToken,
            'Great progress on technical skills. Focus on communication clarity.'
        );
        
        // Step 4: Verify comment was added
        List<Feedback_Share__c> shares = [
            SELECT Id, Mentor_Comments__c 
            FROM Feedback_Share__c 
            WHERE Share_Token__c = :shareToken
        ];
        
        System.assertEquals(1, shares.size(), 'Share record should exist');
        System.assert(shares[0].Mentor_Comments__c.contains('Great progress'), 'Comment should be added');
        
        // Step 5: Revoke access
        FeedbackSharingService.revokeAccess(shares[0].Id);
        
        // Step 6: Verify access is revoked
        Boolean accessAfterRevoke = FeedbackSharingService.validateShareAccess(shareToken);
        System.assertEquals(false, accessAfterRevoke, 'Access should be revoked');
        
        Test.stopTest();
    }
    
    /**
     * @description Test mobile feedback capture workflow
     * Requirements: 7.1, 7.2, 7.3, 7.4
     */
    @IsTest
    static void testMobileFeedbackWorkflow() {
        Job_Application__c jobApp = [SELECT Id FROM Job_Application__c LIMIT 1];
        
        Test.startTest();
        
        // Simulate mobile feedback capture with offline data
        Map<String, Object> mobileData = new Map<String, Object>{
            'job_application_id' => jobApp.Id,
            'interview_type' => 'Behavioral',
            'quick_ratings' => new Map<String, Object>{
                'overall' => 3,
                'communication' => 4,
                'cultural_fit' => 3
            },
            'voice_notes' => 'Candidate showed good cultural alignment',
            'offline_timestamp' => System.now().addHours(-2),
            'sync_timestamp' => System.now(),
            'device_info' => 'Mobile App v1.0'
        };
        
        // Process mobile feedback
        Interview_Feedback__c mobileFeedback = InterviewFeedbackService.processMobileFeedback(mobileData);
        
        System.assertNotEquals(null, mobileFeedback.Id, 'Mobile feedback should be created');
        System.assertEquals('Behavioral', mobileFeedback.Interview_Type__c, 'Interview type should match');
        System.assertEquals(3, mobileFeedback.Overall_Rating__c, 'Rating should match mobile input');
        
        Test.stopTest();
    }
}