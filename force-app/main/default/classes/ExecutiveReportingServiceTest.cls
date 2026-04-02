/**
 * @description Test class for ExecutiveReportingService
 * @author Test Suite
 * @date 2025
 */
@IsTest
private class ExecutiveReportingServiceTest {

    @TestSetup
    static void setupTestData() {
        List<Job_Application__c> apps = new List<Job_Application__c>();

        // Create applications with various statuses and dates
        apps.add(TestDataFactory.createJobApplication(
            'Tech Corp', 'Software Engineer', 'Applied', 120000, false
        ));
        apps[0].Application_Date__c = Date.today();

        apps.add(TestDataFactory.createJobApplication(
            'Data Inc', 'Data Analyst', 'Interviewed', 95000, false
        ));
        apps[1].Application_Date__c = Date.today().addDays(-10);

        apps.add(TestDataFactory.createJobApplication(
            'Cloud Co', 'Cloud Architect', 'Accepted', 180000, false
        ));
        apps[2].Application_Date__c = Date.today().addDays(-20);

        apps.add(TestDataFactory.createJobApplication(
            'AI Startup', 'ML Engineer', 'Rejected', 140000, false
        ));
        apps[3].Application_Date__c = Date.today().addDays(-5);

        apps.add(TestDataFactory.createJobApplication(
            'Finance Ltd', 'Backend Developer', 'Applied', 110000, false
        ));
        apps[4].Application_Date__c = Date.today().addDays(-45);

        insert apps;
    }

    @IsTest
    static void testGetExecutiveKPIs() {
        Test.startTest();
        Map<String, Object> kpis = ExecutiveReportingService.getExecutiveKPIs();
        Test.stopTest();

        System.assertNotEquals(null, kpis, 'KPIs should not be null');
        System.assert(kpis.containsKey('thisWeekApplications'),
            'Should contain thisWeekApplications');
        System.assert(kpis.containsKey('thisMonthApplications'),
            'Should contain thisMonthApplications');
        System.assert(kpis.containsKey('thisQuarterApplications'),
            'Should contain thisQuarterApplications');
        System.assert(kpis.containsKey('appliedCount'),
            'Should contain conversion funnel data');
        System.assert(kpis.containsKey('projectedMonthlyApplications'),
            'Should contain forecasting data');
    }

    @IsTest
    static void testGetMonthlyPerformanceReportWithParams() {
        Integer year = Date.today().year();
        Integer month = Date.today().month();

        Test.startTest();
        Map<String, Object> report =
            ExecutiveReportingService.getMonthlyPerformanceReport(year, month);
        Test.stopTest();

        System.assertNotEquals(null, report, 'Report should not be null');
        System.assert(report.containsKey('totalApplications'),
            'Should contain totalApplications');
        System.assert(report.containsKey('period'), 'Should contain period');
        System.assert(report.containsKey('startDate'), 'Should contain startDate');
        System.assert(report.containsKey('endDate'), 'Should contain endDate');
    }

    @IsTest
    static void testGetMonthlyPerformanceReportWithNullParams() {
        Test.startTest();
        Map<String, Object> report =
            ExecutiveReportingService.getMonthlyPerformanceReport(null, null);
        Test.stopTest();

        System.assertNotEquals(null, report, 'Report should not be null with null params');
        System.assert(report.containsKey('totalApplications'),
            'Should default to current month and contain totalApplications');
    }

    @IsTest
    static void testGetQuarterlyBusinessReview() {
        Integer year = Date.today().year();
        Integer quarter = ((Date.today().month() - 1) / 3) + 1;

        Test.startTest();
        Map<String, Object> qbr =
            ExecutiveReportingService.getQuarterlyBusinessReview(year, quarter);
        Test.stopTest();

        System.assertNotEquals(null, qbr, 'QBR should not be null');
        System.assert(qbr.containsKey('quarter'), 'Should contain quarter label');
        System.assert(qbr.containsKey('totalApplications'),
            'Should contain totalApplications');
        System.assert(qbr.containsKey('startDate'), 'Should contain startDate');
        System.assert(qbr.containsKey('endDate'), 'Should contain endDate');
        System.assert(qbr.containsKey('salaryTrends'), 'Should contain salaryTrends');
    }

    @IsTest
    static void testGetQuarterlyBusinessReviewWithNullParams() {
        Test.startTest();
        Map<String, Object> qbr =
            ExecutiveReportingService.getQuarterlyBusinessReview(null, null);
        Test.stopTest();

        System.assertNotEquals(null, qbr, 'QBR should not be null with null params');
        System.assert(qbr.containsKey('quarter'), 'Should default to current quarter');
    }

    @IsTest
    static void testEmptyDataScenario() {
        // Delete all test data
        delete [SELECT Id FROM Job_Application__c];

        Test.startTest();
        Map<String, Object> kpis = ExecutiveReportingService.getExecutiveKPIs();
        Map<String, Object> report =
            ExecutiveReportingService.getMonthlyPerformanceReport(
                Date.today().year(), Date.today().month()
            );
        Map<String, Object> qbr =
            ExecutiveReportingService.getQuarterlyBusinessReview(
                Date.today().year(), 1
            );
        Test.stopTest();

        System.assertNotEquals(null, kpis, 'KPIs should not be null even with no data');
        System.assertNotEquals(null, report, 'Report should not be null even with no data');
        System.assertEquals(0, report.get('totalApplications'),
            'Total applications should be 0 with no data');
        System.assertNotEquals(null, qbr, 'QBR should not be null even with no data');
    }

    @IsTest
    static void testConversionFunnelCalculations() {
        Test.startTest();
        Map<String, Object> kpis = ExecutiveReportingService.getExecutiveKPIs();
        Test.stopTest();

        // Verify conversion funnel keys exist
        System.assert(kpis.containsKey('appliedCount'),
            'Should have appliedCount in funnel');
        System.assert(kpis.containsKey('acceptedCount'),
            'Should have acceptedCount in funnel');
        System.assert(kpis.containsKey('overallSuccessRate'),
            'Should have overallSuccessRate');
        System.assert(kpis.containsKey('applicationToInterview'),
            'Should have applicationToInterview rate');
    }
}
