public with sharing class AccountHelper {
    
    @TestVisible
    public static void createACRForPrimaryContact(List<Account> acctTriggerNew) {
        Contact defaultPrimaryContact = Utilities.getDefaultPrimaryContact();
        List<AccountContactRelation> newACRs = new List<AccountContactRelation>();
        for (Account acc : acctTriggerNew) {
            AccountContactRelation newACR = new AccountContactRelation();
            newACR.AccountId = acc.Id;
            newACR.ContactId = defaultPrimaryContact.Id;
            newACR.Roles = 'Other';
            newACR.Primary_Contact__c = true;
            newACRs.add(newACR);
        }
        Id batchId = Utilities.batchUpsert(newACRs, 20);
    }

}