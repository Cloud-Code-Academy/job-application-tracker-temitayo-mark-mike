List<Job__c> listJobs = [SELECT Id, Name FROM Job__c];
delete listJobs;

List<Contact> listContacts = [SELECT Id, FirstName, LastName FROM Contact WHERE Lastname != '<unknown_contact>' AND Id NOT IN (SELECT ContactId FROM Case)];
delete listContacts;

List<AccountContactRelation> listACR = [SELECT Id FROM AccountContactRelation];
delete listACR;

List<Account> listAccounts = [SELECT Id, Name, CreatedDate FROM Account WHERE RecordType.Name = 'Employer' AND Id != '001ak00001GGbujAAD'];
System.debug('listAccounts: ' + JSON.serializePretty(listAccounts));
delete listAccounts;

List<Task> listTasks = [SELECT Id FROM Task];
delete listTasks;

List<Event> listEvents = [SELECT Id FROM Event];
delete listEvents;

Map<String, String> JoobleKeywordsMap = new Map<String,String>{
    'keywords' => 'Salesforce developer',
    'location' => 'Des Moines, Iowa',
    'salary' => '70000',
    'datecreatedfrom' => '2023-01-01',
    'companysearch' => 'false'
};
System.debug('******* JoobleKeywordsMap -> JSON: ' + JSON.serializePretty(JoobleKeywordsMap));
JobHelper.JoobleCallout(JSON.serialize(JoobleKeywordsMap));