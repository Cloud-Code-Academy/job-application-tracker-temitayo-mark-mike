// Create a test job application to verify automation
Job_Application__c testJob = new Job_Application__c(
    Company_Name__c = 'Salesforce',
    Position_Title__c = 'Senior Developer',
    Status__c = 'Saved',
    Salary__c = 120000,
    Location__c = 'Remote',
    Rating__c = '5',
    Description__c = 'Amazing opportunity to work with cutting-edge technology'
);

insert testJob;

System.debug('Created Job Application: ' + testJob.Id);

// Query the created record to see calculated fields
Job_Application__c createdJob = [
    SELECT Id, Name, Company_Name__c, Position_Title__c, Status__c, Salary__c,
           Federal_Tax__c, Social_Security_Tax__c, Medicare_Tax__c,
           Take_Home_Pay_Yearly__c, Take_Home_Pay_Monthly__c, Primary_Contact__c
    FROM Job_Application__c
    WHERE Id = :testJob.Id
];

System.debug('Job Application Details:');
System.debug('Name: ' + createdJob.Name);
System.debug('Company: ' + createdJob.Company_Name__c);
System.debug('Position: ' + createdJob.Position_Title__c);
System.debug('Salary: $' + createdJob.Salary__c);
System.debug('Federal Tax: $' + createdJob.Federal_Tax__c);
System.debug('Social Security Tax: $' + createdJob.Social_Security_Tax__c);
System.debug('Medicare Tax: $' + createdJob.Medicare_Tax__c);
System.debug('Take Home (Yearly): $' + createdJob.Take_Home_Pay_Yearly__c);
System.debug('Take Home (Monthly): $' + createdJob.Take_Home_Pay_Monthly__c);

// Query created tasks
List<Task> createdTasks = [
    SELECT Id, Subject, Priority, ActivityDate, Status
    FROM Task
    WHERE WhatId = :testJob.Id
    ORDER BY Subject
];

System.debug('Created ' + createdTasks.size() + ' tasks:');
for (Task t : createdTasks) {
    System.debug('- ' + t.Subject + ' (Priority: ' + t.Priority + ', Due: ' + t.ActivityDate + ')');
}
