/**
 * Integration tests for performance optimization features
 */

import * as fs from 'fs';
import * as path from 'path';
import { DocumentationMigrator } from '../../src/core/DocumentationMigrator';
import { BatchProcessor } from '../../src/core/BatchProcessor';
import { PerformanceOptimizer } from '../../src/utils/PerformanceOptimizer';
import { MigrationConfig } from '../../src/types';

describe('Performance Optimization Integration', () => {
  const testDocsDir = path.join(__dirname, '../fixtures/performance-test');
  const tempDir = path.join(__dirname, '../fixtures/temp-perf');
  
  let migrator: DocumentationMigrator;
  let batchProcessor: BatchProcessor;
  let performanceOptimizer: PerformanceOptimizer;

  beforeAll(async () => {
    // Create test directory structure
    await createPerformanceTestFiles();
    
    const config: MigrationConfig = {
      salesforce: {
        loginUrl: 'https://test.salesforce.com',
        username: 'test@example.com',
        password: 'password',
        securityToken: 'token',
        apiVersion: '58.0'
      },
      migration: {
        sourceDirectory: testDocsDir,
        excludePatterns: [],
        dryRun: true,
        batchSize: 5,
        resumeFile: path.join(tempDir, 'progress.json')
      },
      categoryRules: [],
      contentProcessing: {
        imageHandling: 'embed',
        linkProcessing: 'convert',
        codeBlockStyling: 'salesforce'
      }
    };

    migrator = new DocumentationMigrator(config);
    batchProcessor = new BatchProcessor({
      batchSize: 3,
      concurrency: 2,
      memoryThresholdMB: 100,
      rateLimitRequests: 50,
      rateLimitWindowMs: 60000,
      enableCaching: true,
      enableStreaming: true
    });
    performanceOptimizer = new PerformanceOptimizer();
  });

  afterAll(async () => {
    // Clean up test files
    await cleanupPerformanceTestFiles();
  });

  describe('Batch Processing Performance', () => {
    it('should process multiple files efficiently in batches', async () => {
      const items = Array.from({ length: 20 }, (_, i) => ({ id: i, data: `item-${i}` }));
      const processor = jest.fn().mockImplementation(async (item: any) => {
        // Simulate processing time
        await new Promise(resolve => setTimeout(resolve, 50));
        return `processed-${item.id}`;
      });

      const startTime = Date.now();
      const result = await batchProcessor.processBatches(items, processor);
      const duration = Date.now() - startTime;

      expect(result.results).toHaveLength(20);
      expect(result.errors).toHaveLength(0);
      expect(result.metrics.totalItems).toBe(20);
      expect(result.metrics.successfulItems).toBe(20);
      
      // Should be faster than sequential processing due to batching and concurrency
      expect(duration).toBeLessThan(20 * 50); // Less than sequential time
      expect(result.metrics.averageTimePerItem).toBeGreaterThan(0);
    });

    it('should handle mixed success and failure scenarios', async () => {
      const items = Array.from({ length: 10 }, (_, i) => ({ id: i }));
      const processor = jest.fn().mockImplementation(async (item: any) => {
        if (item.id % 3 === 0) {
          throw new Error(`Failed to process item ${item.id}`);
        }
        return `success-${item.id}`;
      });

      const result = await batchProcessor.processBatches(items, processor);

      expect(result.results.length + result.errors.length).toBe(10);
      expect(result.errors.length).toBe(4); // Items 0, 3, 6, 9
      expect(result.metrics.successfulItems).toBe(6);
      expect(result.metrics.failedItems).toBe(4);
    });

    it('should respect memory thresholds during processing', async () => {
      const items = Array.from({ length: 5 }, (_, i) => ({ id: i }));
      const processor = jest.fn().mockImplementation(async (item: any) => {
        // Simulate memory-intensive operation
        const largeArray = new Array(100000).fill(`data-${item.id}`);
        return largeArray.length;
      });

      const result = await batchProcessor.processBatches(items, processor, undefined, {
        respectRateLimit: true
      });

      expect(result.results).toHaveLength(5);
      expect(result.metrics.memoryUsage).toBeGreaterThan(0);
    });
  });

  describe('Large File Processing', () => {
    it('should handle large files with streaming', async () => {
      const largeFilePath = path.join(testDocsDir, 'large-document.md');
      
      // Create a large file for testing
      const largeContent = '# Large Document\n\n' + 'This is a large document. '.repeat(10000);
      fs.writeFileSync(largeFilePath, largeContent);

      const processor = jest.fn().mockImplementation(async (content: string) => {
        return content.replace(/large/gi, 'LARGE');
      });

      const startTime = Date.now();
      const result = await batchProcessor.processLargeFile(largeFilePath, processor, {
        maxMemoryMB: 50
      });
      const duration = Date.now() - startTime;

      expect(result.success).toBe(true);
      expect(result.processedContent).toContain('LARGE Document');
      expect(result.fromCache).toBe(false);
      expect(result.memoryUsed).toBeGreaterThan(0);
      expect(duration).toBeGreaterThan(0);

      // Clean up
      fs.unlinkSync(largeFilePath);
    });

    it('should use cached content for repeated processing', async () => {
      const testFilePath = path.join(testDocsDir, 'cached-test.md');
      const content = '# Test Document\n\nThis is test content.';
      fs.writeFileSync(testFilePath, content);

      const processor = jest.fn().mockResolvedValue('processed content');

      // First call - should process and cache
      const result1 = await batchProcessor.processLargeFile(testFilePath, processor);
      expect(result1.fromCache).toBe(false);
      expect(processor).toHaveBeenCalledTimes(1);

      // Second call - should use cache
      const result2 = await batchProcessor.processLargeFile(testFilePath, processor);
      expect(result2.fromCache).toBe(true);
      expect(processor).toHaveBeenCalledTimes(1); // Not called again

      // Clean up
      fs.unlinkSync(testFilePath);
    });

    it('should handle file processing errors gracefully', async () => {
      const nonExistentFile = path.join(testDocsDir, 'does-not-exist.md');
      const processor = jest.fn();

      const result = await batchProcessor.processLargeFile(nonExistentFile, processor);

      expect(result.success).toBe(false);
      expect(result.error).toBeDefined();
      expect(processor).not.toHaveBeenCalled();
    });
  });

  describe('Rate Limiting', () => {
    it('should respect rate limits for API calls', async () => {
      const apiCalls = Array.from({ length: 10 }, (_, i) => 
        () => Promise.resolve({ data: `result-${i}` })
      );

      const startTime = Date.now();
      const results = [];

      for (const apiCall of apiCalls) {
        const result = await batchProcessor.processApiCall(apiCall);
        results.push(result);
      }

      const duration = Date.now() - startTime;

      expect(results).toHaveLength(10);
      expect(results.every(r => r.success)).toBe(true);
      
      // Should take some time due to rate limiting
      expect(duration).toBeGreaterThan(100);
    });

    it('should provide accurate rate limit status', async () => {
      const apiCall = () => Promise.resolve({ data: 'test' });

      // Make a few API calls
      await batchProcessor.processApiCall(apiCall);
      await batchProcessor.processApiCall(apiCall);
      
      const stats = batchProcessor.getPerformanceStatistics();
      
      expect(stats.rateLimit.requestsInWindow).toBeGreaterThan(0);
      expect(stats.rateLimit.maxRequests).toBeDefined();
      expect(stats.rateLimit.remainingRequests).toBeDefined();
    });
  });

  describe('Caching Performance', () => {
    it('should improve performance through content caching', async () => {
      const content = '# Test Document\n\nThis is test content for caching.';
      const filePath = 'test-cache.md';

      // First processing - no cache
      const startTime1 = Date.now();
      performanceOptimizer.cacheContent(filePath, content, '<h1>Test Document</h1>');
      const duration1 = Date.now() - startTime1;

      // Second processing - from cache
      const startTime2 = Date.now();
      const cached = performanceOptimizer.getCachedContent(filePath, content);
      const duration2 = Date.now() - startTime2;

      expect(cached).toBe('<h1>Test Document</h1>');
      expect(duration2).toBeLessThan(duration1);
    });

    it('should manage cache size effectively', async () => {
      const smallOptimizer = new PerformanceOptimizer({ maxCacheSize: 5 });

      // Add more items than cache size
      for (let i = 0; i < 10; i++) {
        smallOptimizer.cacheContent(`file-${i}.md`, `content-${i}`, `html-${i}`);
      }

      const stats = smallOptimizer.getCacheStatistics();
      expect(stats.contentCache.size).toBeLessThanOrEqual(5);
    });

    it('should expire cached content appropriately', async () => {
      const shortLivedOptimizer = new PerformanceOptimizer({ cacheExpiryMs: 100 });
      const filePath = 'expire-test.md';
      const content = 'test content';

      shortLivedOptimizer.cacheContent(filePath, content, 'cached html');
      
      // Should be cached initially
      let cached = shortLivedOptimizer.getCachedContent(filePath, content);
      expect(cached).toBe('cached html');

      // Wait for expiry
      await new Promise(resolve => setTimeout(resolve, 150));

      // Should be expired now
      cached = shortLivedOptimizer.getCachedContent(filePath, content);
      expect(cached).toBeNull();
    }, 1000);
  });

  describe('Content Analysis and Optimization', () => {
    it('should analyze content and suggest optimizations', () => {
      const complexContent = `# Complex Document

This is a complex document with various features.

\`\`\`javascript
// Large code block
const complexFunction = () => {
  ${'  // Complex logic\n'.repeat(100)}
};
\`\`\`

| Column 1 | Column 2 | Column 3 | Column 4 |
|----------|----------|----------|----------|
${'| Data | Data | Data | Data |\n'.repeat(30)}

${Array.from({ length: 25 }, (_, i) => `[Link ${i}](file${i}.md)`).join(' ')}

![Image 1](image1.png)
![Image 2](image2.png)
`;

      const optimized = performanceOptimizer.optimizeContentProcessing(complexContent);

      expect(optimized.analysis.hasLargeCodeBlocks).toBe(true);
      expect(optimized.analysis.hasComplexTables).toBe(true);
      expect(optimized.analysis.hasManyLinks).toBe(true);
      expect(optimized.analysis.hasImages).toBe(true);
      
      expect(optimized.optimizations).toContain('lazy_code_highlighting');
      expect(optimized.optimizations).toContain('table_streaming');
      expect(optimized.optimizations).toContain('link_batch_processing');
      
      expect(optimized.processingTime).toBeGreaterThan(0);
      expect(optimized.estimatedMemoryUsage).toBeGreaterThan(0);
    });

    it('should handle simple content efficiently', () => {
      const simpleContent = '# Simple Document\n\nThis is simple content.';
      
      const optimized = performanceOptimizer.optimizeContentProcessing(simpleContent);

      expect(optimized.analysis.isLarge).toBe(false);
      expect(optimized.analysis.hasLargeCodeBlocks).toBe(false);
      expect(optimized.analysis.hasComplexTables).toBe(false);
      expect(optimized.analysis.hasManyLinks).toBe(false);
      
      expect(optimized.optimizations).toHaveLength(0);
    });
  });

  describe('Memory Management', () => {
    it('should monitor memory usage during processing', async () => {
      const items = Array.from({ length: 20 }, (_, i) => ({ id: i }));
      const processor = jest.fn().mockImplementation(async (item: any) => {
        // Create some memory pressure
        const tempArray = new Array(10000).fill(`data-${item.id}`);
        return tempArray.length;
      });

      const result = await batchProcessor.processBatches(items, processor);
      const stats = batchProcessor.getPerformanceStatistics();

      expect(result.results).toHaveLength(20);
      expect(stats.memory.heapUsed).toBeGreaterThan(0);
      expect(stats.memory.heapTotal).toBeGreaterThan(0);
    });

    it('should handle memory pressure gracefully', async () => {
      const memoryIntensiveProcessor = new BatchProcessor({
        batchSize: 2,
        memoryThresholdMB: 1 // Very low threshold
      });

      const items = Array.from({ length: 5 }, (_, i) => ({ id: i }));
      const processor = jest.fn().mockResolvedValue('result');

      const result = await memoryIntensiveProcessor.processBatches(items, processor);

      expect(result.results).toHaveLength(5);
      expect(result.errors).toHaveLength(0);
    });
  });

  describe('Performance Statistics', () => {
    it('should provide comprehensive performance metrics', async () => {
      const items = [1, 2, 3, 4, 5];
      const processor = jest.fn().mockImplementation(async (item: number) => {
        await new Promise(resolve => setTimeout(resolve, 10));
        return item * 2;
      });

      const result = await batchProcessor.processBatches(items, processor);
      const stats = batchProcessor.getPerformanceStatistics();

      expect(result.metrics.totalItems).toBe(5);
      expect(result.metrics.duration).toBeGreaterThan(0);
      expect(result.metrics.averageTimePerItem).toBeGreaterThan(0);
      expect(result.metrics.cacheHitRate).toBeGreaterThanOrEqual(0);
      
      expect(stats.cache).toBeDefined();
      expect(stats.rateLimit).toBeDefined();
      expect(stats.memory).toBeDefined();
      expect(stats.config).toBeDefined();
    });

    it('should track cache hit rates accurately', () => {
      const optimizer = new PerformanceOptimizer();
      
      // Add some cached content
      optimizer.cacheContent('file1.md', 'content1', 'html1');
      optimizer.cacheContent('file2.md', 'content2', 'html2');
      
      // Access cached content
      optimizer.getCachedContent('file1.md', 'content1');
      optimizer.getCachedContent('file2.md', 'content2');
      
      const stats = optimizer.getCacheStatistics();
      
      expect(stats.contentCache.size).toBe(2);
      expect(stats.totalMemoryUsage).toBeGreaterThan(0);
    });
  });

  // Helper functions

  async function createPerformanceTestFiles(): Promise<void> {
    if (!fs.existsSync(testDocsDir)) {
      fs.mkdirSync(testDocsDir, { recursive: true });
    }

    if (!fs.existsSync(tempDir)) {
      fs.mkdirSync(tempDir, { recursive: true });
    }

    // Create various test files
    const files = [
      { name: 'small-doc.md', content: '# Small Document\n\nSmall content.' },
      { name: 'medium-doc.md', content: '# Medium Document\n\n' + 'Medium content. '.repeat(100) },
      { name: 'complex-doc.md', content: createComplexDocument() },
      { name: 'simple-doc.md', content: '# Simple\n\nSimple.' },
      { name: 'linked-doc.md', content: '# Linked\n\nSee [other](simple-doc.md).' }
    ];

    for (const file of files) {
      fs.writeFileSync(path.join(testDocsDir, file.name), file.content);
    }
  }

  function createComplexDocument(): string {
    return `# Complex Document

This is a complex document for performance testing.

## Code Blocks

\`\`\`javascript
// Complex code block
function complexFunction() {
${Array.from({ length: 50 }, (_, i) => `  console.log('Line ${i}');`).join('\n')}
}
\`\`\`

## Tables

| Column 1 | Column 2 | Column 3 | Column 4 | Column 5 |
|----------|----------|----------|----------|----------|
${Array.from({ length: 20 }, (_, i) => `| Data ${i} | Data ${i} | Data ${i} | Data ${i} | Data ${i} |`).join('\n')}

## Links

${Array.from({ length: 15 }, (_, i) => `[Link ${i}](file${i}.md)`).join(' ')}

## Images

![Image 1](image1.png)
![Image 2](image2.png)
![Image 3](image3.png)

## Content

${'This is repeated content for testing. '.repeat(500)}
`;
  }

  async function cleanupPerformanceTestFiles(): Promise<void> {
    if (fs.existsSync(testDocsDir)) {
      const files = fs.readdirSync(testDocsDir);
      for (const file of files) {
        fs.unlinkSync(path.join(testDocsDir, file));
      }
      fs.rmdirSync(testDocsDir);
    }

    if (fs.existsSync(tempDir)) {
      fs.rmSync(tempDir, { recursive: true, force: true });
    }
  }
});