// Create comprehensive showcase data for Job Application Tracker
List<Job_Application__c> jobApps = new List<Job_Application__c>();

// Tech Companies
jobApps.add(new Job_Application__c(
    Company_Name__c = 'Salesforce',
    Position_Title__c = 'Senior Salesforce Developer',
    Salary__c = 120000,
    Status__c = 'Interviewing',
    Application_Date__c = Date.newInstance(2024, 1, 15),
    Description__c = 'Lead development of custom Salesforce solutions using Apex, LWC, and integrations.',
    Notes__c = 'Great company culture and growth opportunities. Technical interview scheduled.',
    Job_URL__c = 'https://salesforce.com/careers/senior-dev',
    Location__c = 'Remote'
));

jobApps.add(new Job_Application__c(
    Company_Name__c = 'Microsoft',
    Position_Title__c = 'Software Engineer II',
    Salary__c = 110000,
    Status__c = 'Applied',
    Application_Date__c = Date.newInstance(2024, 1, 20),
    Job_Description__c = 'Develop and maintain cloud-based applications using .NET, Azure, and modern web technologies. Collaborate with product teams on feature development.',
    Notes__c = 'Applied through employee referral. Strong technical requirements match my background.',
    Contact_Name__c = 'Mike Chen',
    Contact_Email__c = 'mike.chen@microsoft.com',
    Job_URL__c = 'https://careers.microsoft.com/swe2'
));

jobApps.add(new Job_Application__c(
    Company_Name__c = 'Google',
    Position_Title__c = 'Product Manager',
    Salary__c = 140000,
    Status__c = 'Offer',
    Application_Date__c = Date.newInstance(2024, 1, 10),
    Job_Description__c = 'Drive product strategy and roadmap for consumer-facing applications. Work with engineering and design teams to deliver user-centric solutions.',
    Notes__c = 'Received offer! Excellent compensation package and team culture. Need to respond by Friday.',
    Contact_Name__c = 'Lisa Rodriguez',
    Contact_Email__c = 'lisa.rodriguez@google.com',
    Job_URL__c = 'https://careers.google.com/pm-consumer'
));

jobApps.add(new Job_Application__c(
    Company_Name__c = 'Amazon',
    Position_Title__c = 'Data Scientist',
    Salary__c = 115000,
    Status__c = 'Rejected',
    Application_Date__c = Date.newInstance(2024, 1, 5),
    Job_Description__c = 'Apply machine learning and statistical analysis to solve complex business problems. Build predictive models and data pipelines at scale.',
    Notes__c = 'Feedback: Strong technical skills but looking for more AWS experience. Good learning opportunity.',
    Contact_Name__c = 'David Kim',
    Contact_Email__c = 'david.kim@amazon.com',
    Job_URL__c = 'https://amazon.jobs/data-scientist'
));

jobApps.add(new Job_Application__c(
    Company_Name__c = 'Meta',
    Position_Title__c = 'Frontend Developer',
    Salary__c = 125000,
    Status__c = 'Applied',
    Application_Date__c = Date.newInstance(2024, 1, 25),
    Job_Description__c = 'Build responsive web applications using React, TypeScript, and modern frontend technologies. Focus on user experience and performance optimization.',
    Notes__c = 'Exciting opportunity to work on products used by billions. Applied after attending their tech talk.',
    Contact_Name__c = 'Jennifer Wu',
    Contact_Email__c = 'jennifer.wu@meta.com',
    Job_URL__c = 'https://careers.meta.com/frontend-dev'
));

jobApps.add(new Job_Application__c(
    Company_Name__c = 'Netflix',
    Position_Title__c = 'DevOps Engineer',
    Salary__c = 130000,
    Status__c = 'Interviewing',
    Application_Date__c = Date.newInstance(2024, 1, 12),
    Job_Description__c = 'Manage cloud infrastructure and CI/CD pipelines. Ensure high availability and scalability of streaming services.',
    Notes__c = 'Phone screen went well. Technical interview scheduled. Love their engineering culture.',
    Contact_Name__c = 'Alex Thompson',
    Contact_Email__c = 'alex.thompson@netflix.com',
    Job_URL__c = 'https://jobs.netflix.com/devops'
));

// Finance Companies
jobApps.add(new Job_Application__c(
    Company_Name__c = 'JPMorgan Chase',
    Position_Title__c = 'Business Analyst',
    Salary__c = 85000,
    Status__c = 'Applied',
    Application_Date__c = Date.newInstance(2024, 1, 22),
    Job_Description__c = 'Analyze business requirements and translate them into technical solutions. Work with stakeholders to improve operational efficiency.',
    Notes__c = 'Strong financial services opportunity. Good work-life balance and training programs.',
    Contact_Name__c = 'Rachel Brown',
    Contact_Email__c = 'rachel.brown@jpmorgan.com',
    Job_URL__c = 'https://careers.jpmorgan.com/business-analyst'
));

jobApps.add(new Job_Application__c(
    Company_Name__c = 'Goldman Sachs',
    Position_Title__c = 'Quantitative Analyst',
    Salary__c = 135000,
    Status__c = 'Interviewing',
    Application_Date__c = Date.newInstance(2024, 1, 8),
    Job_Description__c = 'Develop mathematical models for trading strategies and risk management. Apply statistical analysis to financial markets.',
    Notes__c = 'Challenging role with excellent compensation. Technical interview focuses on probability and coding.',
    Contact_Name__c = 'James Lee',
    Contact_Email__c = 'james.lee@goldmansachs.com',
    Job_URL__c = 'https://goldmansachs.com/careers/quant'
));

jobApps.add(new Job_Application__c(
    Company_Name__c = 'Wells Fargo',
    Position_Title__c = 'Project Manager',
    Salary__c = 90000,
    Status__c = 'Offer',
    Application_Date__c = Date.newInstance(2024, 1, 3),
    Job_Description__c = 'Lead cross-functional technology projects in banking operations. Manage timelines, budgets, and stakeholder communications.',
    Notes__c = 'Received offer with good benefits package. Team seems collaborative and supportive.',
    Contact_Name__c = 'Amanda Davis',
    Contact_Email__c = 'amanda.davis@wellsfargo.com',
    Job_URL__c = 'https://wellsfargo.com/careers/pm'
));

// Healthcare Companies
jobApps.add(new Job_Application__c(
    Company_Name__c = 'Johnson & Johnson',
    Position_Title__c = 'Data Analyst',
    Salary__c = 75000,
    Status__c = 'Applied',
    Application_Date__c = Date.newInstance(2024, 1, 26),
    Job_Description__c = 'Analyze clinical trial data and healthcare outcomes. Support regulatory submissions and business intelligence initiatives.',
    Notes__c = 'Healthcare focus aligns with my interests. Good opportunity to make meaningful impact.',
    Contact_Name__c = 'Robert Anderson',
    Contact_Email__c = 'robert.anderson@jnj.com',
    Job_URL__c = 'https://jnj.com/careers/data-analyst'
));

jobApps.add(new Job_Application__c(
    Company_Name__c = 'Pfizer',
    Position_Title__c = 'Clinical Research Associate',
    Salary__c = 70000,
    Status__c = 'Interviewing',
    Application_Date__c = Date.newInstance(2024, 1, 14),
    Job_Description__c = 'Monitor clinical trials and ensure compliance with regulatory requirements. Travel to investigational sites for data collection.',
    Notes__c = 'Phone interview went well. Interested in their COVID vaccine research. Some travel required.',
    Contact_Name__c = 'Emily White',
    Contact_Email__c = 'emily.white@pfizer.com',
    Job_URL__c = 'https://pfizer.com/careers/cra'
));

// Consulting Companies
jobApps.add(new Job_Application__c(
    Company_Name__c = 'McKinsey & Company',
    Position_Title__c = 'Business Analyst',
    Salary__c = 95000,
    Status__c = 'Interviewing',
    Application_Date__c = Date.newInstance(2024, 1, 11),
    Job_Description__c = 'Support client engagements across various industries. Conduct market research and develop strategic recommendations.',
    Notes__c = 'Prestigious consulting opportunity. Case interview preparation in progress. Steep learning curve expected.',
    Contact_Name__c = 'Michelle Lewis',
    Contact_Email__c = 'michelle.lewis@mckinsey.com',
    Job_URL__c = 'https://mckinsey.com/careers/business-analyst'
));

jobApps.add(new Job_Application__c(
    Company_Name__c = 'Accenture',
    Position_Title__c = 'Digital Consultant',
    Salary__c = 82000,
    Status__c = 'Offer',
    Application_Date__c = Date.newInstance(2024, 1, 7),
    Job_Description__c = 'Lead digital transformation initiatives for Fortune 500 clients. Implement cloud solutions and automation technologies.',
    Notes__c = 'Received offer with signing bonus. Good training program and international opportunities.',
    Contact_Name__c = 'Nicole Young',
    Contact_Email__c = 'nicole.young@accenture.com',
    Job_URL__c = 'https://accenture.com/careers/digital'
));

// Startups
jobApps.add(new Job_Application__c(
    Company_Name__c = 'Stripe',
    Position_Title__c = 'Backend Engineer',
    Salary__c = 115000,
    Status__c = 'Applied',
    Application_Date__c = Date.newInstance(2024, 1, 16),
    Job_Description__c = 'Build scalable payment processing systems and APIs. Work on financial infrastructure used by millions of businesses.',
    Notes__c = 'Fintech leader with strong engineering culture. Applied after using their APIs in personal projects.',
    Contact_Name__c = 'Stephanie Wright',
    Contact_Email__c = 'stephanie.wright@stripe.com',
    Job_URL__c = 'https://stripe.com/careers/backend'
));

jobApps.add(new Job_Application__c(
    Company_Name__c = 'Zoom',
    Position_Title__c = 'Customer Success Manager',
    Salary__c = 75000,
    Status__c = 'Interviewing',
    Application_Date__c = Date.newInstance(2024, 1, 21),
    Job_Description__c = 'Manage relationships with enterprise customers. Drive adoption and expansion of video communication solutions.',
    Notes__c = 'Growing company with remote-first culture. Customer success role aligns with my communication skills.',
    Contact_Name__c = 'Andrew Lopez',
    Contact_Email__c = 'andrew.lopez@zoom.us',
    Job_URL__c = 'https://zoom.us/careers/csm'
));

// Insert all job applications
insert jobApps;

System.debug('Successfully created ' + jobApps.size() + ' job applications!');
System.debug('Job Application IDs: ' + jobApps);

// The triggers will automatically create tasks and calculate salaries!
