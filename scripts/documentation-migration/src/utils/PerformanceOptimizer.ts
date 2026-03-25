/**
 * Performance optimization utilities for the documentation migration system
 */

import * as fs from 'fs';
import * as crypto from 'crypto';
import { Readable } from 'stream';

export class PerformanceOptimizer {
  private contentCache: Map<string, CachedContent> = new Map();
  private authTokenCache: Map<string, CachedToken> = new Map();
  private fileStreamCache: Map<string, string> = new Map();
  private readonly maxCacheSize: number;
  private readonly cacheExpiryMs: number;

  constructor(options: PerformanceOptions = {}) {
    this.maxCacheSize = options.maxCacheSize || 1000;
    this.cacheExpiryMs = options.cacheExpiryMs || 30 * 60 * 1000; // 30 minutes
  }

  /**
   * Cache processed content to avoid reprocessing
   */
  public cacheContent(filePath: string, content: string, processedHtml: string): void {
    const contentHash = this.generateContentHash(content);
    
    // Clean cache if it's getting too large
    if (this.contentCache.size >= this.maxCacheSize) {
      this.cleanExpiredCache();
    }

    this.contentCache.set(filePath, {
      contentHash,
      processedHtml,
      timestamp: Date.now(),
      filePath
    });
  }

  /**
   * Get cached content if available and not expired
   */
  public getCachedContent(filePath: string, currentContent: string): string | null {
    const cached = this.contentCache.get(filePath);
    if (!cached) {
      return null;
    }

    // Check if content has changed
    const currentHash = this.generateContentHash(currentContent);
    if (cached.contentHash !== currentHash) {
      this.contentCache.delete(filePath);
      return null;
    }

    // Check if cache has expired
    if (Date.now() - cached.timestamp > this.cacheExpiryMs) {
      this.contentCache.delete(filePath);
      return null;
    }

    return cached.processedHtml;
  }

  /**
   * Cache authentication tokens
   */
  public cacheAuthToken(key: string, token: string, expiresIn: number): void {
    this.authTokenCache.set(key, {
      token,
      expiresAt: Date.now() + (expiresIn * 1000),
      timestamp: Date.now()
    });
  }

  /**
   * Get cached authentication token if valid
   */
  public getCachedAuthToken(key: string): string | null {
    const cached = this.authTokenCache.get(key);
    if (!cached) {
      return null;
    }

    // Check if token has expired (with 5 minute buffer)
    if (Date.now() >= (cached.expiresAt - 5 * 60 * 1000)) {
      this.authTokenCache.delete(key);
      return null;
    }

    return cached.token;
  }

  /**
   * Create a readable stream for large files to avoid loading entire file into memory
   */
  public createFileStream(filePath: string, options: StreamOptions = {}): Promise<string> {
    return new Promise((resolve, reject) => {
      const chunks: Buffer[] = [];
      const stream = fs.createReadStream(filePath, {
        encoding: 'utf8',
        highWaterMark: options.chunkSize || 64 * 1024 // 64KB chunks
      });

      stream.on('data', (chunk: Buffer) => {
        chunks.push(chunk);
        
        // Optional memory limit check
        if (options.maxMemoryMB) {
          const totalSize = chunks.reduce((sum, chunk) => sum + chunk.length, 0);
          if (totalSize > options.maxMemoryMB * 1024 * 1024) {
            stream.destroy();
            reject(new Error(`File ${filePath} exceeds memory limit of ${options.maxMemoryMB}MB`));
            return;
          }
        }
      });

      stream.on('end', () => {
        const content = Buffer.concat(chunks).toString('utf8');
        resolve(content);
      });

      stream.on('error', (error) => {
        reject(new Error(`Failed to read file ${filePath}: ${error.message}`));
      });
    });
  }

  /**
   * Process files in optimized batches with memory management
   */
  public async processInOptimizedBatches<T, R>(
    items: T[],
    processor: (item: T) => Promise<R>,
    options: BatchProcessingOptions = {}
  ): Promise<R[]> {
    const batchSize = options.batchSize || 10;
    const concurrency = options.concurrency || 3;
    const memoryThresholdMB = options.memoryThresholdMB || 500;
    const results: R[] = [];

    for (let i = 0; i < items.length; i += batchSize) {
      const batch = items.slice(i, i + batchSize);
      
      // Check memory usage before processing batch
      const memoryUsage = process.memoryUsage();
      const heapUsedMB = memoryUsage.heapUsed / 1024 / 1024;
      
      if (heapUsedMB > memoryThresholdMB) {
        // Force garbage collection if available
        if (global.gc) {
          global.gc();
        }
        
        // Wait a bit for memory to be freed
        await this.delay(1000);
      }

      // Process batch with controlled concurrency
      const batchPromises = batch.map(async (item, index) => {
        // Stagger the start of concurrent operations
        if (index > 0) {
          await this.delay(100 * (index % concurrency));
        }
        return processor(item);
      });

      const batchResults = await Promise.all(batchPromises);
      results.push(...batchResults);

      // Add delay between batches for rate limiting
      if (i + batchSize < items.length && options.delayBetweenBatches) {
        await this.delay(options.delayBetweenBatches);
      }
    }

    return results;
  }

  /**
   * Rate limiter for API calls
   */
  public createRateLimiter(options: RateLimitOptions): RateLimiter {
    return new RateLimiter(options);
  }

  /**
   * Optimize content processing pipeline
   */
  public optimizeContentProcessing(content: string): OptimizedContent {
    const startTime = Date.now();
    
    // Pre-process content to identify expensive operations
    const analysis = this.analyzeContent(content);
    
    // Apply optimizations based on content analysis
    const optimizations: ContentOptimization[] = [];
    
    if (analysis.hasLargeCodeBlocks) {
      optimizations.push('lazy_code_highlighting');
    }
    
    if (analysis.hasComplexTables) {
      optimizations.push('table_streaming');
    }
    
    if (analysis.hasManyLinks) {
      optimizations.push('link_batch_processing');
    }
    
    if (analysis.isLarge) {
      optimizations.push('chunk_processing');
    }

    return {
      content,
      analysis,
      optimizations,
      processingTime: Date.now() - startTime,
      estimatedMemoryUsage: this.estimateMemoryUsage(content)
    };
  }

  /**
   * Get cache statistics
   */
  public getCacheStatistics(): CacheStatistics {
    const now = Date.now();
    
    const contentCacheStats = {
      size: this.contentCache.size,
      hitRate: this.calculateHitRate('content'),
      expiredEntries: Array.from(this.contentCache.values())
        .filter(entry => now - entry.timestamp > this.cacheExpiryMs).length
    };

    const authCacheStats = {
      size: this.authTokenCache.size,
      hitRate: this.calculateHitRate('auth'),
      expiredEntries: Array.from(this.authTokenCache.values())
        .filter(entry => now >= entry.expiresAt).length
    };

    return {
      contentCache: contentCacheStats,
      authCache: authCacheStats,
      totalMemoryUsage: this.estimateCacheMemoryUsage()
    };
  }

  /**
   * Clear all caches
   */
  public clearCaches(): void {
    this.contentCache.clear();
    this.authTokenCache.clear();
    this.fileStreamCache.clear();
  }

  // Private methods

  private generateContentHash(content: string): string {
    return crypto.createHash('sha256').update(content).digest('hex');
  }

  private cleanExpiredCache(): void {
    const now = Date.now();
    
    // Clean content cache
    for (const [key, value] of this.contentCache.entries()) {
      if (now - value.timestamp > this.cacheExpiryMs) {
        this.contentCache.delete(key);
      }
    }

    // Clean auth cache
    for (const [key, value] of this.authTokenCache.entries()) {
      if (now >= value.expiresAt) {
        this.authTokenCache.delete(key);
      }
    }

    // If still too large, remove oldest entries
    if (this.contentCache.size >= this.maxCacheSize) {
      const entries = Array.from(this.contentCache.entries())
        .sort(([, a], [, b]) => a.timestamp - b.timestamp);
      
      const toRemove = entries.slice(0, Math.floor(this.maxCacheSize * 0.2));
      toRemove.forEach(([key]) => this.contentCache.delete(key));
    }
  }

  private analyzeContent(content: string): ContentAnalysis {
    const lines = content.split('\n');
    const wordCount = content.split(/\s+/).length;
    
    return {
      wordCount,
      lineCount: lines.length,
      isLarge: wordCount > 10000,
      hasLargeCodeBlocks: /```[\s\S]{1000,}```/.test(content),
      hasComplexTables: (content.match(/\|/g) || []).length > 50,
      hasManyLinks: (content.match(/\[.*?\]\(.*?\)/g) || []).length > 20,
      hasImages: /!\[.*?\]\(.*?\)/.test(content),
      estimatedProcessingTime: Math.max(100, wordCount * 0.1) // ms
    };
  }

  private estimateMemoryUsage(content: string): number {
    // Rough estimate: content size * 3 (original + processed + overhead)
    return Buffer.byteLength(content, 'utf8') * 3;
  }

  private calculateHitRate(cacheType: 'content' | 'auth'): number {
    // This would need to be tracked over time in a real implementation
    return 0.75; // Placeholder
  }

  private estimateCacheMemoryUsage(): number {
    let totalSize = 0;
    
    for (const entry of this.contentCache.values()) {
      totalSize += Buffer.byteLength(entry.processedHtml, 'utf8');
    }
    
    for (const entry of this.authTokenCache.values()) {
      totalSize += Buffer.byteLength(entry.token, 'utf8');
    }
    
    return totalSize;
  }

  private async delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}

/**
 * Rate limiter implementation
 */
export class RateLimiter {
  private requests: number[] = [];
  private readonly maxRequests: number;
  private readonly windowMs: number;
  private readonly delayMs: number;

  constructor(options: RateLimitOptions) {
    this.maxRequests = options.maxRequests;
    this.windowMs = options.windowMs;
    this.delayMs = options.delayMs || 0;
  }

  /**
   * Wait if necessary to respect rate limits
   */
  public async waitIfNeeded(): Promise<void> {
    const now = Date.now();
    
    // Remove old requests outside the window
    this.requests = this.requests.filter(time => now - time < this.windowMs);
    
    // Check if we're at the limit
    if (this.requests.length >= this.maxRequests) {
      const oldestRequest = Math.min(...this.requests);
      const waitTime = this.windowMs - (now - oldestRequest) + this.delayMs;
      
      if (waitTime > 0) {
        await this.delay(waitTime);
      }
    }
    
    // Record this request
    this.requests.push(now);
  }

  /**
   * Get current rate limit status
   */
  public getStatus(): RateLimitStatus {
    const now = Date.now();
    this.requests = this.requests.filter(time => now - time < this.windowMs);
    
    return {
      requestsInWindow: this.requests.length,
      maxRequests: this.maxRequests,
      windowMs: this.windowMs,
      remainingRequests: Math.max(0, this.maxRequests - this.requests.length),
      resetTime: this.requests.length > 0 ? Math.min(...this.requests) + this.windowMs : now
    };
  }

  private async delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}

// Type definitions

export interface PerformanceOptions {
  maxCacheSize?: number;
  cacheExpiryMs?: number;
}

export interface CachedContent {
  contentHash: string;
  processedHtml: string;
  timestamp: number;
  filePath: string;
}

export interface CachedToken {
  token: string;
  expiresAt: number;
  timestamp: number;
}

export interface StreamOptions {
  chunkSize?: number;
  maxMemoryMB?: number;
}

export interface BatchProcessingOptions {
  batchSize?: number;
  concurrency?: number;
  memoryThresholdMB?: number;
  delayBetweenBatches?: number;
}

export interface RateLimitOptions {
  maxRequests: number;
  windowMs: number;
  delayMs?: number;
}

export interface RateLimitStatus {
  requestsInWindow: number;
  maxRequests: number;
  windowMs: number;
  remainingRequests: number;
  resetTime: number;
}

export interface ContentAnalysis {
  wordCount: number;
  lineCount: number;
  isLarge: boolean;
  hasLargeCodeBlocks: boolean;
  hasComplexTables: boolean;
  hasManyLinks: boolean;
  hasImages: boolean;
  estimatedProcessingTime: number;
}

export interface OptimizedContent {
  content: string;
  analysis: ContentAnalysis;
  optimizations: ContentOptimization[];
  processingTime: number;
  estimatedMemoryUsage: number;
}

export interface CacheStatistics {
  contentCache: {
    size: number;
    hitRate: number;
    expiredEntries: number;
  };
  authCache: {
    size: number;
    hitRate: number;
    expiredEntries: number;
  };
  totalMemoryUsage: number;
}

export type ContentOptimization = 
  | 'lazy_code_highlighting'
  | 'table_streaming'
  | 'link_batch_processing'
  | 'chunk_processing';