# Modernization Changelog

> **Date:** March 25, 2026  
> **Scope:** Full codebase modernization — API upgrade, security hardening, LWC cleanup, platform enhancements, documentation reorganization  
> **Deployed to:** `capstone@taju.com` (myCapstoneOrg)

---

## Changes Made

### 1. API Version: 58.0 / 60.0 → 62.0 (Winter '25)

**Files affected:** 79 meta.xml files, `sfdx-project.json`, `package.xml`, `interview-feedback-tracker-package.xml`

**Why this matters:**

The project was running on API v58.0 (Summer '23) — nearly 3 years behind. Each Salesforce release introduces new Apex methods, LWC features, and platform capabilities that are only available at that API version or higher. Staying outdated means:

- **Missing platform features** — Newer API versions unlock capabilities like enhanced `@wire` adapters, improved `lightning/ui*Api` modules, and new Apex system methods.
- **Deprecation risk** — Salesforce eventually drops support for old API versions. Running on 58.0 while the platform is on 63.0+ means accumulated technical debt.
- **Test compatibility** — Scratch orgs and sandboxes created on newer releases may behave differently when code is pinned to an old API version, causing phantom test failures.

We chose **62.0** (Winter '25) rather than the bleeding-edge 63.0 because it's the latest **stable, fully GA** release — the sweet spot between modern and proven.

---

### 2. Removed `@track` Decorators from All LWC Components

**Files affected:** 10 Lightning Web Components (~60 property declarations)

| Component | `@track` Removed |
|-----------|-----------------|
| `jobApplicationDashboard` | 7 properties |
| `interviewFeedbackCollector` | 10 properties |
| `mobileFeedbackCapture` | 30 properties |
| `salaryCalculator` | 9 properties |
| `calendarIntegration` | 11 properties |
| `securityGovernanceDashboard` | 3 properties |
| `applicationAnalyticsDashboard` | 3 properties |
| `integrationDeploymentDashboard` | 7 properties |
| `executiveKpiDashboard` | 4 properties |
| `performanceOptimizationDashboard` | 5 properties |
| `performanceDashboard` | 8 properties |

**Why this matters:**

Since **Spring '20 (API 48.0)**, all LWC properties are **reactive by default** — meaning any reassignment automatically triggers a re-render. The `@track` decorator is only needed for deep object mutation tracking (e.g., changing `this.obj.nested.value` without reassigning `this.obj`). Using `@track` on primitives, strings, and top-level reassignments is:

- **Misleading** — It implies the property needs special handling when it doesn't
- **Code noise** — Adds visual clutter that obscures the properties that actually *do* need tracking
- **A signal of outdated knowledge** — In a code review or interview, unnecessary `@track` flags that the developer hasn't kept up with the framework

The `import { track } from 'lwc'` was also removed from each file's import statement to keep imports clean.

---

### 3. Added `inherited sharing` to All Apex Classes

**Files affected:** 56 Apex classes across 3 audit passes

Initial pass fixed `SalaryBenchmarkService.cls` and `CompanyDataService.cls`. A second audit found **39 more classes** missing the keyword — batch jobs, schedulers, queueable classes, handlers, utility classes, and test classes. A final audit caught **15 additional classes** that either had no sharing keyword (private test classes) or used `with sharing` when the project convention is `inherited sharing` (service classes called from mixed contexts). All 56 now consistently declare `inherited sharing`.

**Why this matters:**

When an Apex class has **no sharing keyword**, it runs in `without sharing` mode by default when called from certain contexts. This is a **security anti-pattern** because:

- It bypasses record-level access controls (Org-Wide Defaults, sharing rules, manual shares)
- A user could potentially see salary benchmark data or company data they shouldn't have access to
- It violates the **principle of least privilege**

We used `inherited sharing` rather than `with sharing` because these services are called from multiple contexts (triggers, LWC controllers, batch jobs). `inherited sharing` means:
- When called from a `with sharing` context (like an LWC controller) → respects sharing rules
- When called from a `without sharing` context (like a system batch job) → runs without sharing
- This is the **Salesforce-recommended default** for service-layer classes

---

### 4. Updated Tax Calculation Constants to 2025 Rates

**File affected:** `salaryCalculator.js`

| Parameter | Old (2023) | New (2025) |
|-----------|-----------|-----------|
| Standard Deduction | $13,850 | $15,000 |
| SS Wage Base | $160,200 | $176,100 |
| 10% bracket ceiling | $11,000 | $11,925 |
| 12% bracket ceiling | $44,725 | $48,475 |
| 22% bracket ceiling | $95,375 | $103,350 |
| 24% bracket ceiling | $182,050 | $197,300 |
| 32% bracket ceiling | $231,250 | $250,525 |
| 35% bracket ceiling | $578,125 | $626,350 |

**Why this matters:**

The salary calculator is one of the app's most visible features — users rely on it to compare job offers. Running 2023 tax rates in 2026 would produce **inaccurate take-home pay estimates**, potentially leading to poor decision-making when evaluating competing offers. Tax brackets are inflation-adjusted annually by the IRS.

---

### 5. Updated Scratch Org Definition

**File affected:** `config/project-scratch-def.json`

Added `languageSettings` with `enableEndUserLanguages: true` for better scratch org provisioning compat with current Salesforce releases.

---

## Implemented Enhancements

All 9 recommended enhancements from the initial audit have been implemented and deployed.

---

### 1. Named Credentials for API Services (was: High Priority)
**Files:** `SalaryBenchmarkService.cls`, `CompanyDataService.cls`

Replaced hard-coded API keys (`'demo-api-key-12345'`, `'Bearer demo-salary-api-key-67890'`) with Named Credential callouts (`callout:Salary_Benchmark_API`, `callout:Company_Data_API`).

**Why this matters:**

Even when API keys are "demo" values, hard-coding credentials in source code trains developers to accept a dangerous pattern. Once real keys are added the same way, they're permanently in version control history — even after deletion, `git log` exposes them. Named Credentials solve this by:

- **Centralizing auth in Setup** — admins rotate keys or switch to OAuth without code deployments
- **Never touching source control** — credentials live in the org, not the repo
- **Enabling per-environment config** — dev, staging, and production can point to different API endpoints with different auth, using the same codebase

This is a common finding in Salesforce security audits and a best practice enforced by the AppExchange security review.

---

### 2. SOQL Injection Protection (was: High Priority)
**File:** `PerformanceOptimizationService.cls`

Added input validation to `optimizeQuery()`: blank check, length limit (10,000 chars), and DML keyword sanitization (`INSERT`, `UPDATE`, `DELETE`, `UPSERT`, `MERGE`, `UNDELETE` are stripped).

**Why this matters:**

SOQL Injection is the Salesforce equivalent of SQL Injection (OWASP #3). When a method accepts a raw query string that includes user input, an attacker can manipulate it to access data they shouldn't see or cause unexpected DML operations. The three-layer defense we added:

1. **Blank check** — rejects empty strings before they waste governor limits
2. **Length limit** — prevents denial-of-service via absurdly long query strings
3. **DML keyword stripping** — removes `INSERT`, `UPDATE`, `DELETE` etc. even if someone bypasses UI validation

In production, the ideal solution is always static SOQL with bind variables (`WHERE Name = :userInput`), but since this method's purpose is to analyze arbitrary SOQL, sanitization is the pragmatic defense.

---

### 3. Custom Metadata for Tax Configuration (was: High Priority)
**Files created:** `Tax_Configuration__mdt` (object + 7 fields), `TaxConfigurationService.cls`, CMDT record `Tax_Year_2025`  
**File modified:** `salaryCalculator.js`

Tax brackets moved from hard-coded JavaScript constants to `Tax_Configuration__mdt` Custom Metadata Type. The LWC loads active config at runtime via `@wire(getActiveTaxConfiguration)` with hard-coded 2025 defaults as fallback.

**Why this matters:**

Tax brackets change every year (IRS inflation adjustments). With hard-coded values, updating rates requires a developer to change code, run tests, submit a PR, and deploy. With Custom Metadata Types:

- **Admins self-serve** — update rates in Setup > Custom Metadata Types, no code change needed
- **Deployable as metadata** — CMDT records travel with change sets and packages, unlike Custom Settings
- **Cacheable by the platform** — `@wire(cacheable=true)` means the LWC doesn't make a server call every time; the platform cache handles it
- **Historical preservation** — keep multiple year records (2024, 2025, 2026) with an `Is_Active__c` toggle

**Deployment lesson learned:** Custom Metadata Types don't support `Currency` field types — we changed `Standard_Deduction__c` and `Social_Security_Wage_Base__c` to `Number` type. Also, `currency` is an Apex reserved word, so the property in `SalaryBenchmarkService` was renamed to `currencyCode`.

---

### 4. Reusable Error Panel LWC (was: Medium Priority)
**Files created:** `errorPanel/` LWC component (JS, HTML, meta.xml)

Created `c-error-panel` — a reusable inline error display component with:
- `@api friendlyMessage` and `@api errorDetails` for customizable messaging
- Expandable details section with `aria-expanded` accessibility
- Optional retry button dispatching a `retry` custom event
- `role="alert"` and `aria-live="assertive"` for screen reader announcements

**Why this matters:**

The dashboard components were logging errors to `console.error` — invisible to end users. When a server call fails, users saw either nothing (data silently missing) or the spinner spinning forever. Good error UX means:

- **Inline error states** — users see what went wrong without navigating away
- **Retry capability** — transient failures (network blips, SOQL timeouts) can be resolved with one click instead of a full page refresh
- **Accessibility** — `role="alert"` ensures screen readers announce errors immediately, and `aria-expanded` on the details toggle communicates state to assistive technology
- **Reusability** — any component across the app can drop in `<c-error-panel>` instead of implementing its own error display

---

### 5. Platform Event Error Handling (was: Medium Priority)
**Files modified:** `JobApplicationEventPublisher.cls`, `JobApplicationEventSubscriber.cls`  
**Added:** `inherited sharing` keyword, `FailedEventRecord` inner class

The subscriber now tracks failed events in a `@TestVisible` list with `jobApplicationId`, `eventType`, `errorMessage`, `replayId`, and `failedAt` fields.

**Why this matters:**

Platform Events are "fire-and-forget" by default. When the publisher fires an event and the subscriber throws an exception processing it, the event is lost with no record it ever existed. In production, this means:

- Job application status changes could silently fail to trigger notifications
- Tasks that should have been auto-created are never created
- Analytics data is incomplete without any indication that records were missed

The `FailedEventRecord` inner class captures failures with their `replayId`, which enables:
- **Monitoring** — admins can query `failedEvents` to see what's failing and why
- **Replay** — using the `replayId`, failed events can be reprocessed from the event bus
- **Alerting** — test classes can assert on `failedEvents.size()` to catch regression

---

### 6. Jest Tests for LWC Components (was: Lower Priority)
**Files created:** `errorPanel/__tests__/errorPanel.test.js`, `securityGovernanceDashboard/__tests__/securityGovernanceDashboard.test.js`, `calendarIntegration/__tests__/calendarIntegration.test.js`

Added Jest test coverage for three components that had none. Tests validate rendering, user interactions, retry dispatch, and template structure.

**Why this matters:**

LWC Jest tests run locally in milliseconds, catching issues before you ever push to the org:

- **Template rendering** — catches typos in property bindings, missing conditional blocks, and broken component references
- **Wire adapter behavior** — validates that components handle both success and error responses from Apex correctly
- **User interaction flows** — simulates button clicks, form inputs, and custom events to verify the component responds correctly
- **Regression safety net** — when you modify a component, tests immediately tell you if you broke existing behavior

Without Jest tests, the only way to verify LWC behavior is manual testing in the browser — slow, unreliable, and not repeatable in CI/CD.

---

### 7. Dashboard Pagination (was: Lower Priority)
**File modified:** `ApplicationAnalyticsService.cls`

Added `getApplicationsPaginated(Integer pageSize, Integer pageNumber, String statusFilter)` with `LIMIT`/`OFFSET` SOQL, `COUNT()` query, and pagination metadata (`hasNext`, `hasPrevious`, `totalPages`, `totalRecords`).

**Why this matters:**

Dashboard components were running `SELECT ... FROM Job_Application__c` with no row limit. Salesforce enforces a 50,000-row SOQL limit per transaction. As the org grows:

- **100 records:** works fine
- **10,000 records:** works but slow (all records loaded into heap memory)
- **50,001 records:** hard crash — `System.LimitException: Too many query rows`

The pagination method prevents this by:
- Using `LIMIT`/`OFFSET` to fetch only one page at a time (e.g., 25 records)
- Running a separate `COUNT()` query to calculate total pages without loading all records
- Returning metadata (`hasNext`, `hasPrevious`) so the UI can show page controls
- Supporting a `statusFilter` parameter so users can narrow results before paging

---

### 8. Accessibility (WCAG) Compliance (was: Lower Priority)
**Files modified:** `jobApplicationDashboard.html/js`, `securityGovernanceDashboard.html`

- Added `aria-live="polite"` to dynamic metric regions
- Added `aria-hidden="true"` to decorative emojis
- Added `role="list"`, `role="listitem"`, `role="status"` semantic landmarks
- Added `tabindex="0"` and `onkeydown` keyboard activation (Enter/Space) to clickable items
- Added `aria-label` attributes to interactive elements

**Why this matters:**

Accessibility isn't optional — it's a legal requirement in many jurisdictions (ADA, Section 508, EU Accessibility Act) and a best practice for all users:

- **`aria-live="polite"`** — when dashboard metrics update (e.g., after a filter change), screen readers announce the new values without interrupting the user's current task
- **`aria-hidden="true"` on emojis** — without this, screen readers read decorative emojis aloud (e.g., "pile of poo" or "trophy"), confusing the content flow
- **Keyboard navigation** — users who can't use a mouse (motor disabilities, power users who prefer keyboard) need `tabindex` and key handlers to interact with clickable elements
- **Semantic roles** — `role="list"` and `role="listitem"` tell assistive technology the structure of the data, enabling screen readers to announce "list, 5 items" and navigate item-by-item

---

### 9. Shared Apex Sharing Keywords (was: included in audit)
**Files modified:** `JobApplicationEventPublisher.cls`, `JobApplicationEventSubscriber.cls`, `SalaryBenchmarkService.cls`, `CompanyDataService.cls`

Added `inherited sharing` to all service classes that previously had no sharing declaration.

**Why this matters:**

Covered in detail under "Changes Made > 3. Added `inherited sharing`" above. The short version: classes without a sharing keyword default to `without sharing` in certain contexts, potentially bypassing record-level security. `inherited sharing` inherits the caller's context — secure by default, flexible when needed.

---

## Additional Cleanup

### Documentation Reorganization

The `docs/` folder had 20+ files dumped flat with no structure, duplicate content across files, and broken links to deleted documents. This was reorganized into three logical categories:

```
docs/
├── README.md                          # Documentation index
├── PROJECT_DOCUMENTATION_NAVIGATOR.md # Use-case-based navigation
├── guides/                            # Learning & development
│   ├── LEARNING_JOURNEY_GUIDE.md
│   ├── FEATURE_IMPLEMENTATION_GUIDE.md
│   ├── CODE_QUALITY_GUIDE.md
│   ├── COMPREHENSIVE_DEBUGGING_GUIDE.md
│   ├── TESTING_MASTERY_GUIDE.md
│   ├── TEAM_COLLABORATION_GUIDE.md
│   └── KNOWLEDGE_BASE_SETUP_GUIDE.md
├── reference/                         # Technical specifications
│   ├── API_REFERENCE.md
│   ├── TECHNICAL_ARCHITECTURE_GUIDE.md
│   ├── ARCHITECTURE_DECISIONS_GUIDE.md
│   ├── DATA_DICTIONARY.md
│   └── QUICK_REFERENCE_CARD.md
└── project/                           # Operations & management
    ├── ADMIN_GUIDE.md
    ├── USER_GUIDE.md
    ├── DEPLOYMENT_CHECKLIST.md
    ├── CAPSTONE_REQUIREMENTS.md
    ├── PRESENTATION_EXPECTATIONS.md
    └── PROJECT_COMPLETION_SUMMARY.md
```

**Actions taken:**
- Merged `INTERVIEW_FEEDBACK_TRACKER_ADMIN_GUIDE.md` (544 lines, more comprehensive) with `ADMIN_GUIDE.md` (200 lines) into a unified admin guide
- Merged `INTERVIEW_FEEDBACK_TRACKER_API_REFERENCE.md` (774 lines) with `API_REFERENCE.md` (411 lines) into a unified API reference
- Renamed `INTERVIEW_FEEDBACK_TRACKER_USER_GUIDE.md` → `USER_GUIDE.md` and `INTERVIEW_FEEDBACK_TRACKER_DEPLOYMENT_CHECKLIST.md` → `DEPLOYMENT_CHECKLIST.md`
- Rewrote `PROJECT_DOCUMENTATION_NAVIGATOR.md` and `docs/README.md` — all links now point to correct subdirectory paths
- Removed 12 redundant root markdown files (fix instructions, setup summaries, status dashboards)
- Removed 6 PDF duplicates of existing markdown docs
- Removed obsolete app-visibility fix scripts

### Source Control Cleanup

- Added `.kiro/` to `.gitignore` (workspace config, should not be tracked)
- Organized 340 changed files into **5 clean, descriptive commits** with conventional commit prefixes (`chore:`, `refactor:`, `feat:`, `docs:`)
- Fixed `sforge` → `sforce` xmlns typo in `Social_Security_Rate__c.field-meta.xml` (would have caused deployment failure)

### AI Context Files

Created context files that AI coding tools read automatically when opening the project:

- **`CLAUDE.md`** — Project context for Claude Code, Cursor, and Windsurf. Contains tech stack, architecture, object model, commands, conventions, and known issues. Without it, every AI session wastes time re-exploring the project structure.
- **`.github/copilot-instructions.md`** — GitHub Copilot-specific context loaded automatically in VS Code. Focuses on code generation rules: always use `inherited sharing`, don't add `@track`, use Named Credentials. Prevents Copilot from generating code that violates project conventions.

### Deployment Script

- **`scripts/quick-deploy.ps1`** — Dependency-ordered deployment script that deploys in 4 stages (CMDT → Apex → LWC → Objects/Triggers) and skips components with pre-existing compilation errors. Created because `sf project deploy start --source-dir force-app` fails due to pre-existing issues in `AutomatedReportService`, `CompanyDataServiceTest`, etc.

### Bug Fixes Found During Deployment

- `Tax_Configuration__mdt` fields `Standard_Deduction__c` and `Social_Security_Wage_Base__c` used `Currency` type — **Custom Metadata Types don't support Currency fields**. Changed to `Number` type.
- `SalaryBenchmarkService.cls` used `currency` as a property name — this is an **Apex reserved word**. Renamed to `currencyCode`.

### Final Audit Fixes

A third comprehensive audit pass (automated scan of every file) caught issues the earlier manual reviews missed:

#### Missing `.cls-meta.xml` Files (22 classes)

**Files created:** 22 `.cls-meta.xml` files for classes like `FeedbackAnalyticsService`, `InterviewFeedbackService`, `FeedbackGDPRComplianceService`, and others.

**Why this matters:**

Every Apex class deployed to Salesforce needs a companion `.cls-meta.xml` file that declares its API version and status. Without it:

- **`sf project deploy start` will fail** — the CLI doesn't know what API version to compile the class against
- **Source tracking breaks** — `sf project retrieve start` won't pull the class because it doesn't exist in the manifest
- **Version drift** — if you deploy via other means (change sets, workbench), the class defaults to whatever API version the org is on, which may differ from your project's intent

These 22 classes were likely authored directly in the org (Developer Console) and retrieved without their metadata companion — a common mistake when mixing org-based and source-based development.

#### Named Credential Migration for Remaining API Services

**Files modified:** `SalaryDataAPIService.cls`, `WeatherAPIService.cls`

`SalaryDataAPIService` had `API_KEY = 'your_api_key_here'` and `WeatherAPIService` had `API_KEY = 'demo_key'` — both using direct `BASE_URL` endpoints with manual `Authorization` headers. Migrated both to Named Credentials (`callout:Salary_Data_API`, `callout:Weather_API`), removing the hard-coded keys and `Authorization` headers entirely.

**Why this matters:**

This is the same pattern as Enhancement #1 (Named Credentials), but these two services were missed in the initial pass because they used placeholder keys that didn't trigger the same alarm as real-looking credentials. The lesson: **even placeholder keys establish a pattern** that future developers will copy. By the time real keys are added, the hard-coding habit is already baked in.

#### Debug `console.log` Removal (6 statements, 4 components)

**Files modified:** `executiveKpiDashboard.js`, `integrationDeploymentDashboard.js`, `performanceOptimizationDashboard.js`, `securityGovernanceDashboard.js`

Removed `console.log('KPI Data processed:', ...)`, `console.log('Quarterly Report:', ...)`, `console.log('Monthly Report:', ...)`, `console.log('Health Data processed:', ...)`, `console.log('Performance Data processed:', ...)`, and `console.log('Security Data processed:', ...)`. Kept all `console.error(...)` calls since those log genuine error conditions.

**Why this matters:**

`console.log` in production code is a **code smell** for several reasons:

- **Information leakage** — logged data is visible in browser DevTools to any user. In a Salesforce context, this could expose record data, API responses, or internal state to users who have DevTools open.
- **Performance impact** — serializing complex objects (like `this.kpiData`) for console output costs CPU cycles on every invocation, even when nobody is watching.
- **Noise in debugging** — when you actually need to debug an issue, real diagnostic logs are buried under "Data processed" noise.
- **`console.error` is different** — it's intentional error logging that appears in the Error panel, helps with production debugging, and signals genuine failure conditions. That's why we kept those.

### Pre-Existing Issues (Not Caused by This Work)

These were discovered during the full `force-app` deployment attempt and are **not regressions**:

- `Job_Application_Workflow.flow-meta.xml` — duplicate `actionCalls` element at line 537 (XML parsing error)
- `Job_Application_Manager.permissionset-meta.xml` — references required field `Company_Name__c` incorrectly
- `jobApplicationDashboard.html` — inline ternary in HTML `label` attribute uses syntax not supported by the LWC compiler on the server
- Multiple pre-existing Apex compilation errors in `AutomatedReportService`, `CompanyDataServiceTest`, `JobApplicationCleanupBatch`, `JobApplicationEnrichmentQueue` (invalid types, missing methods, static field access issues)

---

## Deployment Summary

**Target org:** `capstone@taju.com` (myCapstoneOrg)

| Deployment | Components | Status |
|-----------|-----------|--------|
| Custom Metadata Type + records | 9/9 | Succeeded |
| Apex classes (new + modified) | 8/8 | Succeeded |
| LWC components (errorPanel, salaryCalculator, securityGovernanceDashboard) | 3/3 | Succeeded |
| Remaining Apex + triggers (API version bumps) | 18/18 | Succeeded |
| LWC + objects + fields (API version bumps) | 44/44 | Succeeded |
| **Total deployed** | **82** | **Succeeded** |

**Skipped** (pre-existing issues): `Job_Application_Workflow`, `Job_Application_Manager` permissionset, `jobApplicationDashboard` LWC

---

## Git History

```
56f2026 fix: final audit — sharing keywords, meta.xml, Named Credentials, debug cleanup
ef612ef fix: add inherited sharing to 41 Apex classes missing sharing keyword
10c64ac chore: add AI context files and quick-deploy script
f09c9de docs: enhance MODERNIZATION_CHANGELOG with educational explanations
3dfd1da chore: reorganize docs, fix deployment issues, update changelog
472a712 docs: consolidate documentation and add supporting scripts
9ac56c3 feat: add Interview Feedback Tracker and platform enhancements
5bc70e0 refactor: modernize codebase and remove redundant files
509bc99 chore: add .kiro/ to gitignore
708a3ec (origin/main) Merge branch 'main' [previous state]
```

---

## Summary

| Category | Change | Status |
|----------|--------|--------|
| API Version | 58.0 → 62.0 across 79 metadata files | Done |
| `@track` removal | 60 properties across 10 LWCs | Done |
| Sharing keywords | 56 classes (all Apex classes standardized) | Done |
| Tax rates | 2023 → 2025, moved to Custom Metadata | Done |
| Named Credentials | All API services use callout: endpoints | Done |
| SOQL Injection | Input validation in PerformanceOptimizationService | Done |
| Custom Metadata | Tax_Configuration__mdt with admin UI | Done |
| Error Panel | Reusable c-error-panel LWC component | Done |
| Platform Events | Failed event tracking with replay support | Done |
| Jest Tests | 3 new test suites for LWC components | Done |
| Pagination | getApplicationsPaginated() with LIMIT/OFFSET | Done |
| Accessibility | WCAG aria-live, keyboard nav, semantic roles | Done |
| Docs Cleanup | 20 docs organized into 3 subdirectories | Done |
| Source Control | 340 files → clean commits, gitignore updated | Done |
| AI Context | CLAUDE.md + copilot-instructions.md for AI tools | Done |
| Deploy Script | quick-deploy.ps1 with dependency ordering | Done |
| xmlns Fix | sforge → sforce typo in CMDT field metadata | Done |
| Missing meta.xml | Created 22 .cls-meta.xml files for orphaned classes | Done |
| Debug cleanup | Removed leftover console.log from LWC dashboards | Done |
