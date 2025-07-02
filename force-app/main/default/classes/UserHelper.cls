public with sharing class UserHelper {
    
    // **********************************************************************************************************
    // BEFORE_INSERT
    public static void processInsertedUserForErrorEmail(List<User> userTriggerNew) {
        

        List<Profile> sysAdminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        List<User> usersForErrorEmail = new List<User>();
        for (User usr : userTriggerNew) {
            if (usr.IsErrorEmailRecipient__c == true || usr.ProfileId == sysAdminProfile[0].Id) {
                usersForErrorEmail.add(usr);
            }
        }
        if (usersForErrorEmail.size() > 0) {
           List<String> listErrorUsers = Utilities.updateErrorEmailInOrgPart(usersForErrorEmail); 
        }
        
    }

    // **********************************************************************************************************
    // BEFORE_UPDATE
    public static void processUpdatedUserForErrorEmail(List<User> userTriggerOld, Map<Id,User> userTriggerNewMap) {
        List<User> usersUpdatedForErrorEmail = new List<User>();
        // Loop thru userTriggerOld List and compare Profile change and IsErrorEmailRecipient__c change
        // If User record has changed && the User should recieve the ErrorEmail then pass to updateErrorEmailInOrgPart

        if (usersUpdatedForErrorEmail.size() > 0) {
            List<String> listErrorUsers = Utilities.updateErrorEmailInOrgPart(usersUpdatedForErrorEmail); 
        }

    }
    
}