/**
 * Type definitions for the Documentation Migration system
 */

export interface FileMetadata {
  filePath: string;
  fileName: string;
  title: string;
  urlName: string;
  category: string;
  subcategory?: string;
  tags: string[];
  difficulty: 'Beginner' | 'Intermediate' | 'Advanced' | 'Expert';
  readingTime: number;
  prerequisites?: string;
  summary?: string;
  lastModified: string;
  contentHash: string;
}

export interface KnowledgeArticleData {
  Title: string;
  UrlName: string;
  Summary?: string;
  Content__c: string;
  Difficulty_Level__c: string;
  Reading_Time__c: number;
  Tags__c: string;
  Prerequisites__c?: string;
  Related_Articles__c?: string;
  Language: string;
  IsVisibleInApp: boolean;
  IsVisibleInPkb: boolean;
  IsVisibleInCsp: boolean;
}

export interface MigrationConfig {
  salesforce: SalesforceConfig;
  migration: MigrationSettings;
  categoryRules: CategoryRule[];
  contentProcessing: ContentProcessingOptions;
}

export interface SalesforceConfig {
  loginUrl: string;
  username: string;
  password: string;
  securityToken: string;
  apiVersion: string;
}

export interface MigrationSettings {
  sourceDirectory: string;
  excludePatterns: string[];
  dryRun: boolean;
  batchSize: number;
  resumeFile: string;
}

export interface CategoryRule {
  pattern: RegExp;
  category: string;
  subcategory?: string;
  difficulty?: string;
}

export interface ContentProcessingOptions {
  imageHandling: 'embed' | 'link' | 'skip';
  linkProcessing: 'convert' | 'preserve';
  codeBlockStyling: 'salesforce' | 'default';
}

export interface MigrationProgress {
  totalFiles: number;
  processedFiles: number;
  successfulMigrations: number;
  failedMigrations: number;
  skippedFiles: number;
  startTime: string;
  lastCheckpoint: string;
  processedFileHashes: Record<string, string>;
}

export interface MigrationResult {
  success: boolean;
  filePath: string;
  articleId?: string;
  urlName: string;
  action: 'created' | 'updated' | 'skipped' | 'failed';
  error?: string;
  warnings: string[];
}

export interface MigrationReport {
  summary: {
    totalFiles: number;
    successful: number;
    failed: number;
    skipped: number;
    duration: number;
  };
  results: MigrationResult[];
  urlMappings: Record<string, string>;
  errors: Array<{
    file: string;
    error: string;
    stack?: string;
  }>;
  linkMappingReport: any;
  relationshipReport?: any;
  errorReport: any;
  progressReport: any;
  performanceReport?: any;
}

export interface ProcessingContext {
  sourceFile: string;
  targetArticle?: string;
  metadata: FileMetadata;
  attempt: number;
  maxAttempts: number;
}