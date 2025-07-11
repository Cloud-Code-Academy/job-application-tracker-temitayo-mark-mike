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
 
    public override void beforeInsert() {
        //AccountHelper.testAccountMethod(acctTriggerNew);
    }

    public override void afterInsert() {
    }

    public override void beforeUpdate() {
       //AccountHelper.testAccountMethod(acctTriggerNew);
    }

    public override void beforeDelete() {
    }

    public override void afterDelete() {
    }

    public override void afterUndelete() {     
    }
}