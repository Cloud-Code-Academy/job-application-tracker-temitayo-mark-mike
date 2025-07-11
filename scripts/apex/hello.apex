
// Date todayDate = Utilities.addWorkingDays(Date.today(), 4);
// System.debug('todayDate: ' + todayDate.toString());

// Utilities.sendErrorEmail('test error email subject', 'test error email body');

// List<Job_Application_Task__c> jobApplTasks = Utilities.getJobAppTasks();
// System.debug('jobApplTasks: ' + JSON.serializePretty(jobApplTasks));

Job_Application__c ja = new Job_Application__c();
ja.Job__c = 'a03ak00000Pq0VNAAZ';
insert ja;

Job__c job = new Job__c();
job.Name = 'Job20';
job.Employer__c = '001ak00001EMxGzAAL';
job.Primary_Contact__c = '003ak00000PGVpRAAX';
insert job;