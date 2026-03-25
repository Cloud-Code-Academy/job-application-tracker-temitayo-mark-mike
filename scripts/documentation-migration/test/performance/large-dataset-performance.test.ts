/**
 * Performance tests for large document sets
 */

import * as fs from 'fs';
import * as path from 'path';
import { DocumentationMigrator } from '../../src/core/DocumentationMigrator';
import { BatchProcessor } from '../../src/core/BatchProcessor';
import { PerformanceOptimizer } from '../../src/utils/PerformanceOptimizer';
import { MigrationConfig } from '../../src/types';

describe('Large Dataset Performance Tests', () => {
  const testDocsDir = path.join(__dirname, '../fixtures/performance-docs');
  const tempDir = path.join(__dirname, '../fixtures/temp-perf');
  
  let migrator: DocumentationMigrator;
  let config: MigrationConfig;

  beforeAll(async () => {
    // Create performance test directory
    if (!fs.existsSync(testDocsDir)) {
      fs.mkdirSync(testDocsDir, { recursive: true });
    }
    
    if (!fs.existsSync(tempDir)) {
      fs.mkdirSync(tempDir, { recursive: true });
    }

    // Generate large dataset
    await generateLargeDataset();

    // Setup configuration
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
        excludePatterns: [],
        dryRun: true,
        batchSize: 10,
        resumeFile: path.join(tempDir, 'perf-progress.json')
      },
      categoryRules: [
        { pattern: /tutorial/i, category: 'Tutorial' },
        { pattern: /api/i, category: 'Reference' },
        { pattern: /guide/i, category: 'Guide' }
      ],
      contentProcessing: {
        imageHandling: 'embed',
        linkProcessing: 'convert',
        codeBlockStyling: 'salesforce'
      }
    };

    migrator = new DocumentationMigrator(config);
  });

  afterAll(async () => {
    // Clean up performance test files
    await cleanupPerformanceFiles();
  });

  describe('Batch Processing Performance', () => {
    it('should process 100 documents efficiently', async () => {
      const batchProcessor = new BatchProcessor({
        batchSize: 10,
        concurrency: 3,
        memoryThresholdMB: 200,
        enableCaching: true,
        enableStreaming: true
      });

      const documents = Array.from({ length: 100 }, (_, i) => ({
        id: i,
        content: `Document ${i} content`.repeat(100)
      }));

      const processor = jest.fn().mockImplementation(async (doc: any) => {
        // Simulate processing time
        await new Promise(resolve => setTimeout(resolve, 10));
        return `processed-${doc.id}`;
      });

      const startTime = Date.now();
      const result = await batchProcessor.processBatches(documents, processor);
      const duration = Date.now() - startTime;

      expect(result.results).toHaveLength(100);
      expect(result.errors).toHaveLength(0);
      expect(duration).toBeLessThan(15000); // Should complete within 15 seconds
      expect(result.metrics.averageTimePerItem).toBeLessThan(150); // Average < 150ms per item

      console.log('Batch processing performance:', {
        totalItems: result.metrics.totalItems,
        duration: `${duration}ms`,
        averageTimePerItem: `${Math.round(result.metrics.averageTimePerItem)}ms`,
        throughput: `${Math.round(result.metrics.totalItems / (duration / 1000))} items/sec`
      });
    }, 30000);

    it('should handle memory efficiently with large documents', async () => {
      const batchProcessor = new BatchProcessor({
        batchSize: 5,
        memoryThresholdMB: 100,
        enableStreaming: true
      });

      // Create large documents
      const largeDocuments = Array.from({ length: 20 }, (_, i) => ({
        id: i,
        content: 'Large content block. '.repeat(10000) // ~200KB per document
      }));

      const processor = jest.fn().mockImplementation(async (doc: any) => {
        // Process the large content
        return doc.content.toUpperCase();
      });

      const initialMemory = process.memoryUsage().heapUsed;
      
      const result = await batchProcessor.processBatches(largeDocuments, processor);
      
      const finalMemory = process.memoryUsage().heapUsed;
      const memoryIncrease = finalMemory - initialMemory;

      expect(result.results).toHaveLength(20);
      expect(result.errors).toHaveLength(0);
      
      // Memory increase should be reasonable (less than 50MB)
      expect(memoryIncrease).toBeLessThan(50 * 1024 * 1024);

      console.log('Memory usage:', {
        initialMemory: `${Math.round(initialMemory / 1024 / 1024)}MB`,
        finalMemory: `${Math.round(finalMemory / 1024 / 1024)}MB`,
        memoryIncrease: `${Math.round(memoryIncrease / 1024 / 1024)}MB`
      });
    }, 45000);
  });

  describe('File Processing Performance', () => {
    it('should process large files with streaming', async () => {
      const performanceOptimizer = new PerformanceOptimizer();
      
      // Create a very large file
      const largeFilePath = path.join(testDocsDir, 'very-large-file.md');
      const largeContent = '# Large File\n\n' + 'This is a very large file. '.repeat(50000);
      fs.writeFileSync(largeFilePath, largeContent);

      const processor = jest.fn().mockImplementation(async (content: string) => {
        return content.replace(/large/gi, 'LARGE');
      });

      const startTime = Date.now();
      const result = await performanceOptimizer.createFileStream(largeFilePath, {
        chunkSize: 64 * 1024,
        maxMemoryMB: 10
      });
      const streamDuration = Date.now() - startTime;

      expect(result).toBeDefined();
      expect(result.length).toBeGreaterThan(1000000); // > 1MB
      expect(streamDuration).toBeLessThan(5000); // Should stream within 5 seconds

      console.log('File streaming performance:', {
        fileSize: `${Math.round(result.length / 1024 / 1024)}MB`,
        streamDuration: `${streamDuration}ms`,
        throughput: `${Math.round((result.length / 1024 / 1024) / (streamDuration / 1000))}MB/sec`
      });

      // Clean up
      fs.unlinkSync(largeFilePath);
    }, 15000);

    it('should cache content effectively', async () => {
      const performanceOptimizer = new PerformanceOptimizer();
      const content = 'Test content for caching performance';
      const processedHtml = '<p>Test content for caching performance</p>';

      // Cache many items
      const cacheStartTime = Date.now();
      for (let i = 0; i < 1000; i++) {
        performanceOptimizer.cacheContent(`file-${i}.md`, content + i, processedHtml + i);
      }
      const cacheDuration = Date.now() - cacheStartTime;

      // Retrieve cached items
      const retrieveStartTime = Date.now();
      let hits = 0;
      for (let i = 0; i < 1000; i++) {
        const cached = performanceOptimizer.getCachedContent(`file-${i}.md`, content + i);
        if (cached) hits++;
      }
      const retrieveDuration = Date.now() - retrieveStartTime;

      expect(hits).toBeGreaterThan(900); // Should have high hit rate
      expect(cacheDuration).toBeLessThan(1000); // Caching should be fast
      expect(retrieveDuration).toBeLessThan(500); // Retrieval should be very fast

      console.log('Cache performance:', {
        cacheOperations: 1000,
        cacheDuration: `${cacheDuration}ms`,
        retrieveDuration: `${retrieveDuration}ms`,
        hitRate: `${(hits / 1000 * 100).toFixed(1)}%`,
        cacheOpsPerSec: Math.round(1000 / (cacheDuration / 1000)),
        retrieveOpsPerSec: Math.round(1000 / (retrieveDuration / 1000))
      });
    });
  });

  describe('End-to-End Migration Performance', () => {
    it('should migrate 50 documents within performance targets', async () => {
      // Mock Salesforce client for performance testing
      const mockSalesforceClient = {
        authenticate: jest.fn().mockResolvedValue(true),
        testConnection: jest.fn().mockResolvedValue({ success: true }),
        findExistingArticle: jest.fn().mockResolvedValue(null),
        createKnowledgeArticle: jest.fn().mockImplementation(async (data) => {
          // Simulate API delay
          await new Promise(resolve => setTimeout(resolve, 50));
          return {
            success: true,
            articleId: `ka${Math.random().toString(36).substr(2, 15)}`,
            knowledgeArticleId: `kav${Math.random().toString(36).substr(2, 15)}`,
            urlName: data.UrlName,
            publishStatus: 'Draft',
            versionNumber: 1
          };
        })
      };

      (migrator as any).salesforceClient = mockSalesforceClient;

      const startTime = Date.now();
      const result = await migrator.migrate({
        dryRun: false,
        verbose: false
      });
      const duration = Date.now() - startTime;

      expect(result.summary.totalFiles).toBeGreaterThan(40); // Should process most files
      expect(result.summary.successful).toBeGreaterThan(30);
      expect(duration).toBeLessThan(60000); // Should complete within 60 seconds

      const throughput = result.summary.totalFiles / (duration / 1000);
      expect(throughput).toBeGreaterThan(0.5); // At least 0.5 files per second

      console.log('End-to-end migration performance:', {
        totalFiles: result.summary.totalFiles,
        successful: result.summary.successful,
        duration: `${Math.round(duration / 1000)}s`,
        throughput: `${throughput.toFixed(2)} files/sec`,
        averageTimePerFile: `${Math.round(duration / result.summary.totalFiles)}ms`
      });

      // Verify performance metrics
      expect(result.performanceReport).toBeDefined();
      expect(result.performanceReport.batchProcessing).toBeDefined();
      expect(result.performanceReport.memoryUsage).toBeDefined();
    }, 90000);

    it('should handle concurrent processing efficiently', async () => {
      const concurrentMigrators = [];
      const concurrentConfigs = [];

      // Create multiple migrator instances
      for (let i = 0; i < 3; i++) {
        const concurrentConfig = {
          ...config,
          migration: {
            ...config.migration,
            sourceDirectory: path.join(testDocsDir, `batch-${i}`),
            resumeFile: path.join(tempDir, `progress-${i}.json`)
          }
        };

        // Create subset of files for each migrator
        const batchDir = concurrentConfig.migration.sourceDirectory;
        if (!fs.existsSync(batchDir)) {
          fs.mkdirSync(batchDir, { recursive: true });
        }

        // Copy some files to each batch directory
        const sourceFiles = fs.readdirSync(testDocsDir).slice(i * 10, (i + 1) * 10);
        for (const file of sourceFiles) {
          if (file.endsWith('.md')) {
            const sourceContent = fs.readFileSync(path.join(testDocsDir, file), 'utf8');
            fs.writeFileSync(path.join(batchDir, file), sourceContent);
          }
        }

        const migrator = new DocumentationMigrator(concurrentConfig);
        
        // Mock Salesforce client
        (migrator as any).salesforceClient = {
          authenticate: jest.fn().mockResolvedValue(true),
          testConnection: jest.fn().mockResolvedValue({ success: true }),
          findExistingArticle: jest.fn().mockResolvedValue(null),
          createKnowledgeArticle: jest.fn().mockImplementation(async (data) => {
            await new Promise(resolve => setTimeout(resolve, 30));
            return {
              success: true,
              articleId: `ka${Math.random().toString(36).substr(2, 15)}`,
              knowledgeArticleId: `kav${Math.random().toString(36).substr(2, 15)}`,
              urlName: data.UrlName,
              publishStatus: 'Draft',
              versionNumber: 1
            };
          })
        };

        concurrentMigrators.push(migrator);
        concurrentConfigs.push(concurrentConfig);
      }

      const startTime = Date.now();
      
      // Run migrations concurrently
      const promises = concurrentMigrators.map(migrator => 
        migrator.migrate({ dryRun: false, verbose: false })
      );
      
      const results = await Promise.all(promises);
      const duration = Date.now() - startTime;

      // All migrations should complete successfully
      expect(results).toHaveLength(3);
      results.forEach(result => {
        expect(result.summary.totalFiles).toBeGreaterThan(0);
        expect(result.summary.successful).toBeGreaterThan(0);
      });

      const totalFiles = results.reduce((sum, result) => sum + result.summary.totalFiles, 0);
      const totalSuccessful = results.reduce((sum, result) => sum + result.summary.successful, 0);

      console.log('Concurrent migration performance:', {
        concurrentMigrations: 3,
        totalFiles,
        totalSuccessful,
        duration: `${Math.round(duration / 1000)}s`,
        overallThroughput: `${(totalFiles / (duration / 1000)).toFixed(2)} files/sec`
      });

      // Clean up batch directories
      for (const config of concurrentConfigs) {
        if (fs.existsSync(config.migration.sourceDirectory)) {
          fs.rmSync(config.migration.sourceDirectory, { recursive: true, force: true });
        }
      }
    }, 120000);
  });

  describe('Memory and Resource Management', () => {
    it('should maintain stable memory usage during long-running operations', async () => {
      const batchProcessor = new BatchProcessor({
        batchSize: 5,
        memoryThresholdMB: 100
      });

      const memoryReadings: number[] = [];
      const interval = setInterval(() => {
        memoryReadings.push(process.memoryUsage().heapUsed);
      }, 1000);

      try {
        // Process many batches
        for (let batch = 0; batch < 10; batch++) {
          const items = Array.from({ length: 20 }, (_, i) => ({
            id: batch * 20 + i,
            data: 'Data '.repeat(1000)
          }));

          const processor = jest.fn().mockImplementation(async (item: any) => {
            // Simulate memory-intensive processing
            const tempArray = new Array(1000).fill(item.data);
            return tempArray.length;
          });

          await batchProcessor.processBatches(items, processor);
        }
      } finally {
        clearInterval(interval);
      }

      // Analyze memory stability
      const maxMemory = Math.max(...memoryReadings);
      const minMemory = Math.min(...memoryReadings);
      const memoryVariation = (maxMemory - minMemory) / minMemory;

      expect(memoryVariation).toBeLessThan(2.0); // Memory shouldn't vary by more than 200%

      console.log('Memory stability:', {
        readings: memoryReadings.length,
        minMemory: `${Math.round(minMemory / 1024 / 1024)}MB`,
        maxMemory: `${Math.round(maxMemory / 1024 / 1024)}MB`,
        variation: `${(memoryVariation * 100).toFixed(1)}%`
      });
    }, 60000);

    it('should handle garbage collection effectively', async () => {
      const performanceOptimizer = new PerformanceOptimizer();
      
      // Force garbage collection if available
      if (global.gc) {
        global.gc();
      }

      const initialMemory = process.memoryUsage().heapUsed;

      // Create many cached items
      for (let i = 0; i < 5000; i++) {
        const content = `Content ${i} `.repeat(100);
        performanceOptimizer.cacheContent(`file-${i}.md`, content, `<p>${content}</p>`);
      }

      const peakMemory = process.memoryUsage().heapUsed;

      // Clear caches
      performanceOptimizer.clearCaches();

      // Force garbage collection if available
      if (global.gc) {
        global.gc();
      }

      // Wait a bit for GC
      await new Promise(resolve => setTimeout(resolve, 1000));

      const finalMemory = process.memoryUsage().heapUsed;
      const memoryRecovered = peakMemory - finalMemory;
      const recoveryRate = memoryRecovered / (peakMemory - initialMemory);

      expect(recoveryRate).toBeGreaterThan(0.5); // Should recover at least 50% of allocated memory

      console.log('Garbage collection effectiveness:', {
        initialMemory: `${Math.round(initialMemory / 1024 / 1024)}MB`,
        peakMemory: `${Math.round(peakMemory / 1024 / 1024)}MB`,
        finalMemory: `${Math.round(finalMemory / 1024 / 1024)}MB`,
        memoryRecovered: `${Math.round(memoryRecovered / 1024 / 1024)}MB`,
        recoveryRate: `${(recoveryRate * 100).toFixed(1)}%`
      });
    }, 15000);
  });

  // Helper functions

  async function generateLargeDataset(): Promise<void> {
    const documentTypes = [
      { prefix: 'tutorial', category: 'Tutorial', count: 15 },
      { prefix: 'api', category: 'Reference', count: 20 },
      { prefix: 'guide', category: 'Guide', count: 15 }
    ];

    for (const type of documentTypes) {
      for (let i = 1; i <= type.count; i++) {
        const fileName = `${type.prefix}-${i.toString().padStart(3, '0')}.md`;
        const content = generateDocumentContent(type.prefix, i, type.category);
        fs.writeFileSync(path.join(testDocsDir, fileName), content);
      }
    }
  }

  function generateDocumentContent(prefix: string, index: number, category: string): string {
    const title = `${prefix.charAt(0).toUpperCase() + prefix.slice(1)} Document ${index}`;
    
    return `---
title: ${title}
category: ${category}
tags: [${prefix}, test, performance]
difficulty: ${['Beginner', 'Intermediate', 'Advanced'][index % 3]}
---

# ${title}

This is a generated document for performance testing.

## Introduction

${'This is introductory content. '.repeat(50)}

## Main Content

${'This is the main content section with substantial text. '.repeat(100)}

### Subsection ${index}.1

${'Subsection content with detailed information. '.repeat(30)}

### Subsection ${index}.2

${'More subsection content for testing purposes. '.repeat(30)}

## Code Examples

\`\`\`javascript
// Example code block
function example${index}() {
${Array.from({ length: 20 }, (_, i) => `  console.log('Line ${i} in example ${index}');`).join('\n')}
}
\`\`\`

## Tables

| Column 1 | Column 2 | Column 3 |
|----------|----------|----------|
${Array.from({ length: 10 }, (_, i) => `| Row ${i} | Data ${i} | Value ${i} |`).join('\n')}

## Links

${Array.from({ length: 5 }, (_, i) => `[Link ${i}](${prefix}-${(index + i) % 10 + 1}.md)`).join(' ')}

## Conclusion

${'This concludes the generated document. '.repeat(20)}
`;
  }

  async function cleanupPerformanceFiles(): Promise<void> {
    if (fs.existsSync(testDocsDir)) {
      fs.rmSync(testDocsDir, { recursive: true, force: true });
    }
    
    if (fs.existsSync(tempDir)) {
      fs.rmSync(tempDir, { recursive: true, force: true });
    }
  }
});