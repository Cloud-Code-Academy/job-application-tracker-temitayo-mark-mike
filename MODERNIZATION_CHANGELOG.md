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

## Recommended Enhancements

### High Priority

#### 1. Replace Hard-Coded API Keys with Named Credentials
**Files:** `SalaryBenchmarkService.cls`, `CompanyDataService.cls`

Both files contain hard-coded API keys (`'demo-api-key-12345'`, `'Bearer demo-salary-api-key-67890'`). Even though they're demo values, this pattern is dangerous because:
- Credentials in source code get committed to version control history permanently
- Named Credentials centralize auth management, support OAuth flows, and are admin-configurable without code changes
- This is a common Salesforce security audit finding

**How:** Create Named Credentials in Setup, then replace `HttpRequest.setHeader('Authorization', API_KEY)` with `req.setEndpoint('callout:SalaryBenchmark/endpoint')`.

---

#### 2. Add SOQL Injection Protection to `PerformanceOptimizationService`
**File:** `PerformanceOptimizationService.cls`

The `optimizeQuery(String queryString)` method accepts a raw SOQL string. If any part of that string comes from user input, it's vulnerable to SOQL injection. 

**How:** Use `String.escapeSingleQuotes()` for any user-supplied values, or better yet, use bind variables with static SOQL.

---

#### 3. Implement Custom Metadata for Tax Configuration
**File:** `salaryCalculator.js` (and corresponding Apex service)

Tax brackets are hard-coded in JavaScript. Every year they change, requiring a code deployment.

**Why it matters:** Moving tax config to Custom Metadata Types means:
- Admins can update rates without developer involvement
- Changes deploy instantly — no code review or test cycle needed
- Historical rates can be preserved for comparison

---

### Medium Priority

#### 4. Add Error Boundaries to LWC Components

Several components (analytics dashboards especially) log errors to `console.error` without giving users actionable feedback. A consistent error handling pattern would improve UX:
- Show inline error states (not just toast notifications that disappear)
- Add retry buttons for transient failures
- Log errors to a custom `Application_Error__c` object for monitoring

---

#### 5. Convert Imperative Apex Calls to `@wire` Where Possible

Components like `integrationDeploymentDashboard` and `performanceOptimizationDashboard` use imperative Apex calls inside `connectedCallback` for initial data loading. Using `@wire` instead would:
- Enable automatic caching via the Lightning Data Service cache
- Simplify loading/error state management
- Support `refreshApex()` for cache invalidation without manual state tracking

---

#### 6. Add Platform Event Error Handling

`JobApplicationEventPublisher` publishes platform events but the subscriber side doesn't have robust retry logic. Platform events can fail silently. Consider:
- Checking `Database.SaveResult` from `EventBus.publish()`
- Implementing a replay mechanism using `ReplayId`
- Adding monitoring for event delivery failures

---

### Lower Priority (Polish)

#### 7. Add Jest Unit Tests for LWC Components

There are no `__tests__` directories for any LWC component. LWC Jest tests catch:
- Template rendering issues before deployment
- Wire adapter behavior with mock data
- User interaction flows (button clicks, form submissions)

---

#### 8. Implement Pagination for Dashboard Queries

Dashboard components query all records at once. For orgs with large data volumes, this will hit governor limits. Consider:
- Offset-based or cursor-based pagination
- `LIMIT`/`OFFSET` in SOQL with "Load More" UI
- `lightning-datatable` with lazy loading

---

#### 9. Add Accessibility (WCAG) Compliance

Review LWC templates for:
- Missing `aria-label` attributes on interactive elements
- Keyboard navigation support for custom components
- Screen reader compatibility for dashboard charts
- Color contrast ratios on status indicators

---

## Summary

| Category | Change | Risk if Ignored |
|----------|--------|----------------|
| API Version | 58.0 → 62.0 | Feature lockout, deprecation, test drift |
| `@track` removal | 60 properties across 10 LWCs | Code smell, misleading reactivity model |
| Sharing keywords | 2 service classes | Potential data exposure via CRUD/FLS bypass |
| Tax rates | 2023 → 2025 | Inaccurate salary calculations |
| Named Credentials | *Recommended* | Credentials in source control |
| SOQL Injection | *Recommended* | Security vulnerability |
| Custom Metadata for config | *Recommended* | Deployment overhead for data changes |
