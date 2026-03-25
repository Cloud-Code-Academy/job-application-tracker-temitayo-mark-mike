/**
 * Unit tests for TextAnalyzer utility class
 */

import { TextAnalyzer, KeywordResult, ComplexityAnalysis, TechnicalTerm, DocumentStructure } from '../../src/utils/TextAnalyzer';

describe('TextAnalyzer', () => {
  describe('extractKeywords', () => {
    it('should extract keywords from text', () => {
      const text = `
        Salesforce development involves creating Apex classes and Lightning components.
        Testing is crucial for Salesforce development. Apex testing ensures code quality.
        Lightning components provide modern user interfaces for Salesforce applications.
      `;

      const keywords = TextAnalyzer.extractKeywords(text, 5);

      expect(keywords).toHaveLength(5);
      expect(keywords[0]).toHaveProperty('keyword');
      expect(keywords[0]).toHaveProperty('frequency');
      expect(keywords[0]).toHaveProperty('score');
      
      // Should find relevant keywords
      const keywordTexts = keywords.map(k => k.keyword);
      expect(keywordTexts.some(k => k.includes('salesforce') || k.includes('apex') || k.includes('lightning'))).toBe(true);
    });

    it('should filter out stop words', () => {
      const text = 'The quick brown fox jumps over the lazy dog and runs through the forest';

      const keywords = TextAnalyzer.extractKeywords(text, 10);

      // Should not include common stop words
      const keywordTexts = keywords.map(k => k.keyword);
      expect(keywordTexts).not.toContain('the');
      expect(keywordTexts).not.toContain('and');
      expect(keywordTexts).not.toContain('over');
    });

    it('should handle empty text', () => {
      const keywords = TextAnalyzer.extractKeywords('', 5);

      expect(keywords).toHaveLength(0);
    });

    it('should limit results to maxKeywords', () => {
      const text = 'word1 word2 word3 word4 word5 word6 word7 word8 word9 word10 word11 word12';

      const keywords = TextAnalyzer.extractKeywords(text, 5);

      expect(keywords).toHaveLength(5);
    });
  });

  describe('analyzeComplexity', () => {
    it('should analyze simple text complexity', () => {
      const text = 'This is a simple text. It has short sentences. Easy to read.';

      const analysis = TextAnalyzer.analyzeComplexity(text);

      expect(analysis.complexityLevel).toBe('Simple');
      expect(analysis.fleschScore).toBeGreaterThan(70);
      expect(analysis.sentenceCount).toBe(3);
      expect(analysis.wordCount).toBeGreaterThan(0);
    });

    it('should analyze complex text complexity', () => {
      const text = `
        The implementation of sophisticated architectural patterns necessitates comprehensive understanding of multifaceted 
        system interactions, requiring extensive analysis of interdependent components and their complex relationships 
        within the broader ecosystem of enterprise-level applications that demand meticulous attention to performance 
        optimization and scalability considerations.
      `;

      const analysis = TextAnalyzer.analyzeComplexity(text);

      expect(analysis.complexityLevel).toBe('Complex');
      expect(analysis.fleschScore).toBeLessThan(70);
      expect(analysis.gradeLevel).toBeGreaterThan(10);
    });

    it('should calculate reading metrics correctly', () => {
      const text = 'Short sentence. Another short sentence.';

      const analysis = TextAnalyzer.analyzeComplexity(text);

      expect(analysis.sentenceCount).toBe(2);
      expect(analysis.wordCount).toBe(6);
      expect(analysis.avgWordsPerSentence).toBe(3);
      expect(analysis.avgSyllablesPerWord).toBeGreaterThan(0);
    });

    it('should handle empty text', () => {
      const analysis = TextAnalyzer.analyzeComplexity('');

      expect(analysis.sentenceCount).toBe(0);
      expect(analysis.wordCount).toBe(0);
      expect(analysis.complexityLevel).toBe('Simple');
    });
  });

  describe('extractTechnicalTerms', () => {
    it('should extract API endpoints', () => {
      const text = 'Call the /api/users endpoint and /api/orders/123 for data retrieval.';

      const terms = TextAnalyzer.extractTechnicalTerms(text);

      const apiTerms = terms.filter(t => t.category === 'API Endpoint');
      expect(apiTerms.length).toBeGreaterThan(0);
      expect(apiTerms.some(t => t.term.includes('/api/users'))).toBe(true);
    });

    it('should extract class names', () => {
      const text = 'The UserController and OrderService classes handle business logic.';

      const terms = TextAnalyzer.extractTechnicalTerms(text);

      const classTerms = terms.filter(t => t.category === 'Class/Type');
      expect(classTerms.length).toBeGreaterThan(0);
      expect(classTerms.some(t => t.term === 'UserController')).toBe(true);
      expect(classTerms.some(t => t.term === 'OrderService')).toBe(true);
    });

    it('should extract method names', () => {
      const text = 'Call the getUserData() method and processOrder() function.';

      const terms = TextAnalyzer.extractTechnicalTerms(text);

      const methodTerms = terms.filter(t => t.category === 'Method');
      expect(methodTerms.length).toBeGreaterThan(0);
      expect(methodTerms.some(t => t.term === 'getUserData')).toBe(true);
    });

    it('should extract Salesforce-specific terms', () => {
      const text = 'Use SOQL queries and Apex triggers in your Lightning Web Components.';

      const terms = TextAnalyzer.extractTechnicalTerms(text);

      const salesforceTerms = terms.filter(t => t.category === 'Salesforce');
      expect(salesforceTerms.length).toBeGreaterThan(0);
      expect(salesforceTerms.some(t => t.term.toLowerCase() === 'soql')).toBe(true);
      expect(salesforceTerms.some(t => t.term.toLowerCase() === 'apex')).toBe(true);
    });

    it('should count term frequency', () => {
      const text = 'UserController is used. UserController handles requests. UserController is important.';

      const terms = TextAnalyzer.extractTechnicalTerms(text);

      const userControllerTerm = terms.find(t => t.term === 'UserController');
      expect(userControllerTerm?.frequency).toBe(3);
    });

    it('should remove duplicates and sort by frequency', () => {
      const text = 'ApiService ApiService UserController ApiService';

      const terms = TextAnalyzer.extractTechnicalTerms(text);

      expect(terms[0].term).toBe('ApiService');
      expect(terms[0].frequency).toBe(3);
      expect(terms[1].term).toBe('UserController');
      expect(terms[1].frequency).toBe(1);
    });
  });

  describe('analyzeStructure', () => {
    it('should analyze document structure', () => {
      const text = `
# Main Title

Introduction paragraph.

## Section 1

Content for section 1.

### Subsection 1.1

More detailed content.

## Section 2

- List item 1
- List item 2
- List item 3

1. Ordered item 1
2. Ordered item 2

\`\`\`javascript
console.log('code example');
\`\`\`

| Column 1 | Column 2 |
|----------|----------|
| Data 1   | Data 2   |
| Data 3   | Data 4   |
      `;

      const structure = TextAnalyzer.analyzeStructure(text);

      expect(structure.headings).toHaveLength(4);
      expect(structure.headings[0].level).toBe(1);
      expect(structure.headings[0].text).toBe('Main Title');

      expect(structure.sections).toHaveLength(4);
      expect(structure.sections[0].title).toBe('Main Title');

      expect(structure.lists).toHaveLength(2);
      expect(structure.lists[0].type).toBe('unordered');
      expect(structure.lists[0].itemCount).toBe(3);
      expect(structure.lists[1].type).toBe('ordered');
      expect(structure.lists[1].itemCount).toBe(2);

      expect(structure.codeBlocks).toHaveLength(1);
      expect(structure.codeBlocks[0].language).toBe('javascript');

      expect(structure.tables).toHaveLength(1);
      expect(structure.tables[0].columnCount).toBe(2);
      expect(structure.tables[0].rowCount).toBe(2);

      expect(structure.estimatedReadingTime).toBeGreaterThan(0);
      expect(structure.documentType).toBeTruthy();
    });

    it('should detect table of contents', () => {
      const text = `
# Document Title

## Table of Contents

1. Introduction
2. Main Content
3. Conclusion

## Introduction

Content here.
      `;

      const structure = TextAnalyzer.analyzeStructure(text);

      expect(structure.hasTableOfContents).toBe(true);
    });

    it('should infer document type from content', () => {
      const apiText = 'This document describes the REST API endpoints for user management.';
      const tutorialText = 'This tutorial will guide you step by step through the installation process.';
      const architectureText = 'This document outlines the system architecture and design decisions.';

      const apiStructure = TextAnalyzer.analyzeStructure(apiText);
      const tutorialStructure = TextAnalyzer.analyzeStructure(tutorialText);
      const architectureStructure = TextAnalyzer.analyzeStructure(architectureText);

      expect(apiStructure.documentType).toBe('API Documentation');
      expect(tutorialStructure.documentType).toBe('Tutorial');
      expect(architectureStructure.documentType).toBe('Architecture Document');
    });

    it('should handle documents without structure', () => {
      const text = 'Just a simple paragraph without any structure.';

      const structure = TextAnalyzer.analyzeStructure(text);

      expect(structure.headings).toHaveLength(0);
      expect(structure.sections).toHaveLength(0);
      expect(structure.lists).toHaveLength(0);
      expect(structure.codeBlocks).toHaveLength(0);
      expect(structure.tables).toHaveLength(0);
      expect(structure.hasTableOfContents).toBe(false);
    });
  });

  describe('edge cases', () => {
    it('should handle text with only code blocks', () => {
      const text = `
\`\`\`javascript
console.log('hello');
\`\`\`

\`\`\`python
print('world')
\`\`\`
      `;

      const keywords = TextAnalyzer.extractKeywords(text, 5);
      const complexity = TextAnalyzer.analyzeComplexity(text);
      const structure = TextAnalyzer.analyzeStructure(text);

      expect(keywords).toHaveLength(0); // Code blocks should be filtered out
      expect(complexity.wordCount).toBe(0);
      expect(structure.codeBlocks).toHaveLength(2);
    });

    it('should handle text with only links', () => {
      const text = '[Link 1](http://example.com) and [Link 2](http://test.com)';

      const keywords = TextAnalyzer.extractKeywords(text, 5);
      const complexity = TextAnalyzer.analyzeComplexity(text);

      // Should extract text from links
      expect(keywords.some(k => k.keyword.includes('link'))).toBe(true);
      expect(complexity.wordCount).toBeGreaterThan(0);
    });

    it('should handle malformed markdown', () => {
      const text = `
# Incomplete heading
## Another heading without content
### 
[Incomplete link](
\`\`\`
Incomplete code block
      `;

      expect(() => {
        TextAnalyzer.extractKeywords(text, 5);
        TextAnalyzer.analyzeComplexity(text);
        TextAnalyzer.analyzeStructure(text);
      }).not.toThrow();
    });

    it('should handle very long text', () => {
      const longText = 'word '.repeat(10000);

      const keywords = TextAnalyzer.extractKeywords(longText, 5);
      const complexity = TextAnalyzer.analyzeComplexity(longText);

      expect(keywords).toHaveLength(1); // Only one unique word
      expect(complexity.wordCount).toBe(10000);
      expect(complexity.sentenceCount).toBe(1);
    });

    it('should handle text with special characters', () => {
      const text = 'Special chars: @#$%^&*()_+{}|:"<>?[]\\;\',./ and émojis 🚀 and ñoñó';

      expect(() => {
        TextAnalyzer.extractKeywords(text, 5);
        TextAnalyzer.analyzeComplexity(text);
        TextAnalyzer.extractTechnicalTerms(text);
      }).not.toThrow();
    });
  });
});