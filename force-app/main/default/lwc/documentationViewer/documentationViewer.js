import { LightningElement } from 'lwc';

export default class DocumentationViewer extends LightningElement {
    activeSectionId = 'getting-started';

    sections = [
        {
            id: 'getting-started',
            title: 'Getting Started',
            icon: 'utility:home',
            content: [
                {
                    heading: 'Welcome to Job Application Tracker',
                    text: 'The Enterprise Job Application Tracker is a comprehensive Salesforce application built for managing your entire job search pipeline. Track applications across every stage, schedule interviews with conflict detection, analyze salary data with real-time tax calculations, and gain deep insights into your career journey — all in one unified platform.\n\nThis application was built as a capstone project for **Cloud Code Academy** by Temitayo, Mark, and Mike, demonstrating enterprise-grade Salesforce development with modern best practices.'
                },
                {
                    heading: 'Quick Start Guide',
                    text: '1. **Job Applications Tab** — Create a new application by clicking "New". Fill in Company Name, Position Title, Status, Salary, and Location. The app auto-generates follow-up tasks when you save.\n2. **Application Analytics** — View your pipeline as a Kanban board. See status breakdown charts, interview rates, and salary analysis at a glance.\n3. **Salary Calculator** — Enter any salary amount to see real-time federal tax, Social Security, Medicare, and take-home pay breakdowns using 2025 tax brackets.\n4. **Interview Calendar** — Schedule interviews with date/time pickers, platform selection (Zoom, Teams, etc.), and automatic conflict detection. View upcoming and past interviews in the timeline.\n5. **List Views** — Use pre-built filters like "Needs Follow-Up", "Interviewing", "Top Salary", and "Remote Positions" to quickly find what you need.\n6. **Documentation** — You are here! Reference guides for the entire application.'
                },
                {
                    heading: 'Key Features at a Glance',
                    text: '• **50+ job applications** with rich data — descriptions, job URLs, ratings, follow-up dates, and salary calculations\n• **10 list views** for instant filtering — Active, Interviewing, Negotiating, Needs Follow-Up, Remote, Top Salary, Accepted, High Priority, Recent, and All\n• **Real-time salary calculator** powered by Custom Metadata tax configuration (admin-updatable, no code changes)\n• **Interview scheduler** with calendar timeline, time suggestions, conflict detection, and upcoming/past event views\n• **Pipeline analytics** — Kanban board, status charts, interview rate tracking, and salary insights\n• **Automated triggers** — Follow-up tasks auto-created on new applications, platform events on status changes\n• **Modern UI** — Consistent gradient headers, lightning-icon components, responsive design across all pages\n• **In-app documentation** — This viewer provides reference guides accessible directly within the org'
                },
                {
                    heading: 'Application Workflow',
                    text: 'A typical job application flows through these stages:\n\n**Saved** → You found a posting worth applying for. Add it to track it.\n**Applying** → You are preparing your application (resume, cover letter).\n**Applied** → Application submitted. A follow-up task is auto-created.\n**Interviewing** → You have been contacted for interviews. Schedule them via the Interview Calendar.\n**Negotiating** → You received an offer and are discussing terms. Use the Salary Calculator to compare.\n**Accepted** → Congratulations! The offer is accepted.\n**Closed** → The application is no longer active (withdrew, rejected, or position filled).'
                }
            ]
        },
        {
            id: 'architecture',
            title: 'Architecture',
            icon: 'utility:builder',
            content: [
                {
                    heading: 'Trigger → Handler → Service Pattern',
                    text: 'The application strictly follows the **Trigger → Handler → Service** architecture, a Salesforce best practice for clean, testable, and maintainable code.\n\n**Trigger Layer** — One trigger per object, one line of code that delegates to its handler. Example: `JobApplicationTrigger` calls `JobApplicationTriggerHandler`. Triggers never contain business logic.\n\n**Handler Layer** — Determines which service methods to call based on trigger context (`before insert`, `after update`, etc.). The handler is the traffic controller, not the business logic owner.\n\n**Service Layer** — All domain logic lives in Service classes: `SalaryCalculationService`, `InterviewCalendarService`, `TaxConfigurationService`, `ApplicationAnalyticsService`, etc. Services use `inherited sharing` to inherit the caller\'s permissions.\n\n**LWC Layer** — Lightning Web Components call Apex services via `@wire` (for cacheable, read-only data) or imperative `@AuraEnabled` methods (for DML operations).'
                },
                {
                    heading: 'Platform Stack',
                    text: '• **Salesforce API Version:** 62.0 (Winter \'25) — updated from 58.0 across 79 metadata files\n• **Backend Language:** Apex with `inherited sharing` on all classes (56 classes standardized)\n• **Frontend Framework:** Lightning Web Components (14 components, no `@track` — reactive by default)\n• **Async Processing:** Batch Apex (`SalaryMarketAnalysisBatch`, `JobApplicationCleanupBatch`), Queueable (`EmailNotificationQueue`, `JobApplicationEnrichmentQueue`), and Schedulable classes\n• **Platform Events:** `Job_Application_Event__e` with publisher/subscriber pattern and failed event tracking\n• **External Integrations:** Named Credentials — `callout:Salary_Benchmark_API`, `callout:Company_Data_API`, `callout:Salary_Data_API`, `callout:Weather_API`\n• **Configuration:** `Tax_Configuration__mdt` Custom Metadata Type for admin-managed tax brackets\n• **Testing:** Apex test classes (95%+ coverage target) + Jest via sfdx-lwc-jest\n• **CI/CD:** GitHub Actions for scratch org deploy, test, and code scanning'
                },
                {
                    heading: 'Data Model',
                    text: '**Job_Application__c** — The core object with 29 fields: company details, application tracking, salary and tax calculations, market analysis, interview metrics, and notes. Supports validation rules, triggers, and multiple list views.\n\n**Interview_Feedback__c** — Feedback collection with competency ratings, linked to job applications via lookup.\n\n**Competency_Rating__c** — Individual skill ratings linked to feedback records.\n\n**Feedback_Template__c** — Configurable feedback form templates for standardized evaluations.\n\n**Feedback_Share__c** — Token-based feedback sharing with mentors or external reviewers.\n\n**Tax_Configuration__mdt** — Custom Metadata Type storing 2025 federal tax brackets, Social Security rate (6.2%), wage base ($176,100), and Medicare rate (1.45%). Admins update rates in Setup with zero code changes.\n\n**Job_Application_Event__e** — Platform Event fired on status changes, enabling real-time cross-feature notifications. Includes failed event tracking with replay ID support.'
                },
                {
                    heading: 'Security Architecture',
                    text: '• **Sharing Model:** All Apex service classes use `inherited sharing` — they inherit the calling context\'s sharing rules. Never `without sharing` unless explicitly justified.\n• **API Authentication:** All external API calls use Named Credentials (`callout:Name`). No API keys or endpoints are hard-coded in source. Credentials are managed in Setup and never enter version control.\n• **SOQL Injection Protection:** User-supplied query strings in `PerformanceOptimizationService` are validated with blank checks, 10,000-char length limits, and DML keyword sanitization.\n• **Field-Level Security:** Standard Salesforce FLS enforced through the platform. LWC components access data via `@wire` which respects the user\'s profile permissions.\n• **Input Validation:** Event scheduling validates business hours, weekend detection, past-date prevention, and time range logic before creating records.'
                }
            ]
        },
        {
            id: 'objects-fields',
            title: 'Objects & Fields',
            icon: 'utility:database',
            content: [
                {
                    heading: 'Job Application — Core Fields',
                    text: '• **Company_Name__c** (Text) — The company you are applying to\n• **Position_Title__c** (Text) — Job title or role name\n• **Status__c** (Picklist, Restricted) — Saved, Applying, Applied, Interviewing, Negotiating, Accepted, Closed\n• **Location__c** (Picklist, Restricted) — Remote, Hybrid, On-site\n• **Salary__c** (Currency) — Annual gross salary offered or expected\n• **Application_Date__c** (Date) — When the application was submitted\n• **Rating__c** (Picklist) — Priority rating from 1 (Low Interest) to 5 (Must Apply)\n• **Description__c** (Long Text Area) — Detailed job description and responsibilities\n• **Notes__c** (Long Text Area) — Personal notes about the opportunity\n• **Job_URL__c** (URL) — Link to the original job posting\n• **Follow_Up_Date__c** (Date) — Next action date (auto-suggested by list views)\n• **Primary_Contact__c** (Lookup to Contact) — Recruiter or hiring manager contact'
                },
                {
                    heading: 'Job Application — Salary & Tax Fields',
                    text: 'These fields are populated when you use the Salary Calculator and save to the record:\n\n• **Federal_Tax__c** (Currency) — Calculated federal income tax using progressive brackets\n• **Social_Security_Tax__c** (Currency) — 6.2% of salary up to the wage base ($176,100)\n• **Medicare_Tax__c** (Currency) — 1.45% of total wages\n• **Take_Home_Pay_Yearly__c** (Currency) — Annual net pay after all taxes\n• **Take_Home_Pay_Monthly__c** (Currency) — Monthly net pay (yearly / 12)'
                },
                {
                    heading: 'Job Application — Market & Interview Fields',
                    text: '**Market Analysis Fields** (populated via Salary Benchmark API):\n• **Market_Salary_Min__c** / **Market_Salary_Median__c** / **Market_Salary_Max__c** — External market salary benchmarks\n• **Salary_Competitiveness__c** — How your offer compares to market (percentage)\n• **Market_Analysis_Date__c** — When the benchmark was last pulled\n\n**Interview Tracking Fields:**\n• **Average_Interview_Rating__c** — Rolled up from Interview_Feedback__c records\n• **Total_Interview_Count__c** — Number of interviews conducted\n• **Last_Interview_Date__c** — Most recent interview date\n• **Interview_Success_Score__c** — Composite performance score\n• **Feedback_Summary__c** (Long Text Area) — Aggregated feedback notes'
                },
                {
                    heading: 'Supporting Objects',
                    text: '**Interview_Feedback__c** — Captures interview feedback with fields for interviewer name, date, overall rating (1-5), strengths, areas for improvement, recommendation (Hire/No Hire), and linked competency ratings.\n\n**Competency_Rating__c** — Child of Interview_Feedback__c. Stores individual skill scores: Technical Skills, Communication, Problem Solving, Culture Fit, Leadership, etc.\n\n**Feedback_Template__c** — Configurable templates defining which competencies to rate and what questions to ask.\n\n**Feedback_Share__c** — Token-based sharing. Generates a unique token allowing mentors or external parties to view specific feedback without a Salesforce login.\n\n**Tax_Configuration__mdt** — Custom Metadata with fields: `Standard_Deduction__c`, `Social_Security_Rate__c`, `Social_Security_Wage_Base__c`, `Medicare_Rate__c`, bracket threshold fields, and `Is_Active__c` toggle.'
                }
            ]
        },
        {
            id: 'list-views',
            title: 'List Views',
            icon: 'utility:filterList',
            content: [
                {
                    heading: 'Overview',
                    text: 'The app includes 10 pre-built list views that provide instant filtered access to your job applications. Each view is shared with all internal users and shows the most relevant columns for that context.'
                },
                {
                    heading: 'Action-Oriented Views',
                    text: '**Needs Follow-Up** — Applications where the follow-up date is today or earlier, excluding Closed status. This is your daily action list — what needs attention right now. Columns: Name, Company, Position, Status, Follow-Up Date, Application Date, Notes.\n\n**Interviewing** — All applications currently in interview stage. Sorted by Follow-Up Date first so upcoming interviews surface at the top. Columns include Notes for quick interview prep context.\n\n**Negotiating** — Active offers being negotiated. Shows Salary, Location, Follow-Up Date, and Notes so you can track where each negotiation stands.'
                },
                {
                    heading: 'Analysis Views',
                    text: '**Top Salary Opportunities** — All applications that have salary data, allowing you to compare compensation across opportunities. Includes Take_Home_Pay_Yearly column when populated by the Salary Calculator.\n\n**High Priority (4-5 Stars)** — Applications you rated 4 or 5 stars. These are your top-tier opportunities that deserve the most attention.\n\n**Remote Positions** — All Remote-only opportunities. Useful for filtering by work style preference.\n\n**Accepted Offers** — Applications with Accepted status showing salary, take-home pay (yearly and monthly), location, and notes. Your wins dashboard.'
                },
                {
                    heading: 'General Views',
                    text: '**All Job Applications** — Complete view of every record with key columns: Company, Position, Status, Application Date, Salary, Location, Rating, Last Modified.\n\n**Active Applications** — Everything except Closed status. Your current pipeline at a glance.\n\n**Recent Applications (Last 30 Days)** — Newest entries by creation date. Useful for tracking your recent application velocity.'
                }
            ]
        },
        {
            id: 'salary-calc',
            title: 'Salary Calculator',
            icon: 'utility:moneybag',
            content: [
                {
                    heading: 'How It Works',
                    text: 'The Salary Calculator provides real-time tax estimates using configurable tax brackets stored in **Custom Metadata** (`Tax_Configuration__mdt`). Enter any annual salary and instantly see your estimated take-home pay broken down by tax category and pay period.\n\nThe calculator operates in two modes:\n\n**Real-time (Client)** — Instant JavaScript calculations as you type. Tax config is loaded once via `@wire(getActiveTaxConfiguration)` and cached by the platform. Provides immediate feedback with zero server calls per keystroke. Input is debounced (300ms) to prevent excessive recalculations.\n\n**Precise (Server)** — Apex-based calculation via `SalaryCalculationService.calculateSalaryBreakdown()`. Uses server-side logic for edge cases and ensures consistency with any server-side triggers. Slightly slower but authoritative.'
                },
                {
                    heading: 'Tax Components Explained',
                    text: '**Federal Income Tax** — Uses progressive (marginal) brackets. Only the income within each bracket is taxed at that rate. The 2025 brackets are:\n• 10% on income up to $11,925\n• 12% on $11,925 – $48,475\n• 22% on $48,475 – $103,350\n• 24% on $103,350 – $197,300\n• 32% on $197,300 – $250,525\n• 35% on $250,525 – $626,350\n• 37% on income above $626,350\n\nA $15,000 standard deduction is applied before calculating federal tax.\n\n**Social Security Tax** — Flat 6.2% on wages up to the wage base of $176,100. Income above this amount is not subject to Social Security tax.\n\n**Medicare Tax** — Flat 1.45% on all wages with no cap.'
                },
                {
                    heading: 'Results Breakdown',
                    text: 'After entering a salary, you see two result sections:\n\n**Tax Deductions** — Four cards showing Federal Tax, Social Security, Medicare, and Total Taxes. Each displays the dollar amount and the effective percentage of gross salary.\n\n**Take-Home Pay** — Four cards showing your net pay in different frequencies: Per Year, Per Month, Bi-Weekly (÷ 26), and Per Week (÷ 52). The yearly amount is highlighted with a green accent as the primary figure.'
                },
                {
                    heading: 'Updating Tax Rates (Admin Guide)',
                    text: 'Tax rates are managed via Custom Metadata — no code deployment needed:\n\n1. Navigate to **Setup → Custom Metadata Types**\n2. Find **Tax Configuration** and click **Manage Records**\n3. Edit the active record (e.g., "Tax Year 2025") or create a new one\n4. Update bracket thresholds, rates, standard deduction, SS rate, and wage base\n5. Set **Is_Active__c** = true on the new config, false on the old one\n6. Changes take effect immediately — the LWC re-reads config on next page load\n\nThe JavaScript fallback constants in `salaryCalculator.js` serve as a safety net if the Apex wire call fails. They should be kept in sync with the latest CMDT record.'
                },
                {
                    heading: 'Save to Record',
                    text: 'When using the Salary Calculator from a job application record page, the "Save to Record" button writes calculated values back to the record fields: `Federal_Tax__c`, `Social_Security_Tax__c`, `Medicare_Tax__c`, `Take_Home_Pay_Yearly__c`, and `Take_Home_Pay_Monthly__c`. This allows comparison across applications via list views and reports.\n\nWhen using the calculator from the standalone Salary Calculator tab (App Page), the Save button is hidden since there is no record context.'
                }
            ]
        },
        {
            id: 'interview-calendar',
            title: 'Interview Calendar',
            icon: 'utility:event',
            content: [
                {
                    heading: 'Scheduling Interviews',
                    text: 'The Interview Calendar provides a complete scheduling workflow:\n\n1. **Subject** — Auto-populated with the job application context if opened from a record, or enter manually\n2. **Date & Time** — Select start and end times. End time auto-fills to 1 hour after start\n3. **Interview Type** — Choose from Phone Screen, Video Interview, Technical Interview, Panel Interview, Final Interview, or Informal Chat\n4. **Location/Platform** — Zoom, Microsoft Teams, Google Meet, Phone Call, Company Office, Coffee Shop, or Other\n5. **Notes** — Free-text field for preparation items, interviewer names, or special instructions\n\nThe scheduler creates standard Salesforce **Event** records, so interviews appear in your standard Salesforce calendar and can be synced to Outlook/Google via Salesforce integrations.'
                },
                {
                    heading: 'Quick Time Suggestions',
                    text: 'The component generates up to 8 time suggestions for the next 5 business days:\n• Morning slots at **10:00 AM** (1-hour block)\n• Afternoon slots at **2:00 PM** (1-hour block)\n\nWeekends are automatically skipped. Click any suggestion pill to instantly populate the start and end date/time fields.'
                },
                {
                    heading: 'Conflict Detection',
                    text: 'Click **Check Availability** before scheduling to detect potential conflicts with your existing calendar events. The system checks for overlapping time slots and displays any conflicts with their subject and time range.\n\n**Validation rules also enforce:**\n• End time must be after start time\n• Cannot schedule interviews in the past\n• Warnings for interviews outside business hours (8 AM – 6 PM)\n• Warnings for weekend scheduling'
                },
                {
                    heading: 'Interview Timeline',
                    text: 'Below the scheduling form, a live timeline shows your interviews:\n\n**Upcoming Tab** — All future events sorted by date. Cards show urgency:\n• **Red border** — Interview within 24 hours ("Starting soon", "Tomorrow")\n• **Amber border** — Interview within 3 days\n• Standard — More than 3 days away\n\nEach card displays the date, time range, subject, location, and relative time label.\n\n**Past Tab (30 days)** — Recent interviews displayed in a muted style for reference. Shows the same level of detail.\n\nThe timeline auto-refreshes after you schedule a new interview. Data is loaded via `InterviewCalendarService` Apex class using cacheable wire adapters.'
                }
            ]
        },
        {
            id: 'analytics',
            title: 'Analytics Dashboard',
            icon: 'utility:chart',
            content: [
                {
                    heading: 'Overview',
                    text: 'The Application Analytics dashboard provides real-time visual insights into your job search pipeline. All data is loaded via `ApplicationAnalyticsService` with pagination support (LIMIT/OFFSET) to handle large datasets without governor limit issues.'
                },
                {
                    heading: 'Summary Metrics',
                    text: 'Four metric cards at the top provide instant KPIs:\n\n• **Total Applications** — Count of all job application records\n• **Active Applications** — Applications not in Closed status\n• **Interview Rate** — Percentage of applications that reached Interviewing stage or beyond\n• **Success Rate** — Percentage of applications that reached Accepted status\n\nEach card has a color-coded gradient icon (blue, amber, purple, green) for quick visual identification.'
                },
                {
                    heading: 'Status Breakdown & Activity',
                    text: '**Status Breakdown Chart** — Horizontal bar chart showing the count of applications in each status (Saved, Applying, Applied, Interviewing, Negotiating, Accepted, Closed). Each bar is color-coded and shows a proportional fill width.\n\n**Recent Activity** — A timeline of the most recent changes to your applications, showing what changed, which application, and how long ago.'
                },
                {
                    heading: 'Pipeline & Salary Analysis',
                    text: '**Application Pipeline** — Kanban-style board with columns for each status stage. Each column shows its application count badge and lists the individual applications with company, position, and date. Click any application card to navigate to the record.\n\n**Salary Analysis** — Three metrics: Average Salary, Highest Offer, and Salary Range across all applications with salary data. Helps you understand your market positioning.\n\n**Export Data** — Button to export application data for offline analysis or reporting.'
                }
            ]
        },
        {
            id: 'triggers-automation',
            title: 'Triggers & Automation',
            icon: 'utility:flow',
            content: [
                {
                    heading: 'Job Application Trigger',
                    text: '**Trigger:** `JobApplicationTrigger` → **Handler:** `JobApplicationTriggerHandler`\n\n**After Insert:**\n• Auto-creates a follow-up Task linked to the new application\n• Task subject includes company name and position title\n• Due date set based on application status\n\n**After Update:**\n• Fires `Job_Application_Event__e` platform event on status changes\n• Event payload includes application ID, old status, new status, and timestamp'
                },
                {
                    heading: 'Platform Events',
                    text: '**Event:** `Job_Application_Event__e`\n\n**Publisher:** `JobApplicationEventPublisher` — fires events when job application status changes are detected in the trigger handler.\n\n**Subscriber:** `JobApplicationEventSubscriber` — listens for events and can trigger downstream actions (notifications, analytics updates, cross-feature workflows).\n\n**Error Handling:** Failed events are captured in a `FailedEventRecord` inner class with `jobApplicationId`, `eventType`, `errorMessage`, `replayId`, and `failedAt` fields. This enables monitoring and replay of failed events.'
                },
                {
                    heading: 'Batch & Scheduled Jobs',
                    text: '**SalaryMarketAnalysisBatch** — Batch job that calls the Salary Benchmark API for applications missing market data. Updates `Market_Salary_Min__c`, `Median__c`, `Max__c`, and `Salary_Competitiveness__c`.\n\n**JobApplicationCleanupBatch** — Removes or archives stale applications based on configurable criteria (e.g., Closed status older than 90 days).\n\n**FeedbackDataRetentionBatch** — Manages feedback data lifecycle per retention policies.\n\n**EmailNotificationQueue** (Queueable) — Sends email notifications asynchronously to avoid mixed DML issues.\n\n**JobApplicationEnrichmentQueue** (Queueable) — Enriches application data with company information from external APIs via Named Credentials.'
                }
            ]
        },
        {
            id: 'conventions',
            title: 'Code Conventions',
            icon: 'utility:rules',
            content: [
                {
                    heading: 'Apex Conventions',
                    text: '• **Sharing keyword:** Always use `inherited sharing` — never omit the sharing keyword. This ensures classes inherit the caller\'s sharing context (secure by default, flexible when needed).\n• **Service classes:** Named `ClassNameService.cls`. Contain all business logic.\n• **Test classes:** Named `ClassNameTest.cls`. Use `@TestSetup` for shared data and `TestDataFactory` for record creation.\n• **API authentication:** All external calls use Named Credentials (`callout:Name`). Never hard-code API keys, endpoints, or tokens.\n• **Code coverage target:** 95%+ per class. Use `sf apex run test --code-coverage` to verify.\n• **Bulk-safe patterns:** All trigger handlers and services process `List<SObject>` to handle bulk operations. No SOQL/DML inside loops.'
                },
                {
                    heading: 'LWC Conventions',
                    text: '• **No `@track` decorator:** Properties are reactive by default since API 48.0. Only use `@track` for deep object mutation tracking (rare).\n• **UI pattern:** Feature pages use a custom `div` container with gradient `page-header` (navy gradient) + `lightning-icon` components. No emoji icons in production UI.\n• **Import style:** Use `@salesforce/schema` imports for field references. Use `@salesforce/apex` for server calls.\n• **Error handling:** Display errors inline using `c-error-panel` or styled error banners. Never silently catch errors.\n• **Test location:** Jest test files live in `__tests__/` inside each component folder.\n• **Meta.xml targets:** AppPage components must include `<target>lightning__AppPage</target>` in their meta.xml.'
                },
                {
                    heading: 'Git & Deployment Conventions',
                    text: '• **Commit prefixes:** `feat:` (features), `fix:` (bug fixes), `chore:` (maintenance), `docs:` (documentation), `refactor:` (code restructuring)\n• **Branch strategy:** Feature branches merged via pull request\n• **Deployment order:** CMDT → Apex → LWC → Objects/Triggers. Deploy in dependency order to avoid compilation errors.\n• **Pre-existing issues:** Some components have known compilation errors (documented in CLAUDE.md). The `quick-deploy.ps1` script handles dependency ordering and skips problem components.\n• **FlexiPage activation:** After deploying FlexiPages, they must be manually activated via Setup → Lightning App Builder → Component → Activation → Activate for all users.'
                }
            ]
        },
        {
            id: 'admin-guide',
            title: 'Admin Guide',
            icon: 'utility:settings',
            content: [
                {
                    heading: 'Managing Tax Configuration',
                    text: 'Tax brackets are stored in **Tax_Configuration__mdt** (Custom Metadata Type).\n\n**To update tax rates:**\n1. Setup → Custom Metadata Types → Tax Configuration → Manage Records\n2. Clone or edit the active record\n3. Update bracket thresholds and rates\n4. Set `Is_Active__c` = true; deactivate old records\n5. No deployment needed — changes are live immediately\n\n**Fields:** Standard_Deduction__c, Social_Security_Rate__c, Social_Security_Wage_Base__c, Medicare_Rate__c, bracket threshold/rate pairs, Is_Active__c, Tax_Year__c'
                },
                {
                    heading: 'Named Credentials Setup',
                    text: 'External API integrations use Named Credentials for secure authentication:\n\n• **Salary_Benchmark_API** — Used by `SalaryBenchmarkService` for market salary data\n• **Company_Data_API** — Used by `CompanyDataService` for company enrichment\n• **Salary_Data_API** — Used by `SalaryDataAPIService` for additional salary sources\n• **Weather_API** — Used by `WeatherAPIService` for interview day weather info\n\n**To configure:** Setup → Named Credentials → New/Edit. Set the endpoint URL, authentication protocol (OAuth 2.0 or API Key), and credentials. The Apex code references them as `callout:Credential_Name`.'
                },
                {
                    heading: 'App & Tab Management',
                    text: '**Lightning App:** "Job Application Tracker" — configured in Setup → App Manager\n\n**Tabs (6 total):**\n1. Job Tracker Home — Landing page with hero section and KPIs\n2. Job Applications — Standard object tab with list views\n3. Application Analytics — Pipeline analytics and Kanban board\n4. Salary Calculator — Tax breakdown calculator\n5. Interview Calendar — Scheduling with timeline\n6. Documentation — This viewer\n\n**Tab Visibility:** Managed via Profile → Tab Visibility. All custom tabs are set to "Default On" for System Administrator.\n\n**FlexiPage Activation:** Each tab\'s App Page must be activated in Setup → Lightning App Builder. Deploy does not auto-activate.'
                },
                {
                    heading: 'Data Management',
                    text: '**Picklist Values (Restricted):**\n• **Status__c:** Saved, Applying, Applied, Interviewing, Negotiating, Accepted, Closed\n• **Location__c:** Remote, Hybrid, On-site\n• **Rating__c:** 1 (Low Interest), 2 (Some Interest), 3 (Moderate), 4 (Strong Interest), 5 (Must Apply)\n\nThese picklists are restricted — values cannot be added via the UI without admin modification.\n\n**Bulk Data Operations:** Use the scripts in the `scripts/apex/` folder for data seeding, cleanup, and field population. Key scripts:\n• `seed-more-applications.apex` — Add showcase records\n• `populate-missing-fields.apex` — Fill empty fields\n• `clean-and-seed-data.apex` — Full reset with fresh data'
                }
            ]
        },
        {
            id: 'team',
            title: 'Team & History',
            icon: 'utility:people',
            content: [
                {
                    heading: 'Project Team',
                    text: 'This application is a capstone project for **Cloud Code Academy**, built by:\n\n• **Temitayo** (Taju) — Lead Developer\n• **Mark** — Developer\n• **Mike** — Developer\n\n**Academy:** Cloud Code Academy\n**Platform:** Salesforce (API v62.0 / Winter \'25)\n**Org:** myCapstoneOrg (capstone@taju.com)'
                },
                {
                    heading: 'Phase 1 — Codebase Modernization',
                    text: '• Upgraded API version from 58.0 to 62.0 across 79 metadata files\n• Removed `@track` from 60 properties across 10 LWCs\n• Added `inherited sharing` to 56 Apex classes\n• Replaced hard-coded API keys with Named Credentials\n• Moved tax configuration to Custom Metadata Type (Tax_Configuration__mdt)\n• Added SOQL injection protection to PerformanceOptimizationService\n• Created reusable `c-error-panel` LWC for inline error display\n• Added platform event error handling with replay support\n• Added 3 Jest test suites for LWC components\n• Implemented dashboard pagination with LIMIT/OFFSET\n• Added WCAG accessibility (aria-live, keyboard nav, semantic roles)\n• Reorganized 20+ docs into guides/reference/project structure\n• Created 22 missing .cls-meta.xml files\n• Fixed xmlns typo in CMDT field metadata'
                },
                {
                    heading: 'Phase 2 — App Polish & UI Redesign',
                    text: '• Built Job Tracker Home page with hero section, animated counters, and pipeline visualization\n• Created 4 App Pages (FlexiPages) with custom tabs and profile visibility\n• Cleaned org data from 293 test records to 20 realistic showcase records\n• Removed 6 unrelated standard tabs (Contact, Account, Task, Event, Report, Dashboard)\n• Redesigned Analytics Dashboard, Salary Calculator, and Interview Calendar with modern UI\n• Applied consistent gradient page headers and lightning-icon components across all feature pages'
                },
                {
                    heading: 'Phase 3 — Data, Calendar & Documentation',
                    text: '• Expanded to 50+ job applications with full field data (descriptions, URLs, ratings, follow-ups)\n• Created 5 new list views: Negotiating, Top Salary, Needs Follow-Up, Remote Positions, Accepted Offers\n• Added interview calendar timeline with upcoming/past event views and urgency indicators\n• Built InterviewCalendarService Apex class for event queries\n• Created this Documentation Viewer LWC with sidebar navigation and rich formatting\n• Populated missing fields across all records (Description, Job URL, Rating, Follow-Up Date, Application Date)'
                }
            ]
        }
    ];

    get activeSections() {
        return this.sections.map(s => ({
            ...s,
            isActive: s.id === this.activeSectionId,
            navClass: 'nav-item' + (s.id === this.activeSectionId ? ' active' : ''),
            formattedContent: s.content.map((block, idx) => ({
                ...block,
                key: s.id + '-' + idx,
                paragraphs: this.parseText(block.text)
            }))
        }));
    }

    get activeContent() {
        return this.activeSections.find(s => s.isActive);
    }

    get navItems() {
        return this.activeSections;
    }

    handleNavClick(event) {
        this.activeSectionId = event.currentTarget.dataset.id;
    }

    parseText(text) {
        if (!text) return [];
        return text.split('\n').filter(line => line.trim() !== '').map((line, idx) => {
            const isBullet = line.trim().startsWith('•') || line.trim().startsWith('-');
            const isNumbered = /^\d+\./.test(line.trim());
            let cssClass = 'doc-line';
            if (isBullet) cssClass += ' doc-bullet';
            if (isNumbered) cssClass += ' doc-numbered';
            // Bold text handling: replace **text** with styled spans
            const formatted = line.replace(/\*\*(.*?)\*\*/g, '<b>$1</b>');
            // Backtick handling: replace `text` with code spans
            const withCode = formatted.replace(/`(.*?)`/g, '<code>$1</code>');
            return { key: 'p-' + idx, text: withCode, cssClass };
        });
    }
}
