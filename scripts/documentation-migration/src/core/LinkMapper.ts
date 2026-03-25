/**
 * Link mapping system for resolving internal documentation links
 */

import * as path from 'path';
import { FileUtils } from '../utils/FileUtils';

export class LinkMapper {
  private mappings: Map<string, string> = new Map();
  private reverseMappings: Map<string, string> = new Map();
  private baseDirectory: string;

  constructor(baseDirectory: string) {
    this.baseDirectory = path.resolve(baseDirectory);
  }

  /**
   * Add a mapping from original file path to Knowledge article URL
   */
  public addMapping(originalPath: string, knowledgeUrl: string): void {
    const normalizedPath = this.normalizePath(originalPath);
    this.mappings.set(normalizedPath, knowledgeUrl);
    this.reverseMappings.set(knowledgeUrl, normalizedPath);
  }

  /**
   * Resolve an internal link to a Knowledge article URL
   */
  public resolveLink(href: string, sourceFile: string): string | null {
    try {
      // Handle different types of links
      if (href.startsWith('#')) {
        // Anchor link - keep as is but may need adjustment
        return href;
      }

      // Resolve relative path
      const sourcePath = path.resolve(this.baseDirectory, sourceFile);
      const sourceDir = path.dirname(sourcePath);
      const targetPath = path.resolve(sourceDir, href);
      
      // Normalize the target path
      const normalizedTarget = this.normalizePath(path.relative(this.baseDirectory, targetPath));
      
      // Remove .md extension for lookup
      const lookupPath = normalizedTarget.replace(/\.md$/, '');
      
      // Try exact match first
      let knowledgeUrl = this.mappings.get(lookupPath);
      if (knowledgeUrl) {
        return knowledgeUrl;
      }

      // Try with .md extension
      knowledgeUrl = this.mappings.get(lookupPath + '.md');
      if (knowledgeUrl) {
        return knowledgeUrl;
      }

      // Try fuzzy matching
      knowledgeUrl = this.fuzzyMatch(lookupPath);
      if (knowledgeUrl) {
        return knowledgeUrl;
      }

      // If no mapping found, return null
      return null;
    } catch (error) {
      console.warn(`Failed to resolve link ${href} from ${sourceFile}: ${error}`);
      return null;
    }
  }

  /**
   * Get all current mappings
   */
  public getAllMappings(): Record<string, string> {
    const result: Record<string, string> = {};
    for (const [originalPath, knowledgeUrl] of this.mappings.entries()) {
      result[originalPath] = knowledgeUrl;
    }
    return result;
  }

  /**
   * Get reverse mappings (Knowledge URL to original path)
   */
  public getReverseMappings(): Record<string, string> {
    const result: Record<string, string> = {};
    for (const [knowledgeUrl, originalPath] of this.reverseMappings.entries()) {
      result[knowledgeUrl] = originalPath;
    }
    return result;
  }

  /**
   * Load mappings from a JSON file
   */
  public loadMappings(mappingFile: string): void {
    try {
      const content = require('fs').readFileSync(mappingFile, 'utf8');
      const mappings = JSON.parse(content);
      
      for (const [originalPath, knowledgeUrl] of Object.entries(mappings)) {
        this.addMapping(originalPath, knowledgeUrl as string);
      }
    } catch (error) {
      throw new Error(`Failed to load mappings from ${mappingFile}: ${error}`);
    }
  }

  /**
   * Save mappings to a JSON file
   */
  public saveMappings(mappingFile: string): void {
    try {
      const mappings = this.getAllMappings();
      const content = JSON.stringify(mappings, null, 2);
      require('fs').writeFileSync(mappingFile, content, 'utf8');
    } catch (error) {
      throw new Error(`Failed to save mappings to ${mappingFile}: ${error}`);
    }
  }

  /**
   * Generate a mapping report
   */
  public generateMappingReport(): MappingReport {
    const mappings = this.getAllMappings();
    const totalMappings = Object.keys(mappings).length;
    
    // Analyze mapping patterns
    const extensions = new Map<string, number>();
    const directories = new Map<string, number>();
    
    for (const originalPath of Object.keys(mappings)) {
      // Count extensions
      const ext = path.extname(originalPath);
      extensions.set(ext, (extensions.get(ext) || 0) + 1);
      
      // Count directories
      const dir = path.dirname(originalPath);
      directories.set(dir, (directories.get(dir) || 0) + 1);
    }

    return {
      totalMappings,
      mappings,
      statistics: {
        extensionCounts: Object.fromEntries(extensions),
        directoryCounts: Object.fromEntries(directories)
      },
      generatedAt: new Date().toISOString()
    };
  }

  /**
   * Validate all mappings
   */
  public validateMappings(): MappingValidationResult {
    const issues: MappingIssue[] = [];
    const warnings: string[] = [];
    
    for (const [originalPath, knowledgeUrl] of this.mappings.entries()) {
      // Check if original path looks valid
      if (!originalPath || originalPath.trim() === '') {
        issues.push({
          type: 'empty_path',
          originalPath,
          knowledgeUrl,
          message: 'Original path is empty'
        });
      }
      
      // Check if Knowledge URL looks valid
      if (!knowledgeUrl || knowledgeUrl.trim() === '') {
        issues.push({
          type: 'empty_url',
          originalPath,
          knowledgeUrl,
          message: 'Knowledge URL is empty'
        });
      }
      
      // Check URL format
      if (knowledgeUrl && !this.isValidKnowledgeUrl(knowledgeUrl)) {
        issues.push({
          type: 'invalid_url',
          originalPath,
          knowledgeUrl,
          message: 'Knowledge URL format appears invalid'
        });
      }
      
      // Check for potential duplicates
      const duplicates = Array.from(this.mappings.entries())
        .filter(([path, url]) => url === knowledgeUrl && path !== originalPath);
      
      if (duplicates.length > 0) {
        warnings.push(`Multiple paths map to same URL ${knowledgeUrl}: ${originalPath}, ${duplicates.map(d => d[0]).join(', ')}`);
      }
    }

    return {
      isValid: issues.length === 0,
      issues,
      warnings,
      totalMappings: this.mappings.size
    };
  }

  /**
   * Find broken links in content
   */
  public findBrokenLinks(content: string, sourceFile: string): BrokenLink[] {
    const brokenLinks: BrokenLink[] = [];
    
    // Find all markdown links
    const linkRegex = /\[([^\]]+)\]\(([^)]+)\)/g;
    let match;
    
    while ((match = linkRegex.exec(content)) !== null) {
      const [fullMatch, text, href] = match;
      
      // Skip external links
      if (this.isExternalLink(href)) {
        continue;
      }
      
      // Skip anchor links
      if (href.startsWith('#')) {
        continue;
      }
      
      // Try to resolve the link
      const resolvedUrl = this.resolveLink(href, sourceFile);
      
      if (!resolvedUrl) {
        brokenLinks.push({
          text,
          href,
          sourceFile,
          position: match.index,
          reason: 'No mapping found for target file'
        });
      }
    }

    return brokenLinks;
  }

  /**
   * Suggest fixes for broken links
   */
  public suggestLinkFixes(brokenLink: BrokenLink): LinkFixSuggestion[] {
    const suggestions: LinkFixSuggestion[] = [];
    
    // Try fuzzy matching
    const fuzzyMatch = this.fuzzyMatch(brokenLink.href);
    if (fuzzyMatch) {
      suggestions.push({
        type: 'fuzzy_match',
        originalHref: brokenLink.href,
        suggestedHref: fuzzyMatch,
        confidence: this.calculateMatchConfidence(brokenLink.href, fuzzyMatch),
        description: 'Similar file found'
      });
    }
    
    // Try case-insensitive matching
    const caseInsensitiveMatch = this.caseInsensitiveMatch(brokenLink.href);
    if (caseInsensitiveMatch) {
      suggestions.push({
        type: 'case_mismatch',
        originalHref: brokenLink.href,
        suggestedHref: caseInsensitiveMatch,
        confidence: 0.9,
        description: 'Case mismatch detected'
      });
    }
    
    return suggestions;
  }

  /**
   * Normalize file path for consistent lookup
   */
  private normalizePath(filePath: string): string {
    return FileUtils.normalizePath(filePath).toLowerCase();
  }

  /**
   * Perform fuzzy matching to find similar paths
   */
  private fuzzyMatch(targetPath: string): string | null {
    const normalizedTarget = this.normalizePath(targetPath);
    let bestMatch: string | null = null;
    let bestScore = 0;
    
    for (const [originalPath, knowledgeUrl] of this.mappings.entries()) {
      const score = this.calculateSimilarity(normalizedTarget, originalPath);
      if (score > bestScore && score > 0.7) { // 70% similarity threshold
        bestScore = score;
        bestMatch = knowledgeUrl;
      }
    }
    
    return bestMatch;
  }

  /**
   * Perform case-insensitive matching
   */
  private caseInsensitiveMatch(targetPath: string): string | null {
    const normalizedTarget = this.normalizePath(targetPath);
    
    for (const [originalPath, knowledgeUrl] of this.mappings.entries()) {
      if (originalPath.toLowerCase() === normalizedTarget) {
        return knowledgeUrl;
      }
    }
    
    return null;
  }

  /**
   * Calculate similarity between two strings using Levenshtein distance
   */
  private calculateSimilarity(str1: string, str2: string): number {
    const matrix: number[][] = [];
    const len1 = str1.length;
    const len2 = str2.length;

    // Initialize matrix
    for (let i = 0; i <= len1; i++) {
      matrix[i] = [i];
    }
    for (let j = 0; j <= len2; j++) {
      matrix[0][j] = j;
    }

    // Fill matrix
    for (let i = 1; i <= len1; i++) {
      for (let j = 1; j <= len2; j++) {
        const cost = str1[i - 1] === str2[j - 1] ? 0 : 1;
        matrix[i][j] = Math.min(
          matrix[i - 1][j] + 1,      // deletion
          matrix[i][j - 1] + 1,      // insertion
          matrix[i - 1][j - 1] + cost // substitution
        );
      }
    }

    const maxLen = Math.max(len1, len2);
    return maxLen === 0 ? 1 : (maxLen - matrix[len1][len2]) / maxLen;
  }

  /**
   * Calculate match confidence
   */
  private calculateMatchConfidence(original: string, match: string): number {
    return this.calculateSimilarity(original.toLowerCase(), match.toLowerCase());
  }

  /**
   * Check if URL is external
   */
  private isExternalLink(url: string): boolean {
    try {
      const parsed = new URL(url);
      return parsed.protocol === 'http:' || parsed.protocol === 'https:';
    } catch {
      return false;
    }
  }

  /**
   * Validate Knowledge URL format
   */
  private isValidKnowledgeUrl(url: string): boolean {
    // Basic validation - in practice, this would check against Salesforce URL patterns
    return url.length > 0 && 
           !url.includes(' ') && 
           (url.startsWith('http') || url.startsWith('/'));
  }
}

// Type definitions

export interface MappingReport {
  totalMappings: number;
  mappings: Record<string, string>;
  statistics: {
    extensionCounts: Record<string, number>;
    directoryCounts: Record<string, number>;
  };
  generatedAt: string;
}

export interface MappingValidationResult {
  isValid: boolean;
  issues: MappingIssue[];
  warnings: string[];
  totalMappings: number;
}

export interface MappingIssue {
  type: 'empty_path' | 'empty_url' | 'invalid_url' | 'duplicate_mapping';
  originalPath: string;
  knowledgeUrl: string;
  message: string;
}

export interface BrokenLink {
  text: string;
  href: string;
  sourceFile: string;
  position: number;
  reason: string;
}

export interface LinkFixSuggestion {
  type: 'fuzzy_match' | 'case_mismatch' | 'extension_change';
  originalHref: string;
  suggestedHref: string;
  confidence: number;
  description: string;
}