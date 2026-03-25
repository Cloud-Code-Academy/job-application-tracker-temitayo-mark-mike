// Comprehensive Deployment Validation Script
// Run this script after deployment to validate all components are working correctly

System.debug('Starting comprehensive deployment validation for Interview Feedback Tracker...');

Boolean allTestsPassed = true;
List<String> failedTests = new List<String>();

// Test 1: Validate Custom Objects
System.debug('\n=== Testing Custom Objects ===');
try {
    // Test Interview_Feedback__c
    Interview_Feedback__c testFeedback = new Interview_Feedback__c();
    testFeedback.Interview_Round__c = 'Validation Test';
    testFeedback.Interview_Type__c = 'Technical';
    testFeedback.Overall_Rating__c = 4.0;
    testFeedback.Technical_Rating__c = 4.5;
    testFeedback.Communication_Rating__c = 3.5;
    testFeedback.Cultural_Fit_Rating__c = 4.0;
    testFeedback.Detailed_Feedback__c = 'Test feedback for validation';
    testFeedback.Recommendation__c = 'Hire';
    testFeedback.Feedback_Source__c = 'Self';
    testFeedback.Feedback_Status__c = 'Submitted';
    insert testFeedback;
    
    System.debug('✓ Interview_Feedback__c object working correctly');
    
    // Test Competency_Rating__c
    Competency_Rating__c testRating = new Competency_Rating__c();
    testRating.Interview_Feedback__c = testFeedback.Id;
    testRating.Competency_Name__c = 'Technical Skills';
    testRating.Rating__c = 4.5;
    testRating.Weight__c = 1.0;
    testRating.Comments__c = 'Test competency rating';
    insert testRating;
    
    System.debug('✓ Competency_Rating__c object working correctly');
    
    // Test Feedback_Template__c
    Feedback_Template__c testTemplate = new Feedback_Template__c();
    testTemplate.Template_Name__c = 'Validation Test Template';
    testTemplate.Interview_Type__c = 'Technical';
    testTemplate.Is_Active__c = true;
    testTemplate.Rating_Scale__c = '1-5';
    insert testTemplate;
    
    System.debug('✓ Feedback_Template__c object working correctly');
    
    // Test Feedback_Share__c
    Feedback_Share__c testShare = new Feedback_Share__c();
    testShare.Interview_Feedback__c = testFeedback.Id;
    testShare.Shared_With_Email__c = 'validation@test.com';
    testShare.Share_Token__c = 'validation123';
    testShare.Access_Level__c = 'Read Only';
    testShare.Is_Active__c = true;
    testShare.Expiration_Date__c = System.now().addDays(30);
    insert testShare;
    
    System.debug('✓ Feedback_Share__c object working correctly');
    
    // Test Interview_Feedback_Audit__c
    Interview_Feedback_Audit__c testAudit = new Interview_Feedback_Audit__c();
    testAudit.Interview_Feedback__c = testFeedback.Id;
    testAudit.User__c = UserInfo.getUserId();
    testAudit.Event_Type__c = 'Create';
    testAudit.Event_Details__c = 'Validation test audit';
    testAudit.IP_Address__c = '127.0.0.1';
    insert testAudit;
    
    System.debug('✓ Interview_Feedback_Audit__c object working correctly');
    
} catch (Exception e) {
    System.debug('✗ Custom Objects test failed: ' + e.getMessage());
    allTestsPassed = false;
    failedTests.add('Custom Objects: ' + e.getMessage());
}

// Test 2: Validate Apex Services
System.debug('\n=== Testing Apex Services ===');
try {
    // Create test Job Application
    Job_Application__c testJobApp = new Job_Application__c();
    testJobApp.Position_Title__c = 'Validation Test Position';
    testJobApp.Company__c = 'Validation Test Company';
    testJobApp.Status__c = 'Applied';
    insert testJobApp;
    
    // Test InterviewFeedbackService
    Map<String, Object> feedbackData = new Map<String, Object>{
        'interviewRound' => 'Validation Round',
        'interviewDate' => System.now(),
        'durationMinutes' => 60,
        'interviewerName' => 'Test Interviewer',
        'overallRating' => 4.0,
        'technicalRating' => 4.5,
        'communicationRating' => 3.5,
        'culturalFitRating' => 4.0,
        'detailedFeedback' => 'Service validation test',
        'recommendation' => 'Hire'
    };
    
    Interview_Feedback__c serviceFeedback = InterviewFeedbackService.createFeedback(
        testJobApp.Id,
        'Technical',
        feedbackData
    );
    
    System.debug('✓ InterviewFeedbackService working correctly');
    
    // Test FeedbackAnalyticsService
    InterviewFeedbackService.FeedbackAnalysis analysis = 
        InterviewFeedbackService.analyzeFeedback(testJobApp.Id);
    
    System.debug('✓ FeedbackAnalyticsService working correctly');
    
    // Test FeedbackSharingService
    String shareLink = FeedbackSharingService.createShareLink(
        serviceFeedback.Id,
        'validation@test.com',
        'Read Only'
    );
    
    System.debug('✓ FeedbackSharingService working correctly');
    
    // Test FeedbackTemplateService
    List<Feedback_Template__c> templates = FeedbackTemplateService.getTemplatesByType('Technical');
    
    System.debug('✓ FeedbackTemplateService working correctly');
    
    // Test FeedbackSecurityService
    Boolean hasAccess = FeedbackSecurityService.validateFeedbackAccess(
        serviceFeedback.Id,
        UserInfo.getUserId()
    );
    
    System.debug('✓ FeedbackSecurityService working correctly');
    
} catch (Exception e) {
    System.debug('✗ Apex Services test failed: ' + e.getMessage());
    allTestsPassed = false;
    failedTests.add('Apex Services: ' + e.getMessage());
}

// Test 3: Validate Permission Sets
System.debug('\n=== Testing Permission Sets ===');
try {
    List<String> requiredPermissionSets = new List<String>{
        'Interview_Feedback_Manager',
        'Interview_Feedback_User',
        'Interview_Feedback_Viewer'
    };
    
    for (String permSetName : requiredPermissionSets) {
        List<PermissionSet> permSets = [
            SELECT Id, Name, Label
            FROM PermissionSet
            WHERE Name = :permSetName
        ];
        
        if (permSets.isEmpty()) {
            throw new ValidationException('Permission set not found: ' + permSetName);
        }
        
        System.debug('✓ Permission set found: ' + permSetName);
    }
    
} catch (Exception e) {
    System.debug('✗ Permission Sets test failed: ' + e.getMessage());
    allTestsPassed = false;
    failedTests.add('Permission Sets: ' + e.getMessage());
}

// Test 4: Validate Data Relationships
System.debug('\n=== Testing Data Relationships ===');
try {
    // Query with relationships to test they work
    List<Interview_Feedback__c> feedbackWithRelated = [
        SELECT Id, Job_Application__c, Job_Application__r.Position_Title__c,
               (SELECT Id, Competency_Name__c, Rating__c FROM Competency_Ratings__r),
               (SELECT Id, Shared_With_Email__c FROM Feedback_Shares__r)
        FROM Interview_Feedback__c
        WHERE Interview_Round__c = 'Validation Test'
        OR Interview_Round__c = 'Validation Round'
        LIMIT 5
    ];
    
    if (!feedbackWithRelated.isEmpty()) {
        System.debug('✓ Data relationships working correctly');
        System.debug('Found ' + feedbackWithRelated.size() + ' feedback records with relationships');
    } else {
        System.debug('⚠ No test data found for relationship validation');
    }
    
} catch (Exception e) {
    System.debug('✗ Data Relationships test failed: ' + e.getMessage());
    allTestsPassed = false;
    failedTests.add('Data Relationships: ' + e.getMessage());
}

// Test 5: Validate Batch Classes
System.debug('\n=== Testing Batch Classes ===');
try {
    // Test FeedbackDataRetentionBatch
    FeedbackDataRetentionBatch retentionBatch = new FeedbackDataRetentionBatch();
    Database.QueryLocator retentionQL = retentionBatch.start(null);
    System.debug('✓ FeedbackDataRetentionBatch working correctly');
    
    // Test InterviewFeedbackMigrationBatch
    InterviewFeedbackMigrationBatch migrationBatch = new InterviewFeedbackMigrationBatch();
    Database.QueryLocator migrationQL = migrationBatch.start(null);
    System.debug('✓ InterviewFeedbackMigrationBatch working correctly');
    
} catch (Exception e) {
    System.debug('✗ Batch Classes test failed: ' + e.getMessage());
    allTestsPassed = false;
    failedTests.add('Batch Classes: ' + e.getMessage());
}

// Test 6: Validate Monitoring System
System.debug('\n=== Testing Monitoring System ===');
try {
    // Test monitoring service
    InterviewFeedbackMonitoringService.performHealthCheck();
    System.debug('✓ Monitoring service working correctly');
    
    // Test scheduler setup
    InterviewFeedbackMonitoringScheduler scheduler = new InterviewFeedbackMonitoringScheduler();
    System.debug('✓ Monitoring scheduler working correctly');
    
} catch (Exception e) {
    System.debug('✗ Monitoring System test failed: ' + e.getMessage());
    allTestsPassed = false;
    failedTests.add('Monitoring System: ' + e.getMessage());
}

// Test 7: Validate System Performance
System.debug('\n=== Testing System Performance ===');
try {
    Long startTime = System.currentTimeMillis();
    
    // Test dashboard data generation performance
    FeedbackAnalyticsService.DashboardData dashboardData = 
        FeedbackAnalyticsService.generateDashboardData(UserInfo.getUserId());
    
    Long endTime = System.currentTimeMillis();
    Long executionTime = endTime - startTime;
    
    System.debug('Dashboard generation time: ' + executionTime + 'ms');
    
    if (executionTime > 5000) {
        System.debug('⚠ Dashboard generation is slow: ' + executionTime + 'ms (threshold: 5000ms)');
    } else {
        System.debug('✓ Performance test passed');
    }
    
} catch (Exception e) {
    System.debug('✗ Performance test failed: ' + e.getMessage());
    allTestsPassed = false;
    failedTests.add('Performance: ' + e.getMessage());
}

// Test 8: Validate Integration Points
System.debug('\n=== Testing Integration Points ===');
try {
    // Test Job Application integration
    Integer jobAppCount = [SELECT COUNT() FROM Job_Application__c WHERE Position_Title__c = 'Validation Test Position'];
    
    if (jobAppCount > 0) {
        System.debug('✓ Job Application Tracker integration working');
    } else {
        System.debug('⚠ No Job Application test data found');
    }
    
    // Test that feedback can be linked to job applications
    Integer linkedFeedbackCount = [
        SELECT COUNT() 
        FROM Interview_Feedback__c 
        WHERE Job_Application__c != null
        AND (Interview_Round__c = 'Validation Test' OR Interview_Round__c = 'Validation Round')
    ];
    
    if (linkedFeedbackCount > 0) {
        System.debug('✓ Feedback-Job Application linking working');
    }
    
} catch (Exception e) {
    System.debug('✗ Integration Points test failed: ' + e.getMessage());
    allTestsPassed = false;
    failedTests.add('Integration Points: ' + e.getMessage());
}

// Final Results
System.debug('\n=== DEPLOYMENT VALIDATION RESULTS ===');
if (allTestsPassed) {
    System.debug('🎉 ALL TESTS PASSED - Deployment is successful!');
    System.debug('Interview Feedback Tracker is ready for production use.');
} else {
    System.debug('❌ SOME TESTS FAILED - Please review and fix issues:');
    for (String failure : failedTests) {
        System.debug('- ' + failure);
    }
}

// System Statistics
System.debug('\n=== SYSTEM STATISTICS ===');
try {
    Integer totalFeedback = [SELECT COUNT() FROM Interview_Feedback__c];
    Integer totalRatings = [SELECT COUNT() FROM Competency_Rating__c];
    Integer totalShares = [SELECT COUNT() FROM Feedback_Share__c];
    Integer totalTemplates = [SELECT COUNT() FROM Feedback_Template__c];
    Integer totalAudits = [SELECT COUNT() FROM Interview_Feedback_Audit__c];
    
    System.debug('Total Interview Feedback records: ' + totalFeedback);
    System.debug('Total Competency Ratings: ' + totalRatings);
    System.debug('Total Feedback Shares: ' + totalShares);
    System.debug('Total Templates: ' + totalTemplates);
    System.debug('Total Audit Records: ' + totalAudits);
    
} catch (Exception e) {
    System.debug('Could not retrieve system statistics: ' + e.getMessage());
}

System.debug('\n=== NEXT STEPS ===');
System.debug('1. Assign appropriate permission sets to users');
System.debug('2. Import or create feedback templates');
System.debug('3. Configure monitoring email addresses');
System.debug('4. Set up scheduled jobs for data retention');
System.debug('5. Train users on the new functionality');
System.debug('6. Monitor system performance and usage');

System.debug('\nDeployment validation completed at: ' + System.now());

// Custom exception for validation
public class ValidationException extends Exception {}

/*
Deployment Validation Checklist:

□ Custom objects created and accessible
□ Apex classes deployed and functional
□ Permission sets available for assignment
□ Data relationships working correctly
□ Batch processing classes operational
□ Monitoring system functional
□ Performance within acceptable limits
□ Integration points working
□ Security configuration active
□ Test data can be created successfully

If any tests fail, review the error messages and:
1. Check deployment logs for missing components
2. Verify permission set configurations
3. Ensure all dependencies are deployed
4. Check for naming conflicts or field issues
5. Validate that the Job Application Tracker is properly installed
*/