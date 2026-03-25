/**
 * @description Service class for managing feedback templates
 * @author System Generated
 * @date 2025
 */
public with sharing class FeedbackTemplateService {
    
    /**
     * @description Retrieves a feedback template by ID
     * @param templateId ID of the template to retrieve
     * @return Feedback_Template__c Template record or null if not found
     */
    @AuraEnabled(cacheable=true)
    public static Feedback_Template__c getFeedbackTemplate(Id templateId) {
        if (templateId == null) {
            return null;
        }
        
        try {
            List<Feedback_Template__c> templates = [
                SELECT Id, Template_Name__c, Interview_Type__c, Competency_Areas__c,
                       Rating_Scale__c, Template_Description__c, Is_Active__c,
                       Form_Configuration__c
                FROM Feedback_Template__c
                WHERE Id = :templateId
                AND Is_Active__c = true
                LIMIT 1
            ];
            
            return templates.isEmpty() ? null : templates[0];
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error retrieving feedback template: ' + e.getMessage());
            throw new AuraHandledException('Failed to retrieve feedback template: ' + e.getMessage());
        }
    }
    
    /**
     * @description Retrieves active feedback templates by interview type
     * @param interviewType Type of interview to filter by
     * @return List<Feedback_Template__c> List of matching templates
     */
    @AuraEnabled(cacheable=true)
    public static List<Feedback_Template__c> getTemplatesByType(String interviewType) {
        try {
            String query = 'SELECT Id, Template_Name__c, Interview_Type__c, Template_Description__c ' +
                          'FROM Feedback_Template__c WHERE Is_Active__c = true';
            
            if (String.isNotBlank(interviewType)) {
                query += ' AND Interview_Type__c = :interviewType';
            }
            
            query += ' ORDER BY Template_Name__c ASC';
            
            return Database.query(query);
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error retrieving templates by type: ' + e.getMessage());
            throw new AuraHandledException('Failed to retrieve templates: ' + e.getMessage());
        }
    }
    
    /**
     * @description Retrieves all active feedback templates
     * @return List<Feedback_Template__c> List of all active templates
     */
    @AuraEnabled(cacheable=true)
    public static List<Feedback_Template__c> getAllActiveTemplates() {
        try {
            return [
                SELECT Id, Template_Name__c, Interview_Type__c, Template_Description__c,
                       Competency_Areas__c, Rating_Scale__c, Usage_Count__c
                FROM Feedback_Template__c
                WHERE Is_Active__c = true
                ORDER BY Template_Name__c ASC
            ];
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error retrieving all templates: ' + e.getMessage());
            throw new AuraHandledException('Failed to retrieve templates: ' + e.getMessage());
        }
    }
}