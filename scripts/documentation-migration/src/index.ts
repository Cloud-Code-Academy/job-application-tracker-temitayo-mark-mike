/**
 * Main entry point for the Salesforce Documentation Migrator
 * 
 * This module exports the core functionality for programmatic use
 */

export { DocumentationMigrator, MigrationOptions, ResumeOptions, MigrationStatistics, ValidationResult } from './core/DocumentationMigrator';
export { FileScanner, FileScannerOptions, ScanningStats } from './core/FileScanner';
export { MetadataExtractor, FrontmatterResult, InferredMetadata, MetadataValidationResult } from './core/MetadataExtractor';
export { ContentProcessor, LinkMapper, ProcessedContent, ContentProcessingError } from './core/ContentProcessor';
export { LinkMapper as LinkMapperClass, MappingReport, MappingValidationResult, BrokenLink } from './core/LinkMapper';
export { CategoryMapper, CategoryMappingResult, DifficultyInference, CategoryValidationResult, CategoryMappingReport } from './core/CategoryMapper';
export { SalesforceClient, SalesforceApiError, AuthenticationResult, KnowledgeArticleResult, ConnectionTestResult, ApiUsageStats } from './core/SalesforceClient';
export { ProgressTracker, ResumeInfo, ProgressInfo, ProgressReport, CompletionValidation, MigrationStatistics } from './core/ProgressTracker';
export { ErrorHandler, RetryConfig, ErrorInfo, ErrorHandlingResult, ErrorReport, ErrorLogEntry } from './core/ErrorHandler';

// Export utilities
export { FileUtils } from './utils/FileUtils';
export { TextAnalyzer, KeywordResult, ComplexityAnalysis, TechnicalTerm, DocumentStructure } from './utils/TextAnalyzer';

export * from './types';
export * from './config';