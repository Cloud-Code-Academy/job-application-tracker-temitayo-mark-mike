/**
 * @description Batch job for analyzing salary market data and updating job applications
 * with market insights and recommendations
 * @author Temitayo Oluwalade
 * @date 2024
 */
public class SalaryMarketAnalysisBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    
    // Batch configuration
    private static final Integer BATCH_SIZE = 200;
    private static final String JOB_NAME = 'Salary Market Analysis';
    
    // Market data simulation (in real implementation, this would come from external APIs)
    private static final Map<String, Map<String, Decimal>> MARKET_DATA = new Map<String, Map<String, Decimal>>{
        'Software Engineer' => new Map<String, Decimal>{
            'min' => 80000, 'max' => 150000, 'median' => 115000, 'percentile_75' => 130000
        },
        'Product Manager' => new Map<String, Decimal>{
            'min' => 90000, 'max' => 180000, 'median' => 135000, 'percentile_75' => 155000
        },
        'Data Scientist' => new Map<String, Decimal>{
            'min' => 85000, 'max' => 160000, 'median' => 120000, 'percentile_75' => 140000
        },
        'Business Analyst' => new Map<String, Decimal>{
            'min' => 65000, 'max' => 120000, 'median' => 85000, 'percentile_75' => 100000
        },
        'DevOps Engineer' => new Map<String, Decimal>{
            'min' => 90000, 'max' => 170000, 'median' => 130000, 'percentile_75' => 150000
        }
    };
    
    // Batch state tracking
    private Integer recordsProcessed = 0;
    private Integer recordsUpdated = 0;
    private List<String> errors = new List<String>();
    
    /**
     * @description Start method - defines the scope of records to process
     * @param bc BatchableContext
     * @return Database.QueryLocator
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        System.debug('Starting Salary Market Analysis Batch Job');
        
        // Query job applications that need market analysis
        String query = 'SELECT Id, Name, Position_Title__c, Salary__c, Company_Name__c, ' +
                      'Market_Salary_Min__c, Market_Salary_Max__c, Market_Salary_Median__c, ' +
                      'Salary_Competitiveness__c, Market_Analysis_Date__c, Status__c ' +
                      'FROM Job_Application__c ' +
                      'WHERE Status__c IN (\'Applied\', \'Interviewing\', \'Negotiating\') ' +
                      'AND (Market_Analysis_Date__c = null OR Market_Analysis_Date__c < LAST_N_DAYS:30)';
        
        return Database.getQueryLocator(query);
    }
    
    /**
     * @description Execute method - processes each batch of records
     * @param bc BatchableContext
     * @param scope List of Job Application records to process
     */
    public void execute(Database.BatchableContext bc, List<Job_Application__c> scope) {
        System.debug('Processing batch of ' + scope.size() + ' job applications');
        
        List<Job_Application__c> applicationsToUpdate = new List<Job_Application__c>();
        
        for (Job_Application__c app : scope) {
            try {
                recordsProcessed++;
                
                // Analyze market data for this position
                MarketAnalysisResult analysis = analyzeMarketData(app);
                
                if (analysis != null) {
                    // Update the job application with market insights
                    app.Market_Salary_Min__c = analysis.minSalary;
                    app.Market_Salary_Max__c = analysis.maxSalary;
                    app.Market_Salary_Median__c = analysis.medianSalary;
                    app.Salary_Competitiveness__c = analysis.competitiveness;
                    app.Market_Analysis_Date__c = Date.today();
                    
                    applicationsToUpdate.add(app);
                    recordsUpdated++;
                }
                
            } catch (Exception e) {
                String errorMsg = 'Error processing application ' + app.Name + ': ' + e.getMessage();
                errors.add(errorMsg);
                System.debug(LoggingLevel.ERROR, errorMsg);
            }
        }
        
        // Update records in bulk
        if (!applicationsToUpdate.isEmpty()) {
            try {
                update applicationsToUpdate;
                System.debug('Successfully updated ' + applicationsToUpdate.size() + ' job applications');
            } catch (DmlException e) {
                String errorMsg = 'Bulk update failed: ' + e.getMessage();
                errors.add(errorMsg);
                System.debug(LoggingLevel.ERROR, errorMsg);
            }
        }
    }
    
    /**
     * @description Finish method - performs cleanup and sends summary
     * @param bc BatchableContext
     */
    public void finish(Database.BatchableContext bc) {
        System.debug('Salary Market Analysis Batch Job completed');
        
        // Get job details
        AsyncApexJob job = [
            SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedDate, CompletedDate
            FROM AsyncApexJob 
            WHERE Id = :bc.getJobId()
        ];
        
        // Create summary
        String summary = buildJobSummary(job);
        System.debug(summary);
        
        // Send notification email (in real implementation)
        // sendCompletionNotification(summary);
        
        // Schedule next run if needed
        scheduleNextRun();
    }
    
    /**
     * @description Analyzes market data for a specific job application
     * @param app Job Application record
     * @return MarketAnalysisResult with market insights
     */
    private MarketAnalysisResult analyzeMarketData(Job_Application__c app) {
        if (String.isBlank(app.Position_Title__c)) {
            return null;
        }
        
        // Find matching market data (simplified matching logic)
        Map<String, Decimal> marketData = findMarketData(app.Position_Title__c);
        
        if (marketData == null) {
            return null;
        }
        
        // Calculate competitiveness
        String competitiveness = calculateCompetitiveness(app.Salary__c, marketData);
        
        return new MarketAnalysisResult(
            marketData.get('min'),
            marketData.get('max'),
            marketData.get('median'),
            competitiveness
        );
    }
    
    /**
     * @description Finds market data for a given position title
     * @param positionTitle The position title to search for
     * @return Map of market data or null if not found
     */
    private Map<String, Decimal> findMarketData(String positionTitle) {
        String normalizedTitle = positionTitle.toLowerCase();
        
        // Simple keyword matching (in real implementation, use more sophisticated matching)
        for (String marketTitle : MARKET_DATA.keySet()) {
            if (normalizedTitle.contains(marketTitle.toLowerCase()) || 
                marketTitle.toLowerCase().contains(normalizedTitle)) {
                return MARKET_DATA.get(marketTitle);
            }
        }
        
        return null;
    }
    
    /**
     * @description Calculates salary competitiveness based on market data
     * @param salary The offered salary
     * @param marketData Market salary data
     * @return Competitiveness rating
     */
    private String calculateCompetitiveness(Decimal salary, Map<String, Decimal> marketData) {
        if (salary == null) {
            return 'Unknown';
        }
        
        Decimal median = marketData.get('median');
        Decimal percentile75 = marketData.get('percentile_75');
        Decimal min = marketData.get('min');
        
        if (salary >= percentile75) {
            return 'Excellent';
        } else if (salary >= median) {
            return 'Good';
        } else if (salary >= min) {
            return 'Fair';
        } else {
            return 'Below Market';
        }
    }
    
    /**
     * @description Builds a summary of the batch job execution
     * @param job AsyncApexJob record
     * @return Formatted summary string
     */
    private String buildJobSummary(AsyncApexJob job) {
        return String.format(
            '=== SALARY MARKET ANALYSIS BATCH SUMMARY ===\n' +
            'Job ID: {0}\n' +
            'Status: {1}\n' +
            'Started: {2}\n' +
            'Completed: {3}\n' +
            'Records Processed: {4}\n' +
            'Records Updated: {5}\n' +
            'Errors: {6}\n' +
            'Error Details: {7}\n' +
            '============================================',
            new List<Object>{
                job.Id,
                job.Status,
                job.CreatedDate,
                job.CompletedDate,
                recordsProcessed,
                recordsUpdated,
                errors.size(),
                String.join(errors, '\n')
            }
        );
    }
    
    /**
     * @description Schedules the next run of this batch job
     */
    private void scheduleNextRun() {
        // Schedule to run weekly (in real implementation, make this configurable)
        String cronExpression = '0 0 6 ? * MON'; // Every Monday at 6 AM
        
        try {
            System.schedule(
                JOB_NAME + ' - ' + Datetime.now().format('yyyy-MM-dd HH:mm:ss'),
                cronExpression,
                new SalaryMarketAnalysisScheduler()
            );
            System.debug('Next batch job scheduled successfully');
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Failed to schedule next batch job: ' + e.getMessage());
        }
    }
    
    /**
     * @description Static method to execute the batch job
     * @param batchSize Optional batch size (default: 200)
     * @return Database.BatchableContext job ID
     */
    public static Id executeBatch(Integer batchSize) {
        if (batchSize == null) {
            batchSize = BATCH_SIZE;
        }
        
        SalaryMarketAnalysisBatch batch = new SalaryMarketAnalysisBatch();
        return Database.executeBatch(batch, batchSize);
    }
    
    /**
     * @description Static method to execute the batch job with default size
     * @return Database.BatchableContext job ID
     */
    public static Id executeBatch() {
        return executeBatch(BATCH_SIZE);
    }
    
    /**
     * @description Inner class to hold market analysis results
     */
    private class MarketAnalysisResult {
        public Decimal minSalary;
        public Decimal maxSalary;
        public Decimal medianSalary;
        public String competitiveness;
        
        public MarketAnalysisResult(Decimal min, Decimal max, Decimal median, String comp) {
            this.minSalary = min;
            this.maxSalary = max;
            this.medianSalary = median;
            this.competitiveness = comp;
        }
    }
}
