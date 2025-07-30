@IsTest
private class JobTriggerHandlerTest {
    
    @TestSetup
    static void setupData() {
              
        List<Account> accList = new List<Account>();
        Account acc = new Account(Name = 'testEmployer');
        accList.add(acc);
        
        TriggerHandler.bypass('AccountTriggerHandler');
        insert accList;      
        TriggerHandler.clearBypass('AccountTriggerHandler');
        
        Contact cont = new Contact(LastName = 'testPrimCont');
        insert cont;
        
    }
      
    @IsTest 
    static void testJobTriggerHandlerInsert() {
        
        Job__c job = new Job__c();
        job.Name = 'testJob';
        
        Account employer = [SELECT Id FROM Account LIMIT 1];
        job.Employer__c = employer.Id;

        Contact cont = [SELECT Id FROM Contact LIMIT 1];
        job.Primary_Contact__c = cont.Id;
                
        Test.startTest();
        insert job;
        System.assertEquals(true, job.IsCreated__c);
        Test.stopTest();    

    }

}