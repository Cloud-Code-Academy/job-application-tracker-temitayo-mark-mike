// Test script for FeedbackSharingService
System.debug('Starting FeedbackSharingService test...');

try {
    // Create test Job Application
    Job_Application__c jobApp = new Job_Application__c(
        Position_Title__c = 'Senior Software Engineer',
        Company_Name__c = 'Sharing Test Company',
        Status__c = 'Applied',
        Salary__c = 120000,
        Application_Date__c = Date.today().addDays(-30),
        Description__c = 'Test job for sharing service',
        Location__c = 'San Francisco, CA'
    );
    insert jobApp;
    System.debug('Created Job Application: ' + jobApp.Id);
    
    // Create test Interview Feedback
    Interview_Feedback__c feedback = new Interview_Feedback__c(
        Job_Application__c = jobApp.Id,
        Interview_Round__c = 'Technical Round',
        Interview_Type__c = 'Technical',
        Interviewer_Name__c = 'Senior Engineer',
        Interview_Date__c = Date.today().addDays(-5),
        Technical_Rating__c = 4,
        Communication_Rating__c = 4,
        Cultural_Fit_Rating__c = 5,
        Detailed_Feedback__c = 'Excellent technical skills and problem-solving ability. Demonstrated strong knowledge of algorithms and data structures.',
        Feedback_Status__c = 'Submitted',
        Strengths__c = 'Strong technical foundation, good communication, analytical thinking',
        Areas_for_Improvement__c = 'Could improve system design skills and leadership experience',
        Is_Confidential__c = false
    );
    
    // Use InterviewFeedbackService to create feedback (this will calculate overall ratings)
    List<Interview_Feedback__c> createdFeedback = InterviewFeedbackService.createFeedback(
        new List<Interview_Feedback__c>{feedback}
    );
    System.debug('Created feedback record: ' + createdFeedback[0].Id);
    
    // Test creating a share link
    String mentorEmail = 'mentor@example.com';
    String accessLevel = 'Comment';
    Integer expirationDays = 14;
    
    String shareToken = FeedbackSharingService.createShareLink(
        createdFeedback[0].Id, mentorEmail, accessLevel, expirationDays
    );
    
    System.debug('=== SHARE LINK CREATED ===');
    System.debug('Share Token: ' + shareToken);
    System.debug('Recipient: ' + mentorEmail);
    System.debug('Access Level: ' + accessLevel);
    System.debug('Expires in: ' + expirationDays + ' days');
    
    // Test validating and accessing shared feedback
    FeedbackSharingService.SharedFeedbackData sharedData = 
        FeedbackSharingService.validateAndGetSharedFeedback(shareToken);
    
    System.debug('=== SHARED FEEDBACK DATA ===');
    System.debug('Position: ' + sharedData.positionTitle + ' at ' + sharedData.companyName);
    System.debug('Interview: ' + sharedData.interviewRound + ' (' + sharedData.interviewType + ')');
    System.debug('Interviewer: ' + sharedData.interviewerName);
    System.debug('Date: ' + sharedData.interviewDate);
    System.debug('Overall Rating: ' + sharedData.overallRating);
    System.debug('Technical Rating: ' + sharedData.technicalRating);
    System.debug('Communication Rating: ' + sharedData.communicationRating);
    System.debug('Cultural Fit Rating: ' + sharedData.culturalFitRating);
    System.debug('Access Count: ' + sharedData.accessCount);
    System.debug('Detailed Feedback: ' + sharedData.detailedFeedback);
    System.debug('Strengths: ' + sharedData.strengths);
    System.debug('Areas for Improvement: ' + sharedData.areasForImprovement);
    
    // Test adding mentor comment
    String mentorComment = 'Great technical performance! I recommend focusing on system design patterns and practicing architectural discussions. Consider reading "Designing Data-Intensive Applications" and practicing with system design interviews.';
    
    Id commentId = FeedbackSharingService.addMentorComment(shareToken, mentorEmail, mentorComment);
    
    System.debug('=== MENTOR COMMENT ADDED ===');
    System.debug('Comment ID: ' + commentId);
    System.debug('Comment: ' + mentorComment);
    
    // Test getting active shares
    List<FeedbackSharingService.ShareSummary> activeShares = 
        FeedbackSharingService.getActiveShares(createdFeedback[0].Id);
    
    System.debug('=== ACTIVE SHARES ===');
    System.debug('Number of active shares: ' + activeShares.size());
    for (FeedbackSharingService.ShareSummary share : activeShares) {
        System.debug('- Recipient: ' + share.recipientEmail);
        System.debug('  Access Level: ' + share.accessLevel);
        System.debug('  Access Count: ' + share.accessCount);
        System.debug('  Expires: ' + share.expirationDate);
        System.debug('  Created: ' + share.createdDate + ' by ' + share.createdByName);
    }
    
    // Test extending share expiration
    if (!activeShares.isEmpty()) {
        FeedbackSharingService.extendShareExpiration(activeShares[0].shareId, 7);
        System.debug('Extended share expiration by 7 days');
    }
    
    // Test creating additional shares with different access levels
    String coachEmail = 'coach@example.com';
    String readOnlyToken = FeedbackSharingService.createShareLink(
        createdFeedback[0].Id, coachEmail, 'Read Only', 30
    );
    
    System.debug('=== ADDITIONAL SHARE CREATED ===');
    System.debug('Coach Share Token: ' + readOnlyToken);
    System.debug('Access Level: Read Only');
    
    // Test accessing with read-only permissions (should mask sensitive data)
    FeedbackSharingService.SharedFeedbackData readOnlyData = 
        FeedbackSharingService.validateAndGetSharedFeedback(readOnlyToken);
    
    System.debug('=== READ-ONLY ACCESS DATA ===');
    System.debug('Access Level: ' + readOnlyData.accessLevel);
    System.debug('Detailed Feedback (masked): ' + readOnlyData.detailedFeedback);
    
    // Test creating confidential feedback to demonstrate masking
    Interview_Feedback__c confidentialFeedback = new Interview_Feedback__c(
        Job_Application__c = jobApp.Id,
        Interview_Round__c = 'Confidential Round',
        Interview_Type__c = 'Executive',
        Interviewer_Name__c = 'CEO',
        Interview_Date__c = Date.today().addDays(-2),
        Technical_Rating__c = 5,
        Communication_Rating__c = 5,
        Cultural_Fit_Rating__c = 5,
        Detailed_Feedback__c = 'Confidential executive feedback with sensitive information',
        Feedback_Status__c = 'Submitted',
        Strengths__c = 'Executive presence, strategic thinking',
        Areas_for_Improvement__c = 'Confidential improvement areas',
        Is_Confidential__c = true
    );
    
    List<Interview_Feedback__c> confidentialCreated = InterviewFeedbackService.createFeedback(
        new List<Interview_Feedback__c>{confidentialFeedback}
    );
    
    String confidentialToken = FeedbackSharingService.createShareLink(
        confidentialCreated[0].Id, 'trusted-advisor@example.com', 'Comment', 7
    );
    
    FeedbackSharingService.SharedFeedbackData confidentialData = 
        FeedbackSharingService.validateAndGetSharedFeedback(confidentialToken);
    
    System.debug('=== CONFIDENTIAL FEEDBACK (MASKED) ===');
    System.debug('Detailed Feedback: ' + confidentialData.detailedFeedback);
    System.debug('Strengths: ' + confidentialData.strengths);
    System.debug('Areas for Improvement: ' + confidentialData.areasForImprovement);
    
    // Test revoking access
    List<FeedbackSharingService.ShareSummary> allShares = 
        FeedbackSharingService.getActiveShares(createdFeedback[0].Id);
    
    if (!allShares.isEmpty()) {
        FeedbackSharingService.revokeAccess(allShares[0].shareId);
        System.debug('Revoked access for: ' + allShares[0].recipientEmail);
    }
    
    System.debug('FeedbackSharingService test completed successfully!');
    
} catch (Exception e) {
    System.debug(LoggingLevel.ERROR, 'Test failed: ' + e.getMessage());
    System.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());
}