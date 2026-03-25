/**
 * @description Test class for CompanyDataService
 * @author Learning Journey
 * @date 2025-01-08
 */
@IsTest
public class CompanyDataServiceTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test Job Application records
        List<Job_Application__c> jobApps = new List<Job_Application__c>();
        
        jobApps.add(new Job_Application__c(
            Company_Name__c = 'Salesforce',
            Position_Title__c = 'Software Engineer',
            Location__c = 'Remote',
            Job_URL__c = 'https://salesforce.com/careers/job123',
            Status__c = 'Applied'
        ));
        
        jobApps.add(new Job_Application__c(
            Company_Name__c = 'Microsoft',
            Position_Title__c = 'Product Manager',
            Location__c = 'Seattle, WA',
            Job_URL__c = 'https://microsoft.com/careers/job456',
            Status__c = 'Applied'
        ));
        
        jobApps.add(new Job_Application__c(
            Company_Name__c = 'Google',
            Position_Title__c = 'Data Scientist',
            Location__c = 'Mountain View, CA',
            Status__c = 'Applied'
        ));
        
        insert jobApps;
    }
    
    @IsTest
    static void testGetCompanyByName() {
        // Setup mock response
        String mockResponse = '{\n' +
            '  "company": {\n' +
            '    "name": "Salesforce",\n' +
            '    "industry": "Software",\n' +
            '    "size": "Large",\n' +
            '    "website": "https://salesforce.com",\n' +
            '    "description": "Customer Relationship Management",\n' +
            '    "headquarters": "San Francisco, CA",\n' +
            '    "employee_count": 73000,\n' +
            '    "revenue": 26492000000,\n' +
            '    "founded": "1999",\n' +
            '    "technologies": ["Apex", "Lightning", "Heroku"],\n' +
            '    "ratings": {\n' +
            '      "overall": 4.4,\n' +
            '      "work_life_balance": 4.2,\n' +
            '      "compensation": 4.3,\n' +
            '      "culture": 4.5,\n' +
            '      "review_count": 15000\n' +
            '    }\n' +
            '  }\n' +
            '}';\n        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, mockResponse));
        
        CompanyDataService service = new CompanyDataService();
        
        Test.startTest();
        CompanyDataService.CompanyData result = service.getCompanyByName('Salesforce');
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Company data should not be null');
        System.assertEquals('Salesforce', result.companyName, 'Company name should match');
        System.assertEquals('Software', result.industry, 'Industry should match');
        System.assertEquals('Large', result.size, 'Size should match');
        System.assertEquals(73000, result.employeeCount, 'Employee count should match');
        System.assertEquals(4.4, result.rating.overallRating, 'Overall rating should match');
        System.assertEquals(3, result.technologies.size(), 'Should have 3 technologies');
    }
    
    @IsTest
    static void testGetCompanyByDomain() {
        String mockResponse = '{\n' +
            '  "company": {\n' +
            '    "name": "Microsoft",\n' +
            '    "industry": "Technology",\n' +
            '    "size": "Enterprise",\n' +
            '    "website": "https://microsoft.com",\n' +
            '    "headquarters": "Redmond, WA",\n' +
            '    "employee_count": 221000\n' +
            '  }\n' +
            '}';\n        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, mockResponse));
        
        CompanyDataService service = new CompanyDataService();
        
        Test.startTest();
        CompanyDataService.CompanyData result = service.getCompanyByDomain('microsoft.com');
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Company data should not be null');
        System.assertEquals('Microsoft', result.companyName, 'Company name should match');
        System.assertEquals('Technology', result.industry, 'Industry should match');
        System.assertEquals(221000, result.employeeCount, 'Employee count should match');
    }
    
    @IsTest
    static void testEnrichJobApplication() {
        String mockResponse = '{\n' +
            '  "company": {\n' +
            '    "name": "Salesforce",\n' +
            '    "industry": "Cloud Computing",\n' +
            '    "size": "Large Enterprise",\n' +
            '    "employee_count": 73000,\n' +
            '    "headquarters": "San Francisco, CA",\n' +
            '    "ratings": {\n' +
            '      "overall": 4.4,\n' +
            '      "work_life_balance": 4.2\n' +
            '    }\n' +
            '  }\n' +
            '}';\n        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, mockResponse));
        
        Job_Application__c jobApp = [SELECT Id FROM Job_Application__c WHERE Company_Name__c = 'Salesforce' LIMIT 1];
        CompanyDataService service = new CompanyDataService();
        
        Test.startTest();
        Boolean result = service.enrichJobApplication(jobApp.Id);
        Test.stopTest();
        
        System.assert(result, 'Enrichment should be successful');
        
        // Verify the Job Application was updated
        Job_Application__c updatedJobApp = [SELECT Id, Notes__c FROM Job_Application__c WHERE Id = :jobApp.Id];
        System.assert(updatedJobApp.Notes__c.contains('COMPANY DATA ENRICHMENT'), 'Notes should contain enrichment data');
        System.assert(updatedJobApp.Notes__c.contains('Cloud Computing'), 'Notes should contain industry data');
    }
    
    @IsTest
    static void testBulkEnrichJobApplications() {
        String mockResponse = '{\n' +
            '  "company": {\n' +
            '    "name": "Test Company",\n' +
            '    "industry": "Technology",\n' +
            '    "size": "Medium",\n' +
            '    "employee_count": 5000\n' +
            '  }\n' +
            '}';\n        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, mockResponse));
        
        List<Job_Application__c> jobApps = [SELECT Id FROM Job_Application__c LIMIT 2];
        List<Id> jobAppIds = new List<Id>();
        for (Job_Application__c jobApp : jobApps) {
            jobAppIds.add(jobApp.Id);
        }
        
        CompanyDataService service = new CompanyDataService();
        
        Test.startTest();
        Map<Id, Boolean> results = service.bulkEnrichJobApplications(jobAppIds);
        Test.stopTest();
        
        System.assertEquals(2, results.size(), 'Should have results for 2 Job Applications');
        
        // Check that at least some enrichments were successful
        Integer successCount = 0;
        for (Boolean success : results.values()) {
            if (success) successCount++;
        }
        System.assert(successCount > 0, 'At least one enrichment should be successful');
    }
    
    @IsTest
    static void testApiFailure() {
        // Setup mock to return error
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(404, '{"error": "Company not found"}'));
        
        CompanyDataService service = new CompanyDataService();
        
        Test.startTest();
        CompanyDataService.CompanyData result = service.getCompanyByName('NonExistentCompany');
        Test.stopTest();
        
        System.assertEquals(null, result, 'Result should be null for failed API call');
    }
    
    @IsTest
    static void testInvalidJobApplicationId() {
        CompanyDataService service = new CompanyDataService();
        
        Test.startTest();
        Boolean result = service.enrichJobApplication(null);
        Test.stopTest();
        
        System.assert(!result, 'Enrichment should fail for null ID');
    }
    
    @IsTest
    static void testEmptyCompanyName() {
        CompanyDataService service = new CompanyDataService();
        
        Test.startTest();
        CompanyDataService.CompanyData result = service.getCompanyByName('');
        Test.stopTest();
        
        System.assertEquals(null, result, 'Result should be null for empty company name');
    }
    
    @IsTest
    static void testDomainCleaning() {
        String mockResponse = '{\n' +
            '  "company": {\n' +
            '    "name": "Example Corp",\n' +
            '    "industry": "Technology"\n' +
            '  }\n' +
            '}';\n        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, mockResponse));
        
        CompanyDataService service = new CompanyDataService();
        
        Test.startTest();
        // Test various domain formats
        CompanyDataService.CompanyData result1 = service.getCompanyByDomain('https://www.example.com/careers');
        CompanyDataService.CompanyData result2 = service.getCompanyByDomain('http://example.com');
        CompanyDataService.CompanyData result3 = service.getCompanyByDomain('www.example.com');
        Test.stopTest();
        
        // All should work (domain cleaning should handle different formats)
        System.assertNotEquals(null, result1, 'Should handle full URL with path');
        System.assertNotEquals(null, result2, 'Should handle http protocol');
        System.assertNotEquals(null, result3, 'Should handle www prefix');
    }
    
    @IsTest
    static void testMalformedJsonResponse() {
        // Setup mock with malformed JSON
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, '{"company": {"name": "Test", invalid json'));
        
        CompanyDataService service = new CompanyDataService();
        
        Test.startTest();
        CompanyDataService.CompanyData result = service.getCompanyByName('TestCompany');
        Test.stopTest();
        
        System.assertEquals(null, result, 'Should handle malformed JSON gracefully');
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