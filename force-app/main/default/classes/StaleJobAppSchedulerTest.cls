@IsTest
private class StaleJobAppSchedulerTest {
    @IsTest
    static void testSchedulerRuns() {
        // Start test execution
        Test.startTest();

        // Schedule the job to run at a specific time
        String cron = '0 0 1 ? * MON';
        System.schedule('Test Schedule', cron, new StaleJobAppScheduler());

        // Stop test execution
        Test.stopTest();
    }
}