/**
 * Text analysis utilities for content processing and metadata extraction
 */

export class TextAnalyzer {
  
  /**
   * Extract keywords from text using frequency analysis
   */
  public static extractKeywords(text: string, maxKeywords: number = 10): KeywordResult[] {
    // Clean and normalize text
    const cleanText = this.cleanText(text);
    const words = this.tokenizeText(cleanText);
    
    // Filter out common stop words
    const filteredWords = this.removeStopWords(words);
    
    // Count word frequencies
    const wordFreq = this.calculateWordFrequency(filteredWords);
    
    // Calculate TF-IDF-like scores (simplified)
    const keywordScores = this.calculateKeywordScores(wordFreq, filteredWords.length);
    
    // Sort by score and return top keywords
    return keywordScores
      .sort((a, b) => b.score - a.score)
      .slice(0, maxKeywords);
  }

  /**
   * Analyze text complexity and readability
   */
  public static analyzeComplexity(text: string): ComplexityAnalysis {
    const sentences = this.splitIntoSentences(text);
    const words = this.tokenizeText(text);
    const syllables = this.countSyllables(text);
    
    // Calculate basic metrics
    const avgWordsPerSentence = words.length / Math.max(sentences.length, 1);
    const avgSyllablesPerWord = syllables / Math.max(words.length, 1);
    
    // Flesch Reading Ease Score
    const fleschScore = 206.835 - (1.015 * avgWordsPerSentence) - (84.6 * avgSyllablesPerWord);
    
    // Flesch-Kincaid Grade Level
    const gradeLevel = (0.39 * avgWordsPerSentence) + (11.8 * avgSyllablesPerWord) - 15.59;
    
    // Determine complexity level
    let complexityLevel: 'Simple' | 'Moderate' | 'Complex' | 'Very Complex';
    if (fleschScore >= 90) complexityLevel = 'Simple';
    else if (fleschScore >= 70) complexityLevel = 'Moderate';
    else if (fleschScore >= 50) complexityLevel = 'Complex';
    else complexityLevel = 'Very Complex';
    
    return {
      fleschScore: Math.round(fleschScore),
      gradeLevel: Math.round(gradeLevel * 10) / 10,
      complexityLevel,
      sentenceCount: sentences.length,
      wordCount: words.length,
      syllableCount: syllables,
      avgWordsPerSentence: Math.round(avgWordsPerSentence * 10) / 10,
      avgSyllablesPerWord: Math.round(avgSyllablesPerWord * 10) / 10
    };
  }

  /**
   * Extract technical terms and jargon
   */
  public static extractTechnicalTerms(text: string): TechnicalTerm[] {
    const terms: TechnicalTerm[] = [];
    
    // Common technical patterns
    const patterns = [
      // API endpoints
      { pattern: /\/api\/[a-zA-Z0-9\/\-_]+/g, category: 'API Endpoint' },
      // Class names (PascalCase)
      { pattern: /\b[A-Z][a-zA-Z0-9]*(?:[A-Z][a-zA-Z0-9]*)+\b/g, category: 'Class/Type' },
      // Method names (camelCase)
      { pattern: /\b[a-z][a-zA-Z0-9]*(?:[A-Z][a-zA-Z0-9]*)+\(/g, category: 'Method' },
      // Constants (UPPER_CASE)
      { pattern: /\b[A-Z][A-Z0-9_]+\b/g, category: 'Constant' },
      // File extensions
      { pattern: /\.[a-zA-Z0-9]+(?=\s|$|[^a-zA-Z0-9])/g, category: 'File Extension' },
      // URLs
      { pattern: /https?:\/\/[^\s]+/g, category: 'URL' },
      // Salesforce specific
      { pattern: /\b(?:SOQL|SOSL|DML|LWC|Apex|Visualforce|Lightning)\b/gi, category: 'Salesforce' }
    ];
    
    for (const { pattern, category } of patterns) {
      const matches = text.match(pattern);
      if (matches) {
        for (const match of matches) {
          const cleanMatch = match.replace(/[()]/g, '').trim();
          if (cleanMatch.length > 2) {
            terms.push({
              term: cleanMatch,
              category,
              frequency: (text.match(new RegExp(this.escapeRegex(cleanMatch), 'gi')) || []).length
            });
          }
        }
      }
    }
    
    // Remove duplicates and sort by frequency
    const uniqueTerms = terms.reduce((acc, term) => {
      const existing = acc.find(t => t.term.toLowerCase() === term.term.toLowerCase());
      if (existing) {
        existing.frequency += term.frequency;
      } else {
        acc.push(term);
      }
      return acc;
    }, [] as TechnicalTerm[]);
    
    return uniqueTerms.sort((a, b) => b.frequency - a.frequency);
  }

  /**
   * Detect document structure and outline
   */
  public static analyzeStructure(text: string): DocumentStructure {
    const headings = this.extractHeadings(text);
    const sections = this.extractSections(text);
    const lists = this.extractLists(text);
    const codeBlocks = this.extractCodeBlocks(text);
    const tables = this.extractTables(text);
    
    return {
      headings,
      sections,
      lists,
      codeBlocks,
      tables,
      hasTableOfContents: this.hasTableOfContents(text),
      estimatedReadingTime: this.estimateReadingTime(text),
      documentType: this.inferDocumentType(text, headings, codeBlocks)
    };
  }

  /**
   * Clean text for analysis
   */
  private static cleanText(text: string): string {
    return text
      .replace(/```[\s\S]*?```/g, '') // Remove code blocks
      .replace(/`[^`]+`/g, '') // Remove inline code
      .replace(/\[([^\]]+)\]\([^)]+\)/g, '$1') // Replace links with text
      .replace(/[#*_~]/g, '') // Remove markdown formatting
      .replace(/\s+/g, ' ') // Normalize whitespace
      .trim();
  }

  /**
   * Tokenize text into words
   */
  private static tokenizeText(text: string): string[] {
    return text
      .toLowerCase()
      .replace(/[^\w\s]/g, ' ')
      .split(/\s+/)
      .filter(word => word.length > 2);
  }

  /**
   * Remove common stop words
   */
  private static removeStopWords(words: string[]): string[] {
    const stopWords = new Set([
      'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for', 'of', 'with',
      'by', 'from', 'up', 'about', 'into', 'through', 'during', 'before', 'after',
      'above', 'below', 'between', 'among', 'is', 'are', 'was', 'were', 'be', 'been',
      'being', 'have', 'has', 'had', 'do', 'does', 'did', 'will', 'would', 'could',
      'should', 'may', 'might', 'must', 'can', 'this', 'that', 'these', 'those',
      'i', 'you', 'he', 'she', 'it', 'we', 'they', 'me', 'him', 'her', 'us', 'them'
    ]);
    
    return words.filter(word => !stopWords.has(word));
  }

  /**
   * Calculate word frequency
   */
  private static calculateWordFrequency(words: string[]): Map<string, number> {
    const freq = new Map<string, number>();
    
    for (const word of words) {
      freq.set(word, (freq.get(word) || 0) + 1);
    }
    
    return freq;
  }

  /**
   * Calculate keyword scores
   */
  private static calculateKeywordScores(wordFreq: Map<string, number>, totalWords: number): KeywordResult[] {
    const results: KeywordResult[] = [];
    
    for (const [word, frequency] of wordFreq.entries()) {
      // Simple TF score (could be enhanced with IDF)
      const tfScore = frequency / totalWords;
      
      // Boost score for longer words (often more meaningful)
      const lengthBoost = Math.min(word.length / 10, 1.5);
      
      // Boost score for technical-looking words
      const technicalBoost = /^[a-z]+[A-Z]/.test(word) ? 1.2 : 1.0;
      
      const score = tfScore * lengthBoost * technicalBoost;
      
      results.push({
        keyword: word,
        frequency,
        score: Math.round(score * 10000) / 10000
      });
    }
    
    return results;
  }

  /**
   * Split text into sentences
   */
  private static splitIntoSentences(text: string): string[] {
    return text
      .split(/[.!?]+/)
      .map(s => s.trim())
      .filter(s => s.length > 0);
  }

  /**
   * Count syllables in text (approximation)
   */
  private static countSyllables(text: string): number {
    const words = this.tokenizeText(text);
    let totalSyllables = 0;
    
    for (const word of words) {
      // Simple syllable counting heuristic
      const vowelGroups = word.match(/[aeiouy]+/gi);
      let syllables = vowelGroups ? vowelGroups.length : 1;
      
      // Adjust for silent 'e'
      if (word.endsWith('e') && syllables > 1) {
        syllables--;
      }
      
      // Minimum of 1 syllable per word
      totalSyllables += Math.max(syllables, 1);
    }
    
    return totalSyllables;
  }

  /**
   * Extract headings from markdown
   */
  private static extractHeadings(text: string): Heading[] {
    const headingRegex = /^(#{1,6})\s+(.+)$/gm;
    const headings: Heading[] = [];
    let match;
    
    while ((match = headingRegex.exec(text)) !== null) {
      headings.push({
        level: match[1].length,
        text: match[2].trim(),
        position: match.index
      });
    }
    
    return headings;
  }

  /**
   * Extract sections based on headings
   */
  private static extractSections(text: string): Section[] {
    const headings = this.extractHeadings(text);
    const sections: Section[] = [];
    
    for (let i = 0; i < headings.length; i++) {
      const heading = headings[i];
      const nextHeading = headings[i + 1];
      
      const startPos = heading.position;
      const endPos = nextHeading ? nextHeading.position : text.length;
      
      const content = text.substring(startPos, endPos).trim();
      const wordCount = this.tokenizeText(content).length;
      
      sections.push({
        title: heading.text,
        level: heading.level,
        content,
        wordCount,
        position: startPos
      });
    }
    
    return sections;
  }

  /**
   * Extract lists from markdown
   */
  private static extractLists(text: string): ListInfo[] {
    const lists: ListInfo[] = [];
    
    // Ordered lists
    const orderedListRegex = /^\s*\d+\.\s+.+$/gm;
    const orderedMatches = text.match(orderedListRegex);
    if (orderedMatches) {
      lists.push({
        type: 'ordered',
        itemCount: orderedMatches.length,
        items: orderedMatches.map(item => item.replace(/^\s*\d+\.\s+/, '').trim())
      });
    }
    
    // Unordered lists
    const unorderedListRegex = /^\s*[-*+]\s+.+$/gm;
    const unorderedMatches = text.match(unorderedListRegex);
    if (unorderedMatches) {
      lists.push({
        type: 'unordered',
        itemCount: unorderedMatches.length,
        items: unorderedMatches.map(item => item.replace(/^\s*[-*+]\s+/, '').trim())
      });
    }
    
    return lists;
  }

  /**
   * Extract code blocks
   */
  private static extractCodeBlocks(text: string): CodeBlockInfo[] {
    const codeBlocks: CodeBlockInfo[] = [];
    const codeBlockRegex = /```(\w+)?\n([\s\S]*?)```/g;
    let match;
    
    while ((match = codeBlockRegex.exec(text)) !== null) {
      codeBlocks.push({
        language: match[1] || 'text',
        code: match[2].trim(),
        lineCount: match[2].split('\n').length
      });
    }
    
    return codeBlocks;
  }

  /**
   * Extract tables
   */
  private static extractTables(text: string): TableInfo[] {
    const tables: TableInfo[] = [];
    const tableRegex = /\|(.+)\|\n\|[-\s|:]+\|\n((?:\|.+\|\n?)+)/g;
    let match;
    
    while ((match = tableRegex.exec(text)) !== null) {
      const headerRow = match[1].split('|').map(cell => cell.trim()).filter(cell => cell);
      const bodyRows = match[2].split('\n')
        .filter(row => row.trim())
        .map(row => row.split('|').map(cell => cell.trim()).filter(cell => cell));
      
      tables.push({
        columnCount: headerRow.length,
        rowCount: bodyRows.length,
        headers: headerRow,
        hasHeaders: true
      });
    }
    
    return tables;
  }

  /**
   * Check if document has table of contents
   */
  private static hasTableOfContents(text: string): boolean {
    const tocPatterns = [
      /table\s+of\s+contents/i,
      /contents/i,
      /^#+\s*(?:table\s+of\s+)?contents\s*$/im
    ];
    
    return tocPatterns.some(pattern => pattern.test(text));
  }

  /**
   * Estimate reading time
   */
  private static estimateReadingTime(text: string): number {
    const wordCount = this.tokenizeText(text).length;
    return Math.max(1, Math.ceil(wordCount / 200)); // 200 words per minute
  }

  /**
   * Infer document type
   */
  private static inferDocumentType(text: string, headings: Heading[], codeBlocks: CodeBlockInfo[]): string {
    const textLower = text.toLowerCase();
    
    if (textLower.includes('api') && textLower.includes('endpoint')) return 'API Documentation';
    if (textLower.includes('tutorial') || textLower.includes('step by step')) return 'Tutorial';
    if (textLower.includes('guide') && textLower.includes('how to')) return 'How-to Guide';
    if (codeBlocks.length > 5) return 'Technical Reference';
    if (headings.some(h => h.text.toLowerCase().includes('architecture'))) return 'Architecture Document';
    if (textLower.includes('requirements') || textLower.includes('specification')) return 'Specification';
    if (textLower.includes('troubleshoot') || textLower.includes('debug')) return 'Troubleshooting Guide';
    
    return 'General Documentation';
  }

  /**
   * Escape regex special characters
   */
  private static escapeRegex(text: string): string {
    return text.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  }
}

// Type definitions

export interface KeywordResult {
  keyword: string;
  frequency: number;
  score: number;
}

export interface ComplexityAnalysis {
  fleschScore: number;
  gradeLevel: number;
  complexityLevel: 'Simple' | 'Moderate' | 'Complex' | 'Very Complex';
  sentenceCount: number;
  wordCount: number;
  syllableCount: number;
  avgWordsPerSentence: number;
  avgSyllablesPerWord: number;
}

export interface TechnicalTerm {
  term: string;
  category: string;
  frequency: number;
}

export interface DocumentStructure {
  headings: Heading[];
  sections: Section[];
  lists: ListInfo[];
  codeBlocks: CodeBlockInfo[];
  tables: TableInfo[];
  hasTableOfContents: boolean;
  estimatedReadingTime: number;
  documentType: string;
}

export interface Heading {
  level: number;
  text: string;
  position: number;
}

export interface Section {
  title: string;
  level: number;
  content: string;
  wordCount: number;
  position: number;
}

export interface ListInfo {
  type: 'ordered' | 'unordered';
  itemCount: number;
  items: string[];
}

export interface CodeBlockInfo {
  language: string;
  code: string;
  lineCount: number;
}

export interface TableInfo {
  columnCount: number;
  rowCount: number;
  headers: string[];
  hasHeaders: boolean;
}