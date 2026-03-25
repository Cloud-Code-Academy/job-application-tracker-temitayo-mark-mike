// Populate missing fields on all Job Application records
// Fields to fill: Description__c, Job_URL__c, Follow_Up_Date__c, Rating__c, Application_Date__c

List<Job_Application__c> apps = [
    SELECT Id, Company_Name__c, Position_Title__c, Status__c, Salary__c,
           Application_Date__c, Follow_Up_Date__c, Rating__c,
           Description__c, Job_URL__c
    FROM Job_Application__c
    ORDER BY Company_Name__c
];

Map<String, String> descriptions = new Map<String, String>{
    'Salesforce' => 'Build and maintain enterprise CRM solutions on the Salesforce platform. Work with Apex, Lightning Web Components, and integration patterns. Collaborate with product teams to deliver scalable cloud-based solutions.',
    'Google' => 'Join Google Cloud team to design and implement large-scale distributed systems. Work on infrastructure that serves billions of users. Strong focus on reliability engineering and performance optimization.',
    'Microsoft' => 'Develop next-generation cloud services for Azure. Work across the full stack with C#, TypeScript, and microservices architecture. Contribute to products used by millions of enterprise customers worldwide.',
    'Deloitte' => 'Technology consulting role focused on digital transformation initiatives for Fortune 500 clients. Lead Salesforce implementation projects including architecture design, custom development, and data migration.',
    'Accenture' => 'Cloud migration and modernization consulting for enterprise clients. Work with multi-cloud strategies spanning AWS, Azure, and GCP. Lead technical teams through complex integration projects.',
    'Amazon' => 'Software development role on AWS services team. Build highly available, scalable systems processing millions of transactions. Practice Amazons leadership principles in a fast-paced engineering culture.',
    'Slack' => 'Frontend engineering role building real-time collaboration features. Work with React, TypeScript, and WebSocket technologies. Focus on performance optimization for large enterprise deployments.',
    'IBM' => 'Enterprise software engineering role focusing on hybrid cloud solutions. Work with Kubernetes, OpenShift, and AI/ML integration. Contribute to open-source projects and cloud-native development.',
    'Netflix' => 'Backend engineering role on the content delivery platform. Build microservices handling massive scale video streaming. Work with Java, Spring Boot, and distributed data stores.',
    'Stripe' => 'Payments infrastructure engineering role. Build reliable, secure financial systems processing billions in transactions. Work with Ruby, Go, and distributed systems at scale.',
    'Shopify' => 'Commerce platform engineering role. Build tools that power millions of merchants worldwide. Work with Ruby on Rails, React, and GraphQL in a remote-first culture.',
    'Twilio' => 'Communications platform engineering. Build APIs that power voice, messaging, and video for developers worldwide. Work with distributed systems and real-time communication protocols.',
    'Cognizant' => 'Digital engineering and technology modernization consulting. Lead Salesforce and cloud transformation projects for global enterprise clients. Architecture design and technical delivery.',
    'Meta' => 'Infrastructure engineering role working on large-scale distributed systems. Build and maintain services handling billions of daily active users. Focus on reliability and performance at massive scale.',
    'Apple' => 'Software engineering role on cloud services team. Build secure, privacy-focused backend systems for Apple services. Work with Swift, Java, and cloud-native technologies.',
    'Uber' => 'Platform engineering role on marketplace systems. Build real-time matching and pricing algorithms. Work with Go, Java, and stream processing frameworks at massive scale.',
    'LinkedIn' => 'Backend engineering role on the professional network platform. Build data-intensive features serving 900M+ members. Work with Java, Kafka, and machine learning pipelines.',
    'HubSpot' => 'Product engineering role building CRM and marketing automation tools. Full-stack development with Java, React, and microservices. Customer-centric product development culture.',
    'ServiceNow' => 'Platform engineering role building enterprise workflow automation. Develop features on the Now Platform using JavaScript, Angular, and Java. Focus on AI-powered digital workflows.',
    'Workday' => 'Enterprise cloud application engineering. Build HR and financial management solutions used by Fortune 500 companies. Work with Java, cloud infrastructure, and large-scale data processing.',
    'Adobe' => 'Creative Cloud platform engineering. Build tools and services powering creative workflows for millions of designers and developers. Work with modern web technologies and cloud infrastructure.',
    'Atlassian' => 'Cloud platform engineering for Jira and Confluence. Build scalable infrastructure serving millions of teams worldwide. Work with Kotlin, AWS, and distributed systems in a remote-first culture.',
    'Palantir' => 'Forward-deployed engineering role. Work directly with government and commercial clients to deploy data analytics solutions. Build custom integrations and data pipeline architectures.',
    'Datadog' => 'Observability platform engineering. Build next-generation APM and monitoring tools. Work with Go, Python, and distributed tracing systems at massive scale.',
    'Figma' => 'Product engineering role building collaborative design tools. Work on real-time collaboration features, canvas rendering, and plugin architecture. Modern web technologies and WebGL.',
    'Square' => 'Payments platform engineering. Build secure, reliable financial services for merchants of all sizes. Work with Java, Kotlin, and distributed transaction processing systems.',
    'Snowflake' => 'Data cloud platform engineering. Build the data warehouse that powers modern analytics. Work with C++, Java, and distributed computing at petabyte scale.',
    'Notion' => 'Full-stack engineering on a productivity platform. Build collaborative workspace features used by millions. Small, high-impact engineering team working with TypeScript and React.',
    'Vercel' => 'Developer experience engineering for the Next.js platform. Build deployment and hosting infrastructure. Work with TypeScript, Rust, and edge computing technologies.',
    'Plaid' => 'Financial data API engineering. Build secure integrations connecting applications to bank accounts. Work with Python, Go, and financial data processing pipelines.',
    'Airbnb' => 'Staff engineering role on the marketplace platform. Design and build systems powering travel experiences for millions. Lead technical architecture decisions and mentor engineering teams.',
    'Spotify' => 'Backend engineering on the personalization team. Build recommendation algorithms and content delivery systems. Work with Java, Python, and machine learning infrastructure.',
    'Coinbase' => 'Senior platform engineering for cryptocurrency exchange. Build secure, scalable trading infrastructure. Work with Go, PostgreSQL, and blockchain integration technologies.',
    'DoorDash' => 'Logistics engineering role. Build routing optimization and delivery prediction systems. Work with Kotlin, Python, and real-time geospatial data processing.',
    'Dropbox' => 'Senior engineering on the file sync team. Build distributed storage and sync systems. Work with Rust, Python, and distributed consensus algorithms in a Virtual First company.',
    'Robinhood' => 'Backend engineering on the trading platform. Build low-latency order execution systems. Work with Python, Go, and real-time market data processing.',
    'Pinterest' => 'Full-stack engineering on the ads platform. Build advertiser tools and ad delivery systems. Work with Java, Python, and large-scale recommendation systems.',
    'Lyft' => 'Senior engineering on the maps and ETA team. Build routing algorithms and prediction models. Work with Go, Python, and geospatial processing at scale.',
    'GitLab' => 'Staff backend engineering on the DevOps platform. Build CI/CD and version control features. Work with Ruby, Go, and distributed systems in an all-remote company.',
    'Confluent' => 'Engineering on the Kafka cloud platform. Build managed streaming services for enterprise clients. Work with Java, distributed systems, and event-driven architectures.',
    'OpenAI' => 'Platform engineering building infrastructure for AI research and deployment. Work with Python, distributed training systems, and large-scale GPU computing. Shape the future of artificial intelligence.',
    'Anthropic' => 'Backend engineering focused on AI safety research infrastructure. Build systems for training and evaluating AI models. Work with Python, JAX, and distributed ML pipelines at scale.',
    'Databricks' => 'Engineering on the Unity Catalog team. Build data governance and management features for the lakehouse platform. Work with Scala, Spark, and distributed data processing.',
    'Elastic' => 'Core engineering on the Elasticsearch search engine. Build distributed search and analytics features. Work with Java, Lucene, and distributed systems architecture.',
    'HashiCorp' => 'Engineering on Terraform. Build infrastructure-as-code tools used by millions of developers. Work with Go, cloud APIs, and developer tooling ecosystem.',
    'Twitter/X' => 'Senior engineering role on the content platform. Real-time systems and distributed architecture. Role deprioritized due to organizational restructuring.',
    'Oracle' => 'Cloud engineering role on Oracle Cloud Infrastructure. Build and maintain enterprise cloud services. Position filled before final interview round.',
    'VMware' => 'Platform engineering on virtualization products. Focus on container orchestration and cloud-native infrastructure. Role restructured following Broadcom acquisition.',
    'Cisco' => 'Software development on networking and collaboration tools. Build enterprise communication and security solutions. Decided to pursue higher-comp opportunities.'
};

Map<String, String> jobUrls = new Map<String, String>{
    'Salesforce' => 'https://salesforce.com/careers',
    'Google' => 'https://careers.google.com',
    'Microsoft' => 'https://careers.microsoft.com',
    'Deloitte' => 'https://apply.deloitte.com',
    'Accenture' => 'https://accenture.com/careers',
    'Amazon' => 'https://amazon.jobs',
    'Slack' => 'https://slack.com/careers',
    'IBM' => 'https://ibm.com/employment',
    'Netflix' => 'https://jobs.netflix.com',
    'Stripe' => 'https://stripe.com/jobs',
    'Shopify' => 'https://shopify.com/careers',
    'Twilio' => 'https://twilio.com/careers',
    'Cognizant' => 'https://careers.cognizant.com',
    'Meta' => 'https://metacareers.com',
    'Apple' => 'https://jobs.apple.com',
    'Uber' => 'https://uber.com/careers',
    'LinkedIn' => 'https://careers.linkedin.com',
    'HubSpot' => 'https://hubspot.com/careers',
    'ServiceNow' => 'https://servicenow.com/careers',
    'Workday' => 'https://workday.com/careers',
    'Adobe' => 'https://adobe.com/careers',
    'Atlassian' => 'https://atlassian.com/careers',
    'Palantir' => 'https://palantir.com/careers',
    'Datadog' => 'https://careers.datadoghq.com',
    'Figma' => 'https://figma.com/careers',
    'Square' => 'https://squareup.com/careers',
    'Snowflake' => 'https://careers.snowflake.com',
    'Notion' => 'https://notion.so/careers',
    'Vercel' => 'https://vercel.com/careers',
    'Plaid' => 'https://plaid.com/careers',
    'Airbnb' => 'https://careers.airbnb.com',
    'Spotify' => 'https://lifeatspotify.com',
    'Coinbase' => 'https://coinbase.com/careers',
    'DoorDash' => 'https://careers.doordash.com',
    'Dropbox' => 'https://dropbox.com/jobs',
    'Robinhood' => 'https://careers.robinhood.com',
    'Pinterest' => 'https://pinterestcareers.com',
    'Lyft' => 'https://lyft.com/careers',
    'GitLab' => 'https://about.gitlab.com/jobs',
    'Confluent' => 'https://confluent.io/careers',
    'OpenAI' => 'https://openai.com/careers',
    'Anthropic' => 'https://anthropic.com/careers',
    'Databricks' => 'https://databricks.com/careers',
    'Elastic' => 'https://elastic.co/careers',
    'HashiCorp' => 'https://hashicorp.com/careers',
    'Twitter/X' => 'https://careers.twitter.com',
    'Oracle' => 'https://oracle.com/careers',
    'VMware' => 'https://careers.vmware.com',
    'Cisco' => 'https://jobs.cisco.com'
};

// Rating values based on status and company tier
Map<String, String> defaultRatings = new Map<String, String>{
    'Salesforce' => '5', 'Google' => '5', 'Microsoft' => '4', 'Deloitte' => '3',
    'Accenture' => '3', 'Amazon' => '5', 'Slack' => '4', 'IBM' => '3',
    'Netflix' => '5', 'Stripe' => '5', 'Shopify' => '4', 'Twilio' => '3',
    'Cognizant' => '3', 'Meta' => '4', 'Apple' => '5', 'Uber' => '4',
    'LinkedIn' => '4', 'HubSpot' => '4', 'ServiceNow' => '4', 'Workday' => '3',
    'Adobe' => '4', 'Atlassian' => '5', 'Palantir' => '3', 'Datadog' => '4',
    'Figma' => '5', 'Square' => '4', 'Snowflake' => '4', 'Notion' => '5',
    'Vercel' => '4', 'Plaid' => '3', 'Airbnb' => '5', 'Spotify' => '5',
    'Coinbase' => '4', 'DoorDash' => '3', 'Dropbox' => '4', 'Robinhood' => '4',
    'Pinterest' => '3', 'Lyft' => '4', 'GitLab' => '5', 'Confluent' => '4',
    'OpenAI' => '5', 'Anthropic' => '5', 'Databricks' => '4', 'Elastic' => '3',
    'HashiCorp' => '4', 'Twitter/X' => '2', 'Oracle' => '2', 'VMware' => '3',
    'Cisco' => '2'
};

List<Job_Application__c> toUpdate = new List<Job_Application__c>();

for (Job_Application__c app : apps) {
    Boolean changed = false;
    String company = app.Company_Name__c;

    // Fill Description__c
    if (String.isBlank(app.Description__c) && descriptions.containsKey(company)) {
        app.Description__c = descriptions.get(company);
        changed = true;
    }

    // Fill Job_URL__c
    if (String.isBlank(app.Job_URL__c) && jobUrls.containsKey(company)) {
        app.Job_URL__c = jobUrls.get(company);
        changed = true;
    }

    // Fill Rating__c
    if (String.isBlank(app.Rating__c) && defaultRatings.containsKey(company)) {
        app.Rating__c = defaultRatings.get(company);
        changed = true;
    }

    // Fill Application_Date__c for Saved records (estimate)
    if (app.Application_Date__c == null) {
        if (app.Status__c == 'Saved') {
            // Saved records: date they were saved/bookmarked
            app.Application_Date__c = Date.today().addDays(-Math.mod(Math.abs(company.hashCode()), 14) - 1);
        }
        changed = true;
    }

    // Fill Follow_Up_Date__c based on status
    if (app.Follow_Up_Date__c == null) {
        if (app.Status__c == 'Interviewing') {
            app.Follow_Up_Date__c = Date.today().addDays(Math.mod(Math.abs(company.hashCode()), 5) + 1);
        } else if (app.Status__c == 'Negotiating') {
            app.Follow_Up_Date__c = Date.today().addDays(Math.mod(Math.abs(company.hashCode()), 3) + 1);
        } else if (app.Status__c == 'Applied') {
            app.Follow_Up_Date__c = Date.today().addDays(Math.mod(Math.abs(company.hashCode()), 7) + 3);
        } else if (app.Status__c == 'Applying') {
            app.Follow_Up_Date__c = Date.today().addDays(Math.mod(Math.abs(company.hashCode()), 3) + 1);
        } else if (app.Status__c == 'Saved') {
            app.Follow_Up_Date__c = Date.today().addDays(Math.mod(Math.abs(company.hashCode()), 10) + 3);
        } else if (app.Status__c == 'Accepted') {
            app.Follow_Up_Date__c = Date.today().addDays(Math.mod(Math.abs(company.hashCode()), 5) + 1);
        }
        // Closed records don't need follow-up
        if (app.Follow_Up_Date__c != null) {
            changed = true;
        }
    }

    if (changed) {
        toUpdate.add(app);
    }
}

if (!toUpdate.isEmpty()) {
    update toUpdate;
}

System.debug('Updated ' + toUpdate.size() + ' records');

// Verify completeness after update
Integer postDescription = 0, postJobUrl = 0, postRating = 0, postFollowUp = 0, postAppDate = 0;
List<Job_Application__c> verify = [
    SELECT Description__c, Job_URL__c, Rating__c, Follow_Up_Date__c, Application_Date__c
    FROM Job_Application__c
];
for (Job_Application__c a : verify) {
    if (String.isBlank(a.Description__c)) postDescription++;
    if (String.isBlank(a.Job_URL__c)) postJobUrl++;
    if (String.isBlank(a.Rating__c)) postRating++;
    if (a.Follow_Up_Date__c == null) postFollowUp++;
    if (a.Application_Date__c == null) postAppDate++;
}
System.debug('=== POST-UPDATE AUDIT ===');
System.debug('Description__c still missing: ' + postDescription);
System.debug('Job_URL__c still missing: ' + postJobUrl);
System.debug('Rating__c still missing: ' + postRating);
System.debug('Follow_Up_Date__c still missing: ' + postFollowUp);
System.debug('Application_Date__c still missing: ' + postAppDate);
