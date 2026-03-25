// STEP 1: Delete all existing test data
List<Job_Application__c> allApps = [SELECT Id FROM Job_Application__c];
System.debug('Deleting ' + allApps.size() + ' old/test records...');
delete allApps;
System.debug('Deleted successfully.');

// STEP 2: Create realistic showcase data
List<Job_Application__c> newApps = new List<Job_Application__c>();

// --- Active Pipeline (recent applications) ---
newApps.add(new Job_Application__c(
    Company_Name__c = 'Salesforce', Position_Title__c = 'Senior Apex Developer',
    Status__c = 'Interviewing', Salary__c = 185000,
    Application_Date__c = Date.today().addDays(-5), Location__c = 'Hybrid',
    Notes__c = 'Third round scheduled. Team is building next-gen Lightning platform features.'
));
newApps.add(new Job_Application__c(
    Company_Name__c = 'Google', Position_Title__c = 'Cloud Platform Engineer',
    Status__c = 'Applied', Salary__c = 195000,
    Application_Date__c = Date.today().addDays(-3), Location__c = 'On-site',
    Notes__c = 'Applied through referral. GCP infrastructure team.'
));
newApps.add(new Job_Application__c(
    Company_Name__c = 'Microsoft', Position_Title__c = 'Dynamics 365 Developer',
    Status__c = 'Interviewing', Salary__c = 175000,
    Application_Date__c = Date.today().addDays(-8), Location__c = 'Hybrid',
    Notes__c = 'Technical screen completed. System design interview next week.'
));
newApps.add(new Job_Application__c(
    Company_Name__c = 'Deloitte', Position_Title__c = 'Salesforce Consultant',
    Status__c = 'Negotiating', Salary__c = 165000,
    Application_Date__c = Date.today().addDays(-14), Location__c = 'Hybrid',
    Notes__c = 'Offer received! Negotiating base salary and signing bonus.'
));
newApps.add(new Job_Application__c(
    Company_Name__c = 'Accenture', Position_Title__c = 'CRM Technical Lead',
    Status__c = 'Interviewing', Salary__c = 170000,
    Application_Date__c = Date.today().addDays(-10), Location__c = 'On-site',
    Notes__c = 'Panel interview with the delivery team went well.'
));

// --- Recently Applied ---
newApps.add(new Job_Application__c(
    Company_Name__c = 'Amazon', Position_Title__c = 'Solutions Architect',
    Status__c = 'Applied', Salary__c = 190000,
    Application_Date__c = Date.today().addDays(-2), Location__c = 'Hybrid',
    Notes__c = 'AWS team. Applied via careers page.'
));
newApps.add(new Job_Application__c(
    Company_Name__c = 'Slack', Position_Title__c = 'Platform Engineer',
    Status__c = 'Applied', Salary__c = 180000,
    Application_Date__c = Date.today().addDays(-1), Location__c = 'Remote',
    Notes__c = 'Integration team role building Slack-Salesforce connectors.'
));
newApps.add(new Job_Application__c(
    Company_Name__c = 'IBM', Position_Title__c = 'Cloud Integration Specialist',
    Status__c = 'Applied', Salary__c = 155000,
    Application_Date__c = Date.today(), Location__c = 'Hybrid',
    Notes__c = 'Watson AI + Salesforce integration role.'
));

// --- Saved / Researching ---
newApps.add(new Job_Application__c(
    Company_Name__c = 'Netflix', Position_Title__c = 'Backend Engineer',
    Status__c = 'Saved', Salary__c = 210000,
    Application_Date__c = Date.today().addDays(-1), Location__c = 'On-site',
    Notes__c = 'Dream company. Preparing resume and portfolio.'
));
newApps.add(new Job_Application__c(
    Company_Name__c = 'Stripe', Position_Title__c = 'Integration Engineer',
    Status__c = 'Saved', Salary__c = 195000,
    Application_Date__c = Date.today(), Location__c = 'Remote',
    Notes__c = 'Payments platform. Great engineering culture.'
));
newApps.add(new Job_Application__c(
    Company_Name__c = 'Shopify', Position_Title__c = 'Senior Developer',
    Status__c = 'Saved', Salary__c = 175000,
    Application_Date__c = Date.today(), Location__c = 'Remote',
    Notes__c = 'Commerce platform team. Fully remote.'
));
newApps.add(new Job_Application__c(
    Company_Name__c = 'Twilio', Position_Title__c = 'API Platform Engineer',
    Status__c = 'Saved', Salary__c = 168000,
    Application_Date__c = Date.today().addDays(-2), Location__c = 'Remote',
    Notes__c = 'Communications API team. Strong developer experience focus.'
));

// --- Success Stories ---
newApps.add(new Job_Application__c(
    Company_Name__c = 'Cognizant', Position_Title__c = 'Salesforce Technical Architect',
    Status__c = 'Accepted', Salary__c = 160000,
    Application_Date__c = Date.today().addDays(-30), Location__c = 'Hybrid',
    Notes__c = 'Accepted offer! Start date in 2 weeks. Leading a 5-person Salesforce team.'
));

// --- Closed (learning experiences) ---
newApps.add(new Job_Application__c(
    Company_Name__c = 'Meta', Position_Title__c = 'Full Stack Engineer',
    Status__c = 'Closed', Salary__c = 200000,
    Application_Date__c = Date.today().addDays(-21), Location__c = 'On-site',
    Notes__c = 'Made it to final round. Feedback: needed more system design depth.'
));
newApps.add(new Job_Application__c(
    Company_Name__c = 'Apple', Position_Title__c = 'Enterprise Systems Engineer',
    Status__c = 'Closed', Salary__c = 188000,
    Application_Date__c = Date.today().addDays(-25), Location__c = 'On-site',
    Notes__c = 'Phone screen went well but position was filled internally.'
));
newApps.add(new Job_Application__c(
    Company_Name__c = 'Uber', Position_Title__c = 'Platform Engineer',
    Status__c = 'Closed', Salary__c = 185000,
    Application_Date__c = Date.today().addDays(-18), Location__c = 'Hybrid',
    Notes__c = 'Withdrew after receiving better offer from Deloitte.'
));
newApps.add(new Job_Application__c(
    Company_Name__c = 'LinkedIn', Position_Title__c = 'Software Engineer',
    Status__c = 'Closed', Salary__c = 178000,
    Application_Date__c = Date.today().addDays(-35), Location__c = 'Hybrid',
    Notes__c = 'Position closed by hiring team. Will reapply when reopened.'
));

// --- More pipeline depth ---
newApps.add(new Job_Application__c(
    Company_Name__c = 'HubSpot', Position_Title__c = 'CRM Developer',
    Status__c = 'Applied', Salary__c = 155000,
    Application_Date__c = Date.today().addDays(-4), Location__c = 'Remote',
    Notes__c = 'Marketing Technology team. Python + Salesforce integration.'
));
newApps.add(new Job_Application__c(
    Company_Name__c = 'ServiceNow', Position_Title__c = 'Platform Developer',
    Status__c = 'Interviewing', Salary__c = 172000,
    Application_Date__c = Date.today().addDays(-12), Location__c = 'On-site',
    Notes__c = 'Second round completed. Building workflow automation tools.'
));
newApps.add(new Job_Application__c(
    Company_Name__c = 'Workday', Position_Title__c = 'Integration Architect',
    Status__c = 'Applying', Salary__c = 168000,
    Application_Date__c = Date.today().addDays(-6), Location__c = 'Hybrid',
    Notes__c = 'HR tech platform. Salesforce-Workday connector team.'
));

insert newApps;
System.debug('=== CREATED ' + newApps.size() + ' SHOWCASE RECORDS ===');

// Summary
List<AggregateResult> summary = [
    SELECT Status__c, COUNT(Id) cnt 
    FROM Job_Application__c 
    GROUP BY Status__c 
    ORDER BY COUNT(Id) DESC
];
System.debug('=== NEW STATUS BREAKDOWN ===');
for (AggregateResult ar : summary) {
    System.debug('  ' + ar.get('Status__c') + ': ' + ar.get('cnt'));
}
