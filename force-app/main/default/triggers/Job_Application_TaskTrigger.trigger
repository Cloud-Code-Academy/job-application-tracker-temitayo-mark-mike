trigger Job_Application_TaskTrigger on Job_Application_Task__c (before insert, after insert, before update, after update, before delete, after delete, after undelete) {
    new JobApplicationTaskTriggerHandler().run(); 

}