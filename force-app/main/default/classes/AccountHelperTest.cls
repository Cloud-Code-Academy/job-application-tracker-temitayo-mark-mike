@IsTest
private class AccountHelperTest {
    
    @TestSetup
    static void setupData() {
                      
        List<Account> accList = new List<Account>();
        Account acc = new Account(Name = 'testEmployer');
        accList.add(acc);
        Account acc2 = new Account(Name = 'testEmployer2');
        accList.add(acc2);

        TriggerHandler.bypass('AccountTriggerHandler');
        insert accList;      
        TriggerHandler.clearBypass('AccountTriggerHandler');

        acc = [SELECT Id FROM Account WHERE Name = 'testEmployer2' LIMIT 1];
        Contact cont = new Contact(LastName = '<unknown_contact>', AccountId = acc2.Id);
        insert cont;
        
    }

    @IsTest
    static void testCreateACRForPrimaryContact() {
        
        Test.startTest();
        List<Account> accts = [SELECT Id, Name FROM Account LIMIT 1];
        AccountHelper.createACRForPrimaryContact(accts);
        Test.stopTest();       
        
        List<AccountContactRelation> acr = [SELECT Id, AccountId, Primary_Contact__c FROM AccountContactRelation WHERE AccountID = :accts[0].Id ];
        System.assertEquals(true, acr[0].Primary_Contact__c);

    }
}