## Salesforce Development Context

This is a Salesforce SFDX project (API v62.0) using Apex and Lightning Web Components.

### Code Style

- Apex classes use `inherited sharing` by default (never omit the sharing keyword)
- LWC properties are reactive by default — do NOT add `@track` unless tracking deep object mutations
- External API calls use Named Credentials (`callout:Name`) — never hard-code API keys or endpoints
- Tax/financial configuration lives in `Tax_Configuration__mdt` Custom Metadata — not in code constants
- Test classes follow `ClassNameTest.cls` naming and use `TestDataFactory` for data setup

### Architecture Pattern

```
Trigger → TriggerHandler → Service → LWC (@wire / @AuraEnabled)
```

- Keep triggers thin (one line: call handler)
- Business logic goes in `*Service.cls` classes
- Batch/Queueable classes for async work
- Platform Events for cross-feature notifications

### Testing

- Apex: target 95%+ code coverage, use `@TestSetup` for shared data
- LWC Jest: tests live in `__tests__/` inside each component folder
- Run Apex tests: `sf apex run test --target-org myCapstoneOrg --code-coverage`
- Run Jest: `npm run test:unit`

### Key Objects

- `Job_Application__c` — core tracker with 25+ fields
- `Interview_Feedback__c` — feedback with competency ratings
- `Tax_Configuration__mdt` — admin-managed tax brackets
- `Job_Application_Event__e` — platform event for status changes

### Documentation

Project docs are in `docs/` organized into `guides/`, `reference/`, `project/`.
See `MODERNIZATION_CHANGELOG.md` for recent changes and rationale.
