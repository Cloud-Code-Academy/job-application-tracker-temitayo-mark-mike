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
 
    public override void afterInsert() {
       List<String> userStringAfterInsert = Utilities.updateErrorEmailInOrgPart();
    }

    public override void afterUpdate() {
        List<String> userStringAfterUpdate = Utilities.updateErrorEmailInOrgPart();  
    }

}