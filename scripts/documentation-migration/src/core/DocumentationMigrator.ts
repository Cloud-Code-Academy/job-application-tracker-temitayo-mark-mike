/**
 * Main orchestration class for documentation migration
 */

import { MigrationConfig, MigrationResult, MigrationReport } from '../types';
import { FileScanner } from './FileScanner';
import { MetadataExtractor } from './MetadataExtractor';
import { ContentProcessor } from './ContentProcessor';
import { CategoryMapper } from './CategoryMapper';
import { SalesforceClient } from './SalesforceClient';
import { ProgressTracker } from './ProgressTracker';
import { ErrorHandler } from './ErrorHandler';
import { LinkMapper } from './LinkMapper';
import { RelationshipMapper, DocumentInfo } from './RelationshipMapper';
import { BatchProcessor } from './BatchProcessor';
import { PerformanceOptimizer } from '../utils/PerformanceOptimizer';

export class DocumentationMigrator {
  private config: MigrationConfig;
  private fileScanner: FileScanner;
  private metadataExtractor: MetadataExtractor;
  private contentProcessor: ContentProcessor;
  private categoryMapper: CategoryMapper;
  private salesforceClient: SalesforceClient;
  private errorHandler: ErrorHandler;
  private linkMapper: LinkMapper;
  private relationshipMapper: RelationshipMapper;
  private batchProcessor: BatchProcessor;
  private performanceOptimizer: PerformanceOptimizer;

  constructor(config: MigrationConfig) {
    this.config = config;
    
    // Initialize components
    this.fileScanner = new FileScanner(config.migration.sourceDirectory, {
      excludePatterns: config.migration.excludePatterns,
      includeHidden: false,
      maxDepth: 10
    });
    
    this.metadataExtractor = new MetadataExtractor();
    this.linkMapper = new LinkMapper(config.migration.sourceDirectory);
    this.relationshipMapper = new RelationshipMapper(config.migration.sourceDirectory, this.linkMapper);
    this.contentProcessor = new ContentProcessor(config.contentProcessing, this.linkMapper);
    this.categoryMapper = new CategoryMapper(config.categoryRules);
    this.salesforceClient = new SalesforceClient(config.salesforce);
    this.errorHandler = new ErrorHandler({
      maxRetries: 3,
      baseDelay: 1000,
      maxDelay: 30000,
      backoffMultiplier: 2
    });
    this.batchProcessor = new BatchProcessor({
      batchSize: config.migration.batchSize,
      concurrency: 3,
      memoryThresholdMB: 500,
      rateLimitRequests: 100,
      rateLimitWindowMs: 60000,
      enableCaching: true,
      enableStreaming: true
    });
    this.performanceOptimizer = new PerformanceOptimizer();
  }

  /**
   * Main migration method
   */
  public async migrate(options: MigrationOptions = {}): Promise<MigrationReport> {
    const startTime = Date.now();
    const progressTracker = options.progressTracker || new ProgressTracker();
    const results: MigrationResult[] = [];
    const errors: Array<{ file: string; error: string; stack?: string }> = [];

    try {
      // Authenticate with Salesforce
      await this.salesforceClient.authenticate();

      // Scan for files
      const files = await this.fileScanner.scanFiles();
      
      if (files.length === 0) {
        throw new Error(`No markdown files found in ${this.config.migration.sourceDirectory}`);
      }

      // Initialize progress tracking
      if (!progressTracker.hasExistingProgress()) {
        progressTracker.startMigration(files.length);
      }

      // Get unprocessed files for resume capability
      const unprocessedFiles = progressTracker.getUnprocessedFiles(files.map(f => f.filePath));
      const filesToProcess = files.filter(f => unprocessedFiles.includes(f.filePath));

      if (options.verbose) {
        console.log(`Found ${files.length} total files, ${filesToProcess.length} to process`);
      }

      // Analyze relationships between documents
      if (options.verbose) {
        console.log('Analyzing document relationships...');
      }
      
      const documents: DocumentInfo[] = [];
      const fs = require('fs');
      
      for (const file of files) {
        try {
          const content = fs.readFileSync(file.filePath, 'utf8');
          const metadata = this.metadataExtractor.inferMetadata(file.filePath, content);
          
          documents.push({
            filePath: file.filePath,
            content,
            metadata
          });
        } catch (error) {
          if (options.verbose) {
            console.warn(`Failed to read file for relationship analysis: ${file.filePath}`);
          }
        }
      }

      const relationshipAnalysis = this.relationshipMapper.analyzeRelationships(documents);
      
      if (options.verbose) {
        console.log(`Relationship analysis complete: ${relationshipAnalysis.metrics.totalDocuments} documents, ${relationshipAnalysis.metrics.totalRelationships} relationships`);
        
        if (relationshipAnalysis.recommendations.length > 0) {
          console.log('Relationship recommendations:');
          relationshipAnalysis.recommendations.forEach(rec => console.log(`  - ${rec}`));
        }
      }

      // Process files using optimized batch processor
      const batchResult = await this.batchProcessor.processBatches(
        filesToProcess,
        async (fileMetadata) => {
          return this.processFile(fileMetadata, options);
        },
        progressTracker,
        {
          respectRateLimit: true,
          enableCaching: true
        }
      );

      results.push(...batchResult.results);
      errors.push(...batchResult.errors.map(e => ({
        file: e.item.filePath || 'unknown',
        error: e.error,
        stack: undefined
      })));

      // Generate final report
      const duration = Date.now() - startTime;
      const successful = results.filter(r => r.success).length;
      const failed = results.filter(r => !r.success).length;
      const skipped = results.filter(r => r.action === 'skipped').length;

      // Update relationships with migration results
      this.relationshipMapper.updateRelationshipsPostMigration(results);

      // Generate reports
      const mappingReport = this.linkMapper.generateMappingReport();
      const relationshipReport = this.relationshipMapper.generateRelationshipReport();
      const performanceStats = this.batchProcessor.getPerformanceStatistics();
      
      return {
        summary: {
          totalFiles: files.length,
          successful,
          failed,
          skipped,
          duration
        },
        results,
        urlMappings: this.linkMapper.getAllMappings(),
        errors,
        linkMappingReport: mappingReport,
        relationshipReport,
        errorReport: this.errorHandler.getErrorReport(),
        progressReport: progressTracker.generateProgressReport(),
        performanceReport: {
          batchProcessing: batchResult.metrics,
          cacheStatistics: performanceStats.cache,
          memoryUsage: performanceStats.memory,
          rateLimitStatus: performanceStats.rateLimit
        }
      };

    } catch (error) {
      throw new Error(`Migration failed: ${error}`);
    }
  }

  /**
   * Resume an interrupted migration
   */
  public async resume(options: ResumeOptions = {}): Promise<MigrationReport> {
    const progressTracker = options.progressTracker || new ProgressTracker();
    
    if (!progressTracker.hasExistingProgress()) {
      throw new Error('No existing migration found to resume');
    }

    const resumeInfo = progressTracker.resumeMigration();
    
    if (options.verbose) {
      console.log(`Resuming migration: ${resumeInfo.remainingFiles} files remaining`);
    }

    // Continue with regular migration process
    return this.migrate({
      ...options,
      progressTracker
    });
  }

  /**
   * Process a batch of files
   */
  private async processBatch(
    files: any[], 
    progressTracker: ProgressTracker, 
    options: MigrationOptions
  ): Promise<{ results: MigrationResult[]; errors: Array<{ file: string; error: string; stack?: string }> }> {
    const results: MigrationResult[] = [];
    const errors: Array<{ file: string; error: string; stack?: string }> = [];

    for (const fileMetadata of files) {
      try {
        const result = await this.processFile(fileMetadata, options);
        results.push(result);
        progressTracker.recordFileProcessed(fileMetadata.filePath, result);

        if (options.verbose) {
          const status = result.success ? '✅' : '❌';
          console.log(`${status} ${fileMetadata.filePath} -> ${result.action}`);
        }

      } catch (error) {
        const errorResult: MigrationResult = {
          success: false,
          filePath: fileMetadata.filePath,
          urlName: fileMetadata.urlName,
          action: 'failed',
          error: error instanceof Error ? error.message : String(error),
          warnings: []
        };

        results.push(errorResult);
        progressTracker.recordFileProcessed(fileMetadata.filePath, errorResult);

        errors.push({
          file: fileMetadata.filePath,
          error: error instanceof Error ? error.message : String(error),
          stack: error instanceof Error ? error.stack : undefined
        });

        if (options.verbose) {
          console.error(`❌ ${fileMetadata.filePath} -> ERROR: ${errorResult.error}`);
        }
      }
    }

    return { results, errors };
  }

  /**
   * Process a single file
   */
  private async processFile(fileMetadata: any, options: MigrationOptions): Promise<MigrationResult> {
    const context = {
      sourceFile: fileMetadata.filePath,
      targetArticle: undefined,
      metadata: fileMetadata,
      attempt: 1,
      maxAttempts: 3
    };

    try {
      // Read file content using streaming for large files
      const fileResult = await this.batchProcessor.processLargeFile(
        fileMetadata.filePath,
        async (content) => content, // Just return content for now, processing happens later
        { maxMemoryMB: 50 }
      );

      if (!fileResult.success) {
        throw new Error(fileResult.error || 'Failed to read file');
      }

      const content = fileResult.processedContent!;

      // Extract metadata
      const extractedMetadata = this.metadataExtractor.inferMetadata(
        fileMetadata.filePath,
        content
      );

      // Validate metadata
      const metadataValidation = this.metadataExtractor.validateMetadata(extractedMetadata);
      const warnings: string[] = [];

      if (!metadataValidation.isValid) {
        warnings.push(...metadataValidation.issues);
      }
      warnings.push(...metadataValidation.warnings);

      // Update file metadata with extracted information
      const enrichedMetadata = {
        ...fileMetadata,
        title: extractedMetadata.title,
        tags: extractedMetadata.tags,
        difficulty: extractedMetadata.difficulty,
        readingTime: extractedMetadata.readingTime,
        prerequisites: extractedMetadata.prerequisites,
        summary: extractedMetadata.summary
      };

      // Categorize the document
      const categoryResult = this.categoryMapper.mapToCategory(
        fileMetadata.filePath,
        enrichedMetadata,
        content
      );

      enrichedMetadata.category = categoryResult.category;
      enrichedMetadata.subcategory = categoryResult.subcategory;

      if (categoryResult.confidence < 0.5) {
        warnings.push(`Low confidence category mapping: ${categoryResult.category} (${(categoryResult.confidence * 100).toFixed(1)}%)`);
      }

      // Process content
      const processedContent = await this.contentProcessor.processContent(content, fileMetadata.filePath);
      warnings.push(...processedContent.warnings);

      // Check if article already exists
      const existingArticle = await this.salesforceClient.findExistingArticle(enrichedMetadata.urlName);

      if (options.dryRun) {
        return {
          success: true,
          filePath: fileMetadata.filePath,
          urlName: enrichedMetadata.urlName,
          action: existingArticle ? 'would_update' : 'would_create',
          warnings
        };
      }

      // Generate related articles content
      const relatedArticlesContent = this.relationshipMapper.generateRelatedArticlesContent(fileMetadata.filePath);

      // Prepare article data
      const articleData = {
        Title: enrichedMetadata.title,
        UrlName: enrichedMetadata.urlName,
        Summary: enrichedMetadata.summary,
        Content__c: processedContent.html,
        Difficulty_Level__c: enrichedMetadata.difficulty,
        Reading_Time__c: enrichedMetadata.readingTime,
        Tags__c: enrichedMetadata.tags.join(';'),
        Prerequisites__c: enrichedMetadata.prerequisites,
        Related_Articles__c: relatedArticlesContent,
        Language: 'en_US',
        IsVisibleInApp: true,
        IsVisibleInPkb: true,
        IsVisibleInCsp: true
      };

      let salesforceResult;
      let action: string;

      if (existingArticle) {
        // Update existing article with rate limiting
        const updateResult = await this.batchProcessor.processApiCall(
          () => this.salesforceClient.updateKnowledgeArticle(existingArticle.articleId!, articleData),
          `update_${existingArticle.articleId}`,
          { cacheDurationMs: 5 * 60 * 1000 } // Cache for 5 minutes
        );
        
        if (!updateResult.success) {
          throw new Error(updateResult.error || 'Failed to update article');
        }
        
        salesforceResult = updateResult.data;
        action = 'updated';
      } else {
        // Create new article with rate limiting
        const createResult = await this.batchProcessor.processApiCall(
          () => this.salesforceClient.createKnowledgeArticle(articleData),
          undefined, // Don't cache create operations
          {}
        );
        
        if (!createResult.success) {
          throw new Error(createResult.error || 'Failed to create article');
        }
        
        salesforceResult = createResult.data;
        action = 'created';
      }

      // Add link mapping
      if (salesforceResult.success && salesforceResult.knowledgeArticleId) {
        const knowledgeUrl = `/lightning/r/Knowledge__kav/${salesforceResult.knowledgeArticleId}/view`;
        this.linkMapper.addMapping(fileMetadata.filePath, knowledgeUrl);
      }

      return {
        success: salesforceResult.success,
        filePath: fileMetadata.filePath,
        articleId: salesforceResult.articleId,
        urlName: enrichedMetadata.urlName,
        action: action as any,
        warnings
      };

    } catch (error) {
      // Handle error through error handler
      const errorResult = await this.errorHandler.handleError(error as Error, context);
      
      if (errorResult.action === 'retry' && context.attempt < context.maxAttempts) {
        // Wait for retry delay
        await this.delay(errorResult.delay || 1000);
        
        // Retry with incremented attempt
        context.attempt++;
        return this.processFile(fileMetadata, options);
      }

      // Return failed result
      return {
        success: false,
        filePath: fileMetadata.filePath,
        urlName: fileMetadata.urlName,
        action: 'failed',
        error: error instanceof Error ? error.message : String(error),
        warnings: []
      };
    }
  }

  /**
   * Utility method to add delays
   */
  private async delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  /**
   * Get migration statistics
   */
  public getStatistics(): MigrationStatistics {
    return {
      errorStats: this.errorHandler.getErrorStatistics(),
      linkMappingStats: this.linkMapper.generateMappingReport(),
      relationshipStats: this.relationshipMapper.generateRelationshipReport()
    };
  }

  /**
   * Generate URL mapping report for redirects
   */
  public generateUrlMappingReport(): UrlMappingReport {
    const mappings = this.linkMapper.getAllMappings();
    const brokenRelationships = this.relationshipMapper.findBrokenRelationships();
    
    return {
      totalMappings: Object.keys(mappings).length,
      mappings,
      brokenRelationships,
      redirectRules: this.generateRedirectRules(mappings),
      generatedAt: new Date().toISOString()
    };
  }

  /**
   * Generate redirect rules for web server configuration
   */
  private generateRedirectRules(mappings: Record<string, string>): RedirectRule[] {
    const rules: RedirectRule[] = [];
    
    for (const [originalPath, knowledgeUrl] of Object.entries(mappings)) {
      // Convert file path to web path
      const webPath = originalPath
        .replace(/^docs\//, '/')
        .replace(/\.md$/, '')
        .replace(/\\/g, '/');
      
      rules.push({
        from: webPath,
        to: knowledgeUrl,
        type: 'permanent',
        status: 301
      });
    }
    
    return rules;
  }

  /**
   * Export relationship data for external analysis
   */
  public exportRelationshipData(): any {
    return this.relationshipMapper.exportRelationshipData();
  }

  /**
   * Validate migration setup
   */
  public async validateSetup(): Promise<ValidationResult> {
    const issues: string[] = [];
    const warnings: string[] = [];

    try {
      // Test Salesforce connection
      const connectionTest = await this.salesforceClient.testConnection();
      if (!connectionTest.success) {
        issues.push(`Salesforce connection failed: ${connectionTest.error}`);
      }

      // Check source directory
      const fs = require('fs');
      if (!fs.existsSync(this.config.migration.sourceDirectory)) {
        issues.push(`Source directory does not exist: ${this.config.migration.sourceDirectory}`);
      } else {
        // Check for markdown files
        const files = await this.fileScanner.scanFiles();
        if (files.length === 0) {
          warnings.push(`No markdown files found in ${this.config.migration.sourceDirectory}`);
        }
      }

      // Validate category rules
      if (this.config.categoryRules.length === 0) {
        warnings.push('No category rules defined - all files will use fallback category');
      }

      return {
        isValid: issues.length === 0,
        issues,
        warnings
      };

    } catch (error) {
      issues.push(`Setup validation failed: ${error}`);
      return {
        isValid: false,
        issues,
        warnings
      };
    }
  }
}

// Type definitions

export interface MigrationOptions {
  dryRun?: boolean;
  verbose?: boolean;
  progressTracker?: ProgressTracker;
}

export interface ResumeOptions {
  verbose?: boolean;
  progressTracker?: ProgressTracker;
}

export interface MigrationStatistics {
  errorStats: any;
  linkMappingStats: any;
  relationshipStats: any;
}

export interface ValidationResult {
  isValid: boolean;
  issues: string[];
  warnings: string[];
}

export interface UrlMappingReport {
  totalMappings: number;
  mappings: Record<string, string>;
  brokenRelationships: any[];
  redirectRules: RedirectRule[];
  generatedAt: string;
}

export interface RedirectRule {
  from: string;
  to: string;
  type: 'permanent' | 'temporary';
  status: 301 | 302;
}