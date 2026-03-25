/**
 * @description Service to read tax configuration from Custom Metadata Types.
 *              Allows admins to update tax brackets/rates without code deployment.
 * @author Modernization Enhancement
 * @date 2026-03-25
 */
public with sharing class TaxConfigurationService {

    /**
     * @description Gets the active tax configuration for the LWC salary calculator.
     *              Falls back to hard-coded 2025 defaults if no CMDT record exists.
     * @return Map with keys: standardDeduction, socialSecurityRate, socialSecurityWageBase,
     *         medicareRate, taxBrackets (List of bracket maps), taxYear
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getActiveTaxConfiguration() {
        try {
            List<Tax_Configuration__mdt> configs = [
                SELECT Tax_Year__c, Standard_Deduction__c, Social_Security_Rate__c,
                       Social_Security_Wage_Base__c, Medicare_Rate__c, Tax_Brackets_JSON__c
                FROM Tax_Configuration__mdt
                WHERE Is_Active__c = true
                ORDER BY Tax_Year__c DESC
                LIMIT 1
            ];

            if (!configs.isEmpty()) {
                return buildConfigMap(configs[0]);
            }

            // Fallback to hard-coded defaults if no CMDT record exists
            return getDefaultConfiguration();

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error reading tax configuration: ' + e.getMessage());
            return getDefaultConfiguration();
        }
    }

    private static Map<String, Object> buildConfigMap(Tax_Configuration__mdt config) {
        Map<String, Object> result = new Map<String, Object>();
        result.put('taxYear', config.Tax_Year__c);
        result.put('standardDeduction', config.Standard_Deduction__c);
        result.put('socialSecurityRate', config.Social_Security_Rate__c);
        result.put('socialSecurityWageBase', config.Social_Security_Wage_Base__c);
        result.put('medicareRate', config.Medicare_Rate__c);

        // Parse tax brackets JSON
        if (String.isNotBlank(config.Tax_Brackets_JSON__c)) {
            result.put('taxBrackets', JSON.deserializeUntyped(config.Tax_Brackets_JSON__c));
        }

        result.put('source', 'Custom Metadata');
        return result;
    }

    private static Map<String, Object> getDefaultConfiguration() {
        Map<String, Object> defaults = new Map<String, Object>();
        defaults.put('taxYear', 2025);
        defaults.put('standardDeduction', 15000);
        defaults.put('socialSecurityRate', 0.062);
        defaults.put('socialSecurityWageBase', 176100);
        defaults.put('medicareRate', 0.0145);
        defaults.put('taxBrackets', new List<Map<String, Object>>{
            new Map<String, Object>{ 'min' => 0, 'max' => 11925, 'rate' => 0.10 },
            new Map<String, Object>{ 'min' => 11925, 'max' => 48475, 'rate' => 0.12 },
            new Map<String, Object>{ 'min' => 48475, 'max' => 103350, 'rate' => 0.22 },
            new Map<String, Object>{ 'min' => 103350, 'max' => 197300, 'rate' => 0.24 },
            new Map<String, Object>{ 'min' => 197300, 'max' => 250525, 'rate' => 0.32 },
            new Map<String, Object>{ 'min' => 250525, 'max' => 626350, 'rate' => 0.35 },
            new Map<String, Object>{ 'min' => 626350, 'max' => 999999999, 'rate' => 0.37 }
        });
        defaults.put('source', 'Default (no Custom Metadata found)');
        return defaults;
    }
}
