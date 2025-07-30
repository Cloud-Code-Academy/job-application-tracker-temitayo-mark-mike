trigger JobTrigger on Job__c (before insert) {
    new JobTriggerHandler().run();
}