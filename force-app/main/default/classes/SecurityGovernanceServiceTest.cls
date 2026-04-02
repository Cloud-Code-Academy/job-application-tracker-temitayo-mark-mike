/**
 * @description Test class for SecurityGovernanceService
 * @author Test Suite
 * @date 2025
 */
@IsTest
private class SecurityGovernanceServiceTest {

    @TestSetup
    static void setupTestData() {
        List<Job_Application__c> apps = TestDataFactory.createJobApplications(3, 'Applied', true);
    }

    @IsTest
    static void testGetSecurityAssessment() {
        Test.startTest();
        Map<String, Object> assessment =
            SecurityGovernanceService.getSecurityAssessment();
        Test.stopTest();

        System.assertNotEquals(null, assessment, 'Assessment should not be null');
        // User security profile
        System.assert(assessment.containsKey('userId'), 'Should contain userId');
        System.assert(assessment.containsKey('userName'), 'Should contain userName');
        System.assert(assessment.containsKey('profileName'),
            'Should contain profileName');
        System.assert(assessment.containsKey('securityScore'),
            'Should contain securityScore');

        // Data access analysis
        System.assert(assessment.containsKey('ownedRecords'),
            'Should contain ownedRecords');
        System.assert(assessment.containsKey('fieldAccess'),
            'Should contain fieldAccess');

        // Compliance
        System.assert(assessment.containsKey('gdprCompliant'),
            'Should contain gdprCompliant');
        System.assert(assessment.containsKey('complianceScore'),
            'Should contain complianceScore');

        // Recommendations
        System.assert(assessment.containsKey('recommendations'),
            'Should contain recommendations');

        // Audit summary
        System.assert(assessment.containsKey('totalAuditEntries'),
            'Should contain audit trail summary');
    }

    @IsTest
    static void testValidateDataAccessRead() {
        List<Job_Application__c> apps = [SELECT Id FROM Job_Application__c LIMIT 2];
        List<Id> recordIds = new List<Id>();
        for (Job_Application__c app : apps) {
            recordIds.add(app.Id);
        }

        Test.startTest();
        Map<String, Object> validation =
            SecurityGovernanceService.validateDataAccess(recordIds, 'READ');
        Test.stopTest();

        System.assertNotEquals(null, validation, 'Validation should not be null');
        System.assertEquals(recordIds.size(), validation.get('totalRecords'),
            'Total records should match input');
        System.assert(validation.containsKey('accessibleRecords'),
            'Should contain accessibleRecords count');
        System.assert(validation.containsKey('restrictedRecords'),
            'Should contain restrictedRecords count');

        List<Map<String, Object>> results =
            (List<Map<String, Object>>) validation.get('results');
        System.assertEquals(recordIds.size(), results.size(),
            'Should have result for each record');
    }

    @IsTest
    static void testValidateDataAccessEdit() {
        List<Job_Application__c> apps = [SELECT Id FROM Job_Application__c LIMIT 1];
        List<Id> recordIds = new List<Id>{ apps[0].Id };

        Test.startTest();
        Map<String, Object> validation =
            SecurityGovernanceService.validateDataAccess(recordIds, 'EDIT');
        Test.stopTest();

        System.assertNotEquals(null, validation, 'Validation should not be null');
        List<Map<String, Object>> results =
            (List<Map<String, Object>>) validation.get('results');
        System.assertNotEquals(null, results[0].get('accessLevel'),
            'Should have access level for EDIT operation');
    }

    @IsTest
    static void testValidateDataAccessDelete() {
        List<Job_Application__c> apps = [SELECT Id FROM Job_Application__c LIMIT 1];
        List<Id> recordIds = new List<Id>{ apps[0].Id };

        Test.startTest();
        Map<String, Object> validation =
            SecurityGovernanceService.validateDataAccess(recordIds, 'DELETE');
        Test.stopTest();

        System.assertNotEquals(null, validation, 'Validation should not be null');
        List<Map<String, Object>> results =
            (List<Map<String, Object>>) validation.get('results');
        System.assertNotEquals(null, results[0].get('hasAccess'),
            'Should have hasAccess flag for DELETE operation');
    }

    @IsTest
    static void testCreateAuditLog() {
        Job_Application__c app = [SELECT Id FROM Job_Application__c LIMIT 1];

        Test.startTest();
        Boolean success = SecurityGovernanceService.createAuditLog(
            'VIEW', app.Id, 'Viewed salary information'
        );
        Test.stopTest();

        System.assert(success, 'Audit log creation should return true');
    }

    @IsTest
    static void testApplyDataMasking() {
        List<Map<String, Object>> records = new List<Map<String, Object>>();
        records.add(new Map<String, Object>{
            'Id' => 'a00000000000001',
            'Salary__c' => 120000,
            'Notes__c' => 'Some confidential notes about the candidate',
            'Primary_Contact__c' => 'john.doe@company.com',
            'Company_Name__c' => 'Test Corp'
        });
        records.add(new Map<String, Object>{
            'Id' => 'a00000000000002',
            'Salary__c' => 95000,
            'Notes__c' => 'Another set of notes',
            'Primary_Contact__c' => 'jane.doe@company.com',
            'Company_Name__c' => 'Another Corp'
        });

        List<String> fieldNames = new List<String>{
            'Salary__c', 'Notes__c', 'Primary_Contact__c'
        };

        Test.startTest();
        List<Map<String, Object>> maskedRecords =
            SecurityGovernanceService.applyDataMasking(records, fieldNames);
        Test.stopTest();

        System.assertEquals(2, maskedRecords.size(),
            'Should return same number of records');

        // Verify salary is masked
        System.assertEquals('***,***', maskedRecords[0].get('Salary__c'),
            'Salary should be masked');
        // Verify contact is masked
        System.assertEquals('***@***.com', maskedRecords[0].get('Primary_Contact__c'),
            'Contact should be masked');
        // Verify notes are truncated
        String maskedNotes = (String) maskedRecords[0].get('Notes__c');
        System.assert(maskedNotes.endsWith('...'),
            'Notes should be truncated with ellipsis');
        // Verify non-sensitive field is not masked
        System.assertEquals('Test Corp', maskedRecords[0].get('Company_Name__c'),
            'Company name should not be masked');
    }

    @IsTest
    static void testGetComplianceReportGDPR() {
        Test.startTest();
        Map<String, Object> report =
            SecurityGovernanceService.getComplianceReport('GDPR');
        Test.stopTest();

        System.assertNotEquals(null, report, 'GDPR report should not be null');
        System.assertEquals('GDPR', report.get('reportType'),
            'Report type should be GDPR');
        System.assert(report.containsKey('dataSubjects'),
            'GDPR report should contain dataSubjects');
        System.assert(report.containsKey('rightToErasure'),
            'GDPR report should contain rightToErasure');
        System.assert(report.containsKey('generatedDate'),
            'Report should contain generatedDate');
    }

    @IsTest
    static void testGetComplianceReportSOX() {
        Test.startTest();
        Map<String, Object> report =
            SecurityGovernanceService.getComplianceReport('SOX');
        Test.stopTest();

        System.assertNotEquals(null, report, 'SOX report should not be null');
        System.assertEquals('SOX', report.get('reportType'),
            'Report type should be SOX');
        System.assert(report.containsKey('financialControls'),
            'SOX report should contain financialControls');
        System.assert(report.containsKey('auditTrail'),
            'SOX report should contain auditTrail');
    }

    @IsTest
    static void testGetComplianceReportSecurity() {
        Test.startTest();
        Map<String, Object> report =
            SecurityGovernanceService.getComplianceReport('SECURITY');
        Test.stopTest();

        System.assertNotEquals(null, report, 'Security report should not be null');
        System.assertEquals('SECURITY', report.get('reportType'),
            'Report type should be SECURITY');
        System.assert(report.containsKey('passwordPolicy'),
            'Security report should contain passwordPolicy');
        System.assert(report.containsKey('vulnerabilities'),
            'Security report should contain vulnerabilities');
    }

    @IsTest
    static void testGetComplianceReportAccess() {
        Test.startTest();
        Map<String, Object> report =
            SecurityGovernanceService.getComplianceReport('ACCESS');
        Test.stopTest();

        System.assertNotEquals(null, report, 'Access report should not be null');
        System.assertEquals('ACCESS', report.get('reportType'),
            'Report type should be ACCESS');
        System.assert(report.containsKey('totalUsers'),
            'Access report should contain totalUsers');
        System.assert(report.containsKey('privilegedAccess'),
            'Access report should contain privilegedAccess');
    }

    @IsTest
    static void testGetComplianceReportDefault() {
        Test.startTest();
        Map<String, Object> report =
            SecurityGovernanceService.getComplianceReport('UNKNOWN_TYPE');
        Test.stopTest();

        System.assertNotEquals(null, report, 'Default report should not be null');
        System.assertEquals('UNKNOWN_TYPE', report.get('reportType'),
            'Report type should match input');
        System.assert(report.containsKey('overallScore'),
            'Default report should contain overallScore');
        System.assert(report.containsKey('generatedBy'),
            'Report should contain generatedBy');
    }
}
