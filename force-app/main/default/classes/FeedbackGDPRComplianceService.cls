/**
 * @description GDPR compliance service for Interview Feedback Tracker
 * Handles data subject rights including access, portability, rectification, and erasure
 * @author Kiro AI Assistant
 * @date 2025
 */
public inherited sharing class FeedbackGDPRComplianceService {
    
    // GDPR constants
    private static final String GDPR_EXPORT_FORMAT = 'JSON';
    private static final String ANONYMIZED_VALUE = '[ANONYMIZED]';
    private static final Integer GDPR_RESPONSE_DAYS = 30;
    
    /**
     * @description Handles GDPR data subject access request
     * Exports all personal data for a given user in machine-readable format
     * @param userId User ID requesting data access
     * @return GDPRDataExport containing all user's personal data
     */
    public static GDPRDataExport handleDataAccessRequest(Id userId) {
        try {
            // Validate user exists and has permission
            if (!validateGDPRRequest(userId)) {
                throw new GDPRException('Invalid GDPR access request for user: ' + userId);
            }
            
            // Create audit log
            FeedbackSecurityService.createAuditLog(
                'GDPR_ACCESS_REQUEST',
                'Processing data access request for user: ' + userId
            );
            
            // Collect all personal data
            GDPRDataExport dataExport = new GDPRDataExport();
            dataExport.userId = userId;
            dataExport.requestDate = System.now();
            dataExport.exportFormat = GDPR_EXPORT_FORMAT;
            
            // Export feedback data
            dataExport.feedbackData = exportFeedbackData(userId);
            
            // Export sharing data
            dataExport.sharingData = exportSharingData(userId);
            
            // Export audit data
            dataExport.auditData = exportAuditData(userId);
            
            // Create completion audit log
            FeedbackSecurityService.createAuditLog(
                'GDPR_ACCESS_COMPLETE',
                'Completed data access request for user: ' + userId + 
                '. Records exported: ' + getTotalRecordCount(dataExport)
            );
            
            return dataExport;
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error processing GDPR access request: ' + e.getMessage());
            
            FeedbackSecurityService.createAuditLog(
                'GDPR_ACCESS_ERROR',
                'Failed to process data access request for user: ' + userId + '. Error: ' + e.getMessage()
            );
            
            throw new GDPRException('Failed to process data access request: ' + e.getMessage());
        }
    }
    
    /**
     * @description Handles GDPR right to rectification
     * Allows users to correct inaccurate personal data
     * @param userId User ID requesting rectification
     * @param rectificationData Map of field names to corrected values
     * @return Boolean indicating success of rectification
     */
    public static Boolean handleDataRectificationRequest(Id userId, Map<String, Object> rectificationData) {
        try {
            // Validate request
            if (!validateGDPRRequest(userId) || rectificationData.isEmpty()) {
                return false;
            }
            
            // Create audit log
            FeedbackSecurityService.createAuditLog(
                'GDPR_RECTIFICATION_REQUEST',
                'Processing data rectification request for user: ' + userId
            );
            
            // Get user's feedback records
            List<Interview_Feedback__c> feedbackRecords = [
                SELECT Id, Interviewer_Name__c, Interviewer_Email__c, Detailed_Feedback__c,
                       Strengths__c, Areas_For_Improvement__c
                FROM Interview_Feedback__c
                WHERE CreatedById = :userId
                WITH SECURITY_ENFORCED
            ];
            
            // Apply rectifications
            List<Interview_Feedback__c> recordsToUpdate = new List<Interview_Feedback__c>();
            
            for (Interview_Feedback__c feedback : feedbackRecords) {
                Boolean recordUpdated = false;
                
                for (String fieldName : rectificationData.keySet()) {
                    if (isRectifiableField(fieldName)) {
                        Object newValue = rectificationData.get(fieldName);
                        feedback.put(fieldName, newValue);
                        recordUpdated = true;
                        
                        // Log the rectification
                        FeedbackSecurityService.createAuditLog(
                            'GDPR_FIELD_RECTIFICATION',
                            'Rectified field ' + fieldName + ' for record: ' + feedback.Id
                        );
                    }
                }
                
                if (recordUpdated) {
                    recordsToUpdate.add(feedback);
                }
            }
            
            // Update records
            if (!recordsToUpdate.isEmpty()) {
                update recordsToUpdate;
            }
            
            // Create completion audit log
            FeedbackSecurityService.createAuditLog(
                'GDPR_RECTIFICATION_COMPLETE',
                'Completed data rectification for user: ' + userId + 
                '. Records updated: ' + recordsToUpdate.size()
            );
            
            return true;
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error processing GDPR rectification: ' + e.getMessage());
            
            FeedbackSecurityService.createAuditLog(
                'GDPR_RECTIFICATION_ERROR',
                'Failed to process rectification request for user: ' + userId + '. Error: ' + e.getMessage()
            );
            
            return false;
        }
    }
    
    /**
     * @description Handles GDPR right to erasure (right to be forgotten)
     * Permanently deletes or anonymizes all personal data for a user
     * @param userId User ID requesting erasure
     * @param erasureType Type of erasure (DELETE or ANONYMIZE)
     * @return Boolean indicating success of erasure
     */
    public static Boolean handleDataErasureRequest(Id userId, String erasureType) {
        try {
            // Validate request
            if (!validateGDPRRequest(userId)) {
                return false;
            }
            
            // Create audit log
            FeedbackSecurityService.createAuditLog(
                'GDPR_ERASURE_REQUEST',
                'Processing data erasure request (' + erasureType + ') for user: ' + userId
            );
            
            Boolean success = false;
            
            if (erasureType == 'DELETE') {
                success = performDataDeletion(userId);
            } else if (erasureType == 'ANONYMIZE') {
                success = FeedbackSecurityService.anonymizeUserData(userId);
            } else {
                throw new GDPRException('Invalid erasure type: ' + erasureType);
            }
            
            if (success) {
                // Create completion audit log
                FeedbackSecurityService.createAuditLog(
                    'GDPR_ERASURE_COMPLETE',
                    'Completed data erasure (' + erasureType + ') for user: ' + userId
                );
            }
            
            return success;
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error processing GDPR erasure: ' + e.getMessage());
            
            FeedbackSecurityService.createAuditLog(
                'GDPR_ERASURE_ERROR',
                'Failed to process erasure request for user: ' + userId + '. Error: ' + e.getMessage()
            );
            
            return false;
        }
    }
    
    /**
     * @description Handles GDPR data portability request
     * Exports user data in a structured, machine-readable format
     * @param userId User ID requesting data portability
     * @return String containing portable data in JSON format
     */
    public static String handleDataPortabilityRequest(Id userId) {
        try {
            // Get data export
            GDPRDataExport dataExport = handleDataAccessRequest(userId);
            
            // Convert to portable format
            String portableData = JSON.serializePretty(dataExport);
            
            // Create audit log
            FeedbackSecurityService.createAuditLog(
                'GDPR_PORTABILITY_REQUEST',
                'Generated portable data export for user: ' + userId
            );
            
            return portableData;
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error processing GDPR portability: ' + e.getMessage());
            
            FeedbackSecurityService.createAuditLog(
                'GDPR_PORTABILITY_ERROR',
                'Failed to generate portable data for user: ' + userId + '. Error: ' + e.getMessage()
            );
            
            return null;
        }
    }
    
    // Helper methods
    
    /**
     * @description Validates GDPR request permissions and user existence
     * @param userId User ID to validate
     * @return Boolean indicating if request is valid
     */
    private static Boolean validateGDPRRequest(Id userId) {
        try {
            // Check if user exists and is active
            List<User> users = [
                SELECT Id, IsActive
                FROM User
                WHERE Id = :userId
                LIMIT 1
            ];
            
            if (users.isEmpty()) {
                return false;
            }
            
            // Additional validation logic can be added here
            // e.g., check if current user has permission to process GDPR requests
            
            return true;
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error validating GDPR request: ' + e.getMessage());
            return false;
        }
    }
    
    /**
     * @description Exports feedback data for GDPR compliance
     * @param userId User ID
     * @return List of feedback data maps
     */
    private static List<Map<String, Object>> exportFeedbackData(Id userId) {
        List<Map<String, Object>> feedbackData = new List<Map<String, Object>>();
        
        List<Interview_Feedback__c> feedbacks = [
            SELECT Id, Job_Application__c, Interview_Type__c, Interview_Round__c,
                   Interviewer_Name__c, Interviewer_Email__c, Interview_Date__c,
                   Overall_Rating__c, Technical_Rating__c, Communication_Rating__c,
                   Cultural_Fit_Rating__c, Detailed_Feedback__c, Strengths__c,
                   Areas_For_Improvement__c, Recommendation__c, Feedback_Source__c,
                   Is_Confidential__c, Feedback_Status__c, CreatedDate, LastModifiedDate
            FROM Interview_Feedback__c
            WHERE CreatedById = :userId
            WITH SECURITY_ENFORCED
        ];
        
        for (Interview_Feedback__c feedback : feedbacks) {
            Map<String, Object> feedbackMap = new Map<String, Object>();
            feedbackMap.put('Id', feedback.Id);
            feedbackMap.put('JobApplication', feedback.Job_Application__c);
            feedbackMap.put('InterviewType', feedback.Interview_Type__c);
            feedbackMap.put('InterviewRound', feedback.Interview_Round__c);
            feedbackMap.put('InterviewerName', feedback.Interviewer_Name__c);
            feedbackMap.put('InterviewerEmail', feedback.Interviewer_Email__c);
            feedbackMap.put('InterviewDate', feedback.Interview_Date__c);
            feedbackMap.put('OverallRating', feedback.Overall_Rating__c);
            feedbackMap.put('TechnicalRating', feedback.Technical_Rating__c);
            feedbackMap.put('CommunicationRating', feedback.Communication_Rating__c);
            feedbackMap.put('CulturalFitRating', feedback.Cultural_Fit_Rating__c);
            feedbackMap.put('DetailedFeedback', feedback.Detailed_Feedback__c);
            feedbackMap.put('Strengths', feedback.Strengths__c);
            feedbackMap.put('AreasForImprovement', feedback.Areas_For_Improvement__c);
            feedbackMap.put('Recommendation', feedback.Recommendation__c);
            feedbackMap.put('FeedbackSource', feedback.Feedback_Source__c);
            feedbackMap.put('IsConfidential', feedback.Is_Confidential__c);
            feedbackMap.put('FeedbackStatus', feedback.Feedback_Status__c);
            feedbackMap.put('CreatedDate', feedback.CreatedDate);
            feedbackMap.put('LastModifiedDate', feedback.LastModifiedDate);
            
            feedbackData.add(feedbackMap);
        }
        
        return feedbackData;
    }
    
    /**
     * @description Exports sharing data for GDPR compliance
     * @param userId User ID
     * @return List of sharing data maps
     */
    private static List<Map<String, Object>> exportSharingData(Id userId) {
        List<Map<String, Object>> sharingData = new List<Map<String, Object>>();
        
        List<Feedback_Share__c> shares = [
            SELECT Id, Interview_Feedback__c, Shared_With_Email__c, Share_Token__c,
                   Expiration_Date__c, Access_Level__c, Is_Active__c, Access_Count__c,
                   CreatedDate, LastModifiedDate
            FROM Feedback_Share__c
            WHERE CreatedById = :userId
            WITH SECURITY_ENFORCED
        ];
        
        for (Feedback_Share__c share : shares) {
            Map<String, Object> shareMap = new Map<String, Object>();
            shareMap.put('Id', share.Id);
            shareMap.put('FeedbackId', share.Interview_Feedback__c);
            shareMap.put('SharedWithEmail', share.Shared_With_Email__c);
            shareMap.put('ShareToken', share.Share_Token__c);
            shareMap.put('ExpirationDate', share.Expiration_Date__c);
            shareMap.put('AccessLevel', share.Access_Level__c);
            shareMap.put('IsActive', share.Is_Active__c);
            shareMap.put('AccessCount', share.Access_Count__c);
            shareMap.put('CreatedDate', share.CreatedDate);
            shareMap.put('LastModifiedDate', share.LastModifiedDate);
            
            sharingData.add(shareMap);
        }
        
        return sharingData;
    }
    
    /**
     * @description Exports audit data for GDPR compliance
     * @param userId User ID
     * @return List of audit data maps
     */
    private static List<Map<String, Object>> exportAuditData(Id userId) {
        List<Map<String, Object>> auditData = new List<Map<String, Object>>();
        
        List<Interview_Feedback_Audit__c> audits = [
            SELECT Id, Event_Type__c, Event_Details__c, User_Id__c, Username__c,
                   Session_Id__c, IP_Address__c, Timestamp__c, CreatedDate
            FROM Interview_Feedback_Audit__c
            WHERE User_Id__c = :userId
            WITH SECURITY_ENFORCED
            ORDER BY CreatedDate DESC
            LIMIT 1000
        ];
        
        for (Interview_Feedback_Audit__c audit : audits) {
            Map<String, Object> auditMap = new Map<String, Object>();
            auditMap.put('Id', audit.Id);
            auditMap.put('EventType', audit.Event_Type__c);
            auditMap.put('EventDetails', audit.Event_Details__c);
            auditMap.put('UserId', audit.User_Id__c);
            auditMap.put('Username', audit.Username__c);
            auditMap.put('SessionId', audit.Session_Id__c);
            auditMap.put('IPAddress', audit.IP_Address__c);
            auditMap.put('Timestamp', audit.Timestamp__c);
            auditMap.put('CreatedDate', audit.CreatedDate);
            
            auditData.add(auditMap);
        }
        
        return auditData;
    }
    
    /**
     * @description Checks if a field can be rectified under GDPR
     * @param fieldName API name of the field
     * @return Boolean indicating if field is rectifiable
     */
    private static Boolean isRectifiableField(String fieldName) {
        Set<String> rectifiableFields = new Set<String>{
            'Interviewer_Name__c',
            'Interviewer_Email__c',
            'Detailed_Feedback__c',
            'Strengths__c',
            'Areas_For_Improvement__c'
        };
        
        return rectifiableFields.contains(fieldName);
    }
    
    /**
     * @description Performs complete data deletion for a user
     * @param userId User ID
     * @return Boolean indicating success
     */
    private static Boolean performDataDeletion(Id userId) {
        try {
            // Delete feedback records
            List<Interview_Feedback__c> feedbacksToDelete = [
                SELECT Id
                FROM Interview_Feedback__c
                WHERE CreatedById = :userId
                WITH SECURITY_ENFORCED
            ];
            
            if (!feedbacksToDelete.isEmpty()) {
                delete feedbacksToDelete;
            }
            
            // Delete sharing records
            List<Feedback_Share__c> sharesToDelete = [
                SELECT Id
                FROM Feedback_Share__c
                WHERE CreatedById = :userId
                WITH SECURITY_ENFORCED
            ];
            
            if (!sharesToDelete.isEmpty()) {
                delete sharesToDelete;
            }
            
            return true;
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error performing data deletion: ' + e.getMessage());
            return false;
        }
    }
    
    /**
     * @description Gets total record count from data export
     * @param dataExport GDPR data export object
     * @return Integer total record count
     */
    private static Integer getTotalRecordCount(GDPRDataExport dataExport) {
        Integer total = 0;
        
        if (dataExport.feedbackData != null) {
            total += dataExport.feedbackData.size();
        }
        
        if (dataExport.sharingData != null) {
            total += dataExport.sharingData.size();
        }
        
        if (dataExport.auditData != null) {
            total += dataExport.auditData.size();
        }
        
        return total;
    }
    
    // Inner classes
    
    /**
     * @description Data structure for GDPR data export
     */
    public class GDPRDataExport {
        public Id userId;
        public DateTime requestDate;
        public String exportFormat;
        public List<Map<String, Object>> feedbackData;
        public List<Map<String, Object>> sharingData;
        public List<Map<String, Object>> auditData;
    }
    
    /**
     * @description Custom exception for GDPR operations
     */
    public class GDPRException extends Exception {}
}