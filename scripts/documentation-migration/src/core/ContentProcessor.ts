/**
 * Content processing and conversion system for markdown to HTML
 */

import MarkdownIt from 'markdown-it';
import { ContentProcessingOptions } from '../types';

export class ContentProcessor {
  private markdownIt: MarkdownIt;
  private options: ContentProcessingOptions;
  private linkMapper?: LinkMapper;

  constructor(options: ContentProcessingOptions, linkMapper?: LinkMapper) {
    this.options = options;
    this.linkMapper = linkMapper;
    
    // Configure markdown-it with Salesforce-optimized settings
    this.markdownIt = new MarkdownIt({
      html: true,
      linkify: true,
      typographer: true,
      breaks: false
    });

    // Configure plugins and customizations
    this.configureMarkdownIt();
  }

  /**
   * Process markdown content and convert to HTML
   */
  public async processContent(markdown: string, sourceFile: string): Promise<ProcessedContent> {
    try {
      // Remove frontmatter if present
      const contentWithoutFrontmatter = this.removeFrontmatter(markdown);
      
      // Pre-process content
      const preprocessed = await this.preprocessContent(contentWithoutFrontmatter, sourceFile);
      
      // Convert to HTML
      const html = this.markdownIt.render(preprocessed);
      
      // Post-process HTML
      const postprocessed = await this.postprocessHtml(html, sourceFile);
      
      // Apply Salesforce-specific formatting
      const salesforceFormatted = this.applySalesforceFormatting(postprocessed);
      
      // Extract processing metadata
      const metadata = this.extractProcessingMetadata(markdown, salesforceFormatted);
      
      return {
        html: salesforceFormatted,
        originalMarkdown: markdown,
        processedMarkdown: preprocessed,
        metadata,
        warnings: metadata.warnings || []
      };
    } catch (error) {
      throw new ContentProcessingError(`Failed to process content from ${sourceFile}: ${error}`);
    }
  }

  /**
   * Process internal links to Knowledge article references
   */
  public processInternalLinks(html: string, sourceFile: string): string {
    if (this.options.linkProcessing === 'preserve') {
      return html;
    }

    // Pattern to match markdown-style links
    const linkPattern = /<a\s+href="([^"]+)"[^>]*>([^<]+)<\/a>/gi;
    
    return html.replace(linkPattern, (match, href, text) => {
      // Skip external links
      if (this.isExternalLink(href)) {
        return match;
      }

      // Skip anchor links
      if (href.startsWith('#')) {
        return match;
      }

      // Process internal documentation links
      if (this.isInternalDocLink(href)) {
        const knowledgeUrl = this.convertToKnowledgeUrl(href, sourceFile);
        if (knowledgeUrl) {
          return `<a href="${knowledgeUrl}" target="_blank">${text}</a>`;
        }
      }

      // Return original if no conversion possible
      return match;
    });
  }

  /**
   * Configure markdown-it with custom rules and plugins
   */
  private configureMarkdownIt(): void {
    // Custom renderer for code blocks
    this.markdownIt.renderer.rules.code_block = (tokens, idx) => {
      const token = tokens[idx];
      const langClass = token.info ? ` class="language-${token.info}"` : '';
      return `<pre${langClass}><code>${this.escapeHtml(token.content)}</code></pre>\n`;
    };

    // Custom renderer for fenced code blocks
    this.markdownIt.renderer.rules.fence = (tokens, idx) => {
      const token = tokens[idx];
      const langClass = token.info ? ` class="language-${token.info}"` : '';
      const langLabel = token.info ? `<div class="code-language">${token.info}</div>` : '';
      
      if (this.options.codeBlockStyling === 'salesforce') {
        return `<div class="slds-box slds-theme_shade slds-m-bottom_small">
          ${langLabel}
          <pre${langClass}><code>${this.escapeHtml(token.content)}</code></pre>
        </div>\n`;
      }
      
      return `<pre${langClass}><code>${this.escapeHtml(token.content)}</code></pre>\n`;
    };

    // Custom renderer for tables
    this.markdownIt.renderer.rules.table_open = () => {
      if (this.options.codeBlockStyling === 'salesforce') {
        return '<table class="slds-table slds-table_cell-buffer slds-table_bordered">\n';
      }
      return '<table>\n';
    };

    // Custom renderer for table headers
    this.markdownIt.renderer.rules.th_open = () => {
      if (this.options.codeBlockStyling === 'salesforce') {
        return '<th class="slds-text-title_caps" scope="col">';
      }
      return '<th>';
    };

    // Custom renderer for table cells
    this.markdownIt.renderer.rules.td_open = () => {
      if (this.options.codeBlockStyling === 'salesforce') {
        return '<td class="slds-cell-wrap">';
      }
      return '<td>';
    };

    // Custom renderer for blockquotes
    this.markdownIt.renderer.rules.blockquote_open = () => {
      if (this.options.codeBlockStyling === 'salesforce') {
        return '<blockquote class="slds-box slds-box_small slds-theme_shade slds-m-bottom_small">\n';
      }
      return '<blockquote>\n';
    };
  }

  /**
   * Remove frontmatter from content
   */
  private removeFrontmatter(content: string): string {
    const frontmatterRegex = /^---\s*\n[\s\S]*?\n---\s*\n/;
    return content.replace(frontmatterRegex, '');
  }

  /**
   * Pre-process content before markdown conversion
   */
  private async preprocessContent(content: string, sourceFile: string): Promise<string> {
    let processed = content;

    // Handle images based on configuration
    processed = await this.processImages(processed, sourceFile);

    // Process includes or references
    processed = this.processIncludes(processed, sourceFile);

    // Clean up problematic markdown patterns
    processed = this.cleanupMarkdown(processed);

    return processed;
  }

  /**
   * Process images according to configuration
   */
  private async processImages(content: string, sourceFile: string): Promise<string> {
    const imagePattern = /!\[([^\]]*)\]\(([^)]+)\)/g;

    if (this.options.imageHandling === 'skip') {
      return content.replace(imagePattern, '');
    }

    if (this.options.imageHandling === 'link') {
      // Convert to regular links
      return content.replace(imagePattern, '[$1]($2)');
    }

    if (this.options.imageHandling === 'embed') {
      // This would require actual file reading and base64 encoding
      // For now, we'll convert to links with a note
      return content.replace(imagePattern, (match, alt, src) => {
        if (this.isExternalLink(src)) {
          return match; // Keep external images as-is
        }
        return `[Image: ${alt || 'Embedded image'}](${src}) *(Image will be embedded in final version)*`;
      });
    }

    return content;
  }

  /**
   * Process include statements or file references
   */
  private processIncludes(content: string, sourceFile: string): string {
    // Handle common include patterns
    const includePatterns = [
      /\{\{include\s+([^}]+)\}\}/g,
      /\[\[include:([^\]]+)\]\]/g,
      /@include\s+(.+)/g
    ];

    let processed = content;
    
    for (const pattern of includePatterns) {
      processed = processed.replace(pattern, (match, includePath) => {
        // For now, replace with a placeholder
        // In a full implementation, this would read and include the referenced file
        return `\n> **Note:** This section includes content from \`${includePath.trim()}\`\n`;
      });
    }

    return processed;
  }

  /**
   * Clean up problematic markdown patterns
   */
  private cleanupMarkdown(content: string): string {
    let cleaned = content;

    // Fix common markdown issues
    cleaned = cleaned
      // Fix multiple consecutive blank lines
      .replace(/\n{4,}/g, '\n\n\n')
      // Fix spaces before headers
      .replace(/^ +#/gm, '#')
      // Fix list item spacing
      .replace(/^(\s*[-*+])\s{2,}/gm, '$1 ')
      // Fix numbered list spacing
      .replace(/^(\s*\d+\.)\s{2,}/gm, '$1 ')
      // Remove trailing whitespace
      .replace(/[ \t]+$/gm, '');

    return cleaned;
  }

  /**
   * Post-process HTML after markdown conversion
   */
  private async postprocessHtml(html: string, sourceFile: string): Promise<string> {
    let processed = html;

    // Process internal links
    processed = this.processInternalLinks(processed, sourceFile);

    // Add accessibility attributes
    processed = this.addAccessibilityAttributes(processed);

    // Sanitize HTML for Salesforce
    processed = this.sanitizeForSalesforce(processed);

    return processed;
  }

  /**
   * Add accessibility attributes to HTML elements
   */
  private addAccessibilityAttributes(html: string): string {
    let processed = html;

    // Add alt attributes to images that don't have them
    processed = processed.replace(/<img([^>]*?)(?<!alt="[^"]*")>/gi, (match, attrs) => {
      if (!attrs.includes('alt=')) {
        return `<img${attrs} alt="Image">`;
      }
      return match;
    });

    // Add scope attributes to table headers
    processed = processed.replace(/<th(?![^>]*scope=)/gi, '<th scope="col"');

    // Ensure links have proper attributes for external links
    processed = processed.replace(/<a\s+href="(https?:\/\/[^"]+)"([^>]*)>/gi, (match, href, attrs) => {
      if (!attrs.includes('target=')) {
        attrs += ' target="_blank"';
      }
      if (!attrs.includes('rel=')) {
        attrs += ' rel="noopener noreferrer"';
      }
      return `<a href="${href}"${attrs}>`;
    });

    return processed;
  }

  /**
   * Sanitize HTML for Salesforce compatibility
   */
  private sanitizeForSalesforce(html: string): string {
    let sanitized = html;

    // Remove potentially problematic attributes
    const dangerousAttrs = ['onclick', 'onload', 'onerror', 'onmouseover', 'onfocus'];
    for (const attr of dangerousAttrs) {
      const regex = new RegExp(`\\s${attr}="[^"]*"`, 'gi');
      sanitized = sanitized.replace(regex, '');
    }

    // Remove script tags
    sanitized = sanitized.replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, '');

    // Remove style tags (inline styles are okay)
    sanitized = sanitized.replace(/<style\b[^<]*(?:(?!<\/style>)<[^<]*)*<\/style>/gi, '');

    // Limit allowed HTML tags (Salesforce Knowledge has restrictions)
    // This is a simplified approach - in production, you'd use a proper HTML sanitizer
    const allowedTags = [
      'p', 'br', 'strong', 'b', 'em', 'i', 'u', 'strike', 'del',
      'h1', 'h2', 'h3', 'h4', 'h5', 'h6',
      'ul', 'ol', 'li',
      'table', 'thead', 'tbody', 'tr', 'th', 'td',
      'a', 'img',
      'blockquote', 'pre', 'code',
      'div', 'span'
    ];

    // This is a basic implementation - in production, use a library like DOMPurify
    return sanitized;
  }

  /**
   * Apply Salesforce-specific formatting
   */
  private applySalesforceFormatting(html: string): string {
    if (this.options.codeBlockStyling !== 'salesforce') {
      return html;
    }

    let formatted = html;

    // Add Salesforce Lightning Design System classes
    formatted = formatted
      // Style paragraphs
      .replace(/<p>/g, '<p class="slds-m-bottom_small">')
      // Style headings
      .replace(/<h1>/g, '<h1 class="slds-text-heading_large slds-m-bottom_medium">')
      .replace(/<h2>/g, '<h2 class="slds-text-heading_medium slds-m-bottom_small">')
      .replace(/<h3>/g, '<h3 class="slds-text-heading_small slds-m-bottom_small">')
      // Style lists
      .replace(/<ul>/g, '<ul class="slds-list_dotted slds-m-bottom_small">')
      .replace(/<ol>/g, '<ol class="slds-list_ordered slds-m-bottom_small">')
      // Style strong/bold text
      .replace(/<strong>/g, '<strong class="slds-text-body_regular">')
      .replace(/<b>/g, '<b class="slds-text-body_regular">');

    return formatted;
  }

  /**
   * Extract processing metadata
   */
  private extractProcessingMetadata(originalMarkdown: string, processedHtml: string): ProcessingMetadata {
    const warnings: string[] = [];
    
    // Count various elements
    const imageCount = (originalMarkdown.match(/!\[([^\]]*)\]\(([^)]+)\)/g) || []).length;
    const linkCount = (originalMarkdown.match(/\[([^\]]+)\]\(([^)]+)\)/g) || []).length;
    const codeBlockCount = (originalMarkdown.match(/```[\s\S]*?```/g) || []).length;
    const tableCount = (originalMarkdown.match(/\|.*\|/g) || []).length;
    
    // Check for potential issues
    if (imageCount > 10) {
      warnings.push(`High number of images (${imageCount}) may affect performance`);
    }
    
    if (processedHtml.length > 100000) {
      warnings.push('Very large HTML content may hit Salesforce field limits');
    }
    
    if (originalMarkdown.includes('```mermaid')) {
      warnings.push('Mermaid diagrams detected - may need manual conversion');
    }

    return {
      originalLength: originalMarkdown.length,
      processedLength: processedHtml.length,
      imageCount,
      linkCount,
      codeBlockCount,
      tableCount,
      warnings,
      processingTime: Date.now() // This would be calculated properly in real implementation
    };
  }

  /**
   * Check if a URL is external
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
   * Check if a link is an internal documentation link
   */
  private isInternalDocLink(href: string): boolean {
    // Check for common documentation file patterns
    return href.endsWith('.md') || 
           href.includes('/docs/') || 
           href.startsWith('../') ||
           href.startsWith('./');
  }

  /**
   * Convert internal doc link to Knowledge article URL
   */
  private convertToKnowledgeUrl(href: string, sourceFile: string): string | null {
    if (!this.linkMapper) {
      return null;
    }

    // This would use the LinkMapper to resolve the target file and get its Knowledge URL
    return this.linkMapper.resolveLink(href, sourceFile);
  }

  /**
   * Escape HTML special characters
   */
  private escapeHtml(text: string): string {
    const htmlEscapes: Record<string, string> = {
      '&': '&amp;',
      '<': '&lt;',
      '>': '&gt;',
      '"': '&quot;',
      "'": '&#39;'
    };
    
    return text.replace(/[&<>"']/g, (match) => htmlEscapes[match]);
  }
}

/**
 * Link mapper interface for resolving internal links
 */
export interface LinkMapper {
  resolveLink(href: string, sourceFile: string): string | null;
  addMapping(originalPath: string, knowledgeUrl: string): void;
  getAllMappings(): Record<string, string>;
}

/**
 * Content processing error
 */
export class ContentProcessingError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'ContentProcessingError';
  }
}

/**
 * Processed content result
 */
export interface ProcessedContent {
  html: string;
  originalMarkdown: string;
  processedMarkdown: string;
  metadata: ProcessingMetadata;
  warnings: string[];
}

/**
 * Processing metadata
 */
export interface ProcessingMetadata {
  originalLength: number;
  processedLength: number;
  imageCount: number;
  linkCount: number;
  codeBlockCount: number;
  tableCount: number;
  warnings: string[];
  processingTime: number;
}