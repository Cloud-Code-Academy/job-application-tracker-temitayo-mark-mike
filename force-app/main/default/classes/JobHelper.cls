public with sharing class JobHelper {
    
    @future(callout=true)
	public static void JoobleCallout(String strKeywordJSON) {
		
		Http joobleHttp = new Http();										

		HttpRequest joobleRequest = new HttpRequest();
		   
        JoobleAPIKey__mdt APIKeyMDT = JoobleAPIKey__mdt.getInstance('Jooble_API_Key');

        joobleRequest.setEndpoint('callout:JoobleNamedCred' + '/' + APIKeyMDT.API_KEY__c);                
        joobleRequest.setHeader('Content-Type', 'application/json');
        joobleRequest.setMethod('POST');										
        
        joobleRequest.setbody(strKeywordJSON);

		HttpResponse joobleResponse = joobleHttp.send(joobleRequest);			

		if (joobleResponse.getStatusCode() == 200) {	
			
            // Must remove 'over-escaped' \'s and extract "jobs" array from JSON response body
            String joobleResponseBody = joobleResponse.getBody().replaceAll('\"','"');
            Integer startPos = joobleResponseBody.indexOf('\"jobs\":[');
            Integer endPos = joobleResponseBody.indexOf('}]}');
            String jobArrayString = joobleResponseBody.substring(startPos+7, joobleResponseBody.length()-1);
            
            List<JoobleJob> joobleJobList = (List<JoobleJob>) JSON.deserialize(jobArrayString, List<JoobleJob>.class);

            //System.debug('joobleJobList: ' + JSON.serializePretty(joobleJobList));

            JoobleJobParser(joobleJobList);

		} else {
			System.debug('Response error code: ' + joobleResponse.getStatusCode());
		}

	}

    @TestVisible
    public static void JoobleJobParser(List<JoobleJob> jjList) {
    
        List<Account> existingAccounts = new List<Account>([SELECT Id, Name FROM Account WHERE RecordType.Name = 'Employer']);
        
        Set<String> existingAccountNames = new Set<String>(); // We need a Set<String> of unique Account Names to see if an Employer already exists.
        Map<String, Id> existingAccountNameToIdMap = new Map<String, Id>(); // Initialize a Map<String, Id> to use later to get AccountIds for Employer__c Lookup in Job__c.  
        for (Account acct : existingAccounts) {
            existingAccountNames.add(acct.Name);
            existingAccountNameToIdMap.put(acct.Name, acct.Id);
        }
        
        
        Set<String> newAccountNames = new Set<String>();
        for (JoobleJob jj : jjList) {
            if (!existingAccountNames.contains(jj.company)) {
                String unknownJJAccount = jj.company ?? '<unknown> (added: ' + String.valueOfGmt(System.now()) + ')';
                newAccountNames.add(unknownJJAccount);
                //Utilities.sendErrorEmail('JoobleJob JSON response has company = null', unknownJJAccount);
            } else {
                existingAccountNames.add(jj.company);
            }
        }
                
        if (newAccountNames.size() > 0) {
            
            List<Account> newAccounts = new List<Account>();
            for (String accName : newAccountNames) {
                Account newAcct = new Account();
                newAcct.Name = accName;
                newAcct.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Employer').getRecordTypeId();
                newAccounts.add(newAcct);
            }
           
            Boolean newAccountInsertsFailed = true; // Will stay false unless there are no errors in try block.  This enables testing of catch block too
            try {
                insert newAccounts;  // Cannot be done asynch becuase we need the new Account Ids.
                newAccountInsertsFailed = false;
                for (Account newAcct : newAccounts) {                    // Parse newAccounts into the Map<String, Id> that already has the existing Accounts
                    existingAccountNameToIdMap.put(newAcct.Name, newAcct.Id); 
                }
            } catch (DmlException dmlException) {
                String jjDMLError = 'ERROR: Insert of new Accounts for JoobleJob Companies failed. ' + DmlException.getMessage() + ', ' + DmlException.getLineNumber();
                System.debug(jjDMLError);
                //Utilities.sendErrorEmail('DML Error: could not insert new Accounts as Employers.', jjDMLError); 
            }

        }     
        
        // Make a Map<Id(AccountId), Id(ContactId)> from ACR sObj for ACR records where Primary_Contact__c = true
        Map<Id,Id> acrPrimContacts = new Map<Id,Id>();
        List<AccountContactRelation> acrList = [SELECT Id, AccountId, ContactId, Primary_Contact__c FROM AccountContactRelation WHERE Primary_Contact__c = true];
        for (AccountContactRelation acr : acrList) {
            acrPrimContacts.put(acr.AccountId, acr.ContactId);
        }
       
        // Build list of Job__c records to upsert based on List<JoobleJob>
        List<Job__c> joobleUpserts = new List<Job__c>();
        for (JoobleJob jJob : jjList) {
            
            if (jJob.company == null) {
                continue;
            } else {
                Job__c newJob = new Job__c();
                newJob.Name = jJob.title;
                newJob.Employer__c = existingAccountNameToIdMap.get(jJob.company);
                newJob.Primary_Contact__c = acrPrimContacts.get(existingAccountNameToIdMap.get(jJob.company)) ?? Utilities.getDefaultPrimaryContact().Id;
                newJob.Jooble_Location__c = jJob.location;
                newJob.Snippet__c = jJob.snippet;
                newJob.Jooble_Salary__c = jJob.salary;
                newJob.Jooble_Source__c = jJob.source;
                newJob.Jooble_Type__c = jJob.type;
                newJob.Link__c = jJob.link;
                newJob.Last_Updated__c = Date.valueOf(jJob.updated);
                newJob.JoobleId__c = jJob.id;
                newJob.Imported_from_Jooble__c = true;
                joobleUpserts.add(newJob);
            }
                       
        }

        // There is an issue the Utilities.batchUpsert() method.  This callout is @future so the JoobleParser() is too.  
        // The Utilities.batchUpsert() detects System.isFuture() and kicks it over to a queueable - which is failing.
        // Utilities.batchUpsert(joobleUpserts, 200);  //TODO call Utilities.BatchUpsert();
        upsert joobleUpserts JoobleId__c;  // reference to externalId field 
        
        return;

    }      

    @TestVisible
    public class JoobleJob {
        public String title;
        public String location;
        public String snippet;
        public String salary;
        public String source;
        public String type;
        public String link;
        public String company;
        public String updated;
        public String id;
    }

}