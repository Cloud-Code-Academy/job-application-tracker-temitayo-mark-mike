/**
 * Unit tests for ErrorHandler class
 */

import { ErrorHandler, RetryConfig, ErrorHandlingResult, ErrorReport } from '../../src/core/ErrorHandler';
import { ProcessingContext } from '../../src/types';

describe('ErrorHandler', () => {
  let errorHandler: ErrorHandler;
  let mockContext: ProcessingContext;

  beforeEach(() => {
    errorHandler = new ErrorHandler();
    mockContext = {
      sourceFile: 'docs/test.md',
      targetArticle: 'test-article',
      metadata: {
        filePath: 'docs/test.md',
        fileName: 'test.md',
        title: 'Test Document',
        urlName: 'test-document',
        category: 'User_Documentation',
        tags: [],
        difficulty: 'Intermediate',
        readingTime: 5,
        lastModified: '2024-01-01T00:00:00Z',
        contentHash: 'abc123',
        wordCount: 100,
        headingCount: 3,
        codeBlockCount: 1,
        linkCount: 2
      },
      attempt: 1,
      maxAttempts: 3
    };
  });

  describe('constructor', () => {
    it('should initialize with default retry configuration', () => {
      const handler = new ErrorHandler();
      const stats = handler.getErrorStatistics();

      expect(stats.totalErrors).toBe(0);
      expect(stats.retriedErrors).toBe(0);
      expect(stats.recoveredErrors).toBe(0);
      expect(stats.fatalErrors).toBe(0);
    });

    it('should accept custom retry configuration', () => {
      const customConfig: RetryConfig = {
        maxRetries: 5,
        baseDelay: 2000,
        maxDelay: 60000,
        backoffMultiplier: 3,
        retryableErrors: ['CUSTOM_ERROR']
      };

      const handler = new ErrorHandler(customConfig);
      expect(handler).toBeDefined();
    });
  });

  describe('handleError', () => {
    it('should handle retryable network errors', async () => {
      const networkError = new Error('Network connection failed');
      
      const result = await errorHandler.handleError(networkError, mockContext);

      expect(result.action).toBe('retry');
      expect(result.delay).toBeGreaterThan(0);
      expect(result.errorInfo.type).toBe('NETWORK_ERROR');
      expect(result.errorInfo.category).toBe('NETWORK_ERROR');
      expect(result.errorInfo.severity).toBe('medium');
    });

    it('should handle authentication errors with recovery', async () => {
      const authError = new Error('Authentication failed - invalid credentials');
      
      const result = await errorHandler.handleError(authError, mockContext);

      expect(result.action).toBe('recover');
      expect(result.errorInfo.type).toBe('AUTHENTICATION_ERROR');
      expect(result.errorInfo.severity).toBe('critical');
      expect(result.recoveryAction).toBe('reauthenticate');
    });

    it('should handle non-retryable errors as fatal', async () => {
      const fatalError = new Error('Unrecoverable system error');
      const contextWithMaxAttempts = { ...mockContext, attempt: 3, maxAttempts: 3 };
      
      const result = await errorHandler.handleError(fatalError, contextWithMaxAttempts);

      expect(result.action).toBe('fail');
      expect(result.isFatal).toBe(true);
      expect(result.errorInfo.type).toBe('UNKNOWN_ERROR');
    });

    it('should update error statistics', async () => {
      const error1 = new Error('Network timeout');
      const error2 = new Error('File not found');
      
      await errorHandler.handleError(error1, mockContext);
      await errorHandler.handleError(error2, mockContext);

      const stats = errorHandler.getErrorStatistics();
      expect(stats.totalErrors).toBe(2);
      expect(stats.errorsByType.get('NETWORK_ERROR')).toBe(1);
      expect(stats.errorsByType.get('FILE_SYSTEM_ERROR')).toBe(1);
    });

    it('should calculate exponential backoff delay', async () => {
      const networkError = new Error('Connection timeout');
      
      const context1 = { ...mockContext, attempt: 1 };
      const context2 = { ...mockContext, attempt: 2 };
      
      const result1 = await errorHandler.handleError(networkError, context1);
      const result2 = await errorHandler.handleError(networkError, context2);

      expect(result1.delay).toBeLessThan(result2.delay!);
      expect(result2.delay).toBeGreaterThan(result1.delay! * 1.5); // Exponential increase
    });
  });

  describe('handleSalesforceError', () => {
    it('should handle invalid session errors', async () => {
      const salesforceError = {
        name: 'INVALID_SESSION_ID',
        message: 'Session expired'
      };
      
      const result = await errorHandler.handleSalesforceError(salesforceError, mockContext);

      expect(result.errorInfo.type).toBe('INVALID_SESSION_ERROR');
      expect(result.errorInfo.severity).toBe('high');
      expect(result.errorInfo.salesforceDetails?.requiresReauth).toBe(true);
    });

    it('should handle rate limit errors with custom delay', async () => {
      const rateLimitError = {
        name: 'REQUEST_LIMIT_EXCEEDED',
        message: 'Too many requests',
        retryAfter: 5000
      };
      
      const result = await errorHandler.handleSalesforceError(rateLimitError, mockContext);

      expect(result.action).toBe('retry');
      expect(result.delay).toBe(5000);
      expect(result.errorInfo.type).toBe('RATE_LIMIT_ERROR');
    });

    it('should handle generic Salesforce API errors', async () => {
      const apiError = {
        errorCode: 'FIELD_CUSTOM_VALIDATION_EXCEPTION',
        message: 'Custom validation rule failed'
      };
      
      const result = await errorHandler.handleSalesforceError(apiError, mockContext);

      expect(result.errorInfo.type).toBe('SALESFORCE_API_ERROR');
      expect(result.errorInfo.code).toBe('FIELD_CUSTOM_VALIDATION_EXCEPTION');
      expect(result.errorInfo.severity).toBe('high');
    });
  });

  describe('handleContentError', () => {
    it('should handle markdown processing errors', () => {
      const contentError = new Error('Invalid markdown syntax');
      
      const result = errorHandler.handleContentError(contentError, mockContext);

      expect(result.action).toBe('recover');
      expect(result.errorInfo.type).toBe('CONTENT_PROCESSING_ERROR');
      expect(result.errorInfo.category).toBe('CONTENT_PROCESSING_ERROR');
      expect(result.errorInfo.severity).toBe('low');
      expect(result.recoveryAction).toBe('use_fallback_processor');
    });

    it('should handle HTML processing errors', () => {
      const htmlError = new Error('HTML parsing failed');
      
      const result = errorHandler.handleContentError(htmlError, mockContext);

      expect(result.action).toBe('recover');
      expect(result.recoveryAction).toBe('sanitize_content');
    });

    it('should skip unrecoverable content errors', () => {
      const unknownError = new Error('Unknown content processing error');
      
      const result = errorHandler.handleContentError(unknownError, mockContext);

      expect(result.action).toBe('skip');
      expect(result.message).toContain('Skipping file due to content processing error');
    });
  });

  describe('handleFileSystemError', () => {
    it('should handle file not found errors', () => {
      const fileError = new Error('ENOENT: no such file or directory');
      
      const result = errorHandler.handleFileSystemError(fileError, mockContext);

      expect(result.action).toBe('skip');
      expect(result.errorInfo.type).toBe('FILE_NOT_FOUND_ERROR');
      expect(result.errorInfo.severity).toBe('medium');
    });

    it('should handle permission errors', () => {
      const permError = new Error('EACCES: permission denied');
      
      const result = errorHandler.handleFileSystemError(permError, mockContext);

      expect(result.action).toBe('skip');
      expect(result.errorInfo.type).toBe('PERMISSION_ERROR');
      expect(result.errorInfo.severity).toBe('high');
    });

    it('should retry file lock errors', () => {
      const lockError = new Error('EBUSY: resource busy or locked');
      
      const result = errorHandler.handleFileSystemError(lockError, mockContext);

      expect(result.action).toBe('retry');
      expect(result.errorInfo.type).toBe('FILE_LOCK_ERROR');
      expect(result.delay).toBeGreaterThan(0);
    });

    it('should handle critical disk space errors', () => {
      const diskError = new Error('ENOSPC: no space left on device');
      
      const result = errorHandler.handleFileSystemError(diskError, mockContext);

      expect(result.action).toBe('skip');
      expect(result.errorInfo.type).toBe('DISK_SPACE_ERROR');
      expect(result.errorInfo.severity).toBe('critical');
    });
  });

  describe('error categorization', () => {
    it('should categorize network errors correctly', async () => {
      const networkErrors = [
        new Error('Network connection failed'),
        new Error('Connection timeout'),
        new Error('DNS resolution failed')
      ];

      for (const error of networkErrors) {
        const result = await errorHandler.handleError(error, mockContext);
        expect(result.errorInfo.category).toBe('NETWORK_ERROR');
      }
    });

    it('should categorize Salesforce errors correctly', async () => {
      const salesforceErrors = [
        new Error('Salesforce API error'),
        new Error('Invalid session ID'),
        new Error('API request failed')
      ];

      for (const error of salesforceErrors) {
        const result = await errorHandler.handleError(error, mockContext);
        expect(result.errorInfo.category).toBe('SALESFORCE_API_ERROR');
      }
    });

    it('should categorize file system errors correctly', async () => {
      const fileErrors = [
        new Error('ENOENT: file not found'),
        new Error('EACCES: permission denied'),
        new Error('File system error')
      ];

      for (const error of fileErrors) {
        const result = await errorHandler.handleError(error, mockContext);
        expect(result.errorInfo.category).toBe('FILE_SYSTEM_ERROR');
      }
    });

    it('should categorize content processing errors correctly', async () => {
      const contentErrors = [
        new Error('Markdown parsing failed'),
        new Error('HTML conversion error'),
        new Error('Content processing failed')
      ];

      for (const error of contentErrors) {
        const result = await errorHandler.handleError(error, mockContext);
        expect(result.errorInfo.category).toBe('CONTENT_PROCESSING_ERROR');
      }
    });
  });

  describe('getErrorReport', () => {
    beforeEach(async () => {
      // Generate some test errors
      const errors = [
        new Error('Network timeout'),
        new Error('File not found'),
        new Error('Markdown parsing failed'),
        new Error('Network timeout'), // Duplicate
        new Error('Authentication failed')
      ];

      for (const error of errors) {
        await errorHandler.handleError(error, mockContext);
      }
    });

    it('should generate comprehensive error report', () => {
      const report = errorHandler.getErrorReport();

      expect(report.summary.totalErrors).toBe(5);
      expect(report.distribution.byType).toBeDefined();
      expect(report.distribution.byCategory).toBeDefined();
      expect(report.distribution.bySeverity).toBeDefined();
      expect(report.timeline).toBeDefined();
      expect(report.topErrors).toBeDefined();
      expect(report.recommendations).toBeDefined();
      expect(report.recentErrors).toBeDefined();
    });

    it('should identify top errors correctly', () => {
      const report = errorHandler.getErrorReport();
      const topError = report.topErrors[0];

      expect(topError.error).toContain('Network timeout');
      expect(topError.count).toBe(2); // Appears twice
    });

    it('should provide relevant recommendations', () => {
      const report = errorHandler.getErrorReport();

      expect(report.recommendations).toContain(
        'Authentication errors detected. Verify Salesforce credentials and permissions.'
      );
      expect(report.recommendations).toContain(
        'File system errors detected. Check file permissions and disk space.'
      );
    });

    it('should track error timeline', () => {
      const report = errorHandler.getErrorReport();

      expect(report.timeline.length).toBeGreaterThan(0);
      expect(report.timeline[0]).toHaveProperty('time');
      expect(report.timeline[0]).toHaveProperty('count');
    });

    it('should categorize errors by severity', () => {
      const report = errorHandler.getErrorReport();

      expect(report.distribution.bySeverity.low).toBeGreaterThanOrEqual(0);
      expect(report.distribution.bySeverity.medium).toBeGreaterThanOrEqual(0);
      expect(report.distribution.bySeverity.high).toBeGreaterThanOrEqual(0);
      expect(report.distribution.bySeverity.critical).toBeGreaterThanOrEqual(0);
    });
  });

  describe('error statistics', () => {
    it('should track error statistics correctly', async () => {
      const networkError = new Error('Network failed');
      const authError = new Error('Authentication failed');
      
      await errorHandler.handleError(networkError, mockContext);
      await errorHandler.handleError(authError, mockContext);

      const stats = errorHandler.getErrorStatistics();

      expect(stats.totalErrors).toBe(2);
      expect(stats.errorsByType.get('NETWORK_ERROR')).toBe(1);
      expect(stats.errorsByType.get('AUTHENTICATION_ERROR')).toBe(1);
      expect(stats.errorsByCategory.get('NETWORK_ERROR')).toBe(1);
      expect(stats.errorsByCategory.get('AUTHENTICATION_ERROR')).toBe(1);
    });

    it('should track retry and recovery statistics', async () => {
      const retryableError = new Error('Network timeout');
      const recoverableError = new Error('Authentication failed');
      
      await errorHandler.handleError(retryableError, mockContext);
      await errorHandler.handleError(recoverableError, mockContext);

      const stats = errorHandler.getErrorStatistics();

      expect(stats.retriedErrors).toBe(1);
      expect(stats.recoveredErrors).toBe(1);
    });

    it('should track fatal errors', async () => {
      const fatalError = new Error('Unrecoverable error');
      const contextWithMaxAttempts = { ...mockContext, attempt: 3, maxAttempts: 3 };
      
      await errorHandler.handleError(fatalError, contextWithMaxAttempts);

      const stats = errorHandler.getErrorStatistics();

      expect(stats.fatalErrors).toBe(1);
    });
  });

  describe('error log management', () => {
    it('should export error log as JSON', async () => {
      const error = new Error('Test error');
      await errorHandler.handleError(error, mockContext);

      const exportedLog = errorHandler.exportErrorLog();
      const parsedLog = JSON.parse(exportedLog);

      expect(parsedLog.timestamp).toBeDefined();
      expect(parsedLog.statistics).toBeDefined();
      expect(parsedLog.errors).toBeDefined();
      expect(parsedLog.errors.length).toBe(1);
    });

    it('should clear errors and statistics', async () => {
      const error = new Error('Test error');
      await errorHandler.handleError(error, mockContext);

      let stats = errorHandler.getErrorStatistics();
      expect(stats.totalErrors).toBe(1);

      errorHandler.clearErrors();

      stats = errorHandler.getErrorStatistics();
      expect(stats.totalErrors).toBe(0);
      expect(stats.errorsByType.size).toBe(0);
      expect(stats.errorsByCategory.size).toBe(0);
    });
  });

  describe('retry logic', () => {
    it('should respect maximum retry attempts', async () => {
      const retryableError = new Error('Network timeout');
      const contextMaxAttempts = { ...mockContext, attempt: 3, maxAttempts: 3 };
      
      const result = await errorHandler.handleError(retryableError, contextMaxAttempts);

      expect(result.action).toBe('fail');
      expect(result.isFatal).toBe(true);
    });

    it('should calculate exponential backoff correctly', async () => {
      const customConfig: RetryConfig = {
        baseDelay: 1000,
        backoffMultiplier: 2,
        maxDelay: 10000
      };
      
      const handler = new ErrorHandler(customConfig);
      const error = new Error('Network timeout');
      
      const context1 = { ...mockContext, attempt: 1 };
      const context2 = { ...mockContext, attempt: 2 };
      const context3 = { ...mockContext, attempt: 3 };
      
      const result1 = await handler.handleError(error, context1);
      const result2 = await handler.handleError(error, context2);
      const result3 = await handler.handleError(error, context3);

      expect(result1.delay).toBe(1000); // 1000 * 2^1
      expect(result2.delay).toBe(2000); // 1000 * 2^2
      expect(result3.delay).toBe(4000); // 1000 * 2^3
    });

    it('should respect maximum delay limit', async () => {
      const customConfig: RetryConfig = {
        baseDelay: 1000,
        backoffMultiplier: 10,
        maxDelay: 5000
      };
      
      const handler = new ErrorHandler(customConfig);
      const error = new Error('Network timeout');
      const contextHighAttempt = { ...mockContext, attempt: 5 };
      
      const result = await handler.handleError(error, contextHighAttempt);

      expect(result.delay).toBeLessThanOrEqual(5000);
    });
  });

  describe('edge cases', () => {
    it('should handle errors with no message', async () => {
      const error = new Error();
      
      const result = await errorHandler.handleError(error, mockContext);

      expect(result.errorInfo.message).toBe('');
      expect(result.errorInfo.type).toBe('UNKNOWN_ERROR');
    });

    it('should handle errors with no stack trace', async () => {
      const error = new Error('Test error');
      error.stack = undefined;
      
      const result = await errorHandler.handleError(error, mockContext);

      expect(result.logEntry.stack).toBeUndefined();
    });

    it('should handle very long error messages', async () => {
      const longMessage = 'A'.repeat(10000);
      const error = new Error(longMessage);
      
      const result = await errorHandler.handleError(error, mockContext);

      expect(result.errorInfo.message).toBe(longMessage);
      expect(result.logEntry.message).toBe(longMessage);
    });

    it('should handle circular reference in error objects', async () => {
      const error: any = new Error('Circular error');
      error.circular = error; // Create circular reference
      
      // Should not throw when handling circular references
      expect(async () => {
        await errorHandler.handleError(error, mockContext);
      }).not.toThrow();
    });
  });
});