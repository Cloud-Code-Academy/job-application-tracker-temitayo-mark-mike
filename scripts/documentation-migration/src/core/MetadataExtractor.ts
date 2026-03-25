/**
 * Metadata extraction and inference engine for documentation files
 */

import * as yaml from 'yaml';
import { FileMetadata } from '../types';

export class MetadataExtractor {
  private readonly WORDS_PER_MINUTE = 200; // Average reading speed
  private readonly DIFFICULTY_KEYWORDS = {
    beginner: ['introduction', 'getting started', 'basics', 'overview', 'simple', 'easy', 'tutorial', 'guide', 'first steps'],
    intermediate: ['implementation', 'configuration', 'setup', 'workflow', 'process', 'development', 'integration'],
    advanced: ['architecture', 'optimization', 'performance', 'security', 'debugging', 'troubleshooting', 'complex'],
    expert: ['internals', 'deep dive', 'advanced patterns', 'expert level', 'mastery', 'sophisticated']
  };

  private readonly TAG_KEYWORDS = {
    'Apex': ['apex', 'trigger', 'class', 'soql', 'dml', 'governor limits'],
    'Lightning Web Components': ['lwc', 'lightning', 'component', 'javascript', 'html', 'css'],
    'Testing': ['test', 'unit test', 'integration test', 'mock', 'assert', 'coverage'],
    'Architecture': ['architecture', 'design', 'pattern', 'structure', 'system', 'adr'],
    'Security': ['security', 'permission', 'sharing', 'authentication', 'authorization', 'encryption'],
    'Integration': ['api', 'rest', 'soap', 'callout', 'webhook', 'external', 'integration'],
    'Deployment': ['deployment', 'ci/cd', 'pipeline', 'release', 'environment', 'devops'],
    'Team Collaboration': ['team', 'collaboration', 'workflow', 'process', 'review', 'git'],
    'Learning Path': ['learning', 'tutorial', 'guide', 'course', 'training', 'education'],
    'Best Practices': ['best practice', 'convention', 'standard', 'guideline', 'recommendation'],
    'Debugging': ['debug', 'troubleshoot', 'error', 'issue', 'problem', 'fix'],
    'Performance': ['performance', 'optimization', 'speed', 'efficiency', 'scalability', 'benchmark']
  };

  /**
   * Extract frontmatter from markdown content
   */
  public extractFrontmatter(content: string): FrontmatterResult {
    const frontmatterRegex = /^---\s*\n([\s\S]*?)\n---\s*\n/;
    const match = content.match(frontmatterRegex);
    
    if (!match) {
      return {
        frontmatter: {},
        content: content,
        hasFrontmatter: false
      };
    }

    try {
      const frontmatterYaml = match[1];
      const frontmatter = yaml.parse(frontmatterYaml) || {};
      const contentWithoutFrontmatter = content.substring(match[0].length);
      
      return {
        frontmatter,
        content: contentWithoutFrontmatter,
        hasFrontmatter: true
      };
    } catch (error) {
      // If YAML parsing fails, treat as no frontmatter
      return {
        frontmatter: {},
        content: content,
        hasFrontmatter: false,
        parseError: `Failed to parse frontmatter: ${error}`
      };
    }
  }

  /**
   * Infer metadata from filename and content
   */
  public inferMetadata(filePath: string, content: string): InferredMetadata {
    const { frontmatter, content: contentWithoutFrontmatter } = this.extractFrontmatter(content);
    
    // Extract title
    const title = this.extractTitle(frontmatter, contentWithoutFrontmatter, filePath);
    
    // Extract summary
    const summary = this.extractSummary(frontmatter, contentWithoutFrontmatter);
    
    // Calculate reading time
    const readingTime = this.calculateReadingTime(contentWithoutFrontmatter);
    
    // Extract tags
    const tags = this.extractTags(frontmatter, contentWithoutFrontmatter, filePath);
    
    // Infer difficulty
    const difficulty = this.inferDifficulty(frontmatter, contentWithoutFrontmatter, filePath);
    
    // Extract prerequisites
    const prerequisites = this.extractPrerequisites(frontmatter, contentWithoutFrontmatter);
    
    // Extract author information
    const author = this.extractAuthor(frontmatter);
    
    // Extract dates
    const dates = this.extractDates(frontmatter);
    
    return {
      title,
      summary,
      readingTime,
      tags,
      difficulty,
      prerequisites,
      author,
      ...dates,
      frontmatter,
      wordCount: this.countWords(contentWithoutFrontmatter),
      headingCount: this.countHeadings(contentWithoutFrontmatter),
      codeBlockCount: this.countCodeBlocks(contentWithoutFrontmatter),
      linkCount: this.countLinks(contentWithoutFrontmatter)
    };
  }

  /**
   * Extract title from various sources
   */
  private extractTitle(frontmatter: any, content: string, filePath: string): string {
    // Priority: frontmatter title > first heading > filename
    
    // Check frontmatter
    if (frontmatter.title && typeof frontmatter.title === 'string') {
      return frontmatter.title.trim();
    }
    
    // Check first heading
    const headingMatch = content.match(/^#\s+(.+)$/m);
    if (headingMatch) {
      return headingMatch[1].trim();
    }
    
    // Generate from filename
    const filename = filePath.split('/').pop()?.replace(/\.md$/, '') || 'Untitled';
    return this.fileNameToTitle(filename);
  }

  /**
   * Extract summary from frontmatter or content
   */
  private extractSummary(frontmatter: any, content: string): string | undefined {
    // Check frontmatter
    if (frontmatter.summary && typeof frontmatter.summary === 'string') {
      return frontmatter.summary.trim();
    }
    
    if (frontmatter.description && typeof frontmatter.description === 'string') {
      return frontmatter.description.trim();
    }
    
    // Extract from content - look for first paragraph after title
    const lines = content.split('\n');
    let foundTitle = false;
    
    for (const line of lines) {
      const trimmed = line.trim();
      
      // Skip empty lines
      if (!trimmed) continue;
      
      // Skip title
      if (trimmed.startsWith('#')) {
        foundTitle = true;
        continue;
      }
      
      // If we found a title and this is a substantial paragraph, use it
      if (foundTitle && trimmed.length > 50 && !trimmed.startsWith('```')) {
        return trimmed.substring(0, 200) + (trimmed.length > 200 ? '...' : '');
      }
    }
    
    return undefined;
  }

  /**
   * Calculate reading time based on word count
   */
  public calculateReadingTime(content: string): number {
    const wordCount = this.countWords(content);
    return Math.max(1, Math.ceil(wordCount / this.WORDS_PER_MINUTE));
  }

  /**
   * Extract and generate tags from content
   */
  public extractTags(frontmatter: any, content: string, filePath: string): string[] {
    const tags = new Set<string>();
    
    // Add tags from frontmatter
    if (frontmatter.tags && Array.isArray(frontmatter.tags)) {
      frontmatter.tags.forEach((tag: any) => {
        if (typeof tag === 'string') {
          tags.add(tag.trim());
        }
      });
    }
    
    // Add keywords from frontmatter
    if (frontmatter.keywords && Array.isArray(frontmatter.keywords)) {
      frontmatter.keywords.forEach((keyword: any) => {
        if (typeof keyword === 'string') {
          tags.add(keyword.trim());
        }
      });
    }
    
    // Infer tags from content and filename
    const textToAnalyze = (content + ' ' + filePath).toLowerCase();
    
    for (const [tag, keywords] of Object.entries(this.TAG_KEYWORDS)) {
      for (const keyword of keywords) {
        if (textToAnalyze.includes(keyword.toLowerCase())) {
          tags.add(tag);
          break; // Only add the tag once per category
        }
      }
    }
    
    // Add tags based on file structure
    const pathTags = this.inferTagsFromPath(filePath);
    pathTags.forEach(tag => tags.add(tag));
    
    return Array.from(tags).slice(0, 10); // Limit to 10 tags
  }

  /**
   * Infer difficulty level from content
   */
  private inferDifficulty(frontmatter: any, content: string, filePath: string): 'Beginner' | 'Intermediate' | 'Advanced' | 'Expert' {
    // Check frontmatter first
    if (frontmatter.difficulty && typeof frontmatter.difficulty === 'string') {
      const normalized = frontmatter.difficulty.toLowerCase();
      if (['beginner', 'intermediate', 'advanced', 'expert'].includes(normalized)) {
        return normalized.charAt(0).toUpperCase() + normalized.slice(1) as any;
      }
    }
    
    // Analyze content
    const textToAnalyze = (content + ' ' + filePath).toLowerCase();
    const scores = {
      beginner: 0,
      intermediate: 0,
      advanced: 0,
      expert: 0
    };
    
    // Score based on keyword presence
    for (const [level, keywords] of Object.entries(this.DIFFICULTY_KEYWORDS)) {
      for (const keyword of keywords) {
        const regex = new RegExp(`\\b${keyword}\\b`, 'gi');
        const matches = textToAnalyze.match(regex);
        if (matches) {
          scores[level as keyof typeof scores] += matches.length;
        }
      }
    }
    
    // Additional scoring based on content complexity
    const codeBlockCount = this.countCodeBlocks(content);
    const headingDepth = this.getMaxHeadingDepth(content);
    const wordCount = this.countWords(content);
    
    // Adjust scores based on complexity indicators
    if (codeBlockCount > 5) scores.advanced += 2;
    if (headingDepth > 4) scores.intermediate += 1;
    if (wordCount > 2000) scores.advanced += 1;
    if (wordCount < 500) scores.beginner += 1;
    
    // Find the highest scoring difficulty
    const maxScore = Math.max(...Object.values(scores));
    if (maxScore === 0) return 'Intermediate'; // Default
    
    const topLevel = Object.entries(scores).find(([_, score]) => score === maxScore)?.[0];
    return (topLevel?.charAt(0).toUpperCase() + topLevel?.slice(1)) as any || 'Intermediate';
  }

  /**
   * Extract prerequisites from content
   */
  private extractPrerequisites(frontmatter: any, content: string): string | undefined {
    // Check frontmatter
    if (frontmatter.prerequisites && typeof frontmatter.prerequisites === 'string') {
      return frontmatter.prerequisites.trim();
    }
    
    if (frontmatter.requires && typeof frontmatter.requires === 'string') {
      return frontmatter.requires.trim();
    }
    
    // Look for prerequisites section in content
    const prerequisitesRegex = /(?:^|\n)#+\s*(?:prerequisites?|requirements?|before you begin)\s*\n([\s\S]*?)(?=\n#+|\n\n|$)/i;
    const match = content.match(prerequisitesRegex);
    
    if (match) {
      const prereqText = match[1].trim();
      // Clean up markdown formatting
      return prereqText
        .replace(/^\s*[-*+]\s*/gm, '') // Remove list markers
        .replace(/\n+/g, ' ') // Collapse newlines
        .substring(0, 500); // Limit length
    }
    
    return undefined;
  }

  /**
   * Extract author information
   */
  private extractAuthor(frontmatter: any): string | undefined {
    if (frontmatter.author && typeof frontmatter.author === 'string') {
      return frontmatter.author.trim();
    }
    
    if (frontmatter.authors && Array.isArray(frontmatter.authors)) {
      return frontmatter.authors.join(', ');
    }
    
    return undefined;
  }

  /**
   * Extract date information
   */
  private extractDates(frontmatter: any): { createdDate?: string; updatedDate?: string } {
    const result: { createdDate?: string; updatedDate?: string } = {};
    
    // Created date
    if (frontmatter.date) {
      result.createdDate = this.normalizeDate(frontmatter.date);
    } else if (frontmatter.created) {
      result.createdDate = this.normalizeDate(frontmatter.created);
    }
    
    // Updated date
    if (frontmatter.updated) {
      result.updatedDate = this.normalizeDate(frontmatter.updated);
    } else if (frontmatter.modified) {
      result.updatedDate = this.normalizeDate(frontmatter.modified);
    }
    
    return result;
  }

  /**
   * Normalize date to ISO string
   */
  private normalizeDate(dateValue: any): string | undefined {
    if (!dateValue) return undefined;
    
    try {
      const date = new Date(dateValue);
      if (isNaN(date.getTime())) return undefined;
      return date.toISOString();
    } catch {
      return undefined;
    }
  }

  /**
   * Convert filename to title
   */
  private fileNameToTitle(filename: string): string {
    return filename
      .replace(/[-_]/g, ' ')
      .replace(/\b\w/g, l => l.toUpperCase())
      .trim();
  }

  /**
   * Infer tags from file path
   */
  private inferTagsFromPath(filePath: string): string[] {
    const tags: string[] = [];
    const pathLower = filePath.toLowerCase();
    
    // Path-based tag inference
    if (pathLower.includes('/api/') || pathLower.includes('api-')) tags.push('API Documentation');
    if (pathLower.includes('/guide/') || pathLower.includes('guide-')) tags.push('Learning Path');
    if (pathLower.includes('/admin/') || pathLower.includes('admin-')) tags.push('Admin Guide');
    if (pathLower.includes('/dev/') || pathLower.includes('development')) tags.push('Development');
    if (pathLower.includes('/test/') || pathLower.includes('testing')) tags.push('Testing');
    
    return tags;
  }

  /**
   * Count words in content
   */
  private countWords(content: string): number {
    // Remove code blocks and inline code
    const cleanContent = content
      .replace(/```[\s\S]*?```/g, '') // Remove code blocks
      .replace(/`[^`]+`/g, '') // Remove inline code
      .replace(/\[([^\]]+)\]\([^)]+\)/g, '$1') // Replace links with text
      .replace(/[#*_~`]/g, ''); // Remove markdown formatting
    
    const words = cleanContent.trim().split(/\s+/).filter(word => word.length > 0);
    return words.length;
  }

  /**
   * Count headings in content
   */
  private countHeadings(content: string): number {
    const headingMatches = content.match(/^#+\s+.+$/gm);
    return headingMatches ? headingMatches.length : 0;
  }

  /**
   * Get maximum heading depth
   */
  private getMaxHeadingDepth(content: string): number {
    const headingMatches = content.match(/^(#+)\s+.+$/gm);
    if (!headingMatches) return 0;
    
    return Math.max(...headingMatches.map(match => {
      const hashCount = match.match(/^#+/)?.[0].length || 0;
      return hashCount;
    }));
  }

  /**
   * Count code blocks in content
   */
  private countCodeBlocks(content: string): number {
    const codeBlockMatches = content.match(/```[\s\S]*?```/g);
    const inlineCodeMatches = content.match(/`[^`]+`/g);
    
    return (codeBlockMatches?.length || 0) + (inlineCodeMatches?.length || 0);
  }

  /**
   * Count links in content
   */
  private countLinks(content: string): number {
    const linkMatches = content.match(/\[([^\]]+)\]\([^)]+\)/g);
    const urlMatches = content.match(/https?:\/\/[^\s]+/g);
    
    return (linkMatches?.length || 0) + (urlMatches?.length || 0);
  }

  /**
   * Validate extracted metadata
   */
  public validateMetadata(metadata: InferredMetadata): MetadataValidationResult {
    const issues: string[] = [];
    const warnings: string[] = [];
    
    // Title validation
    if (!metadata.title || metadata.title.trim().length === 0) {
      issues.push('Title is required');
    } else if (metadata.title.length > 255) {
      issues.push('Title is too long (max 255 characters)');
    }
    
    // Summary validation
    if (metadata.summary && metadata.summary.length > 1000) {
      warnings.push('Summary is very long (recommended max 1000 characters)');
    }
    
    // Tags validation
    if (metadata.tags.length === 0) {
      warnings.push('No tags found - consider adding tags for better categorization');
    } else if (metadata.tags.length > 10) {
      warnings.push('Too many tags (recommended max 10)');
    }
    
    // Reading time validation
    if (metadata.readingTime > 60) {
      warnings.push('Very long document (over 60 minutes reading time)');
    }
    
    // Prerequisites validation
    if (metadata.prerequisites && metadata.prerequisites.length > 1000) {
      warnings.push('Prerequisites text is very long');
    }
    
    return {
      isValid: issues.length === 0,
      issues,
      warnings
    };
  }
}

/**
 * Result of frontmatter extraction
 */
export interface FrontmatterResult {
  frontmatter: any;
  content: string;
  hasFrontmatter: boolean;
  parseError?: string;
}

/**
 * Inferred metadata from content analysis
 */
export interface InferredMetadata {
  title: string;
  summary?: string;
  readingTime: number;
  tags: string[];
  difficulty: 'Beginner' | 'Intermediate' | 'Advanced' | 'Expert';
  prerequisites?: string;
  author?: string;
  createdDate?: string;
  updatedDate?: string;
  frontmatter: any;
  wordCount: number;
  headingCount: number;
  codeBlockCount: number;
  linkCount: number;
}

/**
 * Metadata validation result
 */
export interface MetadataValidationResult {
  isValid: boolean;
  issues: string[];
  warnings: string[];
}