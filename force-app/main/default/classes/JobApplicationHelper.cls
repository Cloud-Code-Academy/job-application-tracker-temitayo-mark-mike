public with sharing class JobApplicationHelper {
    
    // Method to create/insert Tasks, if any, when a Job Application record is created/inserted.
    public static void createJobAppTasksAfterInsert(List<Job_Application__c> listJobAppl) {
        
        // Get the Task templates from the Org Cache
        List<Job_Application_Task__c> listJobAppTasks = Utilities.getJobAppTasks();         
        // Initialize a List<Tasks> to store the Tasks that will be created.
        List<Task> listTasksToCreate = new List<Task>();
        
        // Loop thru the List of Job Appl. (Trigger.new)
        for (Job_Application__c jobAppl : listJobAppl) {
            
            // Loop thru the Task templates
            for (Job_Application_Task__c jobApplTask : listJobAppTasks) {
                
                System.debug('***********' + JSON.serializePretty(jobApplTask));
                
                // // If the the Job Application Status = template Status then create a new Task from the template
                // if (jobAppl.Status__c == jobApplTask.Job_Appl_Status__c) {
                    
                //     Task tsk = new Task();
                //     tsk.OwnerId = UserInfo.getUserId();
                //     //tsk.WhoId = 
                //     tsk.WhatId = jobAppl.Id;
                //     tsk.Subject = jobApplTask?.Task_Subject__c;
                //     tsk.Description = jobApplTask?.Task_Comment__c;
                //     tsk.Priority = jobApplTask?.Task_Priority__c;
                    
                //     System.debug('jobApplTask.Due_Date_Adjust__c: ' + String.valueOf(jobApplTask.Due_Date_Adjust__c));
                    
                //     //if (jobApplTask.Due_Date_Adjust__c != 0) {
                //         tsk.ActivityDate = Utilities.addWorkingDays(Date.today(), 5);
                //     //} else {
                //     //
                //     listTasksToCreate.add(tsk);
            }
            
        } 
        
        insert listTasksToCreate;

        return;
    }

    
    // public static List<Task> createJobAppTasksBeforeUpdate(List<Job_Application__c> listJobApplOld, List<Job_Application__c> listJobApplNew) {
        
    //     return null;
    // }

}