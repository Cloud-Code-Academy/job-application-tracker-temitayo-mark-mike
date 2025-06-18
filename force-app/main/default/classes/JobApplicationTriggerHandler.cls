/**
 * @description Handler class for Job Application trigger
 * Manages all automation logic for Job Application records
 * @author Temitayo Oluwalade
 * @date 2024
 */
public with sharing class JobApplicationTriggerHandler {
    
    /**
     * @description Handles before insert logic
     * @param newRecords List of new Job Application records
     */
    public void beforeInsert(List<Job_Application__c> newRecords) {
        // Calculate take-home pay for new records with salary
        SalaryCalculationService.calculateTakeHomePay(newRecords);

        // Set primary contact if null
        ContactAssignmentService.assignPrimaryContact(newRecords);
    }
    
    /**
     * @description Handles before update logic
     * @param newRecords List of updated Job Application records
     * @param oldMap Map of old Job Application records
     */
    public void beforeUpdate(List<Job_Application__c> newRecords, Map<Id, Job_Application__c> oldMap) {
        // Recalculate take-home pay if salary changed
        List<Job_Application__c> recordsWithSalaryChange = new List<Job_Application__c>();
        List<Job_Application__c> recordsNeedingContactAssignment = new List<Job_Application__c>();

        for (Job_Application__c newRecord : newRecords) {
            Job_Application__c oldRecord = oldMap.get(newRecord.Id);
            if (newRecord.Salary__c != oldRecord.Salary__c) {
                recordsWithSalaryChange.add(newRecord);
            }

            // Check if primary contact assignment is needed
            if (newRecord.Primary_Contact__c == null) {
                recordsNeedingContactAssignment.add(newRecord);
            }
        }

        if (!recordsWithSalaryChange.isEmpty()) {
            SalaryCalculationService.calculateTakeHomePay(recordsWithSalaryChange);
        }

        // Assign primary contacts where needed
        if (!recordsNeedingContactAssignment.isEmpty()) {
            ContactAssignmentService.assignPrimaryContact(recordsNeedingContactAssignment);
        }
    }
    
    /**
     * @description Handles after insert logic
     * @param newRecords List of new Job Application records
     */
    public void afterInsert(List<Job_Application__c> newRecords) {
        // Create tasks for new job applications
        TaskCreationService.createTasksForStatusChange(newRecords, null);
    }
    
    /**
     * @description Handles after update logic
     * @param newRecords List of updated Job Application records
     * @param oldMap Map of old Job Application records
     */
    public void afterUpdate(List<Job_Application__c> newRecords, Map<Id, Job_Application__c> oldMap) {
        // Track records with status changes
        List<Job_Application__c> recordsWithStatusChange = new List<Job_Application__c>();

        for (Job_Application__c newRecord : newRecords) {
            Job_Application__c oldRecord = oldMap.get(newRecord.Id);

            // Check for status changes
            if (newRecord.Status__c != oldRecord.Status__c) {
                recordsWithStatusChange.add(newRecord);
            }
        }

        // Create tasks for status changes
        if (!recordsWithStatusChange.isEmpty()) {
            TaskCreationService.createTasksForStatusChange(recordsWithStatusChange, oldMap);
        }
    }
}
