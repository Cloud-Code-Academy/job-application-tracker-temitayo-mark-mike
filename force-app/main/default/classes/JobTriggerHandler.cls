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
        JobHelper.testJobMethod(jobTriggerOldTriggerOld);
    }

    public override void afterInsert() {
    }

    public override void beforeUpdate() {
        jobHelper.testjobMethod(jobTriggerOldTriggerNew);
    }

    public override void beforeDelete() {
    }

    public override void afterDelete() {
    }

    public override void afterUndelete() {     
    }
}