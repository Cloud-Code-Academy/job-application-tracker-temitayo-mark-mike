/**
 * Comprehensive configuration validation utilities
 */

import * as fs from 'fs';
import * as path from 'path';
import { MigrationConfig } from '../types';

export class ConfigValidator {
  
  /**
   * Validate Salesforce connectivity configuration
   */
  public static validateSalesforceConfig(config: MigrationConfig['salesforce']): ValidationIssue[] {
    const issues: ValidationIssue[] = [];

    // Check login URL format
    if (!this.isValidSalesforceUrl(config.loginUrl)) {
      issues.push({
        severity: 'error',
        field: 'salesforce.loginUrl',
        message: 'Invalid Salesforce login URL. Must be a valid Salesforce domain.',
        suggestion: 'Use https://login.salesforce.com for production or https://test.salesforce.com for sandbox'
      });
    }

    // Check username format
    if (!this.isValidEmail(config.username)) {
      issues.push({
        severity: 'error',
        field: 'salesforce.username',
        message: 'Username must be a valid email address',
        suggestion: 'Ensure the username follows email format (e.g., user@company.com)'
      });
    }

    // Check password strength
    if (config.password.length < 8) {
      issues.push({
        severity: 'warning',
        field: 'salesforce.password',
        message: 'Password appears to be very short',
        suggestion: 'Ensure you are using the correct Salesforce password'
      });
    }

    // Check security token format
    if (config.securityToken.length !== 25) {
      issues.push({
        severity: 'warning',
        field: 'salesforce.securityToken',
        message: 'Security token length is unusual (expected 25 characters)',
        suggestion: 'Verify the security token from Salesforce setup'
      });
    }

    // Check API version format
    if (!this.isValidApiVersion(config.apiVersion)) {
      issues.push({
        severity: 'error',
        field: 'salesforce.apiVersion',
        message: 'Invalid API version format',
        suggestion: 'Use format like "58.0" or "59.0"'
      });
    }

    return issues;
  }

  /**
   * Validate migration settings
   */
  public static validateMigrationConfig(config: MigrationConfig['migration']): ValidationIssue[] {
    const issues: ValidationIssue[] = [];

    // Check source directory exists
    if (!fs.existsSync(config.sourceDirectory)) {
      issues.push({
        severity: 'error',
        field: 'migration.sourceDirectory',
        message: `Source directory does not exist: ${config.sourceDirectory}`,
        suggestion: 'Create the directory or update the path to an existing directory'
      });
    } else {
      // Check if directory contains markdown files
      const hasMarkdownFiles = this.hasMarkdownFiles(config.sourceDirectory);
      if (!hasMarkdownFiles) {
        issues.push({
          severity: 'warning',
          field: 'migration.sourceDirectory',
          message: 'Source directory contains no markdown files',
          suggestion: 'Verify the correct directory path or add markdown files to migrate'
        });
      }
    }

    // Validate exclude patterns
    for (const pattern of config.excludePatterns) {
      try {
        new RegExp(pattern);
      } catch (error) {
        issues.push({
          severity: 'error',
          field: 'migration.excludePatterns',
          message: `Invalid regex pattern: ${pattern}`,
          suggestion: 'Fix the regular expression syntax or use glob patterns'
        });
      }
    }

    // Check batch size
    if (config.batchSize > 25) {
      issues.push({
        severity: 'warning',
        field: 'migration.batchSize',
        message: 'Large batch size may hit Salesforce API limits',
        suggestion: 'Consider reducing batch size to 10-15 for better reliability'
      });
    }

    // Check resume file path
    const resumeDir = path.dirname(config.resumeFile);
    if (resumeDir !== '.' && !fs.existsSync(resumeDir)) {
      issues.push({
        severity: 'warning',
        field: 'migration.resumeFile',
        message: `Resume file directory does not exist: ${resumeDir}`,
        suggestion: 'Ensure the directory exists or use a relative path'
      });
    }

    return issues;
  }

  /**
   * Validate category rules
   */
  public static validateCategoryRules(rules: MigrationConfig['categoryRules']): ValidationIssue[] {
    const issues: ValidationIssue[] = [];

    if (rules.length === 0) {
      issues.push({
        severity: 'error',
        field: 'categoryRules',
        message: 'No category rules defined',
        suggestion: 'Add at least one category rule for automatic categorization'
      });
      return issues;
    }

    // Check for duplicate patterns
    const patterns = rules.map(rule => rule.pattern.source);
    const duplicates = patterns.filter((pattern, index) => patterns.indexOf(pattern) !== index);
    if (duplicates.length > 0) {
      issues.push({
        severity: 'error',
        field: 'categoryRules',
        message: `Duplicate category rule patterns: ${duplicates.join(', ')}`,
        suggestion: 'Remove or modify duplicate patterns to ensure unique matching'
      });
    }

    // Validate each rule
    rules.forEach((rule, index) => {
      // Check pattern validity
      try {
        new RegExp(rule.pattern);
      } catch (error) {
        issues.push({
          severity: 'error',
          field: `categoryRules[${index}].pattern`,
          message: `Invalid regex pattern: ${rule.pattern.source}`,
          suggestion: 'Fix the regular expression syntax'
        });
      }

      // Check category name format
      if (!this.isValidCategoryName(rule.category)) {
        issues.push({
          severity: 'warning',
          field: `categoryRules[${index}].category`,
          message: `Category name may not match Salesforce data categories: ${rule.category}`,
          suggestion: 'Use underscore-separated names matching your data category structure'
        });
      }

      // Check subcategory if provided
      if (rule.subcategory && !this.isValidCategoryName(rule.subcategory)) {
        issues.push({
          severity: 'warning',
          field: `categoryRules[${index}].subcategory`,
          message: `Subcategory name may not match Salesforce data categories: ${rule.subcategory}`,
          suggestion: 'Use underscore-separated names matching your data category structure'
        });
      }
    });

    return issues;
  }

  /**
   * Validate content processing options
   */
  public static validateContentProcessing(config: MigrationConfig['contentProcessing']): ValidationIssue[] {
    const issues: ValidationIssue[] = [];

    // Check image handling strategy
    if (config.imageHandling === 'embed') {
      issues.push({
        severity: 'info',
        field: 'contentProcessing.imageHandling',
        message: 'Image embedding may increase article size significantly',
        suggestion: 'Consider using "link" strategy for better performance'
      });
    }

    // Check link processing
    if (config.linkProcessing === 'preserve') {
      issues.push({
        severity: 'warning',
        field: 'contentProcessing.linkProcessing',
        message: 'Preserving original links may result in broken references',
        suggestion: 'Use "convert" to automatically update internal links'
      });
    }

    return issues;
  }

  /**
   * Generate comprehensive validation report
   */
  public static generateValidationReport(config: MigrationConfig): ValidationReport {
    const issues: ValidationIssue[] = [
      ...this.validateSalesforceConfig(config.salesforce),
      ...this.validateMigrationConfig(config.migration),
      ...this.validateCategoryRules(config.categoryRules),
      ...this.validateContentProcessing(config.contentProcessing)
    ];

    const errorCount = issues.filter(issue => issue.severity === 'error').length;
    const warningCount = issues.filter(issue => issue.severity === 'warning').length;
    const infoCount = issues.filter(issue => issue.severity === 'info').length;

    return {
      isValid: errorCount === 0,
      summary: {
        errors: errorCount,
        warnings: warningCount,
        info: infoCount,
        total: issues.length
      },
      issues
    };
  }

  // Private helper methods

  private static isValidSalesforceUrl(url: string): boolean {
    try {
      const parsedUrl = new URL(url);
      return parsedUrl.hostname.includes('salesforce.com') || 
             parsedUrl.hostname.includes('force.com') ||
             parsedUrl.hostname.includes('my.salesforce.com');
    } catch {
      return false;
    }
  }

  private static isValidEmail(email: string): boolean {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
  }

  private static isValidApiVersion(version: string): boolean {
    const versionRegex = /^\d+\.\d+$/;
    return versionRegex.test(version);
  }

  private static isValidCategoryName(name: string): boolean {
    // Check if name follows Salesforce data category naming conventions
    const categoryRegex = /^[A-Za-z][A-Za-z0-9_]*$/;
    return categoryRegex.test(name);
  }

  private static hasMarkdownFiles(directory: string): boolean {
    try {
      const files = fs.readdirSync(directory, { recursive: true });
      return files.some(file => 
        typeof file === 'string' && file.toLowerCase().endsWith('.md')
      );
    } catch {
      return false;
    }
  }
}

/**
 * Validation issue interface
 */
export interface ValidationIssue {
  severity: 'error' | 'warning' | 'info';
  field: string;
  message: string;
  suggestion: string;
}

/**
 * Validation report interface
 */
export interface ValidationReport {
  isValid: boolean;
  summary: {
    errors: number;
    warnings: number;
    info: number;
    total: number;
  };
  issues: ValidationIssue[];
}