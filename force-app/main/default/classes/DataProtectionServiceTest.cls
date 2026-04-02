/**
 * @description Test class for DataProtectionService
 * @author Test Suite
 * @date 2025
 */
@IsTest
private class DataProtectionServiceTest {

    @TestSetup
    static void setupTestData() {
        List<Job_Application__c> apps = new List<Job_Application__c>();
        // Compliant record with tax fields populated
        apps.add(TestDataFactory.createJobApplication(
            'Compliant Corp', 'Analyst', 'Applied', 90000, false
        ));
        apps[0].Federal_Tax__c = 19800;
        apps[0].Social_Security_Tax__c = 5580;
        apps[0].Medicare_Tax__c = 1305;

        // Record with high salary and missing taxes (will have violations)
        apps.add(TestDataFactory.createJobApplication(
            'High Pay Inc', 'VP Engineering', 'Applied', 1500000, false
        ));

        // Record with PII in notes
        apps.add(TestDataFactory.createJobApplication(
            'PII Corp', 'Developer', 'Applied', 80000, false
        ));
        apps[2].Federal_Tax__c = 17600;
        apps[2].Social_Security_Tax__c = 4960;
        apps[2].Medicare_Tax__c = 1160;
        apps[2].Notes__c = 'My SSN is 123-45-6789 and my phone is 555-1234';

        insert apps;
    }

    @IsTest
    static void testValidateProtectionCompliantData() {
        List<Job_Application__c> records = [
            SELECT Id, Company_Name__c, Salary__c, Federal_Tax__c,
                   Social_Security_Tax__c, Medicare_Tax__c, Notes__c,
                   Status__c, CreatedDate, LastModifiedDate
            FROM Job_Application__c
            WHERE Company_Name__c = 'Compliant Corp'
        ];

        Test.startTest();
        Map<Id, DataProtectionService.DataProtectionResult> results =
            DataProtectionService.validateDataProtection(records);
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should have one result');
        DataProtectionService.DataProtectionResult result = results.values()[0];
        System.assert(result.isCompliant, 'Compliant record should pass');
    }

    @IsTest
    static void testValidateProtectionWithViolations() {
        List<Job_Application__c> records = [
            SELECT Id, Company_Name__c, Salary__c, Federal_Tax__c,
                   Social_Security_Tax__c, Medicare_Tax__c, Notes__c,
                   Status__c, CreatedDate, LastModifiedDate
            FROM Job_Application__c
            WHERE Company_Name__c = 'High Pay Inc'
        ];

        Test.startTest();
        Map<Id, DataProtectionService.DataProtectionResult> results =
            DataProtectionService.validateDataProtection(records);
        Test.stopTest();

        DataProtectionService.DataProtectionResult result = results.values()[0];
        System.assert(!result.isCompliant, 'High salary with missing taxes should have violations');
        System.assert(!result.violations.isEmpty(), 'Should have at least one violation');
    }

    @IsTest
    static void testValidateProtectionPIIInNotes() {
        List<Job_Application__c> records = [
            SELECT Id, Company_Name__c, Salary__c, Federal_Tax__c,
                   Social_Security_Tax__c, Medicare_Tax__c, Notes__c,
                   Status__c, CreatedDate, LastModifiedDate
            FROM Job_Application__c
            WHERE Company_Name__c = 'PII Corp'
        ];

        Test.startTest();
        Map<Id, DataProtectionService.DataProtectionResult> results =
            DataProtectionService.validateDataProtection(records);
        Test.stopTest();

        DataProtectionService.DataProtectionResult result = results.values()[0];
        System.assert(!result.isCompliant, 'Record with PII in notes should fail compliance');
        Boolean hasPIIViolation = false;
        for (String violation : result.violations) {
            if (violation.contains('PII')) {
                hasPIIViolation = true;
            }
        }
        System.assert(hasPIIViolation, 'Should detect PII in notes');
    }

    @IsTest
    static void testMaskSensitiveData() {
        List<Job_Application__c> records = [
            SELECT Id, Company_Name__c, Salary__c, Federal_Tax__c,
                   Social_Security_Tax__c, Medicare_Tax__c, Notes__c
            FROM Job_Application__c
            WHERE Company_Name__c = 'Compliant Corp'
        ];

        Test.startTest();
        List<Job_Application__c> maskedRecords =
            DataProtectionService.maskSensitiveData(records);
        Test.stopTest();

        System.assertEquals(1, maskedRecords.size(), 'Should return same number of records');
        // hasPermission returns true, so data should not be masked in current implementation
        System.assertNotEquals(null, maskedRecords[0].Salary__c,
            'Salary should remain visible when user has permission');
    }

    @IsTest
    static void testCreateAuditTrail() {
        List<Job_Application__c> records = [
            SELECT Id, Company_Name__c, Salary__c, Notes__c,
                   Federal_Tax__c
            FROM Job_Application__c
            WHERE Company_Name__c = 'Compliant Corp'
        ];

        Test.startTest();
        // Should not throw any exceptions
        DataProtectionService.createAuditTrail(records, 'READ');
        DataProtectionService.createAuditTrail(records, 'WRITE');
        DataProtectionService.createAuditTrail(records, 'DELETE');
        Test.stopTest();

        // Audit trail logs to debug; verify no exceptions were thrown
        System.assert(true, 'Audit trail creation should complete without errors');
    }

    @IsTest
    static void testAnonymizeRecords() {
        List<Job_Application__c> records = [
            SELECT Id FROM Job_Application__c
            WHERE Company_Name__c = 'Compliant Corp'
        ];
        List<Id> recordIds = new List<Id>();
        for (Job_Application__c rec : records) {
            recordIds.add(rec.Id);
        }

        Test.startTest();
        Integer anonymizedCount = DataProtectionService.anonymizeRecords(recordIds);
        Test.stopTest();

        System.assertEquals(1, anonymizedCount, 'Should anonymize 1 record');

        Job_Application__c updated = [
            SELECT Company_Name__c, Position_Title__c, Notes__c, Salary__c
            FROM Job_Application__c
            WHERE Id = :recordIds[0]
        ];
        System.assert(updated.Company_Name__c.startsWith('ANONYMIZED_'),
            'Company name should be anonymized');
        System.assertEquals('ANONYMIZED_POSITION', updated.Position_Title__c,
            'Position title should be anonymized');
        System.assertEquals('[DATA ANONYMIZED - GDPR REQUEST]', updated.Notes__c,
            'Notes should be anonymized');
        System.assertEquals(null, updated.Salary__c, 'Salary should be nulled');
    }

    @IsTest
    static void testGenerateComplianceReport() {
        Test.startTest();
        DataProtectionService.ComplianceReport report =
            DataProtectionService.generateComplianceReport();
        Test.stopTest();

        System.assertNotEquals(null, report, 'Report should not be null');
        System.assert(report.totalRecords >= 0, 'Total records should be non-negative');
        System.assert(report.recordsWithSensitiveData >= 0,
            'Records with sensitive data should be non-negative');
        System.assert(report.recordsNeedingRetentionReview >= 0,
            'Records needing retention review should be non-negative');
        System.assertNotEquals(null, report.complianceScore, 'Compliance score should be set');
        System.assertNotEquals(null, report.recommendations, 'Recommendations should be set');
        System.assert(!report.recommendations.isEmpty(),
            'Should have at least one recommendation');
    }
}
