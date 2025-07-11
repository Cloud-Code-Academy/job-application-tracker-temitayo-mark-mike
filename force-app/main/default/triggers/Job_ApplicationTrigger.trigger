trigger Job_ApplicationTrigger on Job_Application__c (before insert, after insert, before update, after update, before delete, after delete, after undelete) {
    System.debug('JobApplicationTrigger');
    new JobApplicationTriggerHandler().run();
}