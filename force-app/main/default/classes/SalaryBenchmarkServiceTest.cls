/**
 * @description Test class for SalaryBenchmarkService
 * @author Learning Journey
 * @date 2025-01-08
 */
@IsTest
public inherited sharing class SalaryBenchmarkServiceTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test Job Application records
        List<Job_Application__c> jobApps = new List<Job_Application__c>();
        
        jobApps.add(new Job_Application__c(
            Company_Name__c = 'Tech Corp',
            Position_Title__c = 'Software Engineer',
            Location__c = 'Remote',
            Salary__c = 120000,
            Status__c = 'Applied'
        ));
        
        jobApps.add(new Job_Application__c(
            Company_Name__c = 'Data Inc',
            Position_Title__c = 'Data Scientist',
            Location__c = 'New York, NY',
            Salary__c = 95000,
            Status__c = 'Applied'
        ));
        
        jobApps.add(new Job_Application__c(
            Company_Name__c = 'Product Co',
            Position_Title__c = 'Product Manager',
            Location__c = 'Seattle, WA',
            Status__c = 'Applied'
        ));
        
        insert jobApps;
    }
    
    @IsTest
    static void testGetSalaryBenchmark() {
        String mockResponse = '{\n' +
            '  "job_title": "Software Engineer",\n' +
            '  "location": "San Francisco, CA",\n' +
            '  "experience_level": "mid",\n' +
            '  "currency": "USD",\n' +
            '  "salary": {\n' +
            '    "min": 90000,\n' +
            '    "max": 160000,\n' +
            '    "median": 125000,\n' +
            '    "average": 128000\n' +
            '  },\n' +
            '  "sample_size": 1250,\n' +
            '  "last_updated": "2025-01-01",\n' +
            '  "percentiles": [\n' +
            '    {"percentile": 25, "salary": 105000},\n' +
            '    {"percentile": 50, "salary": 125000},\n' +
            '    {"percentile": 75, "salary": 145000},\n' +
            '    {"percentile": 90, "salary": 155000}\n' +
            '  ],\n' +
            '  "experience_breakdown": [\n' +
            '    {"level": "entry", "average": 95000, "min": 80000, "max": 110000, "sample_size": 300},\n' +
            '    {"level": "mid", "average": 128000, "min": 110000, "max": 145000, "sample_size": 600},\n' +
            '    {"level": "senior", "average": 155000, "min": 140000, "max": 170000, "sample_size": 350}\n' +
            '  ]\n' +
            '}';\n        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, mockResponse));
        
        SalaryBenchmarkService service = new SalaryBenchmarkService();
        
        Test.startTest();
        SalaryBenchmarkService.SalaryBenchmark result = service.getSalaryBenchmark('Software Engineer', 'San Francisco, CA', 'mid');
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Salary benchmark should not be null');
        System.assertEquals('Software Engineer', result.jobTitle, 'Job title should match');
        System.assertEquals('San Francisco, CA', result.location, 'Location should match');
        System.assertEquals('mid', result.experienceLevel, 'Experience level should match');
        System.assertEquals(90000, result.minSalary, 'Min salary should match');
        System.assertEquals(160000, result.maxSalary, 'Max salary should match');
        System.assertEquals(125000, result.medianSalary, 'Median salary should match');
        System.assertEquals(128000, result.averageSalary, 'Average salary should match');
        System.assertEquals(1250, result.sampleSize, 'Sample size should match');
        System.assertEquals(4, result.percentiles.size(), 'Should have 4 percentiles');
        System.assertEquals(3, result.experienceBreakdown.size(), 'Should have 3 experience levels');
    }
    
    @IsTest
    static void testGetSalaryTrends() {
        String mockResponse = '{\n' +
            '  "trends": [\n' +
            '    {"month": "2024-12", "average_salary": 125000, "sample_size": 150},\n' +
            '    {"month": "2024-11", "average_salary": 123000, "sample_size": 140},\n' +
            '    {"month": "2024-10", "average_salary": 121000, "sample_size": 135}\n' +
            '  ]\n' +
            '}';\n        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, mockResponse));
        
        SalaryBenchmarkService service = new SalaryBenchmarkService();
        
        Test.startTest();
        List<Map<String, Object>> trends = service.getSalaryTrends('Software Engineer', 'San Francisco, CA', 3);
        Test.stopTest();
        
        System.assertEquals(3, trends.size(), 'Should have 3 trend data points');
        
        Map<String, Object> latestTrend = trends[0];
        System.assertEquals('2024-12', latestTrend.get('month'), 'Latest month should match');
        System.assertEquals(125000, latestTrend.get('average_salary'), 'Latest average salary should match');
    }
    
    @IsTest
    static void testEnrichJobApplicationWithSalary() {
        String mockResponse = '{\n' +
            '  "job_title": "Software Engineer",\n' +
            '  "location": "San Francisco, CA",\n' +
            '  "salary": {\n' +
            '    "min": 90000,\n' +
            '    "max": 160000,\n' +
            '    "median": 125000,\n' +
            '    "average": 128000\n' +
            '  },\n' +
            '  "sample_size": 1250,\n' +
            '  "last_updated": "2025-01-01"\n' +
            '}';\n        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, mockResponse));
        
        Job_Application__c jobApp = [SELECT Id FROM Job_Application__c WHERE Position_Title__c = 'Software Engineer' LIMIT 1];
        SalaryBenchmarkService service = new SalaryBenchmarkService();
        
        Test.startTest();
        Boolean result = service.enrichJobApplicationWithSalary(jobApp.Id);
        Test.stopTest();
        
        System.assert(result, 'Salary enrichment should be successful');
        
        // Verify the Job Application was updated
        Job_Application__c updatedJobApp = [SELECT Id, Notes__c FROM Job_Application__c WHERE Id = :jobApp.Id];
        System.assert(updatedJobApp.Notes__c.contains('SALARY BENCHMARK ANALYSIS'), 'Notes should contain salary analysis');
        System.assert(updatedJobApp.Notes__c.contains('$125,000'), 'Notes should contain median salary');
        System.assert(updatedJobApp.Notes__c.contains('OFFER ANALYSIS'), 'Notes should contain offer analysis');
    }
    
    @IsTest
    static void testCompareSalaryToBenchmark() {
        SalaryBenchmarkService service = new SalaryBenchmarkService();
        
        // Create benchmark data
        SalaryBenchmarkService.SalaryBenchmark benchmark = new SalaryBenchmarkService.SalaryBenchmark();
        benchmark.minSalary = 90000;
        benchmark.maxSalary = 160000;
        benchmark.medianSalary = 125000;
        benchmark.averageSalary = 128000;
        
        // Add percentiles
        benchmark.percentiles.add(createPercentile(25, 105000));
        benchmark.percentiles.add(createPercentile(50, 125000));
        benchmark.percentiles.add(createPercentile(75, 145000));
        benchmark.percentiles.add(createPercentile(90, 155000));
        
        Test.startTest();
        
        // Test above market salary
        Map<String, Object> comparison1 = service.compareSalaryToBenchmark(140000, benchmark);
        System.assertEquals(true, comparison1.get('isValid'), 'Comparison should be valid');
        System.assertEquals('Above Market', comparison1.get('competitiveness'), 'Should be above market');
        System.assertEquals(12.0, comparison1.get('percentageDifferenceFromMedian'), 'Percentage difference should be correct');
        
        // Test below market salary
        Map<String, Object> comparison2 = service.compareSalaryToBenchmark(100000, benchmark);
        System.assertEquals('Below Market', comparison2.get('competitiveness'), 'Should be below market');
        
        // Test market rate salary
        Map<String, Object> comparison3 = service.compareSalaryToBenchmark(125000, benchmark);
        System.assertEquals('Market Rate', comparison3.get('competitiveness'), 'Should be market rate');
        
        Test.stopTest();
    }
    
    @IsTest
    static void testApiFailure() {
        // Setup mock to return error
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(404, '{"error": "Job title not found"}'));
        
        SalaryBenchmarkService service = new SalaryBenchmarkService();
        
        Test.startTest();
        SalaryBenchmarkService.SalaryBenchmark result = service.getSalaryBenchmark('NonExistentJob', 'Nowhere', 'entry');
        Test.stopTest();
        
        System.assertEquals(null, result, 'Result should be null for failed API call');
    }
    
    @IsTest
    static void testInvalidJobApplicationId() {
        SalaryBenchmarkService service = new SalaryBenchmarkService();
        
        Test.startTest();
        Boolean result = service.enrichJobApplicationWithSalary(null);
        Test.stopTest();
        
        System.assert(!result, 'Enrichment should fail for null ID');
    }
    
    @IsTest
    static void testEmptyJobTitle() {
        SalaryBenchmarkService service = new SalaryBenchmarkService();
        
        Test.startTest();
        SalaryBenchmarkService.SalaryBenchmark result = service.getSalaryBenchmark('', 'San Francisco, CA', 'mid');
        Test.stopTest();
        
        System.assertEquals(null, result, 'Result should be null for empty job title');
    }
    
    @IsTest
    static void testJobApplicationWithoutPositionTitle() {
        Job_Application__c jobApp = [SELECT Id FROM Job_Application__c WHERE Position_Title__c = 'Product Manager' LIMIT 1];
        
        // Update to remove position title
        jobApp.Position_Title__c = null;
        update jobApp;
        
        SalaryBenchmarkService service = new SalaryBenchmarkService();
        
        Test.startTest();
        Boolean result = service.enrichJobApplicationWithSalary(jobApp.Id);
        Test.stopTest();
        
        System.assert(!result, 'Enrichment should fail without position title');
    }
    
    @IsTest
    static void testInvalidComparisonData() {
        SalaryBenchmarkService service = new SalaryBenchmarkService();
        
        Test.startTest();
        Map<String, Object> comparison = service.compareSalaryToBenchmark(null, null);
        Test.stopTest();
        
        System.assertEquals(false, comparison.get('isValid'), 'Comparison should be invalid');
        System.assertNotEquals(null, comparison.get('message'), 'Should have error message');
    }
    
    @IsTest
    static void testMalformedJsonResponse() {
        // Setup mock with malformed JSON
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, '{"salary": {"min": 90000, invalid json'));
        
        SalaryBenchmarkService service = new SalaryBenchmarkService();
        
        Test.startTest();
        SalaryBenchmarkService.SalaryBenchmark result = service.getSalaryBenchmark('Software Engineer', 'San Francisco, CA', 'mid');
        Test.stopTest();
        
        System.assertEquals(null, result, 'Should handle malformed JSON gracefully');
    }
    
    @IsTest
    static void testExperienceLevelDetermination() {
        // This tests the private method indirectly through enrichment
        String mockResponse = '{\n' +
            '  "job_title": "Data Scientist",\n' +
            '  "salary": {\n' +
            '    "min": 80000,\n' +
            '    "max": 140000,\n' +
            '    "median": 110000,\n' +
            '    "average": 115000\n' +
            '  }\n' +
            '}';\n        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, mockResponse));
        
        Job_Application__c jobApp = [SELECT Id FROM Job_Application__c WHERE Position_Title__c = 'Data Scientist' LIMIT 1];
        SalaryBenchmarkService service = new SalaryBenchmarkService();
        
        Test.startTest();
        Boolean result = service.enrichJobApplicationWithSalary(jobApp.Id);
        Test.stopTest();
        
        System.assert(result, 'Enrichment should be successful');
        
        // The experience level should be determined based on the salary (95000 = mid level)
        Job_Application__c updatedJobApp = [SELECT Id, Notes__c FROM Job_Application__c WHERE Id = :jobApp.Id];
        System.assert(updatedJobApp.Notes__c.contains('SALARY BENCHMARK ANALYSIS'), 'Should contain salary analysis');
    }
    
    /**
     * @description Helper method to create salary percentile
     */
    private static SalaryBenchmarkService.SalaryPercentile createPercentile(Integer percentile, Decimal salary) {
        SalaryBenchmarkService.SalaryPercentile p = new SalaryBenchmarkService.SalaryPercentile();
        p.percentile = percentile;
        p.salary = salary;
        return p;
    }
    
    /**
     * @description Mock HTTP response generator for testing
     */
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        private Integer statusCode;
        private String body;
        
        public MockHttpResponseGenerator(Integer statusCode, String body) {
            this.statusCode = statusCode;
            this.body = body;
        }
        
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(statusCode);
            response.setBody(body);
            response.setHeader('Content-Type', 'application/json');
            return response;
        }
    }
}