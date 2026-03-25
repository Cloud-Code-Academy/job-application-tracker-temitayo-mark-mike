/**
 * Unit tests for FileScanner class
 */

import { FileScanner, FileScannerOptions, ScanningStats } from '../../src/core/FileScanner';
import { FileUtils } from '../../src/utils/FileUtils';
import * as fs from 'fs';
import * as path from 'path';

// Mock fs module
jest.mock('fs');
const mockFs = fs as jest.Mocked<typeof fs>;

// Mock FileUtils
jest.mock('../../src/utils/FileUtils');
const mockFileUtils = FileUtils as jest.Mocked<typeof FileUtils>;

describe('FileScanner', () => {
  const testRootPath = '/test/docs';
  let fileScanner: FileScanner;

  beforeEach(() => {
    jest.clearAllMocks();
    
    // Mock root path exists and is directory
    mockFs.existsSync.mockReturnValue(true);
    mockFs.statSync.mockReturnValue({
      isDirectory: () => true,
      isFile: () => false,
      mtime: new Date('2024-01-01T10:00:00Z')
    } as any);
  });

  describe('constructor', () => {
    it('should create FileScanner with valid root path', () => {
      expect(() => new FileScanner(testRootPath)).not.toThrow();
    });

    it('should throw error for non-existent root path', () => {
      mockFs.existsSync.mockReturnValue(false);
      
      expect(() => new FileScanner('/non/existent/path')).toThrow('Root path does not exist');
    });

    it('should throw error if root path is not a directory', () => {
      mockFs.statSync.mockReturnValue({
        isDirectory: () => false,
        isFile: () => true
      } as any);
      
      expect(() => new FileScanner(testRootPath)).toThrow('Root path is not a directory');
    });

    it('should accept custom options', () => {
      const options: FileScannerOptions = {
        excludePatterns: ['*.tmp', 'private-*'],
        includeHidden: true,
        maxDepth: 5
      };
      
      expect(() => new FileScanner(testRootPath, options)).not.toThrow();
    });
  });

  describe('scanFiles', () => {
    beforeEach(() => {
      fileScanner = new FileScanner(testRootPath);
    });

    it('should scan and return markdown files', async () => {
      // Mock directory structure
      mockFs.readdirSync.mockReturnValue([
        { name: 'README.md', isDirectory: () => false, isFile: () => true },
        { name: 'guide.md', isDirectory: () => false, isFile: () => true },
        { name: 'image.png', isDirectory: () => false, isFile: () => true },
        { name: 'subfolder', isDirectory: () => true, isFile: () => false }
      ] as any);

      // Mock file reading
      mockFs.readFileSync.mockReturnValue('# Test Document\n\nContent here');
      mockFs.statSync.mockReturnValue({
        mtime: new Date('2024-01-01T10:00:00Z'),
        isDirectory: () => false,
        isFile: () => true
      } as any);

      const files = await fileScanner.scanFiles();
      
      expect(files).toHaveLength(2); // Only markdown files
      expect(files[0].fileName).toBe('README.md');
      expect(files[1].fileName).toBe('guide.md');
    });

    it('should exclude files matching exclude patterns', async () => {
      const options: FileScannerOptions = {
        excludePatterns: ['private-*', '*.tmp']
      };
      fileScanner = new FileScanner(testRootPath, options);

      mockFs.readdirSync.mockReturnValue([
        { name: 'public.md', isDirectory: () => false, isFile: () => true },
        { name: 'private-secret.md', isDirectory: () => false, isFile: () => true },
        { name: 'temp.tmp', isDirectory: () => false, isFile: () => true }
      ] as any);

      mockFs.readFileSync.mockReturnValue('# Test Document');
      mockFs.statSync.mockReturnValue({
        mtime: new Date('2024-01-01T10:00:00Z'),
        isDirectory: () => false,
        isFile: () => true
      } as any);

      const files = await fileScanner.scanFiles();
      
      expect(files).toHaveLength(1);
      expect(files[0].fileName).toBe('public.md');
    });

    it('should skip hidden files by default', async () => {
      mockFs.readdirSync.mockReturnValue([
        { name: 'visible.md', isDirectory: () => false, isFile: () => true },
        { name: '.hidden.md', isDirectory: () => false, isFile: () => true }
      ] as any);

      mockFs.readFileSync.mockReturnValue('# Test Document');
      mockFs.statSync.mockReturnValue({
        mtime: new Date('2024-01-01T10:00:00Z'),
        isDirectory: () => false,
        isFile: () => true
      } as any);

      const files = await fileScanner.scanFiles();
      
      expect(files).toHaveLength(1);
      expect(files[0].fileName).toBe('visible.md');
    });

    it('should include hidden files when configured', async () => {
      const options: FileScannerOptions = { includeHidden: true };
      fileScanner = new FileScanner(testRootPath, options);

      mockFs.readdirSync.mockReturnValue([
        { name: 'visible.md', isDirectory: () => false, isFile: () => true },
        { name: '.hidden.md', isDirectory: () => false, isFile: () => true }
      ] as any);

      mockFs.readFileSync.mockReturnValue('# Test Document');
      mockFs.statSync.mockReturnValue({
        mtime: new Date('2024-01-01T10:00:00Z'),
        isDirectory: () => false,
        isFile: () => true
      } as any);

      const files = await fileScanner.scanFiles();
      
      expect(files).toHaveLength(2);
    });

    it('should handle nested directories', async () => {
      // Mock nested structure
      mockFs.readdirSync
        .mockReturnValueOnce([
          { name: 'root.md', isDirectory: () => false, isFile: () => true },
          { name: 'subfolder', isDirectory: () => true, isFile: () => false }
        ] as any)
        .mockReturnValueOnce([
          { name: 'nested.md', isDirectory: () => false, isFile: () => true }
        ] as any);

      mockFs.readFileSync.mockReturnValue('# Test Document');
      mockFs.statSync.mockReturnValue({
        mtime: new Date('2024-01-01T10:00:00Z'),
        isDirectory: () => false,
        isFile: () => true
      } as any);

      const files = await fileScanner.scanFiles();
      
      expect(files).toHaveLength(2);
      expect(files.some(f => f.fileName === 'root.md')).toBe(true);
      expect(files.some(f => f.fileName === 'nested.md')).toBe(true);
    });

    it('should respect max depth limit', async () => {
      const options: FileScannerOptions = { maxDepth: 1 };
      fileScanner = new FileScanner(testRootPath, options);

      // This should not be called for deep nesting due to maxDepth
      mockFs.readdirSync.mockReturnValue([
        { name: 'deep', isDirectory: () => true, isFile: () => false }
      ] as any);

      const files = await fileScanner.scanFiles();
      
      expect(files).toHaveLength(0);
    });

    it('should sort files by path', async () => {
      mockFs.readdirSync.mockReturnValue([
        { name: 'zebra.md', isDirectory: () => false, isFile: () => true },
        { name: 'alpha.md', isDirectory: () => false, isFile: () => true },
        { name: 'beta.md', isDirectory: () => false, isFile: () => true }
      ] as any);

      mockFs.readFileSync.mockReturnValue('# Test Document');
      mockFs.statSync.mockReturnValue({
        mtime: new Date('2024-01-01T10:00:00Z'),
        isDirectory: () => false,
        isFile: () => true
      } as any);

      const files = await fileScanner.scanFiles();
      
      expect(files).toHaveLength(3);
      expect(files[0].fileName).toBe('alpha.md');
      expect(files[1].fileName).toBe('beta.md');
      expect(files[2].fileName).toBe('zebra.md');
    });
  });

  describe('isMarkdownFile', () => {
    beforeEach(() => {
      fileScanner = new FileScanner(testRootPath);
    });

    it('should identify markdown files correctly', () => {
      expect(fileScanner.isMarkdownFile('test.md')).toBe(true);
      expect(fileScanner.isMarkdownFile('test.markdown')).toBe(true);
      expect(fileScanner.isMarkdownFile('test.mdown')).toBe(true);
      expect(fileScanner.isMarkdownFile('test.mkd')).toBe(true);
    });

    it('should reject non-markdown files', () => {
      expect(fileScanner.isMarkdownFile('test.txt')).toBe(false);
      expect(fileScanner.isMarkdownFile('test.pdf')).toBe(false);
      expect(fileScanner.isMarkdownFile('test.html')).toBe(false);
      expect(fileScanner.isMarkdownFile('test')).toBe(false);
    });

    it('should be case insensitive', () => {
      expect(fileScanner.isMarkdownFile('test.MD')).toBe(true);
      expect(fileScanner.isMarkdownFile('test.Markdown')).toBe(true);
    });
  });

  describe('getScanningStats', () => {
    beforeEach(() => {
      fileScanner = new FileScanner(testRootPath);
    });

    it('should return comprehensive scanning statistics', async () => {
      // Mock file structure
      mockFs.readdirSync.mockReturnValue([
        { name: 'doc1.md', isDirectory: () => false, isFile: () => true },
        { name: 'doc2.md', isDirectory: () => false, isFile: () => true },
        { name: 'image.png', isDirectory: () => false, isFile: () => true },
        { name: 'folder', isDirectory: () => true, isFile: () => false }
      ] as any);

      mockFs.statSync.mockReturnValue({
        size: 1024,
        isDirectory: () => false,
        isFile: () => true
      } as any);

      const stats = await fileScanner.getScanningStats();
      
      expect(stats.totalFiles).toBeGreaterThan(0);
      expect(stats.markdownFiles).toBe(2);
      expect(stats.directories).toBe(1);
      expect(stats.averageFileSize).toBeGreaterThan(0);
    });
  });

  describe('validateFileAccess', () => {
    beforeEach(() => {
      fileScanner = new FileScanner(testRootPath);
    });

    it('should validate accessible files', () => {
      mockFs.existsSync.mockReturnValue(true);
      mockFs.statSync.mockReturnValue({
        isFile: () => true
      } as any);
      mockFs.accessSync.mockImplementation(() => {}); // No error
      mockFs.readFileSync.mockReturnValue('content');

      const result = fileScanner.validateFileAccess('test.md');
      
      expect(result.accessible).toBe(true);
      expect(result.error).toBeUndefined();
    });

    it('should detect non-existent files', () => {
      mockFs.existsSync.mockReturnValue(false);

      const result = fileScanner.validateFileAccess('nonexistent.md');
      
      expect(result.accessible).toBe(false);
      expect(result.error).toBe('File does not exist');
    });

    it('should detect directories instead of files', () => {
      mockFs.existsSync.mockReturnValue(true);
      mockFs.statSync.mockReturnValue({
        isFile: () => false
      } as any);

      const result = fileScanner.validateFileAccess('folder');
      
      expect(result.accessible).toBe(false);
      expect(result.error).toBe('Path is not a file');
    });

    it('should detect permission errors', () => {
      mockFs.existsSync.mockReturnValue(true);
      mockFs.statSync.mockReturnValue({
        isFile: () => true
      } as any);
      mockFs.accessSync.mockImplementation(() => {
        throw new Error('Permission denied');
      });

      const result = fileScanner.validateFileAccess('restricted.md');
      
      expect(result.accessible).toBe(false);
      expect(result.error).toContain('Access error');
    });

    it('should warn about empty files', () => {
      mockFs.existsSync.mockReturnValue(true);
      mockFs.statSync.mockReturnValue({
        isFile: () => true
      } as any);
      mockFs.accessSync.mockImplementation(() => {}); // No error
      mockFs.readFileSync.mockReturnValue(''); // Empty file

      const result = fileScanner.validateFileAccess('empty.md');
      
      expect(result.accessible).toBe(true);
      expect(result.warning).toBe('File is empty');
    });
  });

  describe('error handling', () => {
    beforeEach(() => {
      fileScanner = new FileScanner(testRootPath);
    });

    it('should handle directory read errors gracefully', async () => {
      mockFs.readdirSync.mockImplementation(() => {
        throw new Error('Permission denied');
      });

      await expect(fileScanner.scanFiles()).rejects.toThrow('Failed to scan directory');
    });

    it('should continue processing when individual files fail', async () => {
      mockFs.readdirSync.mockReturnValue([
        { name: 'good.md', isDirectory: () => false, isFile: () => true },
        { name: 'bad.md', isDirectory: () => false, isFile: () => true }
      ] as any);

      // Mock one file to fail
      mockFs.readFileSync
        .mockReturnValueOnce('# Good file')
        .mockImplementationOnce(() => {
          throw new Error('File corrupted');
        });

      mockFs.statSync.mockReturnValue({
        mtime: new Date('2024-01-01T10:00:00Z'),
        isDirectory: () => false,
        isFile: () => true
      } as any);

      // Should continue and process the good file
      const files = await fileScanner.scanFiles();
      expect(files).toHaveLength(1);
      expect(files[0].fileName).toBe('good.md');
    });
  });
});