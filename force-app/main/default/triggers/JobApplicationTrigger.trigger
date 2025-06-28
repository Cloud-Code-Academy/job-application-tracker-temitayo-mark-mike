/**
 * @description Trigger for Job Application object to handle automation
 * @author Temitayo Oluwalade
 * @date 2024
 */
trigger JobApplicationTrigger on Job_Application__c (before insert, before update, after insert, after update) {
    
    // Delegate to handler class for better organization and testability
    JobApplicationTriggerHandler handler = new JobApplicationTriggerHandler();
    
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            handler.beforeInsert(Trigger.new);
        }
        if (Trigger.isUpdate) {
            handler.beforeUpdate(Trigger.new, Trigger.oldMap);
        }
    }
    
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            handler.afterInsert(Trigger.new);
        }
        if (Trigger.isUpdate) {
            handler.afterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}
