/**
 * Unit tests for ProgressTracker class
 */

import { ProgressTracker, ResumeInfo, ProgressInfo, ProgressReport } from '../../src/core/ProgressTracker';
import { MigrationResult } from '../../src/types';
import * as fs from 'fs';

// Mock fs module
jest.mock('fs');
const mockFs = fs as jest.Mocked<typeof fs>;

describe('ProgressTracker', () => {
  let progressTracker: ProgressTracker;
  const testProgressFile = '.test-progress.json';

  beforeEach(() => {
    jest.clearAllMocks();
    progressTracker = new ProgressTracker(testProgressFile, 1000); // Short checkpoint interval for testing
  });

  afterEach(() => {
    // Clean up any real files that might have been created
    if (fs.existsSync && fs.existsSync(testProgressFile)) {
      try {
        fs.unlinkSync(testProgressFile);
      } catch (error) {
        // Ignore cleanup errors
      }
    }
  });

  describe('constructor and initialization', () => {
    it('should create new progress when no file exists', () => {
      mockFs.existsSync.mockReturnValue(false);

      const tracker = new ProgressTracker(testProgressFile);
      const progress = tracker.getProgress();

      expect(progress.totalFiles).toBe(0);
      expect(progress.processedFiles).toBe(0);
      expect(progress.successfulMigrations).toBe(0);
      expect(progress.failedMigrations).toBe(0);
      expect(progress.skippedFiles).toBe(0);
    });

    it('should load existing progress when file exists', () => {
      const existingProgress = {
        totalFiles: 10,
        processedFiles: 5,
        successfulMigrations: 4,
        failedMigrations: 1,
        skippedFiles: 0,
        startTime: '2024-01-01T10:00:00Z',
        lastCheckpoint: '2024-01-01T10:30:00Z',
        processedFileHashes: {
          'file1.md': 'file-1',
          'file2.md': 'file-2'
        }
      };

      mockFs.existsSync.mockReturnValue(true);
      mockFs.readFileSync.mockReturnValue(JSON.stringify(existingProgress));

      const tracker = new ProgressTracker(testProgressFile);
      const progress = tracker.getProgress();

      expect(progress.totalFiles).toBe(10);
      expect(progress.processedFiles).toBe(5);
      expect(progress.successfulMigrations).toBe(4);
      expect(progress.failedMigrations).toBe(1);
    });

    it('should handle corrupted progress file gracefully', () => {
      mockFs.existsSync.mockReturnValue(true);
      mockFs.readFileSync.mockReturnValue('invalid json');

      const tracker = new ProgressTracker(testProgressFile);
      const progress = tracker.getProgress();

      // Should create new progress when file is corrupted
      expect(progress.totalFiles).toBe(0);
      expect(progress.processedFiles).toBe(0);
    });

    it('should handle invalid progress structure', () => {
      const invalidProgress = {
        totalFiles: 'not a number',
        processedFiles: 5
        // Missing required fields
      };

      mockFs.existsSync.mockReturnValue(true);
      mockFs.readFileSync.mockReturnValue(JSON.stringify(invalidProgress));

      const tracker = new ProgressTracker(testProgressFile);
      const progress = tracker.getProgress();

      // Should create new progress when structure is invalid
      expect(progress.totalFiles).toBe(0);
      expect(progress.processedFiles).toBe(0);
    });
  });

  describe('startMigration', () => {
    it('should initialize new migration with correct values', () => {
      mockFs.writeFileSync.mockImplementation(() => {});

      progressTracker.startMigration(20);
      const progress = progressTracker.getProgress();

      expect(progress.totalFiles).toBe(20);
      expect(progress.processedFiles).toBe(0);
      expect(progress.successfulMigrations).toBe(0);
      expect(progress.failedMigrations).toBe(0);
      expect(progress.skippedFiles).toBe(0);
      expect(progress.startTime).toBeTruthy();
      expect(progress.lastCheckpoint).toBeTruthy();
    });

    it('should save progress to file', () => {
      mockFs.writeFileSync.mockImplementation(() => {});
      mockFs.existsSync.mockReturnValue(false);
      mockFs.mkdirSync.mockImplementation(() => {});

      progressTracker.startMigration(10);

      expect(mockFs.writeFileSync).toHaveBeenCalledWith(
        testProgressFile,
        expect.stringContaining('"totalFiles": 10'),
        'utf8'
      );
    });
  });

  describe('recordFileProcessed', () => {
    beforeEach(() => {
      mockFs.writeFileSync.mockImplementation(() => {});
      progressTracker.startMigration(5);
    });

    it('should record successful file processing', () => {
      const result: MigrationResult = {
        success: true,
        filePath: 'docs/test.md',
        urlName: 'test-document',
        action: 'created',
        warnings: []
      };

      progressTracker.recordFileProcessed('docs/test.md', result);
      const progress = progressTracker.getProgress();

      expect(progress.processedFiles).toBe(1);
      expect(progress.successfulMigrations).toBe(1);
      expect(progress.failedMigrations).toBe(0);
      expect(progress.skippedFiles).toBe(0);
    });

    it('should record failed file processing', () => {
      const result: MigrationResult = {
        success: false,
        filePath: 'docs/test.md',
        urlName: 'test-document',
        action: 'failed',
        error: 'Processing failed',
        warnings: []
      };

      progressTracker.recordFileProcessed('docs/test.md', result);
      const progress = progressTracker.getProgress();

      expect(progress.processedFiles).toBe(1);
      expect(progress.successfulMigrations).toBe(0);
      expect(progress.failedMigrations).toBe(1);
      expect(progress.skippedFiles).toBe(0);
    });

    it('should record skipped file processing', () => {
      const result: MigrationResult = {
        success: true,
        filePath: 'docs/test.md',
        urlName: 'test-document',
        action: 'skipped',
        warnings: []
      };

      progressTracker.recordFileProcessed('docs/test.md', result);
      const progress = progressTracker.getProgress();

      expect(progress.processedFiles).toBe(1);
      expect(progress.successfulMigrations).toBe(0);
      expect(progress.failedMigrations).toBe(0);
      expect(progress.skippedFiles).toBe(1);
    });

    it('should record updated file processing', () => {
      const result: MigrationResult = {
        success: true,
        filePath: 'docs/test.md',
        urlName: 'test-document',
        action: 'updated',
        warnings: []
      };

      progressTracker.recordFileProcessed('docs/test.md', result);
      const progress = progressTracker.getProgress();

      expect(progress.processedFiles).toBe(1);
      expect(progress.successfulMigrations).toBe(1);
      expect(progress.failedMigrations).toBe(0);
      expect(progress.skippedFiles).toBe(0);
    });

    it('should update last checkpoint time', () => {
      const result: MigrationResult = {
        success: true,
        filePath: 'docs/test.md',
        urlName: 'test-document',
        action: 'created',
        warnings: []
      };

      const initialProgress = progressTracker.getProgress();
      const initialCheckpoint = initialProgress.lastCheckpoint;

      // Wait a bit to ensure timestamp difference
      setTimeout(() => {
        progressTracker.recordFileProcessed('docs/test.md', result);
        const updatedProgress = progressTracker.getProgress();
        
        expect(updatedProgress.lastCheckpoint).not.toBe(initialCheckpoint);
      }, 10);
    });
  });

  describe('isFileProcessed', () => {
    beforeEach(() => {
      mockFs.writeFileSync.mockImplementation(() => {});
      progressTracker.startMigration(5);
    });

    it('should return false for unprocessed files', () => {
      expect(progressTracker.isFileProcessed('docs/unprocessed.md')).toBe(false);
    });

    it('should return true for processed files', () => {
      const result: MigrationResult = {
        success: true,
        filePath: 'docs/test.md',
        urlName: 'test-document',
        action: 'created',
        warnings: []
      };

      progressTracker.recordFileProcessed('docs/test.md', result);
      expect(progressTracker.isFileProcessed('docs/test.md')).toBe(true);
    });
  });

  describe('getUnprocessedFiles', () => {
    beforeEach(() => {
      mockFs.writeFileSync.mockImplementation(() => {});
      progressTracker.startMigration(5);
    });

    it('should return all files when none are processed', () => {
      const allFiles = ['file1.md', 'file2.md', 'file3.md'];
      const unprocessed = progressTracker.getUnprocessedFiles(allFiles);

      expect(unprocessed).toEqual(allFiles);
    });

    it('should return only unprocessed files', () => {
      const allFiles = ['file1.md', 'file2.md', 'file3.md'];
      
      const result: MigrationResult = {
        success: true,
        filePath: 'file1.md',
        urlName: 'file-1',
        action: 'created',
        warnings: []
      };

      progressTracker.recordFileProcessed('file1.md', result);
      const unprocessed = progressTracker.getUnprocessedFiles(allFiles);

      expect(unprocessed).toEqual(['file2.md', 'file3.md']);
    });

    it('should return empty array when all files are processed', () => {
      const allFiles = ['file1.md', 'file2.md'];
      
      const result1: MigrationResult = {
        success: true,
        filePath: 'file1.md',
        urlName: 'file-1',
        action: 'created',
        warnings: []
      };

      const result2: MigrationResult = {
        success: true,
        filePath: 'file2.md',
        urlName: 'file-2',
        action: 'created',
        warnings: []
      };

      progressTracker.recordFileProcessed('file1.md', result1);
      progressTracker.recordFileProcessed('file2.md', result2);
      
      const unprocessed = progressTracker.getUnprocessedFiles(allFiles);
      expect(unprocessed).toEqual([]);
    });
  });

  describe('resumeMigration', () => {
    it('should throw error when no existing progress', () => {
      mockFs.existsSync.mockReturnValue(false);
      const tracker = new ProgressTracker(testProgressFile);

      expect(() => tracker.resumeMigration()).toThrow('No existing migration progress found to resume');
    });

    it('should return resume info for existing progress', () => {
      const existingProgress = {
        totalFiles: 10,
        processedFiles: 3,
        successfulMigrations: 2,
        failedMigrations: 1,
        skippedFiles: 0,
        startTime: '2024-01-01T10:00:00Z',
        lastCheckpoint: '2024-01-01T10:30:00Z',
        processedFileHashes: {
          'file1.md': 'file-1',
          'file2.md': 'file-2',
          'file3.md': 'file-3'
        }
      };

      mockFs.existsSync.mockReturnValue(true);
      mockFs.readFileSync.mockReturnValue(JSON.stringify(existingProgress));

      const tracker = new ProgressTracker(testProgressFile);
      const resumeInfo = tracker.resumeMigration();

      expect(resumeInfo.canResume).toBe(true);
      expect(resumeInfo.totalFiles).toBe(10);
      expect(resumeInfo.processedFiles).toBe(3);
      expect(resumeInfo.remainingFiles).toBe(7);
      expect(resumeInfo.successfulMigrations).toBe(2);
      expect(resumeInfo.failedMigrations).toBe(1);
    });
  });

  describe('getProgress', () => {
    beforeEach(() => {
      mockFs.writeFileSync.mockImplementation(() => {});
      progressTracker.startMigration(10);
    });

    it('should calculate completion percentage correctly', () => {
      // Process 3 out of 10 files
      for (let i = 0; i < 3; i++) {
        const result: MigrationResult = {
          success: true,
          filePath: `file${i}.md`,
          urlName: `file-${i}`,
          action: 'created',
          warnings: []
        };
        progressTracker.recordFileProcessed(`file${i}.md`, result);
      }

      const progress = progressTracker.getProgress();
      expect(progress.completionPercentage).toBe(30);
    });

    it('should indicate completion when all files processed', () => {
      progressTracker.startMigration(2);
      
      const result1: MigrationResult = {
        success: true,
        filePath: 'file1.md',
        urlName: 'file-1',
        action: 'created',
        warnings: []
      };

      const result2: MigrationResult = {
        success: true,
        filePath: 'file2.md',
        urlName: 'file-2',
        action: 'created',
        warnings: []
      };

      progressTracker.recordFileProcessed('file1.md', result1);
      progressTracker.recordFileProcessed('file2.md', result2);

      const progress = progressTracker.getProgress();
      expect(progress.isComplete).toBe(true);
      expect(progress.completionPercentage).toBe(100);
    });
  });

  describe('generateProgressReport', () => {
    beforeEach(() => {
      mockFs.writeFileSync.mockImplementation(() => {});
      progressTracker.startMigration(10);
    });

    it('should generate comprehensive progress report', () => {
      // Process some files
      const results = [
        { success: true, filePath: 'file1.md', urlName: 'file-1', action: 'created' as const, warnings: [] },
        { success: true, filePath: 'file2.md', urlName: 'file-2', action: 'updated' as const, warnings: [] },
        { success: false, filePath: 'file3.md', urlName: 'file-3', action: 'failed' as const, error: 'Error', warnings: [] }
      ];

      results.forEach((result, index) => {
        progressTracker.recordFileProcessed(`file${index + 1}.md`, result);
      });

      const report = progressTracker.generateProgressReport();

      expect(report.summary.totalFiles).toBe(10);
      expect(report.summary.processedFiles).toBe(3);
      expect(report.summary.successfulMigrations).toBe(2);
      expect(report.summary.failedMigrations).toBe(1);
      expect(report.performance.averageTimePerFile).toBeGreaterThanOrEqual(0);
      expect(report.status.isComplete).toBe(false);
      expect(report.processedFiles).toHaveLength(3);
    });

    it('should assess health status correctly', () => {
      progressTracker.startMigration(4);

      // Create scenario with high failure rate
      const results = [
        { success: false, filePath: 'file1.md', urlName: 'file-1', action: 'failed' as const, error: 'Error', warnings: [] },
        { success: false, filePath: 'file2.md', urlName: 'file-2', action: 'failed' as const, error: 'Error', warnings: [] },
        { success: false, filePath: 'file3.md', urlName: 'file-3', action: 'failed' as const, error: 'Error', warnings: [] },
        { success: true, filePath: 'file4.md', urlName: 'file-4', action: 'created' as const, warnings: [] }
      ];

      results.forEach((result, index) => {
        progressTracker.recordFileProcessed(`file${index + 1}.md`, result);
      });

      const report = progressTracker.generateProgressReport();
      expect(report.status.healthStatus).toBe('error'); // 75% failure rate
    });
  });

  describe('validateCompletion', () => {
    beforeEach(() => {
      mockFs.writeFileSync.mockImplementation(() => {});
      progressTracker.startMigration(3);
    });

    it('should validate successful completion', () => {
      const expectedFiles = ['file1.md', 'file2.md', 'file3.md'];
      
      expectedFiles.forEach(file => {
        const result: MigrationResult = {
          success: true,
          filePath: file,
          urlName: file.replace('.md', ''),
          action: 'created',
          warnings: []
        };
        progressTracker.recordFileProcessed(file, result);
      });

      const validation = progressTracker.validateCompletion(expectedFiles);

      expect(validation.isComplete).toBe(true);
      expect(validation.missingFiles).toHaveLength(0);
      expect(validation.extraFiles).toHaveLength(0);
      expect(validation.successRate).toBe(100);
    });

    it('should detect missing files', () => {
      const expectedFiles = ['file1.md', 'file2.md', 'file3.md'];
      
      // Only process first two files
      const result1: MigrationResult = {
        success: true,
        filePath: 'file1.md',
        urlName: 'file-1',
        action: 'created',
        warnings: []
      };

      const result2: MigrationResult = {
        success: true,
        filePath: 'file2.md',
        urlName: 'file-2',
        action: 'created',
        warnings: []
      };

      progressTracker.recordFileProcessed('file1.md', result1);
      progressTracker.recordFileProcessed('file2.md', result2);

      const validation = progressTracker.validateCompletion(expectedFiles);

      expect(validation.isComplete).toBe(false);
      expect(validation.missingFiles).toEqual(['file3.md']);
      expect(validation.extraFiles).toHaveLength(0);
    });

    it('should detect extra files', () => {
      const expectedFiles = ['file1.md', 'file2.md'];
      
      // Process expected files plus an extra one
      const results = [
        { success: true, filePath: 'file1.md', urlName: 'file-1', action: 'created' as const, warnings: [] },
        { success: true, filePath: 'file2.md', urlName: 'file-2', action: 'created' as const, warnings: [] },
        { success: true, filePath: 'extra.md', urlName: 'extra', action: 'created' as const, warnings: [] }
      ];

      results.forEach(result => {
        progressTracker.recordFileProcessed(result.filePath, result);
      });

      const validation = progressTracker.validateCompletion(expectedFiles);

      expect(validation.isComplete).toBe(true); // All expected files are processed
      expect(validation.missingFiles).toHaveLength(0);
      expect(validation.extraFiles).toEqual(['extra.md']);
    });
  });

  describe('clearProgress', () => {
    it('should clear progress and delete file', () => {
      mockFs.writeFileSync.mockImplementation(() => {});
      mockFs.existsSync.mockReturnValue(true);
      mockFs.unlinkSync.mockImplementation(() => {});

      progressTracker.startMigration(5);
      progressTracker.clearProgress();

      const progress = progressTracker.getProgress();
      expect(progress.totalFiles).toBe(0);
      expect(progress.processedFiles).toBe(0);
      expect(mockFs.unlinkSync).toHaveBeenCalledWith(testProgressFile);
    });

    it('should handle file deletion errors gracefully', () => {
      mockFs.writeFileSync.mockImplementation(() => {});
      mockFs.existsSync.mockReturnValue(true);
      mockFs.unlinkSync.mockImplementation(() => {
        throw new Error('Permission denied');
      });

      // Should not throw error
      expect(() => progressTracker.clearProgress()).not.toThrow();
    });
  });

  describe('checkpoint functionality', () => {
    it('should create checkpoint manually', () => {
      mockFs.writeFileSync.mockImplementation(() => {});
      progressTracker.startMigration(5);

      const initialProgress = progressTracker.getProgress();
      const initialCheckpoint = initialProgress.lastCheckpoint;

      // Wait a bit and create checkpoint
      setTimeout(() => {
        progressTracker.createCheckpoint();
        const updatedProgress = progressTracker.getProgress();
        
        expect(updatedProgress.lastCheckpoint).not.toBe(initialCheckpoint);
        expect(mockFs.writeFileSync).toHaveBeenCalled();
      }, 10);
    });
  });

  describe('statistics', () => {
    beforeEach(() => {
      mockFs.writeFileSync.mockImplementation(() => {});
      progressTracker.startMigration(10);
    });

    it('should calculate migration statistics', () => {
      // Process some files with different outcomes
      const results = [
        { success: true, filePath: 'file1.md', urlName: 'file-1', action: 'created' as const, warnings: [] },
        { success: true, filePath: 'file2.md', urlName: 'file-2', action: 'updated' as const, warnings: [] },
        { success: false, filePath: 'file3.md', urlName: 'file-3', action: 'failed' as const, error: 'Error', warnings: [] },
        { success: true, filePath: 'file4.md', urlName: 'file-4', action: 'skipped' as const, warnings: [] }
      ];

      results.forEach((result, index) => {
        progressTracker.recordFileProcessed(`file${index + 1}.md`, result);
      });

      const stats = progressTracker.getStatistics();

      expect(stats.success.successRate).toBe(20); // 2 successful out of 10 total
      expect(stats.success.failureRate).toBe(10); // 1 failed out of 10 total
      expect(stats.success.skipRate).toBe(10); // 1 skipped out of 10 total
      expect(stats.throughput.filesPerSecond).toBeGreaterThanOrEqual(0);
      expect(stats.duration.total).toBeGreaterThanOrEqual(0);
    });
  });
});