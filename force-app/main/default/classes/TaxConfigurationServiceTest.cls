/**
 * @description Test class for TaxConfigurationService
 * Tests tax configuration retrieval and fallback defaults
 * @author Test Suite
 * @date 2025
 */
@IsTest
private class TaxConfigurationServiceTest {

    @IsTest
    static void testGetActiveTaxConfigurationReturnsMap() {
        Test.startTest();
        Map<String, Object> config = TaxConfigurationService.getActiveTaxConfiguration();
        Test.stopTest();

        System.assertNotEquals(null, config, 'Configuration map should not be null');
        System.assert(!config.isEmpty(), 'Configuration map should not be empty');
    }

    @IsTest
    static void testConfigurationHasAllExpectedKeys() {
        Test.startTest();
        Map<String, Object> config = TaxConfigurationService.getActiveTaxConfiguration();
        Test.stopTest();

        System.assert(config.containsKey('taxYear'), 'Should contain taxYear key');
        System.assert(config.containsKey('standardDeduction'), 'Should contain standardDeduction key');
        System.assert(config.containsKey('socialSecurityRate'), 'Should contain socialSecurityRate key');
        System.assert(config.containsKey('socialSecurityWageBase'), 'Should contain socialSecurityWageBase key');
        System.assert(config.containsKey('medicareRate'), 'Should contain medicareRate key');
        System.assert(config.containsKey('taxBrackets'), 'Should contain taxBrackets key');
        System.assert(config.containsKey('source'), 'Should contain source key');
    }

    @IsTest
    static void testConfigurationValueTypes() {
        Test.startTest();
        Map<String, Object> config = TaxConfigurationService.getActiveTaxConfiguration();
        Test.stopTest();

        // taxYear should be numeric
        Object taxYear = config.get('taxYear');
        System.assertNotEquals(null, taxYear, 'taxYear should not be null');

        // Rates should be non-null
        Object ssRate = config.get('socialSecurityRate');
        System.assertNotEquals(null, ssRate, 'socialSecurityRate should not be null');

        Object medicareRate = config.get('medicareRate');
        System.assertNotEquals(null, medicareRate, 'medicareRate should not be null');

        Object standardDeduction = config.get('standardDeduction');
        System.assertNotEquals(null, standardDeduction, 'standardDeduction should not be null');

        Object ssWageBase = config.get('socialSecurityWageBase');
        System.assertNotEquals(null, ssWageBase, 'socialSecurityWageBase should not be null');
    }

    @IsTest
    static void testConfigurationHasTaxBrackets() {
        Test.startTest();
        Map<String, Object> config = TaxConfigurationService.getActiveTaxConfiguration();
        Test.stopTest();

        Object brackets = config.get('taxBrackets');
        System.assertNotEquals(null, brackets, 'taxBrackets should not be null');
        System.assert(brackets instanceof List<Object>, 'taxBrackets should be a list');

        List<Object> bracketList = (List<Object>) brackets;
        System.assert(bracketList.size() > 0, 'Tax brackets list should not be empty');
    }

    @IsTest
    static void testConfigurationSourceIsPresent() {
        Test.startTest();
        Map<String, Object> config = TaxConfigurationService.getActiveTaxConfiguration();
        Test.stopTest();

        String source = (String) config.get('source');
        System.assertNotEquals(null, source, 'Source should not be null');
        System.assert(source.length() > 0, 'Source should not be empty');
    }

    @IsTest
    static void testFallbackDefaultValues() {
        // In test context without CMDT records, the fallback defaults should be used
        Test.startTest();
        Map<String, Object> config = TaxConfigurationService.getActiveTaxConfiguration();
        Test.stopTest();

        // The source tells us whether defaults or CMDT was used
        String source = (String) config.get('source');
        if (source.contains('Default')) {
            // Verify fallback default values
            System.assertEquals(2025, config.get('taxYear'), 'Default tax year should be 2025');
            System.assertEquals(15000, config.get('standardDeduction'), 'Default standard deduction should be 15000');
            System.assertEquals(0.062, config.get('socialSecurityRate'), 'Default SS rate should be 0.062');
            System.assertEquals(176100, config.get('socialSecurityWageBase'), 'Default SS wage base should be 176100');
            System.assertEquals(0.0145, config.get('medicareRate'), 'Default Medicare rate should be 0.0145');
        }
        // If CMDT records exist in the org, the values will come from there — still valid
    }

    @IsTest
    static void testMethodDoesNotThrowException() {
        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            Map<String, Object> config = TaxConfigurationService.getActiveTaxConfiguration();
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assertEquals(false, exceptionThrown, 'getActiveTaxConfiguration should not throw exceptions');
    }
}
