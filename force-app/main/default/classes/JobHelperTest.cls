@IsTest
private class JobHelperTest {
    
    @TestSetup
    static void setupData(){
        
        List<Account> accList = new List<Account>();
        Account acc = new Account(Name = 'testEmployer');
        accList.add(acc);
        
        TriggerHandler.bypass('AccountTriggerHandler');
        insert accList;      
        TriggerHandler.clearBypass('AccountTriggerHandler');
        
        Contact cont = new Contact(LastName = '<unknown_contact>', AccountId = accList[0].Id);
        insert cont;

    }
    
    
    
    @IsTest
    static void getJoobleResponseFromMock() {

        Map<String, String> JoobleKeywordsMap = new Map<String,String>{
            'keywords' => 'Salesforce developer',
            'location' => 'Des Moines, Iowa',
            'salary' => '70000',
            'datecreatedfrom' => '2023-01-01',
            'companysearch' => 'false'
        };
        
        Test.setMock(HttpCalloutMock.class, new JoobleJSONCalloutMockGenerator());

        Test.startTest();
        JobHelper.JoobleCallout(JSON.serialize(JoobleKeywordsMap));
        Test.stopTest();

        Account acc = [SELECT Id, Name FROM Account WHERE Name != 'testEmployer'];
        System.assertEquals('Principal Financial Group', acc.Name);
        Job__c job = [SELECT Id, Name, Employer__r.Name FROM Job__c];
        System.assertEquals('Principal Financial Group', job.Employer__r.Name);
        System.assertEquals('TESTSalesforce Developer (Hybrid)', job.Name);

    } 

}