public class JobApplicationTriggerHandler extends TriggerHandler {
    private List<Job_Application__c> jobApplTriggerNew;
    private List<Job_Application__c> jobApplTriggerOld;
    private Map<Id,Job_Application__c> jobApplTriggerNewMap;
    private Map<Id,Job_Application__c> jobApplTriggerOldMap;

    public JobApplicationTriggerHandler() {
        this.jobApplTriggerNew = (List<Job_Application__c>) Trigger.new;
        this.jobApplTriggerOld = (List<Job_Application__c>) Trigger.old;
        this.jobApplTriggerNewMap = (Map<Id, Job_Application__c>) Trigger.newMap;
        this.jobApplTriggerOldMap = (Map<Id, Job_Application__c>) Trigger.oldMap;
    }
 
    public override void beforeInsert() {
        //Job_Application__cHelper.testJob_Application__cMethod(acctTriggerNew);
    }

    public override void afterInsert() {
    }

    public override void beforeUpdate() {
        //Job_Application__cHelper.testJob_Application__cMethod(acctTriggerNew);
    }

    public override void beforeDelete() {
    }

    public override void afterDelete() {
    }

    public override void afterUndelete() {     
    }

}