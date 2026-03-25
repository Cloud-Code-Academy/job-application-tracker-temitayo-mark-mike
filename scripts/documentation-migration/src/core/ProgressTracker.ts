/**
 * Progress tracking and resume functionality for migration operations
 */

import * as fs from 'fs';
import * as path from 'path';
import { MigrationProgress, MigrationResult } from '../types';

export class ProgressTracker {
  private progressFile: string;
  private progress: MigrationProgress;
  private checkpointInterval: number;
  private lastCheckpointTime: number;
  private isInitialized: boolean = false;

  constructor(progressFile: string = '.migration-progress.json', checkpointInterval: number = 5000) {
    this.progressFile = progressFile;
    this.checkpointInterval = checkpointInterval;
    this.lastCheckpointTime = 0;
    this.progress = this.initializeProgress();
    this.isInitialized = true;
  }

  /**
   * Initialize or load existing progress
   */
  public initializeProgress(): MigrationProgress {
    if (fs.existsSync(this.progressFile)) {
      try {
        const data = fs.readFileSync(this.progressFile, 'utf8');
        const loadedProgress = JSON.parse(data) as MigrationProgress;
        
        // Validate loaded progress structure
        if (this.isValidProgress(loadedProgress)) {
          return loadedProgress;
        }
      } catch (error) {
        console.warn(`Failed to load progress file ${this.progressFile}: ${error}`);
      }
    }

    // Return new progress if file doesn't exist or is invalid
    return this.createNewProgress();
  }

  /**
   * Start a new migration session
   */
  public startMigration(totalFiles: number): void {
    this.progress = {
      totalFiles,
      processedFiles: 0,
      successfulMigrations: 0,
      failedMigrations: 0,
      skippedFiles: 0,
      startTime: new Date().toISOString(),
      lastCheckpoint: new Date().toISOString(),
      processedFileHashes: {}
    };
    
    this.saveProgress();
  }

  /**
   * Resume an existing migration session
   */
  public resumeMigration(): ResumeInfo {
    if (!this.hasExistingProgress()) {
      throw new Error('No existing migration progress found to resume');
    }

    const resumeInfo: ResumeInfo = {
      canResume: true,
      totalFiles: this.progress.totalFiles,
      processedFiles: this.progress.processedFiles,
      remainingFiles: this.progress.totalFiles - this.progress.processedFiles,
      successfulMigrations: this.progress.successfulMigrations,
      failedMigrations: this.progress.failedMigrations,
      skippedFiles: this.progress.skippedFiles,
      startTime: this.progress.startTime,
      lastCheckpoint: this.progress.lastCheckpoint,
      elapsedTime: this.calculateElapsedTime(),
      estimatedTimeRemaining: this.estimateTimeRemaining()
    };

    return resumeInfo;
  }

  /**
   * Record the processing of a file
   */
  public recordFileProcessed(filePath: string, result: MigrationResult): void {
    this.progress.processedFiles++;
    this.progress.processedFileHashes[filePath] = result.urlName || filePath;

    switch (result.action) {
      case 'created':
      case 'updated':
        this.progress.successfulMigrations++;
        break;
      case 'failed':
        this.progress.failedMigrations++;
        break;
      case 'skipped':
        this.progress.skippedFiles++;
        break;
    }

    this.progress.lastCheckpoint = new Date().toISOString();
    
    // Save checkpoint if enough time has passed
    this.saveCheckpointIfNeeded();
  }

  /**
   * Check if a file has already been processed
   */
  public isFileProcessed(filePath: string): boolean {
    return filePath in this.progress.processedFileHashes;
  }

  /**
   * Get list of processed files
   */
  public getProcessedFiles(): string[] {
    return Object.keys(this.progress.processedFileHashes);
  }

  /**
   * Get current progress information
   */
  public getProgress(): ProgressInfo {
    const elapsedTime = this.calculateElapsedTime();
    const completionPercentage = this.progress.totalFiles > 0 
      ? (this.progress.processedFiles / this.progress.totalFiles) * 100 
      : 0;

    return {
      totalFiles: this.progress.totalFiles,
      processedFiles: this.progress.processedFiles,
      remainingFiles: this.progress.totalFiles - this.progress.processedFiles,
      successfulMigrations: this.progress.successfulMigrations,
      failedMigrations: this.progress.failedMigrations,
      skippedFiles: this.progress.skippedFiles,
      completionPercentage,
      elapsedTime,
      estimatedTimeRemaining: this.estimateTimeRemaining(),
      averageTimePerFile: this.calculateAverageTimePerFile(),
      startTime: this.progress.startTime,
      lastCheckpoint: this.progress.lastCheckpoint,
      isComplete: this.progress.processedFiles >= this.progress.totalFiles
    };
  }

  /**
   * Generate a detailed progress report
   */
  public generateProgressReport(): ProgressReport {
    const progressInfo = this.getProgress();
    
    return {
      summary: {
        totalFiles: progressInfo.totalFiles,
        processedFiles: progressInfo.processedFiles,
        successfulMigrations: progressInfo.successfulMigrations,
        failedMigrations: progressInfo.failedMigrations,
        skippedFiles: progressInfo.skippedFiles,
        completionPercentage: progressInfo.completionPercentage,
        elapsedTime: progressInfo.elapsedTime,
        estimatedTimeRemaining: progressInfo.estimatedTimeRemaining
      },
      performance: {
        averageTimePerFile: progressInfo.averageTimePerFile,
        filesPerMinute: this.calculateFilesPerMinute(),
        throughputTrend: this.calculateThroughputTrend()
      },
      status: {
        isComplete: progressInfo.isComplete,
        canResume: this.hasExistingProgress(),
        lastCheckpoint: progressInfo.lastCheckpoint,
        healthStatus: this.assessHealthStatus()
      },
      processedFiles: Object.keys(this.progress.processedFileHashes)
    };
  }

  /**
   * Save current progress to file
   */
  public saveProgress(): void {
    try {
      const progressDir = path.dirname(this.progressFile);
      if (!fs.existsSync(progressDir)) {
        fs.mkdirSync(progressDir, { recursive: true });
      }

      const data = JSON.stringify(this.progress, null, 2);
      fs.writeFileSync(this.progressFile, data, 'utf8');
    } catch (error) {
      console.error(`Failed to save progress to ${this.progressFile}: ${error}`);
    }
  }

  /**
   * Clear progress and delete progress file
   */
  public clearProgress(): void {
    this.progress = this.createNewProgress();
    
    if (fs.existsSync(this.progressFile)) {
      try {
        fs.unlinkSync(this.progressFile);
      } catch (error) {
        console.warn(`Failed to delete progress file ${this.progressFile}: ${error}`);
      }
    }
  }

  /**
   * Check if there's existing progress to resume
   */
  public hasExistingProgress(): boolean {
    return fs.existsSync(this.progressFile) && this.progress.processedFiles > 0;
  }

  /**
   * Get files that still need to be processed
   */
  public getUnprocessedFiles(allFiles: string[]): string[] {
    return allFiles.filter(file => !this.isFileProcessed(file));
  }

  /**
   * Create a checkpoint manually
   */
  public createCheckpoint(): void {
    this.progress.lastCheckpoint = new Date().toISOString();
    this.saveProgress();
    this.lastCheckpointTime = Date.now();
  }

  /**
   * Validate migration completion
   */
  public validateCompletion(expectedFiles: string[]): CompletionValidation {
    const processedFiles = this.getProcessedFiles();
    const missingFiles = expectedFiles.filter(file => !this.isFileProcessed(file));
    const extraFiles = processedFiles.filter(file => !expectedFiles.includes(file));
    
    return {
      isComplete: missingFiles.length === 0,
      expectedFiles: expectedFiles.length,
      processedFiles: processedFiles.length,
      missingFiles,
      extraFiles,
      successRate: this.progress.totalFiles > 0 
        ? (this.progress.successfulMigrations / this.progress.totalFiles) * 100 
        : 0
    };
  }

  /**
   * Get migration statistics
   */
  public getStatistics(): MigrationStatistics {
    const elapsedTime = this.calculateElapsedTime();
    
    return {
      duration: {
        total: elapsedTime,
        average: this.calculateAverageTimePerFile(),
        fastest: 0, // Would need to track individual file times
        slowest: 0  // Would need to track individual file times
      },
      throughput: {
        filesPerSecond: elapsedTime > 0 ? this.progress.processedFiles / (elapsedTime / 1000) : 0,
        filesPerMinute: this.calculateFilesPerMinute(),
        filesPerHour: this.calculateFilesPerMinute() * 60
      },
      success: {
        successRate: this.progress.totalFiles > 0 
          ? (this.progress.successfulMigrations / this.progress.totalFiles) * 100 
          : 0,
        failureRate: this.progress.totalFiles > 0 
          ? (this.progress.failedMigrations / this.progress.totalFiles) * 100 
          : 0,
        skipRate: this.progress.totalFiles > 0 
          ? (this.progress.skippedFiles / this.progress.totalFiles) * 100 
          : 0
      }
    };
  }

  // Private helper methods

  private createNewProgress(): MigrationProgress {
    return {
      totalFiles: 0,
      processedFiles: 0,
      successfulMigrations: 0,
      failedMigrations: 0,
      skippedFiles: 0,
      startTime: new Date().toISOString(),
      lastCheckpoint: new Date().toISOString(),
      processedFileHashes: {}
    };
  }

  private isValidProgress(progress: any): boolean {
    return progress &&
           typeof progress.totalFiles === 'number' &&
           typeof progress.processedFiles === 'number' &&
           typeof progress.successfulMigrations === 'number' &&
           typeof progress.failedMigrations === 'number' &&
           typeof progress.skippedFiles === 'number' &&
           typeof progress.startTime === 'string' &&
           typeof progress.lastCheckpoint === 'string' &&
           typeof progress.processedFileHashes === 'object';
  }

  private saveCheckpointIfNeeded(): void {
    const now = Date.now();
    if (now - this.lastCheckpointTime >= this.checkpointInterval) {
      this.saveProgress();
      this.lastCheckpointTime = now;
    }
  }

  private calculateElapsedTime(): number {
    const startTime = new Date(this.progress.startTime).getTime();
    return Date.now() - startTime;
  }

  private estimateTimeRemaining(): number {
    if (this.progress.processedFiles === 0) {
      return 0;
    }

    const elapsedTime = this.calculateElapsedTime();
    const averageTimePerFile = elapsedTime / this.progress.processedFiles;
    const remainingFiles = this.progress.totalFiles - this.progress.processedFiles;
    
    return remainingFiles * averageTimePerFile;
  }

  private calculateAverageTimePerFile(): number {
    if (this.progress.processedFiles === 0) {
      return 0;
    }

    const elapsedTime = this.calculateElapsedTime();
    return elapsedTime / this.progress.processedFiles;
  }

  private calculateFilesPerMinute(): number {
    const elapsedMinutes = this.calculateElapsedTime() / (1000 * 60);
    return elapsedMinutes > 0 ? this.progress.processedFiles / elapsedMinutes : 0;
  }

  private calculateThroughputTrend(): 'increasing' | 'decreasing' | 'stable' {
    // Simplified trend calculation - in a real implementation,
    // you'd track throughput over time windows
    return 'stable';
  }

  private assessHealthStatus(): 'healthy' | 'warning' | 'error' {
    const failureRate = this.progress.totalFiles > 0 
      ? (this.progress.failedMigrations / this.progress.totalFiles) * 100 
      : 0;

    if (failureRate > 50) return 'error';
    if (failureRate > 20) return 'warning';
    return 'healthy';
  }
}

// Type definitions

export interface ResumeInfo {
  canResume: boolean;
  totalFiles: number;
  processedFiles: number;
  remainingFiles: number;
  successfulMigrations: number;
  failedMigrations: number;
  skippedFiles: number;
  startTime: string;
  lastCheckpoint: string;
  elapsedTime: number;
  estimatedTimeRemaining: number;
}

export interface ProgressInfo {
  totalFiles: number;
  processedFiles: number;
  remainingFiles: number;
  successfulMigrations: number;
  failedMigrations: number;
  skippedFiles: number;
  completionPercentage: number;
  elapsedTime: number;
  estimatedTimeRemaining: number;
  averageTimePerFile: number;
  startTime: string;
  lastCheckpoint: string;
  isComplete: boolean;
}

export interface ProgressReport {
  summary: {
    totalFiles: number;
    processedFiles: number;
    successfulMigrations: number;
    failedMigrations: number;
    skippedFiles: number;
    completionPercentage: number;
    elapsedTime: number;
    estimatedTimeRemaining: number;
  };
  performance: {
    averageTimePerFile: number;
    filesPerMinute: number;
    throughputTrend: 'increasing' | 'decreasing' | 'stable';
  };
  status: {
    isComplete: boolean;
    canResume: boolean;
    lastCheckpoint: string;
    healthStatus: 'healthy' | 'warning' | 'error';
  };
  processedFiles: string[];
}

export interface CompletionValidation {
  isComplete: boolean;
  expectedFiles: number;
  processedFiles: number;
  missingFiles: string[];
  extraFiles: string[];
  successRate: number;
}

export interface MigrationStatistics {
  duration: {
    total: number;
    average: number;
    fastest: number;
    slowest: number;
  };
  throughput: {
    filesPerSecond: number;
    filesPerMinute: number;
    filesPerHour: number;
  };
  success: {
    successRate: number;
    failureRate: number;
    skipRate: number;
  };
}