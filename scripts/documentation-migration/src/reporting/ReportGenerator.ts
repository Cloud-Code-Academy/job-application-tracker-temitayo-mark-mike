/**
 * Report generator utility for creating various types of migration reports
 */

import * as fs from 'fs';
import * as path from 'path';
import { MigrationReporter } from './MigrationReporter';
import { MigrationReport } from '../types';

export class ReportGenerator {
  private reporter: MigrationReporter;
  private outputDirectory: string;

  constructor(migrationReport: MigrationReport, outputDirectory: string = './reports') {
    this.reporter = new MigrationReporter(migrationReport, outputDirectory);
    this.outputDirectory = outputDirectory;
  }

  /**
   * Generate all report types
   */
  public async generateAllReports(): Promise<ReportGenerationResult> {
    const results: ReportGenerationResult = {
      success: true,
      reports: [],
      errors: []
    };

    try {
      // Generate JSON report
      const jsonPath = this.reporter.exportJsonReport();
      results.reports.push({
        type: 'json',
        path: jsonPath,
        size: this.getFileSize(jsonPath)
      });

      // Generate HTML report
      const htmlPath = this.reporter.exportHtmlReport();
      results.reports.push({
        type: 'html',
        path: htmlPath,
        size: this.getFileSize(htmlPath)
      });

      // Generate dashboard
      const dashboardPath = this.reporter.exportDashboardReport();
      results.reports.push({
        type: 'dashboard',
        path: dashboardPath,
        size: this.getFileSize(dashboardPath)
      });

      // Generate executive summary
      const executiveSummary = this.reporter.generateExecutiveSummary();
      const summaryPath = this.generateExecutiveSummaryReport(executiveSummary);
      results.reports.push({
        type: 'executive-summary',
        path: summaryPath,
        size: this.getFileSize(summaryPath)
      });

      // Generate URL mapping files
      const urlMappingReport = this.reporter.generateUrlMappingReport();
      const mappingResults = this.generateUrlMappingFiles(urlMappingReport);
      results.reports.push(...mappingResults);

      // Generate validation report
      const validationReport = this.reporter.generateValidationReport();
      const validationPath = this.generateValidationReportFile(validationReport);
      results.reports.push({
        type: 'validation',
        path: validationPath,
        size: this.getFileSize(validationPath)
      });

    } catch (error) {
      results.success = false;
      results.errors.push({
        type: 'generation',
        message: error instanceof Error ? error.message : String(error)
      });
    }

    return results;
  }

  /**
   * Generate specific report type
   */
  public async generateReport(type: ReportType): Promise<string> {
    switch (type) {
      case 'json':
        return this.reporter.exportJsonReport();
      
      case 'html':
        return this.reporter.exportHtmlReport();
      
      case 'dashboard':
        return this.reporter.exportDashboardReport();
      
      case 'executive-summary':
        const summary = this.reporter.generateExecutiveSummary();
        return this.generateExecutiveSummaryReport(summary);
      
      case 'url-mappings':
        const urlReport = this.reporter.generateUrlMappingReport();
        const mappingFiles = this.generateUrlMappingFiles(urlReport);
        return mappingFiles[0]?.path || '';
      
      case 'validation':
        const validationReport = this.reporter.generateValidationReport();
        return this.generateValidationReportFile(validationReport);
      
      default:
        throw new Error(`Unknown report type: ${type}`);
    }
  }

  /**
   * Generate analytics summary for CLI output
   */
  public generateCliSummary(): CliSummary {
    const analytics = this.reporter.generateAnalytics();
    const stats = this.reporter.generateSummaryStatistics();
    const validation = this.reporter.generateValidationReport();

    return {
      overview: {
        totalFiles: stats.overview.totalFiles,
        successful: stats.overview.successful,
        failed: stats.overview.failed,
        successRate: `${stats.overview.successRate}%`,
        duration: this.formatDuration(stats.overview.totalDuration)
      },
      performance: {
        throughput: `${analytics.performance.throughput.toFixed(1)} files/sec`,
        averageTime: this.formatDuration(stats.overview.averageProcessingTime),
        cacheHitRate: `${(analytics.performance.cacheEfficiency * 100).toFixed(1)}%`
      },
      quality: {
        score: `${validation.summary.qualityScore}/100`,
        issues: validation.summary.totalIssues,
        warnings: validation.summary.totalWarnings
      },
      relationships: {
        totalLinks: analytics.relationships.totalRelationships,
        brokenLinks: analytics.relationships.brokenLinks,
        isolatedDocs: analytics.relationships.isolatedDocuments
      },
      recommendations: analytics.recommendations.slice(0, 3)
    };
  }

  /**
   * Generate report index file
   */
  public generateReportIndex(reports: ReportFile[]): string {
    const indexHtml = this.generateIndexTemplate(reports);
    const indexPath = path.join(this.outputDirectory, 'index.html');
    
    fs.writeFileSync(indexPath, indexHtml);
    
    return indexPath;
  }

  // Private helper methods

  private generateExecutiveSummaryReport(summary: any): string {
    const content = this.generateExecutiveSummaryTemplate(summary);
    const filename = `executive-summary-${this.getTimestamp()}.html`;
    const filePath = path.join(this.outputDirectory, filename);
    
    fs.writeFileSync(filePath, content);
    
    return filePath;
  }

  private generateUrlMappingFiles(urlReport: any): ReportFile[] {
    const files: ReportFile[] = [];
    const timestamp = this.getTimestamp();

    // Generate nginx config
    const nginxPath = path.join(this.outputDirectory, `nginx-redirects-${timestamp}.conf`);
    fs.writeFileSync(nginxPath, urlReport.redirectRules.nginx);
    files.push({
      type: 'nginx-config',
      path: nginxPath,
      size: this.getFileSize(nginxPath)
    });

    // Generate apache config
    const apachePath = path.join(this.outputDirectory, `apache-redirects-${timestamp}.htaccess`);
    fs.writeFileSync(apachePath, urlReport.redirectRules.apache);
    files.push({
      type: 'apache-config',
      path: apachePath,
      size: this.getFileSize(apachePath)
    });

    // Generate Cloudflare config
    const cloudflarePath = path.join(this.outputDirectory, `cloudflare-redirects-${timestamp}.json`);
    fs.writeFileSync(cloudflarePath, urlReport.redirectRules.cloudflare);
    files.push({
      type: 'cloudflare-config',
      path: cloudflarePath,
      size: this.getFileSize(cloudflarePath)
    });

    // Generate URL mapping JSON
    const mappingPath = path.join(this.outputDirectory, `url-mappings-${timestamp}.json`);
    fs.writeFileSync(mappingPath, JSON.stringify(urlReport, null, 2));
    files.push({
      type: 'url-mappings',
      path: mappingPath,
      size: this.getFileSize(mappingPath)
    });

    return files;
  }

  private generateValidationReportFile(validationReport: any): string {
    const content = this.generateValidationTemplate(validationReport);
    const filename = `validation-report-${this.getTimestamp()}.html`;
    const filePath = path.join(this.outputDirectory, filename);
    
    fs.writeFileSync(filePath, content);
    
    return filePath;
  }

  private generateExecutiveSummaryTemplate(summary: any): string {
    return `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Executive Summary - Migration Report</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; padding: 20px; background: #f8f9fa; }
        .container { max-width: 800px; margin: 0 auto; background: white; padding: 40px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .header { text-align: center; margin-bottom: 40px; }
        .header h1 { color: #2c3e50; margin-bottom: 10px; }
        .header p { color: #7f8c8d; font-size: 1.1em; }
        .metrics { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin: 30px 0; }
        .metric { text-align: center; padding: 20px; background: #ecf0f1; border-radius: 8px; }
        .metric-value { font-size: 2em; font-weight: bold; color: #3498db; }
        .metric-label { color: #7f8c8d; margin-top: 5px; }
        .section { margin: 30px 0; }
        .section h2 { color: #2c3e50; border-bottom: 2px solid #3498db; padding-bottom: 10px; }
        .highlight { background: #d5f4e6; padding: 15px; border-radius: 5px; margin: 10px 0; }
        .concern { background: #ffeaa7; padding: 15px; border-radius: 5px; margin: 10px 0; }
        .recommendation { background: #e3f2fd; padding: 15px; border-radius: 5px; margin: 10px 0; }
        ul { list-style-type: none; padding: 0; }
        li { padding: 8px 0; border-bottom: 1px solid #ecf0f1; }
        li:last-child { border-bottom: none; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Executive Summary</h1>
            <p>Documentation Migration Report - ${summary.overview.migrationDate}</p>
        </div>

        <div class="metrics">
            <div class="metric">
                <div class="metric-value">${summary.overview.totalDocuments}</div>
                <div class="metric-label">Documents Migrated</div>
            </div>
            <div class="metric">
                <div class="metric-value">${summary.overview.successRate}%</div>
                <div class="metric-label">Success Rate</div>
            </div>
            <div class="metric">
                <div class="metric-value">${summary.overview.totalDuration}</div>
                <div class="metric-label">Total Duration</div>
            </div>
            <div class="metric">
                <div class="metric-value">${summary.overview.qualityScore}/100</div>
                <div class="metric-label">Quality Score</div>
            </div>
        </div>

        <div class="section">
            <h2>Key Performance Metrics</h2>
            <ul>
                <li><strong>Average Processing Time:</strong> ${summary.keyMetrics.averageProcessingTime}</li>
                <li><strong>Documents per Hour:</strong> ${summary.keyMetrics.documentsPerHour}</li>
                <li><strong>Error Rate:</strong> ${summary.keyMetrics.errorRate}%</li>
                <li><strong>Content Quality Score:</strong> ${summary.keyMetrics.contentQualityScore}/100</li>
            </ul>
        </div>

        ${summary.highlights.length > 0 ? `
        <div class="section">
            <h2>Highlights</h2>
            ${summary.highlights.map((highlight: string) => `<div class="highlight">✅ ${highlight}</div>`).join('')}
        </div>
        ` : ''}

        ${summary.concerns.length > 0 ? `
        <div class="section">
            <h2>Areas of Concern</h2>
            ${summary.concerns.map((concern: string) => `<div class="concern">⚠️ ${concern}</div>`).join('')}
        </div>
        ` : ''}

        <div class="section">
            <h2>Recommendations</h2>
            ${summary.recommendations.map((rec: string) => `<div class="recommendation">💡 ${rec}</div>`).join('')}
        </div>

        <div class="section">
            <h2>Next Steps</h2>
            <ul>
                ${summary.nextSteps.map((step: string) => `<li>${step}</li>`).join('')}
            </ul>
        </div>
    </div>
</body>
</html>`;
  }

  private generateValidationTemplate(validationReport: any): string {
    return `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Content Validation Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; }
        .summary { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px; margin-bottom: 30px; }
        .summary-card { padding: 15px; background: #f8f9fa; border-radius: 5px; text-align: center; }
        .summary-value { font-size: 1.5em; font-weight: bold; }
        .issues { margin: 20px 0; }
        .issue-category { margin: 15px 0; }
        .issue-category h3 { color: #dc3545; }
        .issue-item { padding: 10px; margin: 5px 0; background: #fff5f5; border-left: 4px solid #dc3545; }
        .warning-item { padding: 10px; margin: 5px 0; background: #fffbf0; border-left: 4px solid #ffc107; }
        .suggestion-item { padding: 10px; margin: 5px 0; background: #f0f8ff; border-left: 4px solid #007bff; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Content Validation Report</h1>
        <p>Generated on ${validationReport.generatedAt}</p>

        <div class="summary">
            <div class="summary-card">
                <div class="summary-value">${validationReport.summary.qualityScore}/100</div>
                <div>Quality Score</div>
            </div>
            <div class="summary-card">
                <div class="summary-value">${validationReport.summary.totalIssues}</div>
                <div>Issues</div>
            </div>
            <div class="summary-card">
                <div class="summary-value">${validationReport.summary.totalWarnings}</div>
                <div>Warnings</div>
            </div>
            <div class="summary-card">
                <div class="summary-value">${validationReport.summary.totalSuggestions}</div>
                <div>Suggestions</div>
            </div>
        </div>

        <div class="issues">
            <h2>Issues by Category</h2>
            ${Object.entries(validationReport.issues).map(([category, issues]: [string, any[]]) => `
                <div class="issue-category">
                    <h3>${category} (${issues.length})</h3>
                    ${issues.map(issue => `
                        <div class="issue-item">
                            <strong>${issue.file}</strong>: ${issue.message}
                        </div>
                    `).join('')}
                </div>
            `).join('')}
        </div>

        <div class="recommendations">
            <h2>Recommendations</h2>
            ${validationReport.recommendations.map((rec: string) => `<p>• ${rec}</p>`).join('')}
        </div>
    </div>
</body>
</html>`;
  }

  private generateIndexTemplate(reports: ReportFile[]): string {
    return `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Migration Reports Index</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
        .container { max-width: 800px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; }
        .report-list { list-style: none; padding: 0; }
        .report-item { padding: 15px; margin: 10px 0; background: #f8f9fa; border-radius: 5px; display: flex; justify-content: space-between; align-items: center; }
        .report-link { text-decoration: none; color: #007bff; font-weight: bold; }
        .report-link:hover { text-decoration: underline; }
        .report-size { color: #6c757d; font-size: 0.9em; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Migration Reports</h1>
        <p>Generated on ${new Date().toISOString()}</p>
        
        <ul class="report-list">
            ${reports.map(report => `
                <li class="report-item">
                    <a href="${path.basename(report.path)}" class="report-link">
                        ${this.getReportDisplayName(report.type)}
                    </a>
                    <span class="report-size">${this.formatFileSize(report.size)}</span>
                </li>
            `).join('')}
        </ul>
    </div>
</body>
</html>`;
  }

  private getReportDisplayName(type: string): string {
    const displayNames: Record<string, string> = {
      'json': 'Complete JSON Report',
      'html': 'HTML Report',
      'dashboard': 'Interactive Dashboard',
      'executive-summary': 'Executive Summary',
      'validation': 'Content Validation Report',
      'nginx-config': 'Nginx Redirect Configuration',
      'apache-config': 'Apache Redirect Configuration',
      'cloudflare-config': 'Cloudflare Redirect Configuration',
      'url-mappings': 'URL Mappings'
    };
    
    return displayNames[type] || type;
  }

  private getFileSize(filePath: string): number {
    try {
      return fs.statSync(filePath).size;
    } catch {
      return 0;
    }
  }

  private formatFileSize(bytes: number): string {
    if (bytes === 0) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i];
  }

  private formatDuration(ms: number): string {
    if (ms < 1000) return `${ms}ms`;
    if (ms < 60000) return `${(ms / 1000).toFixed(1)}s`;
    if (ms < 3600000) return `${(ms / 60000).toFixed(1)}m`;
    return `${(ms / 3600000).toFixed(1)}h`;
  }

  private getTimestamp(): string {
    return new Date().toISOString().replace(/[:.]/g, '-').split('T')[0];
  }
}

// Type definitions

export type ReportType = 
  | 'json' 
  | 'html' 
  | 'dashboard' 
  | 'executive-summary' 
  | 'url-mappings' 
  | 'validation';

export interface ReportGenerationResult {
  success: boolean;
  reports: ReportFile[];
  errors: ReportError[];
}

export interface ReportFile {
  type: string;
  path: string;
  size: number;
}

export interface ReportError {
  type: string;
  message: string;
}

export interface CliSummary {
  overview: {
    totalFiles: number;
    successful: number;
    failed: number;
    successRate: string;
    duration: string;
  };
  performance: {
    throughput: string;
    averageTime: string;
    cacheHitRate: string;
  };
  quality: {
    score: string;
    issues: number;
    warnings: number;
  };
  relationships: {
    totalLinks: number;
    brokenLinks: number;
    isolatedDocs: number;
  };
  recommendations: string[];
}