/**
 * @description Service for getting salary benchmark data from external APIs
 * @author Learning Journey
 * @date 2025-01-08
 */
public inherited sharing class SalaryBenchmarkService extends BaseApiService {
    
    // API configuration — uses Named Credential for secure auth (no hard-coded keys)
    // Setup: Setup > Named Credentials > "Salary_Benchmark_API"
    private static final String NAMED_CREDENTIAL = 'callout:Salary_Benchmark_API';
    
    /**
     * @description Salary benchmark data structure
     */
    public class SalaryBenchmark {
        public String jobTitle { get; set; }
        public String location { get; set; }
        public String experienceLevel { get; set; }
        public Decimal minSalary { get; set; }
        public Decimal maxSalary { get; set; }
        public Decimal medianSalary { get; set; }
        public Decimal averageSalary { get; set; }
        public String currencyCode { get; set; }
        public Integer sampleSize { get; set; }
        public Date lastUpdated { get; set; }
        public List<SalaryPercentile> percentiles { get; set; }
        public List<SalaryByExperience> experienceBreakdown { get; set; }
        
        public SalaryBenchmark() {
            this.currencyCode = 'USD';
            this.percentiles = new List<SalaryPercentile>();
            this.experienceBreakdown = new List<SalaryByExperience>();
        }
    }
    
    /**
     * @description Salary percentile data
     */
    public class SalaryPercentile {
        public Integer percentile { get; set; }
        public Decimal salary { get; set; }
    }
    
    /**
     * @description Salary breakdown by experience level
     */
    public class SalaryByExperience {
        public String experienceLevel { get; set; }
        public Decimal averageSalary { get; set; }
        public Decimal minSalary { get; set; }
        public Decimal maxSalary { get; set; }
        public Integer sampleSize { get; set; }
    }
    
    /**
     * @description Get salary benchmark for a job title and location
     * @param jobTitle Job title to benchmark
     * @param location Location (city, state, or country)
     * @param experienceLevel Experience level (entry, mid, senior, executive)
     * @return SalaryBenchmark data or null if not found
     */
    public SalaryBenchmark getSalaryBenchmark(String jobTitle, String location, String experienceLevel) {
        if (String.isBlank(jobTitle)) {
            return null;
        }
        
        try {
            // Build API request — Named Credential handles auth headers automatically
            ApiRequest request = new ApiRequest();
            request.endpoint = NAMED_CREDENTIAL + '/benchmark';
            request.method = HTTP_GET;
            
            // Add parameters
            request.parameters.put('title', jobTitle);
            if (String.isNotBlank(location)) {
                request.parameters.put('location', location);
            }
            if (String.isNotBlank(experienceLevel)) {
                request.parameters.put('experience', experienceLevel);
            }
            request.parameters.put('include', 'percentiles,experience_breakdown');
            request.parameters.put('currency', 'USD');
            
            // Make API call
            ApiResponse response = makeCallout(request);
            
            if (response.isSuccess) {
                return parseSalaryResponse(response.body);
            } else {
                System.debug(LoggingLevel.ERROR, 'Salary API call failed: ' + response.errorMessage);
                return null;
            }
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error getting salary benchmark: ' + e.getMessage());
            return null;
        }
    }
    
    /**
     * @description Enrich Job Application with salary benchmark data
     * @param jobAppId Job Application record ID
     * @return True if enrichment was successful
     */
    public Boolean enrichJobApplicationWithSalary(Id jobAppId) {
        if (jobAppId == null) {
            return false;
        }
        
        try {
            // Get Job Application record
            Job_Application__c jobApp = [SELECT Id, Position_Title__c, Location__c, Salary__c 
                                       FROM Job_Application__c 
                                       WHERE Id = :jobAppId LIMIT 1];
            
            if (String.isBlank(jobApp.Position_Title__c)) {
                System.debug('No position title found for Job Application: ' + jobAppId);
                return false;
            }
            
            // Determine experience level based on salary or other factors
            String experienceLevel = determineExperienceLevel(jobApp.Salary__c);
            
            // Get salary benchmark
            SalaryBenchmark benchmark = getSalaryBenchmark(
                jobApp.Position_Title__c, 
                jobApp.Location__c, 
                experienceLevel
            );
            
            if (benchmark != null) {
                updateJobApplicationWithSalaryData(jobApp, benchmark);
                return true;
            }
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error enriching Job Application with salary data: ' + e.getMessage());
        }
        
        return false;
    }
    
    /**
     * @description Compare offered salary against market benchmark
     * @param offeredSalary Salary offered by company
     * @param benchmark Market benchmark data
     * @return Comparison analysis
     */
    public Map<String, Object> compareSalaryToBenchmark(Decimal offeredSalary, SalaryBenchmark benchmark) {
        Map<String, Object> comparison = new Map<String, Object>();
        
        if (offeredSalary == null || benchmark == null || benchmark.medianSalary == null) {
            comparison.put('isValid', false);
            comparison.put('message', 'Insufficient data for comparison');
            return comparison;
        }
        
        comparison.put('isValid', true);
        comparison.put('offeredSalary', offeredSalary);
        comparison.put('marketMedian', benchmark.medianSalary);
        comparison.put('marketMin', benchmark.minSalary);
        comparison.put('marketMax', benchmark.maxSalary);
        
        // Calculate percentage difference from median
        Decimal percentageDiff = ((offeredSalary - benchmark.medianSalary) / benchmark.medianSalary) * 100;
        comparison.put('percentageDifferenceFromMedian', percentageDiff.setScale(1));
        
        // Determine competitiveness
        String competitiveness;
        if (offeredSalary >= benchmark.maxSalary) {
            competitiveness = 'Excellent (Top of Market)';
        } else if (offeredSalary >= benchmark.medianSalary * 1.1) {
            competitiveness = 'Above Market';
        } else if (offeredSalary >= benchmark.medianSalary * 0.9) {
            competitiveness = 'Market Rate';
        } else if (offeredSalary >= benchmark.minSalary) {
            competitiveness = 'Below Market';
        } else {
            competitiveness = 'Significantly Below Market';
        }
        
        comparison.put('competitiveness', competitiveness);
        
        // Calculate percentile
        Integer percentile = calculatePercentile(offeredSalary, benchmark);
        comparison.put('percentile', percentile);
        
        return comparison;
    }
    
    /**
     * @description Parse salary API response
     * @param responseBody JSON response from API
     * @return Parsed SalaryBenchmark or null
     */
    private SalaryBenchmark parseSalaryResponse(String responseBody) {
        Map<String, Object> data = parseJsonResponse(responseBody);
        if (data == null) {
            return null;
        }
        
        try {
            SalaryBenchmark benchmark = new SalaryBenchmark();
            
            // Basic salary information
            benchmark.jobTitle = (String) getNestedValue(data, 'job_title');
            benchmark.location = (String) getNestedValue(data, 'location');
            benchmark.experienceLevel = (String) getNestedValue(data, 'experience_level');
            benchmark.currencyCode = (String) getNestedValue(data, 'currency');
            
            // Salary figures
            Object minSal = getNestedValue(data, 'salary.min');
            if (minSal != null) {
                benchmark.minSalary = Decimal.valueOf(String.valueOf(minSal));
            }
            
            Object maxSal = getNestedValue(data, 'salary.max');
            if (maxSal != null) {
                benchmark.maxSalary = Decimal.valueOf(String.valueOf(maxSal));
            }
            
            Object medianSal = getNestedValue(data, 'salary.median');
            if (medianSal != null) {
                benchmark.medianSalary = Decimal.valueOf(String.valueOf(medianSal));
            }
            
            Object avgSal = getNestedValue(data, 'salary.average');
            if (avgSal != null) {
                benchmark.averageSalary = Decimal.valueOf(String.valueOf(avgSal));
            }
            
            // Sample size
            Object sampleSize = getNestedValue(data, 'sample_size');
            if (sampleSize != null) {
                benchmark.sampleSize = Integer.valueOf(sampleSize);
            }
            
            return benchmark;
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error parsing salary response: ' + e.getMessage());
            return null;
        }
    }
    
    /**
     * @description Update Job Application with salary benchmark data
     * @param jobApp Job Application record
     * @param benchmark Salary benchmark data
     */
    private void updateJobApplicationWithSalaryData(Job_Application__c jobApp, SalaryBenchmark benchmark) {
        Job_Application__c updatedJobApp = new Job_Application__c(Id = jobApp.Id);
        
        // Build salary analysis text
        String salaryAnalysis = 'SALARY BENCHMARK ANALYSIS:\\n';
        salaryAnalysis += 'Position: ' + benchmark.jobTitle + '\\n';
        salaryAnalysis += 'Location: ' + (benchmark.location ?? 'General Market') + '\\n';
        salaryAnalysis += 'Experience Level: ' + (benchmark.experienceLevel ?? 'All Levels') + '\\n\\n';
        
        salaryAnalysis += 'MARKET SALARY RANGE:\\n';
        salaryAnalysis += 'Minimum: ' + formatCurrency(benchmark.minSalary) + '\\n';
        salaryAnalysis += 'Median: ' + formatCurrency(benchmark.medianSalary) + '\\n';
        salaryAnalysis += 'Maximum: ' + formatCurrency(benchmark.maxSalary) + '\\n';
        salaryAnalysis += 'Average: ' + formatCurrency(benchmark.averageSalary) + '\\n\\n';
        
        // Compare with offered salary if available
        if (jobApp.Salary__c != null) {
            Map<String, Object> comparison = compareSalaryToBenchmark(jobApp.Salary__c, benchmark);
            if ((Boolean) comparison.get('isValid')) {
                salaryAnalysis += 'OFFER ANALYSIS:\\n';
                salaryAnalysis += 'Offered Salary: ' + formatCurrency(jobApp.Salary__c) + '\\n';
                salaryAnalysis += 'Market Position: ' + comparison.get('competitiveness') + '\\n';
                salaryAnalysis += 'Percentile: ' + comparison.get('percentile') + 'th\\n';
                salaryAnalysis += 'Difference from Median: ' + comparison.get('percentageDifferenceFromMedian') + '%\\n\\n';
            }
        }
        
        salaryAnalysis += 'Sample Size: ' + benchmark.sampleSize + ' data points\\n';
        salaryAnalysis += 'Analysis Date: ' + DateTime.now().format() + '\\n';
        
        // For demo, append to Notes field
        updatedJobApp.Notes__c = (jobApp.Notes__c ?? '') + '\\n\\n' + salaryAnalysis;
        
        update updatedJobApp;
    }
    
    /**
     * @description Determine experience level based on salary or other factors
     * @param salary Offered salary
     * @return Experience level string
     */
    private String determineExperienceLevel(Decimal salary) {
        if (salary == null) {
            return null;
        }
        
        // Simple heuristic based on salary ranges
        if (salary < 60000) {
            return 'entry';
        } else if (salary < 100000) {
            return 'mid';
        } else if (salary < 150000) {
            return 'senior';
        } else {
            return 'executive';
        }
    }
    
    /**
     * @description Calculate percentile of offered salary within benchmark
     * @param offeredSalary Salary to evaluate
     * @param benchmark Market benchmark data
     * @return Percentile (0-100)
     */
    private Integer calculatePercentile(Decimal offeredSalary, SalaryBenchmark benchmark) {
        if (offeredSalary == null || benchmark == null || benchmark.percentiles.isEmpty()) {
            return null;
        }
        
        // Find closest percentile
        for (SalaryPercentile percentile : benchmark.percentiles) {
            if (offeredSalary <= percentile.salary) {
                return percentile.percentile;
            }
        }
        
        // If higher than all percentiles, return 100
        return 100;
    }
    
    /**
     * @description Format currency for display
     * @param amount Decimal amount
     * @return Formatted currency string
     */
    private String formatCurrency(Decimal amount) {
        if (amount == null) {
            return 'N/A';
        }
        
        return '$' + String.valueOf(amount.setScale(0).format());
    }
}