// Populate robust data for all Job Application records
System.debug('=== POPULATING ROBUST JOB APPLICATION DATA ===');

// Get all existing Job Application records
List<Job_Application__c> allApps = [
    SELECT Id, Name, Company_Name__c, Position_Title__c, Status__c, 
           Salary__c, Location__c, Rating__c, Application_Date__c,
           Follow_Up_Date__c, Notes__c, Description__c, Job_URL__c
    FROM Job_Application__c
];

System.debug('📊 Found ' + allApps.size() + ' Job Application records to enhance');

if (allApps.isEmpty()) {
    System.debug('⚠️ No records found. Create some Job Applications first!');
    return;
}

// Define realistic data sets
List<String> locations = new List<String>{'Remote', 'Hybrid', 'On-site'};

Map<String, List<Integer>> salaryRanges = new Map<String, List<Integer>>{
    'Software Engineer' => new List<Integer>{85000, 120000},
    'Senior Software Engineer' => new List<Integer>{110000, 160000},
    'Lead Developer' => new List<Integer>{130000, 180000},
    'Engineering Manager' => new List<Integer>{140000, 200000},
    'Product Manager' => new List<Integer>{95000, 140000},
    'Senior Product Manager' => new List<Integer>{125000, 175000},
    'Data Scientist' => new List<Integer>{90000, 135000},
    'Senior Data Scientist' => new List<Integer>{120000, 170000},
    'DevOps Engineer' => new List<Integer>{95000, 145000},
    'Solutions Architect' => new List<Integer>{125000, 185000},
    'Technical Lead' => new List<Integer>{115000, 165000},
    'Full Stack Developer' => new List<Integer>{80000, 125000},
    'Frontend Developer' => new List<Integer>{75000, 115000},
    'Backend Developer' => new List<Integer>{85000, 130000},
    'Mobile Developer' => new List<Integer>{80000, 125000},
    'QA Engineer' => new List<Integer>{70000, 105000},
    'Security Engineer' => new List<Integer>{100000, 150000},
    'Cloud Engineer' => new List<Integer>{95000, 145000},
    'Salesforce Developer' => new List<Integer>{85000, 130000},
    'Salesforce Architect' => new List<Integer>{130000, 190000}
};

Map<String, String> jobDescriptions = new Map<String, String>{
    'Software Engineer' => 'Design and develop scalable software solutions using modern technologies. Collaborate with cross-functional teams to deliver high-quality products.',
    'Senior Software Engineer' => 'Lead technical design and implementation of complex software systems. Mentor junior developers and drive architectural decisions.',
    'Lead Developer' => 'Oversee development team and technical strategy. Responsible for code quality, architecture decisions, and team mentorship.',
    'Engineering Manager' => 'Manage engineering team while maintaining technical involvement. Drive product delivery and team growth.',
    'Product Manager' => 'Define product strategy and roadmap. Work closely with engineering, design, and business stakeholders.',
    'Data Scientist' => 'Analyze complex datasets to drive business insights. Build predictive models and data-driven solutions.',
    'DevOps Engineer' => 'Design and maintain CI/CD pipelines. Manage cloud infrastructure and deployment automation.',
    'Solutions Architect' => 'Design enterprise-level technical solutions. Lead architectural discussions and technology decisions.',
    'Salesforce Developer' => 'Develop custom Salesforce solutions including Apex, Lightning Web Components, and integrations.',
    'Salesforce Architect' => 'Design comprehensive Salesforce solutions for enterprise clients. Lead technical implementations and best practices.'
};

Map<String, String> jobUrls = new Map<String, String>{
    'LinkedIn' => 'https://linkedin.com/jobs/view/12345',
    'Indeed' => 'https://indeed.com/viewjob?jk=abc123',
    'Glassdoor' => 'https://glassdoor.com/job-listing/xyz789',
    'Company Website' => 'https://company.com/careers/position-123',
    'AngelList' => 'https://angel.co/company/startup/jobs/456',
    'Stack Overflow' => 'https://stackoverflow.com/jobs/789'
};

List<String> urlSources = new List<String>(jobUrls.keySet());

// Enhanced notes based on status
Map<String, List<String>> statusNotes = new Map<String, List<String>>{
    'Saved' => new List<String>{
        'Found this role through LinkedIn. Looks like a great fit for my skills.',
        'Company has excellent reviews on Glassdoor. Planning to apply this week.',
        'Interesting tech stack - React, Node.js, AWS. Matches my experience perfectly.'
    },
    'Applying' => new List<String>{
        'Currently working on cover letter. Need to highlight my recent project experience.',
        'Tailoring resume to match job requirements. Emphasizing relevant skills.',
        'Researching company culture and recent news for application.'
    },
    'Applied' => new List<String>{
        'Application submitted via company portal. Confirmation email received.',
        'Applied through recruiter referral. Should hear back within a week.',
        'Submitted application with portfolio links. Fingers crossed!'
    },
    'Interviewing' => new List<String>{
        'Phone screen scheduled for next Tuesday at 2 PM.',
        'Technical interview went well. Discussed system design and coding challenges.',
        'Final round with hiring manager. Great conversation about team dynamics.'
    },
    'Negotiating' => new List<String>{
        'Received initial offer. Negotiating salary and start date.',
        'Discussing remote work options and benefits package.',
        'Counter-offered with salary expectations. Waiting for response.'
    },
    'Accepted' => new List<String>{
        'Offer accepted! Start date confirmed for next month.',
        'Excited to join the team. Great company culture and growth opportunities.',
        'Negotiated successfully. Looking forward to new challenges.'
    },
    'Closed' => new List<String>{
        'Position filled internally. Good learning experience.',
        'Decided to pursue other opportunities. Company was great though.',
        'Role requirements changed. No longer a good fit.'
    }
};

// Update each record with robust data
List<Job_Application__c> appsToUpdate = new List<Job_Application__c>();

for (Job_Application__c app : allApps) {
    Boolean needsUpdate = false;
    
    // Add salary if missing
    if (app.Salary__c == null) {
        String position = app.Position_Title__c != null ? app.Position_Title__c : 'Software Engineer';
        List<Integer> range = salaryRanges.get(position);
        if (range == null) {
            // Default range for unknown positions
            range = new List<Integer>{80000, 130000};
        }
        
        // Generate random salary within range
        Integer minSalary = range[0];
        Integer maxSalary = range[1];
        Integer salaryRange = maxSalary - minSalary;
        app.Salary__c = minSalary + (Math.random() * salaryRange).intValue();
        needsUpdate = true;
    }
    
    // Add location if missing
    if (String.isBlank(app.Location__c)) {
        Integer locationIndex = (Math.random() * locations.size()).intValue();
        app.Location__c = locations[locationIndex];
        needsUpdate = true;
    }
    
    // Add rating if missing
    if (String.isBlank(app.Rating__c)) {
        // Generate weighted rating (more 4s and 5s than 1s and 2s)
        List<String> weightedRatings = new List<String>{'3', '3', '4', '4', '4', '5', '5', '2', '1'};
        Integer ratingIndex = (Math.random() * weightedRatings.size()).intValue();
        app.Rating__c = weightedRatings[ratingIndex];
        needsUpdate = true;
    }
    
    // Add application date if missing
    if (app.Application_Date__c == null) {
        // Random date within last 60 days
        Integer daysAgo = (Math.random() * 60).intValue();
        app.Application_Date__c = Date.today().addDays(-daysAgo);
        needsUpdate = true;
    }
    
    // Add follow-up date based on status
    if (app.Follow_Up_Date__c == null && app.Status__c != 'Closed' && app.Status__c != 'Accepted') {
        Integer daysFromNow = 3 + (Math.random() * 10).intValue(); // 3-13 days from now
        app.Follow_Up_Date__c = Date.today().addDays(daysFromNow);
        needsUpdate = true;
    }
    
    // Add description if missing
    if (String.isBlank(app.Description__c)) {
        String position = app.Position_Title__c != null ? app.Position_Title__c : 'Software Engineer';
        String description = jobDescriptions.get(position);
        if (description == null) {
            description = 'Exciting opportunity to work with cutting-edge technologies in a collaborative environment. Join our team and make an impact!';
        }
        app.Description__c = description;
        needsUpdate = true;
    }
    
    // Add job URL if missing
    if (String.isBlank(app.Job_URL__c)) {
        Integer sourceIndex = (Math.random() * urlSources.size()).intValue();
        String source = urlSources[sourceIndex];
        app.Job_URL__c = jobUrls.get(source);
        needsUpdate = true;
    }
    
    // Add notes if missing
    if (String.isBlank(app.Notes__c)) {
        String status = app.Status__c != null ? app.Status__c : 'Saved';
        List<String> notesForStatus = statusNotes.get(status);
        if (notesForStatus != null && !notesForStatus.isEmpty()) {
            Integer noteIndex = (Math.random() * notesForStatus.size()).intValue();
            app.Notes__c = notesForStatus[noteIndex];
            needsUpdate = true;
        }
    }
    
    if (needsUpdate) {
        appsToUpdate.add(app);
    }
}

// Update records
if (!appsToUpdate.isEmpty()) {
    try {
        update appsToUpdate;
        System.debug('✅ Successfully updated ' + appsToUpdate.size() + ' Job Application records');
        
        // Show summary of updates
        System.debug('📊 DATA ENHANCEMENT SUMMARY:');
        for (Job_Application__c app : appsToUpdate) {
            System.debug('  • ' + app.Name + ' (' + app.Company_Name__c + ')');
            System.debug('    - Salary: $' + app.Salary__c?.format());
            System.debug('    - Location: ' + app.Location__c);
            System.debug('    - Rating: ' + app.Rating__c + ' stars');
            System.debug('    - Status: ' + app.Status__c);
        }
        
    } catch (Exception e) {
        System.debug('❌ Error updating records: ' + e.getMessage());
    }
} else {
    System.debug('ℹ️ All records already have complete data');
}

System.debug('');
System.debug('🎉 DATA ENHANCEMENT COMPLETE!');
System.debug('📱 Go to your Job Application Tracker app to see the enhanced data');
System.debug('📋 Try the different list views to see organized, professional data');
System.debug('⭐ Your job applications now have realistic salaries, locations, ratings, and notes!');
