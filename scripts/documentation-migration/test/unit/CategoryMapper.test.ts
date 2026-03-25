/**
 * Unit tests for CategoryMapper class
 */

import { CategoryMapper, CategoryMappingResult, DifficultyInference } from '../../src/core/CategoryMapper';
import { CategoryRule, FileMetadata } from '../../src/types';
import { TextAnalyzer } from '../../src/utils/TextAnalyzer';

// Mock TextAnalyzer
jest.mock('../../src/utils/TextAnalyzer');
const mockTextAnalyzer = TextAnalyzer as jest.Mocked<typeof TextAnalyzer>;

describe('CategoryMapper', () => {
  let categoryMapper: CategoryMapper;
  let defaultRules: CategoryRule[];
  let sampleMetadata: FileMetadata;

  beforeEach(() => {
    defaultRules = [
      {
        pattern: /ARCHITECTURE|DESIGN|ADR/i,
        category: 'Architecture_and_Design',
        subcategory: 'System_Architecture',
        difficulty: 'Intermediate'
      },
      {
        pattern: /LEARNING|GUIDE|TUTORIAL/i,
        category: 'Learning_and_Development',
        subcategory: 'Learning_Paths',
        difficulty: 'Beginner'
      },
      {
        pattern: /TEAM|COLLABORATION|WORKFLOW/i,
        category: 'Team_Collaboration',
        subcategory: 'Workflows',
        difficulty: 'Intermediate'
      },
      {
        pattern: /API|REFERENCE|TECHNICAL/i,
        category: 'User_Documentation',
        subcategory: 'API_Documentation',
        difficulty: 'Advanced'
      }
    ];

    sampleMetadata = {
      filePath: 'docs/test.md',
      fileName: 'test.md',
      title: 'Test Document',
      urlName: 'test-document',
      category: '',
      tags: [],
      difficulty: 'Intermediate',
      readingTime: 5,
      lastModified: '2024-01-01T00:00:00Z',
      contentHash: 'abc123',
      wordCount: 100,
      headingCount: 3,
      codeBlockCount: 1,
      linkCount: 2
    };

    categoryMapper = new CategoryMapper(defaultRules);

    // Setup default mocks
    mockTextAnalyzer.analyzeStructure.mockReturnValue({
      headings: [{ level: 1, text: 'Test', position: 0 }],
      sections: [],
      lists: [],
      codeBlocks: [],
      tables: [],
      hasTableOfContents: false,
      estimatedReadingTime: 5,
      documentType: 'General Documentation'
    });

    mockTextAnalyzer.extractKeywords.mockReturnValue([
      { keyword: 'test', frequency: 3, score: 0.5 }
    ]);

    mockTextAnalyzer.extractTechnicalTerms.mockReturnValue([
      { term: 'TestClass', category: 'Class/Type', frequency: 1 }
    ]);

    mockTextAnalyzer.analyzeComplexity.mockReturnValue({
      fleschScore: 70,
      gradeLevel: 8,
      complexityLevel: 'Moderate',
      sentenceCount: 10,
      wordCount: 100,
      syllableCount: 150,
      avgWordsPerSentence: 10,
      avgSyllablesPerWord: 1.5
    });

    jest.clearAllMocks();
  });

  describe('mapToCategory', () => {
    it('should map to category based on matching rule', () => {
      const content = 'This document describes the system architecture and design patterns.';

      const result = categoryMapper.mapToCategory('docs/architecture.md', sampleMetadata, content);

      expect(result.category).toBe('Architecture_and_Design');
      expect(result.subcategory).toBe('System_Architecture');
      expect(result.confidence).toBeGreaterThan(0.5);
      expect(result.matchedRule).toBeDefined();
      expect(result.reasoning).toContain('Matched rule pattern');
    });

    it('should fall back to content analysis when no rules match', () => {
      const content = 'This is a general document about various topics.';
      
      // Mock structure analysis to suggest a category
      mockTextAnalyzer.analyzeStructure.mockReturnValue({
        headings: [{ level: 1, text: 'API Reference', position: 0 }],
        sections: [],
        lists: [],
        codeBlocks: [{ language: 'javascript', code: 'console.log("test")', lineCount: 1 }],
        tables: [],
        hasTableOfContents: false,
        estimatedReadingTime: 5,
        documentType: 'API Documentation'
      });

      const result = categoryMapper.mapToCategory('docs/general.md', sampleMetadata, content);

      expect(result.category).toBeTruthy();
      expect(result.confidence).toBeGreaterThan(0);
      expect(result.reasoning).toContain('Content analysis suggests');
    });

    it('should use fallback category when no matches found', () => {
      const content = 'Random content with no specific indicators.';
      
      // Mock all analysis to return empty/low scores
      mockTextAnalyzer.analyzeStructure.mockReturnValue({
        headings: [],
        sections: [],
        lists: [],
        codeBlocks: [],
        tables: [],
        hasTableOfContents: false,
        estimatedReadingTime: 1,
        documentType: 'General Documentation'
      });

      const result = categoryMapper.mapToCategory('docs/random.md', sampleMetadata, content);

      expect(result.category).toBe('User_Documentation'); // Default fallback
      expect(result.confidence).toBeLessThan(0.5);
      expect(result.reasoning).toContain('fallback category');
    });

    it('should provide alternative categories', () => {
      const content = 'This document covers architecture and also includes some tutorial content.';

      const result = categoryMapper.mapToCategory('docs/mixed.md', sampleMetadata, content);

      expect(result.alternatives).toBeDefined();
      expect(Array.isArray(result.alternatives)).toBe(true);
    });

    it('should handle multiple rule matches by taking the first', () => {
      const content = 'This architecture guide is also a tutorial for learning design patterns.';

      const result = categoryMapper.mapToCategory('docs/arch-tutorial.md', sampleMetadata, content);

      // Should match the first rule (architecture)
      expect(result.category).toBe('Architecture_and_Design');
      expect(result.matchedRule?.pattern.source).toContain('ARCHITECTURE');
    });
  });

  describe('inferDifficulty', () => {
    it('should use metadata difficulty when explicitly set', () => {
      const metadataWithDifficulty = { ...sampleMetadata, difficulty: 'Expert' as const };
      const content = 'Simple beginner content.';

      const result = categoryMapper.inferDifficulty(content, metadataWithDifficulty, 'docs/test.md');

      expect(result.difficulty).toBe('Expert');
      expect(result.confidence).toBe(0.9);
      expect(result.reasoning).toContain('explicitly set in document metadata');
    });

    it('should infer difficulty from content keywords', () => {
      const content = `
        # Getting Started Guide
        
        This is an introduction to the basics. It's simple and easy to follow.
        Perfect for beginners who want to learn the fundamentals.
      `;

      const result = categoryMapper.inferDifficulty(content, sampleMetadata, 'docs/getting-started.md');

      expect(result.difficulty).toBe('Beginner');
      expect(result.confidence).toBeGreaterThan(0);
      expect(result.factors).toBeDefined();
    });

    it('should infer difficulty from file path', () => {
      const content = 'Regular content without specific difficulty indicators.';

      const result = categoryMapper.inferDifficulty(content, sampleMetadata, 'docs/advanced/expert-guide.md');

      expect(result.difficulty).toBe('Advanced');
      expect(result.confidence).toBeGreaterThan(0.5);
    });

    it('should consider document structure complexity', () => {
      const content = 'Content with complex structure.';
      
      // Mock complex structure
      mockTextAnalyzer.analyzeStructure.mockReturnValue({
        headings: Array(10).fill(0).map((_, i) => ({ level: Math.min(i + 1, 6), text: `Heading ${i}`, position: i * 100 })),
        sections: [],
        lists: [],
        codeBlocks: Array(15).fill({ language: 'javascript', code: 'complex code', lineCount: 10 }),
        tables: [],
        hasTableOfContents: true,
        estimatedReadingTime: 45,
        documentType: 'Technical Reference'
      });

      mockTextAnalyzer.analyzeComplexity.mockReturnValue({
        fleschScore: 30,
        gradeLevel: 16,
        complexityLevel: 'Very Complex',
        sentenceCount: 100,
        wordCount: 2000,
        syllableCount: 3000,
        avgWordsPerSentence: 20,
        avgSyllablesPerWord: 1.5
      });

      const result = categoryMapper.inferDifficulty(content, sampleMetadata, 'docs/complex.md');

      expect(result.difficulty).toBe('Advanced');
      expect(result.confidence).toBeGreaterThan(0);
    });

    it('should combine multiple difficulty factors', () => {
      const content = `
        # Advanced Architecture Patterns
        
        This document covers sophisticated optimization techniques and complex debugging strategies.
        Expert-level knowledge of internals is required.
      `;

      const result = categoryMapper.inferDifficulty(content, sampleMetadata, 'docs/advanced/expert-patterns.md');

      expect(result.factors).toBeDefined();
      expect(result.factors?.contentKeywords).toBeDefined();
      expect(result.factors?.pathIndicators).toBeDefined();
      expect(result.factors?.structureComplexity).toBeDefined();
    });
  });

  describe('validateCategory', () => {
    it('should validate known categories', () => {
      const result = categoryMapper.validateCategory('Architecture_and_Design', 'System_Architecture');

      expect(result.isValid).toBe(true);
      expect(result.issues).toHaveLength(0);
    });

    it('should detect unknown categories', () => {
      const result = categoryMapper.validateCategory('Unknown_Category');

      expect(result.isValid).toBe(false);
      expect(result.issues).toContain('Unknown category: Unknown_Category');
    });

    it('should warn about unknown subcategories', () => {
      const result = categoryMapper.validateCategory('Architecture_and_Design', 'Unknown_Subcategory');

      expect(result.isValid).toBe(true); // Not an error, just a warning
      expect(result.warnings.length).toBeGreaterThan(0);
      expect(result.warnings[0]).toContain('may not exist');
    });

    it('should detect invalid naming conventions', () => {
      const result = categoryMapper.validateCategory('invalid category name');

      expect(result.isValid).toBe(false);
      expect(result.issues).toContain("doesn't follow naming conventions");
    });

    it('should suggest similar categories', () => {
      const result = categoryMapper.validateCategory('Architecture_Design'); // Similar to Architecture_and_Design

      expect(result.suggestions).toBeDefined();
      expect(Array.isArray(result.suggestions)).toBe(true);
    });
  });

  describe('generateMappingReport', () => {
    it('should generate comprehensive mapping report', () => {
      const mappings: CategoryMappingResult[] = [
        {
          category: 'Architecture_and_Design',
          subcategory: 'System_Architecture',
          confidence: 0.9,
          matchedRule: defaultRules[0],
          reasoning: 'Rule match',
          alternatives: []
        },
        {
          category: 'Learning_and_Development',
          subcategory: 'Learning_Paths',
          confidence: 0.8,
          matchedRule: defaultRules[1],
          reasoning: 'Rule match',
          alternatives: []
        },
        {
          category: 'Architecture_and_Design',
          confidence: 0.4,
          reasoning: 'Content analysis',
          alternatives: []
        }
      ];

      const report = categoryMapper.generateMappingReport(mappings);

      expect(report.totalMappings).toBe(3);
      expect(report.categoryDistribution['Architecture_and_Design']).toBe(2);
      expect(report.categoryDistribution['Learning_and_Development']).toBe(1);
      expect(report.confidenceDistribution.high).toBe(2); // 0.9 and 0.8
      expect(report.confidenceDistribution.low).toBe(1); // 0.4
      expect(report.averageConfidence).toBeCloseTo(0.7);
      expect(report.lowConfidenceMappings).toBe(1);
    });

    it('should handle empty mappings', () => {
      const report = categoryMapper.generateMappingReport([]);

      expect(report.totalMappings).toBe(0);
      expect(Object.keys(report.categoryDistribution)).toHaveLength(0);
      expect(report.averageConfidence).toBe(0);
    });

    it('should track rule usage statistics', () => {
      const mappings: CategoryMappingResult[] = [
        {
          category: 'Architecture_and_Design',
          confidence: 0.9,
          matchedRule: defaultRules[0],
          reasoning: 'Rule match',
          alternatives: []
        },
        {
          category: 'Architecture_and_Design',
          confidence: 0.8,
          matchedRule: defaultRules[0], // Same rule used twice
          reasoning: 'Rule match',
          alternatives: []
        }
      ];

      const report = categoryMapper.generateMappingReport(mappings);

      const rulePattern = defaultRules[0].pattern.source;
      expect(report.ruleUsageStats[rulePattern]).toBe(2);
    });
  });

  describe('content analysis scoring', () => {
    it('should score based on document structure', () => {
      mockTextAnalyzer.analyzeStructure.mockReturnValue({
        headings: [{ level: 1, text: 'API Endpoints', position: 0 }],
        sections: [],
        lists: [],
        codeBlocks: [],
        tables: [],
        hasTableOfContents: false,
        estimatedReadingTime: 5,
        documentType: 'API Documentation'
      });

      const content = 'API documentation content.';
      const result = categoryMapper.mapToCategory('docs/api.md', sampleMetadata, content);

      expect(result.category).toBeTruthy();
    });

    it('should score based on keywords', () => {
      mockTextAnalyzer.extractKeywords.mockReturnValue([
        { keyword: 'architecture', frequency: 5, score: 0.8 },
        { keyword: 'design', frequency: 3, score: 0.6 },
        { keyword: 'pattern', frequency: 2, score: 0.4 }
      ]);

      const content = 'Content about architecture, design, and patterns.';
      const result = categoryMapper.mapToCategory('docs/content.md', sampleMetadata, content);

      expect(result.category).toBeTruthy();
    });

    it('should score based on technical terms', () => {
      mockTextAnalyzer.extractTechnicalTerms.mockReturnValue([
        { term: 'apex', category: 'Salesforce', frequency: 3 },
        { term: 'SOQL', category: 'Salesforce', frequency: 2 },
        { term: 'trigger', category: 'Salesforce', frequency: 1 }
      ]);

      const content = 'Salesforce Apex and SOQL content.';
      const result = categoryMapper.mapToCategory('docs/salesforce.md', sampleMetadata, content);

      expect(result.category).toBeTruthy();
    });

    it('should score based on file path patterns', () => {
      const content = 'General content.';
      const result = categoryMapper.mapToCategory('docs/api/reference/endpoints.md', sampleMetadata, content);

      expect(result.category).toBeTruthy();
    });
  });

  describe('edge cases', () => {
    it('should handle empty content', () => {
      const result = categoryMapper.mapToCategory('docs/empty.md', sampleMetadata, '');

      expect(result.category).toBeTruthy();
      expect(result.confidence).toBeGreaterThan(0);
    });

    it('should handle very long content', () => {
      const longContent = 'Content word. '.repeat(10000);
      
      const result = categoryMapper.mapToCategory('docs/long.md', sampleMetadata, longContent);

      expect(result.category).toBeTruthy();
    });

    it('should handle special characters in content', () => {
      const content = 'Content with émojis 🚀 and special chars @#$%^&*()';
      
      const result = categoryMapper.mapToCategory('docs/special.md', sampleMetadata, content);

      expect(result.category).toBeTruthy();
    });

    it('should handle malformed file paths', () => {
      const content = 'Regular content.';
      
      const result = categoryMapper.mapToCategory('', sampleMetadata, content);

      expect(result.category).toBeTruthy();
    });

    it('should handle rules with complex regex patterns', () => {
      const complexRules: CategoryRule[] = [
        {
          pattern: /(?:api|rest|endpoint).*(?:reference|documentation)/i,
          category: 'User_Documentation',
          subcategory: 'API_Documentation'
        }
      ];

      const mapper = new CategoryMapper(complexRules);
      const content = 'This is an API reference documentation.';
      
      const result = mapper.mapToCategory('docs/api-ref.md', sampleMetadata, content);

      expect(result.category).toBe('User_Documentation');
      expect(result.subcategory).toBe('API_Documentation');
    });
  });

  describe('similarity calculations', () => {
    it('should calculate string similarity correctly', () => {
      // Access private method for testing
      const similarity1 = (categoryMapper as any).calculateStringSimilarity('architecture', 'architecture');
      const similarity2 = (categoryMapper as any).calculateStringSimilarity('architecture', 'architecure'); // typo
      const similarity3 = (categoryMapper as any).calculateStringSimilarity('architecture', 'completely_different');

      expect(similarity1).toBe(1); // Identical
      expect(similarity2).toBeGreaterThan(0.8); // Very similar
      expect(similarity3).toBeLessThan(0.5); // Different
    });

    it('should handle empty strings in similarity calculation', () => {
      const similarity1 = (categoryMapper as any).calculateStringSimilarity('', '');
      const similarity2 = (categoryMapper as any).calculateStringSimilarity('test', '');

      expect(similarity1).toBe(1); // Both empty
      expect(similarity2).toBe(0); // One empty
    });
  });

  describe('custom fallback categories', () => {
    it('should use custom fallback category', () => {
      const customMapper = new CategoryMapper([], 'Custom_Fallback', 'Custom_Subcategory');
      const content = 'Content that matches no rules.';

      const result = customMapper.mapToCategory('docs/test.md', sampleMetadata, content);

      expect(result.category).toBe('Custom_Fallback');
      expect(result.subcategory).toBe('Custom_Subcategory');
    });
  });
});