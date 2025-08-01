public class AccountTriggerHandler extends TriggerHandler {
    
    private List<Account> accountTriggerNew;
    private List<Account> accountTriggerOld;
    private Map<Id,Account> accountTriggerNewMap;
    private Map<Id,Account> accountTriggerOldMap;

    public AccountTriggerHandler() {
        this.accountTriggerNew = (List<Account>) Trigger.new;
        this.accountTriggerOld = (List<Account>) Trigger.old;
        this.accountTriggerNewMap = (Map<Id, Account>) Trigger.newMap;
        this.accountTriggerOldMap = (Map<Id, Account>) Trigger.oldMap;
    }
 
    public override void afterInsert() {
        Contact defaultPrimaryContact = Utilities.getDefaultPrimaryContact();
        List<AccountContactRelation> newACRs = new List<AccountContactRelation>();
        for (Account acc : (List<Account>) Trigger.new) {
            AccountContactRelation newACR = new AccountContactRelation();
            newACR.AccountId = acc.Id;
            newACR.ContactId = defaultPrimaryContact.Id;
            newACR.Roles = 'Other';
            newACR.Primary_Contact__c = true;
            newACRs.add(newACR);
        }
        Id batchId = Utilities.batchUpsert(newACRs, 20);
        
        //AccountHelper.createACRForPrimaryContact(Trigger.new);
    }

}