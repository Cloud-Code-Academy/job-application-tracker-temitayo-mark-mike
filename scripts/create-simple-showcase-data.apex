// Create showcase data for Job Application Tracker
List<Job_Application__c> jobApps = new List<Job_Application__c>();

// Tech Companies - High Salary Range
jobApps.add(new Job_Application__c(
    Company_Name__c = 'Salesforce',
    Position_Title__c = 'Senior Salesforce Developer',
    Salary__c = 120000,
    Status__c = 'Interviewing',
    Application_Date__c = Date.newInstance(2024, 1, 15)
));

jobApps.add(new Job_Application__c(
    Company_Name__c = 'Microsoft',
    Position_Title__c = 'Software Engineer II',
    Salary__c = 110000,
    Status__c = 'Applied',
    Application_Date__c = Date.newInstance(2024, 1, 20)
));

jobApps.add(new Job_Application__c(
    Company_Name__c = 'Google',
    Position_Title__c = 'Product Manager',
    Salary__c = 140000,
    Status__c = 'Negotiating',
    Application_Date__c = Date.newInstance(2024, 1, 10)
));

jobApps.add(new Job_Application__c(
    Company_Name__c = 'Amazon',
    Position_Title__c = 'Data Scientist',
    Salary__c = 115000,
    Status__c = 'Closed',
    Application_Date__c = Date.newInstance(2024, 1, 5)
));

jobApps.add(new Job_Application__c(
    Company_Name__c = 'Meta',
    Position_Title__c = 'Frontend Developer',
    Salary__c = 125000,
    Status__c = 'Applied',
    Application_Date__c = Date.newInstance(2024, 1, 25)
));

// Finance Companies - Mid-High Salary Range
jobApps.add(new Job_Application__c(
    Company_Name__c = 'JPMorgan Chase',
    Position_Title__c = 'Business Analyst',
    Salary__c = 85000,
    Status__c = 'Applied',
    Application_Date__c = Date.newInstance(2024, 1, 22)
));

jobApps.add(new Job_Application__c(
    Company_Name__c = 'Goldman Sachs',
    Position_Title__c = 'Quantitative Analyst',
    Salary__c = 135000,
    Status__c = 'Interviewing',
    Application_Date__c = Date.newInstance(2024, 1, 8)
));

jobApps.add(new Job_Application__c(
    Company_Name__c = 'Wells Fargo',
    Position_Title__c = 'Project Manager',
    Salary__c = 90000,
    Status__c = 'Negotiating',
    Application_Date__c = Date.newInstance(2024, 1, 3)
));

// Healthcare Companies - Mid Salary Range
jobApps.add(new Job_Application__c(
    Company_Name__c = 'Johnson & Johnson',
    Position_Title__c = 'Data Analyst',
    Salary__c = 75000,
    Status__c = 'Applied',
    Application_Date__c = Date.newInstance(2024, 1, 26)
));

jobApps.add(new Job_Application__c(
    Company_Name__c = 'Pfizer',
    Position_Title__c = 'Clinical Research Associate',
    Salary__c = 70000,
    Status__c = 'Interviewing',
    Application_Date__c = Date.newInstance(2024, 1, 14)
));

// Consulting Companies
jobApps.add(new Job_Application__c(
    Company_Name__c = 'McKinsey & Company',
    Position_Title__c = 'Business Analyst',
    Salary__c = 95000,
    Status__c = 'Interviewing',
    Application_Date__c = Date.newInstance(2024, 1, 11)
));

jobApps.add(new Job_Application__c(
    Company_Name__c = 'Accenture',
    Position_Title__c = 'Digital Consultant',
    Salary__c = 82000,
    Status__c = 'Accepted',
    Application_Date__c = Date.newInstance(2024, 1, 7)
));

// Startups - Varied Range
jobApps.add(new Job_Application__c(
    Company_Name__c = 'Stripe',
    Position_Title__c = 'Backend Engineer',
    Salary__c = 115000,
    Status__c = 'Applied',
    Application_Date__c = Date.newInstance(2024, 1, 16)
));

jobApps.add(new Job_Application__c(
    Company_Name__c = 'Zoom',
    Position_Title__c = 'Customer Success Manager',
    Salary__c = 75000,
    Status__c = 'Interviewing',
    Application_Date__c = Date.newInstance(2024, 1, 21)
));

jobApps.add(new Job_Application__c(
    Company_Name__c = 'Slack',
    Position_Title__c = 'Marketing Manager',
    Salary__c = 85000,
    Status__c = 'Applied',
    Application_Date__c = Date.newInstance(2024, 1, 27)
));

jobApps.add(new Job_Application__c(
    Company_Name__c = 'DocuSign',
    Position_Title__c = 'Sales Development Rep',
    Salary__c = 65000,
    Status__c = 'Applied',
    Application_Date__c = Date.newInstance(2024, 1, 23)
));

// Insert all job applications
insert jobApps;

System.debug('Successfully created ' + jobApps.size() + ' job applications!');

// Display some statistics
Map<String, Integer> statusCounts = new Map<String, Integer>();
Decimal totalSalary = 0;
Decimal maxSalary = 0;
Decimal minSalary = 999999;

for (Job_Application__c app : jobApps) {
    // Count by status
    String status = app.Status__c;
    statusCounts.put(status, statusCounts.containsKey(status) ? statusCounts.get(status) + 1 : 1);
    
    // Salary statistics
    if (app.Salary__c != null) {
        totalSalary += app.Salary__c;
        maxSalary = Math.max(maxSalary, app.Salary__c);
        minSalary = Math.min(minSalary, app.Salary__c);
    }
}

System.debug('=== SHOWCASE DATA STATISTICS ===');
System.debug('Total Applications: ' + jobApps.size());
System.debug('Status Breakdown: ' + statusCounts);
System.debug('Average Salary: $' + (totalSalary / jobApps.size()).format());
System.debug('Salary Range: $' + minSalary.format() + ' - $' + maxSalary.format());
System.debug('=== Triggers will automatically create tasks and calculate take-home pay! ===');
