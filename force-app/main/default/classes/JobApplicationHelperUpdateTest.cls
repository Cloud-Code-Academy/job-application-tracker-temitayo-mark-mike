@IsTest
private class JobApplicationHelperUpdateTest {
    
    @TestSetup
    static void setupData() {
                      
        List<Account> accList = new List<Account>();
        Account accs = new Account(Name = 'testEmployer');
        accList.add(accs);
       
        TriggerHandler.bypass('AccountTriggerHandler');
        insert accList;      
        TriggerHandler.clearBypass('AccountTriggerHandler');

        accs = [SELECT Id FROM Account LIMIT 1];
        Contact cont = new Contact(LastName = '<unknown_contact>', AccountId = accs.Id);
        insert cont;
    
        Account acc = [SELECT Id FROM Account];
        Contact con = [SELECT Id FROM Contact];
    
        Job__c job = new Job__c();
        job.Employer__c = acc.Id;
        job.Primary_Contact__c = con.Id;
        job.JoobleId__c = '12345';
        insert job;

        List<Job_Application_Task__c> jaTasks = new List<Job_Application_Task__c>();
        Job_Application_Task__c jaTask = new Job_Application_Task__c();
        jaTask.Active__c = true;
        jaTask.Job_Appl_Status__c = 'Saved';
        jaTask.Task_Subject__c = 'Task1';
        jaTask.Task_Comment__c = 'Task1';
        jaTask.Task_Priority__c = 'High';
        jaTasks.add(jaTask);
        Job_Application_Task__c jaTask2 = new Job_Application_Task__c();
        jaTask2.Active__c = true;
        jaTask2.Job_Appl_Status__c = 'Applying';
        jaTask2.Task_Subject__c = 'Task2';
        jaTask2.Task_Comment__c = 'Task2';
        jaTask2.Task_Priority__c = 'High';
        jaTasks.add(jaTask2);  
        insert jaTasks;

        System.debug(JSON.serializePretty(jaTasks)); 
         
        Job_Application__c jobApp = new Job_Application__c();
        jobApp.Job__c = job.Id;
        insert jobApp;

    }
    
    @IsTest
    static void testProcessJobAppTasksAfterUpdate() {

        Test.startTest();   
       
        Job_Application__c ja = [SELECT Id, Status__c FROM Job_Application__c];
                
        List<Task> tasks = [SELECT Id FROM Task WHERE WhatId = :ja.Id];
        System.debug('Before update: ' + JSON.serializePretty(tasks));
        Integer createSize = tasks.size();
        
        System.debug('ja before update: ' + JSON.serializePretty(ja));
        ja.Status__c = 'Applying';
        System.debug('ja after change: ' + JSON.serializePretty(ja));
        
        update ja;  
        
        Test.stopTest();

        System.debug('ja before update: ' + JSON.serializePretty(ja));
        tasks = [SELECT Id FROM Task WHERE WhatId = :ja.Id];
        System.debug('After update: ' + JSON.serializePretty(tasks));
        
        System.assertNotEquals(createSize, tasks.size());

    }
    
    

    
}