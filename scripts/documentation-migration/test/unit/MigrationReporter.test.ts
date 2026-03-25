/**
 * Unit tests for MigrationReporter class
 */

import * as fs from 'fs';
import * as path from 'path';
import { MigrationReporter } from '../../src/reporting/MigrationReporter';
import { MigrationReport, MigrationResult } from '../../src/types';

// Mock fs module
jest.mock('fs');
const mockFs = fs as jest.Mocked<typeof fs>;

describe('MigrationReporter', () => {
  let reporter: MigrationReporter;
  let mockReport: MigrationReport;
  const outputDir = './test-reports';

  beforeEach(() => {
    // Create mock migration report
    mockReport = {
      summary: {
        totalFiles: 10,
        successful: 8,
        failed: 1,
        skipped: 1,
        duration: 30000
      },
      results: [
        {
          success: true,
          filePath: 'docs/guide.md',
          urlName: 'guide',
          action: 'created',
          warnings: ['Minor formatting issue']
        },
        {
          success: true,
          filePath: 'docs/api.md',
          urlName: 'api-reference',
          action: 'created',
          warnings: []
        },
        {
          success: false,
          filePath: 'docs/broken.md',
          urlName: 'broken',
          action: 'failed',
          error: 'File not found',
          warnings: []
        }
      ] as MigrationResult[],
      urlMappings: {
        'docs/guide.md': '/knowledge/article/guide',
        'docs/api.md': '/knowledge/article/api-reference'
      },
      errors: [
        {
          file: 'docs/broken.md',
          error: 'File not found',
          stack: undefined
        }
      ],
      linkMappingReport: {},
      relationshipReport: {
        summary: {
          totalDocuments: 10,
          totalRelationships: 15,
          brokenRelationships: 2,
          averageRelationshipsPerDocument: 1.5
        },
        brokenRelationships: [
          {
            sourceFile: 'docs/guide.md',
            targetFile: 'docs/missing.md',
            referenceType: 'internal_link',
            context: 'See [missing](missing.md)',
            lineNumber: 10,
            reason: 'Target file not found'
          }
        ],
        isolatedDocuments: ['docs/isolated.md']
      },
      errorReport: {},
      progressReport: {},
      performanceReport: {
        batchProcessing: {
          totalItems: 10,
          successfulItems: 8,
          failedItems: 1,
          duration: 30000,
          averageTimePerItem: 3000,
          cacheHitRate: 0.75
        },
        memoryUsage: {
          heapUsed: 50 * 1024 * 1024,
          heapTotal: 100 * 1024 * 1024,
          external: 10 * 1024 * 1024,
          rss: 120 * 1024 * 1024
        }
      }
    };

    reporter = new MigrationReporter(mockReport, outputDir);

    // Mock fs methods
    mockFs.existsSync.mockReturnValue(true);
    mockFs.mkdirSync.mockReturnValue(undefined);
    mockFs.writeFileSync.mockReturnValue(undefined);
    mockFs.statSync.mockReturnValue({ size: 1024 } as any);

    jest.clearAllMocks();
  });

  describe('Analytics Generation', () => {
    it('should generate comprehensive migration analytics', () => {
      const analytics = reporter.generateAnalytics();

      expect(analytics).toBeDefined();
      expect(analytics.summary).toBeDefined();
      expect(analytics.performance).toBeDefined();
      expect(analytics.quality).toBeDefined();
      expect(analytics.errors).toBeDefined();
      expect(analytics.content).toBeDefined();
      expect(analytics.relationships).toBeDefined();
      expect(analytics.recommendations).toBeDefined();
      expect(analytics.generatedAt).toBeDefined();

      // Verify summary analytics
      expect(analytics.summary.totals.files).toBe(10);
      expect(analytics.summary.totals.successful).toBe(8);
      expect(analytics.summary.totals.failed).toBe(1);
      expect(analytics.summary.rates.success).toBe(80);
    });

    it('should calculate performance analytics correctly', () => {
      const analytics = reporter.generateAnalytics();

      expect(analytics.performance.throughput).toBeGreaterThan(0);
      expect(analytics.performance.memoryUsage.peak).toBeGreaterThan(0);
      expect(analytics.performance.cacheEfficiency).toBe(0.75);
    });

    it('should analyze relationship data', () => {
      const analytics = reporter.generateAnalytics();

      expect(analytics.relationships.totalRelationships).toBe(15);
      expect(analytics.relationships.brokenLinks).toBe(1);
      expect(analytics.relationships.isolatedDocuments).toBe(1);
      expect(analytics.relationships.averageConnections).toBe(1.5);
    });

    it('should generate meaningful recommendations', () => {
      const analytics = reporter.generateAnalytics();

      expect(Array.isArray(analytics.recommendations)).toBe(true);
      expect(analytics.recommendations.length).toBeGreaterThan(0);
    });
  });

  describe('Summary Statistics', () => {
    it('should generate detailed summary statistics', () => {
      const stats = reporter.generateSummaryStatistics();

      expect(stats.overview).toBeDefined();
      expect(stats.breakdown).toBeDefined();
      expect(stats.timeline).toBeDefined();
      expect(stats.trends).toBeDefined();

      // Verify overview calculations
      expect(stats.overview.totalFiles).toBe(10);
      expect(stats.overview.successful).toBe(8);
      expect(stats.overview.successRate).toBe(80);
      expect(stats.overview.averageProcessingTime).toBe(3000);
    });

    it('should group results by action', () => {
      const stats = reporter.generateSummaryStatistics();

      expect(stats.breakdown.byAction).toBeDefined();
      expect(stats.breakdown.byAction.created).toBe(2);
      expect(stats.breakdown.byAction.failed).toBe(1);
    });

    it('should handle empty results gracefully', () => {
      const emptyReport = {
        ...mockReport,
        summary: { totalFiles: 0, successful: 0, failed: 0, skipped: 0, duration: 0 },
        results: []
      };

      const emptyReporter = new MigrationReporter(emptyReport, outputDir);
      const stats = emptyReporter.generateSummaryStatistics();

      expect(stats.overview.totalFiles).toBe(0);
      expect(stats.overview.successRate).toBe(0);
      expect(stats.overview.averageProcessingTime).toBe(0);
    });
  });

  describe('URL Mapping Report', () => {
    it('should generate comprehensive URL mapping report', () => {
      const urlReport = reporter.generateUrlMappingReport();

      expect(urlReport.summary).toBeDefined();
      expect(urlReport.mappings).toBeDefined();
      expect(urlReport.redirectRules).toBeDefined();
      expect(urlReport.brokenLinks).toBeDefined();
      expect(urlReport.validation).toBeDefined();

      // Verify summary
      expect(urlReport.summary.totalMappings).toBe(2);
      expect(urlReport.summary.brokenLinks).toBe(1);

      // Verify redirect rules
      expect(urlReport.redirectRules.nginx).toBeDefined();
      expect(urlReport.redirectRules.apache).toBeDefined();
      expect(urlReport.redirectRules.cloudflare).toBeDefined();
      expect(urlReport.redirectRules.json).toBeDefined();
    });

    it('should generate valid redirect rules', () => {
      const urlReport = reporter.generateUrlMappingReport();

      expect(Array.isArray(urlReport.redirectRules.json)).toBe(true);
      expect(urlReport.redirectRules.json.length).toBe(2);

      const firstRule = urlReport.redirectRules.json[0];
      expect(firstRule.from).toBeDefined();
      expect(firstRule.to).toBeDefined();
      expect(firstRule.status).toBe(301);
      expect(firstRule.type).toBe('permanent');
    });

    it('should validate URL mappings', () => {
      const urlReport = reporter.generateUrlMappingReport();

      expect(urlReport.validation.valid).toBeDefined();
      expect(urlReport.validation.invalid).toBeDefined();
      expect(Array.isArray(urlReport.validation.valid)).toBe(true);
      expect(Array.isArray(urlReport.validation.invalid)).toBe(true);
    });
  });

  describe('Validation Report', () => {
    it('should generate content validation report', () => {
      const validationReport = reporter.generateValidationReport();

      expect(validationReport.summary).toBeDefined();
      expect(validationReport.issues).toBeDefined();
      expect(validationReport.warnings).toBeDefined();
      expect(validationReport.suggestions).toBeDefined();
      expect(validationReport.qualityMetrics).toBeDefined();
      expect(validationReport.recommendations).toBeDefined();

      // Verify summary
      expect(validationReport.summary.totalFiles).toBe(8); // Only successful files
      expect(typeof validationReport.summary.qualityScore).toBe('number');
      expect(validationReport.summary.qualityScore).toBeGreaterThanOrEqual(0);
      expect(validationReport.summary.qualityScore).toBeLessThanOrEqual(100);
    });

    it('should calculate quality score correctly', () => {
      const validationReport = reporter.generateValidationReport();

      // Quality score should be reasonable for our test data
      expect(validationReport.summary.qualityScore).toBeGreaterThan(50);
    });

    it('should categorize issues and warnings', () => {
      const validationReport = reporter.generateValidationReport();

      expect(typeof validationReport.issues).toBe('object');
      expect(typeof validationReport.warnings).toBe('object');
      expect(typeof validationReport.suggestions).toBe('object');
    });
  });

  describe('Report Export', () => {
    it('should export JSON report', () => {
      const filePath = reporter.exportJsonReport('test-report.json');

      expect(mockFs.writeFileSync).toHaveBeenCalled();
      expect(filePath).toContain('test-report.json');

      // Verify the JSON structure
      const writeCall = mockFs.writeFileSync.mock.calls[0];
      const jsonContent = JSON.parse(writeCall[1] as string);

      expect(jsonContent.metadata).toBeDefined();
      expect(jsonContent.migration).toBeDefined();
      expect(jsonContent.analytics).toBeDefined();
      expect(jsonContent.statistics).toBeDefined();
      expect(jsonContent.urlMappings).toBeDefined();
      expect(jsonContent.validation).toBeDefined();
    });

    it('should export HTML report', () => {
      const filePath = reporter.exportHtmlReport('test-report.html');

      expect(mockFs.writeFileSync).toHaveBeenCalled();
      expect(filePath).toContain('test-report.html');

      // Verify HTML content
      const writeCall = mockFs.writeFileSync.mock.calls[0];
      const htmlContent = writeCall[1] as string;

      expect(htmlContent).toContain('<!DOCTYPE html>');
      expect(htmlContent).toContain('<title>Migration Report</title>');
      expect(htmlContent).toContain('Total Files');
    });

    it('should export dashboard report', () => {
      const filePath = reporter.exportDashboardReport('dashboard.html');

      expect(mockFs.writeFileSync).toHaveBeenCalled();
      expect(filePath).toContain('dashboard.html');

      // Verify dashboard content
      const writeCall = mockFs.writeFileSync.mock.calls[0];
      const htmlContent = writeCall[1] as string;

      expect(htmlContent).toContain('Migration Dashboard');
      expect(htmlContent).toContain('chart.js');
      expect(htmlContent).toContain('resultsChart');
    });

    it('should handle file system errors gracefully', () => {
      mockFs.writeFileSync.mockImplementation(() => {
        throw new Error('Write failed');
      });

      expect(() => reporter.exportJsonReport()).toThrow('Write failed');
    });
  });

  describe('Executive Summary', () => {
    it('should generate executive summary', () => {
      const summary = reporter.generateExecutiveSummary();

      expect(summary.overview).toBeDefined();
      expect(summary.keyMetrics).toBeDefined();
      expect(summary.highlights).toBeDefined();
      expect(summary.concerns).toBeDefined();
      expect(summary.recommendations).toBeDefined();
      expect(summary.nextSteps).toBeDefined();

      // Verify overview data
      expect(summary.overview.totalDocuments).toBe(10);
      expect(summary.overview.successfulMigrations).toBe(8);
      expect(summary.overview.successRate).toBe(80);
    });

    it('should identify highlights for good performance', () => {
      // Create a report with high success rate
      const highPerformanceReport = {
        ...mockReport,
        summary: { ...mockReport.summary, successful: 9, failed: 0, skipped: 1 }
      };

      const highPerfReporter = new MigrationReporter(highPerformanceReport, outputDir);
      const summary = highPerfReporter.generateExecutiveSummary();

      expect(summary.highlights.length).toBeGreaterThan(0);
      expect(summary.highlights.some(h => h.includes('success rate'))).toBe(true);
    });

    it('should identify concerns for poor performance', () => {
      // Create a report with low success rate
      const lowPerformanceReport = {
        ...mockReport,
        summary: { ...mockReport.summary, successful: 5, failed: 4, skipped: 1 }
      };

      const lowPerfReporter = new MigrationReporter(lowPerformanceReport, outputDir);
      const summary = lowPerfReporter.generateExecutiveSummary();

      expect(summary.concerns.length).toBeGreaterThan(0);
    });
  });

  describe('Error Handling', () => {
    it('should handle missing performance report', () => {
      const reportWithoutPerf = {
        ...mockReport,
        performanceReport: undefined
      };

      const reporterWithoutPerf = new MigrationReporter(reportWithoutPerf, outputDir);
      const analytics = reporterWithoutPerf.generateAnalytics();

      expect(analytics.performance.throughput).toBe(0);
      expect(analytics.performance.memoryUsage.peak).toBe(0);
      expect(analytics.performance.cacheEfficiency).toBe(0);
    });

    it('should handle missing relationship report', () => {
      const reportWithoutRel = {
        ...mockReport,
        relationshipReport: undefined
      };

      const reporterWithoutRel = new MigrationReporter(reportWithoutRel, outputDir);
      const analytics = reporterWithoutRel.generateAnalytics();

      expect(analytics.relationships.totalRelationships).toBe(0);
      expect(analytics.relationships.brokenLinks).toBe(0);
      expect(analytics.relationships.isolatedDocuments).toBe(0);
    });

    it('should create output directory if it does not exist', () => {
      mockFs.existsSync.mockReturnValue(false);

      new MigrationReporter(mockReport, outputDir);

      expect(mockFs.mkdirSync).toHaveBeenCalledWith(outputDir, { recursive: true });
    });
  });

  describe('Utility Functions', () => {
    it('should format durations correctly', () => {
      const reporter = new MigrationReporter(mockReport, outputDir);
      
      // Access private method for testing
      const formatDuration = (reporter as any).formatDuration;
      
      expect(formatDuration(500)).toBe('500ms');
      expect(formatDuration(1500)).toBe('1.5s');
      expect(formatDuration(65000)).toBe('1.1m');
      expect(formatDuration(3700000)).toBe('1.0h');
    });

    it('should generate timestamps correctly', () => {
      const reporter = new MigrationReporter(mockReport, outputDir);
      
      // Access private method for testing
      const getTimestamp = (reporter as any).getTimestamp;
      const timestamp = getTimestamp();
      
      expect(timestamp).toMatch(/^\d{4}-\d{2}-\d{2}$/);
    });

    it('should convert file paths to web paths correctly', () => {
      const reporter = new MigrationReporter(mockReport, outputDir);
      
      // Access private method for testing
      const convertToWebPath = (reporter as any).convertToWebPath;
      
      expect(convertToWebPath('docs/guide.md')).toBe('/guide');
      expect(convertToWebPath('docs/api/reference.md')).toBe('/api/reference');
      expect(convertToWebPath('docs\\windows\\path.md')).toBe('/windows/path');
    });
  });
});