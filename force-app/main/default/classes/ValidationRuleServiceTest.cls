/**
 * @description Test class for ValidationRuleService
 * @author Test Suite
 * @date 2025
 */
@IsTest
private class ValidationRuleServiceTest {

    @IsTest
    static void testValidRecordPasses() {
        Job_Application__c jobApp = TestDataFactory.createJobApplication(
            'Acme Corp', 'Software Engineer', 'Applied', 80000, false
        );

        Test.startTest();
        ValidationRuleService.ValidationResult result =
            ValidationRuleService.validateJobApplications(
                new List<Job_Application__c>{ jobApp }, 'INSERT'
            );
        Test.stopTest();

        System.assert(result.isValid, 'A fully valid record should pass validation');
        System.assertEquals(0, result.errors.size(), 'There should be no errors');
    }

    @IsTest
    static void testMissingRequiredFields() {
        Job_Application__c jobApp = new Job_Application__c();
        // All required fields are blank/null

        Test.startTest();
        ValidationRuleService.ValidationResult result =
            ValidationRuleService.validateJobApplications(
                new List<Job_Application__c>{ jobApp }, 'INSERT'
            );
        Test.stopTest();

        System.assert(!result.isValid, 'Record missing required fields should fail');
        // Expect errors for Company_Name__c, Position_Title__c, Status__c, Application_Date__c
        Boolean hasCompanyError = false;
        Boolean hasPositionError = false;
        Boolean hasStatusError = false;
        Boolean hasDateError = false;
        for (ValidationRuleService.ValidationError err : result.errors) {
            if (err.fieldName == 'Company_Name__c') hasCompanyError = true;
            if (err.fieldName == 'Position_Title__c') hasPositionError = true;
            if (err.fieldName == 'Status__c') hasStatusError = true;
            if (err.fieldName == 'Application_Date__c') hasDateError = true;
        }
        System.assert(hasCompanyError, 'Should report Company_Name__c required');
        System.assert(hasPositionError, 'Should report Position_Title__c required');
        System.assert(hasStatusError, 'Should report Status__c required');
        System.assert(hasDateError, 'Should report Application_Date__c required');
    }

    @IsTest
    static void testInvalidStatus() {
        Job_Application__c jobApp = TestDataFactory.createJobApplication(
            'Acme Corp', 'Developer', 'InvalidStatus', 80000, false
        );

        Test.startTest();
        ValidationRuleService.ValidationResult result =
            ValidationRuleService.validateJobApplications(
                new List<Job_Application__c>{ jobApp }, 'INSERT'
            );
        Test.stopTest();

        System.assert(!result.isValid, 'Invalid status should fail validation');
        Boolean hasStatusError = false;
        for (ValidationRuleService.ValidationError err : result.errors) {
            if (err.fieldName == 'Status__c' && err.errorType == 'INVALID_PICKLIST_VALUE') {
                hasStatusError = true;
            }
        }
        System.assert(hasStatusError, 'Should have an invalid status picklist error');
    }

    @IsTest
    static void testSalaryBelowMinimum() {
        Job_Application__c jobApp = TestDataFactory.createJobApplication(
            'Acme Corp', 'Intern', 'Applied', 5000, false
        );

        Test.startTest();
        ValidationRuleService.ValidationResult result =
            ValidationRuleService.validateJobApplications(
                new List<Job_Application__c>{ jobApp }, 'INSERT'
            );
        Test.stopTest();

        System.assert(!result.isValid, 'Salary below minimum should fail');
        Boolean hasSalaryError = false;
        for (ValidationRuleService.ValidationError err : result.errors) {
            if (err.fieldName == 'Salary__c' && err.errorType == 'VALUE_TOO_LOW') {
                hasSalaryError = true;
            }
        }
        System.assert(hasSalaryError, 'Should have VALUE_TOO_LOW error for salary');
    }

    @IsTest
    static void testSalaryAboveMaximum() {
        Job_Application__c jobApp = TestDataFactory.createJobApplication(
            'Acme Corp', 'CEO', 'Applied', 3000000, false
        );

        Test.startTest();
        ValidationRuleService.ValidationResult result =
            ValidationRuleService.validateJobApplications(
                new List<Job_Application__c>{ jobApp }, 'INSERT'
            );
        Test.stopTest();

        System.assert(!result.isValid, 'Salary above maximum should fail');
        Boolean hasSalaryError = false;
        for (ValidationRuleService.ValidationError err : result.errors) {
            if (err.fieldName == 'Salary__c' && err.errorType == 'VALUE_TOO_HIGH') {
                hasSalaryError = true;
            }
        }
        System.assert(hasSalaryError, 'Should have VALUE_TOO_HIGH error for salary');
    }

    @IsTest
    static void testFutureDate() {
        Job_Application__c jobApp = TestDataFactory.createJobApplication(
            'Acme Corp', 'Developer', 'Applied', 80000, false
        );
        jobApp.Application_Date__c = Date.today().addDays(30);

        Test.startTest();
        ValidationRuleService.ValidationResult result =
            ValidationRuleService.validateJobApplications(
                new List<Job_Application__c>{ jobApp }, 'INSERT'
            );
        Test.stopTest();

        System.assert(!result.isValid, 'Future application date should fail');
        Boolean hasDateError = false;
        for (ValidationRuleService.ValidationError err : result.errors) {
            if (err.fieldName == 'Application_Date__c' && err.errorType == 'INVALID_DATE_RANGE') {
                hasDateError = true;
            }
        }
        System.assert(hasDateError, 'Should have INVALID_DATE_RANGE error');
    }

    @IsTest
    static void testPIIInNotes() {
        Job_Application__c jobApp = TestDataFactory.createJobApplication(
            'Acme Corp', 'Developer', 'Applied', 80000, false
        );
        jobApp.Notes__c = 'Contact me at user@example.com for details';

        Test.startTest();
        ValidationRuleService.ValidationResult result =
            ValidationRuleService.validateJobApplications(
                new List<Job_Application__c>{ jobApp }, 'INSERT'
            );
        Test.stopTest();

        Boolean hasPrivacyWarning = false;
        for (ValidationRuleService.ValidationWarning warn : result.warnings) {
            if (warn.warningType == 'DATA_PRIVACY_CONCERN') {
                hasPrivacyWarning = true;
            }
        }
        System.assert(hasPrivacyWarning, 'Email in notes should trigger privacy warning');
    }

    @IsTest
    static void testBulkValidationSuccess() {
        List<Job_Application__c> records = TestDataFactory.createJobApplications(100, 'Applied', false);

        Test.startTest();
        Boolean isValid = ValidationRuleService.validateBulkOperation(records);
        Test.stopTest();

        System.assert(isValid, 'Bulk operation with 100 records should succeed');
    }

    @IsTest
    static void testBulkValidationExceedsLimit() {
        // Create a list exceeding 10000 records (in-memory only, no DML)
        List<Job_Application__c> records = new List<Job_Application__c>();
        for (Integer i = 0; i < 10001; i++) {
            records.add(new Job_Application__c(
                Company_Name__c = 'Company ' + i,
                Position_Title__c = 'Position ' + i,
                Status__c = 'Applied'
            ));
        }

        Test.startTest();
        try {
            ValidationRuleService.validateBulkOperation(records);
            System.assert(false, 'Should have thrown ValidationException');
        } catch (ValidationRuleService.ValidationException e) {
            System.assert(e.getMessage().contains('10,000'),
                'Exception message should reference the 10,000 limit');
        }
        Test.stopTest();
    }

    @IsTest
    static void testValidationSummary() {
        // Create a mix of valid and invalid results
        ValidationRuleService.ValidationResult validResult = new ValidationRuleService.ValidationResult();
        validResult.isValid = true;
        validResult.errors = new List<ValidationRuleService.ValidationError>();
        validResult.warnings = new List<ValidationRuleService.ValidationWarning>();

        ValidationRuleService.ValidationResult invalidResult = new ValidationRuleService.ValidationResult();
        invalidResult.isValid = false;
        invalidResult.errors = new List<ValidationRuleService.ValidationError>{
            new ValidationRuleService.ValidationError(null, 'Status__c', 'Invalid', 'INVALID_PICKLIST_VALUE')
        };
        invalidResult.warnings = new List<ValidationRuleService.ValidationWarning>{
            new ValidationRuleService.ValidationWarning(null, 'Salary__c', 'Missing', 'MISSING_RELATED_DATA')
        };

        List<ValidationRuleService.ValidationResult> results =
            new List<ValidationRuleService.ValidationResult>{ validResult, invalidResult };

        Test.startTest();
        ValidationRuleService.ValidationSummary summary =
            ValidationRuleService.createValidationSummary(results);
        Test.stopTest();

        System.assertEquals(2, summary.totalRecords, 'Total records should be 2');
        System.assertEquals(1, summary.validRecords, 'Valid records should be 1');
        System.assertEquals(1, summary.recordsWithErrors, 'Records with errors should be 1');
        System.assertEquals(1, summary.recordsWithWarnings, 'Records with warnings should be 1');
        System.assertEquals(1, summary.totalErrors, 'Total errors should be 1');
        System.assertEquals(1, summary.totalWarnings, 'Total warnings should be 1');
        System.assert(summary.errorsByType.containsKey('INVALID_PICKLIST_VALUE'),
            'errorsByType should contain INVALID_PICKLIST_VALUE');
        System.assert(summary.warningsByType.containsKey('MISSING_RELATED_DATA'),
            'warningsByType should contain MISSING_RELATED_DATA');
        System.assert(summary.successRate != null, 'Success rate should be calculated');
    }

    @IsTest
    static void testFieldLengthValidation() {
        String longName = '';
        for (Integer i = 0; i < 260; i++) {
            longName += 'A';
        }

        Job_Application__c jobApp = TestDataFactory.createJobApplication(
            longName, 'Developer', 'Applied', 80000, false
        );

        Test.startTest();
        ValidationRuleService.ValidationResult result =
            ValidationRuleService.validateJobApplications(
                new List<Job_Application__c>{ jobApp }, 'INSERT'
            );
        Test.stopTest();

        System.assert(!result.isValid, 'Record with field exceeding max length should fail');
        Boolean hasLengthError = false;
        for (ValidationRuleService.ValidationError err : result.errors) {
            if (err.errorType == 'FIELD_TOO_LONG') {
                hasLengthError = true;
            }
        }
        System.assert(hasLengthError, 'Should have FIELD_TOO_LONG error');
    }
}
