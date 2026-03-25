/**
 * Unit tests for ReportGenerator class
 */

import * as fs from 'fs';
import { ReportGenerator } from '../../src/reporting/ReportGenerator';
import { MigrationReport } from '../../src/types';

// Mock fs module
jest.mock('fs');
const mockFs = fs as jest.Mocked<typeof fs>;

// Mock MigrationReporter
jest.mock('../../src/reporting/MigrationReporter');

describe('ReportGenerator', () => {
  let reportGenerator: ReportGenerator;
  let mockMigrationReport: MigrationReport;
  const outputDir = './test-reports';

  beforeEach(() => {
    // Create mock migration report
    mockMigrationReport = {
      summary: {
        totalFiles: 10,
        successful: 8,
        failed: 1,
        skipped: 1,
        duration: 30000
      },
      results: [],
      urlMappings: {
        'docs/guide.md': '/knowledge/article/guide'
      },
      errors: [],
      linkMappingReport: {},
      relationshipReport: {},
      errorReport: {},
      progressReport: {},
      performanceReport: {}
    };

    reportGenerator = new ReportGenerator(mockMigrationReport, outputDir);

    // Mock fs methods
    mockFs.existsSync.mockReturnValue(true);
    mockFs.writeFileSync.mockReturnValue(undefined);
    mockFs.statSync.mockReturnValue({ size: 1024 } as any);

    jest.clearAllMocks();
  });

  describe('Report Generation', () => {
    it('should generate all report types successfully', async () => {
      const result = await reportGenerator.generateAllReports();

      expect(result.success).toBe(true);
      expect(result.reports.length).toBeGreaterThan(0);
      expect(result.errors.length).toBe(0);

      // Verify different report types are generated
      const reportTypes = result.reports.map(r => r.type);
      expect(reportTypes).toContain('json');
      expect(reportTypes).toContain('html');
      expect(reportTypes).toContain('dashboard');
      expect(reportTypes).toContain('executive-summary');
    });

    it('should generate specific report type', async () => {
      const jsonReportPath = await reportGenerator.generateReport('json');

      expect(jsonReportPath).toBeDefined();
      expect(typeof jsonReportPath).toBe('string');
      expect(mockFs.writeFileSync).toHaveBeenCalled();
    });

    it('should handle unknown report type', async () => {
      await expect(
        reportGenerator.generateReport('unknown' as any)
      ).rejects.toThrow('Unknown report type: unknown');
    });

    it('should handle file system errors gracefully', async () => {
      mockFs.writeFileSync.mockImplementation(() => {
        throw new Error('Write failed');
      });

      const result = await reportGenerator.generateAllReports();

      expect(result.success).toBe(false);
      expect(result.errors.length).toBeGreaterThan(0);
      expect(result.errors[0].type).toBe('generation');
    });
  });

  describe('CLI Summary Generation', () => {
    it('should generate CLI summary with correct structure', () => {
      const summary = reportGenerator.generateCliSummary();

      expect(summary.overview).toBeDefined();
      expect(summary.performance).toBeDefined();
      expect(summary.quality).toBeDefined();
      expect(summary.relationships).toBeDefined();
      expect(summary.recommendations).toBeDefined();

      // Verify overview data
      expect(summary.overview.totalFiles).toBe(10);
      expect(summary.overview.successful).toBe(8);
      expect(summary.overview.failed).toBe(1);
      expect(summary.overview.successRate).toBe('80%');
    });

    it('should format performance metrics correctly', () => {
      const summary = reportGenerator.generateCliSummary();

      expect(summary.performance.throughput).toContain('files/sec');
      expect(summary.performance.cacheHitRate).toContain('%');
      expect(summary.overview.duration).toBeDefined();
    });

    it('should include quality metrics', () => {
      const summary = reportGenerator.generateCliSummary();

      expect(summary.quality.score).toContain('/100');
      expect(typeof summary.quality.issues).toBe('number');
      expect(typeof summary.quality.warnings).toBe('number');
    });

    it('should include relationship metrics', () => {
      const summary = reportGenerator.generateCliSummary();

      expect(typeof summary.relationships.totalLinks).toBe('number');
      expect(typeof summary.relationships.brokenLinks).toBe('number');
      expect(typeof summary.relationships.isolatedDocs).toBe('number');
    });

    it('should limit recommendations to top 3', () => {
      const summary = reportGenerator.generateCliSummary();

      expect(Array.isArray(summary.recommendations)).toBe(true);
      expect(summary.recommendations.length).toBeLessThanOrEqual(3);
    });
  });

  describe('Report Index Generation', () => {
    it('should generate report index HTML', () => {
      const mockReports = [
        { type: 'json', path: './reports/report.json', size: 1024 },
        { type: 'html', path: './reports/report.html', size: 2048 },
        { type: 'dashboard', path: './reports/dashboard.html', size: 4096 }
      ];

      const indexPath = reportGenerator.generateReportIndex(mockReports);

      expect(mockFs.writeFileSync).toHaveBeenCalled();
      expect(indexPath).toContain('index.html');

      // Verify HTML content
      const writeCall = mockFs.writeFileSync.mock.calls[0];
      const htmlContent = writeCall[1] as string;

      expect(htmlContent).toContain('<!DOCTYPE html>');
      expect(htmlContent).toContain('Migration Reports');
      expect(htmlContent).toContain('report.json');
      expect(htmlContent).toContain('report.html');
      expect(htmlContent).toContain('dashboard.html');
    });

    it('should handle empty report list', () => {
      const indexPath = reportGenerator.generateReportIndex([]);

      expect(mockFs.writeFileSync).toHaveBeenCalled();
      expect(indexPath).toContain('index.html');
    });
  });

  describe('Utility Functions', () => {
    it('should get correct report display names', () => {
      const generator = reportGenerator as any;

      expect(generator.getReportDisplayName('json')).toBe('Complete JSON Report');
      expect(generator.getReportDisplayName('html')).toBe('HTML Report');
      expect(generator.getReportDisplayName('dashboard')).toBe('Interactive Dashboard');
      expect(generator.getReportDisplayName('executive-summary')).toBe('Executive Summary');
      expect(generator.getReportDisplayName('unknown')).toBe('unknown');
    });

    it('should format file sizes correctly', () => {
      const generator = reportGenerator as any;

      expect(generator.formatFileSize(0)).toBe('0 B');
      expect(generator.formatFileSize(1024)).toBe('1.0 KB');
      expect(generator.formatFileSize(1024 * 1024)).toBe('1.0 MB');
      expect(generator.formatFileSize(1024 * 1024 * 1024)).toBe('1.0 GB');
    });

    it('should format durations correctly', () => {
      const generator = reportGenerator as any;

      expect(generator.formatDuration(500)).toBe('500ms');
      expect(generator.formatDuration(1500)).toBe('1.5s');
      expect(generator.formatDuration(65000)).toBe('1.1m');
      expect(generator.formatDuration(3700000)).toBe('1.0h');
    });

    it('should generate timestamps correctly', () => {
      const generator = reportGenerator as any;
      const timestamp = generator.getTimestamp();

      expect(timestamp).toMatch(/^\d{4}-\d{2}-\d{2}$/);
    });

    it('should handle file size errors gracefully', () => {
      mockFs.statSync.mockImplementation(() => {
        throw new Error('File not found');
      });

      const generator = reportGenerator as any;
      const size = generator.getFileSize('/nonexistent/file.txt');

      expect(size).toBe(0);
    });
  });

  describe('Report Type Validation', () => {
    it('should validate supported report types', async () => {
      const supportedTypes = ['json', 'html', 'dashboard', 'executive-summary', 'url-mappings', 'validation'];

      for (const type of supportedTypes) {
        await expect(
          reportGenerator.generateReport(type as any)
        ).resolves.toBeDefined();
      }
    });

    it('should reject unsupported report types', async () => {
      const unsupportedTypes = ['pdf', 'xml', 'csv', 'txt'];

      for (const type of unsupportedTypes) {
        await expect(
          reportGenerator.generateReport(type as any)
        ).rejects.toThrow(`Unknown report type: ${type}`);
      }
    });
  });

  describe('Error Handling', () => {
    it('should handle missing migration report data gracefully', () => {
      const incompleteReport = {
        summary: { totalFiles: 0, successful: 0, failed: 0, skipped: 0, duration: 0 },
        results: [],
        urlMappings: {},
        errors: []
      } as any;

      const incompleteGenerator = new ReportGenerator(incompleteReport, outputDir);
      const summary = incompleteGenerator.generateCliSummary();

      expect(summary.overview.totalFiles).toBe(0);
      expect(summary.overview.successRate).toBe('0%');
    });

    it('should handle undefined performance report', () => {
      const reportWithoutPerf = {
        ...mockMigrationReport,
        performanceReport: undefined
      };

      const generator = new ReportGenerator(reportWithoutPerf, outputDir);
      const summary = generator.generateCliSummary();

      expect(summary.performance).toBeDefined();
      expect(summary.performance.throughput).toBeDefined();
    });

    it('should handle undefined relationship report', () => {
      const reportWithoutRel = {
        ...mockMigrationReport,
        relationshipReport: undefined
      };

      const generator = new ReportGenerator(reportWithoutRel, outputDir);
      const summary = generator.generateCliSummary();

      expect(summary.relationships).toBeDefined();
      expect(summary.relationships.totalLinks).toBe(0);
    });
  });

  describe('Integration with MigrationReporter', () => {
    it('should properly initialize MigrationReporter', () => {
      expect(reportGenerator).toBeDefined();
      expect((reportGenerator as any).reporter).toBeDefined();
    });

    it('should pass correct parameters to MigrationReporter', () => {
      const customOutputDir = './custom-reports';
      const customGenerator = new ReportGenerator(mockMigrationReport, customOutputDir);

      expect(customGenerator).toBeDefined();
      expect((customGenerator as any).outputDirectory).toBe(customOutputDir);
    });
  });

  describe('Concurrent Report Generation', () => {
    it('should handle multiple concurrent report generations', async () => {
      const promises = [
        reportGenerator.generateReport('json'),
        reportGenerator.generateReport('html'),
        reportGenerator.generateReport('dashboard')
      ];

      const results = await Promise.all(promises);

      expect(results).toHaveLength(3);
      results.forEach(result => {
        expect(typeof result).toBe('string');
        expect(result.length).toBeGreaterThan(0);
      });
    });

    it('should handle concurrent generateAllReports calls', async () => {
      const promises = [
        reportGenerator.generateAllReports(),
        reportGenerator.generateAllReports()
      ];

      const results = await Promise.all(promises);

      expect(results).toHaveLength(2);
      results.forEach(result => {
        expect(result.success).toBe(true);
        expect(result.reports.length).toBeGreaterThan(0);
      });
    });
  });
});