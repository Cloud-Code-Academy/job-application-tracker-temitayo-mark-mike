/**
 * Enhanced configuration manager with validation and file generation
 */

import * as path from 'path';
import * as fs from 'fs';
import Joi from 'joi';
import { MigrationConfig, CategoryRule } from '../types';
import { createDefaultConfig, loadConfig as baseLoadConfig } from './index';

export class ConfigManager {
  private config: MigrationConfig;
  private configPath?: string;

  constructor(configPath?: string) {
    this.configPath = configPath;
    this.config = this.loadConfiguration();
  }

  /**
   * Load configuration with enhanced error handling
   */
  private loadConfiguration(): MigrationConfig {
    try {
      return baseLoadConfig(this.configPath);
    } catch (error) {
      throw new ConfigurationError(`Failed to load configuration: ${error}`);
    }
  }

  /**
   * Get current configuration
   */
  public getConfig(): MigrationConfig {
    return { ...this.config };
  }

  /**
   * Update configuration with validation
   */
  public updateConfig(updates: Partial<MigrationConfig>): void {
    const newConfig = { ...this.config, ...updates };
    
    // Validate the updated configuration
    const validation = this.validateConfiguration(newConfig);
    if (!validation.isValid) {
      throw new ConfigurationError(`Configuration validation failed: ${validation.errors.join(', ')}`);
    }

    this.config = newConfig;
  }

  /**
   * Save current configuration to file
   */
  public saveConfiguration(filePath?: string): void {
    const targetPath = filePath || this.configPath || './migration-config.json';
    
    try {
      const configDir = path.dirname(targetPath);
      if (!fs.existsSync(configDir)) {
        fs.mkdirSync(configDir, { recursive: true });
      }

      // Create a serializable version of the config (convert RegExp to strings)
      const serializableConfig = this.createSerializableConfig(this.config);
      
      fs.writeFileSync(targetPath, JSON.stringify(serializableConfig, null, 2));
    } catch (error) {
      throw new ConfigurationError(`Failed to save configuration to ${targetPath}: ${error}`);
    }
  }

  /**
   * Generate a default configuration file
   */
  public static generateDefaultConfigFile(filePath: string): void {
    const defaultConfig = createDefaultConfig();
    const configManager = new ConfigManager();
    configManager.config = defaultConfig;
    configManager.saveConfiguration(filePath);
  }

  /**
   * Validate configuration against schema
   */
  public validateConfiguration(config: MigrationConfig): ValidationResult {
    const schema = this.getConfigurationSchema();
    const { error } = schema.validate(config, { allowUnknown: false, abortEarly: false });
    
    if (error) {
      return {
        isValid: false,
        errors: error.details.map(detail => detail.message)
      };
    }

    // Additional custom validations
    const customErrors = this.performCustomValidations(config);
    
    return {
      isValid: customErrors.length === 0,
      errors: customErrors
    };
  }

  /**
   * Validate environment variables
   */
  public validateEnvironment(): ValidationResult {
    const errors: string[] = [];
    
    // Check required Salesforce credentials
    const requiredEnvVars = ['SF_USERNAME', 'SF_PASSWORD', 'SF_SECURITY_TOKEN'];
    for (const envVar of requiredEnvVars) {
      if (!process.env[envVar]) {
        errors.push(`Missing required environment variable: ${envVar}`);
      }
    }

    // Validate Salesforce login URL format
    if (this.config.salesforce.loginUrl && !this.isValidUrl(this.config.salesforce.loginUrl)) {
      errors.push('Invalid Salesforce login URL format');
    }

    // Check source directory exists
    if (!fs.existsSync(this.config.migration.sourceDirectory)) {
      errors.push(`Source directory does not exist: ${this.config.migration.sourceDirectory}`);
    }

    return {
      isValid: errors.length === 0,
      errors
    };
  }

  /**
   * Get configuration summary for reporting
   */
  public getConfigurationSummary(): ConfigurationSummary {
    return {
      salesforceOrg: this.maskCredentials(this.config.salesforce.username),
      sourceDirectory: this.config.migration.sourceDirectory,
      batchSize: this.config.migration.batchSize,
      dryRun: this.config.migration.dryRun,
      categoryRulesCount: this.config.categoryRules.length,
      excludePatterns: this.config.migration.excludePatterns,
      contentProcessing: this.config.contentProcessing
    };
  }

  /**
   * Create configuration schema for validation
   */
  private getConfigurationSchema(): Joi.ObjectSchema {
    return Joi.object({
      salesforce: Joi.object({
        loginUrl: Joi.string().uri().required(),
        username: Joi.string().email().required(),
        password: Joi.string().min(1).required(),
        securityToken: Joi.string().min(1).required(),
        apiVersion: Joi.string().pattern(/^\d+\.\d+$/).required()
      }).required(),
      
      migration: Joi.object({
        sourceDirectory: Joi.string().required(),
        excludePatterns: Joi.array().items(Joi.string()).required(),
        dryRun: Joi.boolean().required(),
        batchSize: Joi.number().integer().min(1).max(50).required(),
        resumeFile: Joi.string().required()
      }).required(),
      
      categoryRules: Joi.array().items(
        Joi.object({
          pattern: Joi.object().instance(RegExp).required(),
          category: Joi.string().required(),
          subcategory: Joi.string().optional(),
          difficulty: Joi.string().valid('Beginner', 'Intermediate', 'Advanced', 'Expert').optional()
        })
      ).min(1).required(),
      
      contentProcessing: Joi.object({
        imageHandling: Joi.string().valid('embed', 'link', 'skip').required(),
        linkProcessing: Joi.string().valid('convert', 'preserve').required(),
        codeBlockStyling: Joi.string().valid('salesforce', 'default').required()
      }).required()
    });
  }

  /**
   * Perform custom validations beyond schema
   */
  private performCustomValidations(config: MigrationConfig): string[] {
    const errors: string[] = [];

    // Validate category rules have unique patterns
    const patterns = config.categoryRules.map(rule => rule.pattern.source);
    const duplicates = patterns.filter((pattern, index) => patterns.indexOf(pattern) !== index);
    if (duplicates.length > 0) {
      errors.push(`Duplicate category rule patterns found: ${duplicates.join(', ')}`);
    }

    // Validate batch size is reasonable
    if (config.migration.batchSize > 25) {
      errors.push('Batch size should not exceed 25 to avoid Salesforce API limits');
    }

    return errors;
  }

  /**
   * Create a serializable version of config (convert RegExp to strings)
   */
  private createSerializableConfig(config: MigrationConfig): any {
    return {
      ...config,
      categoryRules: config.categoryRules.map(rule => ({
        ...rule,
        pattern: rule.pattern.source,
        flags: rule.pattern.flags
      }))
    };
  }

  /**
   * Validate URL format
   */
  private isValidUrl(url: string): boolean {
    try {
      new URL(url);
      return true;
    } catch {
      return false;
    }
  }

  /**
   * Mask sensitive credentials for logging
   */
  private maskCredentials(credential: string): string {
    if (!credential || credential.length < 4) {
      return '***';
    }
    return credential.substring(0, 3) + '*'.repeat(credential.length - 3);
  }
}

/**
 * Custom error class for configuration issues
 */
export class ConfigurationError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'ConfigurationError';
  }
}

/**
 * Validation result interface
 */
interface ValidationResult {
  isValid: boolean;
  errors: string[];
}

/**
 * Configuration summary interface
 */
interface ConfigurationSummary {
  salesforceOrg: string;
  sourceDirectory: string;
  batchSize: number;
  dryRun: boolean;
  categoryRulesCount: number;
  excludePatterns: string[];
  contentProcessing: {
    imageHandling: string;
    linkProcessing: string;
    codeBlockStyling: string;
  };
}