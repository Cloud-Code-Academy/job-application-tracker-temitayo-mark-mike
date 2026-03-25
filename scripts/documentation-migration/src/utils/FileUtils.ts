/**
 * Utility functions for file operations and path handling
 */

import * as fs from 'fs';
import * as path from 'path';
import * as crypto from 'crypto';

export class FileUtils {
  
  /**
   * Safely read a file with encoding detection
   */
  public static readFileWithEncoding(filePath: string): { content: string; encoding: string } {
    try {
      // Try UTF-8 first
      const buffer = fs.readFileSync(filePath);
      
      // Check for BOM
      if (buffer.length >= 3 && buffer[0] === 0xEF && buffer[1] === 0xBB && buffer[2] === 0xBF) {
        return { content: buffer.toString('utf8').substring(1), encoding: 'utf8-bom' };
      }
      
      // Try to decode as UTF-8
      const content = buffer.toString('utf8');
      
      // Check if content contains replacement characters (indicates encoding issues)
      if (content.includes('\uFFFD')) {
        // Try other encodings
        const encodings = ['latin1', 'ascii'];
        for (const encoding of encodings) {
          try {
            const decoded = buffer.toString(encoding as BufferEncoding);
            if (!decoded.includes('\uFFFD')) {
              return { content: decoded, encoding };
            }
          } catch {
            continue;
          }
        }
      }
      
      return { content, encoding: 'utf8' };
    } catch (error) {
      throw new Error(`Failed to read file ${filePath}: ${error}`);
    }
  }

  /**
   * Calculate file hash for change detection
   */
  public static calculateFileHash(filePath: string): string {
    try {
      const content = fs.readFileSync(filePath);
      return crypto.createHash('sha256').update(content).digest('hex');
    } catch (error) {
      throw new Error(`Failed to calculate hash for ${filePath}: ${error}`);
    }
  }

  /**
   * Get file size in bytes
   */
  public static getFileSize(filePath: string): number {
    try {
      const stats = fs.statSync(filePath);
      return stats.size;
    } catch (error) {
      throw new Error(`Failed to get file size for ${filePath}: ${error}`);
    }
  }

  /**
   * Format file size in human-readable format
   */
  public static formatFileSize(bytes: number): string {
    const units = ['B', 'KB', 'MB', 'GB'];
    let size = bytes;
    let unitIndex = 0;
    
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    
    return `${size.toFixed(unitIndex === 0 ? 0 : 1)} ${units[unitIndex]}`;
  }

  /**
   * Normalize path separators for cross-platform compatibility
   */
  public static normalizePath(filePath: string): string {
    return filePath.replace(/\\/g, '/');
  }

  /**
   * Get relative path with normalized separators
   */
  public static getRelativePath(from: string, to: string): string {
    const relativePath = path.relative(from, to);
    return this.normalizePath(relativePath);
  }

  /**
   * Check if a path is within a directory (security check)
   */
  public static isPathWithinDirectory(basePath: string, targetPath: string): boolean {
    const resolvedBase = path.resolve(basePath);
    const resolvedTarget = path.resolve(targetPath);
    const relative = path.relative(resolvedBase, resolvedTarget);
    
    return !relative.startsWith('..') && !path.isAbsolute(relative);
  }

  /**
   * Create directory if it doesn't exist
   */
  public static ensureDirectoryExists(dirPath: string): void {
    try {
      if (!fs.existsSync(dirPath)) {
        fs.mkdirSync(dirPath, { recursive: true });
      }
    } catch (error) {
      throw new Error(`Failed to create directory ${dirPath}: ${error}`);
    }
  }

  /**
   * Get file extension without the dot
   */
  public static getFileExtension(filePath: string): string {
    const ext = path.extname(filePath);
    return ext.startsWith('.') ? ext.substring(1) : ext;
  }

  /**
   * Get filename without extension
   */
  public static getFileNameWithoutExtension(filePath: string): string {
    const basename = path.basename(filePath);
    const ext = path.extname(basename);
    return basename.substring(0, basename.length - ext.length);
  }

  /**
   * Check if file has been modified since a given date
   */
  public static isFileModifiedSince(filePath: string, since: Date): boolean {
    try {
      const stats = fs.statSync(filePath);
      return stats.mtime > since;
    } catch (error) {
      // If file doesn't exist or can't be accessed, consider it modified
      return true;
    }
  }

  /**
   * Get file modification time
   */
  public static getFileModificationTime(filePath: string): Date {
    try {
      const stats = fs.statSync(filePath);
      return stats.mtime;
    } catch (error) {
      throw new Error(`Failed to get modification time for ${filePath}: ${error}`);
    }
  }

  /**
   * Validate filename for Salesforce compatibility
   */
  public static validateSalesforceFileName(fileName: string): ValidationResult {
    const issues: string[] = [];
    
    // Check length
    if (fileName.length > 80) {
      issues.push('Filename too long (max 80 characters for Salesforce URL names)');
    }
    
    // Check for invalid characters
    const invalidChars = /[^a-zA-Z0-9\-_]/g;
    if (invalidChars.test(fileName)) {
      issues.push('Contains invalid characters (only letters, numbers, hyphens, and underscores allowed)');
    }
    
    // Check for reserved names
    const reservedNames = ['con', 'prn', 'aux', 'nul', 'com1', 'com2', 'com3', 'com4', 'com5', 'com6', 'com7', 'com8', 'com9', 'lpt1', 'lpt2', 'lpt3', 'lpt4', 'lpt5', 'lpt6', 'lpt7', 'lpt8', 'lpt9'];
    if (reservedNames.includes(fileName.toLowerCase())) {
      issues.push('Uses reserved system name');
    }
    
    // Check for leading/trailing spaces or dots
    if (fileName !== fileName.trim()) {
      issues.push('Contains leading or trailing whitespace');
    }
    
    if (fileName.startsWith('.') || fileName.endsWith('.')) {
      issues.push('Cannot start or end with a dot');
    }
    
    return {
      isValid: issues.length === 0,
      issues
    };
  }

  /**
   * Generate a safe filename for Salesforce
   */
  public static generateSafeFileName(originalName: string): string {
    let safeName = originalName
      .toLowerCase()
      .replace(/[^a-z0-9\-_\s]/g, '') // Remove invalid characters
      .replace(/\s+/g, '-') // Replace spaces with hyphens
      .replace(/-+/g, '-') // Collapse multiple hyphens
      .replace(/^-|-$/g, '') // Remove leading/trailing hyphens
      .substring(0, 80); // Limit length
    
    // Ensure it doesn't start with a number
    if (/^\d/.test(safeName)) {
      safeName = 'doc-' + safeName;
    }
    
    // Ensure it's not empty
    if (!safeName) {
      safeName = 'unnamed-document';
    }
    
    return safeName;
  }

  /**
   * Compare two files to check if they're identical
   */
  public static areFilesIdentical(filePath1: string, filePath2: string): boolean {
    try {
      const hash1 = this.calculateFileHash(filePath1);
      const hash2 = this.calculateFileHash(filePath2);
      return hash1 === hash2;
    } catch (error) {
      return false;
    }
  }

  /**
   * Get directory size recursively
   */
  public static getDirectorySize(dirPath: string): number {
    let totalSize = 0;
    
    try {
      const entries = fs.readdirSync(dirPath, { withFileTypes: true });
      
      for (const entry of entries) {
        const fullPath = path.join(dirPath, entry.name);
        
        if (entry.isDirectory()) {
          totalSize += this.getDirectorySize(fullPath);
        } else if (entry.isFile()) {
          const stats = fs.statSync(fullPath);
          totalSize += stats.size;
        }
      }
    } catch (error) {
      // Continue on error
    }
    
    return totalSize;
  }

  /**
   * Create a backup of a file
   */
  public static createBackup(filePath: string, backupSuffix: string = '.backup'): string {
    try {
      const backupPath = filePath + backupSuffix;
      fs.copyFileSync(filePath, backupPath);
      return backupPath;
    } catch (error) {
      throw new Error(`Failed to create backup of ${filePath}: ${error}`);
    }
  }
}

/**
 * Validation result interface
 */
interface ValidationResult {
  isValid: boolean;
  issues: string[];
}