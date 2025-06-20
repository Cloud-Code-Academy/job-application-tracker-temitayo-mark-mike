public with sharing class JobHelper {
    
    public static void testJobMethod(List<Job__c> jobTriggerOld) {
        System.debug('jobTriggerOld: ' + JSON.serializePretty(jobTriggerOld));
    }

}