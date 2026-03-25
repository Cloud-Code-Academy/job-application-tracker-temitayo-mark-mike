/**
 * Enhanced batch processing system with performance optimizations
 */

import { PerformanceOptimizer, RateLimiter } from '../utils/PerformanceOptimizer';
import { ProgressTracker } from './ProgressTracker';
import { ErrorHandler } from './ErrorHandler';

export class BatchProcessor {
  private performanceOptimizer: PerformanceOptimizer;
  private rateLimiter: RateLimiter;
  private errorHandler: ErrorHandler;
  private config: BatchProcessorConfig;

  constructor(config: BatchProcessorConfig) {
    this.config = {
      batchSize: 10,
      concurrency: 3,
      memoryThresholdMB: 500,
      rateLimitRequests: 100,
      rateLimitWindowMs: 60000, // 1 minute
      enableCaching: true,
      enableStreaming: true,
      ...config
    };

    this.performanceOptimizer = new PerformanceOptimizer({
      maxCacheSize: this.config.maxCacheSize || 1000,
      cacheExpiryMs: this.config.cacheExpiryMs || 30 * 60 * 1000
    });

    this.rateLimiter = this.performanceOptimizer.createRateLimiter({
      maxRequests: this.config.rateLimitRequests!,
      windowMs: this.config.rateLimitWindowMs!,
      delayMs: this.config.rateLimitDelayMs || 100
    });

    this.errorHandler = new ErrorHandler({
      maxRetries: this.config.maxRetries || 3,
      baseDelay: this.config.baseRetryDelay || 1000,
      maxDelay: this.config.maxRetryDelay || 30000,
      backoffMultiplier: this.config.backoffMultiplier || 2
    });
  }

  /**
   * Process items in optimized batches with comprehensive performance monitoring
   */
  public async processBatches<T, R>(
    items: T[],
    processor: BatchItemProcessor<T, R>,
    progressTracker?: ProgressTracker,
    options: ProcessingOptions = {}
  ): Promise<BatchProcessingResult<R>> {
    const startTime = Date.now();
    const results: R[] = [];
    const errors: BatchError[] = [];
    const metrics = new ProcessingMetrics();

    // Initialize progress tracking
    if (progressTracker) {
      progressTracker.updateBatchProgress(0, items.length);
    }

    // Process items in optimized batches
    const batchResults = await this.performanceOptimizer.processInOptimizedBatches(
      items,
      async (item: T) => {
        return this.processItemWithOptimizations(item, processor, metrics, options);
      },
      {
        batchSize: this.config.batchSize,
        concurrency: this.config.concurrency,
        memoryThresholdMB: this.config.memoryThresholdMB,
        delayBetweenBatches: this.config.delayBetweenBatches
      }
    );

    // Separate successful results from errors
    for (const result of batchResults) {
      if (result.success) {
        results.push(result.data);
      } else {
        errors.push({
          item: result.item,
          error: result.error,
          retryCount: result.retryCount || 0,
          timestamp: Date.now()
        });
      }
    }

    // Update final progress
    if (progressTracker) {
      progressTracker.updateBatchProgress(items.length, items.length);
    }

    const duration = Date.now() - startTime;
    const cacheStats = this.performanceOptimizer.getCacheStatistics();

    return {
      results,
      errors,
      metrics: {
        totalItems: items.length,
        successfulItems: results.length,
        failedItems: errors.length,
        duration,
        averageTimePerItem: duration / items.length,
        cacheHitRate: cacheStats.contentCache.hitRate,
        memoryUsage: cacheStats.totalMemoryUsage,
        rateLimitStatus: this.rateLimiter.getStatus(),
        performanceMetrics: metrics.getMetrics()
      }
    };
  }

  /**
   * Process large files with streaming to minimize memory usage
   */
  public async processLargeFile(
    filePath: string,
    processor: (content: string) => Promise<string>,
    options: LargeFileOptions = {}
  ): Promise<LargeFileResult> {
    const startTime = Date.now();
    
    try {
      // Check if content is cached
      let content: string;
      
      if (this.config.enableCaching) {
        // Try to get from cache first (we need to read a small portion to check hash)
        const previewContent = await this.performanceOptimizer.createFileStream(filePath, {
          chunkSize: 1024 // Just read first 1KB for hash check
        });
        
        const cachedContent = this.performanceOptimizer.getCachedContent(filePath, previewContent);
        if (cachedContent) {
          return {
            success: true,
            processedContent: cachedContent,
            fromCache: true,
            duration: Date.now() - startTime,
            memoryUsed: 0
          };
        }
      }

      // Stream the full file
      const memoryBefore = process.memoryUsage().heapUsed;
      
      if (this.config.enableStreaming) {
        content = await this.performanceOptimizer.createFileStream(filePath, {
          chunkSize: options.chunkSize || 64 * 1024,
          maxMemoryMB: options.maxMemoryMB || 100
        });
      } else {
        const fs = require('fs');
        content = fs.readFileSync(filePath, 'utf8');
      }

      // Process content with optimizations
      const optimizedContent = this.performanceOptimizer.optimizeContentProcessing(content);
      const processedContent = await processor(optimizedContent.content);

      // Cache the result
      if (this.config.enableCaching) {
        this.performanceOptimizer.cacheContent(filePath, content, processedContent);
      }

      const memoryAfter = process.memoryUsage().heapUsed;
      const duration = Date.now() - startTime;

      return {
        success: true,
        processedContent,
        fromCache: false,
        duration,
        memoryUsed: memoryAfter - memoryBefore,
        optimizations: optimizedContent.optimizations,
        contentAnalysis: optimizedContent.analysis
      };

    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : String(error),
        duration: Date.now() - startTime,
        memoryUsed: 0
      };
    }
  }

  /**
   * Process API calls with rate limiting and caching
   */
  public async processApiCall<T>(
    apiCall: () => Promise<T>,
    cacheKey?: string,
    options: ApiCallOptions = {}
  ): Promise<ApiCallResult<T>> {
    const startTime = Date.now();

    try {
      // Check cache first
      if (cacheKey && this.config.enableCaching) {
        const cachedResult = this.performanceOptimizer.getCachedAuthToken(cacheKey);
        if (cachedResult) {
          return {
            success: true,
            data: JSON.parse(cachedResult) as T,
            fromCache: true,
            duration: Date.now() - startTime,
            rateLimitStatus: this.rateLimiter.getStatus()
          };
        }
      }

      // Apply rate limiting
      await this.rateLimiter.waitIfNeeded();

      // Make the API call
      const result = await apiCall();

      // Cache the result if specified
      if (cacheKey && options.cacheDurationMs) {
        this.performanceOptimizer.cacheAuthToken(
          cacheKey,
          JSON.stringify(result),
          options.cacheDurationMs / 1000
        );
      }

      return {
        success: true,
        data: result,
        fromCache: false,
        duration: Date.now() - startTime,
        rateLimitStatus: this.rateLimiter.getStatus()
      };

    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : String(error),
        duration: Date.now() - startTime,
        rateLimitStatus: this.rateLimiter.getStatus()
      };
    }
  }

  /**
   * Get comprehensive performance statistics
   */
  public getPerformanceStatistics(): PerformanceStatistics {
    const cacheStats = this.performanceOptimizer.getCacheStatistics();
    const rateLimitStatus = this.rateLimiter.getStatus();
    const memoryUsage = process.memoryUsage();

    return {
      cache: cacheStats,
      rateLimit: rateLimitStatus,
      memory: {
        heapUsed: memoryUsage.heapUsed,
        heapTotal: memoryUsage.heapTotal,
        external: memoryUsage.external,
        rss: memoryUsage.rss
      },
      config: this.config
    };
  }

  /**
   * Clear all caches and reset performance counters
   */
  public reset(): void {
    this.performanceOptimizer.clearCaches();
  }

  // Private methods

  private async processItemWithOptimizations<T, R>(
    item: T,
    processor: BatchItemProcessor<T, R>,
    metrics: ProcessingMetrics,
    options: ProcessingOptions
  ): Promise<BatchItemResult<T, R>> {
    const startTime = Date.now();
    let retryCount = 0;

    while (retryCount <= (this.config.maxRetries || 3)) {
      try {
        metrics.incrementAttempts();

        // Apply rate limiting for API calls
        if (options.respectRateLimit !== false) {
          await this.rateLimiter.waitIfNeeded();
        }

        // Process the item
        const result = await processor(item);
        
        metrics.incrementSuccesses();
        metrics.addProcessingTime(Date.now() - startTime);

        return {
          success: true,
          data: result,
          item,
          retryCount,
          duration: Date.now() - startTime
        };

      } catch (error) {
        retryCount++;
        metrics.incrementErrors();

        // Check if we should retry
        const shouldRetry = retryCount <= (this.config.maxRetries || 3) && 
                           this.shouldRetryError(error);

        if (!shouldRetry) {
          return {
            success: false,
            error: error instanceof Error ? error.message : String(error),
            item,
            retryCount,
            duration: Date.now() - startTime
          };
        }

        // Wait before retry with exponential backoff
        const delay = this.calculateRetryDelay(retryCount);
        await this.delay(delay);
      }
    }

    // This should never be reached, but TypeScript requires it
    return {
      success: false,
      error: 'Maximum retries exceeded',
      item,
      retryCount,
      duration: Date.now() - startTime
    };
  }

  private shouldRetryError(error: any): boolean {
    // Retry on network errors, rate limit errors, and temporary failures
    const errorMessage = error?.message?.toLowerCase() || '';
    return errorMessage.includes('network') ||
           errorMessage.includes('timeout') ||
           errorMessage.includes('rate limit') ||
           errorMessage.includes('temporary') ||
           errorMessage.includes('503') ||
           errorMessage.includes('502');
  }

  private calculateRetryDelay(attempt: number): number {
    const baseDelay = this.config.baseRetryDelay || 1000;
    const multiplier = this.config.backoffMultiplier || 2;
    const maxDelay = this.config.maxRetryDelay || 30000;
    
    const delay = baseDelay * Math.pow(multiplier, attempt - 1);
    return Math.min(delay, maxDelay);
  }

  private async delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}

/**
 * Performance metrics collector
 */
class ProcessingMetrics {
  private attempts = 0;
  private successes = 0;
  private errors = 0;
  private totalProcessingTime = 0;

  incrementAttempts(): void {
    this.attempts++;
  }

  incrementSuccesses(): void {
    this.successes++;
  }

  incrementErrors(): void {
    this.errors++;
  }

  addProcessingTime(time: number): void {
    this.totalProcessingTime += time;
  }

  getMetrics(): ProcessingMetricsData {
    return {
      attempts: this.attempts,
      successes: this.successes,
      errors: this.errors,
      successRate: this.attempts > 0 ? this.successes / this.attempts : 0,
      averageProcessingTime: this.successes > 0 ? this.totalProcessingTime / this.successes : 0
    };
  }
}

// Type definitions

export interface BatchProcessorConfig {
  batchSize?: number;
  concurrency?: number;
  memoryThresholdMB?: number;
  rateLimitRequests?: number;
  rateLimitWindowMs?: number;
  rateLimitDelayMs?: number;
  enableCaching?: boolean;
  enableStreaming?: boolean;
  maxCacheSize?: number;
  cacheExpiryMs?: number;
  maxRetries?: number;
  baseRetryDelay?: number;
  maxRetryDelay?: number;
  backoffMultiplier?: number;
  delayBetweenBatches?: number;
}

export interface ProcessingOptions {
  respectRateLimit?: boolean;
  enableCaching?: boolean;
  priority?: 'low' | 'normal' | 'high';
}

export interface LargeFileOptions {
  chunkSize?: number;
  maxMemoryMB?: number;
}

export interface ApiCallOptions {
  cacheDurationMs?: number;
  priority?: 'low' | 'normal' | 'high';
}

export type BatchItemProcessor<T, R> = (item: T) => Promise<R>;

export interface BatchItemResult<T, R> {
  success: boolean;
  data?: R;
  error?: string;
  item: T;
  retryCount: number;
  duration: number;
}

export interface BatchError {
  item: any;
  error: string;
  retryCount: number;
  timestamp: number;
}

export interface BatchProcessingResult<R> {
  results: R[];
  errors: BatchError[];
  metrics: BatchProcessingMetrics;
}

export interface BatchProcessingMetrics {
  totalItems: number;
  successfulItems: number;
  failedItems: number;
  duration: number;
  averageTimePerItem: number;
  cacheHitRate: number;
  memoryUsage: number;
  rateLimitStatus: any;
  performanceMetrics: ProcessingMetricsData;
}

export interface ProcessingMetricsData {
  attempts: number;
  successes: number;
  errors: number;
  successRate: number;
  averageProcessingTime: number;
}

export interface LargeFileResult {
  success: boolean;
  processedContent?: string;
  error?: string;
  fromCache: boolean;
  duration: number;
  memoryUsed: number;
  optimizations?: string[];
  contentAnalysis?: any;
}

export interface ApiCallResult<T> {
  success: boolean;
  data?: T;
  error?: string;
  fromCache: boolean;
  duration: number;
  rateLimitStatus: any;
}

export interface PerformanceStatistics {
  cache: any;
  rateLimit: any;
  memory: {
    heapUsed: number;
    heapTotal: number;
    external: number;
    rss: number;
  };
  config: BatchProcessorConfig;
}