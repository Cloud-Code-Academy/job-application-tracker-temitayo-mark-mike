
// Date todayDate = Utilities.addWorkingDays(Date.today(), 4);
// System.debug('todayDate: ' + todayDate.toString());

// Utilities.sendErrorEmail('test error email subject', 'test error email body');

// List<Job_Application_Task__c> jobApplTasks = Utilities.getJobAppTasks();
// System.debug('jobApplTasks: ' + JSON.serializePretty(jobApplTasks));

// Job_Application__c ja = new Job_Application__c();
// ja.Job__c = 'a03ak00000Pq0VNAAZ';
// insert ja;

// Job__c job = new Job__c();
// job.Name = 'Job20';
// job.Employer__c = '001ak00001EMxGzAAL';
// job.Primary_Contact__c = '003ak00000PGVpRAAX';
// insert job;

Map<String, String> JoobleKeywordsMap = new Map<String,String>{
    'keywords' => 'Salesforce developer',
    'location' => 'Miami, Florida',
    'salary' => '100000',
    'datecreatedfrom' => '2025-01-01',
    'companysearch' => 'false'
    /* 'radius' => '100',
    'page' => '0',
    'resultonpage' => '0',
    'companysearch' => 'false' */
};

System.debug('******* JoobleKeywordsMap -> JSON: ' + JSON.serializePretty(JoobleKeywordsMap));

JobHelper.JoobleCallout(JSON.serialize(JoobleKeywordsMap));