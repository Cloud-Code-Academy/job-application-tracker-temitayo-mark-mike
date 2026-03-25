/**
 * @description Orchestrator service for enriching Job Applications with multiple external APIs
 * @author Learning Journey
 * @date 2025-01-08
 */
public class JobApplicationEnrichmentService {
    
    // Service instances
    private CompanyDataService companyService;
    private SalaryBenchmarkService salaryService;
    
    // Configuration
    private static final Integer MAX_CONCURRENT_CALLOUTS = 5;
    private static final Integer BATCH_SIZE = 10;
    
    /**
     * @description Enrichment result wrapper
     */
    public class EnrichmentResult {
        public Id jobApplicationId { get; set; }
        public Boolean success { get; set; }
        public String errorMessage { get; set; }
        public List<String> enrichmentTypes { get; set; }
        public Long processingTime { get; set; }
        
        public EnrichmentResult(Id jobAppId) {
            this.jobApplicationId = jobAppId;
            this.success = false;
            this.enrichmentTypes = new List<String>();
        }
    }
    
    /**
     * @description Batch enrichment summary
     */
    public class BatchEnrichmentSummary {
        public Integer totalRecords { get; set; }
        public Integer successfulEnrichments { get; set; }
        public Integer failedEnrichments { get; set; }
        public Long totalProcessingTime { get; set; }
        public List<EnrichmentResult> results { get; set; }
        
        public BatchEnrichmentSummary() {
            this.results = new List<EnrichmentResult>();
        }
    }
    
    /**
     * @description Constructor
     */
    public JobApplicationEnrichmentService() {
        this.companyService = new CompanyDataService();
        this.salaryService = new SalaryBenchmarkService();
    }
    
    /**
     * @description Enrich a single Job Application with all available data
     * @param jobAppId Job Application record ID
     * @return EnrichmentResult with details
     */
    public EnrichmentResult enrichJobApplication(Id jobAppId) {
        EnrichmentResult result = new EnrichmentResult(jobAppId);
        Long startTime = System.currentTimeMillis();
        
        try {
            // Get Job Application record
            Job_Application__c jobApp = getJobApplicationRecord(jobAppId);
            if (jobApp == null) {
                result.errorMessage = 'Job Application record not found';
                return result;
            }
            
            List<String> enrichmentErrors = new List<String>();
            
            // Enrich with company data
            try {
                Boolean companySuccess = companyService.enrichJobApplication(jobAppId);
                if (companySuccess) {
                    result.enrichmentTypes.add('Company Data');
                } else {
                    enrichmentErrors.add('Company data enrichment failed');
                }
            } catch (Exception e) {
                enrichmentErrors.add('Company data error: ' + e.getMessage());
            }
            
            // Enrich with salary benchmark data
            try {
                Boolean salarySuccess = salaryService.enrichJobApplicationWithSalary(jobAppId);
                if (salarySuccess) {
                    result.enrichmentTypes.add('Salary Benchmark');
                } else {
                    enrichmentErrors.add('Salary benchmark enrichment failed');
                }
            } catch (Exception e) {
                enrichmentErrors.add('Salary benchmark error: ' + e.getMessage());
            }
            
            // Determine overall success
            result.success = !result.enrichmentTypes.isEmpty();
            
            if (!enrichmentErrors.isEmpty()) {
                result.errorMessage = String.join(enrichmentErrors, '; ');
            }
            
        } catch (Exception e) {
            result.errorMessage = 'Enrichment process failed: ' + e.getMessage();
            System.debug(LoggingLevel.ERROR, 'Enrichment error for Job App ' + jobAppId + ': ' + e.getMessage());
        }
        
        result.processingTime = System.currentTimeMillis() - startTime;
        return result;
    }
    
    /**
     * @description Enrich multiple Job Applications in batch
     * @param jobAppIds List of Job Application IDs
     * @return BatchEnrichmentSummary with results
     */
    public BatchEnrichmentSummary batchEnrichJobApplications(List<Id> jobAppIds) {
        BatchEnrichmentSummary summary = new BatchEnrichmentSummary();
        Long startTime = System.currentTimeMillis();
        
        if (jobAppIds == null || jobAppIds.isEmpty()) {
            summary.totalRecords = 0;
            return summary;
        }
        
        summary.totalRecords = jobAppIds.size();
        
        // Process in batches to manage callout limits
        List<List<Id>> batches = createBatches(jobAppIds, BATCH_SIZE);
        
        for (List<Id> batch : batches) {
            processBatch(batch, summary);
        }
        
        // Calculate summary statistics
        summary.successfulEnrichments = 0;
        summary.failedEnrichments = 0;
        
        for (EnrichmentResult result : summary.results) {
            if (result.success) {
                summary.successfulEnrichments++;
            } else {
                summary.failedEnrichments++;
            }
        }
        
        summary.totalProcessingTime = System.currentTimeMillis() - startTime;
        
        return summary;
    }
    
    /**
     * @description Enrich Job Applications that were recently created or updated
     * @param hours Number of hours to look back
     * @return BatchEnrichmentSummary with results
     */
    public BatchEnrichmentSummary enrichRecentJobApplications(Integer hours) {
        if (hours == null || hours <= 0) {
            hours = 24; // Default to last 24 hours
        }
        
        DateTime cutoffTime = DateTime.now().addHours(-hours);
        
        // Query recent Job Applications that need enrichment
        List<Job_Application__c> recentJobApps = [
            SELECT Id, Company_Name__c, Position_Title__c, LastModifiedDate
            FROM Job_Application__c 
            WHERE LastModifiedDate >= :cutoffTime
            AND (Company_Name__c != null OR Position_Title__c != null)
            ORDER BY LastModifiedDate DESC
            LIMIT 100
        ];
        
        List<Id> jobAppIds = new List<Id>();
        for (Job_Application__c jobApp : recentJobApps) {
            jobAppIds.add(jobApp.Id);
        }
        
        return batchEnrichJobApplications(jobAppIds);
    }
    
    /**
     * @description Get enrichment statistics for reporting
     * @param days Number of days to analyze
     * @return Map with enrichment statistics
     */
    public Map<String, Object> getEnrichmentStatistics(Integer days) {
        Map<String, Object> stats = new Map<String, Object>();
        
        if (days == null || days <= 0) {
            days = 30; // Default to last 30 days
        }
        
        DateTime cutoffTime = DateTime.now().addDays(-days);
        
        // Query Job Applications with enrichment data
        List<Job_Application__c> enrichedApps = [
            SELECT Id, Notes__c, LastModifiedDate
            FROM Job_Application__c 
            WHERE LastModifiedDate >= :cutoffTime
            AND Notes__c LIKE '%COMPANY DATA ENRICHMENT%'
        ];
        
        List<Job_Application__c> salaryEnrichedApps = [
            SELECT Id, Notes__c, LastModifiedDate
            FROM Job_Application__c 
            WHERE LastModifiedDate >= :cutoffTime
            AND Notes__c LIKE '%SALARY BENCHMARK ANALYSIS%'
        ];
        
        stats.put('totalJobApplications', [SELECT COUNT() FROM Job_Application__c WHERE LastModifiedDate >= :cutoffTime][0].get('expr0'));
        stats.put('companyDataEnrichments', enrichedApps.size());
        stats.put('salaryBenchmarkEnrichments', salaryEnrichedApps.size());
        stats.put('enrichmentRate', calculateEnrichmentRate(enrichedApps.size(), (Integer) stats.get('totalJobApplications')));
        stats.put('analysisDate', DateTime.now());
        stats.put('analysisPeriodDays', days);
        
        return stats;
    }
    
    /**
     * @description Process a batch of Job Applications
     * @param batch List of Job Application IDs to process
     * @param summary Summary object to update
     */
    private void processBatch(List<Id> batch, BatchEnrichmentSummary summary) {
        // Use bulk operations for better performance
        Map<Id, Boolean> companyResults = companyService.bulkEnrichJobApplications(batch);
        Map<Id, Boolean> salaryResults = new Map<Id, Boolean>();
        
        // Process salary enrichments individually due to API limitations
        for (Id jobAppId : batch) {
            try {
                Boolean salarySuccess = salaryService.enrichJobApplicationWithSalary(jobAppId);
                salaryResults.put(jobAppId, salarySuccess);
            } catch (Exception e) {
                salaryResults.put(jobAppId, false);
                System.debug(LoggingLevel.ERROR, 'Salary enrichment error for ' + jobAppId + ': ' + e.getMessage());
            }
        }
        
        // Create results for each Job Application
        for (Id jobAppId : batch) {
            EnrichmentResult result = new EnrichmentResult(jobAppId);
            
            Boolean companySuccess = companyResults.get(jobAppId) == true;
            Boolean salarySuccess = salaryResults.get(jobAppId) == true;
            
            if (companySuccess) {
                result.enrichmentTypes.add('Company Data');
            }
            
            if (salarySuccess) {
                result.enrichmentTypes.add('Salary Benchmark');
            }
            
            result.success = companySuccess || salarySuccess;
            
            if (!result.success) {
                result.errorMessage = 'All enrichment attempts failed';
            }
            
            summary.results.add(result);
        }
    }
    
    /**
     * @description Create batches from list of IDs
     * @param ids List of IDs to batch
     * @param batchSize Size of each batch
     * @return List of batches
     */
    private List<List<Id>> createBatches(List<Id> ids, Integer batchSize) {
        List<List<Id>> batches = new List<List<Id>>();
        List<Id> currentBatch = new List<Id>();
        
        for (Id id : ids) {
            currentBatch.add(id);
            
            if (currentBatch.size() >= batchSize) {
                batches.add(currentBatch);
                currentBatch = new List<Id>();
            }
        }
        
        // Add remaining items
        if (!currentBatch.isEmpty()) {
            batches.add(currentBatch);
        }
        
        return batches;
    }
    
    /**
     * @description Get Job Application record with required fields
     * @param jobAppId Job Application ID
     * @return Job Application record or null
     */
    private Job_Application__c getJobApplicationRecord(Id jobAppId) {
        try {
            return [SELECT Id, Company_Name__c, Position_Title__c, Location__c, Salary__c, Job_URL__c, Notes__c
                   FROM Job_Application__c 
                   WHERE Id = :jobAppId LIMIT 1];
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error querying Job Application: ' + e.getMessage());
            return null;
        }
    }
    
    /**
     * @description Calculate enrichment rate percentage
     * @param enrichedCount Number of enriched records
     * @param totalCount Total number of records
     * @return Enrichment rate as percentage
     */
    private Decimal calculateEnrichmentRate(Integer enrichedCount, Integer totalCount) {
        if (totalCount == 0) {
            return 0;
        }
        
        return ((Decimal) enrichedCount / totalCount * 100).setScale(1);
    }
    
    /**
     * @description Schedule automatic enrichment for new Job Applications
     * This method would be called from a trigger or scheduled job
     * @param jobAppIds List of Job Application IDs to enrich
     */
    public static void scheduleEnrichment(List<Id> jobAppIds) {
        if (jobAppIds == null || jobAppIds.isEmpty()) {
            return;
        }
        
        // In a real implementation, you might use:
        // 1. Queueable Apex for immediate processing
        // 2. Batch Apex for large volumes
        // 3. Platform Events for decoupled processing
        
        // For demo, we'll use a simple queueable
        System.enqueueJob(new EnrichmentQueueable(jobAppIds));
    }
    
    /**
     * @description Queueable class for asynchronous enrichment
     */
    public class EnrichmentQueueable implements Queueable, Database.AllowsCallouts {
        private List<Id> jobAppIds;
        
        public EnrichmentQueueable(List<Id> jobAppIds) {
            this.jobAppIds = jobAppIds;
        }
        
        public void execute(QueueableContext context) {
            JobApplicationEnrichmentService service = new JobApplicationEnrichmentService();
            BatchEnrichmentSummary summary = service.batchEnrichJobApplications(jobAppIds);
            
            // Log results
            System.debug('Enrichment completed: ' + summary.successfulEnrichments + ' successful, ' + 
                        summary.failedEnrichments + ' failed out of ' + summary.totalRecords + ' total');
        }
    }
}