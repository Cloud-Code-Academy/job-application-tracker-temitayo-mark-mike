public with sharing class JobHelper {
    
    // Simple process to mark IsCreated__c field to True to conditionally display fields, sections, components, etc.
    // AFTER_INSERT
    public static void processInsertedJob(List<Job__c> listTrigger) {
        // Run query to obtain records in Trigger
        List<Job__c> jobsToUpdate = [SELECT Id, IsCreated__c, Name, Employer__r.Name, Long_Name__c FROM Job__c WHERE Id IN :listTrigger WITH SYSTEM_MODE];
        System.debug('jobsToUpdate: ' + JSON.serializePretty(jobsToUpdate));
        // Loop thru the List and update the IsCreated__c field
        for (Job__c job : jobsToUpdate) {
            job.IsCreated__c = true;
            job.Long_Name__c = job.Name + ' (' + job.Employer__r.Name + ')';
        }
        System.debug('jobsToUpdateAFTER: ' + JSON.serializePretty(jobsToUpdate));
        update jobsToUpdate;
    }
    
    public static void processUpdatedJob(List<Job__c> listTriggerNew, Map<Id,Job__c> mapTriggerOld) {
        for (Job__c newJob : listTriggerNew) {
            Job__c oldJob = (Job__c) mapTriggerOld?.get(newJob.Id);
            if (newJob.Name != oldJob.Name) {
                newJob.Long_Name__c.replace(oldJob.Name, newJob.Name);
            }
        }
        
    }

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
			
            String joobleResponseBody = joobleResponse.getBody().replaceAll('\"','"');
            
            System.debug('Clean String joobleResponse: ' + joobleResponseBody);
            //System.debug('Length of Cleaned String: ' + String.valueOf(joobleResponseBody.length()));
      
		} else {
			System.debug('Response error code: ' + joobleResponse.getStatusCode());
		}

	}



}