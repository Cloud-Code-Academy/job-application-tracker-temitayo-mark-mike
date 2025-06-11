@isTest
private class StaleJobAppSchedulerTest {
    @isTest
    static void testSchedulerRuns() {
        Test.startTest();
        String cron = '0 0 1 ? * MON';
        System.schedule('Test Schedule', cron, new StaleJobAppScheduler());
        Test.stopTest();
    }
}
