# Project Context

Enterprise Job Application Tracker — a Salesforce capstone project built by Temitayo, Mark, and Mike for Cloud Code Academy.

## Tech Stack

- **Platform:** Salesforce (API v62.0 / Winter '25)
- **Backend:** Apex (trigger-handler-service pattern)
- **Frontend:** Lightning Web Components (12 components)
- **Testing:** Apex test classes + Jest (sfdx-lwc-jest)
- **CI/CD:** GitHub Actions (scratch org deploy + test + scan)
- **Source format:** SFDX project, single `force-app` package directory

## Architecture

```
Trigger → TriggerHandler → Service classes → LWC (via @AuraEnabled/@wire)
```

- **Triggers:** `JobApplicationTrigger`, `InterviewFeedbackTrigger`, `EventValidationTrigger`
- **Handlers:** `JobApplicationTriggerHandler`, `JobApplicationEventTriggerHandler`
- **Services:** Domain logic in `*Service.cls` classes (e.g., `SalaryCalculationService`, `InterviewFeedbackService`, `FeedbackAnalyticsService`)
- **Async:** Batch (`SalaryMarketAnalysisBatch`, `JobApplicationCleanupBatch`, `FeedbackDataRetentionBatch`), Queueable (`EmailNotificationQueue`, `JobApplicationEnrichmentQueue`), Schedulable
- **Platform Events:** `Job_Application_Event__e` with publisher/subscriber pattern
- **External APIs:** `SalaryBenchmarkService`, `CompanyDataService`, `SalaryDataAPIService`, `WeatherAPIService` (use Named Credentials: `callout:Salary_Benchmark_API`, `callout:Company_Data_API`, `callout:Salary_Data_API`, `callout:Weather_API`)

## Key Custom Objects

| Object | Type | Purpose |
|--------|------|---------|
| `Job_Application__c` | Custom Object | Core tracker — 25+ fields, validation rules, list views |
| `Interview_Feedback__c` | Custom Object | Feedback collection with ratings and competency tracking |
| `Competency_Rating__c` | Custom Object | Individual skill ratings linked to feedback |
| `Feedback_Template__c` | Custom Object | Configurable feedback form templates |
| `Feedback_Share__c` | Custom Object | Token-based feedback sharing with mentors |
| `Job_Application_Event__e` | Platform Event | Async notifications for status changes |
| `Tax_Configuration__mdt` | Custom Metadata Type | Admin-managed tax brackets (no-code updates) |

## LWC Components

| Component | Purpose |
|-----------|---------|
| `jobApplicationDashboard` | Main dashboard with metrics and application list |
| `salaryCalculator` | Interactive salary/tax calculator (wired to TaxConfigurationService) |
| `calendarIntegration` | Interview scheduling with conflict detection |
| `interviewFeedbackCollector` | Feedback entry form with competency ratings |
| `mobileFeedbackCapture` | Mobile-optimized feedback capture |
| `performanceDashboard` | Chart.js analytics dashboard |
| `errorPanel` | Reusable error display with retry capability |
| `securityGovernanceDashboard` | Compliance monitoring dashboard |
| `applicationAnalyticsDashboard` | Application pipeline analytics |
| `executiveKpiDashboard` | Executive KPI summary |
| `integrationDeploymentDashboard` | Deployment status monitor |
| `performanceOptimizationDashboard` | Performance metrics viewer |

## Commands

```bash
# Deploy to default org
sf project deploy start --source-dir force-app --target-org myCapstoneOrg

# Run all Apex tests
sf apex run test --target-org myCapstoneOrg --code-coverage --result-format human

# Run LWC Jest tests
npm run test:unit

# Lint
npm run lint

# Open org
sf org open --target-org myCapstoneOrg
```

## Connected Orgs

- **DevHub:** `cloud-code-academy` (samuel.* username)
- **Default Org:** `myCapstoneOrg` (capstone@taju.com)
- **Scratch Org:** `cloud-code-scratch` (expires periodically)

## Known Pre-Existing Issues

These exist in the codebase but are NOT regressions from recent work:

- `Job_Application_Workflow.flow-meta.xml` — duplicate `actionCalls` element (XML parse error)
- `Job_Application_Manager.permissionset-meta.xml` — references required field incorrectly
- `jobApplicationDashboard.html` — inline ternary syntax not supported by LWC compiler on server
- Several Apex classes have compilation errors: `AutomatedReportService`, `CompanyDataServiceTest`, `JobApplicationCleanupBatch`, `JobApplicationEnrichmentQueue`

## Documentation

```
docs/
├── README.md                          # Documentation index
├── PROJECT_DOCUMENTATION_NAVIGATOR.md # Use-case navigation
├── guides/                            # Learning & development
├── reference/                         # Technical specs (API, architecture, data dictionary)
└── project/                           # Admin guide, deployment checklist, requirements
```

See `MODERNIZATION_CHANGELOG.md` at root for the full history of recent upgrades.

## Conventions

- **Sharing:** All service classes use `inherited sharing` (inherits caller's sharing context)
- **API auth:** Named Credentials only — never hard-code API keys
- **LWC reactivity:** No `@track` on properties (reactive by default since API 48.0)
- **Testing:** Test classes follow `*Test.cls` naming; use `TestDataFactory` for test data
- **Tax config:** Managed via `Tax_Configuration__mdt` — not hard-coded
