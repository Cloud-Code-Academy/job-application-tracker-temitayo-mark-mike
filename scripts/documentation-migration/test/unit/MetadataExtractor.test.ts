/**
 * Unit tests for MetadataExtractor class
 */

import { MetadataExtractor, FrontmatterResult, InferredMetadata } from '../../src/core/MetadataExtractor';

describe('MetadataExtractor', () => {
  let extractor: MetadataExtractor;

  beforeEach(() => {
    extractor = new MetadataExtractor();
  });

  describe('extractFrontmatter', () => {
    it('should extract valid YAML frontmatter', () => {
      const content = `---
title: Test Document
author: John Doe
tags: [test, example]
---

# Content here`;

      const result = extractor.extractFrontmatter(content);

      expect(result.hasFrontmatter).toBe(true);
      expect(result.frontmatter.title).toBe('Test Document');
      expect(result.frontmatter.author).toBe('John Doe');
      expect(result.frontmatter.tags).toEqual(['test', 'example']);
      expect(result.content).toBe('\n# Content here');
    });

    it('should handle content without frontmatter', () => {
      const content = '# Just a regular document\n\nWith some content.';

      const result = extractor.extractFrontmatter(content);

      expect(result.hasFrontmatter).toBe(false);
      expect(result.frontmatter).toEqual({});
      expect(result.content).toBe(content);
    });

    it('should handle invalid YAML frontmatter', () => {
      const content = `---
title: Test Document
invalid: yaml: content: here
---

# Content`;

      const result = extractor.extractFrontmatter(content);

      expect(result.hasFrontmatter).toBe(false);
      expect(result.parseError).toContain('Failed to parse frontmatter');
      expect(result.content).toBe(content);
    });

    it('should handle empty frontmatter', () => {
      const content = `---
---

# Content here`;

      const result = extractor.extractFrontmatter(content);

      expect(result.hasFrontmatter).toBe(true);
      expect(result.frontmatter).toEqual({});
      expect(result.content).toBe('\n# Content here');
    });
  });

  describe('inferMetadata', () => {
    it('should infer metadata from content with frontmatter', () => {
      const content = `---
title: Advanced Salesforce Architecture
difficulty: expert
tags: [architecture, salesforce, advanced]
---

# Advanced Salesforce Architecture

This is a comprehensive guide to advanced Salesforce architecture patterns.

## Prerequisites

- Understanding of Salesforce basics
- Experience with Apex development

## Content

This document covers complex architectural patterns and best practices.`;

      const metadata = extractor.inferMetadata('docs/architecture-guide.md', content);

      expect(metadata.title).toBe('Advanced Salesforce Architecture');
      expect(metadata.difficulty).toBe('Expert');
      expect(metadata.tags).toContain('Architecture');
      expect(metadata.readingTime).toBeGreaterThan(0);
      expect(metadata.prerequisites).toContain('Understanding of Salesforce basics');
    });

    it('should infer metadata from content without frontmatter', () => {
      const content = `# Getting Started Guide

This is a simple introduction to our system.

It covers the basics and helps new users get up and running quickly.

## Installation

Follow these simple steps to install the software.`;

      const metadata = extractor.inferMetadata('docs/getting-started.md', content);

      expect(metadata.title).toBe('Getting Started Guide');
      expect(metadata.difficulty).toBe('Beginner');
      expect(metadata.tags).toContain('Learning Path');
      expect(metadata.readingTime).toBeGreaterThan(0);
    });

    it('should generate title from filename when no heading exists', () => {
      const content = 'Just some content without a title.';

      const metadata = extractor.inferMetadata('docs/api-reference-guide.md', content);

      expect(metadata.title).toBe('Api Reference Guide');
    });

    it('should extract summary from first paragraph', () => {
      const content = `# Test Document

This is a comprehensive summary of the document that explains what it covers and why it's important for readers to understand.

## Section 1

More content here.`;

      const metadata = extractor.inferMetadata('docs/test.md', content);

      expect(metadata.summary).toContain('comprehensive summary');
      expect(metadata.summary?.length).toBeLessThanOrEqual(200);
    });
  });

  describe('calculateReadingTime', () => {
    it('should calculate reading time correctly', () => {
      // Create content with approximately 400 words (should be 2 minutes at 200 WPM)
      const words = Array(400).fill('word').join(' ');
      const readingTime = extractor.calculateReadingTime(words);

      expect(readingTime).toBe(2);
    });

    it('should return minimum 1 minute for short content', () => {
      const shortContent = 'Just a few words here.';
      const readingTime = extractor.calculateReadingTime(shortContent);

      expect(readingTime).toBe(1);
    });

    it('should ignore code blocks in reading time calculation', () => {
      const content = `
Some text here.

\`\`\`javascript
// This is a long code block that should not count towards reading time
function example() {
  console.log('This is code');
  return 'lots of code here that would normally increase reading time';
}
\`\`\`

More text here.`;

      const readingTime = extractor.calculateReadingTime(content);

      // Should be much less than if code was counted
      expect(readingTime).toBe(1);
    });
  });

  describe('extractTags', () => {
    it('should extract tags from frontmatter', () => {
      const frontmatter = { tags: ['custom-tag', 'another-tag'] };
      const content = 'Some content';
      const filePath = 'test.md';

      const tags = extractor.extractTags(frontmatter, content, filePath);

      expect(tags).toContain('custom-tag');
      expect(tags).toContain('another-tag');
    });

    it('should infer tags from content keywords', () => {
      const frontmatter = {};
      const content = `
# Apex Development Guide

This guide covers Apex triggers, classes, and SOQL queries.
We'll also discuss Lightning Web Components and testing strategies.`;
      const filePath = 'apex-guide.md';

      const tags = extractor.extractTags(frontmatter, content, filePath);

      expect(tags).toContain('Apex');
      expect(tags).toContain('Lightning Web Components');
      expect(tags).toContain('Testing');
    });

    it('should infer tags from file path', () => {
      const frontmatter = {};
      const content = 'Some content';
      const filePath = 'docs/api/rest-api-guide.md';

      const tags = extractor.extractTags(frontmatter, content, filePath);

      expect(tags).toContain('API Documentation');
    });

    it('should limit tags to maximum number', () => {
      const frontmatter = { tags: Array(15).fill(0).map((_, i) => `tag-${i}`) };
      const content = 'Content with apex, lwc, testing, architecture, security, integration, deployment keywords';
      const filePath = 'test.md';

      const tags = extractor.extractTags(frontmatter, content, filePath);

      expect(tags.length).toBeLessThanOrEqual(10);
    });
  });

  describe('difficulty inference', () => {
    it('should infer beginner difficulty from content', () => {
      const content = `
# Getting Started Tutorial

This is a simple introduction guide for beginners.
We'll cover the basics and provide easy step-by-step instructions.`;

      const metadata = extractor.inferMetadata('getting-started.md', content);

      expect(metadata.difficulty).toBe('Beginner');
    });

    it('should infer advanced difficulty from content', () => {
      const content = `
# Advanced Architecture Patterns

This document covers complex optimization techniques, advanced debugging strategies,
and sophisticated performance tuning for enterprise applications.

\`\`\`apex
// Complex code example 1
\`\`\`

\`\`\`apex
// Complex code example 2
\`\`\`

\`\`\`apex
// Complex code example 3
\`\`\`

\`\`\`apex
// Complex code example 4
\`\`\`

\`\`\`apex
// Complex code example 5
\`\`\`

\`\`\`apex
// Complex code example 6
\`\`\``;

      const metadata = extractor.inferMetadata('advanced-patterns.md', content);

      expect(metadata.difficulty).toBe('Advanced');
    });

    it('should use frontmatter difficulty when provided', () => {
      const content = `---
difficulty: expert
---

# Simple Guide

This is actually a simple guide despite the frontmatter.`;

      const metadata = extractor.inferMetadata('test.md', content);

      expect(metadata.difficulty).toBe('Expert');
    });

    it('should default to intermediate when no clear indicators', () => {
      const content = `# Some Document

This is a regular document without clear difficulty indicators.`;

      const metadata = extractor.inferMetadata('test.md', content);

      expect(metadata.difficulty).toBe('Intermediate');
    });
  });

  describe('prerequisites extraction', () => {
    it('should extract prerequisites from frontmatter', () => {
      const content = `---
prerequisites: Basic understanding of Salesforce and Apex development
---

# Test Document`;

      const metadata = extractor.inferMetadata('test.md', content);

      expect(metadata.prerequisites).toBe('Basic understanding of Salesforce and Apex development');
    });

    it('should extract prerequisites from content section', () => {
      const content = `
# Test Document

## Prerequisites

- Understanding of Salesforce basics
- Experience with Apex development
- Knowledge of Lightning components

## Content

More content here.`;

      const metadata = extractor.inferMetadata('test.md', content);

      expect(metadata.prerequisites).toContain('Understanding of Salesforce basics');
      expect(metadata.prerequisites).toContain('Experience with Apex development');
    });

    it('should handle no prerequisites', () => {
      const content = `# Simple Document

Just some basic content without prerequisites.`;

      const metadata = extractor.inferMetadata('test.md', content);

      expect(metadata.prerequisites).toBeUndefined();
    });
  });

  describe('content analysis', () => {
    it('should count words correctly', () => {
      const content = `
# Title

This is a test document with some content.

\`\`\`javascript
// This code should not be counted
console.log('hello');
\`\`\`

More content here with [a link](http://example.com) and \`inline code\`.`;

      const metadata = extractor.inferMetadata('test.md', content);

      // Should count words but exclude code blocks and inline code
      expect(metadata.wordCount).toBeGreaterThan(0);
      expect(metadata.wordCount).toBeLessThan(50); // Reasonable range
    });

    it('should count headings correctly', () => {
      const content = `
# Main Title
## Section 1
### Subsection 1.1
## Section 2
### Subsection 2.1
### Subsection 2.2`;

      const metadata = extractor.inferMetadata('test.md', content);

      expect(metadata.headingCount).toBe(6);
    });

    it('should count code blocks correctly', () => {
      const content = `
# Document

Some text.

\`\`\`javascript
console.log('block 1');
\`\`\`

More text with \`inline code\`.

\`\`\`apex
System.debug('block 2');
\`\`\``;

      const metadata = extractor.inferMetadata('test.md', content);

      expect(metadata.codeBlockCount).toBe(3); // 2 blocks + 1 inline
    });

    it('should count links correctly', () => {
      const content = `
# Document

Check out [this link](http://example.com) and also visit https://github.com directly.

Another [link here](http://test.com).`;

      const metadata = extractor.inferMetadata('test.md', content);

      expect(metadata.linkCount).toBe(3);
    });
  });

  describe('validateMetadata', () => {
    it('should validate correct metadata', () => {
      const metadata: InferredMetadata = {
        title: 'Valid Title',
        summary: 'A good summary',
        readingTime: 5,
        tags: ['tag1', 'tag2'],
        difficulty: 'Intermediate',
        frontmatter: {},
        wordCount: 100,
        headingCount: 3,
        codeBlockCount: 1,
        linkCount: 2
      };

      const result = extractor.validateMetadata(metadata);

      expect(result.isValid).toBe(true);
      expect(result.issues).toHaveLength(0);
    });

    it('should detect missing title', () => {
      const metadata: InferredMetadata = {
        title: '',
        readingTime: 5,
        tags: ['tag1'],
        difficulty: 'Intermediate',
        frontmatter: {},
        wordCount: 100,
        headingCount: 3,
        codeBlockCount: 1,
        linkCount: 2
      };

      const result = extractor.validateMetadata(metadata);

      expect(result.isValid).toBe(false);
      expect(result.issues).toContain('Title is required');
    });

    it('should detect title too long', () => {
      const metadata: InferredMetadata = {
        title: 'A'.repeat(300), // Too long
        readingTime: 5,
        tags: ['tag1'],
        difficulty: 'Intermediate',
        frontmatter: {},
        wordCount: 100,
        headingCount: 3,
        codeBlockCount: 1,
        linkCount: 2
      };

      const result = extractor.validateMetadata(metadata);

      expect(result.isValid).toBe(false);
      expect(result.issues).toContain('Title is too long (max 255 characters)');
    });

    it('should warn about missing tags', () => {
      const metadata: InferredMetadata = {
        title: 'Valid Title',
        readingTime: 5,
        tags: [], // No tags
        difficulty: 'Intermediate',
        frontmatter: {},
        wordCount: 100,
        headingCount: 3,
        codeBlockCount: 1,
        linkCount: 2
      };

      const result = extractor.validateMetadata(metadata);

      expect(result.isValid).toBe(true);
      expect(result.warnings).toContain('No tags found - consider adding tags for better categorization');
    });

    it('should warn about too many tags', () => {
      const metadata: InferredMetadata = {
        title: 'Valid Title',
        readingTime: 5,
        tags: Array(15).fill(0).map((_, i) => `tag-${i}`), // Too many tags
        difficulty: 'Intermediate',
        frontmatter: {},
        wordCount: 100,
        headingCount: 3,
        codeBlockCount: 1,
        linkCount: 2
      };

      const result = extractor.validateMetadata(metadata);

      expect(result.isValid).toBe(true);
      expect(result.warnings).toContain('Too many tags (recommended max 10)');
    });

    it('should warn about very long documents', () => {
      const metadata: InferredMetadata = {
        title: 'Valid Title',
        readingTime: 65, // Very long
        tags: ['tag1'],
        difficulty: 'Intermediate',
        frontmatter: {},
        wordCount: 13000,
        headingCount: 3,
        codeBlockCount: 1,
        linkCount: 2
      };

      const result = extractor.validateMetadata(metadata);

      expect(result.isValid).toBe(true);
      expect(result.warnings).toContain('Very long document (over 60 minutes reading time)');
    });
  });
});