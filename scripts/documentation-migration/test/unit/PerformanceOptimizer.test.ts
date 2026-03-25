/**
 * Unit tests for PerformanceOptimizer class
 */

import { PerformanceOptimizer, RateLimiter } from '../../src/utils/PerformanceOptimizer';
import * as fs from 'fs';
import * as path from 'path';

// Mock fs module
jest.mock('fs');
const mockFs = fs as jest.Mocked<typeof fs>;

describe('PerformanceOptimizer', () => {
  let optimizer: PerformanceOptimizer;

  beforeEach(() => {
    optimizer = new PerformanceOptimizer({
      maxCacheSize: 100,
      cacheExpiryMs: 5000 // 5 seconds for testing
    });
    jest.clearAllMocks();
  });

  describe('Content Caching', () => {
    it('should cache and retrieve processed content', () => {
      const filePath = 'test.md';
      const content = '# Test Content';
      const processedHtml = '<h1>Test Content</h1>';

      optimizer.cacheContent(filePath, content, processedHtml);
      const cached = optimizer.getCachedContent(filePath, content);

      expect(cached).toBe(processedHtml);
    });

    it('should return null for non-existent cache entries', () => {
      const cached = optimizer.getCachedContent('nonexistent.md', 'content');
      expect(cached).toBeNull();
    });

    it('should return null when content has changed', () => {
      const filePath = 'test.md';
      const originalContent = '# Original Content';
      const changedContent = '# Changed Content';
      const processedHtml = '<h1>Original Content</h1>';

      optimizer.cacheContent(filePath, originalContent, processedHtml);
      const cached = optimizer.getCachedContent(filePath, changedContent);

      expect(cached).toBeNull();
    });

    it('should expire cached content after timeout', async () => {
      const filePath = 'test.md';
      const content = '# Test Content';
      const processedHtml = '<h1>Test Content</h1>';

      optimizer.cacheContent(filePath, content, processedHtml);
      
      // Wait for cache to expire
      await new Promise(resolve => setTimeout(resolve, 6000));
      
      const cached = optimizer.getCachedContent(filePath, content);
      expect(cached).toBeNull();
    }, 7000);

    it('should handle cache size limits', () => {
      const smallOptimizer = new PerformanceOptimizer({ maxCacheSize: 2 });

      // Add more items than cache size
      smallOptimizer.cacheContent('file1.md', 'content1', 'html1');
      smallOptimizer.cacheContent('file2.md', 'content2', 'html2');
      smallOptimizer.cacheContent('file3.md', 'content3', 'html3');

      const stats = smallOptimizer.getCacheStatistics();
      expect(stats.contentCache.size).toBeLessThanOrEqual(2);
    });
  });

  describe('Authentication Token Caching', () => {
    it('should cache and retrieve auth tokens', () => {
      const key = 'salesforce_token';
      const token = 'abc123token';
      const expiresIn = 3600; // 1 hour

      optimizer.cacheAuthToken(key, token, expiresIn);
      const cached = optimizer.getCachedAuthToken(key);

      expect(cached).toBe(token);
    });

    it('should return null for expired tokens', async () => {
      const key = 'salesforce_token';
      const token = 'abc123token';
      const expiresIn = 1; // 1 second

      optimizer.cacheAuthToken(key, token, expiresIn);
      
      // Wait for token to expire
      await new Promise(resolve => setTimeout(resolve, 2000));
      
      const cached = optimizer.getCachedAuthToken(key);
      expect(cached).toBeNull();
    }, 3000);

    it('should return null for non-existent tokens', () => {
      const cached = optimizer.getCachedAuthToken('nonexistent_key');
      expect(cached).toBeNull();
    });
  });

  describe('File Streaming', () => {
    it('should create file stream and read content', async () => {
      const filePath = 'test.md';
      const content = '# Test Content\n\nThis is test content.';
      
      // Mock createReadStream
      const mockStream = {
        on: jest.fn((event, callback) => {
          if (event === 'data') {
            callback(Buffer.from(content));
          } else if (event === 'end') {
            callback();
          }
          return mockStream;
        }),
        destroy: jest.fn()
      };

      mockFs.createReadStream = jest.fn().mockReturnValue(mockStream);

      const result = await optimizer.createFileStream(filePath);
      expect(result).toBe(content);
    });

    it('should handle file read errors', async () => {
      const filePath = 'nonexistent.md';
      
      const mockStream = {
        on: jest.fn((event, callback) => {
          if (event === 'error') {
            callback(new Error('File not found'));
          }
          return mockStream;
        }),
        destroy: jest.fn()
      };

      mockFs.createReadStream = jest.fn().mockReturnValue(mockStream);

      await expect(optimizer.createFileStream(filePath)).rejects.toThrow('Failed to read file');
    });

    it('should respect memory limits', async () => {
      const filePath = 'large.md';
      const largeContent = 'x'.repeat(2 * 1024 * 1024); // 2MB
      
      const mockStream = {
        on: jest.fn((event, callback) => {
          if (event === 'data') {
            callback(Buffer.from(largeContent));
          }
          return mockStream;
        }),
        destroy: jest.fn()
      };

      mockFs.createReadStream = jest.fn().mockReturnValue(mockStream);

      await expect(
        optimizer.createFileStream(filePath, { maxMemoryMB: 1 })
      ).rejects.toThrow('exceeds memory limit');
    });
  });

  describe('Batch Processing', () => {
    it('should process items in batches', async () => {
      const items = [1, 2, 3, 4, 5];
      const processor = jest.fn().mockImplementation(async (item: number) => item * 2);

      const results = await optimizer.processInOptimizedBatches(items, processor, {
        batchSize: 2,
        concurrency: 1
      });

      expect(results).toEqual([2, 4, 6, 8, 10]);
      expect(processor).toHaveBeenCalledTimes(5);
    });

    it('should handle processing errors gracefully', async () => {
      const items = [1, 2, 3];
      const processor = jest.fn().mockImplementation(async (item: number) => {
        if (item === 2) {
          throw new Error('Processing failed');
        }
        return item * 2;
      });

      await expect(
        optimizer.processInOptimizedBatches(items, processor)
      ).rejects.toThrow('Processing failed');
    });

    it('should respect memory thresholds', async () => {
      const items = [1, 2, 3];
      const processor = jest.fn().mockResolvedValue('result');

      // Mock process.memoryUsage to return high memory usage
      const originalMemoryUsage = process.memoryUsage;
      process.memoryUsage = jest.fn().mockReturnValue({
        heapUsed: 600 * 1024 * 1024, // 600MB
        heapTotal: 1024 * 1024 * 1024,
        external: 0,
        rss: 1024 * 1024 * 1024
      });

      const results = await optimizer.processInOptimizedBatches(items, processor, {
        memoryThresholdMB: 500
      });

      expect(results).toHaveLength(3);
      
      // Restore original function
      process.memoryUsage = originalMemoryUsage;
    });
  });

  describe('Content Analysis and Optimization', () => {
    it('should analyze content characteristics', () => {
      const content = `# Large Document

This is a large document with many features.

\`\`\`javascript
// Large code block
const largeCode = 'x'.repeat(2000);
\`\`\`

| Column 1 | Column 2 | Column 3 |
|----------|----------|----------|
${'| Data | Data | Data |\n'.repeat(30)}

[Link 1](file1.md) [Link 2](file2.md) [Link 3](file3.md)
![Image](image.png)
`;

      const optimized = optimizer.optimizeContentProcessing(content);

      expect(optimized.analysis.hasLargeCodeBlocks).toBe(true);
      expect(optimized.analysis.hasComplexTables).toBe(true);
      expect(optimized.analysis.hasManyLinks).toBe(false); // Only 3 links
      expect(optimized.analysis.hasImages).toBe(true);
      expect(optimized.optimizations).toContain('lazy_code_highlighting');
      expect(optimized.optimizations).toContain('table_streaming');
    });

    it('should identify large content', () => {
      const largeContent = 'word '.repeat(15000); // 15k words
      const optimized = optimizer.optimizeContentProcessing(largeContent);

      expect(optimized.analysis.isLarge).toBe(true);
      expect(optimized.optimizations).toContain('chunk_processing');
    });

    it('should handle empty content', () => {
      const optimized = optimizer.optimizeContentProcessing('');

      expect(optimized.analysis.wordCount).toBe(1); // Empty string splits to ['']
      expect(optimized.analysis.isLarge).toBe(false);
      expect(optimized.optimizations).toHaveLength(0);
    });
  });

  describe('Cache Statistics', () => {
    it('should provide cache statistics', () => {
      optimizer.cacheContent('file1.md', 'content1', 'html1');
      optimizer.cacheAuthToken('token1', 'abc123', 3600);

      const stats = optimizer.getCacheStatistics();

      expect(stats.contentCache.size).toBe(1);
      expect(stats.authCache.size).toBe(1);
      expect(typeof stats.totalMemoryUsage).toBe('number');
    });

    it('should track expired entries', async () => {
      const shortLivedOptimizer = new PerformanceOptimizer({ cacheExpiryMs: 100 });
      
      shortLivedOptimizer.cacheContent('file1.md', 'content1', 'html1');
      
      // Wait for cache to expire
      await new Promise(resolve => setTimeout(resolve, 200));
      
      const stats = shortLivedOptimizer.getCacheStatistics();
      expect(stats.contentCache.expiredEntries).toBe(1);
    }, 1000);
  });

  describe('Cache Management', () => {
    it('should clear all caches', () => {
      optimizer.cacheContent('file1.md', 'content1', 'html1');
      optimizer.cacheAuthToken('token1', 'abc123', 3600);

      optimizer.clearCaches();

      const stats = optimizer.getCacheStatistics();
      expect(stats.contentCache.size).toBe(0);
      expect(stats.authCache.size).toBe(0);
    });
  });
});

describe('RateLimiter', () => {
  let rateLimiter: RateLimiter;

  beforeEach(() => {
    rateLimiter = new RateLimiter({
      maxRequests: 3,
      windowMs: 1000, // 1 second
      delayMs: 100
    });
  });

  describe('Rate Limiting', () => {
    it('should allow requests within limit', async () => {
      const startTime = Date.now();

      await rateLimiter.waitIfNeeded();
      await rateLimiter.waitIfNeeded();
      await rateLimiter.waitIfNeeded();

      const endTime = Date.now();
      expect(endTime - startTime).toBeLessThan(500); // Should be fast
    });

    it('should delay requests when limit is exceeded', async () => {
      const startTime = Date.now();

      // Make 3 requests quickly (within limit)
      await rateLimiter.waitIfNeeded();
      await rateLimiter.waitIfNeeded();
      await rateLimiter.waitIfNeeded();

      // 4th request should be delayed
      await rateLimiter.waitIfNeeded();

      const endTime = Date.now();
      expect(endTime - startTime).toBeGreaterThan(1000); // Should wait for window
    }, 2000);

    it('should provide accurate status information', async () => {
      await rateLimiter.waitIfNeeded();
      await rateLimiter.waitIfNeeded();

      const status = rateLimiter.getStatus();

      expect(status.requestsInWindow).toBe(2);
      expect(status.maxRequests).toBe(3);
      expect(status.remainingRequests).toBe(1);
      expect(status.windowMs).toBe(1000);
    });

    it('should reset after window expires', async () => {
      // Fill up the rate limit
      await rateLimiter.waitIfNeeded();
      await rateLimiter.waitIfNeeded();
      await rateLimiter.waitIfNeeded();

      // Wait for window to reset
      await new Promise(resolve => setTimeout(resolve, 1100));

      const status = rateLimiter.getStatus();
      expect(status.requestsInWindow).toBe(0);
      expect(status.remainingRequests).toBe(3);
    }, 2000);
  });

  describe('Edge Cases', () => {
    it('should handle zero delay configuration', async () => {
      const noDelayLimiter = new RateLimiter({
        maxRequests: 2,
        windowMs: 1000,
        delayMs: 0
      });

      const startTime = Date.now();
      await noDelayLimiter.waitIfNeeded();
      await noDelayLimiter.waitIfNeeded();
      await noDelayLimiter.waitIfNeeded(); // Should still wait for window
      const endTime = Date.now();

      expect(endTime - startTime).toBeGreaterThan(900);
    }, 2000);

    it('should handle very small windows', async () => {
      const fastLimiter = new RateLimiter({
        maxRequests: 1,
        windowMs: 100,
        delayMs: 0
      });

      await fastLimiter.waitIfNeeded();
      
      const startTime = Date.now();
      await fastLimiter.waitIfNeeded();
      const endTime = Date.now();

      expect(endTime - startTime).toBeGreaterThan(90);
    }, 1000);
  });
});