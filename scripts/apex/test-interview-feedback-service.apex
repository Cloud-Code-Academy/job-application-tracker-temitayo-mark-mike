// Test script for InterviewFeedbackService
System.debug('Starting InterviewFeedbackService test...');

try {
    // Create test Job Application
    Job_Application__c jobApp = new Job_Application__c(
        Position_Title__c = 'Senior Software Engineer',
        Company_Name__c = 'Test Company Inc',
        Status__c = 'Applied',
        Salary__c = 120000,
        Application_Date__c = Date.today().addDays(-30),
        Description__c = 'Test job description for software engineering position',
        Location__c = 'San Francisco, CA'
    );
    insert jobApp;
    System.debug('Created Job Application: ' + jobApp.Id);
    
    // Create test Interview Feedback
    Interview_Feedback__c feedback = new Interview_Feedback__c(
        Job_Application__c = jobApp.Id,
        Interview_Round__c = 'Technical',
        Interview_Type__c = 'Technical',
        Interviewer_Name__c = 'John Smith',
        Interview_Date__c = Date.today(),
        Technical_Rating__c = 4,
        Communication_Rating__c = 4,
        Cultural_Fit_Rating__c = 5,
        Detailed_Feedback__c = 'Strong technical skills demonstrated',
        Feedback_Status__c = 'Draft',
        Strengths__c = 'Problem solving, technical depth',
        Areas_for_Improvement__c = 'Could improve system design knowledge'
    );
    
    // Test createFeedback method
    List<Interview_Feedback__c> feedbackList = new List<Interview_Feedback__c>{feedback};
    List<Interview_Feedback__c> result = InterviewFeedbackService.createFeedback(feedbackList);
    
    System.debug('Created feedback record: ' + result[0].Id);
    System.debug('Overall Rating calculated: ' + result[0].Overall_Rating__c);
    
    // Test calculateAggregateScores method
    InterviewFeedbackService.AggregateScores scores = InterviewFeedbackService.calculateAggregateScores(jobApp.Id);
    System.debug('Aggregate scores calculated - Total count: ' + scores.totalFeedbackCount);
    
    System.debug('InterviewFeedbackService test completed successfully!');
    
} catch (Exception e) {
    System.debug(LoggingLevel.ERROR, 'Test failed: ' + e.getMessage());
    System.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());
}