// Seed 30 additional realistic job application records
// Bringing total from 20 to 50

List<Job_Application__c> apps = new List<Job_Application__c>();

// Batch 1: Recently Applied (10)
apps.add(new Job_Application__c(
    Company_Name__c = 'Adobe', Position_Title__c = 'Senior Full Stack Developer',
    Status__c = 'Applied', Salary__c = 175000, Location__c = 'Remote',
    Application_Date__c = Date.today().addDays(-3), Rating__c = '4',
    Notes__c = 'Applied via their careers site. Strong match for creative cloud team.',
    Job_URL__c = 'https://adobe.com/careers'));
apps.add(new Job_Application__c(
    Company_Name__c = 'Atlassian', Position_Title__c = 'Cloud Platform Engineer',
    Status__c = 'Applied', Salary__c = 185000, Location__c = 'Remote',
    Application_Date__c = Date.today().addDays(-5), Rating__c = '5',
    Notes__c = 'Referred by former colleague. Team works on Jira Cloud infrastructure.'));
apps.add(new Job_Application__c(
    Company_Name__c = 'Palantir', Position_Title__c = 'Forward Deployed Engineer',
    Status__c = 'Applied', Salary__c = 195000, Location__c = 'Hybrid',
    Application_Date__c = Date.today().addDays(-2), Rating__c = '3',
    Notes__c = 'Interesting role but intense culture. Government contracts focus.'));
apps.add(new Job_Application__c(
    Company_Name__c = 'Datadog', Position_Title__c = 'Software Engineer - Observability',
    Status__c = 'Applied', Salary__c = 180000, Location__c = 'Hybrid',
    Application_Date__c = Date.today().addDays(-7), Rating__c = '4',
    Notes__c = 'Love the product. Team building next-gen APM tooling.'));
apps.add(new Job_Application__c(
    Company_Name__c = 'Figma', Position_Title__c = 'Product Engineer',
    Status__c = 'Applied', Salary__c = 190000, Location__c = 'On-site',
    Application_Date__c = Date.today().addDays(-4), Rating__c = '5',
    Notes__c = 'Dream company. Design tools space is exciting.'));
apps.add(new Job_Application__c(
    Company_Name__c = 'Square', Position_Title__c = 'Backend Engineer - Payments',
    Status__c = 'Applied', Salary__c = 188000, Location__c = 'Remote',
    Application_Date__c = Date.today().addDays(-6), Rating__c = '4',
    Notes__c = 'Fintech experience would be valuable. Java/Kotlin stack.'));
apps.add(new Job_Application__c(
    Company_Name__c = 'Snowflake', Position_Title__c = 'Senior Software Engineer',
    Status__c = 'Applied', Salary__c = 200000, Location__c = 'Hybrid',
    Application_Date__c = Date.today().addDays(-1), Rating__c = '4',
    Notes__c = 'Data cloud platform. Great comp package.'));
apps.add(new Job_Application__c(
    Company_Name__c = 'Notion', Position_Title__c = 'Full Stack Engineer',
    Status__c = 'Applying', Salary__c = 178000, Location__c = 'Remote',
    Application_Date__c = Date.today(), Rating__c = '5',
    Notes__c = 'Still working on cover letter. Small engineering team.'));
apps.add(new Job_Application__c(
    Company_Name__c = 'Vercel', Position_Title__c = 'Developer Experience Engineer',
    Status__c = 'Applying', Salary__c = 172000, Location__c = 'Remote',
    Application_Date__c = Date.today(), Rating__c = '4',
    Notes__c = 'Next.js team. Need to prepare portfolio examples.'));
apps.add(new Job_Application__c(
    Company_Name__c = 'Plaid', Position_Title__c = 'Software Engineer - APIs',
    Status__c = 'Applying', Salary__c = 183000, Location__c = 'Remote',
    Application_Date__c = Date.today(), Rating__c = '3',
    Notes__c = 'Financial data APIs. Interesting problem space.'));

// Batch 2: Interviewing (8)
apps.add(new Job_Application__c(
    Company_Name__c = 'Airbnb', Position_Title__c = 'Staff Software Engineer',
    Status__c = 'Interviewing', Salary__c = 210000, Location__c = 'Hybrid',
    Application_Date__c = Date.today().addDays(-18), Rating__c = '5',
    Follow_Up_Date__c = Date.today().addDays(2),
    Notes__c = 'Passed phone screen. Technical interview scheduled next week.'));
apps.add(new Job_Application__c(
    Company_Name__c = 'Spotify', Position_Title__c = 'Backend Engineer - Personalization',
    Status__c = 'Interviewing', Salary__c = 192000, Location__c = 'Remote',
    Application_Date__c = Date.today().addDays(-15), Rating__c = '5',
    Follow_Up_Date__c = Date.today().addDays(3),
    Notes__c = 'ML-adjacent role. Second round coming up.'));
apps.add(new Job_Application__c(
    Company_Name__c = 'Coinbase', Position_Title__c = 'Senior Platform Engineer',
    Status__c = 'Interviewing', Salary__c = 205000, Location__c = 'Remote',
    Application_Date__c = Date.today().addDays(-12), Rating__c = '4',
    Follow_Up_Date__c = Date.today().addDays(1),
    Notes__c = 'Crypto platform infra. Panel interview tomorrow.'));
apps.add(new Job_Application__c(
    Company_Name__c = 'DoorDash', Position_Title__c = 'Software Engineer - Logistics',
    Status__c = 'Interviewing', Salary__c = 187000, Location__c = 'On-site',
    Application_Date__c = Date.today().addDays(-20), Rating__c = '3',
    Follow_Up_Date__c = Date.today().addDays(5),
    Notes__c = 'Routing optimization challenges. On-site loop pending.'));
apps.add(new Job_Application__c(
    Company_Name__c = 'Dropbox', Position_Title__c = 'Senior Software Engineer - Sync',
    Status__c = 'Interviewing', Salary__c = 195000, Location__c = 'Remote',
    Application_Date__c = Date.today().addDays(-14), Rating__c = '4',
    Follow_Up_Date__c = Date.today().addDays(4),
    Notes__c = 'Virtual First company. Distributed systems team.'));
apps.add(new Job_Application__c(
    Company_Name__c = 'Robinhood', Position_Title__c = 'Backend Engineer - Trading',
    Status__c = 'Interviewing', Salary__c = 198000, Location__c = 'Hybrid',
    Application_Date__c = Date.today().addDays(-10), Rating__c = '4',
    Follow_Up_Date__c = Date.today().addDays(2),
    Notes__c = 'Trading platform team. System design round next.'));
apps.add(new Job_Application__c(
    Company_Name__c = 'Pinterest', Position_Title__c = 'Full Stack Engineer - Ads',
    Status__c = 'Interviewing', Salary__c = 182000, Location__c = 'Remote',
    Application_Date__c = Date.today().addDays(-16), Rating__c = '3',
    Follow_Up_Date__c = Date.today().addDays(6),
    Notes__c = 'Ads platform engineering. Final round pending decision.'));
apps.add(new Job_Application__c(
    Company_Name__c = 'Lyft', Position_Title__c = 'Senior Software Engineer - Maps',
    Status__c = 'Interviewing', Salary__c = 191000, Location__c = 'Hybrid',
    Application_Date__c = Date.today().addDays(-11), Rating__c = '4',
    Follow_Up_Date__c = Date.today().addDays(3),
    Notes__c = 'Mapping and ETA prediction. Completed coding challenge.'));

// Batch 3: Negotiating (3)
apps.add(new Job_Application__c(
    Company_Name__c = 'GitLab', Position_Title__c = 'Staff Backend Engineer',
    Status__c = 'Negotiating', Salary__c = 205000, Location__c = 'Remote',
    Application_Date__c = Date.today().addDays(-30), Rating__c = '5',
    Follow_Up_Date__c = Date.today().addDays(2),
    Notes__c = 'All-remote company. Negotiating equity package.'));
apps.add(new Job_Application__c(
    Company_Name__c = 'Confluent', Position_Title__c = 'Senior Software Engineer',
    Status__c = 'Negotiating', Salary__c = 198000, Location__c = 'Remote',
    Application_Date__c = Date.today().addDays(-28), Rating__c = '4',
    Follow_Up_Date__c = Date.today().addDays(1),
    Notes__c = 'Kafka cloud platform. Counter-offered on base salary.'));

// Batch 4: Saved / Researching (5)
apps.add(new Job_Application__c(
    Company_Name__c = 'OpenAI', Position_Title__c = 'Software Engineer - Platform',
    Status__c = 'Saved', Salary__c = 250000, Location__c = 'On-site',
    Rating__c = '5',
    Notes__c = 'Dream role. Need to brush up on ML fundamentals first.'));
apps.add(new Job_Application__c(
    Company_Name__c = 'Anthropic', Position_Title__c = 'Backend Engineer - Safety',
    Status__c = 'Saved', Salary__c = 240000, Location__c = 'Hybrid',
    Rating__c = '5',
    Notes__c = 'AI safety research. Fascinating mission. Preparing application.'));
apps.add(new Job_Application__c(
    Company_Name__c = 'Databricks', Position_Title__c = 'Senior Software Engineer',
    Status__c = 'Saved', Salary__c = 215000, Location__c = 'Remote',
    Rating__c = '4',
    Notes__c = 'Unity Catalog team. Great for data engineering career path.'));
apps.add(new Job_Application__c(
    Company_Name__c = 'Elastic', Position_Title__c = 'Software Engineer - Search',
    Status__c = 'Saved', Salary__c = 178000, Location__c = 'Remote',
    Rating__c = '3',
    Notes__c = 'Elasticsearch core team. Distributed systems focus.'));
apps.add(new Job_Application__c(
    Company_Name__c = 'HashiCorp', Position_Title__c = 'Senior Engineer - Terraform',
    Status__c = 'Saved', Salary__c = 192000, Location__c = 'Remote',
    Rating__c = '4',
    Notes__c = 'Infrastructure as code. Go language stack.'));

// Batch 5: Closed (4)
apps.add(new Job_Application__c(
    Company_Name__c = 'Twitter/X', Position_Title__c = 'Senior Software Engineer',
    Status__c = 'Closed', Salary__c = 190000, Location__c = 'On-site',
    Application_Date__c = Date.today().addDays(-45), Rating__c = '2',
    Notes__c = 'Decided not to pursue after recent company changes.'));
apps.add(new Job_Application__c(
    Company_Name__c = 'Oracle', Position_Title__c = 'Cloud Engineer',
    Status__c = 'Closed', Salary__c = 165000, Location__c = 'Hybrid',
    Application_Date__c = Date.today().addDays(-40), Rating__c = '2',
    Notes__c = 'Position filled before final interview.'));
apps.add(new Job_Application__c(
    Company_Name__c = 'VMware', Position_Title__c = 'Platform Engineer',
    Status__c = 'Closed', Salary__c = 172000, Location__c = 'On-site',
    Application_Date__c = Date.today().addDays(-50), Rating__c = '3',
    Notes__c = 'Role restructured after Broadcom acquisition.'));
apps.add(new Job_Application__c(
    Company_Name__c = 'Cisco', Position_Title__c = 'Software Developer',
    Status__c = 'Closed', Salary__c = 160000, Location__c = 'On-site',
    Application_Date__c = Date.today().addDays(-55), Rating__c = '2',
    Notes__c = 'Salary below expectations after second interview.'));

insert apps;
System.debug('Successfully inserted ' + apps.size() + ' new job applications');
System.debug('Total records: ' + [SELECT COUNT() FROM Job_Application__c]);
