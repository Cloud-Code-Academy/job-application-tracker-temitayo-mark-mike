/**
 * Category mapping and classification system for automatic document categorization
 */

import { CategoryRule, FileMetadata } from '../types';
import { TextAnalyzer } from '../utils/TextAnalyzer';

export class CategoryMapper {
  private rules: CategoryRule[];
  private fallbackCategory: string;
  private fallbackSubcategory?: string;

  constructor(rules: CategoryRule[], fallbackCategory: string = 'User_Documentation', fallbackSubcategory?: string) {
    this.rules = rules;
    this.fallbackCategory = fallbackCategory;
    this.fallbackSubcategory = fallbackSubcategory;
  }

  /**
   * Map a document to appropriate categories based on rules and content analysis
   */
  public mapToCategory(filePath: string, metadata: FileMetadata, content: string): CategoryMappingResult {
    const analysisContext = this.createAnalysisContext(filePath, metadata, content);
    
    // Try rule-based mapping first
    const ruleBasedResult = this.applyRules(analysisContext);
    if (ruleBasedResult.matched) {
      return {
        category: ruleBasedResult.category,
        subcategory: ruleBasedResult.subcategory,
        confidence: ruleBasedResult.confidence,
        matchedRule: ruleBasedResult.rule,
        reasoning: ruleBasedResult.reasoning,
        alternatives: this.findAlternativeCategories(analysisContext, ruleBasedResult.category)
      };
    }

    // Fall back to content-based analysis
    const contentBasedResult = this.analyzeContentForCategory(analysisContext);
    if (contentBasedResult.category) {
      return {
        category: contentBasedResult.category,
        subcategory: contentBasedResult.subcategory,
        confidence: contentBasedResult.confidence,
        reasoning: contentBasedResult.reasoning,
        alternatives: this.findAlternativeCategories(analysisContext, contentBasedResult.category)
      };
    }

    // Use fallback category
    return {
      category: this.fallbackCategory,
      subcategory: this.fallbackSubcategory,
      confidence: 0.3,
      reasoning: 'No specific category rules matched, using fallback category',
      alternatives: this.findAlternativeCategories(analysisContext, this.fallbackCategory)
    };
  }

  /**
   * Infer difficulty level from content and metadata
   */
  public inferDifficulty(content: string, metadata: FileMetadata, filePath: string): DifficultyInference {
    const analysisContext = this.createAnalysisContext(filePath, metadata, content);
    
    // Check if difficulty is already set in metadata
    if (metadata.difficulty && metadata.difficulty !== 'Intermediate') {
      return {
        difficulty: metadata.difficulty,
        confidence: 0.9,
        reasoning: 'Difficulty explicitly set in document metadata'
      };
    }

    // Analyze content for difficulty indicators
    const contentAnalysis = this.analyzeDifficultyFromContent(content);
    const pathAnalysis = this.analyzeDifficultyFromPath(filePath);
    const structureAnalysis = this.analyzeDifficultyFromStructure(content);

    // Combine scores
    const combinedScores = this.combineDifficultyScores([
      contentAnalysis,
      pathAnalysis,
      structureAnalysis
    ]);

    const topDifficulty = this.getTopScoredDifficulty(combinedScores);

    return {
      difficulty: topDifficulty.difficulty,
      confidence: topDifficulty.confidence,
      reasoning: this.generateDifficultyReasoning(combinedScores, topDifficulty.difficulty),
      factors: {
        contentKeywords: contentAnalysis,
        pathIndicators: pathAnalysis,
        structureComplexity: structureAnalysis
      }
    };
  }

  /**
   * Validate category assignment against known categories
   */
  public validateCategory(category: string, subcategory?: string): CategoryValidationResult {
    const knownCategories = this.getKnownCategories();
    const issues: string[] = [];
    const warnings: string[] = [];

    // Check if category exists
    if (!knownCategories.has(category)) {
      issues.push(`Unknown category: ${category}`);
    } else {
      // Check subcategory if provided
      if (subcategory) {
        const validSubcategories = knownCategories.get(category) || [];
        if (!validSubcategories.includes(subcategory)) {
          warnings.push(`Subcategory '${subcategory}' may not exist under category '${category}'`);
        }
      }
    }

    // Check naming conventions
    if (!this.isValidCategoryName(category)) {
      issues.push(`Category name '${category}' doesn't follow naming conventions`);
    }

    if (subcategory && !this.isValidCategoryName(subcategory)) {
      issues.push(`Subcategory name '${subcategory}' doesn't follow naming conventions`);
    }

    return {
      isValid: issues.length === 0,
      issues,
      warnings,
      suggestions: this.suggestSimilarCategories(category, subcategory)
    };
  }

  /**
   * Generate category mapping report
   */
  public generateMappingReport(mappings: CategoryMappingResult[]): CategoryMappingReport {
    const categoryStats = new Map<string, number>();
    const subcategoryStats = new Map<string, number>();
    const confidenceDistribution = { high: 0, medium: 0, low: 0 };
    const ruleUsage = new Map<string, number>();

    for (const mapping of mappings) {
      // Count categories
      categoryStats.set(mapping.category, (categoryStats.get(mapping.category) || 0) + 1);
      
      if (mapping.subcategory) {
        const key = `${mapping.category}/${mapping.subcategory}`;
        subcategoryStats.set(key, (subcategoryStats.get(key) || 0) + 1);
      }

      // Count confidence levels
      if (mapping.confidence >= 0.8) confidenceDistribution.high++;
      else if (mapping.confidence >= 0.5) confidenceDistribution.medium++;
      else confidenceDistribution.low++;

      // Count rule usage
      if (mapping.matchedRule) {
        const ruleKey = mapping.matchedRule.pattern.source;
        ruleUsage.set(ruleKey, (ruleUsage.get(ruleKey) || 0) + 1);
      }
    }

    return {
      totalMappings: mappings.length,
      categoryDistribution: Object.fromEntries(categoryStats),
      subcategoryDistribution: Object.fromEntries(subcategoryStats),
      confidenceDistribution,
      ruleUsageStats: Object.fromEntries(ruleUsage),
      averageConfidence: mappings.reduce((sum, m) => sum + m.confidence, 0) / mappings.length,
      lowConfidenceMappings: mappings.filter(m => m.confidence < 0.5).length
    };
  }

  /**
   * Create analysis context from file information
   */
  private createAnalysisContext(filePath: string, metadata: FileMetadata, content: string): AnalysisContext {
    const structure = TextAnalyzer.analyzeStructure(content);
    const keywords = TextAnalyzer.extractKeywords(content, 20);
    const technicalTerms = TextAnalyzer.extractTechnicalTerms(content);

    return {
      filePath,
      fileName: filePath.split('/').pop() || '',
      metadata,
      content,
      structure,
      keywords: keywords.map(k => k.keyword),
      technicalTerms: technicalTerms.map(t => t.term),
      contentLength: content.length,
      wordCount: metadata.wordCount || 0
    };
  }

  /**
   * Apply categorization rules to determine category
   */
  private applyRules(context: AnalysisContext): RuleMatchResult {
    const textToAnalyze = `${context.filePath} ${context.content}`.toLowerCase();
    
    for (const rule of this.rules) {
      const matches = textToAnalyze.match(rule.pattern);
      if (matches) {
        const confidence = this.calculateRuleConfidence(rule, context, matches);
        
        return {
          matched: true,
          category: rule.category,
          subcategory: rule.subcategory,
          confidence,
          rule,
          reasoning: `Matched rule pattern: ${rule.pattern.source}`
        };
      }
    }

    return { matched: false };
  }

  /**
   * Analyze content to determine category when rules don't match
   */
  private analyzeContentForCategory(context: AnalysisContext): ContentCategoryResult {
    const categoryScores = new Map<string, number>();
    
    // Analyze based on document structure
    const structureScore = this.scoreByStructure(context);
    this.addScores(categoryScores, structureScore);

    // Analyze based on keywords
    const keywordScore = this.scoreByKeywords(context);
    this.addScores(categoryScores, keywordScore);

    // Analyze based on technical terms
    const technicalScore = this.scoreByTechnicalTerms(context);
    this.addScores(categoryScores, technicalScore);

    // Analyze based on file path
    const pathScore = this.scoreByPath(context);
    this.addScores(categoryScores, pathScore);

    // Find the highest scoring category
    const topCategory = this.getTopScoredCategory(categoryScores);
    
    if (topCategory && topCategory.score > 0.4) {
      return {
        category: topCategory.category,
        subcategory: this.inferSubcategory(topCategory.category, context),
        confidence: topCategory.score,
        reasoning: `Content analysis suggests ${topCategory.category} (score: ${topCategory.score.toFixed(2)})`
      };
    }

    return { category: null };
  }

  /**
   * Score categories based on document structure
   */
  private scoreByStructure(context: AnalysisContext): Map<string, number> {
    const scores = new Map<string, number>();
    const structure = context.structure;

    // API Documentation indicators
    if (structure.documentType === 'API Documentation' || 
        structure.headings.some(h => h.text.toLowerCase().includes('endpoint'))) {
      scores.set('User_Documentation', 0.8);
    }

    // Tutorial indicators
    if (structure.documentType === 'Tutorial' ||
        structure.headings.some(h => h.text.toLowerCase().includes('step'))) {
      scores.set('Learning_and_Development', 0.7);
    }

    // Architecture indicators
    if (structure.documentType === 'Architecture Document' ||
        structure.headings.some(h => h.text.toLowerCase().includes('architecture'))) {
      scores.set('Architecture_and_Design', 0.8);
    }

    // Technical reference indicators
    if (structure.codeBlocks.length > 5) {
      scores.set('User_Documentation', 0.6);
    }

    return scores;
  }

  /**
   * Score categories based on keywords
   */
  private scoreByKeywords(context: AnalysisContext): Map<string, number> {
    const scores = new Map<string, number>();
    const keywords = context.keywords.join(' ').toLowerCase();

    const categoryKeywords = {
      'Architecture_and_Design': ['architecture', 'design', 'pattern', 'system', 'structure'],
      'Learning_and_Development': ['tutorial', 'guide', 'learning', 'training', 'course'],
      'Team_Collaboration': ['team', 'collaboration', 'workflow', 'process', 'review'],
      'User_Documentation': ['api', 'reference', 'documentation', 'manual', 'usage'],
      'Project_Specifications': ['requirements', 'specification', 'scope', 'deliverable']
    };

    for (const [category, categoryKeywords] of Object.entries(categoryKeywords)) {
      let score = 0;
      for (const keyword of categoryKeywords) {
        if (keywords.includes(keyword)) {
          score += 0.2;
        }
      }
      if (score > 0) {
        scores.set(category, Math.min(score, 1.0));
      }
    }

    return scores;
  }

  /**
   * Score categories based on technical terms
   */
  private scoreByTechnicalTerms(context: AnalysisContext): Map<string, number> {
    const scores = new Map<string, number>();
    const terms = context.technicalTerms.join(' ').toLowerCase();

    if (terms.includes('apex') || terms.includes('soql') || terms.includes('trigger')) {
      scores.set('User_Documentation', 0.7);
    }

    if (terms.includes('lwc') || terms.includes('lightning') || terms.includes('component')) {
      scores.set('User_Documentation', 0.6);
    }

    if (terms.includes('test') || terms.includes('mock') || terms.includes('assert')) {
      scores.set('Learning_and_Development', 0.5);
    }

    return scores;
  }

  /**
   * Score categories based on file path
   */
  private scoreByPath(context: AnalysisContext): Map<string, number> {
    const scores = new Map<string, number>();
    const pathLower = context.filePath.toLowerCase();

    const pathPatterns = {
      'Architecture_and_Design': ['/architecture/', '/design/', '/adr/'],
      'Learning_and_Development': ['/tutorial/', '/guide/', '/learning/', '/training/'],
      'Team_Collaboration': ['/team/', '/collaboration/', '/workflow/', '/process/'],
      'User_Documentation': ['/api/', '/reference/', '/docs/', '/manual/'],
      'Project_Specifications': ['/requirements/', '/spec/', '/specification/']
    };

    for (const [category, patterns] of Object.entries(pathPatterns)) {
      for (const pattern of patterns) {
        if (pathLower.includes(pattern)) {
          scores.set(category, 0.6);
          break;
        }
      }
    }

    return scores;
  }

  /**
   * Analyze difficulty from content keywords
   */
  private analyzeDifficultyFromContent(content: string): DifficultyScores {
    const contentLower = content.toLowerCase();
    const scores: DifficultyScores = {
      Beginner: 0,
      Intermediate: 0,
      Advanced: 0,
      Expert: 0
    };

    const difficultyKeywords = {
      Beginner: ['introduction', 'getting started', 'basics', 'overview', 'simple', 'easy', 'tutorial', 'first steps'],
      Intermediate: ['implementation', 'configuration', 'setup', 'workflow', 'process', 'development'],
      Advanced: ['architecture', 'optimization', 'performance', 'security', 'debugging', 'complex'],
      Expert: ['internals', 'deep dive', 'advanced patterns', 'expert level', 'mastery', 'sophisticated']
    };

    for (const [level, keywords] of Object.entries(difficultyKeywords)) {
      for (const keyword of keywords) {
        const regex = new RegExp(`\\b${keyword}\\b`, 'gi');
        const matches = contentLower.match(regex);
        if (matches) {
          scores[level as keyof DifficultyScores] += matches.length * 0.1;
        }
      }
    }

    return scores;
  }

  /**
   * Analyze difficulty from file path
   */
  private analyzeDifficultyFromPath(filePath: string): DifficultyScores {
    const pathLower = filePath.toLowerCase();
    const scores: DifficultyScores = {
      Beginner: 0,
      Intermediate: 0,
      Advanced: 0,
      Expert: 0
    };

    if (pathLower.includes('beginner') || pathLower.includes('intro') || pathLower.includes('getting-started')) {
      scores.Beginner = 0.8;
    } else if (pathLower.includes('advanced') || pathLower.includes('expert')) {
      scores.Advanced = 0.7;
    } else if (pathLower.includes('architecture') || pathLower.includes('internals')) {
      scores.Expert = 0.6;
    } else {
      scores.Intermediate = 0.3; // Default assumption
    }

    return scores;
  }

  /**
   * Analyze difficulty from document structure
   */
  private analyzeDifficultyFromStructure(content: string): DifficultyScores {
    const structure = TextAnalyzer.analyzeStructure(content);
    const complexity = TextAnalyzer.analyzeComplexity(content);
    
    const scores: DifficultyScores = {
      Beginner: 0,
      Intermediate: 0,
      Advanced: 0,
      Expert: 0
    };

    // Code block complexity
    if (structure.codeBlocks.length > 10) {
      scores.Advanced += 0.3;
    } else if (structure.codeBlocks.length > 5) {
      scores.Intermediate += 0.2;
    } else if (structure.codeBlocks.length > 0) {
      scores.Beginner += 0.1;
    }

    // Document length and complexity
    if (complexity.complexityLevel === 'Very Complex') {
      scores.Expert += 0.4;
    } else if (complexity.complexityLevel === 'Complex') {
      scores.Advanced += 0.3;
    } else if (complexity.complexityLevel === 'Moderate') {
      scores.Intermediate += 0.2;
    } else {
      scores.Beginner += 0.2;
    }

    // Heading depth
    const maxHeadingLevel = Math.max(...structure.headings.map(h => h.level));
    if (maxHeadingLevel > 4) {
      scores.Advanced += 0.2;
    }

    return scores;
  }

  /**
   * Helper methods
   */
  private calculateRuleConfidence(rule: CategoryRule, context: AnalysisContext, matches: RegExpMatchArray): number {
    let confidence = 0.7; // Base confidence for rule match

    // Boost confidence based on match quality
    if (matches[0].length > 10) confidence += 0.1;
    if (matches.length > 1) confidence += 0.1;

    // Boost confidence if multiple indicators align
    if (context.filePath.toLowerCase().includes(rule.category.toLowerCase())) {
      confidence += 0.1;
    }

    return Math.min(confidence, 1.0);
  }

  private addScores(target: Map<string, number>, source: Map<string, number>): void {
    for (const [category, score] of source.entries()) {
      target.set(category, (target.get(category) || 0) + score);
    }
  }

  private getTopScoredCategory(scores: Map<string, number>): { category: string; score: number } | null {
    let topCategory: string | null = null;
    let topScore = 0;

    for (const [category, score] of scores.entries()) {
      if (score > topScore) {
        topScore = score;
        topCategory = category;
      }
    }

    return topCategory ? { category: topCategory, score: topScore } : null;
  }

  private getTopScoredDifficulty(scores: DifficultyScores): { difficulty: 'Beginner' | 'Intermediate' | 'Advanced' | 'Expert'; confidence: number } {
    const entries = Object.entries(scores) as [keyof DifficultyScores, number][];
    const sorted = entries.sort(([,a], [,b]) => b - a);
    
    const topDifficulty = sorted[0][0];
    const topScore = sorted[0][1];
    
    // Normalize confidence
    const totalScore = entries.reduce((sum, [, score]) => sum + score, 0);
    const confidence = totalScore > 0 ? Math.min(topScore / totalScore, 1.0) : 0.3;

    return { difficulty: topDifficulty, confidence };
  }

  private combineDifficultyScores(scoreArrays: DifficultyScores[]): DifficultyScores {
    const combined: DifficultyScores = {
      Beginner: 0,
      Intermediate: 0,
      Advanced: 0,
      Expert: 0
    };

    for (const scores of scoreArrays) {
      for (const [level, score] of Object.entries(scores)) {
        combined[level as keyof DifficultyScores] += score;
      }
    }

    return combined;
  }

  private generateDifficultyReasoning(scores: DifficultyScores, selectedDifficulty: string): string {
    const factors: string[] = [];
    
    if (scores.Beginner > 0.3) factors.push('beginner-friendly content');
    if (scores.Advanced > 0.3) factors.push('advanced concepts');
    if (scores.Expert > 0.3) factors.push('expert-level topics');
    
    return `Selected ${selectedDifficulty} based on: ${factors.join(', ') || 'content analysis'}`;
  }

  private inferSubcategory(category: string, context: AnalysisContext): string | undefined {
    const subcategoryMappings: Record<string, string[]> = {
      'Architecture_and_Design': ['System_Architecture', 'Data_Model', 'Integration_Patterns', 'Security_Design'],
      'Learning_and_Development': ['Beginner_Guides', 'Advanced_Topics', 'Learning_Paths', 'Skill_Development'],
      'Team_Collaboration': ['Workflows', 'Best_Practices', 'Code_Review', 'Project_Management'],
      'User_Documentation': ['End_User_Guides', 'Admin_Guides', 'Quick_References', 'API_Documentation'],
      'Project_Specifications': ['Requirements', 'Design_Documents', 'Implementation_Plans', 'Completion_Reports']
    };

    const possibleSubcategories = subcategoryMappings[category];
    if (!possibleSubcategories) return undefined;

    // Simple heuristic to pick subcategory
    const contentLower = context.content.toLowerCase();
    
    for (const subcategory of possibleSubcategories) {
      const subcategoryKeywords = subcategory.toLowerCase().replace(/_/g, ' ').split(' ');
      if (subcategoryKeywords.some(keyword => contentLower.includes(keyword))) {
        return subcategory;
      }
    }

    return possibleSubcategories[0]; // Default to first subcategory
  }

  private findAlternativeCategories(context: AnalysisContext, excludeCategory: string): string[] {
    const allScores = new Map<string, number>();
    
    // Collect scores from all analysis methods
    this.addScores(allScores, this.scoreByStructure(context));
    this.addScores(allScores, this.scoreByKeywords(context));
    this.addScores(allScores, this.scoreByTechnicalTerms(context));
    this.addScores(allScores, this.scoreByPath(context));

    // Remove the selected category and return top alternatives
    allScores.delete(excludeCategory);
    
    return Array.from(allScores.entries())
      .sort(([,a], [,b]) => b - a)
      .slice(0, 3)
      .map(([category]) => category);
  }

  private getKnownCategories(): Map<string, string[]> {
    return new Map([
      ['Architecture_and_Design', ['System_Architecture', 'Data_Model', 'Integration_Patterns', 'Security_Design']],
      ['Learning_and_Development', ['Beginner_Guides', 'Advanced_Topics', 'Learning_Paths', 'Skill_Development']],
      ['Team_Collaboration', ['Workflows', 'Best_Practices', 'Code_Review', 'Project_Management']],
      ['User_Documentation', ['End_User_Guides', 'Admin_Guides', 'Quick_References', 'API_Documentation']],
      ['Project_Specifications', ['Requirements', 'Design_Documents', 'Implementation_Plans', 'Completion_Reports']]
    ]);
  }

  private isValidCategoryName(name: string): boolean {
    return /^[A-Za-z][A-Za-z0-9_]*$/.test(name);
  }

  private suggestSimilarCategories(category: string, subcategory?: string): string[] {
    const knownCategories = Array.from(this.getKnownCategories().keys());
    const suggestions: string[] = [];

    // Simple similarity check
    for (const knownCategory of knownCategories) {
      if (this.calculateStringSimilarity(category.toLowerCase(), knownCategory.toLowerCase()) > 0.6) {
        suggestions.push(knownCategory);
      }
    }

    return suggestions;
  }

  private calculateStringSimilarity(str1: string, str2: string): number {
    const longer = str1.length > str2.length ? str1 : str2;
    const shorter = str1.length > str2.length ? str2 : str1;
    
    if (longer.length === 0) return 1.0;
    
    const editDistance = this.calculateEditDistance(longer, shorter);
    return (longer.length - editDistance) / longer.length;
  }

  private calculateEditDistance(str1: string, str2: string): number {
    const matrix: number[][] = [];
    
    for (let i = 0; i <= str2.length; i++) {
      matrix[i] = [i];
    }
    
    for (let j = 0; j <= str1.length; j++) {
      matrix[0][j] = j;
    }
    
    for (let i = 1; i <= str2.length; i++) {
      for (let j = 1; j <= str1.length; j++) {
        if (str2.charAt(i - 1) === str1.charAt(j - 1)) {
          matrix[i][j] = matrix[i - 1][j - 1];
        } else {
          matrix[i][j] = Math.min(
            matrix[i - 1][j - 1] + 1,
            matrix[i][j - 1] + 1,
            matrix[i - 1][j] + 1
          );
        }
      }
    }
    
    return matrix[str2.length][str1.length];
  }
}

// Type definitions

export interface CategoryMappingResult {
  category: string;
  subcategory?: string;
  confidence: number;
  matchedRule?: CategoryRule;
  reasoning: string;
  alternatives: string[];
}

export interface DifficultyInference {
  difficulty: 'Beginner' | 'Intermediate' | 'Advanced' | 'Expert';
  confidence: number;
  reasoning: string;
  factors?: {
    contentKeywords: DifficultyScores;
    pathIndicators: DifficultyScores;
    structureComplexity: DifficultyScores;
  };
}

export interface CategoryValidationResult {
  isValid: boolean;
  issues: string[];
  warnings: string[];
  suggestions: string[];
}

export interface CategoryMappingReport {
  totalMappings: number;
  categoryDistribution: Record<string, number>;
  subcategoryDistribution: Record<string, number>;
  confidenceDistribution: {
    high: number;
    medium: number;
    low: number;
  };
  ruleUsageStats: Record<string, number>;
  averageConfidence: number;
  lowConfidenceMappings: number;
}

interface AnalysisContext {
  filePath: string;
  fileName: string;
  metadata: FileMetadata;
  content: string;
  structure: any;
  keywords: string[];
  technicalTerms: string[];
  contentLength: number;
  wordCount: number;
}

interface RuleMatchResult {
  matched: boolean;
  category?: string;
  subcategory?: string;
  confidence?: number;
  rule?: CategoryRule;
  reasoning?: string;
}

interface ContentCategoryResult {
  category: string | null;
  subcategory?: string;
  confidence?: number;
  reasoning?: string;
}

interface DifficultyScores {
  Beginner: number;
  Intermediate: number;
  Advanced: number;
  Expert: number;
}