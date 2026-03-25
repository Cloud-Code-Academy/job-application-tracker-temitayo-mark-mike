/**
 * File scanning and discovery module for markdown documentation files
 */

import * as fs from 'fs';
import * as path from 'path';
import * as crypto from 'crypto';
import { FileMetadata } from '../types';

export class FileScanner {
  private rootPath: string;
  private excludePatterns: string[];
  private includeHidden: boolean;
  private maxDepth: number;

  constructor(rootPath: string, options: FileScannerOptions = {}) {
    this.rootPath = path.resolve(rootPath);
    this.excludePatterns = options.excludePatterns || [];
    this.includeHidden = options.includeHidden || false;
    this.maxDepth = options.maxDepth || 10;

    // Validate root path exists
    if (!fs.existsSync(this.rootPath)) {
      throw new Error(`Root path does not exist: ${this.rootPath}`);
    }

    // Ensure root path is a directory
    const stats = fs.statSync(this.rootPath);
    if (!stats.isDirectory()) {
      throw new Error(`Root path is not a directory: ${this.rootPath}`);
    }
  }

  /**
   * Scan for all markdown files in the directory tree
   */
  public async scanFiles(): Promise<FileMetadata[]> {
    const files: FileMetadata[] = [];
    await this.scanDirectory(this.rootPath, files, 0);
    
    // Sort files by path for consistent ordering
    files.sort((a, b) => a.filePath.localeCompare(b.filePath));
    
    return files;
  }

  /**
   * Scan a specific directory recursively
   */
  private async scanDirectory(dirPath: string, files: FileMetadata[], depth: number): Promise<void> {
    // Check depth limit
    if (depth > this.maxDepth) {
      return;
    }

    try {
      const entries = fs.readdirSync(dirPath, { withFileTypes: true });

      for (const entry of entries) {
        const fullPath = path.join(dirPath, entry.name);
        const relativePath = path.relative(this.rootPath, fullPath);

        // Skip if excluded by patterns
        if (this.isExcluded(relativePath, entry.name)) {
          continue;
        }

        // Skip hidden files unless explicitly included
        if (!this.includeHidden && entry.name.startsWith('.')) {
          continue;
        }

        if (entry.isDirectory()) {
          // Recursively scan subdirectories
          await this.scanDirectory(fullPath, files, depth + 1);
        } else if (entry.isFile() && this.isMarkdownFile(entry.name)) {
          // Process markdown files
          try {
            const metadata = await this.extractFileMetadata(fullPath);
            files.push(metadata);
          } catch (error) {
            // Log error but continue processing other files
            console.warn(`Failed to process file ${fullPath}: ${error}`);
          }
        }
      }
    } catch (error) {
      throw new Error(`Failed to scan directory ${dirPath}: ${error}`);
    }
  }

  /**
   * Extract basic metadata from a file
   */
  private async extractFileMetadata(filePath: string): Promise<FileMetadata> {
    const stats = fs.statSync(filePath);
    const content = fs.readFileSync(filePath, 'utf8');
    const relativePath = path.relative(this.rootPath, filePath);
    
    // Generate content hash for change detection
    const contentHash = crypto.createHash('sha256').update(content).digest('hex');
    
    // Extract basic title from filename or first heading
    const fileName = path.basename(filePath, '.md');
    const title = this.extractTitle(content, fileName);
    
    // Generate URL-friendly name
    const urlName = this.generateUrlName(title);

    return {
      filePath: relativePath,
      fileName: path.basename(filePath),
      title,
      urlName,
      category: '', // Will be set by CategoryMapper
      subcategory: undefined,
      tags: [], // Will be set by MetadataExtractor
      difficulty: 'Intermediate', // Default, will be refined by MetadataExtractor
      readingTime: 0, // Will be calculated by MetadataExtractor
      prerequisites: undefined,
      summary: undefined,
      lastModified: stats.mtime.toISOString(),
      contentHash
    };
  }

  /**
   * Check if a file is a markdown file
   */
  public isMarkdownFile(fileName: string): boolean {
    const markdownExtensions = ['.md', '.markdown', '.mdown', '.mkd'];
    const ext = path.extname(fileName).toLowerCase();
    return markdownExtensions.includes(ext);
  }

  /**
   * Check if a file/directory should be excluded
   */
  private isExcluded(relativePath: string, fileName: string): boolean {
    for (const pattern of this.excludePatterns) {
      if (this.matchesPattern(pattern, relativePath, fileName)) {
        return true;
      }
    }
    return false;
  }

  /**
   * Check if a path matches an exclusion pattern
   */
  private matchesPattern(pattern: string, relativePath: string, fileName: string): boolean {
    // Convert glob patterns to regex
    if (pattern.includes('*') || pattern.includes('?')) {
      const regexPattern = this.globToRegex(pattern);
      return regexPattern.test(relativePath) || regexPattern.test(fileName);
    }
    
    // Exact match
    if (pattern === fileName || pattern === relativePath) {
      return true;
    }
    
    // Prefix match for directories
    if (relativePath.startsWith(pattern + '/') || relativePath.startsWith(pattern + '\\')) {
      return true;
    }
    
    return false;
  }

  /**
   * Convert glob pattern to regex
   */
  private globToRegex(pattern: string): RegExp {
    // Escape special regex characters except * and ?
    let regexPattern = pattern
      .replace(/[.+^${}()|[\]\\]/g, '\\$&')
      .replace(/\*/g, '.*')
      .replace(/\?/g, '.');
    
    // Handle directory separators
    regexPattern = regexPattern.replace(/\\\//g, '[/\\\\]');
    
    return new RegExp(`^${regexPattern}$`, 'i');
  }

  /**
   * Extract title from content or generate from filename
   */
  private extractTitle(content: string, fileName: string): string {
    // Try to find first heading
    const lines = content.split('\n');
    for (const line of lines.slice(0, 10)) { // Check first 10 lines
      const trimmed = line.trim();
      if (trimmed.startsWith('# ')) {
        return trimmed.substring(2).trim();
      }
    }
    
    // Try to find title in frontmatter
    const frontmatterMatch = content.match(/^---\s*\n([\s\S]*?)\n---/);
    if (frontmatterMatch) {
      const titleMatch = frontmatterMatch[1].match(/^title:\s*(.+)$/m);
      if (titleMatch) {
        return titleMatch[1].trim().replace(/['"]/g, '');
      }
    }
    
    // Generate from filename
    return this.fileNameToTitle(fileName);
  }

  /**
   * Convert filename to readable title
   */
  private fileNameToTitle(fileName: string): string {
    return fileName
      .replace(/[-_]/g, ' ')
      .replace(/\b\w/g, l => l.toUpperCase())
      .trim();
  }

  /**
   * Generate URL-friendly name from title
   */
  private generateUrlName(title: string): string {
    return title
      .toLowerCase()
      .replace(/[^a-z0-9\s-]/g, '')
      .replace(/\s+/g, '-')
      .replace(/-+/g, '-')
      .replace(/^-|-$/g, '')
      .substring(0, 80); // Salesforce URL name limit
  }

  /**
   * Get scanning statistics
   */
  public async getScanningStats(): Promise<ScanningStats> {
    const allFiles = await this.scanAllFiles();
    const markdownFiles = allFiles.filter(file => this.isMarkdownFile(file.name));
    const excludedFiles = allFiles.filter(file => 
      this.isExcluded(path.relative(this.rootPath, file.path), file.name)
    );

    return {
      totalFiles: allFiles.length,
      markdownFiles: markdownFiles.length,
      excludedFiles: excludedFiles.length,
      processableFiles: markdownFiles.length - excludedFiles.filter(f => this.isMarkdownFile(f.name)).length,
      directories: allFiles.filter(file => file.isDirectory).length,
      largestFile: this.findLargestFile(markdownFiles),
      averageFileSize: this.calculateAverageSize(markdownFiles)
    };
  }

  /**
   * Scan all files (not just markdown) for statistics
   */
  private async scanAllFiles(): Promise<FileInfo[]> {
    const files: FileInfo[] = [];
    await this.scanAllFilesRecursive(this.rootPath, files, 0);
    return files;
  }

  /**
   * Recursive helper for scanning all files
   */
  private async scanAllFilesRecursive(dirPath: string, files: FileInfo[], depth: number): Promise<void> {
    if (depth > this.maxDepth) return;

    try {
      const entries = fs.readdirSync(dirPath, { withFileTypes: true });

      for (const entry of entries) {
        const fullPath = path.join(dirPath, entry.name);
        
        if (entry.isDirectory()) {
          files.push({
            name: entry.name,
            path: fullPath,
            size: 0,
            isDirectory: true
          });
          await this.scanAllFilesRecursive(fullPath, files, depth + 1);
        } else {
          const stats = fs.statSync(fullPath);
          files.push({
            name: entry.name,
            path: fullPath,
            size: stats.size,
            isDirectory: false
          });
        }
      }
    } catch (error) {
      // Continue on error
    }
  }

  /**
   * Find the largest file
   */
  private findLargestFile(files: FileInfo[]): { name: string; size: number } | null {
    if (files.length === 0) return null;
    
    const largest = files.reduce((max, file) => file.size > max.size ? file : max);
    return { name: largest.name, size: largest.size };
  }

  /**
   * Calculate average file size
   */
  private calculateAverageSize(files: FileInfo[]): number {
    if (files.length === 0) return 0;
    
    const totalSize = files.reduce((sum, file) => sum + file.size, 0);
    return Math.round(totalSize / files.length);
  }

  /**
   * Validate file accessibility and permissions
   */
  public validateFileAccess(filePath: string): FileAccessResult {
    try {
      const fullPath = path.resolve(this.rootPath, filePath);
      
      // Check if file exists
      if (!fs.existsSync(fullPath)) {
        return { accessible: false, error: 'File does not exist' };
      }

      // Check if it's a file (not directory)
      const stats = fs.statSync(fullPath);
      if (!stats.isFile()) {
        return { accessible: false, error: 'Path is not a file' };
      }

      // Try to read the file
      fs.accessSync(fullPath, fs.constants.R_OK);
      
      // Try to read a small portion to verify encoding
      const buffer = fs.readFileSync(fullPath, { encoding: 'utf8', flag: 'r' });
      if (buffer.length === 0) {
        return { accessible: true, warning: 'File is empty' };
      }

      return { accessible: true };
    } catch (error) {
      return { 
        accessible: false, 
        error: `Access error: ${error instanceof Error ? error.message : 'Unknown error'}` 
      };
    }
  }
}

/**
 * Options for file scanner configuration
 */
export interface FileScannerOptions {
  excludePatterns?: string[];
  includeHidden?: boolean;
  maxDepth?: number;
}

/**
 * File information for statistics
 */
interface FileInfo {
  name: string;
  path: string;
  size: number;
  isDirectory: boolean;
}

/**
 * Scanning statistics
 */
export interface ScanningStats {
  totalFiles: number;
  markdownFiles: number;
  excludedFiles: number;
  processableFiles: number;
  directories: number;
  largestFile: { name: string; size: number } | null;
  averageFileSize: number;
}

/**
 * File access validation result
 */
export interface FileAccessResult {
  accessible: boolean;
  error?: string;
  warning?: string;
}