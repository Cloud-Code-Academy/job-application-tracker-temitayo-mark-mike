/**
 * Unit tests for FileUtils class
 */

import { FileUtils } from '../../src/utils/FileUtils';
import * as fs from 'fs';
import * as path from 'path';

// Mock fs module
jest.mock('fs');
const mockFs = fs as jest.Mocked<typeof fs>;

describe('FileUtils', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('readFileWithEncoding', () => {
    it('should read UTF-8 files correctly', () => {
      const content = 'Hello, world!';
      const buffer = Buffer.from(content, 'utf8');
      mockFs.readFileSync.mockReturnValue(buffer);

      const result = FileUtils.readFileWithEncoding('/test/file.txt');
      
      expect(result.content).toBe(content);
      expect(result.encoding).toBe('utf8');
    });

    it('should handle UTF-8 BOM', () => {
      const content = 'Hello, world!';
      const bom = Buffer.from([0xEF, 0xBB, 0xBF]);
      const buffer = Buffer.concat([bom, Buffer.from(content, 'utf8')]);
      mockFs.readFileSync.mockReturnValue(buffer);

      const result = FileUtils.readFileWithEncoding('/test/file.txt');
      
      expect(result.content).toBe(content);
      expect(result.encoding).toBe('utf8-bom');
    });

    it('should throw error for unreadable files', () => {
      mockFs.readFileSync.mockImplementation(() => {
        throw new Error('File not found');
      });

      expect(() => FileUtils.readFileWithEncoding('/test/nonexistent.txt'))
        .toThrow('Failed to read file');
    });
  });

  describe('calculateFileHash', () => {
    it('should calculate SHA-256 hash correctly', () => {
      const content = 'test content';
      const buffer = Buffer.from(content, 'utf8');
      mockFs.readFileSync.mockReturnValue(buffer);

      const hash = FileUtils.calculateFileHash('/test/file.txt');
      
      expect(hash).toBe('1eebdf4fdc9fc7bf283031b93f9aef3338de9052f584b10f4e8a90f1d5b8b0e');
    });

    it('should throw error for unreadable files', () => {
      mockFs.readFileSync.mockImplementation(() => {
        throw new Error('Permission denied');
      });

      expect(() => FileUtils.calculateFileHash('/test/restricted.txt'))
        .toThrow('Failed to calculate hash');
    });
  });

  describe('getFileSize', () => {
    it('should return file size in bytes', () => {
      mockFs.statSync.mockReturnValue({
        size: 1024
      } as any);

      const size = FileUtils.getFileSize('/test/file.txt');
      
      expect(size).toBe(1024);
    });

    it('should throw error for non-existent files', () => {
      mockFs.statSync.mockImplementation(() => {
        throw new Error('File not found');
      });

      expect(() => FileUtils.getFileSize('/test/nonexistent.txt'))
        .toThrow('Failed to get file size');
    });
  });

  describe('formatFileSize', () => {
    it('should format bytes correctly', () => {
      expect(FileUtils.formatFileSize(512)).toBe('512 B');
      expect(FileUtils.formatFileSize(1024)).toBe('1.0 KB');
      expect(FileUtils.formatFileSize(1536)).toBe('1.5 KB');
      expect(FileUtils.formatFileSize(1048576)).toBe('1.0 MB');
      expect(FileUtils.formatFileSize(1073741824)).toBe('1.0 GB');
    });

    it('should handle zero bytes', () => {
      expect(FileUtils.formatFileSize(0)).toBe('0 B');
    });
  });

  describe('normalizePath', () => {
    it('should convert backslashes to forward slashes', () => {
      expect(FileUtils.normalizePath('path\\to\\file.txt')).toBe('path/to/file.txt');
      expect(FileUtils.normalizePath('path/to/file.txt')).toBe('path/to/file.txt');
    });
  });

  describe('getRelativePath', () => {
    it('should return normalized relative path', () => {
      // Mock path.relative to return a path with backslashes
      jest.spyOn(path, 'relative').mockReturnValue('subfolder\\file.txt');
      
      const result = FileUtils.getRelativePath('/base', '/base/subfolder/file.txt');
      
      expect(result).toBe('subfolder/file.txt');
    });
  });

  describe('isPathWithinDirectory', () => {
    it('should return true for paths within directory', () => {
      const result = FileUtils.isPathWithinDirectory('/base', '/base/subfolder/file.txt');
      expect(result).toBe(true);
    });

    it('should return false for paths outside directory', () => {
      const result = FileUtils.isPathWithinDirectory('/base', '/other/file.txt');
      expect(result).toBe(false);
    });

    it('should return false for parent directory traversal', () => {
      const result = FileUtils.isPathWithinDirectory('/base', '/base/../outside/file.txt');
      expect(result).toBe(false);
    });
  });

  describe('ensureDirectoryExists', () => {
    it('should create directory if it does not exist', () => {
      mockFs.existsSync.mockReturnValue(false);
      mockFs.mkdirSync.mockImplementation(() => {});

      FileUtils.ensureDirectoryExists('/test/new-dir');
      
      expect(mockFs.mkdirSync).toHaveBeenCalledWith('/test/new-dir', { recursive: true });
    });

    it('should not create directory if it already exists', () => {
      mockFs.existsSync.mockReturnValue(true);

      FileUtils.ensureDirectoryExists('/test/existing-dir');
      
      expect(mockFs.mkdirSync).not.toHaveBeenCalled();
    });

    it('should throw error if directory creation fails', () => {
      mockFs.existsSync.mockReturnValue(false);
      mockFs.mkdirSync.mockImplementation(() => {
        throw new Error('Permission denied');
      });

      expect(() => FileUtils.ensureDirectoryExists('/test/restricted'))
        .toThrow('Failed to create directory');
    });
  });

  describe('getFileExtension', () => {
    it('should return extension without dot', () => {
      expect(FileUtils.getFileExtension('file.txt')).toBe('txt');
      expect(FileUtils.getFileExtension('document.pdf')).toBe('pdf');
      expect(FileUtils.getFileExtension('archive.tar.gz')).toBe('gz');
    });

    it('should return empty string for files without extension', () => {
      expect(FileUtils.getFileExtension('README')).toBe('');
      expect(FileUtils.getFileExtension('file.')).toBe('');
    });
  });

  describe('getFileNameWithoutExtension', () => {
    it('should return filename without extension', () => {
      expect(FileUtils.getFileNameWithoutExtension('/path/to/file.txt')).toBe('file');
      expect(FileUtils.getFileNameWithoutExtension('document.pdf')).toBe('document');
      expect(FileUtils.getFileNameWithoutExtension('archive.tar.gz')).toBe('archive.tar');
    });

    it('should return full name for files without extension', () => {
      expect(FileUtils.getFileNameWithoutExtension('README')).toBe('README');
    });
  });

  describe('isFileModifiedSince', () => {
    it('should return true if file is modified after given date', () => {
      const modifiedDate = new Date('2024-01-02T10:00:00Z');
      const checkDate = new Date('2024-01-01T10:00:00Z');
      
      mockFs.statSync.mockReturnValue({
        mtime: modifiedDate
      } as any);

      const result = FileUtils.isFileModifiedSince('/test/file.txt', checkDate);
      
      expect(result).toBe(true);
    });

    it('should return false if file is not modified after given date', () => {
      const modifiedDate = new Date('2024-01-01T10:00:00Z');
      const checkDate = new Date('2024-01-02T10:00:00Z');
      
      mockFs.statSync.mockReturnValue({
        mtime: modifiedDate
      } as any);

      const result = FileUtils.isFileModifiedSince('/test/file.txt', checkDate);
      
      expect(result).toBe(false);
    });

    it('should return true if file cannot be accessed', () => {
      mockFs.statSync.mockImplementation(() => {
        throw new Error('File not found');
      });

      const result = FileUtils.isFileModifiedSince('/test/nonexistent.txt', new Date());
      
      expect(result).toBe(true);
    });
  });

  describe('validateSalesforceFileName', () => {
    it('should validate correct filenames', () => {
      const result = FileUtils.validateSalesforceFileName('valid-file-name');
      
      expect(result.isValid).toBe(true);
      expect(result.issues).toHaveLength(0);
    });

    it('should detect filename too long', () => {
      const longName = 'a'.repeat(81);
      const result = FileUtils.validateSalesforceFileName(longName);
      
      expect(result.isValid).toBe(false);
      expect(result.issues).toContain('Filename too long (max 80 characters for Salesforce URL names)');
    });

    it('should detect invalid characters', () => {
      const result = FileUtils.validateSalesforceFileName('file@name!');
      
      expect(result.isValid).toBe(false);
      expect(result.issues).toContain('Contains invalid characters (only letters, numbers, hyphens, and underscores allowed)');
    });

    it('should detect reserved names', () => {
      const result = FileUtils.validateSalesforceFileName('con');
      
      expect(result.isValid).toBe(false);
      expect(result.issues).toContain('Uses reserved system name');
    });

    it('should detect leading/trailing whitespace', () => {
      const result = FileUtils.validateSalesforceFileName(' filename ');
      
      expect(result.isValid).toBe(false);
      expect(result.issues).toContain('Contains leading or trailing whitespace');
    });

    it('should detect leading/trailing dots', () => {
      const result1 = FileUtils.validateSalesforceFileName('.filename');
      const result2 = FileUtils.validateSalesforceFileName('filename.');
      
      expect(result1.isValid).toBe(false);
      expect(result2.isValid).toBe(false);
      expect(result1.issues).toContain('Cannot start or end with a dot');
      expect(result2.issues).toContain('Cannot start or end with a dot');
    });
  });

  describe('generateSafeFileName', () => {
    it('should generate safe filename from problematic input', () => {
      const result = FileUtils.generateSafeFileName('My Document! @#$%');
      
      expect(result).toBe('my-document');
    });

    it('should handle filenames starting with numbers', () => {
      const result = FileUtils.generateSafeFileName('123-document');
      
      expect(result).toBe('doc-123-document');
    });

    it('should handle empty input', () => {
      const result = FileUtils.generateSafeFileName('');
      
      expect(result).toBe('unnamed-document');
    });

    it('should limit length to 80 characters', () => {
      const longInput = 'very-long-document-name-that-exceeds-the-maximum-allowed-length-for-salesforce-url-names';
      const result = FileUtils.generateSafeFileName(longInput);
      
      expect(result.length).toBeLessThanOrEqual(80);
    });

    it('should collapse multiple hyphens', () => {
      const result = FileUtils.generateSafeFileName('document---with---many---hyphens');
      
      expect(result).toBe('document-with-many-hyphens');
    });
  });

  describe('areFilesIdentical', () => {
    it('should return true for identical files', () => {
      const hash = 'abc123';
      mockFs.readFileSync.mockReturnValue(Buffer.from('same content'));

      const result = FileUtils.areFilesIdentical('/test/file1.txt', '/test/file2.txt');
      
      expect(result).toBe(true);
    });

    it('should return false for different files', () => {
      mockFs.readFileSync
        .mockReturnValueOnce(Buffer.from('content 1'))
        .mockReturnValueOnce(Buffer.from('content 2'));

      const result = FileUtils.areFilesIdentical('/test/file1.txt', '/test/file2.txt');
      
      expect(result).toBe(false);
    });

    it('should return false if files cannot be read', () => {
      mockFs.readFileSync.mockImplementation(() => {
        throw new Error('File not found');
      });

      const result = FileUtils.areFilesIdentical('/test/file1.txt', '/test/file2.txt');
      
      expect(result).toBe(false);
    });
  });

  describe('createBackup', () => {
    it('should create backup with default suffix', () => {
      mockFs.copyFileSync.mockImplementation(() => {});

      const backupPath = FileUtils.createBackup('/test/file.txt');
      
      expect(backupPath).toBe('/test/file.txt.backup');
      expect(mockFs.copyFileSync).toHaveBeenCalledWith('/test/file.txt', '/test/file.txt.backup');
    });

    it('should create backup with custom suffix', () => {
      mockFs.copyFileSync.mockImplementation(() => {});

      const backupPath = FileUtils.createBackup('/test/file.txt', '.bak');
      
      expect(backupPath).toBe('/test/file.txt.bak');
      expect(mockFs.copyFileSync).toHaveBeenCalledWith('/test/file.txt', '/test/file.txt.bak');
    });

    it('should throw error if backup creation fails', () => {
      mockFs.copyFileSync.mockImplementation(() => {
        throw new Error('Permission denied');
      });

      expect(() => FileUtils.createBackup('/test/file.txt'))
        .toThrow('Failed to create backup');
    });
  });
});