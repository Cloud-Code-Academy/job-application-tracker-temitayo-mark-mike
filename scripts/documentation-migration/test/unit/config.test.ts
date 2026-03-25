/**
 * Unit tests for configuration management
 */

import { ConfigManager, ConfigValidator, ConfigTemplate, ConfigurationError } from '../../src/config';
import { MigrationConfig } from '../../src/types';
import * as fs from 'fs';
import * as path from 'path';

// Mock fs module
jest.mock('fs');
const mockFs = fs as jest.Mocked<typeof fs>;

describe('ConfigManager', () => {
  let tempConfigPath: string;

  beforeEach(() => {
    tempConfigPath = './test-config.json';
    jest.clearAllMocks();
  });

  afterEach(() => {
    // Clean up any created files
    if (fs.existsSync(tempConfigPath)) {
      fs.unlinkSync(tempConfigPath);
    }
  });

  describe('constructor', () => {
    it('should load default configuration when no config file exists', () => {
      mockFs.existsSync.mockReturnValue(false);
      
      const configManager = new ConfigManager();
      const config = configManager.getConfig();
      
      expect(config.salesforce).toBeDefined();
      expect(config.migration).toBeDefined();
      expect(config.categoryRules).toBeDefined();
      expect(config.contentProcessing).toBeDefined();
    });

    it('should throw ConfigurationError for invalid config file', () => {
      mockFs.existsSync.mockReturnValue(true);
      mockFs.readFileSync.mockReturnValue('invalid json');
      
      expect(() => new ConfigManager(tempConfigPath)).toThrow(ConfigurationError);
    });
  });

  describe('updateConfig', () => {
    it('should update configuration with valid changes', () => {
      mockFs.existsSync.mockReturnValue(false);
      
      const configManager = new ConfigManager();
      const updates = {
        migration: {
          sourceDirectory: './custom-docs',
          excludePatterns: ['*.tmp'],
          dryRun: true,
          batchSize: 5,
          resumeFile: '.custom-progress.json'
        }
      };
      
      configManager.updateConfig(updates);
      const config = configManager.getConfig();
      
      expect(config.migration.sourceDirectory).toBe('./custom-docs');
      expect(config.migration.dryRun).toBe(true);
    });

    it('should throw error for invalid configuration updates', () => {
      mockFs.existsSync.mockReturnValue(false);
      
      const configManager = new ConfigManager();
      const invalidUpdates = {
        migration: {
          batchSize: -1 // Invalid batch size
        }
      } as any;
      
      expect(() => configManager.updateConfig(invalidUpdates)).toThrow(ConfigurationError);
    });
  });

  describe('validateEnvironment', () => {
    it('should return errors for missing environment variables', () => {
      mockFs.existsSync.mockReturnValue(true); // Source directory exists
      
      // Clear environment variables
      delete process.env.SF_USERNAME;
      delete process.env.SF_PASSWORD;
      delete process.env.SF_SECURITY_TOKEN;
      
      const configManager = new ConfigManager();
      const result = configManager.validateEnvironment();
      
      expect(result.isValid).toBe(false);
      expect(result.errors).toContain('Missing required environment variable: SF_USERNAME');
      expect(result.errors).toContain('Missing required environment variable: SF_PASSWORD');
      expect(result.errors).toContain('Missing required environment variable: SF_SECURITY_TOKEN');
    });

    it('should validate successfully with all required variables', () => {
      mockFs.existsSync.mockReturnValue(true);
      
      // Set required environment variables
      process.env.SF_USERNAME = 'test@example.com';
      process.env.SF_PASSWORD = 'testpassword';
      process.env.SF_SECURITY_TOKEN = 'testtokentesttokentestt';
      
      const configManager = new ConfigManager();
      const result = configManager.validateEnvironment();
      
      expect(result.isValid).toBe(true);
      expect(result.errors).toHaveLength(0);
    });
  });

  describe('getConfigurationSummary', () => {
    it('should return masked configuration summary', () => {
      mockFs.existsSync.mockReturnValue(false);
      
      const configManager = new ConfigManager();
      const summary = configManager.getConfigurationSummary();
      
      expect(summary.salesforceOrg).toMatch(/\*+/); // Should be masked
      expect(summary.sourceDirectory).toBeDefined();
      expect(summary.batchSize).toBeGreaterThan(0);
      expect(summary.categoryRulesCount).toBeGreaterThan(0);
    });
  });
});

describe('ConfigValidator', () => {
  describe('validateSalesforceConfig', () => {
    it('should validate correct Salesforce configuration', () => {
      const config = {
        loginUrl: 'https://login.salesforce.com',
        username: 'test@example.com',
        password: 'validpassword',
        securityToken: 'validtokenvalidtokenvalid',
        apiVersion: '58.0'
      };
      
      const issues = ConfigValidator.validateSalesforceConfig(config);
      const errors = issues.filter(issue => issue.severity === 'error');
      
      expect(errors).toHaveLength(0);
    });

    it('should detect invalid login URL', () => {
      const config = {
        loginUrl: 'invalid-url',
        username: 'test@example.com',
        password: 'validpassword',
        securityToken: 'validtokenvalidtokenvalid',
        apiVersion: '58.0'
      };
      
      const issues = ConfigValidator.validateSalesforceConfig(config);
      const errors = issues.filter(issue => issue.severity === 'error');
      
      expect(errors.length).toBeGreaterThan(0);
      expect(errors[0].field).toBe('salesforce.loginUrl');
    });

    it('should detect invalid email format', () => {
      const config = {
        loginUrl: 'https://login.salesforce.com',
        username: 'invalid-email',
        password: 'validpassword',
        securityToken: 'validtokenvalidtokenvalid',
        apiVersion: '58.0'
      };
      
      const issues = ConfigValidator.validateSalesforceConfig(config);
      const errors = issues.filter(issue => issue.severity === 'error');
      
      expect(errors.length).toBeGreaterThan(0);
      expect(errors[0].field).toBe('salesforce.username');
    });
  });

  describe('validateMigrationConfig', () => {
    it('should detect non-existent source directory', () => {
      mockFs.existsSync.mockReturnValue(false);
      
      const config = {
        sourceDirectory: './non-existent-dir',
        excludePatterns: ['*.pdf'],
        dryRun: false,
        batchSize: 10,
        resumeFile: '.progress.json'
      };
      
      const issues = ConfigValidator.validateMigrationConfig(config);
      const errors = issues.filter(issue => issue.severity === 'error');
      
      expect(errors.length).toBeGreaterThan(0);
      expect(errors[0].field).toBe('migration.sourceDirectory');
    });

    it('should warn about large batch sizes', () => {
      mockFs.existsSync.mockReturnValue(true);
      mockFs.readdirSync.mockReturnValue(['test.md'] as any);
      
      const config = {
        sourceDirectory: './docs',
        excludePatterns: ['*.pdf'],
        dryRun: false,
        batchSize: 30, // Large batch size
        resumeFile: '.progress.json'
      };
      
      const issues = ConfigValidator.validateMigrationConfig(config);
      const warnings = issues.filter(issue => issue.severity === 'warning');
      
      expect(warnings.length).toBeGreaterThan(0);
      expect(warnings.some(w => w.field === 'migration.batchSize')).toBe(true);
    });
  });

  describe('generateValidationReport', () => {
    it('should generate comprehensive validation report', () => {
      const config = {
        salesforce: {
          loginUrl: 'invalid-url',
          username: 'invalid-email',
          password: 'short',
          securityToken: 'short',
          apiVersion: 'invalid'
        },
        migration: {
          sourceDirectory: './non-existent',
          excludePatterns: ['*.pdf'],
          dryRun: false,
          batchSize: 10,
          resumeFile: '.progress.json'
        },
        categoryRules: [],
        contentProcessing: {
          imageHandling: 'embed' as const,
          linkProcessing: 'convert' as const,
          codeBlockStyling: 'salesforce' as const
        }
      };
      
      mockFs.existsSync.mockReturnValue(false);
      
      const report = ConfigValidator.generateValidationReport(config);
      
      expect(report.isValid).toBe(false);
      expect(report.summary.errors).toBeGreaterThan(0);
      expect(report.issues.length).toBeGreaterThan(0);
    });
  });
});

describe('ConfigTemplate', () => {
  describe('generateTemplate', () => {
    it('should generate valid JSON template', () => {
      const template = ConfigTemplate.generateTemplate();
      
      expect(template).toContain('salesforce');
      expect(template).toContain('migration');
      expect(template).toContain('categoryRules');
      expect(template).toContain('contentProcessing');
    });
  });

  describe('generateEnvTemplate', () => {
    it('should generate environment template with required variables', () => {
      const envTemplate = ConfigTemplate.generateEnvTemplate();
      
      expect(envTemplate).toContain('SF_USERNAME');
      expect(envTemplate).toContain('SF_PASSWORD');
      expect(envTemplate).toContain('SF_SECURITY_TOKEN');
    });
  });

  describe('createQuickStartConfig', () => {
    it('should create safe quick start configuration', () => {
      const config = ConfigTemplate.createQuickStartConfig('./test-docs');
      
      expect(config.migration.sourceDirectory).toBe('./test-docs');
      expect(config.migration.dryRun).toBe(true); // Should default to dry run
      expect(config.migration.batchSize).toBeLessThanOrEqual(10); // Conservative batch size
    });
  });
});