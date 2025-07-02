public class UserTriggerHandler extends TriggerHandler {
    
    private List<User> userTriggerNew;
    private List<User> userTriggerOld;
    private Map<Id,User> userTriggerNewMap;
    private Map<Id,User> UserTriggerOldMap;

    public UserTriggerHandler() {
        this.userTriggerNew = (List<User>) Trigger.new;
        this.userTriggerOld = (List<User>) Trigger.old;
        this.userTriggerNewMap = (Map<Id, User>) Trigger.newMap;
        this.userTriggerOldMap = (Map<Id, User>) Trigger.oldMap;
    }
 
    public override void beforeInsert() {
        userHelper.processInsertedUserForErrorEmail(userTriggerNew);
    }

    public override void afterInsert() {
    }

    public override void beforeUpdate() {
        //UserHelper.testUserMethod(acctTriggerNew);
    }

    public override void beforeDelete() {
    }

    public override void afterDelete() {
    }

    public override void afterUndelete() {     
    }
}