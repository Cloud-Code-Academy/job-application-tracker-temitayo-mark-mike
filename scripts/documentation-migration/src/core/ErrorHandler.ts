/**
 * Comprehensive error handling system with categorized errors and retry logic
 */

import { ProcessingContext } from '../types';

export class ErrorHandler {
  private retryConfig: RetryConfig;
  private errorLog: ErrorLogEntry[] = [];
  private errorStats: ErrorStatistics;

  constructor(retryConfig: RetryConfig = {}) {
    this.retryConfig = {
      maxRetries: retryConfig.maxRetries || 3,
      baseDelay: retryConfig.baseDelay || 1000,
      maxDelay: retryConfig.maxDelay || 30000,
      backoffMultiplier: retryConfig.backoffMultiplier || 2,
      retryableErrors: retryConfig.retryableErrors || [
        'NETWORK_ERROR',
        'TIMEOUT_ERROR',
        'RATE_LIMIT_ERROR',
        'TEMPORARY_SALESFORCE_ERROR',
        'FILE_LOCK_ERROR'
      ]
    };

    this.errorStats = {
      totalErrors: 0,
      errorsByType: new Map(),
      errorsByCategory: new Map(),
      retriedErrors: 0,
      recoveredErrors: 0,
      fatalErrors: 0
    };
  }

  /**
   * Handle an error with automatic categorization and retry logic
   */
  public async handleError(error: Error, context: ProcessingContext): Promise<ErrorHandlingResult> {
    const errorInfo = this.categorizeError(error, context);
    const logEntry = this.createLogEntry(errorInfo, context);
    
    this.errorLog.push(logEntry);
    this.updateErrorStats(errorInfo);

    // Determine if error is retryable
    if (this.isRetryableError(errorInfo) && context.attempt < context.maxAttempts) {
      const retryResult = await this.attemptRetry(errorInfo, context);
      if (retryResult.shouldRetry) {
        return {
          action: 'retry',
          delay: retryResult.delay,
          errorInfo,
          logEntry,
          message: `Retrying after ${retryResult.delay}ms (attempt ${context.attempt + 1}/${context.maxAttempts})`
        };
      }
    }

    // Handle non-retryable or exhausted retry errors
    const recoveryResult = this.attemptRecovery(errorInfo, context);
    if (recoveryResult.canRecover) {
      this.errorStats.recoveredErrors++;
      return {
        action: 'recover',
        errorInfo,
        logEntry,
        recoveryAction: recoveryResult.action,
        message: recoveryResult.message
      };
    }

    // Mark as fatal error
    this.errorStats.fatalErrors++;
    return {
      action: 'fail',
      errorInfo,
      logEntry,
      message: `Fatal error: ${errorInfo.message}`,
      isFatal: true
    };
  }

  /**
   * Handle Salesforce-specific errors
   */
  public async handleSalesforceError(error: any, context: ProcessingContext): Promise<ErrorHandlingResult> {
    const salesforceError = this.parseSalesforceError(error);
    const errorInfo: ErrorInfo = {
      type: salesforceError.type,
      category: 'SALESFORCE_API_ERROR',
      message: salesforceError.message,
      code: salesforceError.code,
      severity: salesforceError.severity,
      originalError: error,
      timestamp: new Date().toISOString(),
      context: {
        file: context.sourceFile,
        operation: 'salesforce_api_call',
        attempt: context.attempt
      },
      salesforceDetails: salesforceError.details
    };

    return this.handleError(new Error(salesforceError.message), context);
  }

  /**
   * Handle content processing errors
   */
  public handleContentError(error: Error, context: ProcessingContext): ErrorHandlingResult {
    const errorInfo: ErrorInfo = {
      type: 'CONTENT_PROCESSING_ERROR',
      category: 'CONTENT_PROCESSING_ERROR',
      message: error.message,
      severity: 'medium',
      originalError: error,
      timestamp: new Date().toISOString(),
      context: {
        file: context.sourceFile,
        operation: 'content_processing',
        attempt: context.attempt
      }
    };

    const logEntry = this.createLogEntry(errorInfo, context);
    this.errorLog.push(logEntry);
    this.updateErrorStats(errorInfo);

    // Content errors are usually not retryable but recoverable
    const recoveryResult = this.attemptContentRecovery(errorInfo, context);
    
    return {
      action: recoveryResult.canRecover ? 'recover' : 'skip',
      errorInfo,
      logEntry,
      recoveryAction: recoveryResult.action,
      message: recoveryResult.message || `Skipping file due to content processing error: ${error.message}`
    };
  }

  /**
   * Handle file system errors
   */
  public handleFileSystemError(error: Error, context: ProcessingContext): ErrorHandlingResult {
    const errorInfo: ErrorInfo = {
      type: this.classifyFileSystemError(error),
      category: 'FILE_SYSTEM_ERROR',
      message: error.message,
      severity: this.getFileSystemErrorSeverity(error),
      originalError: error,
      timestamp: new Date().toISOString(),
      context: {
        file: context.sourceFile,
        operation: 'file_system_operation',
        attempt: context.attempt
      }
    };

    const logEntry = this.createLogEntry(errorInfo, context);
    this.errorLog.push(logEntry);
    this.updateErrorStats(errorInfo);

    // Some file system errors are retryable (locks, temporary issues)
    if (this.isRetryableFileSystemError(errorInfo.type) && context.attempt < context.maxAttempts) {
      return {
        action: 'retry',
        delay: this.calculateRetryDelay(context.attempt),
        errorInfo,
        logEntry,
        message: `File system error, retrying: ${error.message}`
      };
    }

    return {
      action: 'skip',
      errorInfo,
      logEntry,
      message: `Skipping file due to file system error: ${error.message}`
    };
  }

  /**
   * Handle generic errors
   */
  public handleGenericError(error: Error, context: ProcessingContext): ErrorHandlingResult {
    const errorInfo: ErrorInfo = {
      type: 'UNKNOWN_ERROR',
      category: 'GENERIC_ERROR',
      message: error.message,
      severity: 'medium',
      originalError: error,
      timestamp: new Date().toISOString(),
      context: {
        file: context.sourceFile,
        operation: 'unknown',
        attempt: context.attempt
      }
    };

    const logEntry = this.createLogEntry(errorInfo, context);
    this.errorLog.push(logEntry);
    this.updateErrorStats(errorInfo);

    return {
      action: 'skip',
      errorInfo,
      logEntry,
      message: `Unknown error, skipping file: ${error.message}`
    };
  }

  /**
   * Get comprehensive error report
   */
  public getErrorReport(): ErrorReport {
    const errorsByType = Object.fromEntries(this.errorStats.errorsByType);
    const errorsByCategory = Object.fromEntries(this.errorStats.errorsByCategory);
    
    return {
      summary: {
        totalErrors: this.errorStats.totalErrors,
        retriedErrors: this.errorStats.retriedErrors,
        recoveredErrors: this.errorStats.recoveredErrors,
        fatalErrors: this.errorStats.fatalErrors,
        errorRate: this.calculateErrorRate()
      },
      distribution: {
        byType: errorsByType,
        byCategory: errorsByCategory,
        bySeverity: this.getErrorsBySeverity()
      },
      timeline: this.getErrorTimeline(),
      topErrors: this.getTopErrors(10),
      recommendations: this.generateRecommendations(),
      recentErrors: this.errorLog.slice(-20) // Last 20 errors
    };
  }

  /**
   * Get error statistics
   */
  public getErrorStatistics(): ErrorStatistics {
    return { ...this.errorStats };
  }

  /**
   * Clear error log and statistics
   */
  public clearErrors(): void {
    this.errorLog = [];
    this.errorStats = {
      totalErrors: 0,
      errorsByType: new Map(),
      errorsByCategory: new Map(),
      retriedErrors: 0,
      recoveredErrors: 0,
      fatalErrors: 0
    };
  }

  /**
   * Export error log to file
   */
  public exportErrorLog(): string {
    return JSON.stringify({
      timestamp: new Date().toISOString(),
      statistics: this.getErrorStatistics(),
      errors: this.errorLog
    }, null, 2);
  }

  // Private helper methods

  private categorizeError(error: Error, context: ProcessingContext): ErrorInfo {
    // Analyze error message and stack trace to categorize
    const message = error.message.toLowerCase();
    const stack = error.stack?.toLowerCase() || '';

    let type: string;
    let category: string;
    let severity: 'low' | 'medium' | 'high' | 'critical';

    // Network and connectivity errors
    if (message.includes('network') || message.includes('connection') || message.includes('timeout')) {
      type = 'NETWORK_ERROR';
      category = 'NETWORK_ERROR';
      severity = 'medium';
    }
    // Salesforce API errors
    else if (message.includes('salesforce') || message.includes('invalid_session') || message.includes('api')) {
      type = 'SALESFORCE_API_ERROR';
      category = 'SALESFORCE_API_ERROR';
      severity = 'high';
    }
    // File system errors
    else if (message.includes('enoent') || message.includes('eacces') || message.includes('file') || message.includes('directory')) {
      type = 'FILE_SYSTEM_ERROR';
      category = 'FILE_SYSTEM_ERROR';
      severity = 'medium';
    }
    // Content processing errors
    else if (message.includes('markdown') || message.includes('html') || message.includes('parsing')) {
      type = 'CONTENT_PROCESSING_ERROR';
      category = 'CONTENT_PROCESSING_ERROR';
      severity = 'low';
    }
    // Rate limiting errors
    else if (message.includes('rate limit') || message.includes('too many requests')) {
      type = 'RATE_LIMIT_ERROR';
      category = 'RATE_LIMIT_ERROR';
      severity = 'medium';
    }
    // Authentication errors
    else if (message.includes('auth') || message.includes('login') || message.includes('credential')) {
      type = 'AUTHENTICATION_ERROR';
      category = 'AUTHENTICATION_ERROR';
      severity = 'critical';
    }
    // Default categorization
    else {
      type = 'UNKNOWN_ERROR';
      category = 'GENERIC_ERROR';
      severity = 'medium';
    }

    return {
      type,
      category,
      message: error.message,
      severity,
      originalError: error,
      timestamp: new Date().toISOString(),
      context: {
        file: context.sourceFile,
        operation: 'migration',
        attempt: context.attempt
      }
    };
  }

  private parseSalesforceError(error: any): SalesforceErrorInfo {
    // Parse Salesforce-specific error structure
    if (error.name === 'INVALID_SESSION_ID') {
      return {
        type: 'INVALID_SESSION_ERROR',
        code: 'INVALID_SESSION_ID',
        message: 'Salesforce session has expired',
        severity: 'high',
        details: { requiresReauth: true }
      };
    }

    if (error.name === 'REQUEST_LIMIT_EXCEEDED') {
      return {
        type: 'RATE_LIMIT_ERROR',
        code: 'REQUEST_LIMIT_EXCEEDED',
        message: 'Salesforce API request limit exceeded',
        severity: 'medium',
        details: { retryAfter: error.retryAfter || 60000 }
      };
    }

    if (error.errorCode) {
      return {
        type: 'SALESFORCE_API_ERROR',
        code: error.errorCode,
        message: error.message || 'Salesforce API error',
        severity: 'high',
        details: error
      };
    }

    return {
      type: 'UNKNOWN_SALESFORCE_ERROR',
      code: 'UNKNOWN',
      message: error.message || 'Unknown Salesforce error',
      severity: 'medium',
      details: error
    };
  }

  private isRetryableError(errorInfo: ErrorInfo): boolean {
    return this.retryConfig.retryableErrors.includes(errorInfo.type);
  }

  private async attemptRetry(errorInfo: ErrorInfo, context: ProcessingContext): Promise<RetryResult> {
    const delay = this.calculateRetryDelay(context.attempt);
    
    // Special handling for rate limit errors
    if (errorInfo.type === 'RATE_LIMIT_ERROR' && errorInfo.salesforceDetails?.retryAfter) {
      return {
        shouldRetry: true,
        delay: errorInfo.salesforceDetails.retryAfter
      };
    }

    this.errorStats.retriedErrors++;
    
    return {
      shouldRetry: true,
      delay
    };
  }

  private calculateRetryDelay(attempt: number): number {
    const delay = this.retryConfig.baseDelay * Math.pow(this.retryConfig.backoffMultiplier, attempt);
    return Math.min(delay, this.retryConfig.maxDelay);
  }

  private attemptRecovery(errorInfo: ErrorInfo, context: ProcessingContext): RecoveryResult {
    switch (errorInfo.type) {
      case 'CONTENT_PROCESSING_ERROR':
        return {
          canRecover: true,
          action: 'skip_with_warning',
          message: 'Content processing failed, skipping file with warning'
        };

      case 'FILE_SYSTEM_ERROR':
        return {
          canRecover: false,
          action: 'skip',
          message: 'File system error, cannot recover'
        };

      case 'AUTHENTICATION_ERROR':
        return {
          canRecover: true,
          action: 'reauthenticate',
          message: 'Authentication failed, attempting to reauthenticate'
        };

      default:
        return {
          canRecover: false,
          action: 'skip',
          message: 'Cannot recover from this error type'
        };
    }
  }

  private attemptContentRecovery(errorInfo: ErrorInfo, context: ProcessingContext): RecoveryResult {
    // Attempt to recover from content processing errors
    if (errorInfo.message.includes('markdown')) {
      return {
        canRecover: true,
        action: 'use_fallback_processor',
        message: 'Markdown processing failed, using fallback processor'
      };
    }

    if (errorInfo.message.includes('html')) {
      return {
        canRecover: true,
        action: 'sanitize_content',
        message: 'HTML processing failed, using content sanitization'
      };
    }

    return {
      canRecover: false,
      action: 'skip',
      message: 'Cannot recover from content processing error'
    };
  }

  private classifyFileSystemError(error: Error): string {
    const message = error.message.toLowerCase();
    
    if (message.includes('enoent')) return 'FILE_NOT_FOUND_ERROR';
    if (message.includes('eacces')) return 'PERMISSION_ERROR';
    if (message.includes('ebusy')) return 'FILE_LOCK_ERROR';
    if (message.includes('enospc')) return 'DISK_SPACE_ERROR';
    if (message.includes('emfile')) return 'TOO_MANY_FILES_ERROR';
    
    return 'UNKNOWN_FILE_SYSTEM_ERROR';
  }

  private getFileSystemErrorSeverity(error: Error): 'low' | 'medium' | 'high' | 'critical' {
    const message = error.message.toLowerCase();
    
    if (message.includes('enospc')) return 'critical'; // Disk space
    if (message.includes('eacces')) return 'high'; // Permissions
    if (message.includes('enoent')) return 'medium'; // File not found
    
    return 'medium';
  }

  private isRetryableFileSystemError(errorType: string): boolean {
    const retryableTypes = ['FILE_LOCK_ERROR', 'TEMPORARY_FILE_ERROR'];
    return retryableTypes.includes(errorType);
  }

  private createLogEntry(errorInfo: ErrorInfo, context: ProcessingContext): ErrorLogEntry {
    return {
      id: this.generateErrorId(),
      timestamp: errorInfo.timestamp,
      type: errorInfo.type,
      category: errorInfo.category,
      severity: errorInfo.severity,
      message: errorInfo.message,
      context: {
        file: context.sourceFile,
        targetArticle: context.targetArticle,
        attempt: context.attempt,
        maxAttempts: context.maxAttempts
      },
      stack: errorInfo.originalError.stack,
      metadata: {
        userAgent: process.version,
        platform: process.platform,
        nodeVersion: process.version
      }
    };
  }

  private updateErrorStats(errorInfo: ErrorInfo): void {
    this.errorStats.totalErrors++;
    
    // Update by type
    const typeCount = this.errorStats.errorsByType.get(errorInfo.type) || 0;
    this.errorStats.errorsByType.set(errorInfo.type, typeCount + 1);
    
    // Update by category
    const categoryCount = this.errorStats.errorsByCategory.get(errorInfo.category) || 0;
    this.errorStats.errorsByCategory.set(errorInfo.category, categoryCount + 1);
  }

  private generateErrorId(): string {
    return `err_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }

  private calculateErrorRate(): number {
    // This would need total operations count to calculate properly
    // For now, return a placeholder
    return 0;
  }

  private getErrorsBySeverity(): Record<string, number> {
    const severityCounts = { low: 0, medium: 0, high: 0, critical: 0 };
    
    for (const entry of this.errorLog) {
      severityCounts[entry.severity]++;
    }
    
    return severityCounts;
  }

  private getErrorTimeline(): TimelineEntry[] {
    // Group errors by hour for timeline
    const timeline = new Map<string, number>();
    
    for (const entry of this.errorLog) {
      const hour = new Date(entry.timestamp).toISOString().substr(0, 13);
      timeline.set(hour, (timeline.get(hour) || 0) + 1);
    }
    
    return Array.from(timeline.entries()).map(([time, count]) => ({ time, count }));
  }

  private getTopErrors(limit: number): TopError[] {
    const errorCounts = new Map<string, { count: number; lastSeen: string; severity: string }>();
    
    for (const entry of this.errorLog) {
      const key = `${entry.type}: ${entry.message}`;
      const existing = errorCounts.get(key);
      
      if (existing) {
        existing.count++;
        existing.lastSeen = entry.timestamp;
      } else {
        errorCounts.set(key, {
          count: 1,
          lastSeen: entry.timestamp,
          severity: entry.severity
        });
      }
    }
    
    return Array.from(errorCounts.entries())
      .map(([error, data]) => ({ error, ...data }))
      .sort((a, b) => b.count - a.count)
      .slice(0, limit);
  }

  private generateRecommendations(): string[] {
    const recommendations: string[] = [];
    const stats = this.errorStats;
    
    // Check for high error rates
    if (stats.fatalErrors > stats.totalErrors * 0.1) {
      recommendations.push('High fatal error rate detected. Review system configuration and connectivity.');
    }
    
    // Check for authentication issues
    if (stats.errorsByType.get('AUTHENTICATION_ERROR') || 0 > 0) {
      recommendations.push('Authentication errors detected. Verify Salesforce credentials and permissions.');
    }
    
    // Check for rate limiting
    if (stats.errorsByType.get('RATE_LIMIT_ERROR') || 0 > 0) {
      recommendations.push('Rate limiting detected. Consider reducing batch size or adding delays.');
    }
    
    // Check for file system issues
    if (stats.errorsByCategory.get('FILE_SYSTEM_ERROR') || 0 > 0) {
      recommendations.push('File system errors detected. Check file permissions and disk space.');
    }
    
    return recommendations;
  }
}

// Type definitions

export interface RetryConfig {
  maxRetries?: number;
  baseDelay?: number;
  maxDelay?: number;
  backoffMultiplier?: number;
  retryableErrors?: string[];
}

export interface ErrorInfo {
  type: string;
  category: string;
  message: string;
  code?: string;
  severity: 'low' | 'medium' | 'high' | 'critical';
  originalError: Error;
  timestamp: string;
  context: {
    file: string;
    operation: string;
    attempt: number;
  };
  salesforceDetails?: any;
}

export interface SalesforceErrorInfo {
  type: string;
  code: string;
  message: string;
  severity: 'low' | 'medium' | 'high' | 'critical';
  details: any;
}

export interface ErrorHandlingResult {
  action: 'retry' | 'recover' | 'skip' | 'fail';
  delay?: number;
  errorInfo: ErrorInfo;
  logEntry: ErrorLogEntry;
  recoveryAction?: string;
  message: string;
  isFatal?: boolean;
}

export interface RetryResult {
  shouldRetry: boolean;
  delay: number;
}

export interface RecoveryResult {
  canRecover: boolean;
  action: string;
  message: string;
}

export interface ErrorLogEntry {
  id: string;
  timestamp: string;
  type: string;
  category: string;
  severity: 'low' | 'medium' | 'high' | 'critical';
  message: string;
  context: {
    file: string;
    targetArticle?: string;
    attempt: number;
    maxAttempts: number;
  };
  stack?: string;
  metadata: {
    userAgent: string;
    platform: string;
    nodeVersion: string;
  };
}

export interface ErrorStatistics {
  totalErrors: number;
  errorsByType: Map<string, number>;
  errorsByCategory: Map<string, number>;
  retriedErrors: number;
  recoveredErrors: number;
  fatalErrors: number;
}

export interface ErrorReport {
  summary: {
    totalErrors: number;
    retriedErrors: number;
    recoveredErrors: number;
    fatalErrors: number;
    errorRate: number;
  };
  distribution: {
    byType: Record<string, number>;
    byCategory: Record<string, number>;
    bySeverity: Record<string, number>;
  };
  timeline: TimelineEntry[];
  topErrors: TopError[];
  recommendations: string[];
  recentErrors: ErrorLogEntry[];
}

export interface TimelineEntry {
  time: string;
  count: number;
}

export interface TopError {
  error: string;
  count: number;
  lastSeen: string;
  severity: string;
}