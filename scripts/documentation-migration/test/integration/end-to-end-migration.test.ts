/**
 * End-to-end integration tests for the complete migration flow
 */

import * as fs from 'fs';
import * as path from 'path';
import { DocumentationMigrator } from '../../src/core/DocumentationMigrator';
import { ConfigManager } from '../../src/config/ConfigManager';
import { ProgressTracker } from '../../src/core/ProgressTracker';
import { MigrationConfig } from '../../src/types';

describe('End-to-End Migration Flow', () => {
  const testDocsDir = path.join(__dirname, '../fixtures/sample-docs');
  const tempDir = path.join(__dirname, '../fixtures/temp-e2e');
  const configPath = path.join(tempDir, 'test-config.json');
  const progressPath = path.join(tempDir, 'progress.json');
  
  let migrator: DocumentationMigrator;
  let config: MigrationConfig;

  beforeAll(async () => {
    // Ensure temp directory exists
    if (!fs.existsSync(tempDir)) {
      fs.mkdirSync(tempDir, { recursive: true });
    }

    // Create test configuration
    config = {
      salesforce: {
        loginUrl: 'https://test.salesforce.com',
        username: 'test@example.com',
        password: 'testpassword',
        securityToken: 'testtoken123',
        apiVersion: '58.0'
      },
      migration: {
        sourceDirectory: testDocsDir,
        excludePatterns: ['*.tmp', 'draft-*'],
        dryRun: true, // Use dry run for testing
        batchSize: 3,
        resumeFile: progressPath
      },
      categoryRules: [
        {
          pattern: /tutorial|getting-started/i,
          category: 'Tutorial',
          subcategory: 'Getting_Started'
        },
        {
          pattern: /api|reference/i,
          category: 'Reference',
          subcategory: 'API_Documentation'
        },
        {
          pattern: /troubleshooting|support/i,
          category: 'Support',
          subcategory: 'Troubleshooting'
        },
        {
          pattern: /advanced|features/i,
          category: 'Advanced',
          subcategory: 'Advanced_Features'
        }
      ],
      contentProcessing: {
        imageHandling: 'embed',
        linkProcessing: 'convert',
        codeBlockStyling: 'salesforce'
      }
    };

    // Save configuration
    fs.writeFileSync(configPath, JSON.stringify(config, null, 2));

    // Initialize migrator
    migrator = new DocumentationMigrator(config);
  });

  afterAll(async () => {
    // Clean up temp files
    if (fs.existsSync(tempDir)) {
      fs.rmSync(tempDir, { recursive: true, force: true });
    }
  });

  describe('Complete Migration Process', () => {
    it('should perform a complete migration with all components working together', async () => {
      // Mock Salesforce client to avoid actual API calls
      const mockSalesforceClient = {
        authenticate: jest.fn().mockResolvedValue(true),
        testConnection: jest.fn().mockResolvedValue({ success: true }),
        findExistingArticle: jest.fn().mockResolvedValue(null),
        createKnowledgeArticle: jest.fn().mockImplementation((data) => ({
          success: true,
          articleId: `ka${Math.random().toString(36).substr(2, 15)}`,
          knowledgeArticleId: `kav${Math.random().toString(36).substr(2, 15)}`,
          urlName: data.UrlName,
          publishStatus: 'Draft',
          versionNumber: 1
        })),
        updateKnowledgeArticle: jest.fn().mockImplementation((id, data) => ({
          success: true,
          articleId: id,
          knowledgeArticleId: `kav${Math.random().toString(36).substr(2, 15)}`,
          urlName: data.UrlName,
          publishStatus: 'Draft',
          versionNumber: 2
        }))
      };

      // Replace the Salesforce client
      (migrator as any).salesforceClient = mockSalesforceClient;

      // Run the migration
      const startTime = Date.now();
      const result = await migrator.migrate({
        dryRun: false,
        verbose: true
      });
      const duration = Date.now() - startTime;

      // Verify migration results
      expect(result).toBeDefined();
      expect(result.summary).toBeDefined();
      expect(result.summary.totalFiles).toBeGreaterThan(0);
      expect(result.summary.duration).toBeGreaterThan(0);
      expect(result.summary.duration).toBeLessThan(30000); // Should complete within 30 seconds

      // Verify all files were processed
      expect(result.summary.totalFiles).toBe(result.summary.successful + result.summary.failed + result.summary.skipped);

      // Verify results structure
      expect(result.results).toBeDefined();
      expect(Array.isArray(result.results)).toBe(true);
      expect(result.results.length).toBe(result.summary.totalFiles);

      // Verify URL mappings were created
      expect(result.urlMappings).toBeDefined();
      expect(Object.keys(result.urlMappings).length).toBeGreaterThan(0);

      // Verify relationship analysis was performed
      expect(result.relationshipReport).toBeDefined();
      expect(result.relationshipReport.summary).toBeDefined();

      // Verify performance metrics
      expect(result.performanceReport).toBeDefined();
      expect(result.performanceReport.batchProcessing).toBeDefined();
      expect(result.performanceReport.memoryUsage).toBeDefined();

      // Verify error handling
      expect(result.errorReport).toBeDefined();

      // Verify progress tracking
      expect(result.progressReport).toBeDefined();

      console.log('Migration completed successfully:', {
        totalFiles: result.summary.totalFiles,
        successful: result.summary.successful,
        failed: result.summary.failed,
        duration: `${duration}ms`,
        averageTimePerFile: `${Math.round(duration / result.summary.totalFiles)}ms`
      });
    }, 60000); // 60 second timeout

    it('should handle resume functionality correctly', async () => {
      // Create initial progress
      const progressTracker = new ProgressTracker(progressPath);
      progressTracker.startMigration(5);
      
      // Simulate partial completion
      progressTracker.recordFileProcessed('file1.md', {
        success: true,
        filePath: 'file1.md',
        urlName: 'file1',
        action: 'created',
        warnings: []
      });
      
      progressTracker.recordFileProcessed('file2.md', {
        success: false,
        filePath: 'file2.md',
        urlName: 'file2',
        action: 'failed',
        error: 'Test error',
        warnings: []
      });

      // Mock Salesforce client
      const mockSalesforceClient = {
        authenticate: jest.fn().mockResolvedValue(true),
        testConnection: jest.fn().mockResolvedValue({ success: true }),
        findExistingArticle: jest.fn().mockResolvedValue(null),
        createKnowledgeArticle: jest.fn().mockResolvedValue({
          success: true,
          articleId: 'test123',
          knowledgeArticleId: 'kav123',
          urlName: 'test',
          publishStatus: 'Draft',
          versionNumber: 1
        })
      };

      (migrator as any).salesforceClient = mockSalesforceClient;

      // Test resume functionality
      const resumeResult = await migrator.resume({
        verbose: true,
        progressTracker
      });

      expect(resumeResult).toBeDefined();
      expect(resumeResult.summary).toBeDefined();
      
      // Should process remaining files
      expect(resumeResult.summary.totalFiles).toBeGreaterThan(0);
    }, 30000);

    it('should validate setup before migration', async () => {
      const validation = await migrator.validateSetup();

      expect(validation).toBeDefined();
      expect(validation.isValid).toBeDefined();
      expect(validation.issues).toBeDefined();
      expect(validation.warnings).toBeDefined();
      expect(Array.isArray(validation.issues)).toBe(true);
      expect(Array.isArray(validation.warnings)).toBe(true);

      // In dry run mode with mocked client, should be valid
      if (!validation.isValid) {
        console.log('Validation issues:', validation.issues);
        console.log('Validation warnings:', validation.warnings);
      }
    });

    it('should generate comprehensive statistics', () => {
      const stats = migrator.getStatistics();

      expect(stats).toBeDefined();
      expect(stats.errorStats).toBeDefined();
      expect(stats.linkMappingStats).toBeDefined();
      expect(stats.relationshipStats).toBeDefined();
    });

    it('should generate URL mapping report', () => {
      const urlMappingReport = migrator.generateUrlMappingReport();

      expect(urlMappingReport).toBeDefined();
      expect(urlMappingReport.totalMappings).toBeDefined();
      expect(urlMappingReport.mappings).toBeDefined();
      expect(urlMappingReport.redirectRules).toBeDefined();
      expect(urlMappingReport.generatedAt).toBeDefined();
      expect(Array.isArray(urlMappingReport.redirectRules)).toBe(true);
    });

    it('should export relationship data', () => {
      const relationshipData = migrator.exportRelationshipData();

      expect(relationshipData).toBeDefined();
      expect(relationshipData.documentGraph).toBeDefined();
      expect(relationshipData.crossReferences).toBeDefined();
      expect(relationshipData.relatedArticles).toBeDefined();
      expect(relationshipData.linkMappings).toBeDefined();
      expect(relationshipData.generatedAt).toBeDefined();
    });
  });

  describe('Error Handling and Edge Cases', () => {
    it('should handle missing source directory gracefully', async () => {
      const invalidConfig = {
        ...config,
        migration: {
          ...config.migration,
          sourceDirectory: '/nonexistent/directory'
        }
      };

      const invalidMigrator = new DocumentationMigrator(invalidConfig);
      
      await expect(invalidMigrator.migrate()).rejects.toThrow();
    });

    it('should handle empty source directory', async () => {
      const emptyDir = path.join(tempDir, 'empty');
      if (!fs.existsSync(emptyDir)) {
        fs.mkdirSync(emptyDir, { recursive: true });
      }

      const emptyConfig = {
        ...config,
        migration: {
          ...config.migration,
          sourceDirectory: emptyDir
        }
      };

      const emptyMigrator = new DocumentationMigrator(emptyConfig);
      
      await expect(emptyMigrator.migrate()).rejects.toThrow('No markdown files found');
    });

    it('should handle Salesforce authentication failures', async () => {
      const mockFailingClient = {
        authenticate: jest.fn().mockRejectedValue(new Error('Authentication failed')),
        testConnection: jest.fn().mockResolvedValue({ success: false, error: 'Auth failed' })
      };

      (migrator as any).salesforceClient = mockFailingClient;

      await expect(migrator.migrate()).rejects.toThrow();
    });

    it('should handle individual file processing errors gracefully', async () => {
      // Create a file with invalid content
      const invalidFile = path.join(testDocsDir, 'invalid-test.md');
      fs.writeFileSync(invalidFile, 'Invalid content with \x00 null bytes');

      const mockSalesforceClient = {
        authenticate: jest.fn().mockResolvedValue(true),
        testConnection: jest.fn().mockResolvedValue({ success: true }),
        findExistingArticle: jest.fn().mockResolvedValue(null),
        createKnowledgeArticle: jest.fn().mockImplementation((data) => {
          if (data.Title.includes('invalid')) {
            throw new Error('Invalid content');
          }
          return {
            success: true,
            articleId: 'test123',
            knowledgeArticleId: 'kav123',
            urlName: data.UrlName,
            publishStatus: 'Draft',
            versionNumber: 1
          };
        })
      };

      (migrator as any).salesforceClient = mockSalesforceClient;

      const result = await migrator.migrate({
        dryRun: false,
        verbose: false
      });

      // Should complete despite individual file errors
      expect(result).toBeDefined();
      expect(result.summary.totalFiles).toBeGreaterThan(0);
      
      // Clean up
      if (fs.existsSync(invalidFile)) {
        fs.unlinkSync(invalidFile);
      }
    });
  });

  describe('Performance and Scalability', () => {
    it('should handle batch processing efficiently', async () => {
      const batchConfig = {
        ...config,
        migration: {
          ...config.migration,
          batchSize: 2 // Small batch size for testing
        }
      };

      const batchMigrator = new DocumentationMigrator(batchConfig);
      
      const mockSalesforceClient = {
        authenticate: jest.fn().mockResolvedValue(true),
        testConnection: jest.fn().mockResolvedValue({ success: true }),
        findExistingArticle: jest.fn().mockResolvedValue(null),
        createKnowledgeArticle: jest.fn().mockImplementation((data) => ({
          success: true,
          articleId: `ka${Math.random().toString(36).substr(2, 15)}`,
          knowledgeArticleId: `kav${Math.random().toString(36).substr(2, 15)}`,
          urlName: data.UrlName,
          publishStatus: 'Draft',
          versionNumber: 1
        }))
      };

      (batchMigrator as any).salesforceClient = mockSalesforceClient;

      const startTime = Date.now();
      const result = await batchMigrator.migrate({
        dryRun: false,
        verbose: false
      });
      const duration = Date.now() - startTime;

      expect(result).toBeDefined();
      expect(result.summary.totalFiles).toBeGreaterThan(0);
      expect(result.performanceReport.batchProcessing).toBeDefined();
      
      // Should complete in reasonable time even with small batches
      expect(duration).toBeLessThan(60000); // 60 seconds
    }, 70000);

    it('should track memory usage during migration', async () => {
      const mockSalesforceClient = {
        authenticate: jest.fn().mockResolvedValue(true),
        testConnection: jest.fn().mockResolvedValue({ success: true }),
        findExistingArticle: jest.fn().mockResolvedValue(null),
        createKnowledgeArticle: jest.fn().mockResolvedValue({
          success: true,
          articleId: 'test123',
          knowledgeArticleId: 'kav123',
          urlName: 'test',
          publishStatus: 'Draft',
          versionNumber: 1
        })
      };

      (migrator as any).salesforceClient = mockSalesforceClient;

      const initialMemory = process.memoryUsage().heapUsed;
      
      const result = await migrator.migrate({
        dryRun: false,
        verbose: false
      });

      const finalMemory = process.memoryUsage().heapUsed;
      const memoryIncrease = finalMemory - initialMemory;

      expect(result.performanceReport.memoryUsage).toBeDefined();
      
      // Memory increase should be reasonable (less than 100MB for test files)
      expect(memoryIncrease).toBeLessThan(100 * 1024 * 1024);
    });
  });

  describe('Configuration Management', () => {
    it('should load configuration from file', () => {
      const configManager = new ConfigManager(configPath);
      const loadedConfig = configManager.getConfig();

      expect(loadedConfig).toBeDefined();
      expect(loadedConfig.salesforce).toBeDefined();
      expect(loadedConfig.migration).toBeDefined();
      expect(loadedConfig.categoryRules).toBeDefined();
      expect(loadedConfig.contentProcessing).toBeDefined();
    });

    it('should validate configuration', () => {
      const configManager = new ConfigManager(configPath);
      const validation = configManager.validateEnvironment();

      expect(validation).toBeDefined();
      expect(validation.isValid).toBeDefined();
      expect(Array.isArray(validation.errors)).toBe(true);
      expect(Array.isArray(validation.warnings)).toBe(true);
    });
  });
});