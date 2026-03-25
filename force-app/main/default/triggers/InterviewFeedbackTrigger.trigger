/**
 * @description Trigger for Interview Feedback object
 * Handles integration with Job Application workflow
 * @author Temitayo Oluwalade
 * @date 2024
 */
trigger InterviewFeedbackTrigger on Interview_Feedback__c (after insert, after update, after delete) {
    
    if (Trigger.isAfter) {
        List<Interview_Feedback__c> feedbackRecords = new List<Interview_Feedback__c>();
        
        if (Trigger.isInsert || Trigger.isUpdate) {
            feedbackRecords = Trigger.new;
        } else if (Trigger.isDelete) {
            feedbackRecords = Trigger.old;
        }
        
        if (!feedbackRecords.isEmpty()) {
            // Update job application metrics
            JobApplicationFeedbackIntegrationService.updateJobApplicationMetrics(feedbackRecords);
            
            // Update job application status (only on insert/update)
            if (Trigger.isInsert || Trigger.isUpdate) {
                JobApplicationFeedbackIntegrationService.updateJobApplicationStatus(feedbackRecords);
                
                // Create follow-up tasks
                JobApplicationFeedbackIntegrationService.createFollowUpTasks(feedbackRecords);
            }
        }
    }
}