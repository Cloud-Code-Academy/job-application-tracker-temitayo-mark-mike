/**
 * @description Test class for ApplicationAnalyticsService
 * @author Temitayo Oluwalade
 * @date 2024
 */
@isTest
public class ApplicationAnalyticsServiceTest {
    
    /**
     * @description Test data setup
     */
    @TestSetup
    static void setupTestData() {
        // Create test job applications with various statuses
        List<Job_Application__c> testApps = new List<Job_Application__c>();
        
        // Applied status applications
        for (Integer i = 0; i < 5; i++) {
            testApps.add(new Job_Application__c(
                Company_Name__c = 'Test Company ' + i,
                Position_Title__c = 'Software Engineer ' + i,
                Status__c = 'Applied',
                Application_Date__c = Date.today().addDays(-i),
                Salary__c = 100000 + (i * 5000)
            ));
        }
        
        // Interviewing status applications
        for (Integer i = 0; i < 3; i++) {
            testApps.add(new Job_Application__c(
                Company_Name__c = 'Interview Company ' + i,
                Position_Title__c = 'Product Manager ' + i,
                Status__c = 'Interviewing',
                Application_Date__c = Date.today().addDays(-i - 5),
                Salary__c = 120000 + (i * 10000)
            ));
        }
        
        // Negotiating status applications
        testApps.add(new Job_Application__c(
            Company_Name__c = 'Negotiation Corp',
            Position_Title__c = 'Senior Developer',
            Status__c = 'Negotiating',
            Application_Date__c = Date.today().addDays(-10),
            Salary__c = 150000
        ));
        
        // Accepted status applications
        testApps.add(new Job_Application__c(
            Company_Name__c = 'Success Company',
            Position_Title__c = 'Lead Engineer',
            Status__c = 'Accepted',
            Application_Date__c = Date.today().addDays(-15),
            Salary__c = 160000
        ));
        
        // Closed status applications
        for (Integer i = 0; i < 2; i++) {
            testApps.add(new Job_Application__c(
                Company_Name__c = 'Closed Company ' + i,
                Position_Title__c = 'Developer ' + i,
                Status__c = 'Closed',
                Application_Date__c = Date.today().addDays(-i - 20),
                Salary__c = 90000 + (i * 5000)
            ));
        }
        
        insert testApps;
    }
    
    /**
     * @description Test getApplicationAnalytics method
     */
    @isTest
    static void testGetApplicationAnalytics() {
        Test.startTest();
        
        Map<String, Object> analytics = ApplicationAnalyticsService.getApplicationAnalytics();
        
        Test.stopTest();
        
        // Verify basic metrics
        System.assertNotEquals(null, analytics, 'Analytics should not be null');
        System.assertEquals(12, (Integer)analytics.get('totalApplications'), 'Should have 12 total applications');
        System.assertEquals(10, (Integer)analytics.get('activeApplications'), 'Should have 10 active applications');
        
        // Verify interview rate calculation
        Decimal interviewRate = (Decimal)analytics.get('interviewRate');
        System.assert(interviewRate > 0, 'Interview rate should be greater than 0');
        
        // Verify success rate calculation
        Decimal successRate = (Decimal)analytics.get('successRate');
        System.assert(successRate > 0, 'Success rate should be greater than 0');
        
        // Verify status breakdown
        List<Object> statusBreakdown = (List<Object>)analytics.get('statusBreakdown');
        System.assertNotEquals(null, statusBreakdown, 'Status breakdown should not be null');
        System.assert(statusBreakdown.size() > 0, 'Status breakdown should have data');
        
        // Verify recent activity
        List<Object> recentActivity = (List<Object>)analytics.get('recentActivity');
        System.assertNotEquals(null, recentActivity, 'Recent activity should not be null');
        System.assert(recentActivity.size() <= 5, 'Recent activity should have max 5 items');
        
        // Verify pipeline data
        List<Object> pipeline = (List<Object>)analytics.get('pipeline');
        System.assertNotEquals(null, pipeline, 'Pipeline should not be null');
        System.assertEquals(5, pipeline.size(), 'Pipeline should have 5 stages');
        
        // Verify salary analytics
        System.assert(analytics.containsKey('averageSalary'), 'Should contain average salary');
        System.assert(analytics.containsKey('highestSalary'), 'Should contain highest salary');
        System.assert(analytics.containsKey('minSalary'), 'Should contain min salary');
        System.assert(analytics.containsKey('maxSalary'), 'Should contain max salary');
    }
    
    /**
     * @description Test getApplicationTrends method
     */
    @isTest
    static void testGetApplicationTrends() {
        Test.startTest();
        
        List<Map<String, Object>> trends = ApplicationAnalyticsService.getApplicationTrends(6);
        
        Test.stopTest();
        
        System.assertNotEquals(null, trends, 'Trends should not be null');
        // Trends might be empty if no applications in the timeframe, which is valid
    }
    
    /**
     * @description Test getApplicationTrends with null parameter
     */
    @isTest
    static void testGetApplicationTrendsWithNullParameter() {
        Test.startTest();
        
        List<Map<String, Object>> trends = ApplicationAnalyticsService.getApplicationTrends(null);
        
        Test.stopTest();
        
        System.assertNotEquals(null, trends, 'Trends should not be null even with null parameter');
    }
    
    /**
     * @description Test getPerformanceMetrics method
     */
    @isTest
    static void testGetPerformanceMetrics() {
        Date startDate = Date.today().addMonths(-1);
        Date endDate = Date.today();
        
        Test.startTest();
        
        Map<String, Object> metrics = ApplicationAnalyticsService.getPerformanceMetrics(startDate, endDate);
        
        Test.stopTest();
        
        System.assertNotEquals(null, metrics, 'Metrics should not be null');
        System.assert(metrics.containsKey('totalApplications'), 'Should contain total applications');
        System.assert(metrics.containsKey('interviewRate'), 'Should contain interview rate');
        System.assert(metrics.containsKey('successRate'), 'Should contain success rate');
        System.assert(metrics.containsKey('averageResponseTime'), 'Should contain average response time');
    }
    
    /**
     * @description Test getPerformanceMetrics with null dates
     */
    @isTest
    static void testGetPerformanceMetricsWithNullDates() {
        Test.startTest();
        
        Map<String, Object> metrics = ApplicationAnalyticsService.getPerformanceMetrics(null, null);
        
        Test.stopTest();
        
        System.assertNotEquals(null, metrics, 'Metrics should not be null with null dates');
    }
    
    /**
     * @description Test analytics with no data
     */
    @isTest
    static void testAnalyticsWithNoData() {
        // Delete all test data
        delete [SELECT Id FROM Job_Application__c];
        
        Test.startTest();
        
        Map<String, Object> analytics = ApplicationAnalyticsService.getApplicationAnalytics();
        
        Test.stopTest();
        
        // Verify empty state handling
        System.assertEquals(0, (Integer)analytics.get('totalApplications'), 'Should have 0 total applications');
        System.assertEquals(0, (Integer)analytics.get('activeApplications'), 'Should have 0 active applications');
        System.assertEquals(0, (Decimal)analytics.get('interviewRate'), 'Interview rate should be 0');
        System.assertEquals(0, (Decimal)analytics.get('successRate'), 'Success rate should be 0');
        
        // Verify salary analytics with no data
        System.assertEquals(0, (Decimal)analytics.get('averageSalary'), 'Average salary should be 0');
        System.assertEquals(0, (Decimal)analytics.get('highestSalary'), 'Highest salary should be 0');
    }
    
    /**
     * @description Test salary calculations
     */
    @isTest
    static void testSalaryCalculations() {
        Test.startTest();
        
        Map<String, Object> analytics = ApplicationAnalyticsService.getApplicationAnalytics();
        
        Test.stopTest();
        
        // Verify salary calculations
        Decimal averageSalary = (Decimal)analytics.get('averageSalary');
        Decimal highestSalary = (Decimal)analytics.get('highestSalary');
        Decimal minSalary = (Decimal)analytics.get('minSalary');
        Decimal maxSalary = (Decimal)analytics.get('maxSalary');
        
        System.assert(averageSalary > 0, 'Average salary should be greater than 0');
        System.assert(highestSalary >= averageSalary, 'Highest salary should be >= average');
        System.assert(minSalary <= averageSalary, 'Min salary should be <= average');
        System.assertEquals(highestSalary, maxSalary, 'Highest and max salary should be equal');
    }
    
    /**
     * @description Test status breakdown calculations
     */
    @isTest
    static void testStatusBreakdown() {
        Test.startTest();
        
        Map<String, Object> analytics = ApplicationAnalyticsService.getApplicationAnalytics();
        
        Test.stopTest();
        
        List<Object> statusBreakdown = (List<Object>)analytics.get('statusBreakdown');
        
        // Verify we have status data
        System.assert(statusBreakdown.size() > 0, 'Should have status breakdown data');
        
        // Verify structure of status breakdown
        Map<String, Object> firstStatus = (Map<String, Object>)statusBreakdown[0];
        System.assert(firstStatus.containsKey('label'), 'Status should have label');
        System.assert(firstStatus.containsKey('count'), 'Status should have count');
        
        // Verify counts add up to total
        Integer totalFromBreakdown = 0;
        for (Object statusObj : statusBreakdown) {
            Map<String, Object> status = (Map<String, Object>)statusObj;
            totalFromBreakdown += (Integer)status.get('count');
        }
        
        System.assertEquals(
            (Integer)analytics.get('totalApplications'), 
            totalFromBreakdown, 
            'Status breakdown counts should equal total applications'
        );
    }
    
    /**
     * @description Test pipeline data structure
     */
    @isTest
    static void testPipelineData() {
        Test.startTest();
        
        Map<String, Object> analytics = ApplicationAnalyticsService.getApplicationAnalytics();
        
        Test.stopTest();
        
        List<Object> pipeline = (List<Object>)analytics.get('pipeline');
        
        // Verify pipeline structure
        System.assertEquals(5, pipeline.size(), 'Pipeline should have 5 stages');
        
        List<String> expectedStages = new List<String>{'Applied', 'Interviewing', 'Negotiating', 'Accepted', 'Closed'};
        
        for (Integer i = 0; i < pipeline.size(); i++) {
            Map<String, Object> stage = (Map<String, Object>)pipeline[i];
            
            System.assertEquals(expectedStages[i], stage.get('name'), 'Stage name should match expected order');
            System.assert(stage.containsKey('count'), 'Stage should have count');
            System.assert(stage.containsKey('applications'), 'Stage should have applications');
            
            List<Object> applications = (List<Object>)stage.get('applications');
            System.assertNotEquals(null, applications, 'Applications list should not be null');
        }
    }
    
    /**
     * @description Test recent activity data
     */
    @isTest
    static void testRecentActivity() {
        Test.startTest();
        
        Map<String, Object> analytics = ApplicationAnalyticsService.getApplicationAnalytics();
        
        Test.stopTest();
        
        List<Object> recentActivity = (List<Object>)analytics.get('recentActivity');
        
        // Verify recent activity structure
        System.assert(recentActivity.size() <= 5, 'Recent activity should have max 5 items');
        
        if (!recentActivity.isEmpty()) {
            Map<String, Object> firstActivity = (Map<String, Object>)recentActivity[0];
            
            System.assert(firstActivity.containsKey('id'), 'Activity should have id');
            System.assert(firstActivity.containsKey('title'), 'Activity should have title');
            System.assert(firstActivity.containsKey('subtitle'), 'Activity should have subtitle');
            System.assert(firstActivity.containsKey('status'), 'Activity should have status');
            System.assert(firstActivity.containsKey('lastModified'), 'Activity should have lastModified');
        }
    }
}
