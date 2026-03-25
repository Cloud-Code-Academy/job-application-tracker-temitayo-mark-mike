/**
 * @description Validation Rule Service for Job Application Tracker
 * @author Salesforce Learning Journey
 * @date 2025
 * 
 * This service provides comprehensive validation rules for data integrity
 * and business rule enforcement. Implements enterprise-grade validation
 * patterns including field validation, cross-field validation, and
 * business logic validation.
 * 
 * Key Features:
 * - Field-level validation rules
 * - Cross-field validation logic
 * - Business rule enforcement
 * - Data quality scoring
 * - Validation error reporting
 * - Custom validation messages
 */
public with sharing class ValidationRuleService {
    
    // Validation constants
    private static final Decimal MIN_SALARY = 15000; // Minimum wage consideration
    private static final Decimal MAX_SALARY = 2000000; // Reasonable maximum
    private static final Integer MAX_COMPANY_NAME_LENGTH = 255;
    private static final Integer MAX_POSITION_TITLE_LENGTH = 255;
    private static final Integer MAX_NOTES_LENGTH = 32000;
    
    // Valid status values
    private static final Set<String> VALID_STATUSES = new Set<String>{
        'Interested', 'Applied', 'Phone Screen', 'Interview Scheduled', 
        'Interviewed', 'Offer Received', 'Accepted', 'Rejected', 'Withdrawn'
    };
    
    // Valid location types
    private static final Set<String> VALID_LOCATIONS = new Set<String>{
        'Remote', 'On-site', 'Hybrid'
    };
    
    /**
     * @description Validates Job Application records before DML operations
     * @param records List of Job Application records to validate
     * @param operationType Type of DML operation (INSERT, UPDATE, DELETE)
     * @return ValidationResult containing validation status and errors
     */
    public static ValidationResult validateJobApplications(List<Job_Application__c> records, String operationType) {
        ValidationResult result = new ValidationResult();
        result.isValid = true;
        result.errors = new List<ValidationError>();
        result.warnings = new List<ValidationWarning>();
        
        for (Job_Application__c record : records) {
            // Perform field-level validation
            validateRequiredFields(record, result);
            validateFieldFormats(record, result);
            validateFieldLengths(record, result);
            validateFieldRanges(record, result);
            
            // Perform business logic validation
            validateBusinessRules(record, result);
            validateStatusTransitions(record, result, operationType);
            validateSalaryConsistency(record, result);
            
            // Perform data quality checks
            validateDataQuality(record, result);
        }
        
        return result;
    }
    
    /**
     * @description Validates required fields are populated
     */
    private static void validateRequiredFields(Job_Application__c record, ValidationResult result) {
        // Company Name is required
        if (String.isBlank(record.Company_Name__c)) {
            result.errors.add(new ValidationError(
                record.Id,
                'Company_Name__c',
                'Company Name is required',
                'REQUIRED_FIELD_MISSING'
            ));
            result.isValid = false;
        }
        
        // Position Title is required
        if (String.isBlank(record.Position_Title__c)) {
            result.errors.add(new ValidationError(
                record.Id,
                'Position_Title__c',
                'Position Title is required',
                'REQUIRED_FIELD_MISSING'
            ));
            result.isValid = false;
        }
        
        // Status is required
        if (String.isBlank(record.Status__c)) {
            result.errors.add(new ValidationError(
                record.Id,
                'Status__c',
                'Status is required',
                'REQUIRED_FIELD_MISSING'
            ));
            result.isValid = false;
        }
        
        // Application Date is required
        if (record.Application_Date__c == null) {
            result.errors.add(new ValidationError(
                record.Id,
                'Application_Date__c',
                'Application Date is required',
                'REQUIRED_FIELD_MISSING'
            ));
            result.isValid = false;
        }
    }
    
    /**
     * @description Validates field formats and patterns
     */
    private static void validateFieldFormats(Job_Application__c record, ValidationResult result) {
        // Validate email format in notes (if present)
        if (String.isNotBlank(record.Notes__c)) {
            Pattern emailPattern = Pattern.compile('[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}');
            Matcher emailMatcher = emailPattern.matcher(record.Notes__c);
            
            if (emailMatcher.find()) {
                result.warnings.add(new ValidationWarning(
                    record.Id,
                    'Notes__c',
                    'Email address detected in notes - consider data privacy implications',
                    'DATA_PRIVACY_CONCERN'
                ));
            }
        }
        
        // Note: URL validation would be added when Job_Posting_URL__c field is available
    }
    
    /**
     * @description Validates field length constraints
     */
    private static void validateFieldLengths(Job_Application__c record, ValidationResult result) {
        // Company Name length
        if (String.isNotBlank(record.Company_Name__c) && 
            record.Company_Name__c.length() > MAX_COMPANY_NAME_LENGTH) {
            result.errors.add(new ValidationError(
                record.Id,
                'Company_Name__c',
                'Company Name cannot exceed ' + MAX_COMPANY_NAME_LENGTH + ' characters',
                'FIELD_TOO_LONG'
            ));
            result.isValid = false;
        }
        
        // Position Title length
        if (String.isNotBlank(record.Position_Title__c) && 
            record.Position_Title__c.length() > MAX_POSITION_TITLE_LENGTH) {
            result.errors.add(new ValidationError(
                record.Id,
                'Position_Title__c',
                'Position Title cannot exceed ' + MAX_POSITION_TITLE_LENGTH + ' characters',
                'FIELD_TOO_LONG'
            ));
            result.isValid = false;
        }
        
        // Notes length
        if (String.isNotBlank(record.Notes__c) && 
            record.Notes__c.length() > MAX_NOTES_LENGTH) {
            result.errors.add(new ValidationError(
                record.Id,
                'Notes__c',
                'Notes cannot exceed ' + MAX_NOTES_LENGTH + ' characters',
                'FIELD_TOO_LONG'
            ));
            result.isValid = false;
        }
    }
    
    /**
     * @description Validates field value ranges
     */
    private static void validateFieldRanges(Job_Application__c record, ValidationResult result) {
        // Salary range validation
        if (record.Salary__c != null) {
            if (record.Salary__c < MIN_SALARY) {
                result.errors.add(new ValidationError(
                    record.Id,
                    'Salary__c',
                    'Salary cannot be less than $' + MIN_SALARY.format(),
                    'VALUE_TOO_LOW'
                ));
                result.isValid = false;
            }
            
            if (record.Salary__c > MAX_SALARY) {
                result.errors.add(new ValidationError(
                    record.Id,
                    'Salary__c',
                    'Salary cannot exceed $' + MAX_SALARY.format(),
                    'VALUE_TOO_HIGH'
                ));
                result.isValid = false;
            }
        }
        
        // Date range validation
        if (record.Application_Date__c != null) {
            // Application date cannot be in the future
            if (record.Application_Date__c > Date.today()) {
                result.errors.add(new ValidationError(
                    record.Id,
                    'Application_Date__c',
                    'Application Date cannot be in the future',
                    'INVALID_DATE_RANGE'
                ));
                result.isValid = false;
            }
            
            // Application date cannot be too far in the past (more than 5 years)
            if (record.Application_Date__c < Date.today().addYears(-5)) {
                result.warnings.add(new ValidationWarning(
                    record.Id,
                    'Application_Date__c',
                    'Application Date is more than 5 years old - verify accuracy',
                    'OLD_DATE_WARNING'
                ));
            }
        }
        
        // Note: Interview date validation would be added when field is available
    }
    
    /**
     * @description Validates business rules and logic
     */
    private static void validateBusinessRules(Job_Application__c record, ValidationResult result) {
        // Valid status values
        if (String.isNotBlank(record.Status__c) && !VALID_STATUSES.contains(record.Status__c)) {
            result.errors.add(new ValidationError(
                record.Id,
                'Status__c',
                'Invalid status value. Valid values are: ' + String.join(new List<String>(VALID_STATUSES), ', '),
                'INVALID_PICKLIST_VALUE'
            ));
            result.isValid = false;
        }
        
        // Valid location values
        if (String.isNotBlank(record.Location__c) && !VALID_LOCATIONS.contains(record.Location__c)) {
            result.errors.add(new ValidationError(
                record.Id,
                'Location__c',
                'Invalid location value. Valid values are: ' + String.join(new List<String>(VALID_LOCATIONS), ', '),
                'INVALID_PICKLIST_VALUE'
            ));
            result.isValid = false;
        }
        
        // Note: Interview date validation would be added when field is available
        
        // Salary should be set for offer-related statuses
        if ((record.Status__c == 'Offer Received' || record.Status__c == 'Accepted') && 
            record.Salary__c == null) {
            result.warnings.add(new ValidationWarning(
                record.Id,
                'Salary__c',
                'Salary should be set when status is ' + record.Status__c,
                'MISSING_RELATED_DATA'
            ));
        }
    }
    
    /**
     * @description Validates status transitions for updates
     */
    private static void validateStatusTransitions(Job_Application__c record, ValidationResult result, String operationType) {
        if (operationType != 'UPDATE') {
            return; // Only validate transitions on updates
        }
        
        // Get old record for comparison (in a real implementation, this would come from Trigger.oldMap)
        // For now, we'll implement basic transition logic
        
        // Cannot go from Accepted/Rejected back to earlier stages
        if (record.Status__c == 'Applied' || record.Status__c == 'Phone Screen') {
            // This would need old record comparison in real implementation
            result.warnings.add(new ValidationWarning(
                record.Id,
                'Status__c',
                'Verify status transition is appropriate',
                'STATUS_TRANSITION_WARNING'
            ));
        }
    }
    
    /**
     * @description Validates salary calculation consistency
     */
    private static void validateSalaryConsistency(Job_Application__c record, ValidationResult result) {
        if (record.Salary__c == null) {
            return; // No salary to validate
        }
        
        // Validate tax calculations if present
        if (record.Federal_Tax__c != null) {
            // Basic federal tax validation (simplified)
            Decimal expectedMinTax = record.Salary__c * 0.10; // Minimum 10%
            Decimal expectedMaxTax = record.Salary__c * 0.37; // Maximum 37%
            
            if (record.Federal_Tax__c < expectedMinTax || record.Federal_Tax__c > expectedMaxTax) {
                result.warnings.add(new ValidationWarning(
                    record.Id,
                    'Federal_Tax__c',
                    'Federal tax amount appears inconsistent with salary - verify calculation',
                    'CALCULATION_INCONSISTENCY'
                ));
            }
        }
        
        // Validate Social Security tax (6.2% up to wage base)
        if (record.Social_Security_Tax__c != null) {
            Decimal expectedSSTax = Math.min(record.Salary__c * 0.062, 9932.40); // 2023 max
            Decimal tolerance = expectedSSTax * 0.05; // 5% tolerance
            
            if (Math.abs(record.Social_Security_Tax__c - expectedSSTax) > tolerance) {
                result.warnings.add(new ValidationWarning(
                    record.Id,
                    'Social_Security_Tax__c',
                    'Social Security tax calculation may be incorrect',
                    'CALCULATION_INCONSISTENCY'
                ));
            }
        }
        
        // Validate Medicare tax (1.45%)
        if (record.Medicare_Tax__c != null) {
            Decimal expectedMedicareTax = record.Salary__c * 0.0145;
            Decimal tolerance = expectedMedicareTax * 0.05; // 5% tolerance
            
            if (Math.abs(record.Medicare_Tax__c - expectedMedicareTax) > tolerance) {
                result.warnings.add(new ValidationWarning(
                    record.Id,
                    'Medicare_Tax__c',
                    'Medicare tax calculation may be incorrect',
                    'CALCULATION_INCONSISTENCY'
                ));
            }
        }
    }
    
    /**
     * @description Validates data quality and completeness
     */
    private static void validateDataQuality(Job_Application__c record, ValidationResult result) {
        Integer qualityScore = 100;
        List<String> qualityIssues = new List<String>();
        
        // Check for completeness
        if (String.isBlank(record.Location__c)) {
            qualityScore -= 10;
            qualityIssues.add('Location not specified');
        }
        
        if (String.isBlank(record.Notes__c)) {
            qualityScore -= 5;
            qualityIssues.add('No notes provided');
        }
        
        if (record.Salary__c == null) {
            qualityScore -= 15;
            qualityIssues.add('Salary information missing');
        }
        
        // Check for data consistency
        if (String.isNotBlank(record.Company_Name__c) && record.Company_Name__c.length() < 2) {
            qualityScore -= 20;
            qualityIssues.add('Company name too short');
        }
        
        if (String.isNotBlank(record.Position_Title__c) && record.Position_Title__c.length() < 3) {
            qualityScore -= 15;
            qualityIssues.add('Position title too short');
        }
        
        // Add quality warning if score is low
        if (qualityScore < 80) {
            result.warnings.add(new ValidationWarning(
                record.Id,
                'Data_Quality',
                'Data quality score: ' + qualityScore + '%. Issues: ' + String.join(qualityIssues, ', '),
                'LOW_DATA_QUALITY'
            ));
        }
    }
    
    /**
     * @description Validates bulk operations for governor limits
     * @param records List of records being processed
     * @return Boolean indicating if bulk operation is safe
     */
    public static Boolean validateBulkOperation(List<Job_Application__c> records) {
        // Check record count limits
        if (records.size() > 10000) {
            throw new ValidationException('Bulk operation exceeds maximum record limit of 10,000');
        }
        
        // Check for potential SOQL query issues
        Set<Id> uniqueIds = new Set<Id>();
        for (Job_Application__c record : records) {
            if (record.Id != null) {
                uniqueIds.add(record.Id);
            }
        }
        
        if (uniqueIds.size() > 200) {
            throw new ValidationException('Bulk operation may exceed SOQL query limits');
        }
        
        return true;
    }
    
    /**
     * @description Creates validation summary report
     * @param validationResults List of validation results to summarize
     * @return ValidationSummary with aggregated results
     */
    public static ValidationSummary createValidationSummary(List<ValidationResult> validationResults) {
        ValidationSummary summary = new ValidationSummary();
        summary.totalRecords = validationResults.size();
        summary.validRecords = 0;
        summary.recordsWithErrors = 0;
        summary.recordsWithWarnings = 0;
        summary.totalErrors = 0;
        summary.totalWarnings = 0;
        summary.errorsByType = new Map<String, Integer>();
        summary.warningsByType = new Map<String, Integer>();
        
        for (ValidationResult result : validationResults) {
            if (result.isValid) {
                summary.validRecords++;
            } else {
                summary.recordsWithErrors++;
            }
            
            if (!result.warnings.isEmpty()) {
                summary.recordsWithWarnings++;
            }
            
            // Count errors by type
            for (ValidationError error : result.errors) {
                summary.totalErrors++;
                Integer count = summary.errorsByType.get(error.errorType);
                summary.errorsByType.put(error.errorType, (count == null ? 1 : count + 1));
            }
            
            // Count warnings by type
            for (ValidationWarning warning : result.warnings) {
                summary.totalWarnings++;
                Integer count = summary.warningsByType.get(warning.warningType);
                summary.warningsByType.put(warning.warningType, (count == null ? 1 : count + 1));
            }
        }
        
        // Calculate success rate
        summary.successRate = summary.totalRecords > 0 ? 
            (Decimal.valueOf(summary.validRecords) / summary.totalRecords * 100).setScale(1) : 0;
        
        return summary;
    }
    
    // Inner classes for structured validation results
    
    public class ValidationResult {
        public Boolean isValid;
        public List<ValidationError> errors;
        public List<ValidationWarning> warnings;
        
        public ValidationResult() {
            this.errors = new List<ValidationError>();
            this.warnings = new List<ValidationWarning>();
        }
    }
    
    public class ValidationError {
        public Id recordId;
        public String fieldName;
        public String message;
        public String errorType;
        
        public ValidationError(Id recordId, String fieldName, String message, String errorType) {
            this.recordId = recordId;
            this.fieldName = fieldName;
            this.message = message;
            this.errorType = errorType;
        }
    }
    
    public class ValidationWarning {
        public Id recordId;
        public String fieldName;
        public String message;
        public String warningType;
        
        public ValidationWarning(Id recordId, String fieldName, String message, String warningType) {
            this.recordId = recordId;
            this.fieldName = fieldName;
            this.message = message;
            this.warningType = warningType;
        }
    }
    
    public class ValidationSummary {
        public Integer totalRecords;
        public Integer validRecords;
        public Integer recordsWithErrors;
        public Integer recordsWithWarnings;
        public Integer totalErrors;
        public Integer totalWarnings;
        public Decimal successRate;
        public Map<String, Integer> errorsByType;
        public Map<String, Integer> warningsByType;
        public DateTime generatedDate;
        
        public ValidationSummary() {
            this.generatedDate = DateTime.now();
            this.errorsByType = new Map<String, Integer>();
            this.warningsByType = new Map<String, Integer>();
        }
    }
    
    // Custom exception for validation errors
    public class ValidationException extends Exception {}
}