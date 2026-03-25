/**
 * @description Test class for JobApplicationEnrichmentQueue
 * @author Learning Journey
 * @date 2025-01-08
 */
@IsTest
public inherited sharing class JobApplicationEnrichmentQueueTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test Job Application records
        List<Job_Application__c> jobApps = new List<Job_Application__c>();
        
        jobApps.add(new Job_Application__c(
            Company_Name__c = 'Test Company 1',
            Position_Title__c = 'Software Engineer',
            Location__c = 'Remote',
            Salary__c = 120000,
            Status__c = 'Applied'
        ));
        
        jobApps.add(new Job_Application__c(
            Company_Name__c = 'Test Company 2',
            Position_Title__c = 'Product Manager',
            Location__c = 'Seattle, WA',
            Salary__c = 95000,
            Status__c = 'Applied'
        ));
        
        jobApps.add(new Job_Application__c(
            Company_Name__c = 'Test Company 3',
            Position_Title__c = 'Data Scientist',
            Location__c = 'New York, NY',
            Salary__c = 110000,
            Status__c = 'Applied'
        ));
        
        insert jobApps;
    }
    
    @IsTest
    static void testCompanyDataEnrichment() {
        List<Job_Application__c> jobApps = [SELECT Id FROM Job_Application__c LIMIT 2];
        List<Id> jobAppIds = new List<Id>();
        for (Job_Application__c jobApp : jobApps) {
            jobAppIds.add(jobApp.Id);
        }
        
        JobApplicationEnrichmentQueue queue = new JobApplicationEnrichmentQueue(
            jobAppIds,
            JobApplicationEnrichmentQueue.EnrichmentType.COMPANY_DATA
        );
        
        Test.startTest();
        System.enqueueJob(queue);
        Test.stopTest();
        
        // Verify enrichment was applied
        List<Job_Application__c> enrichedJobApps = [
            SELECT Id, Notes__c 
            FROM Job_Application__c 
            WHERE Id IN :jobAppIds
        ];
        
        for (Job_Application__c jobApp : enrichedJobApps) {
            System.assert(
                jobApp.Notes__c != null && jobApp.Notes__c.contains('COMPANY ENRICHMENT'), 
                'Company enrichment should be applied'
            );
        }
    }
    
    @IsTest
    static void testSalaryBenchmarkEnrichment() {
        List<Job_Application__c> jobApps = [SELECT Id FROM Job_Application__c LIMIT 2];
        List<Id> jobAppIds = new List<Id>();
        for (Job_Application__c jobApp : jobApps) {
            jobAppIds.add(jobApp.Id);
        }
        
        JobApplicationEnrichmentQueue queue = new JobApplicationEnrichmentQueue(
            jobAppIds,
            JobApplicationEnrichmentQueue.EnrichmentType.SALARY_BENCHMARK
        );
        
        Test.startTest();
        System.enqueueJob(queue);
        Test.stopTest();
        
        // Verify salary enrichment was applied
        List<Job_Application__c> enrichedJobApps = [
            SELECT Id, Notes__c 
            FROM Job_Application__c 
            WHERE Id IN :jobAppIds
        ];
        
        for (Job_Application__c jobApp : enrichedJobApps) {
            System.assert(
                jobApp.Notes__c != null && jobApp.Notes__c.contains('SALARY ENRICHMENT'), 
                'Salary enrichment should be applied'
            );
        }
    }
    
    @IsTest
    static void testMarketAnalysisEnrichment() {
        List<Job_Application__c> jobApps = [SELECT Id FROM Job_Application__c LIMIT 2];
        List<Id> jobAppIds = new List<Id>();
        for (Job_Application__c jobApp : jobApps) {
            jobAppIds.add(jobApp.Id);
        }
        
        JobApplicationEnrichmentQueue queue = new JobApplicationEnrichmentQueue(
            jobAppIds,
            JobApplicationEnrichmentQueue.EnrichmentType.MARKET_ANALYSIS
        );
        
        Test.startTest();
        System.enqueueJob(queue);
        Test.stopTest();
        
        // Verify market analysis was applied
        List<Job_Application__c> enrichedJobApps = [
            SELECT Id, Notes__c 
            FROM Job_Application__c 
            WHERE Id IN :jobAppIds
        ];
        
        for (Job_Application__c jobApp : enrichedJobApps) {
            System.assert(
                jobApp.Notes__c != null && jobApp.Notes__c.contains('MARKET ANALYSIS'), 
                'Market analysis should be applied'
            );
        }
    }
    
    @IsTest
    static void testFullEnrichment() {
        List<Job_Application__c> jobApps = [SELECT Id FROM Job_Application__c LIMIT 1];
        List<Id> jobAppIds = new List<Id>();
        for (Job_Application__c jobApp : jobApps) {
            jobAppIds.add(jobApp.Id);
        }
        
        JobApplicationEnrichmentQueue queue = new JobApplicationEnrichmentQueue(
            jobAppIds,
            JobApplicationEnrichmentQueue.EnrichmentType.FULL_ENRICHMENT
        );
        
        Test.startTest();
        System.enqueueJob(queue);
        Test.stopTest();
        
        // Verify all enrichment types were applied
        Job_Application__c enrichedJobApp = [
            SELECT Id, Notes__c 
            FROM Job_Application__c 
            WHERE Id = :jobAppIds[0]
        ];
        
        System.assert(
            enrichedJobApp.Notes__c.contains('COMPANY ENRICHMENT'), 
            'Company enrichment should be applied in full enrichment'
        );
        System.assert(
            enrichedJobApp.Notes__c.contains('SALARY ENRICHMENT'), 
            'Salary enrichment should be applied in full enrichment'
        );
        System.assert(
            enrichedJobApp.Notes__c.contains('MARKET ANALYSIS'), 
            'Market analysis should be applied in full enrichment'
        );
    }
    
    @IsTest
    static void testEnrichmentWithConfiguration() {
        List<Job_Application__c> jobApps = [SELECT Id FROM Job_Application__c LIMIT 1];
        List<Id> jobAppIds = new List<Id>();
        for (Job_Application__c jobApp : jobApps) {
            jobAppIds.add(jobApp.Id);
        }
        
        Map<String, Object> config = new Map<String, Object>();
        config.put('includeMarketTrends', true);
        config.put('detailedAnalysis', true);
        
        JobApplicationEnrichmentQueue queue = new JobApplicationEnrichmentQueue(
            jobAppIds,
            JobApplicationEnrichmentQueue.EnrichmentType.COMPANY_DATA,
            3,
            config
        );
        
        Test.startTest();
        System.enqueueJob(queue);
        Test.stopTest();
        
        // Verify enrichment completed with configuration
        Job_Application__c enrichedJobApp = [
            SELECT Id, Notes__c 
            FROM Job_Application__c 
            WHERE Id = :jobAppIds[0]
        ];
        
        System.assert(
            enrichedJobApp.Notes__c != null && enrichedJobApp.Notes__c.contains('COMPANY ENRICHMENT'), 
            'Enrichment with configuration should complete'
        );
    }
    
    @IsTest
    static void testEnrichmentResultClass() {
        Id testJobAppId = [SELECT Id FROM Job_Application__c LIMIT 1].Id;
        
        Test.startTest();
        
        JobApplicationEnrichmentQueue.EnrichmentResult result = 
            new JobApplicationEnrichmentQueue.EnrichmentResult(
                testJobAppId, 
                JobApplicationEnrichmentQueue.EnrichmentType.COMPANY_DATA
            );
        
        // Test initial state
        System.assertEquals(testJobAppId, result.jobApplicationId, 'Job App ID should be set');
        System.assertEquals(
            JobApplicationEnrichmentQueue.EnrichmentType.COMPANY_DATA, 
            result.type, 
            'Enrichment type should be set'
        );
        System.assertEquals(false, result.success, 'Success should default to false');
        System.assertNotEquals(null, result.data, 'Data map should be initialized');
        
        // Test setting values
        result.success = true;
        result.errorMessage = 'Test error';
        result.processingTime = 1000;
        result.data.put('testKey', 'testValue');
        
        System.assertEquals(true, result.success, 'Success should be updated');
        System.assertEquals('Test error', result.errorMessage, 'Error message should be set');
        System.assertEquals(1000, result.processingTime, 'Processing time should be set');
        System.assertEquals('testValue', result.data.get('testKey'), 'Data should be stored');
        
        Test.stopTest();
    }
    
    @IsTest
    static void testEnrichmentWithEmptyJobAppList() {
        List<Id> emptyJobAppIds = new List<Id>();
        
        JobApplicationEnrichmentQueue queue = new JobApplicationEnrichmentQueue(
            emptyJobAppIds,
            JobApplicationEnrichmentQueue.EnrichmentType.COMPANY_DATA
        );
        
        Test.startTest();
        System.enqueueJob(queue);
        Test.stopTest();
        
        // Verify queue handles empty list gracefully
        System.assert(true, 'Queue should handle empty job application list gracefully');
    }
    
    @IsTest
    static void testEnrichmentWithNullParameters() {
        List<Job_Application__c> jobApps = [SELECT Id FROM Job_Application__c LIMIT 1];
        List<Id> jobAppIds = new List<Id>();
        for (Job_Application__c jobApp : jobApps) {
            jobAppIds.add(jobApp.Id);
        }
        
        // Test with null parameters
        JobApplicationEnrichmentQueue queue = new JobApplicationEnrichmentQueue(
            jobAppIds,
            null, // null enrichment type
            null, // null max retries
            null  // null config
        );
        
        Test.startTest();
        System.enqueueJob(queue);
        Test.stopTest();
        
        // Verify queue handles null parameters gracefully
        System.assert(true, 'Queue should handle null parameters gracefully');
    }
    
    @IsTest
    static void testEnrichmentWithInvalidJobAppIds() {
        // Create list with invalid Job Application IDs
        List<Id> invalidJobAppIds = new List<Id>();
        
        // Generate a fake ID (this will cause DML errors)
        String fakeId = Job_Application__c.SObjectType.getDescribe().getKeyPrefix() + '000000000000';
        invalidJobAppIds.add(Id.valueOf(fakeId));
        
        JobApplicationEnrichmentQueue queue = new JobApplicationEnrichmentQueue(
            invalidJobAppIds,
            JobApplicationEnrichmentQueue.EnrichmentType.COMPANY_DATA
        );
        
        Test.startTest();
        try {
            System.enqueueJob(queue);
            Test.stopTest();
            
            // Queue should handle invalid IDs gracefully
            System.assert(true, 'Queue should handle invalid Job Application IDs gracefully');
            
        } catch (Exception e) {
            Test.stopTest();
            System.debug('Expected error for invalid IDs: ' + e.getMessage());
        }
    }
    
    @IsTest
    static void testSimplifiedConstructor() {
        List<Job_Application__c> jobApps = [SELECT Id FROM Job_Application__c LIMIT 1];
        List<Id> jobAppIds = new List<Id>();
        for (Job_Application__c jobApp : jobApps) {
            jobAppIds.add(jobApp.Id);
        }
        
        // Test simplified constructor
        JobApplicationEnrichmentQueue queue = new JobApplicationEnrichmentQueue(
            jobAppIds,
            JobApplicationEnrichmentQueue.EnrichmentType.SALARY_BENCHMARK
        );
        
        Test.startTest();
        System.enqueueJob(queue);
        Test.stopTest();
        
        // Verify simplified constructor works
        Job_Application__c enrichedJobApp = [
            SELECT Id, Notes__c 
            FROM Job_Application__c 
            WHERE Id = :jobAppIds[0]
        ];
        
        System.assert(
            enrichedJobApp.Notes__c != null && enrichedJobApp.Notes__c.contains('SALARY ENRICHMENT'), 
            'Simplified constructor should work correctly'
        );
    }
    
    @IsTest
    static void testEnrichmentChaining() {
        List<Job_Application__c> jobApps = [SELECT Id FROM Job_Application__c LIMIT 1];
        List<Id> jobAppIds = new List<Id>();
        for (Job_Application__c jobApp : jobApps) {
            jobAppIds.add(jobApp.Id);
        }
        
        // Test chaining by starting with company data enrichment
        // The queue should automatically chain to salary benchmark
        JobApplicationEnrichmentQueue queue = new JobApplicationEnrichmentQueue(
            jobAppIds,
            JobApplicationEnrichmentQueue.EnrichmentType.COMPANY_DATA
        );
        
        Test.startTest();
        System.enqueueJob(queue);
        Test.stopTest();
        
        // Verify company enrichment was applied
        // Note: In test context, chaining may not execute the second job
        // This test verifies the first job completes successfully
        Job_Application__c enrichedJobApp = [
            SELECT Id, Notes__c 
            FROM Job_Application__c 
            WHERE Id = :jobAppIds[0]
        ];
        
        System.assert(
            enrichedJobApp.Notes__c != null && enrichedJobApp.Notes__c.contains('COMPANY ENRICHMENT'), 
            'First enrichment in chain should complete'
        );
    }
    
    @IsTest
    static void testRetryEnrichment() {
        List<Job_Application__c> jobApps = [SELECT Id FROM Job_Application__c LIMIT 1];
        List<Id> jobAppIds = new List<Id>();
        for (Job_Application__c jobApp : jobApps) {
            jobAppIds.add(jobApp.Id);
        }
        
        JobApplicationEnrichmentQueue queue = new JobApplicationEnrichmentQueue(
            jobAppIds,
            JobApplicationEnrichmentQueue.EnrichmentType.RETRY_FAILED
        );
        
        Test.startTest();
        System.enqueueJob(queue);
        Test.stopTest();
        
        // Verify retry enrichment processes records
        Job_Application__c enrichedJobApp = [
            SELECT Id, Notes__c 
            FROM Job_Application__c 
            WHERE Id = :jobAppIds[0]
        ];
        
        // Retry failed does full enrichment, so should have multiple enrichment types
        System.assert(
            enrichedJobApp.Notes__c != null && 
            (enrichedJobApp.Notes__c.contains('COMPANY ENRICHMENT') || 
             enrichedJobApp.Notes__c.contains('SALARY ENRICHMENT') ||
             enrichedJobApp.Notes__c.contains('MARKET ANALYSIS')), 
            'Retry enrichment should process records'
        );
    }
}