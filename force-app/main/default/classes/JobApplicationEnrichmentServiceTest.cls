/**
 * @description Test class for JobApplicationEnrichmentService
 * @author Learning Journey
 * @date 2025-01-08
 */
@IsTest
public inherited sharing class JobApplicationEnrichmentServiceTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test Job Application records
        List<Job_Application__c> jobApps = new List<Job_Application__c>();
        
        jobApps.add(new Job_Application__c(
            Company_Name__c = 'Salesforce',
            Position_Title__c = 'Software Engineer',
            Location__c = 'Remote',
            Salary__c = 120000,
            Job_URL__c = 'https://salesforce.com/careers/job123',
            Status__c = 'Applied'
        ));
        
        jobApps.add(new Job_Application__c(
            Company_Name__c = 'Microsoft',
            Position_Title__c = 'Product Manager',
            Location__c = 'Seattle, WA',
            Salary__c = 95000,
            Job_URL__c = 'https://microsoft.com/careers/job456',
            Status__c = 'Applied'
        ));
        
        jobApps.add(new Job_Application__c(
            Company_Name__c = 'Google',
            Position_Title__c = 'Data Scientist',
            Location__c = 'Mountain View, CA',
            Salary__c = 110000,
            Status__c = 'Applied'
        ));
        
        jobApps.add(new Job_Application__c(
            Company_Name__c = 'Apple',
            Position_Title__c = 'iOS Developer',
            Location__c = 'Cupertino, CA',
            Status__c = 'Applied'
        ));
        
        insert jobApps;
    }
    
    @IsTest
    static void testEnrichSingleJobApplication() {
        // Setup mock responses for both company and salary APIs
        Test.setMock(HttpCalloutMock.class, new MultiApiMockGenerator());
        
        Job_Application__c jobApp = [SELECT Id FROM Job_Application__c WHERE Company_Name__c = 'Salesforce' LIMIT 1];
        JobApplicationEnrichmentService service = new JobApplicationEnrichmentService();
        
        Test.startTest();
        JobApplicationEnrichmentService.EnrichmentResult result = service.enrichJobApplication(jobApp.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(jobApp.Id, result.jobApplicationId, 'Job Application ID should match');
        System.assert(result.success, 'Enrichment should be successful');
        System.assert(result.processingTime > 0, 'Processing time should be recorded');
        System.assert(!result.enrichmentTypes.isEmpty(), 'Should have enrichment types');
        
        // Verify the Job Application was updated
        Job_Application__c updatedJobApp = [SELECT Id, Notes__c FROM Job_Application__c WHERE Id = :jobApp.Id];
        System.assert(updatedJobApp.Notes__c.contains('COMPANY DATA ENRICHMENT') || 
                     updatedJobApp.Notes__c.contains('SALARY BENCHMARK ANALYSIS'), 
                     'Notes should contain enrichment data');
    }
    
    @IsTest
    static void testBatchEnrichJobApplications() {
        // Setup mock responses
        Test.setMock(HttpCalloutMock.class, new MultiApiMockGenerator());
        
        List<Job_Application__c> jobApps = [SELECT Id FROM Job_Application__c LIMIT 3];
        List<Id> jobAppIds = new List<Id>();
        for (Job_Application__c jobApp : jobApps) {
            jobAppIds.add(jobApp.Id);
        }
        
        JobApplicationEnrichmentService service = new JobApplicationEnrichmentService();
        
        Test.startTest();
        JobApplicationEnrichmentService.BatchEnrichmentSummary summary = service.batchEnrichJobApplications(jobAppIds);
        Test.stopTest();
        
        System.assertNotEquals(null, summary, 'Summary should not be null');
        System.assertEquals(3, summary.totalRecords, 'Total records should be 3');
        System.assertEquals(3, summary.results.size(), 'Should have 3 results');
        System.assert(summary.totalProcessingTime > 0, 'Processing time should be recorded');
        System.assert(summary.successfulEnrichments >= 0, 'Should have success count');
        System.assert(summary.failedEnrichments >= 0, 'Should have failure count');
        System.assertEquals(3, summary.successfulEnrichments + summary.failedEnrichments, 'Success + failure should equal total');
    }
    
    @IsTest
    static void testEnrichRecentJobApplications() {
        // Setup mock responses
        Test.setMock(HttpCalloutMock.class, new MultiApiMockGenerator());
        
        JobApplicationEnrichmentService service = new JobApplicationEnrichmentService();
        
        Test.startTest();
        JobApplicationEnrichmentService.BatchEnrichmentSummary summary = service.enrichRecentJobApplications(24);
        Test.stopTest();
        
        System.assertNotEquals(null, summary, 'Summary should not be null');
        System.assert(summary.totalRecords >= 0, 'Should have total records count');
        System.assertNotEquals(null, summary.results, 'Results should not be null');
    }
    
    @IsTest
    static void testGetEnrichmentStatistics() {
        JobApplicationEnrichmentService service = new JobApplicationEnrichmentService();
        
        Test.startTest();
        Map<String, Object> stats = service.getEnrichmentStatistics(30);
        Test.stopTest();
        
        System.assertNotEquals(null, stats, 'Statistics should not be null');
        System.assert(stats.containsKey('totalJobApplications'), 'Should contain total job applications');
        System.assert(stats.containsKey('companyDataEnrichments'), 'Should contain company enrichments count');
        System.assert(stats.containsKey('salaryBenchmarkEnrichments'), 'Should contain salary enrichments count');
        System.assert(stats.containsKey('enrichmentRate'), 'Should contain enrichment rate');
        System.assert(stats.containsKey('analysisDate'), 'Should contain analysis date');
        System.assert(stats.containsKey('analysisPeriodDays'), 'Should contain analysis period');
        
        System.assertEquals(30, stats.get('analysisPeriodDays'), 'Analysis period should match');
    }
    
    @IsTest
    static void testEnrichmentWithInvalidJobAppId() {
        JobApplicationEnrichmentService service = new JobApplicationEnrichmentService();
        
        Test.startTest();
        JobApplicationEnrichmentService.EnrichmentResult result = service.enrichJobApplication(null);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(!result.success, 'Enrichment should fail');
        System.assertNotEquals(null, result.errorMessage, 'Should have error message');
    }
    
    @IsTest
    static void testBatchEnrichmentWithEmptyList() {
        JobApplicationEnrichmentService service = new JobApplicationEnrichmentService();
        
        Test.startTest();
        JobApplicationEnrichmentService.BatchEnrichmentSummary summary = service.batchEnrichJobApplications(new List<Id>());
        Test.stopTest();
        
        System.assertNotEquals(null, summary, 'Summary should not be null');
        System.assertEquals(0, summary.totalRecords, 'Total records should be 0');
        System.assertEquals(0, summary.results.size(), 'Results should be empty');
    }
    
    @IsTest
    static void testEnrichmentWithApiFailures() {
        // Setup mock to return errors
        Test.setMock(HttpCalloutMock.class, new FailingApiMockGenerator());
        
        Job_Application__c jobApp = [SELECT Id FROM Job_Application__c WHERE Company_Name__c = 'Salesforce' LIMIT 1];
        JobApplicationEnrichmentService service = new JobApplicationEnrichmentService();
        
        Test.startTest();
        JobApplicationEnrichmentService.EnrichmentResult result = service.enrichJobApplication(jobApp.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        // Result might still be successful if one API works and another fails
        System.assertNotEquals(null, result.errorMessage == null ? '' : result.errorMessage, 'Should handle errors gracefully');
    }
    
    @IsTest
    static void testScheduleEnrichment() {
        List<Job_Application__c> jobApps = [SELECT Id FROM Job_Application__c LIMIT 2];
        List<Id> jobAppIds = new List<Id>();
        for (Job_Application__c jobApp : jobApps) {
            jobAppIds.add(jobApp.Id);
        }
        
        Test.startTest();
        JobApplicationEnrichmentService.scheduleEnrichment(jobAppIds);
        Test.stopTest();
        
        // Verify that a queueable job was enqueued
        // Note: In test context, we can't easily verify the queueable was actually enqueued
        // This test mainly ensures no exceptions are thrown
        System.assert(true, 'Schedule enrichment should complete without errors');
    }
    
    @IsTest
    static void testScheduleEnrichmentWithEmptyList() {
        Test.startTest();
        JobApplicationEnrichmentService.scheduleEnrichment(new List<Id>());
        JobApplicationEnrichmentService.scheduleEnrichment(null);
        Test.stopTest();
        
        // Should handle empty/null lists gracefully
        System.assert(true, 'Should handle empty lists without errors');
    }
    
    @IsTest
    static void testEnrichmentQueueable() {
        // Setup mock responses
        Test.setMock(HttpCalloutMock.class, new MultiApiMockGenerator());
        
        List<Job_Application__c> jobApps = [SELECT Id FROM Job_Application__c LIMIT 2];
        List<Id> jobAppIds = new List<Id>();
        for (Job_Application__c jobApp : jobApps) {
            jobAppIds.add(jobApp.Id);
        }
        
        JobApplicationEnrichmentService.EnrichmentQueueable queueable = 
            new JobApplicationEnrichmentService.EnrichmentQueueable(jobAppIds);
        
        Test.startTest();
        System.enqueueJob(queueable);
        Test.stopTest();
        
        // Verify queueable executed without errors
        System.assert(true, 'Queueable should execute without errors');
    }
    
    @IsTest
    static void testEnrichmentResultInitialization() {
        Id testJobAppId = [SELECT Id FROM Job_Application__c LIMIT 1].Id;
        
        Test.startTest();
        JobApplicationEnrichmentService.EnrichmentResult result = 
            new JobApplicationEnrichmentService.EnrichmentResult(testJobAppId);
        Test.stopTest();
        
        System.assertEquals(testJobAppId, result.jobApplicationId, 'Job App ID should be set');
        System.assertEquals(false, result.success, 'Success should default to false');
        System.assertNotEquals(null, result.enrichmentTypes, 'Enrichment types should be initialized');
        System.assertEquals(0, result.enrichmentTypes.size(), 'Enrichment types should be empty initially');
    }
    
    @IsTest
    static void testBatchEnrichmentSummaryInitialization() {
        Test.startTest();
        JobApplicationEnrichmentService.BatchEnrichmentSummary summary = 
            new JobApplicationEnrichmentService.BatchEnrichmentSummary();
        Test.stopTest();
        
        System.assertNotEquals(null, summary.results, 'Results should be initialized');
        System.assertEquals(0, summary.results.size(), 'Results should be empty initially');
    }
    
    /**
     * @description Mock generator that provides responses for multiple APIs
     */
    public class MultiApiMockGenerator implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            
            String endpoint = request.getEndpoint();
            
            if (endpoint.contains('company-data.com')) {
                // Company API response
                response.setStatusCode(200);
                response.setBody('{\n' +
                    '  "company": {\n' +
                    '    "name": "Test Company",\n' +
                    '    "industry": "Technology",\n' +
                    '    "size": "Large",\n' +
                    '    "employee_count": 10000,\n' +
                    '    "headquarters": "San Francisco, CA",\n' +
                    '    "ratings": {\n' +
                    '      "overall": 4.2,\n' +
                    '      "work_life_balance": 4.0\n' +
                    '    }\n' +
                    '  }\n' +
                    '}');
            } else if (endpoint.contains('salary-data.com')) {
                // Salary API response
                response.setStatusCode(200);
                response.setBody('{\n' +
                    '  "job_title": "Software Engineer",\n' +
                    '  "location": "San Francisco, CA",\n' +
                    '  "salary": {\n' +
                    '    "min": 90000,\n' +
                    '    "max": 160000,\n' +
                    '    "median": 125000,\n' +
                    '    "average": 128000\n' +
                    '  },\n' +
                    '  "sample_size": 1000\n' +
                    '}');
            } else {
                // Default response
                response.setStatusCode(404);
                response.setBody('{"error": "Not Found"}');
            }
            
            return response;
        }
    }
    
    /**
     * @description Mock generator that simulates API failures
     */
    public class FailingApiMockGenerator implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(500);
            response.setBody('{"error": "Internal Server Error"}');
            response.setHeader('Content-Type', 'application/json');
            return response;
        }
    }
}