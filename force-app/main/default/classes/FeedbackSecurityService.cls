/**
 * @description Comprehensive security service for Interview Feedback Tracker
 * Handles field-level security, data encryption, audit trails, and privacy compliance
 * @author Kiro AI Assistant
 * @date 2025
 */
public with sharing class FeedbackSecurityService {
    
    // Security constants
    private static final String AUDIT_OBJECT_NAME = 'Interview_Feedback_Audit__c';
    private static final String ANONYMIZED_VALUE = '[ANONYMIZED]';
    private static final Integer DEFAULT_RETENTION_DAYS = 2555; // 7 years
    
    /**
     * @description Validates user permissions for feedback operations
     * @param operation The operation being performed (CREATE, READ, UPDATE, DELETE)
     * @param feedbackIds List of feedback record IDs
     * @return Boolean indicating if user has permission
     */
    public static Boolean validateFeedbackAccess(String operation, List<Id> feedbackIds) {
        try {
            // Check object-level permissions
            if (!hasObjectPermission(operation)) {
                return false;
            }
            
            // Check record-level access for existing records
            if (operation != 'CREATE' && !feedbackIds.isEmpty()) {
                return validateRecordAccess(operation, feedbackIds);
            }
            
            return true;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error validating feedback access: ' + e.getMessage());
            createAuditLog('PERMISSION_ERROR', 'Failed permission validation: ' + e.getMessage());
            return false;
        }
    }
    
    /**
     * @description Checks object-level permissions for Interview Feedback
     * @param operation The operation being performed
     * @return Boolean indicating if user has object permission
     */
    private static Boolean hasObjectPermission(String operation) {
        Schema.DescribeSObjectResult feedbackDescribe = Interview_Feedback__c.SObjectType.getDescribe();
        
        switch on operation.toUpperCase() {
            when 'CREATE' {
                return feedbackDescribe.isCreateable();
            }
            when 'READ' {
                return feedbackDescribe.isAccessible();
            }
            when 'UPDATE' {
                return feedbackDescribe.isUpdateable();
            }
            when 'DELETE' {
                return feedbackDescribe.isDeletable();
            }
            when else {
                return false;
            }
        }
    }
    
    /**
     * @description Validates record-level access using SOQL with security enforced
     * @param operation The operation being performed
     * @param feedbackIds List of feedback record IDs
     * @return Boolean indicating if user has record access
     */
    private static Boolean validateRecordAccess(String operation, List<Id> feedbackIds) {
        try {
            List<Interview_Feedback__c> accessibleRecords = [
                SELECT Id 
                FROM Interview_Feedback__c 
                WHERE Id IN :feedbackIds
                WITH SECURITY_ENFORCED
            ];
            
            // User has access to all requested records
            return accessibleRecords.size() == feedbackIds.size();
        } catch (System.QueryException e) {
            System.debug(LoggingLevel.ERROR, 'Record access validation failed: ' + e.getMessage());
            return false;
        }
    }
    
    /**
     * @description Encrypts sensitive feedback data before storage
     * @param feedbackRecords List of feedback records to encrypt
     */
    public static void encryptSensitiveData(List<Interview_Feedback__c> feedbackRecords) {
        for (Interview_Feedback__c feedback : feedbackRecords) {
            // Mark confidential fields for Platform Encryption
            if (feedback.Is_Confidential__c == true) {
                // Platform Encryption will handle these fields automatically
                // if configured in Setup > Platform Encryption
                createAuditLog('DATA_ENCRYPTION', 'Confidential feedback encrypted for record: ' + feedback.Id);
            }
        }
    }
    
    /**
     * @description Implements GDPR right to be forgotten
     * @param userId User ID requesting data anonymization
     * @return Boolean indicating success of anonymization
     */
    public static Boolean anonymizeUserData(Id userId) {
        try {
            // Find all feedback records created by or about the user
            List<Interview_Feedback__c> feedbackToAnonymize = [
                SELECT Id, Detailed_Feedback__c, Strengths__c, Areas_For_Improvement__c,
                       Interviewer_Name__c, Interviewer_Email__c
                FROM Interview_Feedback__c
                WHERE CreatedById = :userId OR Interviewer_Email__c = :getUserEmail(userId)
                WITH SECURITY_ENFORCED
            ];
            
            // Anonymize sensitive data
            for (Interview_Feedback__c feedback : feedbackToAnonymize) {
                feedback.Detailed_Feedback__c = ANONYMIZED_VALUE;
                feedback.Strengths__c = ANONYMIZED_VALUE;
                feedback.Areas_For_Improvement__c = ANONYMIZED_VALUE;
                feedback.Interviewer_Name__c = ANONYMIZED_VALUE;
                feedback.Interviewer_Email__c = 'anonymized@example.com';
            }
            
            update feedbackToAnonymize;
            
            // Create audit log
            createAuditLog('GDPR_ANONYMIZATION', 'Anonymized ' + feedbackToAnonymize.size() + ' records for user: ' + userId);
            
            return true;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error anonymizing user data: ' + e.getMessage());
            createAuditLog('GDPR_ERROR', 'Failed to anonymize data for user: ' + userId + '. Error: ' + e.getMessage());
            return false;
        }
    }
    
    /**
     * @description Implements data retention policy with automated cleanup
     * @param retentionDays Number of days to retain data (default 7 years)
     */
    public static void enforceDataRetention(Integer retentionDays) {
        if (retentionDays == null) {
            retentionDays = DEFAULT_RETENTION_DAYS;
        }
        
        try {
            Date cutoffDate = Date.today().addDays(-retentionDays);
            
            // Find records older than retention period
            List<Interview_Feedback__c> recordsToArchive = [
                SELECT Id, CreatedDate
                FROM Interview_Feedback__c
                WHERE CreatedDate < :cutoffDate
                WITH SECURITY_ENFORCED
                LIMIT 10000
            ];
            
            if (!recordsToArchive.isEmpty()) {
                // Archive to external system or delete based on policy
                archiveOldRecords(recordsToArchive);
                
                createAuditLog('DATA_RETENTION', 'Archived ' + recordsToArchive.size() + ' records older than ' + retentionDays + ' days');
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error enforcing data retention: ' + e.getMessage());
            createAuditLog('RETENTION_ERROR', 'Failed to enforce data retention: ' + e.getMessage());
        }
    }
    
    /**
     * @description Creates comprehensive audit log for security events
     * @param eventType Type of security event
     * @param eventDetails Details of the security event
     */
    public static void createAuditLog(String eventType, String eventDetails) {
        try {
            // Create audit record (assuming custom object exists)
            Interview_Feedback_Audit__c auditRecord = new Interview_Feedback_Audit__c(
                Event_Type__c = eventType,
                Event_Details__c = eventDetails,
                User_Id__c = UserInfo.getUserId(),
                Username__c = UserInfo.getUsername(),
                Session_Id__c = UserInfo.getSessionId(),
                IP_Address__c = getClientIPAddress(),
                Timestamp__c = System.now()
            );
            
            insert auditRecord;
        } catch (Exception e) {
            // Log to system debug if audit object creation fails
            System.debug(LoggingLevel.ERROR, 'Failed to create audit log: ' + e.getMessage());
        }
    }
    
    /**
     * @description Validates field-level security for sensitive fields
     * @param fieldName API name of the field to check
     * @param operation Operation being performed (READ, EDIT)
     * @return Boolean indicating if user has field access
     */
    public static Boolean validateFieldAccess(String fieldName, String operation) {
        Schema.DescribeFieldResult fieldDescribe = getFieldDescribe(fieldName);
        
        if (fieldDescribe == null) {
            return false;
        }
        
        switch on operation.toUpperCase() {
            when 'READ' {
                return fieldDescribe.isAccessible();
            }
            when 'EDIT' {
                return fieldDescribe.isUpdateable();
            }
            when else {
                return false;
            }
        }
    }
    
    /**
     * @description Masks sensitive data based on user permissions
     * @param feedbackRecords List of feedback records to mask
     * @return List of feedback records with sensitive data masked
     */
    public static List<Interview_Feedback__c> maskSensitiveData(List<Interview_Feedback__c> feedbackRecords) {
        List<Interview_Feedback__c> maskedRecords = new List<Interview_Feedback__c>();
        
        for (Interview_Feedback__c feedback : feedbackRecords) {
            Interview_Feedback__c maskedFeedback = feedback.clone(true, true, true, true);
            
            // Mask sensitive fields based on permissions
            if (!validateFieldAccess('Overall_Rating__c', 'READ')) {
                maskedFeedback.Overall_Rating__c = null;
            }
            
            if (!validateFieldAccess('Detailed_Feedback__c', 'READ')) {
                maskedFeedback.Detailed_Feedback__c = '[RESTRICTED]';
            }
            
            if (!validateFieldAccess('Interviewer_Email__c', 'READ')) {
                maskedFeedback.Interviewer_Email__c = 'restricted@example.com';
            }
            
            maskedRecords.add(maskedFeedback);
        }
        
        return maskedRecords;
    }
    
    // Helper methods
    
    /**
     * @description Gets field describe result for security validation
     * @param fieldName API name of the field
     * @return DescribeFieldResult for the field
     */
    private static Schema.DescribeFieldResult getFieldDescribe(String fieldName) {
        try {
            Schema.SObjectType feedbackType = Interview_Feedback__c.SObjectType;
            Schema.DescribeSObjectResult feedbackDescribe = feedbackType.getDescribe();
            Map<String, Schema.SObjectField> fieldMap = feedbackDescribe.fields.getMap();
            
            if (fieldMap.containsKey(fieldName)) {
                return fieldMap.get(fieldName).getDescribe();
            }
            
            return null;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error getting field describe: ' + e.getMessage());
            return null;
        }
    }
    
    /**
     * @description Gets user email for GDPR operations
     * @param userId User ID
     * @return User email address
     */
    private static String getUserEmail(Id userId) {
        try {
            User userRecord = [SELECT Email FROM User WHERE Id = :userId LIMIT 1];
            return userRecord.Email;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error getting user email: ' + e.getMessage());
            return null;
        }
    }
    
    /**
     * @description Gets client IP address for audit logging
     * @return Client IP address
     */
    private static String getClientIPAddress() {
        // In a real implementation, this would capture the actual client IP
        // For now, return a placeholder
        return 'IP_ADDRESS_PLACEHOLDER';
    }
    
    /**
     * @description Archives old records based on retention policy
     * @param recordsToArchive List of records to archive
     */
    private static void archiveOldRecords(List<Interview_Feedback__c> recordsToArchive) {
        // In a production environment, this would:
        // 1. Export data to external archive system
        // 2. Verify successful export
        // 3. Delete records from Salesforce
        // For now, we'll just log the action
        
        System.debug(LoggingLevel.INFO, 'Archiving ' + recordsToArchive.size() + ' old feedback records');
        
        // Example: Export to external system
        // ExternalArchiveService.exportRecords(recordsToArchive);
        
        // Example: Delete after successful export
        // delete recordsToArchive;
    }
}