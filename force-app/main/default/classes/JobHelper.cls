public with sharing class JobHelper {
    
    // Simple process to mark IsCreated__c field to True to conditionally display fields, sections, components, etc.
    // AFTER_INSERT
    public static void processInsertedJob(List<Job__c> listTrigger) {
        // Run query to obtain records in Trigger
        List<Job__c> jobsToUpdate = [SELECT Id, IsCreated__c, Name, Employer__r.Name, Long_Name__c FROM Job__c WHERE Id IN :listTrigger WITH SYSTEM_MODE];
        System.debug('jobsToUpdate: ' + JSON.serializePretty(jobsToUpdate));
        // Loop thru the List and update the IsCreated__c field
        for (Job__c job : jobsToUpdate) {
            job.IsCreated__c = true;
            job.Long_Name__c = job.Name + ' (' + job.Employer__r.Name + ')';
        }
        System.debug('jobsToUpdateAFTER: ' + JSON.serializePretty(jobsToUpdate));
        update jobsToUpdate;
    }
    
    public static void processUpdatedJob(List<Job__c> listTriggerNew, Map<Id,Job__c> mapTriggerOld) {
        for (Job__c newJob : listTriggerNew) {
            Job__c oldJob = (Job__c) mapTriggerOld?.get(newJob.Id);
            if (newJob.Name != oldJob.Name) {
                newJob.Long_Name__c.replace(oldJob.Name, newJob.Name);
            }
        }
        
    }

}