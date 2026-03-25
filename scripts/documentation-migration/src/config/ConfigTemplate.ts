/**
 * Configuration template generator for easy setup
 */

import * as fs from 'fs';
import * as path from 'path';
import { MigrationConfig } from '../types';
import { createDefaultConfig } from './index';

export class ConfigTemplate {
  
  /**
   * Generate a complete configuration template with comments
   */
  public static generateTemplate(): string {
    const template = `{
  // Salesforce connection configuration
  "salesforce": {
    // Salesforce login URL (use https://test.salesforce.com for sandbox)
    "loginUrl": "https://login.salesforce.com",
    
    // Your Salesforce username (email format)
    "username": "\${SF_USERNAME}",
    
    // Your Salesforce password
    "password": "\${SF_PASSWORD}",
    
    // Your Salesforce security token (get from Setup > My Personal Information > Reset Security Token)
    "securityToken": "\${SF_SECURITY_TOKEN}",
    
    // Salesforce API version to use
    "apiVersion": "58.0"
  },
  
  // Migration process settings
  "migration": {
    // Source directory containing markdown files to migrate
    "sourceDirectory": "./docs",
    
    // File patterns to exclude from migration
    "excludePatterns": [
      "*.pdf",           // Skip PDF files
      "private-*",       // Skip files starting with 'private-'
      ".*",             // Skip hidden files
      "node_modules/**", // Skip node_modules directory
      "*.tmp"           // Skip temporary files
    ],
    
    // Set to true to preview changes without actually creating articles
    "dryRun": false,
    
    // Number of files to process in each batch (recommended: 5-15)
    "batchSize": 10,
    
    // File to store migration progress for resume capability
    "resumeFile": ".migration-progress.json"
  },
  
  // Rules for automatically categorizing articles
  "categoryRules": [
    {
      // Files with architecture/design keywords
      "pattern": "ARCHITECTURE|DESIGN|ADR",
      "patternFlags": "i",
      "category": "Architecture_and_Design",
      "subcategory": "System_Architecture",
      "difficulty": "Intermediate"
    },
    {
      // Learning guides and tutorials
      "pattern": "LEARNING|GUIDE|TUTORIAL|ZERO.*HERO",
      "patternFlags": "i", 
      "category": "Learning_and_Development",
      "subcategory": "Learning_Paths",
      "difficulty": "Beginner"
    },
    {
      // Team collaboration documents
      "pattern": "TEAM|COLLABORATION|WORKFLOW",
      "patternFlags": "i",
      "category": "Team_Collaboration", 
      "subcategory": "Workflows",
      "difficulty": "Intermediate"
    },
    {
      // User documentation
      "pattern": "USER.*GUIDE|ADMIN.*GUIDE|QUICK.*REFERENCE",
      "patternFlags": "i",
      "category": "User_Documentation",
      "subcategory": "End_User_Guides", 
      "difficulty": "Beginner"
    },
    {
      // API and technical references
      "pattern": "API|REFERENCE|TECHNICAL",
      "patternFlags": "i",
      "category": "User_Documentation",
      "subcategory": "API_Documentation",
      "difficulty": "Advanced"
    },
    {
      // Project specifications
      "pattern": "REQUIREMENTS|SPECIFICATION|COMPLETION",
      "patternFlags": "i",
      "category": "Project_Specifications",
      "subcategory": "Requirements",
      "difficulty": "Intermediate"
    },
    {
      // Testing and debugging guides
      "pattern": "TESTING|DEBUG|QUALITY",
      "patternFlags": "i",
      "category": "Learning_and_Development",
      "subcategory": "Advanced_Topics",
      "difficulty": "Advanced"
    }
  ],
  
  // Content processing options
  "contentProcessing": {
    // How to handle images: "embed" (base64), "link" (preserve URLs), "skip" (remove)
    "imageHandling": "link",
    
    // How to handle internal links: "convert" (to Knowledge articles), "preserve" (keep original)
    "linkProcessing": "convert",
    
    // Code block styling: "salesforce" (optimized for SF), "default" (preserve original)
    "codeBlockStyling": "salesforce"
  }
}`;

    return template;
  }

  /**
   * Generate environment file template
   */
  public static generateEnvTemplate(): string {
    return `# Salesforce Configuration
# Get these values from your Salesforce org

# Your Salesforce username (email format)
SF_USERNAME=your-username@company.com

# Your Salesforce password
SF_PASSWORD=your-password-here

# Your Salesforce security token
# Get this from Setup > My Personal Information > Reset Security Token
SF_SECURITY_TOKEN=your-security-token-here

# Salesforce login URL
# Use https://login.salesforce.com for production
# Use https://test.salesforce.com for sandbox
SF_LOGIN_URL=https://login.salesforce.com

# Salesforce API version (optional, defaults to 58.0)
SF_API_VERSION=58.0

# Migration Settings (optional)
MIGRATION_SOURCE_DIR=./docs
MIGRATION_DRY_RUN=false
MIGRATION_BATCH_SIZE=10

# Logging (optional)
LOG_LEVEL=info
LOG_FILE=migration.log`;
  }

  /**
   * Generate setup instructions
   */
  public static generateSetupInstructions(): string {
    return `# Documentation Migration Setup Guide

## Prerequisites

1. **Node.js**: Version 16 or higher
2. **Salesforce Org**: With Knowledge Base enabled
3. **Salesforce Credentials**: Username, password, and security token

## Setup Steps

### 1. Install Dependencies
\`\`\`bash
npm install
\`\`\`

### 2. Configure Environment Variables
Copy the example environment file and update with your credentials:
\`\`\`bash
cp .env.example .env
\`\`\`

Edit \`.env\` file with your Salesforce credentials:
- **SF_USERNAME**: Your Salesforce username (email format)
- **SF_PASSWORD**: Your Salesforce password  
- **SF_SECURITY_TOKEN**: Get from Setup > My Personal Information > Reset Security Token

### 3. Generate Configuration File (Optional)
\`\`\`bash
npm run dev init-config
\`\`\`

This creates a \`migration-config.json\` file you can customize.

### 4. Validate Configuration
\`\`\`bash
npm run dev validate-config
\`\`\`

### 5. Test Connection
\`\`\`bash
npm run dev test-connection
\`\`\`

### 6. Run Migration
\`\`\`bash
# Dry run first (preview only)
npm run dev migrate --dry-run

# Actual migration
npm run dev migrate
\`\`\`

## Troubleshooting

### Common Issues

1. **Invalid Login**: Check username, password, and security token
2. **API Limits**: Reduce batch size in configuration
3. **Permission Errors**: Ensure user has Knowledge Base permissions
4. **Network Issues**: Check firewall and proxy settings

### Getting Help

- Check the logs in \`migration.log\`
- Run with \`--verbose\` flag for detailed output
- Use \`--dry-run\` to preview changes safely

## Configuration Options

See \`migration-config.json\` for detailed configuration options including:
- Source directory settings
- Category mapping rules  
- Content processing options
- Batch processing settings`;
  }

  /**
   * Create all template files in a directory
   */
  public static createTemplateFiles(targetDir: string): void {
    // Ensure target directory exists
    if (!fs.existsSync(targetDir)) {
      fs.mkdirSync(targetDir, { recursive: true });
    }

    // Create configuration template
    const configPath = path.join(targetDir, 'migration-config.template.json');
    fs.writeFileSync(configPath, this.generateTemplate());

    // Create environment template
    const envPath = path.join(targetDir, '.env.template');
    fs.writeFileSync(envPath, this.generateEnvTemplate());

    // Create setup instructions
    const setupPath = path.join(targetDir, 'SETUP.md');
    fs.writeFileSync(setupPath, this.generateSetupInstructions());
  }

  /**
   * Parse template configuration (convert string patterns to RegExp)
   */
  public static parseTemplateConfig(templateConfig: any): MigrationConfig {
    const config = { ...templateConfig };
    
    // Convert category rule patterns from strings to RegExp
    if (config.categoryRules) {
      config.categoryRules = config.categoryRules.map((rule: any) => ({
        ...rule,
        pattern: new RegExp(rule.pattern, rule.patternFlags || 'i')
      }));
    }

    return config as MigrationConfig;
  }

  /**
   * Create a minimal configuration for quick start
   */
  public static createQuickStartConfig(sourceDir: string = './docs'): MigrationConfig {
    const defaultConfig = createDefaultConfig();
    
    return {
      ...defaultConfig,
      migration: {
        ...defaultConfig.migration,
        sourceDirectory: sourceDir,
        dryRun: true, // Start with dry run for safety
        batchSize: 5   // Conservative batch size
      }
    };
  }
}