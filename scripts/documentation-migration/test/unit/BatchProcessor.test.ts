/**
 * Unit tests for BatchProcessor class
 */

import { BatchProcessor } from '../../src/core/BatchProcessor';
import { ProgressTracker } from '../../src/core/ProgressTracker';

// Mock dependencies
jest.mock('../../src/utils/PerformanceOptimizer');
jest.mock('../../src/core/ErrorHandler');

describe('BatchProcessor', () => {
  let batchProcessor: BatchProcessor;

  beforeEach(() => {
    batchProcessor = new BatchProcessor({
      batchSize: 3,
      concurrency: 2,
      memoryThresholdMB: 100,
      rateLimitRequests: 10,
      rateLimitWindowMs: 1000,
      enableCaching: true,
      enableStreaming: true
    });
  });

  describe('Batch Processing', () => {
    it('should process items in batches successfully', async () => {
      const items = [1, 2, 3, 4, 5];
      const processor = jest.fn().mockImplementation(async (item: number) => item * 2);

      const result = await batchProcessor.processBatches(items, processor);

      expect(result.results).toEqual([2, 4, 6, 8, 10]);
      expect(result.errors).toHaveLength(0);
      expect(result.metrics.totalItems).toBe(5);
      expect(result.metrics.successfulItems).toBe(5);
      expect(result.metrics.failedItems).toBe(0);
      expect(processor).toHaveBeenCalledTimes(5);
    });

    it('should handle processing errors and continue with other items', async () => {
      const items = [1, 2, 3, 4, 5];
      const processor = jest.fn().mockImplementation(async (item: number) => {
        if (item === 3) {
          throw new Error(`Failed to process item ${item}`);
        }
        return item * 2;
      });

      const result = await batchProcessor.processBatches(items, processor);

      expect(result.results).toEqual([2, 4, 8, 10]);
      expect(result.errors).toHaveLength(1);
      expect(result.errors[0].item).toBe(3);
      expect(result.errors[0].error).toContain('Failed to process item 3');
      expect(result.metrics.successfulItems).toBe(4);
      expect(result.metrics.failedItems).toBe(1);
    });

    it('should track progress when progress tracker is provided', async () => {
      const items = [1, 2, 3];
      const processor = jest.fn().mockResolvedValue('result');
      const progressTracker = new ProgressTracker();
      const updateSpy = jest.spyOn(progressTracker, 'updateBatchProgress');

      await batchProcessor.processBatches(items, processor, progressTracker);

      expect(updateSpy).toHaveBeenCalledWith(0, 3); // Initial
      expect(updateSpy).toHaveBeenCalledWith(3, 3); // Final
    });

    it('should respect processing options', async () => {
      const items = [1, 2, 3];
      const processor = jest.fn().mockResolvedValue('result');

      await batchProcessor.processBatches(items, processor, undefined, {
        respectRateLimit: false,
        enableCaching: false
      });

      expect(processor).toHaveBeenCalledTimes(3);
    });

    it('should handle empty item list', async () => {
      const items: number[] = [];
      const processor = jest.fn();

      const result = await batchProcessor.processBatches(items, processor);

      expect(result.results).toHaveLength(0);
      expect(result.errors).toHaveLength(0);
      expect(result.metrics.totalItems).toBe(0);
      expect(processor).not.toHaveBeenCalled();
    });
  });

  describe('Large File Processing', () => {
    it('should process large files with streaming', async () => {
      const filePath = 'large-file.md';
      const processor = jest.fn().mockResolvedValue('processed content');

      // Mock the performance optimizer's createFileStream
      const mockCreateFileStream = jest.fn().mockResolvedValue('file content');
      (batchProcessor as any).performanceOptimizer.createFileStream = mockCreateFileStream;

      const result = await batchProcessor.processLargeFile(filePath, processor);

      expect(result.success).toBe(true);
      expect(result.processedContent).toBe('processed content');
      expect(result.fromCache).toBe(false);
      expect(mockCreateFileStream).toHaveBeenCalledWith(filePath, {
        chunkSize: 64 * 1024,
        maxMemoryMB: 100
      });
    });

    it('should return cached content when available', async () => {
      const filePath = 'cached-file.md';
      const processor = jest.fn();

      // Mock cached content
      const mockGetCachedContent = jest.fn().mockReturnValue('cached html');
      const mockCreateFileStream = jest.fn().mockResolvedValue('preview content');
      (batchProcessor as any).performanceOptimizer.getCachedContent = mockGetCachedContent;
      (batchProcessor as any).performanceOptimizer.createFileStream = mockCreateFileStream;

      const result = await batchProcessor.processLargeFile(filePath, processor);

      expect(result.success).toBe(true);
      expect(result.processedContent).toBe('cached html');
      expect(result.fromCache).toBe(true);
      expect(processor).not.toHaveBeenCalled();
    });

    it('should handle file processing errors', async () => {
      const filePath = 'error-file.md';
      const processor = jest.fn();

      // Mock file stream error
      const mockCreateFileStream = jest.fn().mockRejectedValue(new Error('File not found'));
      (batchProcessor as any).performanceOptimizer.createFileStream = mockCreateFileStream;

      const result = await batchProcessor.processLargeFile(filePath, processor);

      expect(result.success).toBe(false);
      expect(result.error).toContain('File not found');
      expect(result.fromCache).toBe(false);
    });

    it('should respect file size options', async () => {
      const filePath = 'test-file.md';
      const processor = jest.fn().mockResolvedValue('result');
      const options = { chunkSize: 32 * 1024, maxMemoryMB: 50 };

      const mockCreateFileStream = jest.fn().mockResolvedValue('content');
      (batchProcessor as any).performanceOptimizer.createFileStream = mockCreateFileStream;

      await batchProcessor.processLargeFile(filePath, processor, options);

      expect(mockCreateFileStream).toHaveBeenCalledWith(filePath, options);
    });
  });

  describe('API Call Processing', () => {
    it('should process API calls with rate limiting', async () => {
      const apiCall = jest.fn().mockResolvedValue({ data: 'api result' });
      const mockWaitIfNeeded = jest.fn().mockResolvedValue(undefined);
      (batchProcessor as any).rateLimiter.waitIfNeeded = mockWaitIfNeeded;

      const result = await batchProcessor.processApiCall(apiCall);

      expect(result.success).toBe(true);
      expect(result.data).toEqual({ data: 'api result' });
      expect(result.fromCache).toBe(false);
      expect(mockWaitIfNeeded).toHaveBeenCalled();
      expect(apiCall).toHaveBeenCalled();
    });

    it('should return cached API results when available', async () => {
      const apiCall = jest.fn();
      const cacheKey = 'api_cache_key';
      const cachedResult = JSON.stringify({ cached: 'data' });

      const mockGetCachedAuthToken = jest.fn().mockReturnValue(cachedResult);
      (batchProcessor as any).performanceOptimizer.getCachedAuthToken = mockGetCachedAuthToken;

      const result = await batchProcessor.processApiCall(apiCall, cacheKey);

      expect(result.success).toBe(true);
      expect(result.data).toEqual({ cached: 'data' });
      expect(result.fromCache).toBe(true);
      expect(apiCall).not.toHaveBeenCalled();
    });

    it('should handle API call errors', async () => {
      const apiCall = jest.fn().mockRejectedValue(new Error('API Error'));
      const mockWaitIfNeeded = jest.fn().mockResolvedValue(undefined);
      (batchProcessor as any).rateLimiter.waitIfNeeded = mockWaitIfNeeded;

      const result = await batchProcessor.processApiCall(apiCall);

      expect(result.success).toBe(false);
      expect(result.error).toContain('API Error');
      expect(result.fromCache).toBe(false);
    });

    it('should cache API results when specified', async () => {
      const apiCall = jest.fn().mockResolvedValue({ data: 'result' });
      const cacheKey = 'cache_key';
      const options = { cacheDurationMs: 5 * 60 * 1000 };

      const mockCacheAuthToken = jest.fn();
      const mockWaitIfNeeded = jest.fn().mockResolvedValue(undefined);
      (batchProcessor as any).performanceOptimizer.cacheAuthToken = mockCacheAuthToken;
      (batchProcessor as any).rateLimiter.waitIfNeeded = mockWaitIfNeeded;

      await batchProcessor.processApiCall(apiCall, cacheKey, options);

      expect(mockCacheAuthToken).toHaveBeenCalledWith(
        cacheKey,
        JSON.stringify({ data: 'result' }),
        300 // 5 minutes in seconds
      );
    });
  });

  describe('Performance Statistics', () => {
    it('should provide comprehensive performance statistics', () => {
      const mockCacheStats = {
        contentCache: { size: 10, hitRate: 0.8, expiredEntries: 2 },
        authCache: { size: 5, hitRate: 0.9, expiredEntries: 1 },
        totalMemoryUsage: 1024 * 1024
      };

      const mockRateLimitStatus = {
        requestsInWindow: 5,
        maxRequests: 10,
        remainingRequests: 5,
        windowMs: 60000,
        resetTime: Date.now() + 30000
      };

      (batchProcessor as any).performanceOptimizer.getCacheStatistics = jest.fn().mockReturnValue(mockCacheStats);
      (batchProcessor as any).rateLimiter.getStatus = jest.fn().mockReturnValue(mockRateLimitStatus);

      const stats = batchProcessor.getPerformanceStatistics();

      expect(stats.cache).toEqual(mockCacheStats);
      expect(stats.rateLimit).toEqual(mockRateLimitStatus);
      expect(stats.memory).toBeDefined();
      expect(stats.memory.heapUsed).toBeDefined();
      expect(stats.config).toBeDefined();
    });
  });

  describe('Cache Management', () => {
    it('should reset caches and counters', () => {
      const mockClearCaches = jest.fn();
      (batchProcessor as any).performanceOptimizer.clearCaches = mockClearCaches;

      batchProcessor.reset();

      expect(mockClearCaches).toHaveBeenCalled();
    });
  });

  describe('Configuration', () => {
    it('should use default configuration values', () => {
      const defaultProcessor = new BatchProcessor({});
      const stats = defaultProcessor.getPerformanceStatistics();

      expect(stats.config.batchSize).toBe(10);
      expect(stats.config.concurrency).toBe(3);
      expect(stats.config.memoryThresholdMB).toBe(500);
      expect(stats.config.enableCaching).toBe(true);
      expect(stats.config.enableStreaming).toBe(true);
    });

    it('should override default configuration', () => {
      const customProcessor = new BatchProcessor({
        batchSize: 20,
        concurrency: 5,
        memoryThresholdMB: 1000,
        enableCaching: false,
        enableStreaming: false
      });

      const stats = customProcessor.getPerformanceStatistics();

      expect(stats.config.batchSize).toBe(20);
      expect(stats.config.concurrency).toBe(5);
      expect(stats.config.memoryThresholdMB).toBe(1000);
      expect(stats.config.enableCaching).toBe(false);
      expect(stats.config.enableStreaming).toBe(false);
    });
  });

  describe('Error Handling and Retries', () => {
    it('should retry failed operations', async () => {
      const items = [1];
      let attemptCount = 0;
      const processor = jest.fn().mockImplementation(async () => {
        attemptCount++;
        if (attemptCount < 3) {
          throw new Error('Temporary failure');
        }
        return 'success';
      });

      // Mock shouldRetryError to return true for our error
      (batchProcessor as any).shouldRetryError = jest.fn().mockReturnValue(true);

      const result = await batchProcessor.processBatches(items, processor);

      expect(result.results).toEqual(['success']);
      expect(result.errors).toHaveLength(0);
      expect(attemptCount).toBe(3);
    });

    it('should stop retrying after max attempts', async () => {
      const items = [1];
      const processor = jest.fn().mockRejectedValue(new Error('Persistent failure'));

      // Mock shouldRetryError to return true
      (batchProcessor as any).shouldRetryError = jest.fn().mockReturnValue(true);

      const result = await batchProcessor.processBatches(items, processor);

      expect(result.results).toHaveLength(0);
      expect(result.errors).toHaveLength(1);
      expect(result.errors[0].error).toContain('Persistent failure');
      expect(processor).toHaveBeenCalledTimes(4); // Initial + 3 retries
    });

    it('should not retry non-retryable errors', async () => {
      const items = [1];
      const processor = jest.fn().mockRejectedValue(new Error('Validation error'));

      // Mock shouldRetryError to return false
      (batchProcessor as any).shouldRetryError = jest.fn().mockReturnValue(false);

      const result = await batchProcessor.processBatches(items, processor);

      expect(result.results).toHaveLength(0);
      expect(result.errors).toHaveLength(1);
      expect(processor).toHaveBeenCalledTimes(1); // No retries
    });
  });

  describe('Memory Management', () => {
    it('should monitor memory usage during processing', async () => {
      const items = [1, 2, 3];
      const processor = jest.fn().mockResolvedValue('result');

      // Mock high memory usage
      const originalMemoryUsage = process.memoryUsage;
      process.memoryUsage = jest.fn().mockReturnValue({
        heapUsed: 600 * 1024 * 1024, // 600MB
        heapTotal: 1024 * 1024 * 1024,
        external: 0,
        rss: 1024 * 1024 * 1024
      });

      const result = await batchProcessor.processBatches(items, processor);

      expect(result.results).toHaveLength(3);
      expect(result.metrics.memoryUsage).toBeGreaterThan(0);

      // Restore original function
      process.memoryUsage = originalMemoryUsage;
    });
  });
});