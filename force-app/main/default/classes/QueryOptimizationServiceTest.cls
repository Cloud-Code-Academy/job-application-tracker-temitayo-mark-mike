/**
 * @description Test class for QueryOptimizationService
 * @author Test Suite
 * @date 2025
 */
@IsTest
private class QueryOptimizationServiceTest {

    @TestSetup
    static void setupTestData() {
        List<Job_Application__c> apps = new List<Job_Application__c>();
        apps.add(TestDataFactory.createJobApplication(
            'Alpha Corp', 'Engineer', 'Applied', 100000, false
        ));
        apps.add(TestDataFactory.createJobApplication(
            'Alpha Corp', 'Senior Engineer', 'Interviewed', 130000, false
        ));
        apps.add(TestDataFactory.createJobApplication(
            'Beta Inc', 'Developer', 'Applied', 95000, false
        ));
        apps.add(TestDataFactory.createJobApplication(
            'Gamma Ltd', 'Architect', 'Accepted', 160000, false
        ));
        insert apps;

        // Create tasks for relationship query tests
        List<Task> tasks = new List<Task>();
        for (Job_Application__c app : apps) {
            tasks.add(TestDataFactory.createTask(app.Id, 'Follow up', 'Normal', 'Not Started', false));
        }
        insert tasks;
    }

    @IsTest
    static void testCompareQueryPatterns() {
        Test.startTest();
        Map<String, Object> results =
            QueryOptimizationService.compareQueryPatterns(100);
        Test.stopTest();

        System.assertNotEquals(null, results, 'Results should not be null');
        System.assert(results.containsKey('inefficientQuery'),
            'Should contain inefficient query results');
        System.assert(results.containsKey('efficientQuery'),
            'Should contain efficient query results');
        System.assert(results.containsKey('indexedQuery'),
            'Should contain indexed query results');
        System.assert(results.containsKey('optimizationGains'),
            'Should contain optimization gains');
    }

    @IsTest
    static void testGetBulkApplicationDataWithValidCompanies() {
        List<String> companyNames = new List<String>{ 'Alpha Corp', 'Beta Inc' };

        Test.startTest();
        Map<String, List<Job_Application__c>> results =
            QueryOptimizationService.getBulkApplicationData(companyNames);
        Test.stopTest();

        System.assertNotEquals(null, results, 'Results should not be null');
        System.assert(results.containsKey('Alpha Corp'),
            'Should contain Alpha Corp results');
        System.assertEquals(2, results.get('Alpha Corp').size(),
            'Alpha Corp should have 2 applications');
        System.assert(results.containsKey('Beta Inc'),
            'Should contain Beta Inc results');
        System.assertEquals(1, results.get('Beta Inc').size(),
            'Beta Inc should have 1 application');
    }

    @IsTest
    static void testGetBulkApplicationDataWithEmptyList() {
        Test.startTest();
        Map<String, List<Job_Application__c>> results =
            QueryOptimizationService.getBulkApplicationData(new List<String>());
        Test.stopTest();

        System.assertNotEquals(null, results, 'Results should not be null');
        System.assert(results.isEmpty(), 'Results should be empty for empty input');
    }

    @IsTest
    static void testGetBulkApplicationDataWithNull() {
        Test.startTest();
        Map<String, List<Job_Application__c>> results =
            QueryOptimizationService.getBulkApplicationData(null);
        Test.stopTest();

        System.assertNotEquals(null, results, 'Results should not be null');
        System.assert(results.isEmpty(), 'Results should be empty for null input');
    }

    @IsTest
    static void testGetAggregatedStatistics() {
        Test.startTest();
        Map<String, Object> results =
            QueryOptimizationService.getAggregatedStatistics(365);
        Test.stopTest();

        System.assertNotEquals(null, results, 'Results should not be null');
        System.assert(results.containsKey('statusBreakdown'),
            'Should contain statusBreakdown');
        System.assert(results.containsKey('totalApplications'),
            'Should contain totalApplications');
        System.assert(results.containsKey('overallAverageSalary'),
            'Should contain overallAverageSalary');
        System.assertEquals(365, results.get('dateRange'),
            'dateRange should match input');
    }

    @IsTest
    static void testGetRelatedTasks() {
        List<Job_Application__c> apps = [SELECT Id FROM Job_Application__c];
        List<Id> appIds = new List<Id>();
        for (Job_Application__c app : apps) {
            appIds.add(app.Id);
        }

        Test.startTest();
        Map<Id, List<Task>> results =
            QueryOptimizationService.getRelatedTasks(appIds);
        Test.stopTest();

        System.assertNotEquals(null, results, 'Results should not be null');
        System.assert(!results.isEmpty(), 'Should find tasks for the applications');
        for (Id appId : results.keySet()) {
            System.assert(!results.get(appId).isEmpty(),
                'Each application should have at least one task');
        }
    }

    @IsTest
    static void testGetRelatedTasksEmptyInput() {
        Test.startTest();
        Map<Id, List<Task>> results =
            QueryOptimizationService.getRelatedTasks(new List<Id>());
        Test.stopTest();

        System.assert(results.isEmpty(), 'Should return empty map for empty input');
    }

    @IsTest
    static void testGetDynamicFilteredApplications() {
        Map<String, Object> filters = new Map<String, Object>{
            'Status__c' => 'Applied'
        };

        Test.startTest();
        List<Job_Application__c> results =
            QueryOptimizationService.getDynamicFilteredApplications(
                filters, 'Application_Date__c', 'DESC', 50
            );
        Test.stopTest();

        System.assertNotEquals(null, results, 'Results should not be null');
        for (Job_Application__c app : results) {
            System.assertEquals('Applied', app.Status__c,
                'All results should have Applied status');
        }
    }

    @IsTest
    static void testGetDynamicFilteredApplicationsNoFilters() {
        Test.startTest();
        List<Job_Application__c> results =
            QueryOptimizationService.getDynamicFilteredApplications(
                null, 'Company_Name__c', 'ASC', 100
            );
        Test.stopTest();

        System.assertNotEquals(null, results, 'Results should not be null');
        System.assert(results.size() > 0, 'Should return all records with no filter');
    }

    @IsTest
    static void testGetPaginatedApplications() {
        Test.startTest();
        QueryOptimizationService.PaginationResult result =
            QueryOptimizationService.getPaginatedApplications(2, 1, 'Application_Date__c');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Pagination result should not be null');
        System.assert(result.records.size() <= 2,
            'Page should have at most 2 records');
        System.assert(result.totalRecords >= 4,
            'Total records should be at least 4');
        System.assertEquals(1, result.currentPage, 'Current page should be 1');
        System.assertEquals(2, result.pageSize, 'Page size should be 2');
        System.assert(result.hasNext, 'Should have next page');
        System.assert(!result.hasPrevious, 'First page should have no previous');
    }

    @IsTest
    static void testGetPaginatedApplicationsSecondPage() {
        Test.startTest();
        QueryOptimizationService.PaginationResult result =
            QueryOptimizationService.getPaginatedApplications(2, 2, null);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Pagination result should not be null');
        System.assertEquals(2, result.currentPage, 'Current page should be 2');
        System.assert(result.hasPrevious, 'Second page should have previous');
    }

    @IsTest
    static void testMonitorQueryPerformance() {
        Test.startTest();
        QueryOptimizationService.QueryPerformanceMetrics metrics =
            QueryOptimizationService.monitorQueryPerformance('BULK_QUERY', 100);
        Test.stopTest();

        System.assertNotEquals(null, metrics, 'Metrics should not be null');
        System.assertEquals('BULK_QUERY', metrics.queryType,
            'Query type should match');
        System.assertEquals(100, metrics.recordCount,
            'Record count should match');
        System.assertNotEquals(null, metrics.executionTime,
            'Execution time should be set');
        System.assertNotEquals(null, metrics.cpuTimeUsed,
            'CPU time used should be set');
    }
}
