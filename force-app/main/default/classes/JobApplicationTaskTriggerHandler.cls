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
        //Job_Application_Task__cHelper.testJob_Application_Task__cMethod(acctTriggerNew);
    }

    public override void afterInsert() {
    }

    public override void beforeUpdate() {
        //Job_Application_Task__cHelper.testJob_Application_Task__cMethod(acctTriggerNew);
    }

    public override void beforeDelete() {
    }

    public override void afterDelete() {
    }

    public override void afterUndelete() {     
    }
}