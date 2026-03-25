// Check data quality in the org
System.debug('=== JOB APPLICATION DATA ANALYSIS ===');

// Total count
Integer total = [SELECT COUNT() FROM Job_Application__c];
System.debug('Total Job Applications: ' + total);

// Status breakdown
List<AggregateResult> statusCounts = [
    SELECT Status__c, COUNT(Id) cnt 
    FROM Job_Application__c 
    GROUP BY Status__c 
    ORDER BY COUNT(Id) DESC
];
System.debug('=== STATUS BREAKDOWN ===');
for (AggregateResult ar : statusCounts) {
    System.debug('  ' + ar.get('Status__c') + ': ' + ar.get('cnt'));
}

// Check for records with no company name
Integer noCompany = [SELECT COUNT() FROM Job_Application__c WHERE Company_Name__c = null];
System.debug('Records with no Company: ' + noCompany);

// Check for records with no position
Integer noPosition = [SELECT COUNT() FROM Job_Application__c WHERE Position_Title__c = null];
System.debug('Records with no Position: ' + noPosition);

// Check for records with no salary
Integer noSalary = [SELECT COUNT() FROM Job_Application__c WHERE Salary__c = null OR Salary__c = 0];
System.debug('Records with no/zero Salary: ' + noSalary);

// Check for duplicates (same company + position)
List<AggregateResult> dupes = [
    SELECT Company_Name__c, Position_Title__c, COUNT(Id) cnt
    FROM Job_Application__c
    GROUP BY Company_Name__c, Position_Title__c
    HAVING COUNT(Id) > 1
    ORDER BY COUNT(Id) DESC
    LIMIT 10
];
System.debug('=== POTENTIAL DUPLICATES (top 10) ===');
for (AggregateResult ar : dupes) {
    System.debug('  ' + ar.get('Company_Name__c') + ' - ' + ar.get('Position_Title__c') + ': ' + ar.get('cnt') + ' records');
}

// Date range
System.debug('=== DATE RANGE ===');

AggregateResult dateAgg = [SELECT MIN(Application_Date__c) minDate, MAX(Application_Date__c) maxDate FROM Job_Application__c];
System.debug('Earliest: ' + dateAgg.get('minDate'));
System.debug('Latest: ' + dateAgg.get('maxDate'));

// Sample some records
List<Job_Application__c> samples = [
    SELECT Company_Name__c, Position_Title__c, Status__c, Salary__c, Application_Date__c
    FROM Job_Application__c
    ORDER BY CreatedDate DESC
    LIMIT 10
];
System.debug('=== LATEST 10 RECORDS ===');
for (Job_Application__c ja : samples) {
    System.debug('  ' + ja.Company_Name__c + ' | ' + ja.Position_Title__c + ' | ' + ja.Status__c + ' | $' + ja.Salary__c + ' | ' + ja.Application_Date__c);
}
