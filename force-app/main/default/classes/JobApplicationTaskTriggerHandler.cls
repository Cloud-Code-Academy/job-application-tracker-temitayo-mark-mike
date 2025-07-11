public with sharing class JobApplicationTaskTriggerHandler extends TriggerHandler {
   
    private List<Job_Application_Task__c> jobApplTaskTriggerNew;
    private List<Job_Application_Task__c> jobApplTaskTriggerOld;
    private Map<Id,Job_Application_Task__c> jobApplTaskTriggerNewMap;
    private Map<Id,Job_Application_Task__c> jobApplTaskTriggerOldMap;

    public JobApplicationTaskTriggerHandler() {
        this.jobApplTaskTriggerNew = (List<Job_Application_Task__c>) Trigger.new;
        this.jobApplTaskTriggerOld = (List<Job_Application_Task__c>) Trigger.old;
        this.jobApplTaskTriggerNewMap = (Map<Id, Job_Application_Task__c>) Trigger.newMap;
        this.jobApplTaskTriggerOldMap = (Map<Id, Job_Application_Task__c>) Trigger.oldMap;
    }
 
    public override void beforeInsert() {
    }

    public override void afterInsert() {
        Utilities.updateJobApplTasks();
    }

    public override void beforeUpdate() {
    }
    
    public override void afterUpdate() {
        Utilities.updateJobApplTasks();
    }

    public override void beforeDelete() {
    }

    public override void afterDelete() {
        Utilities.updateJobApplTasks();
    }

    public override void afterUndelete() {     
        Utilities.updateJobApplTasks();
    }
}