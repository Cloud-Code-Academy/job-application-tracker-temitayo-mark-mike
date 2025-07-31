public class JobApplicationTriggerHandler extends TriggerHandler {
    
    // Local declarations
    private List<Job_Application__c> jobApplTriggerNew;
    private List<Job_Application__c> jobApplTriggerOld;
    private Map<Id,Job_Application__c> jobApplTriggerNewMap;
    private Map<Id,Job_Application__c> jobApplTriggerOldMap;

    // Constructor
    public JobApplicationTriggerHandler() {
        this.jobApplTriggerNew = (List<Job_Application__c>) Trigger.new;
        this.jobApplTriggerOld = (List<Job_Application__c>) Trigger.old;
        this.jobApplTriggerNewMap = (Map<Id, Job_Application__c>) Trigger.newMap;
        this.jobApplTriggerOldMap = (Map<Id, Job_Application__c>) Trigger.oldMap;
    }

    public override void beforeInsert() {
        for (Job_Application__c jobAppl : (List<Job_Application__c>) Trigger.new) {
            jobAppl.IsCreated__c = true;
            jobAppl.Applicant__c = UserInfo.getUserId();
        }        
    }

    public override void afterInsert() {
        // Needs to be *after* context so Id's are established.  These are in Trigger.new
        JobApplicationHelper.createJobAppTasksAfterInsert(jobApplTriggerNew);
    }

    public override void afterUpdate() {
        JobApplicationHelper.processJobAppTasksAfterUpdate(jobApplTriggerOldMap, jobApplTriggerNew);
    }

}