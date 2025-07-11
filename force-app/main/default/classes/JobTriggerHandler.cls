public class JobTriggerHandler extends TriggerHandler {
    
    private List<Job__c> jobTriggerNew;
    private List<Job__c> jobTriggerOld;
    private Map<Id,Job__c> jobTriggerNewMap;
    private Map<Id,Job__c> jobTriggerOldMap;

    public JobTriggerHandler() {
        this.jobTriggerNew = (List<Job__c>) Trigger.new;
        this.jobTriggerOld = (List<Job__c>) Trigger.old;
        this.jobTriggerNewMap = (Map<Id, Job__c>) Trigger.newMap;
        this.jobTriggerOldMap = (Map<Id, Job__c>) Trigger.oldMap;
    }
 
    public override void beforeInsert() {
        
        // Execute a query to retrieve Relationship fields, which are not in triggers
        List<Job__c> jobsToUpdateList = [SELECT Id, IsCreated__c, Name, Employer__r.Name, Long_Name__c FROM Job__c WHERE Id IN :Trigger.new WITH SYSTEM_MODE];
        Map<Id,Job__c> jobsToUpdateMap = new Map<Id,Job__c>(jobsToUpdateList);
        // Loop thru the List and update the IsCreated__c field
        for (Job__c job : (List<Job__c>) Trigger.new) {
            job.IsCreated__c = true;
            Job__c jobFromMap = (Job__c) jobsToUpdateMap.get(Job.Id);
            System.debug('jobFromMap:' + JSON.serializePretty(jobFromMap));
            //job.Long_Name__c = job.Name + ' (' + jobFromMap.Employer__r.Name + ')';
        }
        
    }

    public override void afterInsert() {
    }

    public override void beforeUpdate() {
       
        // Update Long_Name__c if the Position (API Name) field changes.
        for (Job__c newJob : (List<Job__c>) Trigger.new ) {
            Job__c oldJob = (Job__c) Trigger.oldMap?.get(newJob.Id);
            if (newJob.Name != oldJob.Name) {
                String revLongName = newJob.Long_Name__c.replace(oldJob.Name, newJob.Name);
                newJob.Long_Name__c = revLongName;
            }
        }

    }

    public override void afterUpdate() {
    }

    public override void beforeDelete() {
    }

    public override void afterDelete() {
    }

    public override void afterUndelete() {     
    }
}