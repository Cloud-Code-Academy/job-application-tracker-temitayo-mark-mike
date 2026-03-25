/**
 * Configuration management for the Documentation Migration system
 */

import * as path from 'path';
import * as fs from 'fs';
import Joi from 'joi';
import { config as dotenvConfig } from 'dotenv';
import { MigrationConfig, CategoryRule } from '../types';

// Export enhanced configuration classes
export { ConfigManager, ConfigurationError } from './ConfigManager';
export { ConfigValidator, ValidationIssue, ValidationReport } from './ConfigValidator';
export { ConfigTemplate } from './ConfigTemplate';

// Load environment variables
dotenvConfig();

/**
 * Configuration schema for validation
 */
const configSchema = Joi.object({
  salesforce: Joi.object({
    loginUrl: Joi.string().uri().default('https://login.salesforce.com'),
    username: Joi.string().required(),
    password: Joi.string().required(),
    securityToken: Joi.string().required(),
    apiVersion: Joi.string().default('58.0')
  }).required(),
  
  migration: Joi.object({
    sourceDirectory: Joi.string().default('./docs'),
    excludePatterns: Joi.array().items(Joi.string()).default(['*.pdf', 'private-*']),
    dryRun: Joi.boolean().default(false),
    batchSize: Joi.number().integer().min(1).max(50).default(10),
    resumeFile: Joi.string().default('.migration-progress.json')
  }).required(),
  
  categoryRules: Joi.array().items(
    Joi.object({
      pattern: Joi.object().instance(RegExp).required(),
      category: Joi.string().required(),
      subcategory: Joi.string().optional(),
      difficulty: Joi.string().valid('Beginner', 'Intermediate', 'Advanced', 'Expert').optional()
    })
  ).required(),
  
  contentProcessing: Joi.object({
    imageHandling: Joi.string().valid('embed', 'link', 'skip').default('link'),
    linkProcessing: Joi.string().valid('convert', 'preserve').default('convert'),
    codeBlockStyling: Joi.string().valid('salesforce', 'default').default('salesforce')
  }).required()
});

/**
 * Default category rules for automatic categorization
 */
const defaultCategoryRules: CategoryRule[] = [
  {
    pattern: /ARCHITECTURE|DESIGN|ADR/i,
    category: 'Architecture_and_Design',
    subcategory: 'System_Architecture',
    difficulty: 'Intermediate'
  },
  {
    pattern: /LEARNING|GUIDE|TUTORIAL|ZERO.*HERO/i,
    category: 'Learning_and_Development',
    subcategory: 'Learning_Paths',
    difficulty: 'Beginner'
  },
  {
    pattern: /TEAM|COLLABORATION|WORKFLOW/i,
    category: 'Team_Collaboration',
    subcategory: 'Workflows',
    difficulty: 'Intermediate'
  },
  {
    pattern: /USER.*GUIDE|ADMIN.*GUIDE|QUICK.*REFERENCE/i,
    category: 'User_Documentation',
    subcategory: 'End_User_Guides',
    difficulty: 'Beginner'
  },
  {
    pattern: /API|REFERENCE|TECHNICAL/i,
    category: 'User_Documentation',
    subcategory: 'API_Documentation',
    difficulty: 'Advanced'
  },
  {
    pattern: /REQUIREMENTS|SPECIFICATION|COMPLETION/i,
    category: 'Project_Specifications',
    subcategory: 'Requirements',
    difficulty: 'Intermediate'
  },
  {
    pattern: /TESTING|DEBUG|QUALITY/i,
    category: 'Learning_and_Development',
    subcategory: 'Advanced_Topics',
    difficulty: 'Advanced'
  }
];

/**
 * Create default configuration
 */
export function createDefaultConfig(): MigrationConfig {
  return {
    salesforce: {
      loginUrl: process.env.SF_LOGIN_URL || 'https://login.salesforce.com',
      username: process.env.SF_USERNAME || '',
      password: process.env.SF_PASSWORD || '',
      securityToken: process.env.SF_SECURITY_TOKEN || '',
      apiVersion: process.env.SF_API_VERSION || '58.0'
    },
    migration: {
      sourceDirectory: './docs',
      excludePatterns: ['*.pdf', 'private-*', '.*'],
      dryRun: false,
      batchSize: 10,
      resumeFile: '.migration-progress.json'
    },
    categoryRules: defaultCategoryRules,
    contentProcessing: {
      imageHandling: 'link',
      linkProcessing: 'convert',
      codeBlockStyling: 'salesforce'
    }
  };
}

/**
 * Load configuration from file or create default
 */
export function loadConfig(configPath?: string): MigrationConfig {
  let config = createDefaultConfig();
  
  if (configPath && fs.existsSync(configPath)) {
    try {
      const fileConfig = JSON.parse(fs.readFileSync(configPath, 'utf8'));
      config = { ...config, ...fileConfig };
    } catch (error) {
      throw new Error(`Failed to load configuration from ${configPath}: ${error}`);
    }
  }
  
  // Validate configuration
  const { error, value } = configSchema.validate(config, { allowUnknown: false });
  if (error) {
    throw new Error(`Configuration validation failed: ${error.message}`);
  }
  
  return value as MigrationConfig;
}

/**
 * Save configuration to file
 */
export function saveConfig(config: MigrationConfig, configPath: string): void {
  try {
    const configDir = path.dirname(configPath);
    if (!fs.existsSync(configDir)) {
      fs.mkdirSync(configDir, { recursive: true });
    }
    
    fs.writeFileSync(configPath, JSON.stringify(config, null, 2));
  } catch (error) {
    throw new Error(`Failed to save configuration to ${configPath}: ${error}`);
  }
}

/**
 * Validate required environment variables
 */
export function validateEnvironment(): void {
  const required = ['SF_USERNAME', 'SF_PASSWORD', 'SF_SECURITY_TOKEN'];
  const missing = required.filter(key => !process.env[key]);
  
  if (missing.length > 0) {
    throw new Error(`Missing required environment variables: ${missing.join(', ')}`);
  }
}