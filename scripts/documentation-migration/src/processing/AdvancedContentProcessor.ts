/**
 * Advanced content processing features for enhanced Salesforce Knowledge Base compatibility
 */

import * as fs from 'fs';
import * as path from 'path';
import { ContentProcessor } from '../core/ContentProcessor';
import { LinkMapper } from '../core/LinkMapper';

export class AdvancedContentProcessor extends ContentProcessor {
  private syntaxHighlighter: SyntaxHighlighter;
  private tableOptimizer: TableOptimizer;
  private imageProcessor: ImageProcessor;
  private diagramConverter: DiagramConverter;
  private contentValidator: ContentValidator;

  constructor(config: any, linkMapper?: LinkMapper) {
    super(config, linkMapper);
    
    this.syntaxHighlighter = new SyntaxHighlighter(config.syntaxHighlighting || {});
    this.tableOptimizer = new TableOptimizer(config.tableOptimization || {});
    this.imageProcessor = new ImageProcessor(config.imageProcessing || {});
    this.diagramConverter = new DiagramConverter(config.diagramConversion || {});
    this.contentValidator = new ContentValidator(config.contentValidation || {});
  }

  /**
   * Process content with advanced features
   */
  public async processAdvancedContent(content: string, sourceFile: string): Promise<AdvancedProcessingResult> {
    const result: AdvancedProcessingResult = {
      processedContent: content,
      warnings: [],
      optimizations: [],
      validationIssues: [],
      metadata: {
        codeBlocks: 0,
        tables: 0,
        images: 0,
        diagrams: 0,
        processingTime: 0
      }
    };

    const startTime = Date.now();

    try {
      // Step 1: Validate content quality
      const validationResult = await this.contentValidator.validateContent(content, sourceFile);
      result.validationIssues = validationResult.issues;
      result.warnings.push(...validationResult.warnings);

      // Step 2: Process code blocks with syntax highlighting
      const codeProcessingResult = await this.syntaxHighlighter.processCodeBlocks(content);
      result.processedContent = codeProcessingResult.content;
      result.metadata.codeBlocks = codeProcessingResult.codeBlockCount;
      result.optimizations.push(...codeProcessingResult.optimizations);

      // Step 3: Optimize tables for Salesforce display
      const tableProcessingResult = await this.tableOptimizer.optimizeTables(result.processedContent);
      result.processedContent = tableProcessingResult.content;
      result.metadata.tables = tableProcessingResult.tableCount;
      result.optimizations.push(...tableProcessingResult.optimizations);

      // Step 4: Process and optimize images
      const imageProcessingResult = await this.imageProcessor.processImages(result.processedContent, sourceFile);
      result.processedContent = imageProcessingResult.content;
      result.metadata.images = imageProcessingResult.imageCount;
      result.optimizations.push(...imageProcessingResult.optimizations);
      result.warnings.push(...imageProcessingResult.warnings);

      // Step 5: Convert Mermaid diagrams
      const diagramProcessingResult = await this.diagramConverter.convertDiagrams(result.processedContent, sourceFile);
      result.processedContent = diagramProcessingResult.content;
      result.metadata.diagrams = diagramProcessingResult.diagramCount;
      result.optimizations.push(...diagramProcessingResult.optimizations);
      result.warnings.push(...diagramProcessingResult.warnings);

      result.metadata.processingTime = Date.now() - startTime;

    } catch (error) {
      result.warnings.push(`Advanced processing failed: ${error instanceof Error ? error.message : String(error)}`);
    }

    return result;
  }
}