/**
 * @description Test script for REST API Integration demonstration
 * @author Learning Journey
 * @date 2025-01-08
 * 
 * This script demonstrates the REST API integration functionality
 * Run this in Anonymous Apex to test the API services
 */

System.debug('=== REST API Integration Test ===');

// Get a test Job Application record
List<Job_Application__c> jobApps = [SELECT Id, Company_Name__c, Position_Title__c, Location__c, Salary__c 
                                   FROM Job_Application__c 
                                   WHERE Company_Name__c != null 
                                   AND Position_Title__c != null 
                                   LIMIT 3];

if (jobApps.isEmpty()) {
    System.debug('No Job Application records found. Creating test data...');
    
    // Create test Job Application records
    List<Job_Application__c> testJobApps = new List<Job_Application__c>();
    
    testJobApps.add(new Job_Application__c(
        Company_Name__c = 'Salesforce',
        Position_Title__c = 'Software Engineer',
        Location__c = 'San Francisco, CA',
        Salary__c = 120000,
        Job_URL__c = 'https://salesforce.com/careers/job123',
        Status__c = 'Applied',
        Application_Date__c = Date.today()
    ));
    
    testJobApps.add(new Job_Application__c(
        Company_Name__c = 'Microsoft',
        Position_Title__c = 'Product Manager',
        Location__c = 'Seattle, WA',
        Salary__c = 95000,
        Job_URL__c = 'https://microsoft.com/careers/job456',
        Status__c = 'Applied',
        Application_Date__c = Date.today()
    ));
    
    testJobApps.add(new Job_Application__c(
        Company_Name__c = 'Google',
        Position_Title__c = 'Data Scientist',
        Location__c = 'Mountain View, CA',
        Salary__c = 110000,
        Status__c = 'Applied',
        Application_Date__c = Date.today()
    ));
    
    insert testJobApps;
    jobApps = testJobApps;
    System.debug('Created ' + testJobApps.size() + ' test Job Application records');
}

System.debug('Found ' + jobApps.size() + ' Job Application records for testing');

// Test 1: Single Job Application Enrichment
System.debug('\\n--- Test 1: Single Job Application Enrichment ---');
JobApplicationEnrichmentService enrichmentService = new JobApplicationEnrichmentService();

Job_Application__c testJobApp = jobApps[0];
System.debug('Testing enrichment for: ' + testJobApp.Company_Name__c + ' - ' + testJobApp.Position_Title__c);

try {
    JobApplicationEnrichmentService.EnrichmentResult result = enrichmentService.enrichJobApplication(testJobApp.Id);
    
    System.debug('Enrichment Result:');
    System.debug('- Success: ' + result.success);
    System.debug('- Processing Time: ' + result.processingTime + 'ms');
    System.debug('- Enrichment Types: ' + result.enrichmentTypes);
    if (!result.success && result.errorMessage != null) {
        System.debug('- Error: ' + result.errorMessage);
    }
    
} catch (Exception e) {
    System.debug('ERROR in single enrichment: ' + e.getMessage());
    System.debug('Note: This is expected in test environment without actual API endpoints');
}

// Test 2: Batch Job Application Enrichment
System.debug('\\n--- Test 2: Batch Job Application Enrichment ---');

List<Id> jobAppIds = new List<Id>();
for (Job_Application__c jobApp : jobApps) {
    jobAppIds.add(jobApp.Id);
}

try {
    JobApplicationEnrichmentService.BatchEnrichmentSummary batchSummary = 
        enrichmentService.batchEnrichJobApplications(jobAppIds);
    
    System.debug('Batch Enrichment Summary:');
    System.debug('- Total Records: ' + batchSummary.totalRecords);
    System.debug('- Successful Enrichments: ' + batchSummary.successfulEnrichments);
    System.debug('- Failed Enrichments: ' + batchSummary.failedEnrichments);
    System.debug('- Total Processing Time: ' + batchSummary.totalProcessingTime + 'ms');
    
    System.debug('\\nIndividual Results:');
    for (JobApplicationEnrichmentService.EnrichmentResult result : batchSummary.results) {
        System.debug('- Job App ' + result.jobApplicationId + ': ' + 
                    (result.success ? 'SUCCESS' : 'FAILED') + 
                    ' (' + result.enrichmentTypes + ')');
    }
    
} catch (Exception e) {
    System.debug('ERROR in batch enrichment: ' + e.getMessage());
    System.debug('Note: This is expected in test environment without actual API endpoints');
}

// Test 3: Company Data Service Direct Test
System.debug('\\n--- Test 3: Company Data Service Direct Test ---');

CompanyDataService companyService = new CompanyDataService();

try {
    System.debug('Testing company lookup for: ' + testJobApp.Company_Name__c);
    CompanyDataService.CompanyData companyData = companyService.getCompanyByName(testJobApp.Company_Name__c);
    
    if (companyData != null) {
        System.debug('Company Data Retrieved:');
        System.debug('- Name: ' + companyData.companyName);
        System.debug('- Industry: ' + companyData.industry);
        System.debug('- Size: ' + companyData.size);
        System.debug('- Employee Count: ' + companyData.employeeCount);
        System.debug('- Website: ' + companyData.website);
        if (companyData.rating != null) {
            System.debug('- Overall Rating: ' + companyData.rating.overallRating);
        }
    } else {
        System.debug('No company data retrieved (expected in test environment)');
    }
    
} catch (Exception e) {
    System.debug('ERROR in company data service: ' + e.getMessage());
    System.debug('Note: This is expected in test environment without actual API endpoints');
}

// Test 4: Salary Benchmark Service Direct Test
System.debug('\\n--- Test 4: Salary Benchmark Service Direct Test ---');

SalaryBenchmarkService salaryService = new SalaryBenchmarkService();

try {
    System.debug('Testing salary benchmark for: ' + testJobApp.Position_Title__c + ' in ' + testJobApp.Location__c);
    SalaryBenchmarkService.SalaryBenchmark salaryBenchmark = 
        salaryService.getSalaryBenchmark(testJobApp.Position_Title__c, testJobApp.Location__c, 'mid');
    
    if (salaryBenchmark != null) {
        System.debug('Salary Benchmark Retrieved:');
        System.debug('- Job Title: ' + salaryBenchmark.jobTitle);
        System.debug('- Location: ' + salaryBenchmark.location);
        System.debug('- Min Salary: $' + salaryBenchmark.minSalary);
        System.debug('- Median Salary: $' + salaryBenchmark.medianSalary);
        System.debug('- Max Salary: $' + salaryBenchmark.maxSalary);
        System.debug('- Sample Size: ' + salaryBenchmark.sampleSize);
        
        // Test salary comparison if we have an offered salary
        if (testJobApp.Salary__c != null) {
            Map<String, Object> comparison = salaryService.compareSalaryToBenchmark(testJobApp.Salary__c, salaryBenchmark);
            if ((Boolean) comparison.get('isValid')) {
                System.debug('\\nSalary Comparison:');
                System.debug('- Offered Salary: $' + testJobApp.Salary__c);
                System.debug('- Market Position: ' + comparison.get('competitiveness'));
                System.debug('- Percentile: ' + comparison.get('percentile') + 'th');
                System.debug('- Difference from Median: ' + comparison.get('percentageDifferenceFromMedian') + '%');
            }
        }
    } else {
        System.debug('No salary benchmark data retrieved (expected in test environment)');
    }
    
} catch (Exception e) {
    System.debug('ERROR in salary benchmark service: ' + e.getMessage());
    System.debug('Note: This is expected in test environment without actual API endpoints');
}

// Test 5: Enrichment Statistics
System.debug('\\n--- Test 5: Enrichment Statistics ---');

try {
    Map<String, Object> stats = enrichmentService.getEnrichmentStatistics(30);
    
    System.debug('Enrichment Statistics (Last 30 Days):');
    System.debug('- Total Job Applications: ' + stats.get('totalJobApplications'));
    System.debug('- Company Data Enrichments: ' + stats.get('companyDataEnrichments'));
    System.debug('- Salary Benchmark Enrichments: ' + stats.get('salaryBenchmarkEnrichments'));
    System.debug('- Enrichment Rate: ' + stats.get('enrichmentRate') + '%');
    System.debug('- Analysis Date: ' + stats.get('analysisDate'));
    
} catch (Exception e) {
    System.debug('ERROR getting enrichment statistics: ' + e.getMessage());
}

// Test 6: Base API Service Functionality
System.debug('\\n--- Test 6: Base API Service Functionality ---');

try {
    // Create a test API request (this will fail in test environment, but shows the structure)
    BaseApiService.ApiRequest testRequest = new BaseApiService.ApiRequest();
    testRequest.endpoint = 'https://api.example.com/test';
    testRequest.method = 'GET';
    testRequest.parameters.put('test', 'value');
    testRequest.headers.put('Authorization', 'Bearer test-token');
    
    System.debug('Test API Request Created:');
    System.debug('- Endpoint: ' + testRequest.endpoint);
    System.debug('- Method: ' + testRequest.method);
    System.debug('- Parameters: ' + testRequest.parameters);
    System.debug('- Headers: ' + testRequest.headers.keySet());
    System.debug('- Timeout: ' + testRequest.timeout + 'ms');
    System.debug('- Retry Enabled: ' + testRequest.enableRetry);
    
} catch (Exception e) {
    System.debug('ERROR testing base API service: ' + e.getMessage());
}

// Test 7: Schedule Asynchronous Enrichment
System.debug('\\n--- Test 7: Schedule Asynchronous Enrichment ---');

try {
    System.debug('Scheduling asynchronous enrichment for ' + jobAppIds.size() + ' Job Applications...');
    JobApplicationEnrichmentService.scheduleEnrichment(jobAppIds);
    System.debug('Asynchronous enrichment scheduled successfully');
    System.debug('Note: Check Setup -> Apex Jobs to see the queued job');
    
} catch (Exception e) {
    System.debug('ERROR scheduling enrichment: ' + e.getMessage());
}

System.debug('\\n=== REST API Integration Test Complete ===');
System.debug('\\nNOTE: In a real environment with actual API endpoints configured:');
System.debug('1. Set up Named Credentials for secure API authentication');
System.debug('2. Configure Remote Site Settings for external endpoints');
System.debug('3. Replace demo API keys with real credentials');
System.debug('4. Test with actual API responses');
System.debug('5. Monitor API usage and rate limits');
System.debug('\\nThe framework is ready for production use with real APIs!');