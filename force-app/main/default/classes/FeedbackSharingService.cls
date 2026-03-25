/**
 * @description Secure feedback sharing service for collaboration with mentors and coaches
 * @author System Generated
 * @date 2025
 */
public with sharing class FeedbackSharingService {
    
    // Constants for sharing configuration
    private static final Integer DEFAULT_EXPIRATION_DAYS = 30;
    private static final Integer MAX_EXPIRATION_DAYS = 90;
    private static final Integer TOKEN_LENGTH = 32;
    private static final Set<String> VALID_ACCESS_LEVELS = new Set<String>{
        'Read Only', 'Comment', 'Full Access'
    };
    
    // Data masking constants
    private static final String MASKED_TEXT = '[CONFIDENTIAL]';
    private static final Set<String> SENSITIVE_FIELDS = new Set<String>{
        'Detailed_Feedback__c', 'Strengths__c', 'Areas_for_Improvement__c'
    };
    
    /**
     * @description Creates a secure sharing link for interview feedback
     * @param feedbackId ID of the Interview Feedback to share
     * @param recipientEmail Email address of the recipient
     * @param accessLevel Access level (Read Only, Comment, Full Access)
     * @param expirationDays Number of days until expiration (optional)
     * @return String Secure sharing token
     * @throws SharingException for validation failures
     */
    public static String createShareLink(Id feedbackId, String recipientEmail, String accessLevel, Integer expirationDays) {
        if (feedbackId == null) {
            throw new SharingException('Feedback ID cannot be null');
        }
        
        if (String.isBlank(recipientEmail)) {
            throw new SharingException('Recipient email cannot be blank');
        }
        
        if (!isValidEmail(recipientEmail)) {
            throw new SharingException('Invalid email format: ' + recipientEmail);
        }
        
        if (String.isBlank(accessLevel) || !VALID_ACCESS_LEVELS.contains(accessLevel)) {
            throw new SharingException('Invalid access level. Must be one of: ' + VALID_ACCESS_LEVELS);
        }
        
        // Validate feedback exists and user has access
        validateFeedbackAccess(feedbackId);
        
        // Set expiration date
        Integer daysToExpire = expirationDays != null ? expirationDays : DEFAULT_EXPIRATION_DAYS;
        if (daysToExpire > MAX_EXPIRATION_DAYS) {
            daysToExpire = MAX_EXPIRATION_DAYS;
        }
        
        DateTime expirationDate = DateTime.now().addDays(daysToExpire);
        
        // Check if active share already exists for this recipient
        List<Feedback_Share__c> existingShares = [
            SELECT Id, Share_Token__c, Is_Active__c, Expiration_Date__c
            FROM Feedback_Share__c
            WHERE Interview_Feedback__c = :feedbackId
            AND Shared_With_Email__c = :recipientEmail
            AND Is_Active__c = true
            AND Expiration_Date__c > :DateTime.now()
            LIMIT 1
        ];
        
        if (!existingShares.isEmpty()) {
            // Extend existing share if needed
            Feedback_Share__c existingShare = existingShares[0];
            if (expirationDate > existingShare.Expiration_Date__c) {
                existingShare.Expiration_Date__c = expirationDate;
                existingShare.Access_Level__c = accessLevel; // Update access level
                update existingShare;
            }
            return existingShare.Share_Token__c;
        }
        
        // Generate unique token
        String shareToken = generateSecureToken();
        
        // Create new share record
        Feedback_Share__c feedbackShare = new Feedback_Share__c(
            Interview_Feedback__c = feedbackId,
            Shared_With_Email__c = recipientEmail,
            Share_Token__c = shareToken,
            Access_Level__c = accessLevel,
            Expiration_Date__c = expirationDate,
            Is_Active__c = true,
            Access_Count__c = 0
        );
        
        try {
            insert feedbackShare;
            
            // Create audit trail
            createAuditTrail(feedbackShare.Id, 'SHARE_CREATED', 
                           'Feedback shared with ' + recipientEmail + ' with ' + accessLevel + ' access');
            
            return shareToken;
            
        } catch (DmlException e) {
            throw new SharingException('Failed to create share link: ' + e.getMessage());
        }
    }
    
    /**
     * @description Validates share access and returns feedback data
     * @param shareToken Secure sharing token
     * @return SharedFeedbackData Feedback data with appropriate masking
     * @throws SharingException for invalid or expired tokens
     */
    public static SharedFeedbackData validateAndGetSharedFeedback(String shareToken) {
        if (String.isBlank(shareToken)) {
            throw new SharingException('Share token cannot be blank');
        }
        
        // Query share record with feedback data
        List<Feedback_Share__c> shares = [
            SELECT Id, Interview_Feedback__c, Shared_With_Email__c, Access_Level__c,
                   Expiration_Date__c, Is_Active__c, Access_Count__c,
                   Interview_Feedback__r.Job_Application__c,
                   Interview_Feedback__r.Interview_Round__c,
                   Interview_Feedback__r.Interview_Type__c,
                   Interview_Feedback__r.Interviewer_Name__c,
                   Interview_Feedback__r.Interview_Date__c,
                   Interview_Feedback__r.Overall_Rating__c,
                   Interview_Feedback__r.Technical_Rating__c,
                   Interview_Feedback__r.Communication_Rating__c,
                   Interview_Feedback__r.Cultural_Fit_Rating__c,
                   Interview_Feedback__r.Detailed_Feedback__c,
                   Interview_Feedback__r.Strengths__c,
                   Interview_Feedback__r.Areas_for_Improvement__c,
                   Interview_Feedback__r.Recommendation__c,
                   Interview_Feedback__r.Is_Confidential__c,
                   Interview_Feedback__r.Job_Application__r.Position_Title__c,
                   Interview_Feedback__r.Job_Application__r.Company_Name__c
            FROM Feedback_Share__c
            WHERE Share_Token__c = :shareToken
            AND Is_Active__c = true
            LIMIT 1
        ];
        
        if (shares.isEmpty()) {
            throw new SharingException('Invalid or inactive share token');
        }
        
        Feedback_Share__c share = shares[0];
        
        // Check expiration
        if (share.Expiration_Date__c < DateTime.now()) {
            throw new SharingException('Share link has expired');
        }
        
        // Update access count
        share.Access_Count__c = (share.Access_Count__c != null ? share.Access_Count__c : 0) + 1;
        update share;
        
        // Create audit trail
        createAuditTrail(share.Id, 'ACCESS_GRANTED', 
                       'Feedback accessed by ' + share.Shared_With_Email__c);
        
        // Prepare shared feedback data with appropriate masking
        SharedFeedbackData sharedData = new SharedFeedbackData();
        sharedData.shareId = share.Id;
        sharedData.accessLevel = share.Access_Level__c;
        sharedData.recipientEmail = share.Shared_With_Email__c;
        sharedData.expirationDate = share.Expiration_Date__c;
        sharedData.accessCount = share.Access_Count__c.intValue();
        
        // Populate feedback data
        Interview_Feedback__c feedback = share.Interview_Feedback__r;
        sharedData.feedbackId = feedback.Id;
        sharedData.jobApplicationId = feedback.Job_Application__c;
        sharedData.positionTitle = feedback.Job_Application__r.Position_Title__c;
        sharedData.companyName = feedback.Job_Application__r.Company_Name__c;
        sharedData.interviewRound = feedback.Interview_Round__c;
        sharedData.interviewType = feedback.Interview_Type__c;
        sharedData.interviewerName = feedback.Interviewer_Name__c;
        sharedData.interviewDate = feedback.Interview_Date__c;
        sharedData.overallRating = feedback.Overall_Rating__c;
        sharedData.technicalRating = feedback.Technical_Rating__c;
        sharedData.communicationRating = feedback.Communication_Rating__c;
        sharedData.culturalFitRating = feedback.Cultural_Fit_Rating__c;
        sharedData.recommendation = feedback.Recommendation__c;
        
        // Apply data masking for sensitive information
        Boolean isConfidential = feedback.Is_Confidential__c == true;
        Boolean hasReadOnlyAccess = share.Access_Level__c == 'Read Only';
        
        if (isConfidential || hasReadOnlyAccess) {
            sharedData.detailedFeedback = maskSensitiveData(feedback.Detailed_Feedback__c);
            sharedData.strengths = maskSensitiveData(feedback.Strengths__c);
            sharedData.areasForImprovement = maskSensitiveData(feedback.Areas_for_Improvement__c);
        } else {
            sharedData.detailedFeedback = feedback.Detailed_Feedback__c;
            sharedData.strengths = feedback.Strengths__c;
            sharedData.areasForImprovement = feedback.Areas_for_Improvement__c;
        }
        
        return sharedData;
    }
    
    /**
     * @description Adds mentor comment to shared feedback
     * @param shareToken Secure sharing token
     * @param mentorEmail Email of the mentor adding comment
     * @param comment Comment text
     * @return Id ID of the created comment record
     * @throws SharingException for validation failures
     */
    public static Id addMentorComment(String shareToken, String mentorEmail, String comment) {
        if (String.isBlank(shareToken)) {
            throw new SharingException('Share token cannot be blank');
        }
        
        if (String.isBlank(mentorEmail)) {
            throw new SharingException('Mentor email cannot be blank');
        }
        
        if (String.isBlank(comment)) {
            throw new SharingException('Comment cannot be blank');
        }
        
        // Validate share access
        SharedFeedbackData sharedData = validateAndGetSharedFeedback(shareToken);
        
        // Check if mentor has comment access
        if (sharedData.accessLevel == 'Read Only') {
            throw new SharingException('Read Only access does not allow commenting');
        }
        
        // Verify mentor email matches share recipient
        if (!sharedData.recipientEmail.equalsIgnoreCase(mentorEmail)) {
            throw new SharingException('Mentor email does not match share recipient');
        }
        
        // Create comment record (using Task as a simple comment system)
        Task mentorComment = new Task(
            WhatId = sharedData.feedbackId,
            Subject = 'Mentor Comment from ' + mentorEmail,
            Description = comment,
            ActivityDate = Date.today(),
            Status = 'Completed',
            Priority = 'Normal',
            Type = 'Other'
        );
        
        try {
            insert mentorComment;
            
            // Create audit trail
            createAuditTrail(sharedData.shareId, 'COMMENT_ADDED', 
                           'Comment added by ' + mentorEmail);
            
            return mentorComment.Id;
            
        } catch (DmlException e) {
            throw new SharingException('Failed to add mentor comment: ' + e.getMessage());
        }
    }
    
    /**
     * @description Revokes access to shared feedback
     * @param shareId ID of the share record to revoke
     * @throws SharingException for validation failures
     */
    public static void revokeAccess(Id shareId) {
        if (shareId == null) {
            throw new SharingException('Share ID cannot be null');
        }
        
        // Validate share exists and user has permission to revoke
        List<Feedback_Share__c> shares = [
            SELECT Id, Is_Active__c, Shared_With_Email__c,
                   Interview_Feedback__r.Job_Application__r.OwnerId
            FROM Feedback_Share__c
            WHERE Id = :shareId
            LIMIT 1
        ];
        
        if (shares.isEmpty()) {
            throw new SharingException('Share record not found');
        }
        
        Feedback_Share__c share = shares[0];
        
        // Check if current user owns the job application
        if (share.Interview_Feedback__r.Job_Application__r.OwnerId != UserInfo.getUserId()) {
            throw new SharingException('Insufficient permissions to revoke access');
        }
        
        // Revoke access
        share.Is_Active__c = false;
        
        try {
            update share;
            
            // Create audit trail
            createAuditTrail(share.Id, 'ACCESS_REVOKED', 
                           'Access revoked for ' + share.Shared_With_Email__c);
            
        } catch (DmlException e) {
            throw new SharingException('Failed to revoke access: ' + e.getMessage());
        }
    }
    
    /**
     * @description Gets all active shares for a feedback record
     * @param feedbackId ID of the Interview Feedback
     * @return List<ShareSummary> List of active shares
     */
    public static List<ShareSummary> getActiveShares(Id feedbackId) {
        if (feedbackId == null) {
            throw new SharingException('Feedback ID cannot be null');
        }
        
        // Validate feedback access
        validateFeedbackAccess(feedbackId);
        
        List<Feedback_Share__c> shares = [
            SELECT Id, Shared_With_Email__c, Access_Level__c, Expiration_Date__c,
                   Access_Count__c, CreatedDate, CreatedBy.Name
            FROM Feedback_Share__c
            WHERE Interview_Feedback__c = :feedbackId
            AND Is_Active__c = true
            AND Expiration_Date__c > :DateTime.now()
            ORDER BY CreatedDate DESC
        ];
        
        List<ShareSummary> summaries = new List<ShareSummary>();
        for (Feedback_Share__c share : shares) {
            ShareSummary summary = new ShareSummary();
            summary.shareId = share.Id;
            summary.recipientEmail = share.Shared_With_Email__c;
            summary.accessLevel = share.Access_Level__c;
            summary.expirationDate = share.Expiration_Date__c;
            summary.accessCount = share.Access_Count__c != null ? share.Access_Count__c.intValue() : 0;
            summary.createdDate = share.CreatedDate;
            summary.createdByName = share.CreatedBy.Name;
            summaries.add(summary);
        }
        
        return summaries;
    }
    
    /**
     * @description Extends expiration date for an active share
     * @param shareId ID of the share to extend
     * @param additionalDays Number of additional days to extend
     * @throws SharingException for validation failures
     */
    public static void extendShareExpiration(Id shareId, Integer additionalDays) {
        if (shareId == null) {
            throw new SharingException('Share ID cannot be null');
        }
        
        if (additionalDays == null || additionalDays <= 0) {
            throw new SharingException('Additional days must be positive');
        }
        
        List<Feedback_Share__c> shares = [
            SELECT Id, Expiration_Date__c, Shared_With_Email__c,
                   Interview_Feedback__r.Job_Application__r.OwnerId
            FROM Feedback_Share__c
            WHERE Id = :shareId
            AND Is_Active__c = true
            LIMIT 1
        ];
        
        if (shares.isEmpty()) {
            throw new SharingException('Active share record not found');
        }
        
        Feedback_Share__c share = shares[0];
        
        // Check permissions
        if (share.Interview_Feedback__r.Job_Application__r.OwnerId != UserInfo.getUserId()) {
            throw new SharingException('Insufficient permissions to extend share');
        }
        
        // Calculate new expiration date
        DateTime newExpiration = share.Expiration_Date__c.addDays(additionalDays);
        DateTime maxExpiration = DateTime.now().addDays(MAX_EXPIRATION_DAYS);
        
        if (newExpiration > maxExpiration) {
            newExpiration = maxExpiration;
        }
        
        share.Expiration_Date__c = newExpiration;
        
        try {
            update share;
            
            // Create audit trail
            createAuditTrail(share.Id, 'EXPIRATION_EXTENDED', 
                           'Expiration extended by ' + additionalDays + ' days for ' + share.Shared_With_Email__c);
            
        } catch (DmlException e) {
            throw new SharingException('Failed to extend share expiration: ' + e.getMessage());
        }
    }
    
    /**
     * @description Validates that user has access to the feedback record
     * @param feedbackId ID of the Interview Feedback
     * @throws SharingException if access is denied
     */
    private static void validateFeedbackAccess(Id feedbackId) {
        List<Interview_Feedback__c> feedbacks = [
            SELECT Id, Job_Application__r.OwnerId
            FROM Interview_Feedback__c
            WHERE Id = :feedbackId
            LIMIT 1
        ];
        
        if (feedbacks.isEmpty()) {
            throw new SharingException('Feedback record not found');
        }
        
        Interview_Feedback__c feedback = feedbacks[0];
        if (feedback.Job_Application__r.OwnerId != UserInfo.getUserId()) {
            throw new SharingException('Insufficient permissions to access feedback');
        }
    }
    
    /**
     * @description Generates a cryptographically secure token
     * @return String Secure random token
     */
    private static String generateSecureToken() {
        String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
        String token = '';
        
        for (Integer i = 0; i < TOKEN_LENGTH; i++) {
            Integer randomIndex = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
            token += chars.substring(randomIndex, randomIndex + 1);
        }
        
        // Ensure uniqueness by checking existing tokens
        List<Feedback_Share__c> existingShares = [
            SELECT Id FROM Feedback_Share__c WHERE Share_Token__c = :token LIMIT 1
        ];
        
        if (!existingShares.isEmpty()) {
            // Recursively generate new token if collision occurs
            return generateSecureToken();
        }
        
        return token;
    }
    
    /**
     * @description Validates email format
     * @param email Email address to validate
     * @return Boolean True if valid email format
     */
    private static Boolean isValidEmail(String email) {
        String emailRegex = '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$';
        Pattern emailPattern = Pattern.compile(emailRegex);
        return emailPattern.matcher(email).matches();
    }
    
    /**
     * @description Masks sensitive data for privacy protection
     * @param originalText Original text to mask
     * @return String Masked text or original if not sensitive
     */
    private static String maskSensitiveData(String originalText) {
        if (String.isBlank(originalText)) {
            return originalText;
        }
        
        // For demo purposes, mask with placeholder
        // In production, could implement more sophisticated masking
        return MASKED_TEXT + ' (Content hidden for privacy)';
    }
    
    /**
     * @description Creates audit trail for sharing activities
     * @param shareId ID of the share record
     * @param action Action performed
     * @param details Additional details
     */
    private static void createAuditTrail(Id shareId, String action, String details) {
        try {
            // Create audit record using Task for simplicity
            Task auditRecord = new Task(
                WhatId = shareId,
                Subject = 'Sharing Audit: ' + action,
                Description = details + ' at ' + DateTime.now().format(),
                ActivityDate = Date.today(),
                Status = 'Completed',
                Priority = 'Low',
                Type = 'Other'
            );
            
            insert auditRecord;
            
        } catch (Exception e) {
            // Audit failure should not break main functionality
            System.debug('Audit trail creation failed: ' + e.getMessage());
        }
    }
    
    /**
     * @description Custom exception for sharing errors
     */
    public class SharingException extends Exception {}
    
    /**
     * @description Wrapper class for shared feedback data
     */
    public class SharedFeedbackData {
        public Id shareId { get; set; }
        public Id feedbackId { get; set; }
        public Id jobApplicationId { get; set; }
        public String accessLevel { get; set; }
        public String recipientEmail { get; set; }
        public DateTime expirationDate { get; set; }
        public Integer accessCount { get; set; }
        
        // Job Application data
        public String positionTitle { get; set; }
        public String companyName { get; set; }
        
        // Interview Feedback data
        public String interviewRound { get; set; }
        public String interviewType { get; set; }
        public String interviewerName { get; set; }
        public Date interviewDate { get; set; }
        public Decimal overallRating { get; set; }
        public Decimal technicalRating { get; set; }
        public Decimal communicationRating { get; set; }
        public Decimal culturalFitRating { get; set; }
        public String detailedFeedback { get; set; }
        public String strengths { get; set; }
        public String areasForImprovement { get; set; }
        public String recommendation { get; set; }
    }
    
    /**
     * @description Wrapper class for share summary information
     */
    public class ShareSummary {
        public Id shareId { get; set; }
        public String recipientEmail { get; set; }
        public String accessLevel { get; set; }
        public DateTime expirationDate { get; set; }
        public Integer accessCount { get; set; }
        public DateTime createdDate { get; set; }
        public String createdByName { get; set; }
    }
}