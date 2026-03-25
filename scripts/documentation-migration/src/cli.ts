#!/usr/bin/env node

/**
 * Command-line interface for the Salesforce Documentation Migrator
 */

import { Command } from 'commander';
import chalk from 'chalk';
import ora from 'ora';
import { DocumentationMigrator } from './core/DocumentationMigrator';
import { ConfigManager, ConfigValidator, ConfigTemplate } from './config';
import { validateEnvironment } from './config';
import { SalesforceClient } from './core/SalesforceClient';
import { ProgressTracker } from './core/ProgressTracker';
import * as fs from 'fs';
import * as path from 'path';

const program = new Command();

// Package information
const packageJson = JSON.parse(fs.readFileSync(path.join(__dirname, '../package.json'), 'utf8'));

program
  .name('sf-doc-migrate')
  .description('Automated tool to migrate markdown documentation to Salesforce Knowledge Base')
  .version(packageJson.version);

/**
 * Main migration command
 */
program
  .command('migrate')
  .description('Migrate documentation files to Salesforce Knowledge Base')
  .option('-s, --source <path>', 'Source directory containing markdown files', './docs')
  .option('-c, --config <path>', 'Configuration file path', './migration-config.json')
  .option('-d, --dry-run', 'Preview changes without creating articles', false)
  .option('-b, --batch-size <number>', 'Number of files to process in each batch', '10')
  .option('-v, --verbose', 'Enable verbose logging', false)
  .option('-f, --force', 'Force migration even with validation warnings', false)
  .action(async (options) => {
    const spinner = ora('Initializing migration...').start();
    
    try {
      // Load configuration
      const configManager = new ConfigManager(options.config);
      const config = configManager.getConfig();
      
      // Override config with command line options
      if (options.source) config.migration.sourceDirectory = options.source;
      if (options.dryRun) config.migration.dryRun = true;
      if (options.batchSize) config.migration.batchSize = parseInt(options.batchSize);
      
      spinner.text = 'Validating configuration...';
      
      // Validate configuration
      const configValidation = ConfigValidator.generateValidationReport(config);
      if (!configValidation.isValid) {
        spinner.fail('Configuration validation failed');
        console.error(chalk.red('Configuration errors:'));
        configValidation.issues.forEach(issue => {
          console.error(chalk.red(`  - ${issue.message}`));
        });
        process.exit(1);
      }
      
      if (configValidation.summary.warnings > 0 && !options.force) {
        spinner.warn('Configuration warnings detected');
        console.warn(chalk.yellow('Configuration warnings:'));
        configValidation.issues
          .filter(issue => issue.severity === 'warning')
          .forEach(issue => {
            console.warn(chalk.yellow(`  - ${issue.message}`));
          });
        console.log(chalk.yellow('Use --force to proceed with warnings'));
        process.exit(1);
      }
      
      // Validate environment
      spinner.text = 'Validating environment...';
      const envValidation = configManager.validateEnvironment();
      if (!envValidation.isValid) {
        spinner.fail('Environment validation failed');
        console.error(chalk.red('Environment errors:'));
        envValidation.errors.forEach(error => {
          console.error(chalk.red(`  - ${error}`));
        });
        process.exit(1);
      }
      
      // Test Salesforce connection
      spinner.text = 'Testing Salesforce connection...';
      const salesforceClient = new SalesforceClient(config.salesforce);
      const connectionTest = await salesforceClient.testConnection();
      
      if (!connectionTest.success) {
        spinner.fail('Salesforce connection failed');
        console.error(chalk.red(`Connection error: ${connectionTest.error}`));
        process.exit(1);
      }
      
      spinner.succeed('Pre-flight checks completed');
      
      // Initialize migrator
      const migrator = new DocumentationMigrator(config);
      
      // Set up progress tracking
      const progressTracker = new ProgressTracker(config.migration.resumeFile);
      
      // Check for existing progress
      if (progressTracker.hasExistingProgress()) {
        const resumeInfo = progressTracker.resumeMigration();
        console.log(chalk.blue('\nExisting migration progress found:'));
        console.log(`  Total files: ${resumeInfo.totalFiles}`);
        console.log(`  Processed: ${resumeInfo.processedFiles}`);
        console.log(`  Remaining: ${resumeInfo.remainingFiles}`);
        console.log(`  Success rate: ${((resumeInfo.successfulMigrations / resumeInfo.processedFiles) * 100).toFixed(1)}%`);
        
        const shouldResume = await promptUser('Resume existing migration? (y/n): ');
        if (!shouldResume.toLowerCase().startsWith('y')) {
          progressTracker.clearProgress();
          console.log(chalk.yellow('Starting fresh migration...'));
        }
      }
      
      // Start migration
      console.log(chalk.green('\nStarting documentation migration...'));
      console.log(`Source: ${config.migration.sourceDirectory}`);
      console.log(`Dry run: ${config.migration.dryRun ? 'Yes' : 'No'}`);
      console.log(`Batch size: ${config.migration.batchSize}`);
      
      const migrationSpinner = ora('Migrating documentation...').start();
      
      // Set up progress reporting
      const progressInterval = setInterval(() => {
        const progress = progressTracker.getProgress();
        migrationSpinner.text = `Migrating... ${progress.processedFiles}/${progress.totalFiles} files (${progress.completionPercentage.toFixed(1)}%)`;
      }, 1000);
      
      try {
        const result = await migrator.migrate({
          dryRun: config.migration.dryRun,
          verbose: options.verbose,
          progressTracker
        });
        
        clearInterval(progressInterval);
        migrationSpinner.succeed('Migration completed');
        
        // Display results
        console.log(chalk.green('\n✅ Migration Summary:'));
        console.log(`  Total files: ${result.summary.totalFiles}`);
        console.log(`  Successful: ${chalk.green(result.summary.successful)}`);
        console.log(`  Failed: ${chalk.red(result.summary.failed)}`);
        console.log(`  Skipped: ${chalk.yellow(result.summary.skipped)}`);
        console.log(`  Duration: ${formatDuration(result.summary.duration)}`);
        
        if (result.errors.length > 0) {
          console.log(chalk.red('\n❌ Errors encountered:'));
          result.errors.slice(0, 5).forEach(error => {
            console.log(chalk.red(`  - ${error.file}: ${error.error}`));
          });
          
          if (result.errors.length > 5) {
            console.log(chalk.red(`  ... and ${result.errors.length - 5} more errors`));
          }
        }
        
        // Generate comprehensive reports
        console.log(chalk.blue('\n📊 Generating comprehensive reports...'));
        
        const { ReportGenerator } = await import('./reporting/ReportGenerator');
        const reportGenerator = new ReportGenerator(result, './reports');
        
        try {
          const reportResults = await reportGenerator.generateAllReports();
          
          if (reportResults.success) {
            console.log(chalk.green('✅ Reports generated successfully:'));
            reportResults.reports.forEach(report => {
              console.log(chalk.blue(`  - ${report.type}: ${report.path}`));
            });
            
            // Generate report index
            const indexPath = reportGenerator.generateReportIndex(reportResults.reports);
            console.log(chalk.blue(`  - index: ${indexPath}`));
            
            // Display CLI summary
            const cliSummary = reportGenerator.generateCliSummary();
            console.log(chalk.green('\n📈 Migration Analytics:'));
            console.log(`  Performance: ${cliSummary.performance.throughput} (${cliSummary.performance.averageTime} avg)`);
            console.log(`  Quality Score: ${cliSummary.quality.score} (${cliSummary.quality.issues} issues, ${cliSummary.quality.warnings} warnings)`);
            console.log(`  Relationships: ${cliSummary.relationships.totalLinks} links (${cliSummary.relationships.brokenLinks} broken)`);
            
            if (cliSummary.recommendations.length > 0) {
              console.log(chalk.yellow('\n💡 Top Recommendations:'));
              cliSummary.recommendations.forEach(rec => {
                console.log(chalk.yellow(`  - ${rec}`));
              });
            }
            
          } else {
            console.log(chalk.red('❌ Report generation failed:'));
            reportResults.errors.forEach(error => {
              console.log(chalk.red(`  - ${error.message}`));
            });
          }
        } catch (reportError) {
          console.log(chalk.yellow(`⚠️  Report generation failed: ${reportError}`));
          
          // Fallback to simple JSON report
          const reportPath = `migration-report-${new Date().toISOString().split('T')[0]}.json`;
          fs.writeFileSync(reportPath, JSON.stringify(result, null, 2));
          console.log(chalk.blue(`📄 Basic report saved to: ${reportPath}`));
        }
        
      } catch (error) {
        clearInterval(progressInterval);
        migrationSpinner.fail('Migration failed');
        console.error(chalk.red(`Migration error: ${error}`));
        process.exit(1);
      }
      
    } catch (error) {
      spinner.fail('Migration initialization failed');
      console.error(chalk.red(`Error: ${error}`));
      process.exit(1);
    }
  });

/**
 * Resume migration command
 */
program
  .command('resume')
  .description('Resume an interrupted migration')
  .option('-c, --config <path>', 'Configuration file path', './migration-config.json')
  .option('-v, --verbose', 'Enable verbose logging', false)
  .action(async (options) => {
    const spinner = ora('Checking for existing migration...').start();
    
    try {
      const configManager = new ConfigManager(options.config);
      const config = configManager.getConfig();
      
      const progressTracker = new ProgressTracker(config.migration.resumeFile);
      
      if (!progressTracker.hasExistingProgress()) {
        spinner.fail('No existing migration found to resume');
        console.log(chalk.yellow('Use the "migrate" command to start a new migration'));
        process.exit(1);
      }
      
      const resumeInfo = progressTracker.resumeMigration();
      spinner.succeed('Found existing migration progress');
      
      console.log(chalk.blue('\nMigration Status:'));
      console.log(`  Total files: ${resumeInfo.totalFiles}`);
      console.log(`  Processed: ${resumeInfo.processedFiles}`);
      console.log(`  Remaining: ${resumeInfo.remainingFiles}`);
      console.log(`  Elapsed time: ${formatDuration(resumeInfo.elapsedTime)}`);
      console.log(`  Estimated remaining: ${formatDuration(resumeInfo.estimatedTimeRemaining)}`);
      
      // Resume migration using the migrate command logic
      const migrator = new DocumentationMigrator(config);
      
      console.log(chalk.green('\nResuming migration...'));
      const migrationSpinner = ora('Resuming migration...').start();
      
      try {
        const result = await migrator.resume({
          verbose: options.verbose,
          progressTracker
        });
        
        migrationSpinner.succeed('Migration resumed and completed');
        
        console.log(chalk.green('\n✅ Resume Summary:'));
        console.log(`  Additional files processed: ${result.summary.successful + result.summary.failed}`);
        console.log(`  Total successful: ${chalk.green(result.summary.successful)}`);
        console.log(`  Total failed: ${chalk.red(result.summary.failed)}`);
        
      } catch (error) {
        migrationSpinner.fail('Resume failed');
        console.error(chalk.red(`Resume error: ${error}`));
        process.exit(1);
      }
      
    } catch (error) {
      spinner.fail('Resume initialization failed');
      console.error(chalk.red(`Error: ${error}`));
      process.exit(1);
    }
  });

/**
 * Test connection command
 */
program
  .command('test-connection')
  .description('Test connection to Salesforce')
  .option('-c, --config <path>', 'Configuration file path', './migration-config.json')
  .action(async (options) => {
    const spinner = ora('Testing Salesforce connection...').start();
    
    try {
      const configManager = new ConfigManager(options.config);
      const config = configManager.getConfig();
      
      const salesforceClient = new SalesforceClient(config.salesforce);
      const result = await salesforceClient.testConnection();
      
      if (result.success) {
        spinner.succeed('Connection successful');
        console.log(chalk.green('\n✅ Connection Details:'));
        console.log(`  Organization ID: ${result.organizationId}`);
        console.log(`  User ID: ${result.userId}`);
        console.log(`  API Version: ${result.apiVersion}`);
        console.log(`  Knowledge Base accessible: ${result.knowledgeAccessible ? 'Yes' : 'No'}`);
        
        // Get API usage
        const usage = await salesforceClient.getApiUsage();
        console.log(chalk.blue('\n📊 API Usage:'));
        console.log(`  Daily API requests: ${usage.dailyApiRequests.used}/${usage.dailyApiRequests.max} (${usage.dailyApiRequests.remaining} remaining)`);
        console.log(`  Rate limit utilization: ${usage.rateLimitInfo.utilizationPercentage.toFixed(1)}%`);
        
      } else {
        spinner.fail('Connection failed');
        console.error(chalk.red(`Error: ${result.error}`));
        process.exit(1);
      }
      
    } catch (error) {
      spinner.fail('Connection test failed');
      console.error(chalk.red(`Error: ${error}`));
      process.exit(1);
    }
  });

/**
 * Validate configuration command
 */
program
  .command('validate-config')
  .description('Validate migration configuration')
  .option('-c, --config <path>', 'Configuration file path', './migration-config.json')
  .action(async (options) => {
    const spinner = ora('Validating configuration...').start();
    
    try {
      const configManager = new ConfigManager(options.config);
      const config = configManager.getConfig();
      
      const validation = ConfigValidator.generateValidationReport(config);
      
      if (validation.isValid) {
        spinner.succeed('Configuration is valid');
        
        if (validation.summary.warnings > 0) {
          console.log(chalk.yellow('\n⚠️  Warnings:'));
          validation.issues
            .filter(issue => issue.severity === 'warning')
            .forEach(issue => {
              console.log(chalk.yellow(`  - ${issue.message}`));
              if (issue.suggestion) {
                console.log(chalk.gray(`    Suggestion: ${issue.suggestion}`));
              }
            });
        }
        
        if (validation.summary.info > 0) {
          console.log(chalk.blue('\nℹ️  Information:'));
          validation.issues
            .filter(issue => issue.severity === 'info')
            .forEach(issue => {
              console.log(chalk.blue(`  - ${issue.message}`));
            });
        }
        
        console.log(chalk.green('\n✅ Configuration Summary:'));
        console.log(`  Source directory: ${config.migration.sourceDirectory}`);
        console.log(`  Batch size: ${config.migration.batchSize}`);
        console.log(`  Category rules: ${config.categoryRules.length}`);
        console.log(`  Dry run: ${config.migration.dryRun ? 'Enabled' : 'Disabled'}`);
        
      } else {
        spinner.fail('Configuration validation failed');
        console.error(chalk.red('\n❌ Errors:'));
        validation.issues
          .filter(issue => issue.severity === 'error')
          .forEach(issue => {
            console.error(chalk.red(`  - ${issue.message}`));
            if (issue.suggestion) {
              console.error(chalk.gray(`    Suggestion: ${issue.suggestion}`));
            }
          });
        process.exit(1);
      }
      
    } catch (error) {
      spinner.fail('Configuration validation failed');
      console.error(chalk.red(`Error: ${error}`));
      process.exit(1);
    }
  });

/**
 * Initialize configuration command
 */
program
  .command('init-config')
  .description('Generate default configuration files')
  .option('-o, --output <path>', 'Output directory for configuration files', '.')
  .option('-f, --force', 'Overwrite existing files', false)
  .action(async (options) => {
    const spinner = ora('Generating configuration files...').start();
    
    try {
      const outputDir = path.resolve(options.output);
      
      // Check if files already exist
      const configPath = path.join(outputDir, 'migration-config.json');
      const envPath = path.join(outputDir, '.env');
      
      if (!options.force) {
        if (fs.existsSync(configPath)) {
          spinner.fail('Configuration file already exists');
          console.error(chalk.red(`File exists: ${configPath}`));
          console.log(chalk.yellow('Use --force to overwrite existing files'));
          process.exit(1);
        }
        
        if (fs.existsSync(envPath)) {
          spinner.fail('Environment file already exists');
          console.error(chalk.red(`File exists: ${envPath}`));
          console.log(chalk.yellow('Use --force to overwrite existing files'));
          process.exit(1);
        }
      }
      
      // Generate configuration files
      ConfigTemplate.createTemplateFiles(outputDir);
      
      spinner.succeed('Configuration files generated');
      
      console.log(chalk.green('\n✅ Generated Files:'));
      console.log(`  Configuration: ${chalk.blue(configPath)}`);
      console.log(`  Environment: ${chalk.blue(envPath)}`);
      console.log(`  Setup guide: ${chalk.blue(path.join(outputDir, 'SETUP.md'))}`);
      
      console.log(chalk.yellow('\n⚠️  Next Steps:'));
      console.log('  1. Copy .env.template to .env and update with your Salesforce credentials');
      console.log('  2. Review and customize migration-config.template.json');
      console.log('  3. Run "sf-doc-migrate validate-config" to verify your configuration');
      console.log('  4. Run "sf-doc-migrate test-connection" to verify Salesforce connectivity');
      
    } catch (error) {
      spinner.fail('Configuration generation failed');
      console.error(chalk.red(`Error: ${error}`));
      process.exit(1);
    }
  });

/**
 * Status command
 */
program
  .command('status')
  .description('Show current migration status')
  .option('-c, --config <path>', 'Configuration file path', './migration-config.json')
  .action(async (options) => {
    try {
      const configManager = new ConfigManager(options.config);
      const config = configManager.getConfig();
      
      const progressTracker = new ProgressTracker(config.migration.resumeFile);
      
      if (!progressTracker.hasExistingProgress()) {
        console.log(chalk.yellow('No active migration found'));
        console.log('Use "sf-doc-migrate migrate" to start a new migration');
        return;
      }
      
      const progress = progressTracker.getProgress();
      const report = progressTracker.generateProgressReport();
      
      console.log(chalk.blue('📊 Migration Status\n'));
      
      console.log(chalk.green('Progress:'));
      console.log(`  Total files: ${progress.totalFiles}`);
      console.log(`  Processed: ${progress.processedFiles} (${progress.completionPercentage.toFixed(1)}%)`);
      console.log(`  Successful: ${chalk.green(progress.successfulMigrations)}`);
      console.log(`  Failed: ${chalk.red(progress.failedMigrations)}`);
      console.log(`  Skipped: ${chalk.yellow(progress.skippedFiles)}`);
      
      console.log(chalk.blue('\nTiming:'));
      console.log(`  Elapsed: ${formatDuration(progress.elapsedTime)}`);
      console.log(`  Estimated remaining: ${formatDuration(progress.estimatedTimeRemaining)}`);
      console.log(`  Average per file: ${formatDuration(progress.averageTimePerFile)}`);
      
      console.log(chalk.blue('\nPerformance:'));
      console.log(`  Files per minute: ${report.performance.filesPerMinute.toFixed(1)}`);
      console.log(`  Health status: ${getHealthStatusColor(report.status.healthStatus)}${report.status.healthStatus}${chalk.reset()}`);
      
      if (progress.isComplete) {
        console.log(chalk.green('\n✅ Migration completed!'));
      } else {
        console.log(chalk.yellow('\n⏸️  Migration can be resumed with "sf-doc-migrate resume"'));
      }
      
    } catch (error) {
      console.error(chalk.red(`Error: ${error}`));
      process.exit(1);
    }
  });

/**
 * Analyze relationships command
 */
program
  .command('analyze-relationships')
  .description('Analyze document relationships and cross-references')
  .option('-s, --source <path>', 'Source directory containing markdown files', './docs')
  .option('-c, --config <path>', 'Configuration file path', './migration-config.json')
  .option('-o, --output <path>', 'Output file for relationship report', './relationship-report.json')
  .option('-v, --verbose', 'Enable verbose logging', false)
  .action(async (options) => {
    const spinner = ora('Analyzing document relationships...').start();
    
    try {
      const configManager = new ConfigManager(options.config);
      const config = configManager.getConfig();
      
      // Override source directory if provided
      if (options.source) {
        config.migration.sourceDirectory = options.source;
      }
      
      const migrator = new DocumentationMigrator(config);
      
      // Get relationship data
      const relationshipData = migrator.exportRelationshipData();
      
      spinner.succeed('Relationship analysis completed');
      
      // Display summary
      console.log(chalk.green('\n📊 Relationship Analysis Summary:'));
      console.log(`  Total documents: ${relationshipData.documentGraph.nodes.length}`);
      console.log(`  Total relationships: ${relationshipData.documentGraph.edges.length}`);
      console.log(`  Cross-references found: ${Object.keys(relationshipData.crossReferences).length}`);
      console.log(`  Related articles identified: ${Object.keys(relationshipData.relatedArticles).length}`);
      
      // Save detailed report
      fs.writeFileSync(options.output, JSON.stringify(relationshipData, null, 2));
      console.log(chalk.blue(`\n📄 Detailed report saved to: ${options.output}`));
      
      if (options.verbose) {
        console.log(chalk.blue('\n🔗 Top Connected Documents:'));
        const topConnected = relationshipData.documentGraph.nodes
          .sort((a: any, b: any) => (b.connections || 0) - (a.connections || 0))
          .slice(0, 5);
        
        topConnected.forEach((doc: any, index: number) => {
          console.log(`  ${index + 1}. ${doc.data.title} (${doc.connections || 0} connections)`);
        });
      }
      
    } catch (error) {
      spinner.fail('Relationship analysis failed');
      console.error(chalk.red(`Error: ${error}`));
      process.exit(1);
    }
  });

/**
 * Generate comprehensive reports command
 */
program
  .command('generate-reports')
  .description('Generate comprehensive migration reports from existing migration data')
  .option('-i, --input <path>', 'Input migration report JSON file', './migration-report.json')
  .option('-o, --output <path>', 'Output directory for reports', './reports')
  .option('-t, --type <type>', 'Specific report type to generate (json|html|dashboard|executive-summary|validation|url-mappings)', 'all')
  .option('-v, --verbose', 'Enable verbose logging', false)
  .action(async (options) => {
    const spinner = ora('Generating reports...').start();
    
    try {
      // Check if input file exists
      if (!fs.existsSync(options.input)) {
        spinner.fail('Input migration report file not found');
        console.error(chalk.red(`File not found: ${options.input}`));
        console.log(chalk.yellow('Run a migration first to generate the base report data'));
        process.exit(1);
      }
      
      // Load migration report
      const migrationReport = JSON.parse(fs.readFileSync(options.input, 'utf8'));
      
      const { ReportGenerator } = await import('./reporting/ReportGenerator');
      const reportGenerator = new ReportGenerator(migrationReport, options.output);
      
      if (options.type === 'all') {
        // Generate all reports
        const results = await reportGenerator.generateAllReports();
        
        if (results.success) {
          spinner.succeed('All reports generated successfully');
          
          console.log(chalk.green('\n📊 Generated Reports:'));
          results.reports.forEach(report => {
            console.log(chalk.blue(`  ✅ ${report.type}: ${report.path} (${formatFileSize(report.size)})`));
          });
          
          // Generate index
          const indexPath = reportGenerator.generateReportIndex(results.reports);
          console.log(chalk.blue(`  📋 Index: ${indexPath}`));
          
          // Show CLI summary
          const summary = reportGenerator.generateCliSummary();
          console.log(chalk.green('\n📈 Quick Summary:'));
          console.log(`  Success Rate: ${summary.overview.successRate}`);
          console.log(`  Quality Score: ${summary.quality.score}`);
          console.log(`  Processing Time: ${summary.overview.duration}`);
          
        } else {
          spinner.fail('Report generation failed');
          results.errors.forEach(error => {
            console.error(chalk.red(`  - ${error.message}`));
          });
          process.exit(1);
        }
        
      } else {
        // Generate specific report type
        const reportPath = await reportGenerator.generateReport(options.type as any);
        spinner.succeed(`${options.type} report generated`);
        console.log(chalk.blue(`📄 Report saved to: ${reportPath}`));
      }
      
    } catch (error) {
      spinner.fail('Report generation failed');
      console.error(chalk.red(`Error: ${error}`));
      process.exit(1);
    }
  });

/**
 * Generate URL mapping report command
 */
program
  .command('generate-url-mappings')
  .description('Generate URL mapping report for redirects')
  .option('-c, --config <path>', 'Configuration file path', './migration-config.json')
  .option('-o, --output <path>', 'Output file for URL mapping report', './url-mappings.json')
  .option('-f, --format <type>', 'Output format (json|nginx|apache)', 'json')
  .action(async (options) => {
    const spinner = ora('Generating URL mapping report...').start();
    
    try {
      const configManager = new ConfigManager(options.config);
      const config = configManager.getConfig();
      
      const migrator = new DocumentationMigrator(config);
      const urlMappingReport = migrator.generateUrlMappingReport();
      
      spinner.succeed('URL mapping report generated');
      
      if (options.format === 'json') {
        fs.writeFileSync(options.output, JSON.stringify(urlMappingReport, null, 2));
        console.log(chalk.blue(`📄 JSON report saved to: ${options.output}`));
      } else if (options.format === 'nginx') {
        const nginxConfig = generateNginxRedirects(urlMappingReport.redirectRules);
        const nginxPath = options.output.replace('.json', '.nginx.conf');
        fs.writeFileSync(nginxPath, nginxConfig);
        console.log(chalk.blue(`🔧 Nginx config saved to: ${nginxPath}`));
      } else if (options.format === 'apache') {
        const apacheConfig = generateApacheRedirects(urlMappingReport.redirectRules);
        const apachePath = options.output.replace('.json', '.htaccess');
        fs.writeFileSync(apachePath, apacheConfig);
        console.log(chalk.blue(`🔧 Apache config saved to: ${apachePath}`));
      }
      
      console.log(chalk.green('\n📊 URL Mapping Summary:'));
      console.log(`  Total mappings: ${urlMappingReport.totalMappings}`);
      console.log(`  Redirect rules: ${urlMappingReport.redirectRules.length}`);
      console.log(`  Broken relationships: ${urlMappingReport.brokenRelationships.length}`);
      
      if (urlMappingReport.brokenRelationships.length > 0) {
        console.log(chalk.yellow('\n⚠️  Broken relationships detected:'));
        urlMappingReport.brokenRelationships.slice(0, 5).forEach((broken: any) => {
          console.log(chalk.yellow(`  - ${broken.sourceFile} → ${broken.targetFile}`));
        });
        
        if (urlMappingReport.brokenRelationships.length > 5) {
          console.log(chalk.yellow(`  ... and ${urlMappingReport.brokenRelationships.length - 5} more`));
        }
      }
      
    } catch (error) {
      spinner.fail('URL mapping generation failed');
      console.error(chalk.red(`Error: ${error}`));
      process.exit(1);
    }
  });

/**
 * Clean command
 */
program
  .command('clean')
  .description('Clean up migration progress and temporary files')
  .option('-c, --config <path>', 'Configuration file path', './migration-config.json')
  .option('-f, --force', 'Force cleanup without confirmation', false)
  .action(async (options) => {
    try {
      const configManager = new ConfigManager(options.config);
      const config = configManager.getConfig();
      
      const progressTracker = new ProgressTracker(config.migration.resumeFile);
      
      if (!progressTracker.hasExistingProgress()) {
        console.log(chalk.yellow('No migration progress found to clean'));
        return;
      }
      
      if (!options.force) {
        const shouldClean = await promptUser('This will delete all migration progress. Continue? (y/n): ');
        if (!shouldClean.toLowerCase().startsWith('y')) {
          console.log(chalk.yellow('Cleanup cancelled'));
          return;
        }
      }
      
      progressTracker.clearProgress();
      
      // Clean up any report files
      const reportFiles = fs.readdirSync('.')
        .filter(file => file.startsWith('migration-report-') && file.endsWith('.json'));
      
      reportFiles.forEach(file => {
        try {
          fs.unlinkSync(file);
          console.log(chalk.gray(`Removed: ${file}`));
        } catch (error) {
          console.warn(chalk.yellow(`Could not remove: ${file}`));
        }
      });
      
      console.log(chalk.green('✅ Cleanup completed'));
      
    } catch (error) {
      console.error(chalk.red(`Error: ${error}`));
      process.exit(1);
    }
  });

// Helper functions

function generateNginxRedirects(redirectRules: any[]): string {
  const header = `# Nginx redirect configuration for migrated documentation
# Generated on ${new Date().toISOString()}
# Add these rules to your nginx server configuration

`;

  const rules = redirectRules.map(rule => 
    `location = ${rule.from} { return ${rule.status} ${rule.to}; }`
  ).join('\n');

  return header + rules + '\n';
}

function generateApacheRedirects(redirectRules: any[]): string {
  const header = `# Apache redirect configuration for migrated documentation
# Generated on ${new Date().toISOString()}
# Add these rules to your .htaccess file

RewriteEngine On

`;

  const rules = redirectRules.map(rule => 
    `RewriteRule ^${rule.from.replace(/^\//, '').replace(/\//g, '\\/')}$ ${rule.to} [R=${rule.status},L]`
  ).join('\n');

  return header + rules + '\n';
}

function formatDuration(ms: number): string {
  if (ms < 1000) return `${ms}ms`;
  if (ms < 60000) return `${(ms / 1000).toFixed(1)}s`;
  if (ms < 3600000) return `${(ms / 60000).toFixed(1)}m`;
  return `${(ms / 3600000).toFixed(1)}h`;
}

function formatFileSize(bytes: number): string {
  if (bytes === 0) return '0 B';
  const k = 1024;
  const sizes = ['B', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i];
}

function getHealthStatusColor(status: string): string {
  switch (status) {
    case 'healthy': return chalk.green.bold;
    case 'warning': return chalk.yellow.bold;
    case 'error': return chalk.red.bold;
    default: return chalk.gray.bold;
  }
}

async function promptUser(question: string): Promise<string> {
  const readline = require('readline');
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
  });
  
  return new Promise((resolve) => {
    rl.question(question, (answer: string) => {
      rl.close();
      resolve(answer);
    });
  });
}

// Error handling
process.on('uncaughtException', (error) => {
  console.error(chalk.red('\n💥 Uncaught Exception:'));
  console.error(error);
  process.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
  console.error(chalk.red('\n💥 Unhandled Rejection:'));
  console.error('Promise:', promise);
  console.error('Reason:', reason);
  process.exit(1);
});

// Graceful shutdown
process.on('SIGINT', () => {
  console.log(chalk.yellow('\n\n⏹️  Migration interrupted by user'));
  console.log(chalk.blue('Progress has been saved. Use "sf-doc-migrate resume" to continue.'));
  process.exit(0);
});

process.on('SIGTERM', () => {
  console.log(chalk.yellow('\n\n⏹️  Migration terminated'));
  console.log(chalk.blue('Progress has been saved. Use "sf-doc-migrate resume" to continue.'));
  process.exit(0);
});

// Parse command line arguments
program.parse();

// Show help if no command provided
if (!process.argv.slice(2).length) {
  program.outputHelp();
}