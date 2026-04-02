/**
 * @description Test class for PerformanceOptimizationService
 * @author Test Suite
 * @date 2025
 */
@IsTest
private class PerformanceOptimizationServiceTest {

    @TestSetup
    static void setupTestData() {
        List<Job_Application__c> apps = TestDataFactory.createJobApplications(5, 'Applied', true);
    }

    @IsTest
    static void testGetPerformanceMetrics() {
        Test.startTest();
        Map<String, Object> metrics =
            PerformanceOptimizationService.getPerformanceMetrics();
        Test.stopTest();

        System.assertNotEquals(null, metrics, 'Metrics should not be null');
        System.assert(metrics.containsKey('currentCpuTime'),
            'Should contain system metrics');
        System.assert(metrics.containsKey('totalJobApplications'),
            'Should contain data volume metrics');
        System.assert(metrics.containsKey('recommendations'),
            'Should contain recommendations');
        System.assert(metrics.containsKey('dataSource'),
            'Should contain dataSource indicator');
    }

    @IsTest
    static void testOptimizeValidQuery() {
        String queryString = 'SELECT Id, Name FROM Job_Application__c WHERE Status__c = \'Applied\' LIMIT 100';

        Test.startTest();
        Map<String, Object> result =
            PerformanceOptimizationService.optimizeQuery(queryString);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Optimization result should not be null');
        System.assert(result.containsKey('hasWhereClause'),
            'Should analyze WHERE clause presence');
        System.assert(result.containsKey('hasLimit'),
            'Should analyze LIMIT clause presence');
        System.assert(result.containsKey('antiPatterns'),
            'Should contain anti-pattern analysis');
        System.assert(result.containsKey('suggestions'),
            'Should contain optimization suggestions');
        System.assert(result.containsKey('performanceImpact'),
            'Should contain performance impact estimate');
    }

    @IsTest
    static void testOptimizeBlankQuery() {
        Test.startTest();
        try {
            PerformanceOptimizationService.optimizeQuery('');
            System.assert(false, 'Should have thrown AuraHandledException for blank query');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('empty') || e.getMessage().contains('Query'),
                'Exception should mention empty query');
        }
        Test.stopTest();
    }

    @IsTest
    static void testOptimizeLongQuery() {
        // Build a query string exceeding 10000 characters
        String longQuery = 'SELECT Id FROM Job_Application__c WHERE ';
        while (longQuery.length() < 10001) {
            longQuery += 'Company_Name__c = \'SomeReallyLongCompanyName\' OR ';
        }

        Test.startTest();
        try {
            PerformanceOptimizationService.optimizeQuery(longQuery);
            System.assert(false, 'Should have thrown AuraHandledException for long query');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('length') || e.getMessage().contains('maximum'),
                'Exception should mention query length');
        }
        Test.stopTest();
    }

    @IsTest
    static void testOptimizeBulkProcessing() {
        List<Job_Application__c> apps = [SELECT Id FROM Job_Application__c];
        List<Id> recordIds = new List<Id>();
        for (Job_Application__c app : apps) {
            recordIds.add(app.Id);
        }

        Test.startTest();
        Map<String, Object> result =
            PerformanceOptimizationService.optimizeBulkProcessing(recordIds, 'UPDATE');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Bulk processing result should not be null');
        System.assert(result.containsKey('totalRecords'), 'Should contain totalRecords');
        System.assert(result.containsKey('processedRecords'),
            'Should contain processedRecords');
        System.assert(result.containsKey('batchCount'), 'Should contain batchCount');
        System.assert(result.containsKey('optimalBatchSize'),
            'Should contain optimalBatchSize');
        System.assert(result.containsKey('processingTimeMs'),
            'Should contain processingTimeMs');
        System.assert(result.containsKey('successRate'), 'Should contain successRate');
        System.assertEquals(recordIds.size(), result.get('totalRecords'),
            'Total records should match input');
    }

    @IsTest
    static void testMonitorPerformance() {
        Test.startTest();
        Map<String, Object> monitoring =
            PerformanceOptimizationService.monitorPerformance('testOperation');
        Test.stopTest();

        System.assertNotEquals(null, monitoring, 'Monitoring data should not be null');
        System.assert(monitoring.containsKey('cpuTime'), 'Should contain cpuTime');
        System.assert(monitoring.containsKey('cpuTimeLimit'),
            'Should contain cpuTimeLimit');
        System.assert(monitoring.containsKey('heapSize'), 'Should contain heapSize');
        System.assert(monitoring.containsKey('soqlQueries'), 'Should contain soqlQueries');
        System.assert(monitoring.containsKey('dmlStatements'),
            'Should contain dmlStatements');
        System.assert(monitoring.containsKey('performanceStatus'),
            'Should contain performanceStatus');
        System.assertEquals('testOperation', monitoring.get('operationName'),
            'Operation name should match');
        System.assert(monitoring.containsKey('warnings'),
            'Should contain performance warnings');
    }

    @IsTest
    static void testQueryAntiPatternDetection() {
        // Query with anti-patterns: SELECT *, no WHERE, no LIMIT
        String badQuery = 'SELECT * FROM Job_Application__c';

        Test.startTest();
        Map<String, Object> result =
            PerformanceOptimizationService.optimizeQuery(badQuery);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        List<String> antiPatterns = (List<String>) result.get('antiPatterns');
        System.assert(antiPatterns != null && !antiPatterns.isEmpty(),
            'Should detect anti-patterns in bad query');

        Boolean hasSelectStar = (Boolean) result.get('hasSelectStar');
        System.assert(hasSelectStar, 'Should detect SELECT * anti-pattern');
    }
}
