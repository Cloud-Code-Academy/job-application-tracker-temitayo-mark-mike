# 🎓 COMPREHENSIVE LEARNING PATH
## From Zero to Senior Salesforce Developer

> **Project-Based Learning Journey**: Master every aspect of the Job Application Tracker while building production-ready skills

**Last Updated**: November 14, 2025
**Estimated Timeline**: 12-18 months (aggressive), 18-24 months (comfortable)
**Prerequisites**: None - we start from zero!

---

## 📋 Table of Contents

1. [Learning Path Overview](#learning-path-overview)
2. [Phase 1: Foundation (Months 1-3) - Junior Level](#phase-1-foundation-months-1-3---junior-level)
3. [Phase 2: Intermediate (Months 4-8) - Mid Level](#phase-2-intermediate-months-4-8---mid-level)
4. [Phase 3: Advanced (Months 9-14) - Senior Level](#phase-3-advanced-months-9-14---senior-level)
5. [Phase 4: Mastery (Months 15-18+) - Architect Level](#phase-4-mastery-months-15-18---architect-level)
6. [Complementary Skills Timeline](#complementary-skills-timeline)
7. [Project-Specific Deep Dives](#project-specific-deep-dives)
8. [Learning Resources](#learning-resources)

---

## 🗺️ Learning Path Overview

### Skill Progression Model

```
Month 0-3:  FOUNDATION → Junior Developer Ready
Month 4-8:  INTERMEDIATE → Mid-Level Developer Ready
Month 9-14: ADVANCED → Senior Developer Ready
Month 15+:  MASTERY → Architect/Lead Ready
```

### Core Competency Areas

1. **Salesforce Platform** - CRM, data model, declarative tools
2. **Programming** - Apex, JavaScript, patterns
3. **Frontend** - Lightning Web Components, UI/UX
4. **Integration** - APIs, external systems
5. **Architecture** - Design patterns, scalability
6. **DevOps** - CI/CD, version control, deployment
7. **Testing** - Unit tests, integration tests, TDD
8. **Soft Skills** - Communication, problem-solving, documentation

---

## 📚 PHASE 1: FOUNDATION (Months 1-3) - Junior Level

### 🎯 Goal
Understand core Salesforce concepts and basic programming. Be able to create simple customizations and read existing code.

---

### Month 1: Salesforce Basics & Data Fundamentals

#### Week 1-2: Introduction to Salesforce & CRM Concepts

**What You'll Learn:**
- What is Salesforce? (CRM, Cloud, SaaS concepts)
- Salesforce ecosystem (Sales Cloud, Service Cloud, Platform)
- Core objects: Account, Contact, Opportunity, Lead, Case
- User interface navigation (Lightning Experience)
- Setup menu and App Manager

**Project Connection:**
- Understand why we use `Contact` and `Account` in the Job Application Tracker
- Explore `Primary_Contact__c` lookup relationship
- Learn how `OwnerId` relates to User object

**Hands-On Exercise:**
```
1. Sign up for Salesforce Developer Edition org (free)
2. Navigate Setup → Object Manager
3. Explore Account and Contact objects
4. Create 5 Accounts manually
5. Create 10 Contacts related to those Accounts
6. Document what standard fields you see
```

**Complementary Tech Skills:**
- **Basic Computer Science**: What is a database? What are tables/records?
- **Web Basics**: How browsers work, client-server architecture
- **Cloud Computing 101**: What is SaaS vs PaaS vs IaaS?

**Resources:**
- Trailhead: [Salesforce Platform Basics](https://trailhead.salesforce.com/content/learn/modules/starting_force_com)
- Trailhead: [Data Modeling](https://trailhead.salesforce.com/content/learn/modules/data_modeling)
- YouTube: "What is Salesforce?" (Salesforce Ben, Salesforce Hulk)

---

#### Week 3-4: Custom Objects, Fields & Relationships

**What You'll Learn:**
- Creating custom objects
- Field types: Text, Number, Picklist, Date, Checkbox, Currency, URL
- Relationship types: Lookup, Master-Detail, Hierarchical
- Page layouts and field-level security
- Record types and business processes

**Project Connection:**
- Analyze `Job_Application__c` custom object (force-app/main/default/objects/Job_Application__c)
- Study all 22 custom fields and their purposes
- Understand `Primary_Contact__c` lookup relationship
- Explore Global Value Set: `Job_Application_Status`

**Hands-On Exercise:**
```
FILE TO STUDY: force-app/main/default/objects/Job_Application__c/

1. Create a simplified version of Job_Application__c with these fields:
   - Company_Name__c (Text)
   - Position_Title__c (Text)
   - Status__c (Picklist: Saved, Applied, Interviewing, Closed)
   - Application_Date__c (Date)
   - Salary__c (Currency)
   - Primary_Contact__c (Lookup to Contact)

2. Create 20 test records manually
3. Experiment with page layouts
4. Try filtering and list views
```

**Complementary Tech Skills:**
- **Database Concepts**: Primary keys, foreign keys, one-to-many relationships
- **Data Types**: Understanding different data types across programming
- **XML Basics**: Salesforce metadata is stored as XML

**Resources:**
- Trailhead: [Data Modeling](https://trailhead.salesforce.com/content/learn/modules/data_modeling)
- Read: `docs/DATA_DICTIONARY.md` in this project
- Practice: Create 3 custom objects with various field types

---

### Month 2: Automation & Validation

#### Week 1-2: Declarative Automation (Clicks, Not Code)

**What You'll Learn:**
- Workflow Rules (legacy, still important to know)
- Process Builder (legacy, transitioning to Flows)
- Flow Builder: Record-Triggered Flows, Screen Flows
- Formula fields and Roll-Up Summary fields
- Validation rules

**Project Connection:**
- Study `Job_Application_Workflow.flow-meta.xml`
- Analyze 3 validation rules:
  - `Salary_Range_Validation.validationRule-meta.xml`
  - `Application_Date_Validation.validationRule-meta.xml`
  - `Status_Progression_Validation.validationRule-meta.xml`
- Explore formula fields for tax calculations

**Hands-On Exercise:**
```
FILES TO STUDY:
- force-app/main/default/flows/Job_Application_Workflow.flow-meta.xml
- force-app/main/default/objects/Job_Application__c/validationRules/

1. Create a Record-Triggered Flow that:
   - Triggers on Job Application create
   - Creates a Task when Status = "Applied"

2. Build validation rule:
   - Application_Date__c cannot be in the future
   - Salary__c must be between $20,000 and $1,000,000

3. Create formula field:
   - Calculate days since Application_Date__c
```

**Complementary Tech Skills:**
- **Logic & Conditionals**: IF/THEN/ELSE thinking
- **Boolean Logic**: AND, OR, NOT operators
- **Regular Expressions**: Pattern matching basics
- **Business Process Mapping**: Flowcharting tools (Lucidchart, Draw.io)

**Resources:**
- Trailhead: [Flow Builder](https://trailhead.salesforce.com/content/learn/modules/business_process_automation)
- Trailhead: [Formula Fields](https://trailhead.salesforce.com/content/learn/modules/point_click_business_logic)
- Read: Salesforce Formula Field Reference

---

#### Week 3-4: Security Model & User Management

**What You'll Learn:**
- Profiles vs Permission Sets vs Permission Set Groups
- Object-level security (OWD - Organization-Wide Defaults)
- Field-level security
- Record-level security (sharing rules, manual sharing)
- Role hierarchy
- Public groups

**Project Connection:**
- Study `Job_Application_Manager.permissionset-meta.xml`
- Understand why Job Application sharing model is "Private"
- Explore field-level security on salary fields
- Learn about `with sharing` keyword in Apex

**Hands-On Exercise:**
```
FILE TO STUDY: force-app/main/default/permissionsets/Job_Application_Manager.permissionset-meta.xml

1. Create a Permission Set for "Job Application Manager"
2. Grant Read/Create/Edit/Delete on Job_Application__c
3. Grant edit access to all custom fields
4. Test with a new user (create test user)
5. Document what happens when permission is removed
```

**Complementary Tech Skills:**
- **Cybersecurity Basics**: Principle of least privilege
- **Access Control Models**: RBAC (Role-Based Access Control)
- **Authentication vs Authorization**
- **Security Best Practices**: OWASP Top 10 awareness

**Resources:**
- Trailhead: [Data Security](https://trailhead.salesforce.com/content/learn/modules/data_security)
- Read: `docs/TECHNICAL_ARCHITECTURE_GUIDE.md` (Security section)

---

### Month 3: Introduction to Programming

#### Week 1-2: Programming Fundamentals (Language Agnostic)

**What You'll Learn:**
- Variables and data types
- Operators: arithmetic, comparison, logical
- Control structures: if/else, switch
- Loops: for, while, do-while
- Collections: Arrays, Lists, Maps, Sets
- Functions/Methods
- Comments and documentation

**Project Connection:**
- Prepare for reading Apex code
- Understand why we have different data types in custom fields
- Learn concepts that apply to both Apex and JavaScript

**Hands-On Exercise:**
```
Choose ONE language to learn basics (recommend JavaScript or Python):

JAVASCRIPT EXERCISES:
1. Create variables for company name, salary, status
2. Write if/else to categorize salary as "high" or "low"
3. Create array of 5 company names, loop through and print
4. Create function to calculate take-home pay (salary * 0.75)

PYTHON EXERCISES (Alternative):
1. Same exercises as above but in Python
2. Focus on understanding logic, not syntax specifics
```

**Complementary Tech Skills:**
- **JavaScript Fundamentals**: Variables, functions, objects, arrays
- **Python Basics** (Alternative): Great for scripting and automation
- **Git & Version Control**:
  - Install Git
  - Learn: clone, commit, push, pull, branch
  - Create GitHub account
- **Command Line Basics**:
  - Terminal navigation (cd, ls, mkdir, rm)
  - Running scripts

**Resources:**
- FreeCodeCamp: [JavaScript Basics](https://www.freecodecamp.org/learn/javascript-algorithms-and-data-structures/)
- Codecademy: [Learn JavaScript](https://www.codecademy.com/learn/introduction-to-javascript)
- Trailhead: [Developer Beginner](https://trailhead.salesforce.com/content/learn/trails/force_com_dev_beginner)
- Git Tutorial: [Git Basics](https://git-scm.com/book/en/v2/Getting-Started-About-Version-Control)

---

#### Week 3-4: Introduction to Apex

**What You'll Learn:**
- What is Apex? (Strongly-typed, object-oriented)
- Apex syntax vs JavaScript/Java
- Data types in Apex: Integer, String, Boolean, Date, Decimal
- Collections: List, Set, Map
- SOQL (Salesforce Object Query Language)
- DML (Data Manipulation Language): insert, update, delete, upsert
- Debug logs and Developer Console

**Project Connection:**
- Read simple service classes
- Understand basic SOQL queries
- Explore Debug Logs from automation

**Hands-On Exercise:**
```
FILES TO START READING:
- force-app/main/default/classes/ContactAssignmentService.cls (simplest)
- force-app/main/default/classes/JobApplicationTriggerHandler.cls

EXERCISES IN DEVELOPER CONSOLE:
1. Write SOQL query to get all Job Applications with Status = 'Applied'
2. Write SOQL to get Job Apps with Salary > $80,000
3. Create new Job Application using Apex:

   Job_Application__c ja = new Job_Application__c(
       Company_Name__c = 'Test Corp',
       Position_Title__c = 'Developer',
       Status__c = 'Saved'
   );
   insert ja;

4. Query that record back and update the Status
5. Use System.debug() to print values to debug log
```

**Complementary Tech Skills:**
- **SQL Basics**: Learn standard SQL to better understand SOQL
- **Object-Oriented Programming**: Classes, objects, methods, inheritance
- **IDE Setup**:
  - Install VS Code
  - Install Salesforce Extension Pack
  - Learn keyboard shortcuts

**Resources:**
- Trailhead: [Apex Basics & Database](https://trailhead.salesforce.com/content/learn/modules/apex_database)
- Trailhead: [Apex Triggers](https://trailhead.salesforce.com/content/learn/modules/apex_triggers)
- Read: First 5 chapters of [Apex Developer Guide](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/)

---

### 🎓 Phase 1 Assessment: Can You...?

**Salesforce Skills:**
- [ ] Create custom objects with 10+ fields
- [ ] Build lookup and master-detail relationships
- [ ] Create validation rules with complex logic
- [ ] Build a Record-Triggered Flow
- [ ] Configure permission sets and profiles
- [ ] Write basic SOQL queries
- [ ] Perform DML operations in Apex
- [ ] Read and understand simple Apex classes

**Tech Skills:**
- [ ] Use Git to clone, commit, and push
- [ ] Navigate command line/terminal
- [ ] Write basic JavaScript functions
- [ ] Understand if/else, loops, and arrays
- [ ] Use VS Code effectively

**Project Skills:**
- [ ] Explain what the Job Application object does
- [ ] Describe all 22 custom fields and their purposes
- [ ] Explain the 3 validation rules
- [ ] Navigate the project folder structure

---

## 🚀 PHASE 2: INTERMEDIATE (Months 4-8) - Mid Level

### 🎯 Goal
Write production-quality Apex code, build Lightning Web Components, implement integrations, and understand enterprise patterns.

---

### Month 4: Apex Programming Mastery

#### Week 1-2: Apex Triggers & Trigger Framework

**What You'll Learn:**
- Trigger context variables (Trigger.new, Trigger.old, Trigger.isInsert, etc.)
- Trigger events: before/after insert/update/delete/undelete
- Bulkification and governor limits
- Trigger handler pattern (best practice)
- Trigger order of execution
- Common trigger pitfalls (recursion, SOQL in loops)

**Project Connection:**
- Deep dive into `JobApplicationTrigger.trigger`
- Analyze `JobApplicationTriggerHandler.cls`
- Study `EventValidationTrigger.trigger` and `EventValidationHandler.cls`
- Understand why we use trigger handler pattern

**Hands-On Exercise:**
```
FILES TO MASTER:
- force-app/main/default/triggers/JobApplicationTrigger.trigger
- force-app/main/default/classes/JobApplicationTriggerHandler.cls
- force-app/main/default/triggers/EventValidationTrigger.trigger
- force-app/main/default/classes/EventValidationHandler.cls

EXERCISES:
1. Trace execution flow:
   - What happens when you create a Job Application?
   - Map out before insert → service calls → after insert

2. Add logging to JobApplicationTriggerHandler:
   - Add System.debug() at each step
   - Create a Job Application and read debug logs
   - Document the exact execution order

3. Test bulkification:
   - Use Data Import Wizard to load 200 Job Applications
   - Verify no governor limit errors
   - Check that all 200 have tasks created

4. Create your own trigger:
   - Trigger on Contact
   - When Contact email changes, log it
   - Use trigger handler pattern
   - Write with bulk operations in mind
```

**Complementary Tech Skills:**
- **Design Patterns**:
  - Handler Pattern
  - Service Layer Pattern
  - Separation of Concerns
- **Performance Optimization**:
  - Big O Notation basics
  - Understanding algorithmic complexity
- **Code Organization**:
  - Single Responsibility Principle
  - DRY (Don't Repeat Yourself)

**Resources:**
- Trailhead: [Apex Triggers](https://trailhead.salesforce.com/content/learn/modules/apex_triggers)
- Read: [Trigger Framework Best Practices](https://developer.salesforce.com/wiki/apex_trigger_best_practices)
- Study: Salesforce Trigger Framework (SFDC99, Dan Appleman)

---

#### Week 3-4: Service Layer Architecture & SOQL Mastery

**What You'll Learn:**
- Service layer pattern (reusable business logic)
- SOQL advanced features:
  - Relationship queries (parent-to-child, child-to-parent)
  - Aggregate functions (COUNT, SUM, AVG, MIN, MAX)
  - GROUP BY and HAVING
  - LIMIT, OFFSET, ORDER BY
  - Date literals (LAST_N_DAYS, THIS_MONTH, etc.)
- SOSL (Salesforce Object Search Language)
- Dynamic SOQL and SOSL
- Query optimization and selective queries

**Project Connection:**
- Study all service classes:
  - `SalaryCalculationService.cls`
  - `TaskCreationService.cls`
  - `ContactAssignmentService.cls`
  - `ApplicationAnalyticsService.cls`
- Analyze SOQL queries for efficiency
- Understand @AuraEnabled methods

**Hands-On Exercise:**
```
FILES TO MASTER:
- force-app/main/default/classes/SalaryCalculationService.cls
- force-app/main/default/classes/TaskCreationService.cls
- force-app/main/default/classes/ContactAssignmentService.cls
- force-app/main/default/classes/ApplicationAnalyticsService.cls

SOQL EXERCISES:
1. Write query to get all Job Applications with related Tasks:
   SELECT Id, Company_Name__c,
          (SELECT Subject, Status FROM Tasks)
   FROM Job_Application__c

2. Get count of Job Applications by Status:
   SELECT Status__c, COUNT(Id) count
   FROM Job_Application__c
   GROUP BY Status__c

3. Get applications from last 30 days with high salary:
   SELECT Id, Company_Name__c, Salary__c
   FROM Job_Application__c
   WHERE Application_Date__c = LAST_N_DAYS:30
   AND Salary__c > 80000

4. Find the average salary by status:
   SELECT Status__c, AVG(Salary__c) avgSalary
   FROM Job_Application__c
   GROUP BY Status__c

SERVICE LAYER EXERCISES:
1. Create SalaryAnalysisService.cls with methods:
   - getAverageSalaryByStatus()
   - getHighestPaidApplication()
   - getSalaryTrends()

2. Refactor to be @AuraEnabled(cacheable=true) for LWC use

3. Add error handling with try/catch

4. Document with proper Apex comments
```

**Complementary Tech Skills:**
- **SQL Mastery**: Practice on SQLZoo, LeetCode SQL
- **RESTful API Concepts**: Understand HTTP methods, JSON
- **Caching Strategies**: When to cache, cache invalidation

**Resources:**
- Trailhead: [SOQL for Admins](https://trailhead.salesforce.com/content/learn/modules/soql-for-admins)
- Read: [SOQL and SOSL Reference](https://developer.salesforce.com/docs/atlas.en-us.soql_sosl.meta/soql_sosl/)
- Practice: [SOQL Workshop](https://trailhead.salesforce.com/content/learn/projects/workshop-soql)

---

### Month 5: Asynchronous Apex & Advanced Patterns

#### Week 1-2: Asynchronous Processing

**What You'll Learn:**
- Why asynchronous? (Long-running operations, callouts, governor limits)
- **Future Methods** (@future)
- **Queueable Apex** (Database.Queueable)
- **Batch Apex** (Database.Batchable)
- **Scheduled Apex** (Schedulable)
- When to use which async pattern
- Chaining jobs
- Monitoring async jobs

**Project Connection:**
- Master `SalaryMarketAnalysisBatch.cls` (Batch Apex)
- Study `SalaryMarketAnalysisScheduler.cls` (Scheduled Apex)
- Analyze `EmailNotificationQueue.cls` (Queueable)
- Understand `AllowsCallouts` interface

**Hands-On Exercise:**
```
FILES TO MASTER:
- force-app/main/default/classes/SalaryMarketAnalysisBatch.cls
- force-app/main/default/classes/SalaryMarketAnalysisScheduler.cls
- force-app/main/default/classes/EmailNotificationQueue.cls

BATCH APEX EXERCISE:
1. Trace SalaryMarketAnalysisBatch execution:
   - What does start() method do?
   - How many records in each batch chunk?
   - What happens in execute()?
   - What does finish() do?

2. Run the batch job:
   SalaryMarketAnalysisBatch batch = new SalaryMarketAnalysisBatch();
   Database.executeBatch(batch, 200);

3. Monitor in Setup → Apex Jobs
4. Check debug logs for execution details

QUEUEABLE EXERCISE:
1. Study EmailNotificationQueue.cls
2. Understand chaining logic
3. Modify to add custom email logic
4. Test with:
   System.enqueueJob(new EmailNotificationQueue(applicationIds));

SCHEDULER EXERCISE:
1. Schedule the batch job to run weekly:
   String cronExp = '0 0 6 ? * MON'; // 6 AM every Monday
   System.schedule('Weekly Salary Analysis', cronExp, new SalaryMarketAnalysisScheduler());

2. Check Setup → Scheduled Jobs
3. Test by scheduling for 5 minutes from now

CREATE YOUR OWN:
1. Build TaskCleanupBatch.cls:
   - Find all completed tasks older than 90 days
   - Delete them in batches
   - Send summary email when done

2. Schedule it to run monthly
```

**Complementary Tech Skills:**
- **Asynchronous Programming**: Promises, callbacks, async/await (JavaScript)
- **Job Queues**: Understanding message queues (RabbitMQ, AWS SQS concepts)
- **Cron Expressions**: Learn cron syntax
- **Batch Processing Patterns**: ETL concepts

**Resources:**
- Trailhead: [Asynchronous Apex](https://trailhead.salesforce.com/content/learn/modules/asynchronous_apex)
- Read: Batch Apex Best Practices
- Tool: [Cron Expression Generator](https://www.freeformatter.com/cron-expression-generator-quartz.html)

---

#### Week 3-4: Integration & Callouts

**What You'll Learn:**
- HTTP protocol basics (GET, POST, PUT, DELETE)
- RESTful API design principles
- Apex HTTP callouts (HttpRequest, HttpResponse)
- JSON serialization/deserialization
- Named Credentials
- Remote Site Settings
- Callout retry logic and error handling
- Mock callouts for testing

**Project Connection:**
- Deep dive into `SalaryDataAPIService.cls`
- Understand retry logic (3 attempts)
- Learn timeout management (30 seconds)
- Study error handling patterns

**Hands-On Exercise:**
```
FILE TO MASTER:
- force-app/main/default/classes/SalaryDataAPIService.cls

CALLOUT EXERCISES:
1. Analyze the getSalaryData() method:
   - How is HttpRequest constructed?
   - What happens if callout fails?
   - How does retry logic work?
   - How is JSON response parsed?

2. Create your own integration:
   API: https://api.github.com/users/{username}

   public class GitHubService {
       public static String getUserInfo(String username) {
           HttpRequest req = new HttpRequest();
           req.setEndpoint('https://api.github.com/users/' + username);
           req.setMethod('GET');
           req.setTimeout(30000);

           Http http = new Http();
           HttpResponse res = http.send(req);

           if (res.getStatusCode() == 200) {
               return res.getBody();
           } else {
               throw new CalloutException('GitHub API failed: ' + res.getStatus());
           }
       }
   }

3. Add to Remote Site Settings:
   Setup → Remote Site Settings → New
   URL: https://api.github.com

4. Test the callout:
   String result = GitHubService.getUserInfo('salesforce');
   System.debug(result);

5. Parse JSON response:
   Map<String, Object> userData = (Map<String, Object>) JSON.deserializeUntyped(result);
   String name = (String) userData.get('name');
   System.debug('Name: ' + name);

ADVANCED EXERCISE:
1. Add retry logic like SalaryDataAPIService
2. Create wrapper class for GitHub user data
3. Write test class with mock callouts
4. Add caching to avoid repeated calls
```

**Complementary Tech Skills:**
- **REST API Design**: RESTful principles, API best practices
- **JSON**: Deep understanding of JSON structure
- **HTTP/HTTPS**: Headers, status codes, authentication
- **API Testing Tools**: Postman, cURL
- **OAuth 2.0**: Understanding modern authentication

**Resources:**
- Trailhead: [Apex Integration Services](https://trailhead.salesforce.com/content/learn/modules/apex_integration_services)
- Read: [REST API Developer Guide](https://developer.salesforce.com/docs/atlas.en-us.api_rest.meta/api_rest/)
- Practice: [Public APIs for Testing](https://github.com/public-apis/public-apis)
- Tool: [Postman](https://www.postman.com/)

---

### Month 6: Lightning Web Components (LWC) Fundamentals

#### Week 1-2: JavaScript for LWC & Web Component Basics

**What You'll Learn:**
- Modern JavaScript (ES6+):
  - Arrow functions, destructuring, spread operator
  - Template literals, classes
  - Promises, async/await
  - Array methods (map, filter, reduce)
- Web Components standard
- Shadow DOM
- Component lifecycle
- HTML & CSS fundamentals

**Project Connection:**
- Prepare to understand LWC JavaScript code
- Review `salaryCalculator` component structure

**Hands-On Exercise:**
```
JAVASCRIPT ES6+ EXERCISES:
1. Practice arrow functions:
   const calculateTax = (salary) => salary * 0.25;

2. Array methods:
   const salaries = [50000, 75000, 100000, 120000];
   const highSalaries = salaries.filter(s => s > 80000);
   const total = salaries.reduce((sum, s) => sum + s, 0);

3. Destructuring:
   const jobApp = { company: 'Salesforce', salary: 100000 };
   const { company, salary } = jobApp;

4. Promises & async/await:
   async function fetchSalaryData() {
       const response = await fetch('https://api.example.com/salary');
       const data = await response.json();
       return data;
   }

HTML/CSS REFRESHER:
1. Build simple form with:
   - Text inputs
   - Dropdowns (select)
   - Buttons
   - Styling with CSS

2. Practice CSS Grid and Flexbox
3. Understand responsive design (media queries)
```

**Complementary Tech Skills:**
- **Modern JavaScript**: Complete ES6+ course
- **HTML5 & CSS3**: Semantic HTML, CSS Grid, Flexbox
- **Responsive Design**: Mobile-first approach
- **Browser DevTools**: Chrome/Firefox debugging tools
- **npm & Node.js**: Package management basics

**Resources:**
- JavaScript.info: [The Modern JavaScript Tutorial](https://javascript.info/)
- FreeCodeCamp: [Responsive Web Design](https://www.freecodecamp.org/learn/2022/responsive-web-design/)
- MDN: [Web Components](https://developer.mozilla.org/en-US/docs/Web/Web_Components)

---

#### Week 3-4: LWC Development

**What You'll Learn:**
- LWC component structure (HTML, JS, XML)
- Component decorators: @api, @track, @wire
- Lightning Data Service (LDS)
- Wire adapters (getRecord, getObjectInfo, etc.)
- Imperative Apex calls
- Component communication (events, pubsub)
- Lightning Design System (SLDS)
- Error handling with ShowToastEvent

**Project Connection:**
- Master `salaryCalculator` LWC
- Study all 7 LWC components in project
- Understand dashboard components

**Hands-On Exercise:**
```
FILES TO MASTER:
- force-app/main/default/lwc/salaryCalculator/
  - salaryCalculator.html
  - salaryCalculator.js
  - salaryCalculator.js-meta.xml

SALARY CALCULATOR DEEP DIVE:
1. Study the HTML template:
   - Lightning input components
   - Conditional rendering (if:true, if:false)
   - Event handlers (onchange, onclick)

2. Analyze the JavaScript:
   - @track decorator for reactive properties
   - @wire for Apex methods
   - Getters and setters
   - Event handling methods
   - Imperative Apex call pattern

3. Deploy and test:
   sfdx force:source:deploy -p force-app/main/default/lwc/salaryCalculator

4. Add to Job Application page:
   - Lightning App Builder
   - Edit Job Application record page
   - Drag salaryCalculator component
   - Test functionality

CREATE YOUR OWN LWC:
1. Build "applicationStatusTracker" component:
   - Shows current status
   - Displays progress bar
   - Lists next steps (tasks)
   - Uses @wire to get Job Application data

2. Component structure:
   applicationStatusTracker/
   ├── applicationStatusTracker.html
   ├── applicationStatusTracker.js
   └── applicationStatusTracker.js-meta.xml

3. Features to implement:
   - @api recordId property
   - @wire getRecord to fetch data
   - Display status with colored badges
   - Show related tasks
   - Add Lightning Design System styling
```

**Complementary Tech Skills:**
- **Component-Based Architecture**: React, Vue concepts
- **State Management**: Understanding reactive data
- **Event-Driven Programming**: Custom events, bubbling
- **CSS Frameworks**: Bootstrap concepts (SLDS is similar)

**Resources:**
- Trailhead: [Lightning Web Components Basics](https://trailhead.salesforce.com/content/learn/modules/lightning-web-components-basics)
- Read: [LWC Developer Guide](https://developer.salesforce.com/docs/component-library/documentation/en/lwc)
- Component Library: [Lightning Web Components Reference](https://developer.salesforce.com/docs/component-library/overview/components)
- Read: `docs/FEATURE_IMPLEMENTATION_GUIDE.md` (LWC section)

---

### Month 7: Testing & Quality Assurance

#### Week 1-2: Apex Unit Testing

**What You'll Learn:**
- Testing fundamentals (arrange, act, assert)
- Test class structure and annotations (@isTest, @testSetup)
- Test data creation (Test.loadData, TestDataFactory)
- System.assert methods
- Test.startTest() and Test.stopTest()
- Testing async Apex (Test.startTest enables 200 records in batch)
- Mock callouts (Test.setMock)
- Code coverage requirements (75% for production)
- Testing best practices

**Project Connection:**
- Study all 4 test classes:
  - `JobApplicationTriggerTest.cls`
  - `EventValidationHandlerTest.cls`
  - `SalaryMarketAnalysisBatchTest.cls`
  - `ApplicationAnalyticsServiceTest.cls`
- Understand how we achieve 95%+ coverage

**Hands-On Exercise:**
```
FILES TO MASTER:
- force-app/main/default/classes/JobApplicationTriggerTest.cls
- force-app/main/default/classes/EventValidationHandlerTest.cls
- force-app/main/default/classes/SalaryMarketAnalysisBatchTest.cls
- force-app/main/default/classes/ApplicationAnalyticsServiceTest.cls

ANALYZE EXISTING TESTS:
1. JobApplicationTriggerTest.cls:
   - How is test data created?
   - What scenarios are tested?
   - How are assertions structured?
   - How is bulk testing done (200 records)?

2. Run all tests:
   sfdx force:apex:test:run --testlevel RunLocalTests --resultformat human --codecoverage

3. Review code coverage:
   - Which classes have < 75% coverage?
   - Identify untested scenarios

WRITE YOUR OWN TESTS:
1. Create TestDataFactory.cls:
   @isTest
   public class TestDataFactory {
       public static Job_Application__c createJobApplication(String status) {
           return new Job_Application__c(
               Company_Name__c = 'Test Corp',
               Position_Title__c = 'Developer',
               Status__c = status,
               Salary__c = 80000,
               Application_Date__c = Date.today()
           );
       }

       public static List<Job_Application__c> createJobApplications(Integer count) {
           List<Job_Application__c> apps = new List<Job_Application__c>();
           for (Integer i = 0; i < count; i++) {
               apps.add(createJobApplication('Saved'));
           }
           return apps;
       }
   }

2. Test ContactAssignmentService.cls:
   @isTest
   private class ContactAssignmentServiceTest {
       @testSetup
       static void setupData() {
           // Create Account
           // Create Contacts
           // Create Job Applications
       }

       @isTest
       static void testAssignPrimaryContact() {
           // Test contact assignment logic
       }

       @isTest
       static void testBulkAssignment() {
           // Test with 200 records
       }
   }

3. Run and verify coverage:
   sfdx force:apex:test:run --classnames ContactAssignmentServiceTest --resultformat human --codecoverage
```

**Complementary Tech Skills:**
- **Test-Driven Development (TDD)**: Red-Green-Refactor cycle
- **Unit Testing Principles**: AAA pattern, test isolation
- **Mocking & Stubbing**: When and how to mock
- **Code Coverage vs Test Quality**: Understanding the difference

**Resources:**
- Trailhead: [Apex Testing](https://trailhead.salesforce.com/content/learn/modules/apex_testing)
- Read: `docs/TESTING_MASTERY_GUIDE.md`
- Read: [Apex Testing Best Practices](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_testing_best_practices.htm)

---

#### Week 3-4: LWC Testing & End-to-End Testing

**What You'll Learn:**
- Jest for LWC testing
- Test file structure (\_\_tests\_\_)
- Mocking Apex calls
- Testing user interactions
- Lightning Testing Service (legacy, good to know)
- Manual testing strategies
- User acceptance testing (UAT)

**Project Connection:**
- Study `salaryCalculator` Jest tests
- Create test coverage for other LWC components

**Hands-On Exercise:**
```
FILE TO STUDY:
- force-app/main/default/lwc/salaryCalculator/__tests__/salaryCalculator.test.js

SETUP JEST:
1. Install Node.js and npm
2. Install Jest for LWC:
   npm install --save-dev @salesforce/sfdx-lwc-jest

3. Add test script to package.json:
   "scripts": {
       "test:unit": "sfdx-lwc-jest",
       "test:unit:watch": "sfdx-lwc-jest --watch",
       "test:unit:coverage": "sfdx-lwc-jest --coverage"
   }

WRITE LWC TESTS:
1. Create test for salaryCalculator:
   import { createElement } from 'lwc';
   import SalaryCalculator from 'c/salaryCalculator';

   describe('c-salary-calculator', () => {
       afterEach(() => {
           while (document.body.firstChild) {
               document.body.removeChild(document.body.firstChild);
           }
       });

       it('calculates take-home pay correctly', () => {
           const element = createElement('c-salary-calculator', {
               is: SalaryCalculator
           });
           document.body.appendChild(element);

           const input = element.shadowRoot.querySelector('lightning-input[data-id="salary"]');
           input.value = 100000;
           input.dispatchEvent(new CustomEvent('change'));

           return Promise.resolve().then(() => {
               const takeHome = element.shadowRoot.querySelector('.take-home-pay');
               expect(takeHome.textContent).toBeTruthy();
           });
       });
   });

2. Run tests:
   npm run test:unit

3. Check coverage:
   npm run test:unit:coverage

MANUAL TESTING CHECKLIST:
1. Create test plan for Job Application creation:
   - [ ] Create with all required fields
   - [ ] Create with optional fields blank
   - [ ] Test validation rules fire correctly
   - [ ] Verify tasks are created
   - [ ] Check contact assignment
   - [ ] Confirm salary calculations
   - [ ] Test status transitions

2. Document test cases in docs/TEST_PLAN.md
```

**Complementary Tech Skills:**
- **Jest Framework**: JavaScript testing with Jest
- **DOM Testing**: Query selectors, event simulation
- **Test Automation**: Selenium basics (for future use)
- **QA Principles**: Test planning, bug reporting

**Resources:**
- Trailhead: [Test Lightning Web Components](https://trailhead.salesforce.com/content/learn/modules/test-lightning-web-components)
- Read: [Jest LWC Documentation](https://github.com/salesforce/sfdx-lwc-jest)
- Read: `docs/TESTING_MASTERY_GUIDE.md`

---

### Month 8: DevOps & Deployment

#### Week 1-2: Salesforce DX & Version Control

**What You'll Learn:**
- Salesforce DX project structure
- Source format vs metadata format
- sfdx CLI commands
- Scratch orgs vs sandboxes vs production
- Source tracking (push/pull/status)
- Git workflows: feature branches, pull requests
- .gitignore best practices for Salesforce

**Project Connection:**
- Understand this project's structure
- Practice deploying to scratch org
- Use source control effectively

**Hands-On Exercise:**
```
SALESFORCE DX COMMANDS:
1. Authenticate to Dev Hub:
   sfdx auth:web:login --setdefaultdevhubusername --setalias DevHub

2. Create scratch org:
   sfdx force:org:create --setdefaultusername --definitionfile config/project-scratch-def.json --setalias JobTrackerScratch --durationdays 30

3. Push source to scratch org:
   sfdx force:source:push

4. Assign permission set:
   sfdx force:user:permset:assign --permsetname Job_Application_Manager

5. Import test data:
   sfdx force:data:tree:import --plan data/sample-data-plan.json

6. Open org:
   sfdx force:org:open

GIT WORKFLOW PRACTICE:
1. Create feature branch:
   git checkout -b feature/add-interview-rating

2. Make changes to code

3. Stage and commit:
   git add .
   git commit -m "feat: add interview rating field and validation"

4. Push to remote:
   git push origin feature/add-interview-rating

5. Create pull request on GitHub

6. Merge after review

7. Delete feature branch:
   git branch -d feature/add-interview-rating

PROJECT SETUP FROM SCRATCH:
1. Clone project:
   git clone https://github.com/your-repo/job-application-tracker.git

2. Create scratch org:
   sfdx force:org:create -f config/project-scratch-def.json -a MyScratchOrg

3. Deploy all metadata:
   sfdx force:source:push

4. Run all tests:
   sfdx force:apex:test:run --testlevel RunLocalTests --resultformat human

5. View org:
   sfdx force:org:open
```

**Complementary Tech Skills:**
- **Git Mastery**: Branching strategies (GitFlow, trunk-based)
- **GitHub/GitLab**: Pull requests, code reviews, issues
- **Command Line**: Advanced shell scripting
- **CI/CD Concepts**: Continuous Integration/Deployment basics

**Resources:**
- Trailhead: [Salesforce DX](https://trailhead.salesforce.com/content/learn/modules/sfdx_app_dev)
- Read: [Salesforce DX Developer Guide](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/)
- Read: `SETUP_GUIDE.md` and `QUICK_START.md` in this project
- Practice: [Git Branching Game](https://learngitbranching.js.org/)

---

#### Week 3-4: CI/CD & Deployment Automation

**What You'll Learn:**
- Continuous Integration principles
- GitHub Actions / GitLab CI
- Automated testing in CI pipeline
- Change sets (legacy deployment)
- Unlocked packages
- Deployment best practices
- Rollback strategies
- Release management

**Project Connection:**
- Set up CI/CD for this project
- Automate test runs
- Deploy to sandbox automatically

**Hands-On Exercise:**
```
SETUP GITHUB ACTIONS:
1. Create .github/workflows/ci.yml:
   name: Salesforce CI

   on:
     push:
       branches: [ main, develop ]
     pull_request:
       branches: [ main ]

   jobs:
     build:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v2

         - name: Install Salesforce CLI
           run: |
             npm install -g sfdx-cli

         - name: Authenticate to DevHub
           run: |
             echo ${{ secrets.SFDX_AUTH_URL }} > authfile
             sfdx auth:sfdxurl:store -f authfile -d

         - name: Create Scratch Org
           run: |
             sfdx force:org:create -f config/project-scratch-def.json -a ciorg -s

         - name: Push Source
           run: |
             sfdx force:source:push -u ciorg

         - name: Run Apex Tests
           run: |
             sfdx force:apex:test:run -u ciorg --testlevel RunLocalTests --codecoverage --resultformat human

         - name: Delete Scratch Org
           run: |
             sfdx force:org:delete -u ciorg -p

2. Setup secrets in GitHub:
   - SFDX_AUTH_URL (get with: sfdx force:org:display --verbose -u DevHub)

3. Push to trigger workflow

DEPLOYMENT TO SANDBOX:
1. Authenticate to sandbox:
   sfdx auth:web:login --setalias SandboxOrg --instanceurl https://test.salesforce.com

2. Deploy using metadata API:
   sfdx force:source:deploy --targetusername SandboxOrg --sourcepath force-app

3. Run tests in sandbox:
   sfdx force:apex:test:run -u SandboxOrg --testlevel RunLocalTests

4. Validate before production:
   sfdx force:source:deploy --targetusername Production --sourcepath force-app --checkonly --testlevel RunLocalTests

CREATE DEPLOYMENT CHECKLIST:
1. Document in docs/DEPLOYMENT_CHECKLIST.md:
   - [ ] All tests passing locally
   - [ ] Code reviewed and approved
   - [ ] Deployed to sandbox
   - [ ] UAT completed
   - [ ] Deployment validated in production (--checkonly)
   - [ ] Communication sent to users
   - [ ] Deployment window scheduled
   - [ ] Rollback plan documented
   - [ ] Deploy to production
   - [ ] Smoke tests performed
   - [ ] Users notified
```

**Complementary Tech Skills:**
- **YAML**: CI/CD configuration files
- **Docker**: Containerization basics (future skill)
- **Jenkins**: Alternative CI/CD tool
- **Infrastructure as Code**: Basic concepts

**Resources:**
- Trailhead: [Continuous Integration with Salesforce DX](https://trailhead.salesforce.com/content/learn/modules/sfdx_travis_ci)
- Read: [GitHub Actions Documentation](https://docs.github.com/en/actions)
- Read: `docs/DEPLOYMENT_SUCCESS_SUMMARY.md`

---

### 🎓 Phase 2 Assessment: Can You...?

**Salesforce Skills:**
- [ ] Write production-quality Apex triggers with handler pattern
- [ ] Create service classes following best practices
- [ ] Implement all asynchronous patterns (batch, queueable, scheduled, future)
- [ ] Build RESTful API integrations with retry logic
- [ ] Develop Lightning Web Components with @wire and Apex calls
- [ ] Write comprehensive test classes achieving 95%+ coverage
- [ ] Deploy using Salesforce DX and scratch orgs
- [ ] Set up CI/CD pipeline with automated testing

**Tech Skills:**
- [ ] Write modern JavaScript (ES6+)
- [ ] Use Git workflows (branching, PR, merge)
- [ ] Configure GitHub Actions or similar CI/CD
- [ ] Write Jest tests for LWC
- [ ] Use VS Code productively with extensions
- [ ] Debug using browser DevTools and Apex logs

**Project Skills:**
- [ ] Explain every service class in detail
- [ ] Trace trigger execution from start to finish
- [ ] Modify and enhance LWC components
- [ ] Run batch jobs and monitor execution
- [ ] Deploy entire project to new org
- [ ] Troubleshoot and fix bugs independently

---

## 🏆 PHASE 3: ADVANCED (Months 9-14) - Senior Level

### 🎯 Goal
Design scalable solutions, optimize performance, lead technical decisions, mentor others, and handle complex enterprise requirements.

---

### Month 9: Advanced Apex & Design Patterns

#### Week 1-2: Enterprise Design Patterns

**What You'll Learn:**
- **Trigger Framework Patterns**: Recursion prevention, state management
- **Service Layer Pattern**: Separation of concerns
- **Selector Pattern**: SOQL queries centralized
- **Domain Layer Pattern**: Business logic encapsulation
- **Unit of Work Pattern**: Transaction management
- **Factory Pattern**: Object creation
- **Strategy Pattern**: Algorithm selection
- **Observer Pattern**: Event-driven architecture

**Project Connection:**
- Refactor project to use enterprise patterns
- Implement Selector classes
- Create Domain classes

**Hands-On Exercise:**
```
IMPLEMENT SELECTOR PATTERN:
1. Create JobApplicationsSelector.cls:
   public with sharing class JobApplicationsSelector {
       public List<Job_Application__c> selectById(Set<Id> ids) {
           return [
               SELECT Id, Company_Name__c, Position_Title__c, Status__c, Salary__c,
                      Primary_Contact__c, (SELECT Id, Subject, Status FROM Tasks)
               FROM Job_Application__c
               WHERE Id IN :ids
           ];
       }

       public List<Job_Application__c> selectByStatus(String status) {
           return [
               SELECT Id, Company_Name__c, Position_Title__c, Salary__c
               FROM Job_Application__c
               WHERE Status__c = :status
           ];
       }

       public List<Job_Application__c> selectRecentApplications(Integer days) {
           return [
               SELECT Id, Company_Name__c, Application_Date__c
               FROM Job_Application__c
               WHERE Application_Date__c >= LAST_N_DAYS: :days
               ORDER BY Application_Date__c DESC
           ];
       }
   }

IMPLEMENT DOMAIN PATTERN:
1. Create JobApplicationsDomain.cls:
   public with sharing class JobApplicationsDomain {
       private List<Job_Application__c> records;

       public JobApplicationsDomain(List<Job_Application__c> records) {
           this.records = records;
       }

       public void calculateTaxes() {
           for (Job_Application__c app : records) {
               if (app.Salary__c != null) {
                   SalaryCalculationService.calculateTakeHomePay(new List<Job_Application__c>{ app });
               }
           }
       }

       public void assignPrimaryContacts() {
           ContactAssignmentService.assignPrimaryContact(records);
       }

       public void enforceBusinessRules() {
           for (Job_Application__c app : records) {
               // Enforce business rules
               if (app.Status__c == 'Accepted' && app.Salary__c == null) {
                   app.addError('Salary required for accepted applications');
               }
           }
       }
   }

IMPLEMENT UNIT OF WORK PATTERN:
1. Install fflib-apex-common (Salesforce Foundation Library):
   https://github.com/apex-enterprise-patterns/fflib-apex-common

2. Use Unit of Work in service class:
   public static void processApplicationBatch(List<Job_Application__c> apps) {
       fflib_ISObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
           new Schema.SObjectType[] {
               Job_Application__c.SObjectType,
               Task.SObjectType,
               Contact.SObjectType
           }
       );

       // Register work
       for (Job_Application__c app : apps) {
           uow.registerDirty(app);

           Task t = new Task(Subject = 'Follow up', WhatId = app.Id);
           uow.registerNew(t);
       }

       // Commit all in one transaction
       uow.commitWork();
   }

REFACTOR TRIGGER HANDLER:
1. Prevent recursion:
   public class TriggerStateManager {
       private static Set<String> executedTriggers = new Set<String>();

       public static Boolean isFirstRun(String triggerName) {
           if (executedTriggers.contains(triggerName)) {
               return false;
           }
           executedTriggers.add(triggerName);
           return true;
       }

       public static void reset() {
           executedTriggers.clear();
       }
   }

2. Use in trigger handler:
   if (TriggerStateManager.isFirstRun('JobApplicationTrigger_BeforeUpdate')) {
       // Execute logic only once
   }
```

**Complementary Tech Skills:**
- **Software Architecture**: Clean Architecture, Hexagonal Architecture
- **SOLID Principles**: Deep dive into each principle
- **Refactoring**: Martin Fowler's refactoring catalog
- **Domain-Driven Design**: Bounded contexts, aggregates

**Resources:**
- Book: [Enterprise Architecture for Salesforce](https://github.com/apex-enterprise-patterns)
- Read: fflib-apex-common documentation
- Read: Clean Code by Robert Martin
- Read: Design Patterns by Gang of Four

---

#### Week 3-4: Performance Optimization & Governor Limits

**What You'll Learn:**
- Governor limits deep dive (all 20+ limits)
- Query optimization:
  - Selective queries and indexes
  - Query plan tool
  - Avoiding full table scans
- Bulkification techniques
- Platform caching (Platform Cache API)
- Lazy loading and pagination
- CPU time optimization
- Heap size management
- SOQL injection prevention

**Project Connection:**
- Analyze `PerformanceOptimizationService.cls`
- Optimize existing queries
- Add platform caching

**Hands-On Exercise:**
```
GOVERNOR LIMITS ANALYSIS:
1. Study all limits:
   System.debug('SOQL Queries: ' + Limits.getQueries() + ' / ' + Limits.getLimitQueries());
   System.debug('DML Statements: ' + Limits.getDmlStatements() + ' / ' + Limits.getLimitDmlStatements());
   System.debug('CPU Time: ' + Limits.getCpuTime() + ' / ' + Limits.getLimitCpuTime());
   System.debug('Heap Size: ' + Limits.getHeapSize() + ' / ' + Limits.getLimitHeapSize());

2. Create LimitsTracker utility:
   public class LimitsTracker {
       public static void logLimits(String context) {
           System.debug('=== LIMITS: ' + context + ' ===');
           System.debug('SOQL: ' + Limits.getQueries() + ' / ' + Limits.getLimitQueries());
           System.debug('DML: ' + Limits.getDmlStatements() + ' / ' + Limits.getLimitDmlStatements());
           System.debug('CPU: ' + Limits.getCpuTime() + 'ms / ' + Limits.getLimitCpuTime() + 'ms');
           System.debug('Heap: ' + Limits.getHeapSize() + 'b / ' + Limits.getLimitHeapSize() + 'b');
       }
   }

QUERY OPTIMIZATION:
1. Use Query Plan tool:
   - Developer Console → Query Editor
   - Query Plan tab
   - Analyze indexes and table scans

2. Make query selective (uses index):
   // Bad: Full table scan
   SELECT Id FROM Job_Application__c WHERE Company_Name__c LIKE '%Corp%'

   // Better: Indexed field
   SELECT Id FROM Job_Application__c WHERE Status__c = 'Applied'

   // Best: Multiple indexed fields
   SELECT Id FROM Job_Application__c
   WHERE Status__c = 'Applied'
   AND Application_Date__c >= :Date.today().addDays(-30)

3. Create custom indexes:
   - Contact Salesforce to enable custom indexes on fields
   - Or use Setup → Optimize custom metadata for search

PLATFORM CACHING:
1. Enable Platform Cache:
   - Setup → Platform Cache
   - Create cache partition (10 MB trial capacity)

2. Implement caching in service:
   public class CachedSalaryService {
       private static final String CACHE_PARTITION = 'local.JobAppTracker';

       public static Decimal getSalaryData(String jobTitle) {
           // Check cache first
           Cache.Partition partition = Cache.Partition.get(CACHE_PARTITION);
           Decimal cached = (Decimal) partition.get(jobTitle);

           if (cached != null) {
               return cached;
           }

           // Fetch from API
           Decimal salaryData = SalaryDataAPIService.getSalaryData(jobTitle, 'USA');

           // Cache for 1 hour
           partition.put(jobTitle, salaryData, 3600);

           return salaryData;
       }
   }

BULKIFICATION REVIEW:
1. Find anti-patterns in code:
   // BAD: SOQL in loop
   for (Job_Application__c app : Trigger.new) {
       List<Task> tasks = [SELECT Id FROM Task WHERE WhatId = :app.Id];
   }

   // GOOD: SOQL outside loop
   Map<Id, List<Task>> tasksByApp = new Map<Id, List<Task>>();
   for (Task t : [SELECT Id, WhatId FROM Task WHERE WhatId IN :Trigger.newMap.keySet()]) {
       if (!tasksByApp.containsKey(t.WhatId)) {
           tasksByApp.put(t.WhatId, new List<Task>());
       }
       tasksByApp.get(t.WhatId).add(t);
   }

CPU TIME OPTIMIZATION:
1. Profile code execution:
   Long startTime = System.currentTimeMillis();
   // ... code to profile ...
   Long endTime = System.currentTimeMillis();
   System.debug('Execution time: ' + (endTime - startTime) + 'ms');

2. Optimize loops:
   // Use Set for lookups instead of List contains()
   Set<Id> accountIds = new Set<Id>(accountList);
   if (accountIds.contains(someId)) { } // O(1) instead of O(n)
```

**Complementary Tech Skills:**
- **Database Performance**: Indexing strategies, query optimization
- **Caching Strategies**: Redis, Memcached concepts
- **Profiling Tools**: Understanding performance profiling
- **Algorithm Complexity**: Big O notation mastery

**Resources:**
- Trailhead: [Performance Optimization](https://trailhead.salesforce.com/content/learn/modules/performance-optimization)
- Read: [Apex Governor Limits](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_gov_limits.htm)
- Read: [Query & Search Optimization Cheat Sheet](https://developer.salesforce.com/docs/atlas.en-us.salesforce_large_data_volumes_bp.meta/salesforce_large_data_volumes_bp/)

---

### Month 10: Advanced Lightning Web Components

#### Week 1-2: Advanced LWC Patterns

**What You'll Learn:**
- Component composition and reusability
- Parent-child communication (advanced)
- Custom events and event bubbling
- Lightning Message Service (LMS) for pub/sub
- Dynamic component creation
- Internationalization (i18n)
- Accessibility (ARIA, keyboard navigation)
- Performance optimization (lazy loading, caching)

**Project Connection:**
- Enhance dashboard components
- Create reusable component library
- Implement LMS between components

**Hands-On Exercise:**
```
LIGHTNING MESSAGE SERVICE:
1. Create message channel (jobApplicationUpdated.messageChannel-meta.xml):
   <?xml version="1.0" encoding="UTF-8"?>
   <LightningMessageChannel xmlns="http://soap.sforce.com/2006/04/metadata">
       <masterLabel>Job Application Updated</masterLabel>
       <isExposed>true</isExposed>
       <description>Message channel for job application updates</description>
       <lightningMessageFields>
           <fieldName>applicationId</fieldName>
           <description>The ID of the updated application</description>
       </lightningMessageFields>
       <lightningMessageFields>
           <fieldName>status</fieldName>
           <description>New status of the application</description>
       </lightningMessageFields>
   </LightningMessageChannel>

2. Publisher component (statusUpdater.js):
   import { LightningElement, wire } from 'lwc';
   import { publish, MessageContext } from 'lightning/messageService';
   import JOB_APP_UPDATED from '@salesforce/messageChannel/jobApplicationUpdated__c';

   export default class StatusUpdater extends LightningElement {
       @wire(MessageContext)
       messageContext;

       handleStatusChange(event) {
           const payload = {
               applicationId: this.recordId,
               status: event.detail.value
           };
           publish(this.messageContext, JOB_APP_UPDATED, payload);
       }
   }

3. Subscriber component (statusListener.js):
   import { LightningElement, wire } from 'lwc';
   import { subscribe, MessageContext } from 'lightning/messageService';
   import JOB_APP_UPDATED from '@salesforce/messageChannel/jobApplicationUpdated__c';

   export default class StatusListener extends LightningElement {
       @wire(MessageContext)
       messageContext;

       subscription = null;

       connectedCallback() {
           this.subscribeToMessageChannel();
       }

       subscribeToMessageChannel() {
           this.subscription = subscribe(
               this.messageContext,
               JOB_APP_UPDATED,
               (message) => this.handleMessage(message)
           );
       }

       handleMessage(message) {
           console.log('Application updated:', message.applicationId, message.status);
           // Refresh data, show notification, etc.
       }
   }

DYNAMIC COMPONENT CREATION:
1. Create component factory:
   import { createElement } from 'lwc';
   import SalaryCalculator from 'c/salaryCalculator';

   export default class DynamicComponents extends LightningElement {
       handleAddCalculator() {
           const calculator = createElement('c-salary-calculator', {
               is: SalaryCalculator
           });
           calculator.recordId = this.recordId;
           this.template.querySelector('.container').appendChild(calculator);
       }
   }

ACCESSIBILITY:
1. Add ARIA labels and roles:
   <lightning-button
       label="Calculate"
       onclick={handleCalculate}
       aria-label="Calculate take-home salary"
       aria-describedby="help-text">
   </lightning-button>
   <div id="help-text" class="slds-assistive-text">
       This button calculates your estimated take-home pay
   </div>

2. Keyboard navigation:
   handleKeyDown(event) {
       if (event.key === 'Enter' || event.key === ' ') {
           this.handleCalculate();
       }
   }

PERFORMANCE OPTIMIZATION:
1. Use wire with caching:
   @wire(getJobApplications, { status: '$selectedStatus' })
   wiredApplications({ error, data }) {
       // Data is automatically cached by LDS
   }

2. Lazy load components:
   // Use dynamic import
   async loadChartComponent() {
       const { default: ChartComponent } = await import('c/advancedChart');
       // Use ChartComponent
   }

COMPONENT LIBRARY:
1. Create reusable components:
   - c/customButton (branded button)
   - c/customCard (card with standard styling)
   - c/customDataTable (enhanced datatable)
   - c/customModal (modal dialog)

2. Document with JSDoc:
   /**
    * Custom button component with brand styling
    * @param {string} label - Button label
    * @param {string} variant - Button variant (primary, secondary, destructive)
    * @param {boolean} disabled - Whether button is disabled
    * @fires CustomButton#buttonclick
    */
   export default class CustomButton extends LightningElement { }
```

**Complementary Tech Skills:**
- **React Advanced Patterns**: HOCs, Render Props, Hooks (conceptual transfer)
- **State Management**: Redux concepts (for complex LWC apps)
- **Web Accessibility**: WCAG 2.1 guidelines
- **Design Systems**: Component library design

**Resources:**
- Trailhead: [Advanced Lightning Web Components](https://trailhead.salesforce.com/content/learn/modules/advanced-lwc)
- Read: [LMS Documentation](https://developer.salesforce.com/docs/component-library/documentation/en/lwc/lwc.use_message_channel)
- Read: [Web Accessibility](https://www.w3.org/WAI/WCAG21/quickref/)

---

#### Week 3-4: LWC Salesforce Integration Patterns

**What You'll Learn:**
- Lightning Data Service (LDS) advanced patterns
- Working with record forms (lightning-record-form, lightning-record-edit-form, lightning-record-view-form)
- User Interface API
- Apex continuation for long-running callouts
- File upload and Lightning File Upload component
- Rich text editor integration
- Map component integration

**Project Connection:**
- Enhance Job Application forms
- Add file upload for resume
- Integrate mapping for job locations

**Hands-On Exercise:**
```
ADVANCED LDS PATTERNS:
1. Use lightning-record-edit-form with custom validation:
   <template>
       <lightning-record-edit-form
           object-api-name={objectApiName}
           record-id={recordId}
           onsubmit={handleSubmit}
           onsuccess={handleSuccess}>

           <lightning-input-field field-name="Company_Name__c"></lightning-input-field>
           <lightning-input-field field-name="Position_Title__c"></lightning-input-field>
           <lightning-input-field field-name="Salary__c"></lightning-input-field>

           <div class="slds-m-top_medium">
               <lightning-button
                   type="submit"
                   label="Save Application">
               </lightning-button>
           </div>
       </lightning-record-edit-form>
   </template>

2. Custom validation before submit:
   handleSubmit(event) {
       event.preventDefault();
       const fields = event.detail.fields;

       if (fields.Salary__c < 20000) {
           this.dispatchEvent(
               new ShowToastEvent({
                   title: 'Error',
                   message: 'Salary must be at least $20,000',
                   variant: 'error'
               })
           );
           return;
       }

       this.template.querySelector('lightning-record-edit-form').submit(fields);
   }

FILE UPLOAD:
1. Add lightning-file-upload to job application:
   <template>
       <lightning-card title="Upload Resume">
           <lightning-file-upload
               label="Resume"
               name="fileUploader"
               accept=".pdf,.doc,.docx"
               record-id={recordId}
               onuploadfinished={handleUploadFinished}
               multiple>
           </lightning-file-upload>
       </lightning-card>
   </template>

2. Handle upload completion:
   handleUploadFinished(event) {
       const uploadedFiles = event.detail.files;
       this.dispatchEvent(
           new ShowToastEvent({
               title: 'Success',
               message: uploadedFiles.length + ' resume(s) uploaded',
               variant: 'success'
           })
       );
   }

MAP INTEGRATION:
1. Add map for job location:
   <template>
       <lightning-map
           map-markers={mapMarkers}
           zoom-level={zoomLevel}>
       </lightning-map>
   </template>

2. Prepare map markers:
   get mapMarkers() {
       return [{
           location: {
               Street: '1 Market St',
               City: 'San Francisco',
               State: 'CA',
               PostalCode: '94105'
           },
           title: this.companyName,
           description: this.positionTitle,
           icon: 'standard:account'
       }];
   }

APEX CONTINUATION:
1. For long-running callouts:
   public class SalaryDataContinuation {
       @AuraEnabled(continuation=true cacheable=true)
       public static Object getSalaryDataAsync(String jobTitle) {
           Continuation cont = new Continuation(60); // 60 second timeout
           cont.state = jobTitle;

           HttpRequest req = new HttpRequest();
           req.setEndpoint('https://api.salary.com/data');
           req.setMethod('GET');

           cont.addHttpRequest(req);
           cont.continuationMethod = 'processResponse';

           return cont;
       }

       @AuraEnabled(cacheable=true)
       public static Object processResponse(List<String> labels, Object state) {
           HttpResponse res = Continuation.getResponse(labels[0]);
           return res.getBody();
       }
   }
```

**Complementary Tech Skills:**
- **REST API Advanced**: HATEOAS, API versioning
- **WebSockets**: Real-time communication concepts
- **Progressive Web Apps**: Service workers, offline support

**Resources:**
- Trailhead: [Lightning Data Service](https://trailhead.salesforce.com/content/learn/modules/lightning_data_service)
- Read: [UI API Developer Guide](https://developer.salesforce.com/docs/atlas.en-us.uiapi.meta/uiapi/)

---

### Month 11: Enterprise Integration & API Design

#### Week 1-2: Building RESTful APIs in Salesforce

**What You'll Learn:**
- @RestResource annotation
- HTTP methods (GET, POST, PUT, PATCH, DELETE)
- URL mapping and path parameters
- Request/Response classes
- API versioning strategies
- Error handling and status codes
- Authentication (OAuth 2.0, JWT)
- Rate limiting and throttling

**Project Connection:**
- Build REST API for Job Application Tracker
- Expose endpoints for external systems
- Implement authentication

**Hands-On Exercise:**
```
CREATE REST API:
1. Build JobApplicationAPI.cls:
   @RestResource(urlMapping='/api/v1/job-applications/*')
   global with sharing class JobApplicationAPI {

       @HttpGet
       global static JobApplicationResponse getApplication() {
           RestRequest req = RestContext.request;
           String applicationId = req.requestURI.substring(req.requestURI.lastIndexOf('/') + 1);

           try {
               Job_Application__c app = [
                   SELECT Id, Company_Name__c, Position_Title__c, Status__c, Salary__c,
                          Take_Home_Pay_Yearly__c, Take_Home_Pay_Monthly__c
                   FROM Job_Application__c
                   WHERE Id = :applicationId
                   LIMIT 1
               ];

               return new JobApplicationResponse(true, 'Success', app);
           } catch (Exception e) {
               RestContext.response.statusCode = 404;
               return new JobApplicationResponse(false, 'Application not found', null);
           }
       }

       @HttpPost
       global static JobApplicationResponse createApplication(ApplicationRequest request) {
           try {
               Job_Application__c app = new Job_Application__c(
                   Company_Name__c = request.companyName,
                   Position_Title__c = request.positionTitle,
                   Status__c = request.status,
                   Salary__c = request.salary
               );
               insert app;

               RestContext.response.statusCode = 201;
               return new JobApplicationResponse(true, 'Created', app);
           } catch (DmlException e) {
               RestContext.response.statusCode = 400;
               return new JobApplicationResponse(false, e.getMessage(), null);
           }
       }

       @HttpPatch
       global static JobApplicationResponse updateApplication() {
           RestRequest req = RestContext.request;
           String applicationId = req.requestURI.substring(req.requestURI.lastIndexOf('/') + 1);
           ApplicationRequest request = (ApplicationRequest) JSON.deserialize(req.requestBody.toString(), ApplicationRequest.class);

           try {
               Job_Application__c app = [SELECT Id FROM Job_Application__c WHERE Id = :applicationId];

               if (request.companyName != null) app.Company_Name__c = request.companyName;
               if (request.positionTitle != null) app.Position_Title__c = request.positionTitle;
               if (request.status != null) app.Status__c = request.status;
               if (request.salary != null) app.Salary__c = request.salary;

               update app;

               return new JobApplicationResponse(true, 'Updated', app);
           } catch (Exception e) {
               RestContext.response.statusCode = 400;
               return new JobApplicationResponse(false, e.getMessage(), null);
           }
       }

       @HttpDelete
       global static JobApplicationResponse deleteApplication() {
           RestRequest req = RestContext.request;
           String applicationId = req.requestURI.substring(req.requestURI.lastIndexOf('/') + 1);

           try {
               Job_Application__c app = [SELECT Id FROM Job_Application__c WHERE Id = :applicationId];
               delete app;

               RestContext.response.statusCode = 204;
               return new JobApplicationResponse(true, 'Deleted', null);
           } catch (Exception e) {
               RestContext.response.statusCode = 404;
               return new JobApplicationResponse(false, 'Application not found', null);
           }
       }
   }

   global class ApplicationRequest {
       public String companyName;
       public String positionTitle;
       public String status;
       public Decimal salary;
   }

   global class JobApplicationResponse {
       public Boolean success;
       public String message;
       public Job_Application__c data;

       public JobApplicationResponse(Boolean success, String message, Job_Application__c data) {
           this.success = success;
           this.message = message;
           this.data = data;
       }
   }

TEST THE API:
1. Using Postman or cURL:
   # Create
   curl -X POST https://yourinstance.salesforce.com/services/apexrest/api/v1/job-applications \
     -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{
       "companyName": "Salesforce",
       "positionTitle": "Senior Developer",
       "status": "Saved",
       "salary": 120000
     }'

   # Get
   curl https://yourinstance.salesforce.com/services/apexrest/api/v1/job-applications/a00XXXXXXXX \
     -H "Authorization: Bearer YOUR_ACCESS_TOKEN"

   # Update
   curl -X PATCH https://yourinstance.salesforce.com/services/apexrest/api/v1/job-applications/a00XXXXXXXX \
     -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{ "status": "Applied" }'

   # Delete
   curl -X DELETE https://yourinstance.salesforce.com/services/apexrest/api/v1/job-applications/a00XXXXXXXX \
     -H "Authorization: Bearer YOUR_ACCESS_TOKEN"

OAUTH 2.0 SETUP:
1. Create Connected App:
   - Setup → App Manager → New Connected App
   - Enable OAuth Settings
   - Selected OAuth Scopes: full, refresh_token
   - Callback URL: https://localhost:8080/callback

2. Get access token:
   # Using Username-Password Flow (for testing only)
   curl -X POST https://login.salesforce.com/services/oauth2/token \
     -d "grant_type=password" \
     -d "client_id=YOUR_CLIENT_ID" \
     -d "client_secret=YOUR_CLIENT_SECRET" \
     -d "username=YOUR_USERNAME" \
     -d "password=YOUR_PASSWORD_AND_TOKEN"

WRITE API TESTS:
1. Create JobApplicationAPITest.cls with mock requests
```

**Complementary Tech Skills:**
- **API Design**: REST principles, Richardson Maturity Model
- **OAuth 2.0**: All grant types, JWT tokens
- **API Documentation**: OpenAPI/Swagger
- **Postman**: API testing and automation

**Resources:**
- Trailhead: [Apex REST Callouts](https://trailhead.salesforce.com/content/learn/modules/apex_integration_services)
- Read: [REST API Developer Guide](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_rest.htm)
- Read: [OAuth 2.0 Specification](https://oauth.net/2/)

---

#### Week 3-4: Platform Events & Event-Driven Architecture

**What You'll Learn:**
- Platform Events (custom events)
- Change Data Capture (CDC)
- PushTopics and Streaming API
- Event-driven architecture patterns
- Event publishing and subscribing
- CometD and long polling
- Event replay and durability
- Error handling in async events

**Project Connection:**
- Create events for Job Application changes
- Subscribe to events in LWC
- Implement real-time notifications

**Hands-On Exercise:**
```
CREATE PLATFORM EVENT:
1. Setup → Platform Events → New Platform Event
   API Name: Job_Application_Event__e
   Fields:
   - Application_Id__c (Text)
   - Status__c (Text)
   - Action__c (Text) - created, updated, deleted
   - User_Id__c (Text)

2. Publish event in trigger:
   public class JobApplicationEventPublisher {
       public static void publishCreateEvent(Job_Application__c app) {
           Job_Application_Event__e event = new Job_Application_Event__e(
               Application_Id__c = app.Id,
               Status__c = app.Status__c,
               Action__c = 'created',
               User_Id__c = UserInfo.getUserId()
           );

           Database.SaveResult result = EventBus.publish(event);

           if (!result.isSuccess()) {
               for (Database.Error err : result.getErrors()) {
                   System.debug('Error publishing event: ' + err.getMessage());
               }
           }
       }
   }

3. Subscribe in Apex Trigger:
   trigger JobApplicationEventTrigger on Job_Application_Event__e (after insert) {
       for (Job_Application_Event__e event : Trigger.new) {
           System.debug('Event received: ' + event.Action__c + ' for ' + event.Application_Id__c);

           // Process event (send notification, update dashboard, etc.)
           if (event.Action__c == 'created') {
               // Send welcome email
               EmailNotificationQueue.sendWelcomeEmail(event.Application_Id__c);
           }
       }
   }

SUBSCRIBE IN LWC:
1. Create event listener component:
   import { LightningElement } from 'lwc';
   import { subscribe, unsubscribe, onError } from 'lightning/empApi';

   export default class JobApplicationEventListener extends LightningElement {
       channelName = '/event/Job_Application_Event__e';
       subscription = {};

       connectedCallback() {
           this.handleSubscribe();
           this.registerErrorListener();
       }

       handleSubscribe() {
           const messageCallback = (response) => {
               console.log('Event received: ', JSON.stringify(response));

               const eventData = response.data.payload;

               // Update UI
               this.dispatchEvent(new CustomEvent('applicationupdate', {
                   detail: {
                       applicationId: eventData.Application_Id__c,
                       status: eventData.Status__c,
                       action: eventData.Action__c
                   }
               }));
           };

           subscribe(this.channelName, -1, messageCallback).then(response => {
               console.log('Subscribed to channel: ', JSON.stringify(response.channel));
               this.subscription = response;
           });
       }

       registerErrorListener() {
           onError(error => {
               console.error('EMP API error: ', JSON.stringify(error));
           });
       }

       disconnectedCallback() {
           unsubscribe(this.subscription);
       }
   }

CHANGE DATA CAPTURE:
1. Enable CDC for Job_Application__c:
   - Setup → Change Data Capture
   - Select Job_Application__c
   - Save

2. Subscribe to CDC in LWC:
   channelName = '/data/Job_Application__ChangeEvent';

   messageCallback = (response) => {
       const payload = response.data.payload;

       if (payload.ChangeEventHeader.changeType === 'CREATE') {
           console.log('New application created');
       } else if (payload.ChangeEventHeader.changeType === 'UPDATE') {
           console.log('Application updated');
       }
   };

EVENT REPLAY:
1. Subscribe with replay ID to get missed events:
   const replayId = -1; // -1 = tip of queue, -2 = all retained events
   subscribe(this.channelName, replayId, messageCallback);

2. Store and use replay ID for recovery:
   localStorage.setItem('lastReplayId', response.data.event.replayId);
```

**Complementary Tech Skills:**
- **Event-Driven Architecture**: Event sourcing, CQRS
- **Message Queues**: Kafka, RabbitMQ concepts
- **WebSockets**: Bi-directional communication
- **Server-Sent Events**: Push notifications

**Resources:**
- Trailhead: [Platform Events Basics](https://trailhead.salesforce.com/content/learn/modules/platform_events_basics)
- Read: [Platform Events Developer Guide](https://developer.salesforce.com/docs/atlas.en-us.platform_events.meta/platform_events/)
- Read: [Change Data Capture Developer Guide](https://developer.salesforce.com/docs/atlas.en-us.change_data_capture.meta/change_data_capture/)

---

### Month 12: Data & Analytics

#### Week 1-2: Advanced Data Management

**What You'll Learn:**
- Data loader (import/export)
- Bulk API and Bulk API 2.0
- Dataloader.io and other ETL tools
- Data migration strategies
- Large data volumes (LDV) best practices
- Skinny tables
- Big objects
- External objects and External Services
- Data archiving strategies

**Project Connection:**
- Import large datasets for testing
- Export data for analytics
- Handle millions of records

**Hands-On Exercise:**
```
DATA LOADER:
1. Install Salesforce Data Loader

2. Export all Job Applications:
   - Select "Export"
   - Choose Job_Application__c
   - Select all fields
   - Add filter: CreatedDate > LAST_N_DAYS:90
   - Run export → CSV file

3. Import 10,000 test records:
   - Prepare CSV with columns: Company_Name__c, Position_Title__c, Status__c, Salary__c
   - Select "Insert"
   - Map fields
   - Run import
   - Review success/error logs

BULK API IN APEX:
1. Use Batch Apex for large operations:
   global class BulkJobApplicationUpdate implements Database.Batchable<sObject> {
       global Database.QueryLocator start(Database.BatchableContext bc) {
           return Database.getQueryLocator([
               SELECT Id, Status__c
               FROM Job_Application__c
               WHERE Status__c = 'Applied'
               AND Application_Date__c < LAST_N_DAYS:90
           ]);
       }

       global void execute(Database.BatchableContext bc, List<Job_Application__c> scope) {
           for (Job_Application__c app : scope) {
               app.Status__c = 'Closed';
               app.Notes__c = 'Auto-closed after 90 days';
           }
           update scope;
       }

       global void finish(Database.BatchableContext bc) {
           AsyncApexJob job = [
               SELECT Id, Status, NumberOfErrors, JobItemsProcessed
               FROM AsyncApexJob
               WHERE Id = :bc.getJobId()
           ];
           System.debug('Processed ' + job.JobItemsProcessed + ' batches with ' + job.NumberOfErrors + ' errors');
       }
   }

2. Run batch job:
   Database.executeBatch(new BulkJobApplicationUpdate(), 200);

EXTERNAL OBJECTS:
1. Setup external data source (for integrating external DB):
   - Setup → External Data Sources → New
   - Type: OData 4.0
   - URL: https://external-api.com/odata
   - Authentication: Named Credential

2. Create external object:
   - Sync from external data source
   - Map fields
   - Use in SOQL: SELECT Id, Name FROM External_Jobs__x

ARCHIVING STRATEGY:
1. Create archive process:
   - Identify records older than 2 years
   - Export to S3 or external database
   - Delete from Salesforce
   - Maintain reference table for lookups

2. Implement soft delete:
   - Add Archived__c checkbox field
   - Filter views: WHERE Archived__c = false
   - Scheduled job to hard delete after retention period
```

**Complementary Tech Skills:**
- **ETL Tools**: Informatica, Talend, Apache Nifi
- **SQL Databases**: PostgreSQL, MySQL advanced features
- **Data Warehousing**: Snowflake, Redshift concepts
- **Data Modeling**: Dimensional modeling, star schema

**Resources:**
- Trailhead: [Data Management](https://trailhead.salesforce.com/content/learn/modules/lex_implementation_data_management)
- Read: [Large Data Volumes Best Practices](https://developer.salesforce.com/docs/atlas.en-us.salesforce_large_data_volumes_bp.meta/salesforce_large_data_volumes_bp/)

---

#### Week 3-4: Einstein Analytics & Advanced Reporting

**What You'll Learn:**
- Reports and Dashboards advanced features
- Custom Report Types
- Matrix reports and cross-filters
- Bucket fields and formulas
- Einstein Analytics (Tableau CRM) basics
- SAQL (Salesforce Analytics Query Language)
- Datasets and dataflows
- Dashboard JSON customization

**Project Connection:**
- Build executive dashboard for Job Applications
- Create Einstein Analytics lens
- Advanced analytics and predictions

**Hands-On Exercise:**
```
CUSTOM REPORT TYPE:
1. Setup → Report Types → New Custom Report Type
   Primary Object: Job Applications
   Related Objects: Tasks, Events, Contacts

2. Select fields to include in reports

3. Build report:
   - Report Type: Job Applications with Tasks
   - Group by: Status
   - Show: Count, Average Salary, Tasks Count
   - Chart: Funnel chart for status progression

ADVANCED DASHBOARD:
1. Create components:
   - Applications by Status (Pie Chart)
   - Salary Distribution (Bar Chart)
   - Application Trend (Line Chart, by month)
   - Top Companies (Table)
   - Conversion Funnel (Funnel Chart)

2. Add dynamic filters:
   - Date range
   - Status
   - Salary range

3. Use dashboard filters to drill down

EINSTEIN ANALYTICS (If available):
1. Create dataset from Job Applications:
   - Setup → Analytics Studio → Create → Dataset
   - Source: Job_Application__c
   - Schedule: Daily

2. Create lens (exploration):
   - Measures: Count, Avg(Salary)
   - Group by: Status, Company_Name
   - Filters: Application_Date > last 90 days

3. Build dashboard with widgets:
   - Timeline showing applications over time
   - Compare widget for status breakdown
   - Number widget for total applications
   - Table for detailed list

4. Add SAQL query for custom calculation:
   q = load "Job_Applications_Dataset";
   q = group q by 'Status__c';
   q = foreach q generate
       'Status__c' as 'Status',
       count() as 'Count',
       avg('Salary__c') as 'AvgSalary';
   q = order q by 'Count' desc;

PREDICTIVE ANALYTICS:
1. Use Einstein Discovery (if available):
   - Import Job Application dataset
   - Build story to predict: What drives Accepted status?
   - Deploy model as invocable action
   - Call from Flow or Apex
```

**Complementary Tech Skills:**
- **Business Intelligence**: Tableau, Power BI
- **Data Visualization**: D3.js, Chart.js
- **Statistical Analysis**: Basic statistics, correlation
- **Machine Learning Basics**: Supervised learning concepts

**Resources:**
- Trailhead: [Reports & Dashboards](https://trailhead.salesforce.com/content/learn/modules/reports_dashboards)
- Trailhead: [Einstein Analytics Basics](https://trailhead.salesforce.com/content/learn/modules/wave_exploration_basics)
- Read: [Analytics Developer Guide](https://developer.salesforce.com/docs/atlas.en-us.bi_dev_guide_rest.meta/bi_dev_guide_rest/)

---

### Month 13: Security & Compliance

#### Week 1-2: Advanced Security

**What You'll Learn:**
- CRUD/FLS enforcement in code
- Security Review requirements (AppExchange)
- Shield Platform Encryption
- Event Monitoring
- Transaction Security Policies
- Two-factor authentication (2FA)
- Single Sign-On (SSO) setup
- Security Health Check
- Penetration testing concepts

**Project Connection:**
- Audit project for security issues
- Implement CRUD/FLS checks
- Encrypt sensitive salary data

**Hands-On Exercise:**
```
CRUD/FLS ENFORCEMENT:
1. Create security utility class:
   public class SecurityUtils {
       public static Boolean canCreate(Schema.SObjectType objType) {
           return objType.getDescribe().isCreateable();
       }

       public static Boolean canRead(Schema.SObjectType objType) {
           return objType.getDescribe().isAccessible();
       }

       public static Boolean canUpdate(Schema.SObjectType objType) {
           return objType.getDescribe().isUpdateable();
       }

       public static Boolean canDelete(Schema.SObjectType objType) {
           return objType.getDescribe().isDeletable();
       }

       public static Boolean canReadField(Schema.SObjectField field) {
           return field.getDescribe().isAccessible();
       }

       public static void enforceCRUD(Schema.SObjectType objType, String operation) {
           if (operation == 'create' && !canCreate(objType)) {
               throw new SecurityException('No create permission');
           }
           // ... other operations
       }
   }

2. Use in service class:
   public with sharing class SecureJobApplicationService {
       public static void createApplication(Job_Application__c app) {
           SecurityUtils.enforceCRUD(Job_Application__c.SObjectType, 'create');

           if (!SecurityUtils.canReadField(Job_Application__c.Salary__c)) {
               app.Salary__c = null; // Strip sensitive field
           }

           insert app;
       }
   }

3. Use Security.stripInaccessible():
   List<Job_Application__c> apps = [SELECT Id, Salary__c FROM Job_Application__c];
   SObjectAccessDecision decision = Security.stripInaccessible(
       AccessType.READABLE,
       apps
   );
   return decision.getRecords();

PLATFORM ENCRYPTION:
1. Purchase and enable Shield
2. Setup → Platform Encryption → Key Management
3. Generate tenant secret
4. Encrypt Salary__c field:
   - Edit field → Enable encryption
   - Choose encryption scheme

EVENT MONITORING:
1. Enable Event Monitoring:
   - Setup → Event Monitoring → Settings

2. Query EventLogFile:
   List<EventLogFile> logs = [
       SELECT Id, EventType, LogDate, LogFile
       FROM EventLogFile
       WHERE EventType = 'ApexExecution'
       AND LogDate = TODAY
   ];

3. Download and analyze logs for:
   - Slow queries
   - Large query results
   - Long-running Apex
   - Security anomalies

TRANSACTION SECURITY POLICIES:
1. Create policy for data export prevention:
   - Setup → Transaction Security
   - New Policy → Report Export
   - Action: Block
   - Condition: If user downloads > 10,000 records

2. Create Apex policy:
   public class BlockMassDelete implements TxnSecurity.PolicyCondition {
       public boolean evaluate(TxnSecurity.Event e) {
           if (e.data.get('NumberOfRecords') > 100) {
               return true; // Trigger policy action
           }
           return false;
       }
   }

SECURITY REVIEW CHECKLIST:
- [ ] All Apex classes use 'with sharing'
- [ ] CRUD/FLS checks in place
- [ ] No hardcoded credentials
- [ ] SOQL injection prevention
- [ ] XSS prevention in Visualforce/LWC
- [ ] CSRF tokens used
- [ ] API endpoints secured
- [ ] Sensitive data encrypted
- [ ] Audit logs enabled
```

**Complementary Tech Skills:**
- **Application Security**: OWASP Top 10 deep dive
- **Encryption**: Symmetric vs asymmetric, key management
- **Penetration Testing**: Burp Suite, OWASP ZAP basics
- **Compliance**: SOC 2, GDPR, HIPAA basics

**Resources:**
- Trailhead: [Security Specialist](https://trailhead.salesforce.com/content/learn/superbadges/superbadge_security)
- Read: [Secure Coding Guidelines](https://developer.salesforce.com/docs/atlas.en-us.secure_coding_guide.meta/secure_coding_guide/)
- Read: [AppExchange Security Review](https://developer.salesforce.com/docs/atlas.en-us.packagingGuide.meta/packagingGuide/security_review.htm)

---

#### Week 3-4: Compliance & Governance

**What You'll Learn:**
- Data retention policies
- GDPR compliance (right to be forgotten)
- Field audit trail
- Setup audit trail
- Metadata API for governance
- Change sets and dependencies
- Release management
- Compliance documentation

**Project Connection:**
- Implement GDPR compliance features
- Set up audit trails
- Document compliance measures

**Hands-On Exercise:**
```
FIELD AUDIT TRAIL:
1. Enable Field History Tracking:
   - Object Manager → Job_Application__c → Fields & Relationships
   - Set History Tracking
   - Select fields: Status, Salary, Company_Name

2. Query field history:
   List<Job_Application__History> history = [
       SELECT Field, OldValue, NewValue, CreatedDate, CreatedBy.Name
       FROM Job_Application__History
       WHERE ParentId = :recordId
       ORDER BY CreatedDate DESC
   ];

3. Display in LWC component

GDPR COMPLIANCE:
1. Implement "Right to be Forgotten":
   public class GDPRService {
       @future
       public static void anonymizeData(Id recordId) {
           Job_Application__c app = [SELECT Id FROM Job_Application__c WHERE Id = :recordId];

           app.Company_Name__c = 'REDACTED';
           app.Notes__c = null;
           app.Salary__c = null;
           app.Primary_Contact__c = null;

           update app;

           // Delete related files
           List<ContentDocumentLink> links = [
               SELECT ContentDocumentId
               FROM ContentDocumentLink
               WHERE LinkedEntityId = :recordId
           ];
           List<Id> docIds = new List<Id>();
           for (ContentDocumentLink link : links) {
               docIds.add(link.ContentDocumentId);
           }
           delete [SELECT Id FROM ContentDocument WHERE Id IN :docIds];
       }
   }

2. Create "Export my data" feature:
   public class DataExportService {
       public static String exportUserData(Id userId) {
           List<Job_Application__c> apps = [
               SELECT Id, Company_Name__c, Position_Title__c, Status__c, Salary__c,
                      CreatedDate, LastModifiedDate
               FROM Job_Application__c
               WHERE OwnerId = :userId
           ];

           return JSON.serializePretty(apps);
       }
   }

DATA RETENTION:
1. Create retention policy:
   - Archive records after 7 years
   - Delete after 10 years (or as required)

2. Implement scheduled job:
   global class DataRetentionJob implements Schedulable {
       global void execute(SchedulableContext sc) {
           // Archive old records
           List<Job_Application__c> toArchive = [
               SELECT Id
               FROM Job_Application__c
               WHERE CreatedDate < LAST_N_YEARS:7
               AND Archived__c = false
           ];

           // Export to external system
           DataArchiveService.archiveRecords(toArchive);

           // Mark as archived
           for (Job_Application__c app : toArchive) {
               app.Archived__c = true;
           }
           update toArchive;

           // Hard delete very old records
           delete [
               SELECT Id
               FROM Job_Application__c
               WHERE CreatedDate < LAST_N_YEARS:10
               AND Archived__c = true
           ];
       }
   }

RELEASE MANAGEMENT:
1. Create release checklist:
   - [ ] Code review completed
   - [ ] Test coverage > 95%
   - [ ] Security review passed
   - [ ] Performance tested
   - [ ] Documentation updated
   - [ ] Change set created
   - [ ] Deployment validated
   - [ ] Rollback plan ready
   - [ ] Stakeholders notified

2. Document in RELEASE_NOTES.md for each release
```

**Complementary Tech Skills:**
- **Regulatory Compliance**: GDPR, CCPA, HIPAA
- **Data Governance**: Master data management
- **Documentation**: Technical writing skills
- **Project Management**: Agile, Scrum basics

**Resources:**
- Trailhead: [Data Privacy & Compliance](https://trailhead.salesforce.com/content/learn/modules/privacy-and-compliance)
- Read: [Field Audit Trail](https://help.salesforce.com/s/articleView?id=sf.field_audit_trail.htm)

---

### Month 14: Leadership & Soft Skills

#### Week 1-2: Code Review & Mentoring

**What You'll Learn:**
- Code review best practices
- Giving constructive feedback
- Mentoring junior developers
- Pair programming
- Technical documentation
- Knowledge sharing (brown bags, demos)
- Interviewing candidates
- Building technical roadmaps

**Hands-On Exercise:**
```
CODE REVIEW PRACTICE:
1. Review checklist:
   - [ ] Code follows naming conventions
   - [ ] No hardcoded IDs or credentials
   - [ ] SOQL queries are bulkified (no queries in loops)
   - [ ] DML operations are bulkified
   - [ ] Error handling present (try/catch)
   - [ ] Security: with sharing, CRUD/FLS checks
   - [ ] Test coverage exists and is meaningful
   - [ ] Code is readable and well-commented
   - [ ] No complex nested loops
   - [ ] Governor limits considered

2. Practice reviews on GitHub:
   - Comment on pull requests
   - Suggest improvements
   - Approve or request changes

MENTORING:
1. Create learning materials:
   - Write blog posts about features you built
   - Create video tutorials
   - Conduct lunch-and-learn sessions

2. Pair programming:
   - Schedule sessions with junior devs
   - Walk through complex code
   - Think out loud while coding

TECHNICAL DOCUMENTATION:
1. Create architecture diagrams:
   - Use Lucidchart or Draw.io
   - Document data flow
   - Show integration points

2. Write technical specs:
   - Problem statement
   - Proposed solution
   - Technical approach
   - Alternative solutions considered
   - Risks and mitigations
   - Testing strategy

3. Update project README:
   - Keep current with latest changes
   - Add troubleshooting section
   - Include setup instructions
```

**Complementary Tech Skills:**
- **Communication**: Written and verbal clarity
- **Empathy**: Understanding different skill levels
- **Diagramming**: UML, C4 model, flowcharts
- **Public Speaking**: Presenting technical topics

---

#### Week 3-4: Problem-Solving & System Design

**What You'll Learn:**
- System design principles
- Requirement gathering
- Trade-off analysis
- Scalability planning
- Debugging complex issues
- Root cause analysis
- Technical decision-making
- Stakeholder management

**Hands-On Exercise:**
```
SYSTEM DESIGN EXERCISES:
1. Design a job board integration:
   - Requirements: Import 10,000 jobs daily from multiple APIs
   - Consider: Rate limits, duplicates, data quality, errors
   - Solution:
     - Scheduled batch job (6 AM daily)
     - Queueable for API callouts (chaining for rate limits)
     - Deduplication using external ID
     - Error logging and retry mechanism
     - Dashboard for monitoring

2. Design a real-time salary comparison:
   - Requirements: Show market salary when user enters job title
   - Consider: API costs, performance, caching, accuracy
   - Solution:
     - Platform Cache (1 hour TTL)
     - LWC with debounced input
     - Cacheable Apex method
     - Fallback to last known data if API fails

DEBUGGING COMPLEX ISSUES:
1. Use systematic approach:
   - Reproduce the issue
   - Gather all error messages and logs
   - Identify when it started (recent changes?)
   - Isolate variables (user, data, timing)
   - Form hypothesis
   - Test hypothesis
   - Fix and verify

2. Example: "Tasks not being created for some applications"
   - Check debug logs
   - Verify trigger is firing
   - Check if TaskCreationService is called
   - Query for DML errors
   - Check governor limits
   - Verify user permissions
   - Test with different users/data
   - Find: Bulkification issue when > 200 apps processed
   - Fix: Batch task creation properly

ROOT CAUSE ANALYSIS (5 Whys):
1. Problem: Production deployment failed
   - Why? Tests failed
   - Why? New code broke existing tests
   - Why? Tests relied on specific data
   - Why? Tests didn't use @testSetup
   - Why? Junior dev unfamiliar with best practices
   - Root cause: Need better onboarding and code review

2. Action items:
   - Update onboarding docs
   - Add test best practices to code review checklist
   - Pair junior devs with seniors for first few PRs
```

**Complementary Tech Skills:**
- **Critical Thinking**: Structured problem-solving
- **Systems Thinking**: Understanding interconnections
- **Stakeholder Management**: Managing expectations
- **Decision Making**: Data-driven decisions

---

### 🎓 Phase 3 Assessment: Can You...?

**Salesforce Skills:**
- [ ] Design scalable solutions using enterprise patterns
- [ ] Optimize code for performance and governor limits
- [ ] Build production-ready REST APIs
- [ ] Implement event-driven architectures
- [ ] Handle large data volumes efficiently
- [ ] Ensure security and compliance
- [ ] Lead code reviews and mentor others
- [ ] Make architectural decisions with trade-off analysis

**Tech Skills:**
- [ ] Design system architecture diagrams
- [ ] Write comprehensive technical documentation
- [ ] Debug complex, multi-layer issues
- [ ] Perform root cause analysis
- [ ] Give technical presentations

**Leadership Skills:**
- [ ] Mentor junior developers effectively
- [ ] Conduct thorough code reviews
- [ ] Make technical decisions with business context
- [ ] Manage stakeholder expectations
- [ ] Plan and execute complex projects

---

## 🚀 PHASE 4: MASTERY (Months 15-18+) - Architect Level

### 🎯 Goal
Design enterprise architectures, lead technical strategy, drive innovation, and become a recognized expert in the Salesforce ecosystem.

---

### Month 15: Salesforce Architecture

#### Advanced Topics:
- **Multi-Org Strategy**: Hub-and-spoke, mesh architectures
- **Unlocked Packages**: Modular development, dependency management
- **Scratch Org Pooling**: CI/CD optimization
- **API Gateway Patterns**: Rate limiting, transformation, orchestration
- **Data Virtualization**: External Objects, Connect API
- **Mobile Architecture**: Salesforce Mobile SDK, offline-first design

**Hands-On Project:**
Design and implement a multi-org synchronization solution for the Job Application Tracker that syncs data between personal org, company org, and recruiting agency orgs.

---

### Month 16: Advanced Integration Patterns

#### Advanced Topics:
- **Enterprise Service Bus (ESB)**: MuleSoft integration
- **Middleware Patterns**: iPaaS solutions (Boomi, Jitterbit)
- **Streaming Data**: Platform Events at scale, event replay
- **GraphQL APIs**: Exposing Salesforce data via GraphQL
- **Webhooks**: Implementing webhook endpoints
- **API Management**: Rate limiting, versioning, deprecation

**Hands-On Project:**
Build a complete integration layer that syncs Job Applications with LinkedIn, Indeed, and Glassdoor using modern integration patterns.

---

### Month 17: Innovation & Emerging Technologies

#### Advanced Topics:
- **Einstein Platform**: Einstein Vision, Language, Prediction Builder
- **Heroku Integration**: Building full-stack apps
- **Functions**: Salesforce Functions (serverless)
- **Blockchain**: Salesforce Blockchain platform
- **IoT**: Salesforce IoT Explorer
- **Mobile**: Native mobile apps with Mobile SDK

**Hands-On Project:**
Implement Einstein Prediction Builder to predict which job applications are most likely to result in an offer based on historical data.

---

### Month 18: Thought Leadership & Community

#### Focus Areas:
- **Salesforce Certifications**:
  - Platform Developer II
  - JavaScript Developer I
  - Integration Architecture Designer
  - Development Lifecycle & Deployment Designer
  - Application Architect
  - System Architect
- **Community Contribution**:
  - Answer questions on Salesforce Stack Exchange
  - Write blog posts and tutorials
  - Speak at local Salesforce meetups
  - Contribute to open-source Salesforce projects
  - Create YouTube videos or courses
- **Product Innovation**:
  - Build AppExchange apps
  - Create open-source libraries
  - Develop internal frameworks

---

## 🛠️ COMPLEMENTARY SKILLS TIMELINE

### Programming Languages
**Month 1-3**: JavaScript basics
**Month 4-6**: JavaScript ES6+, Node.js
**Month 7-9**: Python basics (for scripts, data analysis)
**Month 10-12**: Java basics (helps with Apex, Android development)
**Month 13-15**: Go or Rust (emerging backend languages)
**Month 16-18**: Mobile development (Swift/Kotlin or React Native)

### Databases
**Month 1-3**: SQL fundamentals
**Month 4-6**: SOQL mastery, database design
**Month 7-9**: NoSQL basics (MongoDB concepts)
**Month 10-12**: PostgreSQL/MySQL advanced
**Month 13-15**: Redis caching, data warehousing
**Month 16-18**: Graph databases (Neo4j)

### DevOps & Infrastructure
**Month 1-3**: Git basics
**Month 4-6**: Git workflows, GitHub
**Month 7-8**: CI/CD with GitHub Actions
**Month 9-10**: Docker basics
**Month 11-12**: Kubernetes fundamentals
**Month 13-14**: AWS/Azure basics
**Month 15-16**: Infrastructure as Code (Terraform)
**Month 17-18**: Monitoring (Datadog, New Relic)

### Frontend
**Month 1-3**: HTML, CSS basics
**Month 4-6**: Modern CSS (Grid, Flexbox), JavaScript
**Month 7-9**: LWC mastery
**Month 10-12**: React fundamentals
**Month 13-15**: Advanced React, state management
**Month 16-18**: Mobile development, PWAs

### Soft Skills
**Month 1-6**: Technical documentation
**Month 7-12**: Communication, presentation skills
**Month 13-18**: Leadership, mentoring, stakeholder management

---

## 📖 PROJECT-SPECIFIC DEEP DIVES

### Deep Dive 1: Trigger Framework Journey
**Duration**: 2 weeks
**Files**: `JobApplicationTrigger.trigger`, `JobApplicationTriggerHandler.cls`

#### Week 1: Understanding
- Read trigger execution order documentation
- Trace execution with debug logs
- Map out all trigger events
- Document context variables

#### Week 2: Enhancement
- Add recursion prevention
- Implement state management
- Add comprehensive logging
- Optimize bulkification
- Write advanced tests

---

### Deep Dive 2: Salary Calculation System
**Duration**: 2 weeks
**Files**: `SalaryCalculationService.cls`, `salaryCalculator` LWC

#### Week 1: Tax Calculation Logic
- Study federal tax brackets (2023)
- Understand progressive taxation
- Review Social Security cap
- Calculate edge cases
- Document formulas

#### Week 2: LWC Integration
- Study component architecture
- Understand reactive properties
- Implement real-time calculation
- Add input validation
- Enhance UX with formatting

---

### Deep Dive 3: Asynchronous Processing
**Duration**: 3 weeks
**Files**: `SalaryMarketAnalysisBatch.cls`, `EmailNotificationQueue.cls`, `SalaryMarketAnalysisScheduler.cls`

#### Week 1: Batch Apex
- Understand batch interface
- Study start, execute, finish methods
- Learn batch size optimization
- Implement error handling
- Monitor async jobs

#### Week 2: Queueable Apex
- Understand queueable interface
- Study chaining patterns
- Implement callouts
- Handle errors and retries
- Compare with @future

#### Week 3: Scheduler
- Study cron expressions
- Schedule batch jobs
- Implement monitoring
- Create scheduler tests
- Document scheduling strategy

---

### Deep Dive 4: API Integration
**Duration**: 2 weeks
**Files**: `SalaryDataAPIService.cls`

#### Week 1: RESTful Integration
- Study REST principles
- Understand HTTP methods
- Analyze retry logic
- Review timeout handling
- Test error scenarios

#### Week 2: Testing & Enhancement
- Write mock callouts
- Test all error paths
- Add caching layer
- Implement circuit breaker
- Document API usage

---

### Deep Dive 5: LWC Ecosystem
**Duration**: 3 weeks
**All 7 LWC components**

#### Week 1: Core Components
- Study `salaryCalculator`
- Analyze `calendarIntegration`
- Understand wire adapters
- Master imperative Apex

#### Week 2: Dashboard Components
- Study analytics dashboards
- Understand data aggregation
- Implement charts
- Add filters

#### Week 3: Testing & Enhancement
- Write Jest tests for all components
- Add accessibility features
- Optimize performance
- Implement lazy loading

---

## 📚 LEARNING RESOURCES

### Official Salesforce
- [Trailhead](https://trailhead.salesforce.com) - Official learning platform
- [Developer Documentation](https://developer.salesforce.com/docs)
- [Salesforce Blog](https://developer.salesforce.com/blogs)
- [Salesforce YouTube](https://www.youtube.com/salesforce)

### Community Resources
- [Salesforce Stack Exchange](https://salesforce.stackexchange.com)
- [Salesforce Reddit](https://reddit.com/r/salesforce)
- [Salesforce Ben](https://www.salesforceben.com)
- [Admin Hero](https://www.adminhero.com)

### Books
- "Advanced Apex Programming" by Dan Appleman
- "Force.com Enterprise Architecture" by Andrew Fawcett
- "Clean Code" by Robert Martin
- "Design Patterns" by Gang of Four
- "The Pragmatic Programmer" by Hunt & Thomas

### Online Courses
- Udemy: Salesforce Development courses
- Pluralsight: Salesforce learning paths
- LinkedIn Learning: Salesforce tutorials
- FreeCodeCamp: JavaScript & Web Development

### Practice Platforms
- LeetCode: Algorithm practice
- HackerRank: Coding challenges
- Salesforce Developer Org: Free practice environment

---

## 🎯 SUCCESS METRICS

### Junior Level (Months 1-3)
- [ ] Complete 50+ Trailhead badges
- [ ] Build 3 custom objects with automation
- [ ] Write first Apex trigger
- [ ] Create first LWC component
- [ ] Deploy using Salesforce DX

### Mid Level (Months 4-8)
- [ ] Complete 100+ Trailhead badges
- [ ] Build complete app with Apex and LWC
- [ ] Achieve 95%+ test coverage
- [ ] Implement REST API integration
- [ ] Set up CI/CD pipeline

### Senior Level (Months 9-14)
- [ ] Complete Platform Developer I certification
- [ ] Lead code reviews
- [ ] Optimize app for performance
- [ ] Implement enterprise patterns
- [ ] Mentor 2+ junior developers

### Architect Level (Months 15-18+)
- [ ] Complete 3+ certifications
- [ ] Design multi-org architecture
- [ ] Contribute to open source
- [ ] Speak at meetup or conference
- [ ] Publish technical blog posts

---

## 🔄 CONTINUOUS LEARNING

### Daily (30 minutes)
- Read Salesforce release notes
- Practice coding challenges
- Review 1 pull request
- Read technical blog post

### Weekly (3-5 hours)
- Complete 1-2 Trailhead modules
- Build something new in scratch org
- Contribute to Stack Exchange
- Watch technical webinar

### Monthly (10+ hours)
- Start new project or feature
- Deep dive into 1 advanced topic
- Attend Salesforce community event
- Update skills and resume

### Quarterly
- Take certification exam
- Speak at meetup
- Publish blog post or video
- Review and update learning plan

---

## 🎓 FINAL THOUGHTS

This learning path is **ambitious but achievable**. Remember:

1. **Progress over perfection**: Don't get stuck trying to master one topic completely before moving on.

2. **Build, build, build**: Hands-on project work is more valuable than passive learning.

3. **Community matters**: Engage with the Salesforce community early and often.

4. **Document your journey**: Blog, tweet, or journal about what you're learning.

5. **It's a marathon, not a sprint**: Pace yourself and avoid burnout.

6. **Specialize eventually**: After becoming a generalist, pick 1-2 areas to specialize in (e.g., integration, analytics, mobile).

7. **Stay current**: Salesforce releases 3 times per year - always be learning.

8. **Give back**: As you learn, help others who are earlier in their journey.

---

**Your journey to mastery starts now. Let's build something amazing! 🚀**
