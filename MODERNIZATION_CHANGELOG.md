# Modernization Changelog & Enhancement Roadmap

> **Date:** March 25, 2026  
> **Scope:** API version bump, LWC reactivity cleanup, Apex security hardening, tax data refresh

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

### 3. Added `inherited sharing` to Apex Service Classes

**Files affected:** `SalaryBenchmarkService.cls`, `CompanyDataService.cls`

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

All 9 recommended enhancements from the initial audit have been implemented.

### 1. Named Credentials for API Services (was: High Priority)
**Files:** `SalaryBenchmarkService.cls`, `CompanyDataService.cls`

Replaced hard-coded API keys (`'demo-api-key-12345'`, `'Bearer demo-salary-api-key-67890'`) with Named Credential callouts (`callout:Salary_Benchmark_API`, `callout:Company_Data_API`). Credentials are now admin-managed in Setup, never stored in source code, and support OAuth rotation without deployments.

### 2. SOQL Injection Protection (was: High Priority)
**File:** `PerformanceOptimizationService.cls`

Added input validation to `optimizeQuery()`: blank check, length limit (10,000 chars), and DML keyword sanitization (`INSERT`, `UPDATE`, `DELETE`, `UPSERT`, `MERGE`, `UNDELETE` are stripped). Prevents malicious SOQL manipulation when query strings originate from user input.

### 3. Custom Metadata for Tax Configuration (was: High Priority)
**Files created:** `Tax_Configuration__mdt` (object + 7 fields), `TaxConfigurationService.cls`, CMDT record `Tax_Year_2025`
**File modified:** `salaryCalculator.js`

Tax brackets moved from hard-coded JavaScript constants to `Tax_Configuration__mdt` Custom Metadata Type. Admins can now update tax rates via Setup without code deployments. The LWC loads active config at runtime via `@wire(getActiveTaxConfiguration)` with hard-coded 2025 defaults as fallback.

### 4. Reusable Error Panel LWC (was: Medium Priority)
**Files created:** `errorPanel/` LWC component (JS, HTML, meta.xml)

Created `c-error-panel` — a reusable inline error display component with:
- `@api friendlyMessage` and `@api errorDetails` for customizable messaging
- Expandable details section with `aria-expanded` accessibility
- Optional retry button dispatching a `retry` custom event
- `role="alert"` and `aria-live="assertive"` for screen reader announcements

### 5. Platform Event Error Handling (was: Medium Priority)
**Files modified:** `JobApplicationEventPublisher.cls`, `JobApplicationEventSubscriber.cls`
**Added:** `inherited sharing` keyword, `FailedEventRecord` inner class

The subscriber now tracks failed events in a `@TestVisible` list with `jobApplicationId`, `eventType`, `errorMessage`, `replayId`, and `failedAt` fields. This enables monitoring and replay of failed platform events instead of silent data loss.

### 6. Jest Tests for LWC Components (was: Lower Priority)
**Files created:** `errorPanel/__tests__/errorPanel.test.js`, `securityGovernanceDashboard/__tests__/securityGovernanceDashboard.test.js`, `calendarIntegration/__tests__/calendarIntegration.test.js`

Added Jest test coverage for three components that had none. Tests validate rendering, user interactions, retry dispatch, and template structure.

### 7. Dashboard Pagination (was: Lower Priority)
**File modified:** `ApplicationAnalyticsService.cls`

Added `getApplicationsPaginated(Integer pageSize, Integer pageNumber, String statusFilter)` method with `LIMIT`/`OFFSET` SOQL, `COUNT()` query, and pagination metadata (`hasNext`, `hasPrevious`, `totalPages`, `totalRecords`). Prevents governor limit issues with large data volumes.

### 8. Accessibility (WCAG) Compliance (was: Lower Priority)
**Files modified:** `jobApplicationDashboard.html/js`, `securityGovernanceDashboard.html`

- Added `aria-live="polite"` to dynamic metric regions
- Added `aria-hidden="true"` to decorative emojis
- Added `role="list"`, `role="listitem"`, `role="status"` semantic landmarks
- Added `tabindex="0"` and `onkeydown` keyboard activation (Enter/Space) to clickable items
- Added `aria-label` attributes to interactive elements

### 9. Shared Apex Sharing Keywords (was: included in audit)
**Files modified:** `JobApplicationEventPublisher.cls`, `JobApplicationEventSubscriber.cls`, `SalaryBenchmarkService.cls`, `CompanyDataService.cls`

Added `inherited sharing` to all service classes that previously had no sharing declaration, preventing unintended `without sharing` behavior.

---

## Additional Cleanup

### Documentation Reorganization
- Merged duplicate admin guides into unified `ADMIN_GUIDE.md`
- Merged duplicate API references into unified `API_REFERENCE.md`
- Renamed `INTERVIEW_FEEDBACK_TRACKER_*` docs to consistent short names
- Organized 20 docs into `guides/`, `reference/`, `project/` subdirectories
- Rewrote `PROJECT_DOCUMENTATION_NAVIGATOR.md` and `docs/README.md` with correct links
- Removed 12 redundant root markdown files, 6 PDF duplicates, obsolete fix scripts

### Source Control Cleanup
- Added `.kiro/` to `.gitignore`
- Organized 340 changed files into 4 clean, descriptive commits
- Fixed `sforge` → `sforce` xmlns typo in `Social_Security_Rate__c.field-meta.xml`

---

## Summary

| Category | Change | Status |
|----------|--------|--------|
| API Version | 58.0 → 62.0 across 79 metadata files | Done |
| `@track` removal | 60 properties across 10 LWCs | Done |
| Sharing keywords | 4 service classes + 2 event classes | Done |
| Tax rates | 2023 → 2025, moved to Custom Metadata | Done |
| Named Credentials | API keys replaced with callout endpoints | Done |
| SOQL Injection | Input validation in PerformanceOptimizationService | Done |
| Custom Metadata | Tax_Configuration__mdt with admin UI | Done |
| Error Panel | Reusable c-error-panel LWC component | Done |
| Platform Events | Failed event tracking with replay support | Done |
| Jest Tests | 3 new test suites for LWC components | Done |
| Pagination | getApplicationsPaginated() with LIMIT/OFFSET | Done |
| Accessibility | WCAG aria-live, keyboard nav, semantic roles | Done |
| Docs Cleanup | 20 docs organized into 3 subdirectories | Done |
| Source Control | 340 files → 4 clean commits, gitignore updated | Done |
| xmlns Fix | sforge → sforce typo in CMDT field metadata | Done |
