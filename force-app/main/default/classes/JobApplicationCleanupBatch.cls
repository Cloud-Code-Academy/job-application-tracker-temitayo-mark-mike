/**
 * @description Batch class for cleaning up and maintaining Job Application records
 * @author Learning Journey
 * @date 2025-01-08
 */
public inherited sharing class JobApplicationCleanupBatch implements Database.Batchable<SObject>, Database.Stateful {
    
    // Batch configuration
    public enum CleanupType { REMOVE_DUPLICATES, ARCHIVE_OLD, UPDATE_STALE, FULL_CLEANUP }
    
    private CleanupType cleanupType;
    private Integer daysOld;
    private Boolean sendReport;
    
    // Stateful properties to track progress
    private Integer totalRecordsProcessed = 0;
    private Integer recordsUpdated = 0;
    private Integer recordsDeleted = 0;
    private Integer duplicatesFound = 0;
    private List<String> errors = new List<String>();
    private DateTime batchStartTime;
    
    /**
     * @description Constructor with cleanup type
     * @param cleanupType Type of cleanup to perform
     * @param daysOld Number of days old for archive operations
     * @param sendReport Whether to send completion report
     */
    public JobApplicationCleanupBatch(CleanupType cleanupType, Integer daysOld, Boolean sendReport) {
        this.cleanupType = cleanupType;
        this.daysOld = daysOld != null ? daysOld : 365; // Default to 1 year
        this.sendReport = sendReport != null ? sendReport : true;
        this.batchStartTime = DateTime.now();
    }
    
    /**
     * @description Default constructor for full cleanup
     */
    public JobApplicationCleanupBatch() {
        this(CleanupType.FULL_CLEANUP, 365, true);
    }
    
    /**
     * @description Start method - defines the scope of records to process
     * @param context Batch context
     * @return Database.QueryLocator for the records to process
     */
    public Database.QueryLocator start(Database.BatchableContext context) {
        System.debug('JobApplicationCleanupBatch started with type: ' + cleanupType);
        
        String query = buildQuery();
        System.debug('Batch query: ' + query);
        
        return Database.getQueryLocator(query);
    }
    
    /**
     * @description Execute method - processes each batch of records
     * @param context Batch context
     * @param scope List of records to process in this batch
     */
    public void execute(Database.BatchableContext context, List<Job_Application__c> scope) {
        System.debug('Processing batch of ' + scope.size() + ' records');
        
        try {
            switch on cleanupType {
                when REMOVE_DUPLICATES {
                    processDuplicates(scope);
                }
                when ARCHIVE_OLD {
                    processArchiving(scope);
                }
                when UPDATE_STALE {
                    processStaleRecords(scope);
                }
                when FULL_CLEANUP {
                    processFullCleanup(scope);
                }
            }
            
            totalRecordsProcessed += scope.size();
            
        } catch (Exception e) {
            String errorMsg = 'Error processing batch: ' + e.getMessage();
            errors.add(errorMsg);
            System.debug(LoggingLevel.ERROR, errorMsg);
            System.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());
        }
    }
    
    /**
     * @description Finish method - called when all batches are complete
     * @param context Batch context
     */
    public void finish(Database.BatchableContext context) {
        DateTime batchEndTime = DateTime.now();
        Long processingTime = batchEndTime.getTime() - batchStartTime.getTime();
        
        System.debug('JobApplicationCleanupBatch completed');
        System.debug('Total records processed: ' + totalRecordsProcessed);
        System.debug('Records updated: ' + recordsUpdated);
        System.debug('Records deleted: ' + recordsDeleted);
        System.debug('Duplicates found: ' + duplicatesFound);
        System.debug('Processing time: ' + processingTime + 'ms');
        System.debug('Errors encountered: ' + errors.size());
        
        if (sendReport) {
            sendCompletionReport(context, processingTime);
        }
        
        // Chain next cleanup type if doing full cleanup
        if (cleanupType == CleanupType.FULL_CLEANUP) {
            scheduleNextCleanupPhase();
        }
    }
    
    /**
     * @description Build SOQL query based on cleanup type
     * @return SOQL query string
     */
    private String buildQuery() {
        String baseQuery = 'SELECT Id, Company_Name__c, Position_Title__c, Status__c, ' +
                          'Application_Date__c, LastModifiedDate, CreatedDate, Notes__c ';
        String fromClause = 'FROM Job_Application__c ';
        String whereClause = '';
        
        switch on cleanupType {
            when REMOVE_DUPLICATES {
                // Get all records for duplicate detection
                whereClause = 'WHERE Company_Name__c != null AND Position_Title__c != null ';
            }
            when ARCHIVE_OLD {
                // Get old records for archiving
                Date cutoffDate = Date.today().addDays(-daysOld);
                whereClause = 'WHERE Application_Date__c < ' + cutoffDate.format() + ' ';
            }
            when UPDATE_STALE {
                // Get records that haven't been updated recently
                DateTime cutoffDateTime = DateTime.now().addDays(-30);
                whereClause = 'WHERE LastModifiedDate < ' + cutoffDateTime.format() + ' ';
            }
            when FULL_CLEANUP {
                // Get all records for comprehensive cleanup
                whereClause = 'WHERE Id != null ';
            }
        }
        
        String orderClause = 'ORDER BY CreatedDate ASC';
        
        return baseQuery + fromClause + whereClause + orderClause;
    }
    
    /**
     * @description Process duplicate records
     * @param scope Records to check for duplicates
     */
    private void processDuplicates(List<Job_Application__c> scope) {
        Map<String, List<Job_Application__c>> duplicateMap = new Map<String, List<Job_Application__c>>();
        
        // Group records by company + position combination
        for (Job_Application__c jobApp : scope) {
            String key = (jobApp.Company_Name__c + '|' + jobApp.Position_Title__c).toLowerCase();
            
            if (!duplicateMap.containsKey(key)) {
                duplicateMap.put(key, new List<Job_Application__c>());
            }
            duplicateMap.get(key).add(jobApp);
        }
        
        List<Job_Application__c> recordsToDelete = new List<Job_Application__c>();
        
        // Find duplicates (keep the oldest record)
        for (String key : duplicateMap.keySet()) {
            List<Job_Application__c> duplicates = duplicateMap.get(key);
            
            if (duplicates.size() > 1) {
                duplicatesFound += duplicates.size() - 1;
                
                // Sort by creation date (oldest first)
                duplicates.sort(new JobApplicationDateComparator());
                
                // Mark all but the first (oldest) for deletion
                for (Integer i = 1; i < duplicates.size(); i++) {
                    recordsToDelete.add(duplicates[i]);
                }
            }
        }
        
        // Delete duplicate records
        if (!recordsToDelete.isEmpty()) {
            try {
                delete recordsToDelete;
                recordsDeleted += recordsToDelete.size();
                System.debug('Deleted ' + recordsToDelete.size() + ' duplicate records');
            } catch (DmlException e) {
                errors.add('Error deleting duplicates: ' + e.getMessage());
            }
        }
    }
    
    /**
     * @description Process old records for archiving
     * @param scope Records to archive
     */
    private void processArchiving(List<Job_Application__c> scope) {
        List<Job_Application__c> recordsToUpdate = new List<Job_Application__c>();
        
        for (Job_Application__c jobApp : scope) {
            // Mark as archived and add archive note
            Job_Application__c updatedJobApp = new Job_Application__c(Id = jobApp.Id);
            updatedJobApp.Status__c = 'Archived';
            
            String archiveNote = '\\n\\nARCHIVED: ' + DateTime.now().format() + 
                               ' - Record archived due to age (' + daysOld + ' days)';
            updatedJobApp.Notes__c = (jobApp.Notes__c ?? '') + archiveNote;
            
            recordsToUpdate.add(updatedJobApp);
        }
        
        // Update records
        if (!recordsToUpdate.isEmpty()) {
            try {
                update recordsToUpdate;
                recordsUpdated += recordsToUpdate.size();
                System.debug('Archived ' + recordsToUpdate.size() + ' old records');
            } catch (DmlException e) {
                errors.add('Error archiving records: ' + e.getMessage());
            }
        }
    }
    
    /**
     * @description Process stale records that need updates
     * @param scope Records to update
     */
    private void processStaleRecords(List<Job_Application__c> scope) {
        List<Job_Application__c> recordsToUpdate = new List<Job_Application__c>();
        
        for (Job_Application__c jobApp : scope) {
            Job_Application__c updatedJobApp = new Job_Application__c(Id = jobApp.Id);
            Boolean needsUpdate = false;
            
            // Clean up status if it's inconsistent
            if (String.isBlank(jobApp.Status__c)) {
                updatedJobApp.Status__c = 'Applied';
                needsUpdate = true;
            }
            
            // Add maintenance note
            if (needsUpdate) {
                String maintenanceNote = '\\n\\nMAINTENANCE: ' + DateTime.now().format() + 
                                       ' - Record updated during batch maintenance';
                updatedJobApp.Notes__c = (jobApp.Notes__c ?? '') + maintenanceNote;
                
                recordsToUpdate.add(updatedJobApp);
            }
        }
        
        // Update records
        if (!recordsToUpdate.isEmpty()) {
            try {
                update recordsToUpdate;
                recordsUpdated += recordsToUpdate.size();
                System.debug('Updated ' + recordsToUpdate.size() + ' stale records');
            } catch (DmlException e) {
                errors.add('Error updating stale records: ' + e.getMessage());
            }
        }
    }
    
    /**
     * @description Process full cleanup (combination of all cleanup types)
     * @param scope Records to process
     */
    private void processFullCleanup(List<Job_Application__c> scope) {
        // First remove duplicates
        processDuplicates(scope);
        
        // Then update stale records
        processStaleRecords(scope);
        
        // Note: Archiving is handled separately to avoid conflicts
    }
    
    /**
     * @description Send completion report via email or platform event
     * @param context Batch context
     * @param processingTime Total processing time in milliseconds
     */
    private void sendCompletionReport(Database.BatchableContext context, Long processingTime) {
        try {
            // Create completion report
            String reportSubject = 'Job Application Cleanup Batch Completed - ' + cleanupType;
            String reportBody = buildReportBody(context, processingTime);
            
            // In a real implementation, you would send an email or create a platform event
            System.debug('=== BATCH COMPLETION REPORT ===');
            System.debug('Subject: ' + reportSubject);
            System.debug('Body: ' + reportBody);
            
            // Create a custom object record to track batch execution
            // This would be a custom object like Batch_Execution_Log__c
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error sending completion report: ' + e.getMessage());
        }
    }
    
    /**
     * @description Build detailed report body
     * @param context Batch context
     * @param processingTime Processing time in milliseconds
     * @return Formatted report body
     */
    private String buildReportBody(Database.BatchableContext context, Long processingTime) {
        String report = 'Job Application Cleanup Batch Results\\n\\n';
        report += 'Batch Job ID: ' + context.getJobId() + '\\n';
        report += 'Cleanup Type: ' + cleanupType + '\\n';
        report += 'Start Time: ' + batchStartTime.format() + '\\n';
        report += 'End Time: ' + DateTime.now().format() + '\\n';
        report += 'Processing Time: ' + (processingTime / 1000) + ' seconds\\n\\n';
        
        report += 'RESULTS:\\n';
        report += '- Total Records Processed: ' + totalRecordsProcessed + '\\n';
        report += '- Records Updated: ' + recordsUpdated + '\\n';
        report += '- Records Deleted: ' + recordsDeleted + '\\n';
        report += '- Duplicates Found: ' + duplicatesFound + '\\n';
        report += '- Errors Encountered: ' + errors.size() + '\\n\\n';
        
        if (!errors.isEmpty()) {
            report += 'ERRORS:\\n';
            for (String error : errors) {
                report += '- ' + error + '\\n';
            }
        }
        
        return report;
    }
    
    /**
     * @description Schedule next phase of cleanup if doing full cleanup
     */
    private void scheduleNextCleanupPhase() {
        // In a full cleanup, we might want to run archiving as a separate batch
        // to avoid conflicts with the duplicate removal and updates
        
        System.debug('Scheduling archiving phase of full cleanup...');
        
        // Schedule archiving batch to run in 5 minutes
        DateTime scheduleTime = DateTime.now().addMinutes(5);
        String cronExpression = scheduleTime.format('s m H d M ? yyyy');
        
        try {
            JobApplicationCleanupScheduler scheduler = new JobApplicationCleanupScheduler(
                CleanupType.ARCHIVE_OLD, daysOld, true
            );
            System.schedule('Job App Cleanup - Archive Phase', cronExpression, scheduler);
            
            System.debug('Archiving phase scheduled for: ' + scheduleTime.format());
        } catch (Exception e) {
            errors.add('Error scheduling next cleanup phase: ' + e.getMessage());
        }
    }
    
    /**
     * @description Comparator class for sorting Job Applications by creation date
     */
    public class JobApplicationDateComparator implements Comparator<Job_Application__c> {
        public Integer compare(Job_Application__c a, Job_Application__c b) {
            if (a.CreatedDate == b.CreatedDate) return 0;
            if (a.CreatedDate < b.CreatedDate) return -1;
            return 1;
        }
    }
}