@IsTest
private class JobApplicationTaskTriggerHandlerTest {
    
    static void testGetJpbAppTasks() {

        List<Job_Application_Task__c> jaTasks = new List<Job_Application_Task__c>();
        Job_Application_Task__c jaTask = new Job_Application_Task__c();
        jaTask.Active__c = true;
        jaTask.Job_Appl_Status__c = 'Saved';
        jaTask.Task_Subject__c = 'Task1';
        jaTask.Task_Comment__c = 'Task1';
        jaTask.Task_Priority__c = 'High';
        jaTasks.add(jaTask);

        insert jaTask;
        List<Job_Application_Task__c> jaTaskFromCache = [SELECT Id, Task_Comment__c FROM Job_Application_Task__c];
        System.assertEquals(1, jaTaskFromCache.size());

        jaTaskFromCache[0].Task_Comment__c = 'updated';
        update jaTaskFromCache;
        jaTaskFromCache = Utilities.getJobAppTasks();
        System.assert(jaTaskFromCache[0].Task_Comment__c == 'updated');

        delete jaTaskFromCache;
        jaTaskFromCache = Utilities.getJobAppTasks();
        System.assert(jaTaskFromCache.size() == 0);

    }
}