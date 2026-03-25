/**
 * @description Service for enriching Job Applications with company data from external APIs
 * @author Learning Journey
 * @date 2025-01-08
 */
public inherited sharing class CompanyDataService extends BaseApiService {
    
    // API configuration — uses Named Credential for secure auth (no hard-coded keys)
    // Setup: Setup > Named Credentials > "Company_Data_API"
    private static final String NAMED_CREDENTIAL = 'callout:Company_Data_API';
    
    /**
     * @description Wrapper class for company data response
     */
    public class CompanyData {
        public String companyName { get; set; }
        public String industry { get; set; }
        public String size { get; set; }
        public String website { get; set; }
        public String description { get; set; }
        public String headquarters { get; set; }
        public Integer employeeCount { get; set; }
        public Decimal revenue { get; set; }
        public String founded { get; set; }
        public List<String> technologies { get; set; }
        public CompanyRating rating { get; set; }
        
        public CompanyData() {
            this.technologies = new List<String>();
        }
    }
    
    /**
     * @description Company rating information
     */
    public class CompanyRating {
        public Decimal overallRating { get; set; }
        public Decimal workLifeBalance { get; set; }
        public Decimal compensation { get; set; }
        public Decimal culture { get; set; }
        public Integer reviewCount { get; set; }
    }
    
    /**
     * @description Get company data by company name
     * @param companyName Name of the company to lookup
     * @return CompanyData or null if not found
     */
    public CompanyData getCompanyByName(String companyName) {
        if (String.isBlank(companyName)) {
            return null;
        }
        
        try {
            // Build API request — Named Credential handles auth headers automatically
            ApiRequest request = new ApiRequest();
            request.endpoint = NAMED_CREDENTIAL + '/companies/search';
            request.method = HTTP_GET;
            request.parameters.put('name', companyName);
            request.parameters.put('include', 'details,ratings,technologies');
            
            // Make API call
            ApiResponse response = makeCallout(request);
            
            if (response.isSuccess) {
                return parseCompanyResponse(response.body);
            } else {
                System.debug(LoggingLevel.ERROR, 'Company API call failed: ' + response.errorMessage);
                return null;
            }
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error getting company data: ' + e.getMessage());
            return null;
        }
    }
    
    /**
     * @description Enrich Job Application with company data
     * @param jobAppId Job Application record ID
     * @return True if enrichment was successful
     */
    public Boolean enrichJobApplication(Id jobAppId) {
        if (jobAppId == null) {
            return false;
        }
        
        try {
            // Get Job Application record
            Job_Application__c jobApp = [SELECT Id, Company_Name__c, Job_URL__c 
                                       FROM Job_Application__c 
                                       WHERE Id = :jobAppId LIMIT 1];
            
            CompanyData companyData = null;
            
            // Try to get company data by name first
            if (String.isNotBlank(jobApp.Company_Name__c)) {
                companyData = getCompanyByName(jobApp.Company_Name__c);
            }
            
            // Update Job Application with enriched data
            if (companyData != null) {
                updateJobApplicationWithCompanyData(jobApp, companyData);
                return true;
            }
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error enriching Job Application: ' + e.getMessage());
        }
        
        return false;
    }
    
    /**
     * @description Bulk enrich multiple Job Applications
     * @param jobAppIds List of Job Application IDs
     * @return Map of Job App ID to success status
     */
    public Map<Id, Boolean> bulkEnrichJobApplications(List<Id> jobAppIds) {
        Map<Id, Boolean> results = new Map<Id, Boolean>();
        
        if (jobAppIds == null || jobAppIds.isEmpty()) {
            return results;
        }
        
        // Get Job Application records
        List<Job_Application__c> jobApps = [SELECT Id, Company_Name__c, Job_URL__c 
                                          FROM Job_Application__c 
                                          WHERE Id IN :jobAppIds];
        
        List<Job_Application__c> toUpdate = new List<Job_Application__c>();
        
        for (Job_Application__c jobApp : jobApps) {
            try {
                CompanyData companyData = null;
                
                // Try company name lookup
                if (String.isNotBlank(jobApp.Company_Name__c)) {
                    companyData = getCompanyByName(jobApp.Company_Name__c);
                }
                
                // Prepare update if data found
                if (companyData != null) {
                    Job_Application__c updatedJobApp = prepareJobAppUpdate(jobApp, companyData);
                    toUpdate.add(updatedJobApp);
                    results.put(jobApp.Id, true);
                } else {
                    results.put(jobApp.Id, false);
                }
                
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Error processing Job App ' + jobApp.Id + ': ' + e.getMessage());
                results.put(jobApp.Id, false);
            }
        }
        
        // Bulk update records
        if (!toUpdate.isEmpty()) {
            try {
                update toUpdate;
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Error updating Job Applications: ' + e.getMessage());
                // Mark all as failed
                for (Job_Application__c jobApp : toUpdate) {
                    results.put(jobApp.Id, false);
                }
            }
        }
        
        return results;
    }
    
    /**
     * @description Parse API response into CompanyData object
     * @param responseBody JSON response from API
     * @return Parsed CompanyData or null
     */
    private CompanyData parseCompanyResponse(String responseBody) {
        Map<String, Object> data = parseJsonResponse(responseBody);
        if (data == null) {
            return null;
        }
        
        try {
            CompanyData company = new CompanyData();
            
            // Basic company information
            company.companyName = (String) getNestedValue(data, 'company.name');
            company.industry = (String) getNestedValue(data, 'company.industry');
            company.size = (String) getNestedValue(data, 'company.size');
            company.website = (String) getNestedValue(data, 'company.website');
            company.description = (String) getNestedValue(data, 'company.description');
            company.headquarters = (String) getNestedValue(data, 'company.headquarters');
            company.founded = (String) getNestedValue(data, 'company.founded');
            
            // Numeric fields
            Object empCount = getNestedValue(data, 'company.employee_count');
            if (empCount != null) {
                company.employeeCount = Integer.valueOf(empCount);
            }
            
            Object revenue = getNestedValue(data, 'company.revenue');
            if (revenue != null) {
                company.revenue = Decimal.valueOf(String.valueOf(revenue));
            }
            
            // Technologies array
            List<Object> techList = (List<Object>) getNestedValue(data, 'company.technologies');
            if (techList != null) {
                for (Object tech : techList) {
                    company.technologies.add(String.valueOf(tech));
                }
            }
            
            // Company ratings
            Map<String, Object> ratingsData = (Map<String, Object>) getNestedValue(data, 'company.ratings');
            if (ratingsData != null) {
                company.rating = new CompanyRating();
                
                Object overall = ratingsData.get('overall');
                if (overall != null) {
                    company.rating.overallRating = Decimal.valueOf(String.valueOf(overall));
                }
                
                Object workLife = ratingsData.get('work_life_balance');
                if (workLife != null) {
                    company.rating.workLifeBalance = Decimal.valueOf(String.valueOf(workLife));
                }
                
                Object compensation = ratingsData.get('compensation');
                if (compensation != null) {
                    company.rating.compensation = Decimal.valueOf(String.valueOf(compensation));
                }
                
                Object culture = ratingsData.get('culture');
                if (culture != null) {
                    company.rating.culture = Decimal.valueOf(String.valueOf(culture));
                }
                
                Object reviewCount = ratingsData.get('review_count');
                if (reviewCount != null) {
                    company.rating.reviewCount = Integer.valueOf(reviewCount);
                }
            }
            
            return company;
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error parsing company response: ' + e.getMessage());
            return null;
        }
    }
    
    /**
     * @description Update Job Application record with company data
     * @param jobApp Job Application record to update
     * @param companyData Company data to apply
     */
    private void updateJobApplicationWithCompanyData(Job_Application__c jobApp, CompanyData companyData) {
        Job_Application__c updatedJobApp = prepareJobAppUpdate(jobApp, companyData);
        update updatedJobApp;
    }
    
    /**
     * @description Prepare Job Application update with company data
     * @param jobApp Original Job Application record
     * @param companyData Company data to apply
     * @return Job Application record ready for update
     */
    private Job_Application__c prepareJobAppUpdate(Job_Application__c jobApp, CompanyData companyData) {
        Job_Application__c updatedJobApp = new Job_Application__c(Id = jobApp.Id);
        
        // Note: These fields would need to be created on the Job_Application__c object
        // For demo purposes, we'll use Notes field to store the enriched data
        
        String enrichmentData = 'COMPANY DATA ENRICHMENT:\\n';
        enrichmentData += 'Industry: ' + (companyData.industry ?? 'N/A') + '\\n';
        enrichmentData += 'Size: ' + (companyData.size ?? 'N/A') + '\\n';
        enrichmentData += 'Employee Count: ' + (companyData.employeeCount != null ? String.valueOf(companyData.employeeCount) : 'N/A') + '\\n';
        enrichmentData += 'Website: ' + (companyData.website ?? 'N/A') + '\\n';
        enrichmentData += 'Headquarters: ' + (companyData.headquarters ?? 'N/A') + '\\n';
        enrichmentData += 'Founded: ' + (companyData.founded ?? 'N/A') + '\\n';
        
        if (companyData.rating != null) {
            enrichmentData += 'Overall Rating: ' + (companyData.rating.overallRating != null ? String.valueOf(companyData.rating.overallRating) : 'N/A') + '\\n';
            enrichmentData += 'Work-Life Balance: ' + (companyData.rating.workLifeBalance != null ? String.valueOf(companyData.rating.workLifeBalance) : 'N/A') + '\\n';
        }
        
        if (!companyData.technologies.isEmpty()) {
            enrichmentData += 'Technologies: ' + String.join(companyData.technologies, ', ') + '\\n';
        }
        
        enrichmentData += '\\nEnriched on: ' + DateTime.now().format() + '\\n';
        
        // For demo, append to Notes field
        updatedJobApp.Notes__c = (jobApp.Notes__c ?? '') + '\\n\\n' + enrichmentData;
        
        return updatedJobApp;
    }
}