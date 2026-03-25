// Audit field completeness across all Job Application records
List<Job_Application__c> apps = [
    SELECT Id, Name, Company_Name__c, Position_Title__c, Status__c, Salary__c,
           Location__c, Application_Date__c, Rating__c, Follow_Up_Date__c,
           Notes__c, Description__c, Job_URL__c, Primary_Contact__c,
           Federal_Tax__c, Social_Security_Tax__c, Medicare_Tax__c,
           Take_Home_Pay_Yearly__c, Take_Home_Pay_Monthly__c
    FROM Job_Application__c
    ORDER BY Company_Name__c
];

System.debug('Total records: ' + apps.size());

// Count nulls per field
Integer noAppDate = 0, noFollowUp = 0, noNotes = 0;
Integer noDescription = 0, noJobUrl = 0, noRating = 0, noContact = 0;
Integer noFedTax = 0, noTakeHome = 0, noLocation = 0;

for (Job_Application__c a : apps) {
    if (a.Application_Date__c == null) noAppDate++;
    if (a.Follow_Up_Date__c == null) noFollowUp++;
    if (String.isBlank(a.Notes__c)) noNotes++;
    if (String.isBlank(a.Description__c)) noDescription++;
    if (String.isBlank(a.Job_URL__c)) noJobUrl++;
    if (String.isBlank(a.Rating__c)) noRating++;
    if (a.Primary_Contact__c == null) noContact++;
    if (a.Federal_Tax__c == null || a.Federal_Tax__c == 0) noFedTax++;
    if (a.Take_Home_Pay_Yearly__c == null || a.Take_Home_Pay_Yearly__c == 0) noTakeHome++;
    if (String.isBlank(a.Location__c)) noLocation++;
}

System.debug('=== FIELD COMPLETENESS AUDIT ===');
System.debug('Application_Date__c missing: ' + noAppDate);
System.debug('Follow_Up_Date__c missing: ' + noFollowUp);
System.debug('Notes__c missing: ' + noNotes);
System.debug('Description__c missing: ' + noDescription);
System.debug('Job_URL__c missing: ' + noJobUrl);
System.debug('Rating__c missing: ' + noRating);
System.debug('Location__c missing: ' + noLocation);
System.debug('Federal_Tax__c zero/null: ' + noFedTax);
System.debug('Take_Home_Pay_Yearly__c zero/null: ' + noTakeHome);
System.debug('Primary_Contact__c missing: ' + noContact);

// List records missing Application_Date__c
System.debug('=== RECORDS MISSING APPLICATION DATE ===');
for (Job_Application__c a : apps) {
    if (a.Application_Date__c == null) {
        System.debug(a.Company_Name__c + ' - ' + a.Position_Title__c + ' (' + a.Status__c + ')');
    }
}

// Next_Steps__c doesn't exist in org — skipping
