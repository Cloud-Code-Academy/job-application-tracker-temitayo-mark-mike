/**
 * @description Service class for assigning primary contacts to Job Applications
 * Implements business logic for automatic contact assignment
 * @author Temitayo Oluwalade
 * @date 2024
 */
public with sharing class ContactAssignmentService {
    
    /**
     * @description Assigns primary contact to job applications that don't have one
     * @param jobApplications List of Job Application records
     */
    public static void assignPrimaryContact(List<Job_Application__c> jobApplications) {
        // Filter records that need contact assignment
        List<Job_Application__c> recordsNeedingContact = new List<Job_Application__c>();
        Set<Id> jobAppIds = new Set<Id>();
        
        for (Job_Application__c jobApp : jobApplications) {
            if (jobApp.Primary_Contact__c == null) {
                recordsNeedingContact.add(jobApp);
                jobAppIds.add(jobApp.Id);
            }
        }
        
        if (recordsNeedingContact.isEmpty()) {
            return;
        }
        
        // Query for related contacts through Account relationships
        Map<Id, List<Contact>> jobAppToContacts = getRelatedContacts(jobAppIds);
        
        // Assign primary contacts directly to the records (no DML needed in trigger context)
        for (Job_Application__c jobApp : recordsNeedingContact) {
            List<Contact> relatedContacts = jobAppToContacts.get(jobApp.Id);

            if (relatedContacts != null && !relatedContacts.isEmpty()) {
                // Use the first available contact
                jobApp.Primary_Contact__c = relatedContacts[0].Id;
            }
        }
    }
    
    /**
     * @description Queries for contacts related to job applications
     * First looks for contacts directly related to the job application,
     * then looks for contacts related to the company account
     * @param jobAppIds Set of Job Application Ids
     * @return Map of Job Application Id to List of related Contacts
     */
    private static Map<Id, List<Contact>> getRelatedContacts(Set<Id> jobAppIds) {
        Map<Id, List<Contact>> jobAppToContacts = new Map<Id, List<Contact>>();
        
        // Initialize map with empty lists
        for (Id jobAppId : jobAppIds) {
            jobAppToContacts.put(jobAppId, new List<Contact>());
        }
        
        // First, look for contacts directly related to job applications
        // This would require a junction object or custom relationship
        // For now, we'll focus on Account-based relationships
        
        // Query job applications with company information
        Map<Id, Job_Application__c> jobAppsWithCompany = new Map<Id, Job_Application__c>([
            SELECT Id, Company_Name__c
            FROM Job_Application__c
            WHERE Id IN :jobAppIds
            AND Company_Name__c != null
        ]);
        
        if (jobAppsWithCompany.isEmpty()) {
            return jobAppToContacts;
        }
        
        // Get company names to search for accounts
        Set<String> companyNames = new Set<String>();
        for (Job_Application__c jobApp : jobAppsWithCompany.values()) {
            companyNames.add(jobApp.Company_Name__c);
        }
        
        // Query accounts that match company names
        Map<String, Account> companyNameToAccount = new Map<String, Account>();
        for (Account acc : [
            SELECT Id, Name
            FROM Account
            WHERE Name IN :companyNames
            LIMIT 100
        ]) {
            companyNameToAccount.put(acc.Name, acc);
        }
        
        if (companyNameToAccount.isEmpty()) {
            return jobAppToContacts;
        }
        
        // Query contacts for matching accounts
        Map<Id, List<Contact>> accountToContacts = new Map<Id, List<Contact>>();
        for (Contact con : [
            SELECT Id, AccountId, Name, Email, Title
            FROM Contact
            WHERE AccountId IN :companyNameToAccount.values()
            ORDER BY CreatedDate ASC
            LIMIT 200
        ]) {
            if (!accountToContacts.containsKey(con.AccountId)) {
                accountToContacts.put(con.AccountId, new List<Contact>());
            }
            accountToContacts.get(con.AccountId).add(con);
        }
        
        // Map contacts back to job applications
        for (Job_Application__c jobApp : jobAppsWithCompany.values()) {
            Account matchingAccount = companyNameToAccount.get(jobApp.Company_Name__c);
            if (matchingAccount != null) {
                List<Contact> accountContacts = accountToContacts.get(matchingAccount.Id);
                if (accountContacts != null) {
                    jobAppToContacts.put(jobApp.Id, accountContacts);
                }
            }
        }
        
        return jobAppToContacts;
    }
}
