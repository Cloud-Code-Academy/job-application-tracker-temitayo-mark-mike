public with sharing class AccountHelper {
    
    public static void testAccountMethod(List<Account> acctTriggerOld) {
        System.debug('TriggerNew:' + JSON.serializePretty(acctTriggerOld));  
    }

}