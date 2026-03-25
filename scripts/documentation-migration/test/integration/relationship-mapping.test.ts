/**
 * Integration tests for relationship mapping functionality
 */

import * as fs from 'fs';
import * as path from 'path';
import { RelationshipMapper } from '../../src/core/RelationshipMapper';
import { LinkMapper } from '../../src/core/LinkMapper';
import { FileScanner } from '../../src/core/FileScanner';
import { MetadataExtractor } from '../../src/core/MetadataExtractor';

describe('Relationship Mapping Integration', () => {
  const testDocsDir = path.join(__dirname, '../fixtures/test-docs');
  const tempDir = path.join(__dirname, '../fixtures/temp');
  
  let relationshipMapper: RelationshipMapper;
  let linkMapper: LinkMapper;
  let fileScanner: FileScanner;
  let metadataExtractor: MetadataExtractor;

  beforeAll(async () => {
    // Create test directory structure
    await createTestDocuments();
    
    linkMapper = new LinkMapper(testDocsDir);
    relationshipMapper = new RelationshipMapper(testDocsDir, linkMapper);
    fileScanner = new FileScanner(testDocsDir);
    metadataExtractor = new MetadataExtractor();
  });

  afterAll(async () => {
    // Clean up test files
    await cleanupTestFiles();
  });

  describe('End-to-End Relationship Analysis', () => {
    it('should analyze relationships in real document structure', async () => {
      // Scan files
      const files = await fileScanner.scanFiles();
      expect(files.length).toBeGreaterThan(0);

      // Extract metadata and content
      const documents = [];
      for (const file of files) {
        const content = fs.readFileSync(file.path, 'utf8');
        const metadata = metadataExtractor.extractMetadata(file.path, content);
        
        documents.push({
          filePath: path.relative(testDocsDir, file.path),
          content,
          metadata
        });
      }

      // Analyze relationships
      const analysis = relationshipMapper.analyzeRelationships(documents);

      expect(analysis.documentGraph).toBeDefined();
      expect(analysis.metrics.totalDocuments).toBe(documents.length);
      expect(analysis.crossReferences).toBeDefined();
      expect(analysis.relatedArticles).toBeDefined();

      // Verify specific relationships exist
      expect(analysis.crossReferences['getting-started.md']).toBeDefined();
      expect(analysis.crossReferences['getting-started.md'].some(
        ref => ref.target === 'api-reference.md'
      )).toBe(true);
    });

    it('should generate relationship report with real data', async () => {
      const files = await fileScanner.scanFiles();
      const documents = [];
      
      for (const file of files) {
        const content = fs.readFileSync(file.path, 'utf8');
        const metadata = metadataExtractor.extractMetadata(file.path, content);
        
        documents.push({
          filePath: path.relative(testDocsDir, file.path),
          content,
          metadata
        });
      }

      relationshipMapper.analyzeRelationships(documents);
      const report = relationshipMapper.generateRelationshipReport();

      expect(report.summary.totalDocuments).toBeGreaterThan(0);
      expect(report.topConnectedDocuments).toBeDefined();
      expect(report.relationshipTypes).toBeDefined();
      expect(report.recommendations).toBeDefined();

      // Verify report structure
      expect(typeof report.summary.averageRelationshipsPerDocument).toBe('number');
      expect(Array.isArray(report.topConnectedDocuments)).toBe(true);
      expect(Array.isArray(report.isolatedDocuments)).toBe(true);
      expect(Array.isArray(report.brokenRelationships)).toBe(true);
    });

    it('should handle link resolution with real file paths', async () => {
      // Add some mappings
      linkMapper.addMapping('getting-started.md', '/knowledge/article/getting-started');
      linkMapper.addMapping('api-reference.md', '/knowledge/article/api-reference');
      linkMapper.addMapping('user-guide.md', '/knowledge/article/user-guide');

      const files = await fileScanner.scanFiles();
      const documents = [];
      
      for (const file of files) {
        const content = fs.readFileSync(file.path, 'utf8');
        const metadata = metadataExtractor.extractMetadata(file.path, content);
        
        documents.push({
          filePath: path.relative(testDocsDir, file.path),
          content,
          metadata
        });
      }

      relationshipMapper.analyzeRelationships(documents);

      // Test related articles content generation
      const relatedContent = relationshipMapper.generateRelatedArticlesContent('getting-started.md');
      
      if (relatedContent) {
        expect(relatedContent).toContain('Related Articles');
        expect(relatedContent).toContain('/knowledge/article/');
      }
    });

    it('should identify and report broken relationships', async () => {
      const files = await fileScanner.scanFiles();
      const documents = [];
      
      for (const file of files) {
        const content = fs.readFileSync(file.path, 'utf8');
        const metadata = metadataExtractor.extractMetadata(file.path, content);
        
        documents.push({
          filePath: path.relative(testDocsDir, file.path),
          content,
          metadata
        });
      }

      relationshipMapper.analyzeRelationships(documents);
      const brokenRelationships = relationshipMapper.findBrokenRelationships();

      // Should find broken links to non-existent files
      expect(brokenRelationships.some(
        broken => broken.targetFile === 'non-existent.md'
      )).toBe(true);

      // Each broken relationship should have required fields
      for (const broken of brokenRelationships) {
        expect(broken.sourceFile).toBeDefined();
        expect(broken.targetFile).toBeDefined();
        expect(broken.referenceType).toBeDefined();
        expect(broken.reason).toBeDefined();
        expect(typeof broken.lineNumber).toBe('number');
      }
    });

    it('should export and import relationship data', async () => {
      const files = await fileScanner.scanFiles();
      const documents = [];
      
      for (const file of files) {
        const content = fs.readFileSync(file.path, 'utf8');
        const metadata = metadataExtractor.extractMetadata(file.path, content);
        
        documents.push({
          filePath: path.relative(testDocsDir, file.path),
          content,
          metadata
        });
      }

      relationshipMapper.analyzeRelationships(documents);
      
      // Export relationship data
      const exportData = relationshipMapper.exportRelationshipData();
      
      expect(exportData.documentGraph).toBeDefined();
      expect(exportData.crossReferences).toBeDefined();
      expect(exportData.relatedArticles).toBeDefined();
      expect(exportData.linkMappings).toBeDefined();
      expect(exportData.generatedAt).toBeDefined();

      // Verify export data can be serialized
      const serialized = JSON.stringify(exportData);
      expect(serialized.length).toBeGreaterThan(0);

      // Verify it can be parsed back
      const parsed = JSON.parse(serialized);
      expect(parsed.generatedAt).toBe(exportData.generatedAt);
    });
  });

  describe('Performance and Scalability', () => {
    it('should handle large document sets efficiently', async () => {
      // Create additional test documents for performance testing
      await createLargeDocumentSet();

      const files = await fileScanner.scanFiles();
      const documents = [];
      
      for (const file of files) {
        const content = fs.readFileSync(file.path, 'utf8');
        const metadata = metadataExtractor.extractMetadata(file.path, content);
        
        documents.push({
          filePath: path.relative(testDocsDir, file.path),
          content,
          metadata
        });
      }

      const startTime = Date.now();
      const analysis = relationshipMapper.analyzeRelationships(documents);
      const endTime = Date.now();

      const processingTime = endTime - startTime;
      const documentsPerSecond = documents.length / (processingTime / 1000);

      expect(analysis.metrics.totalDocuments).toBe(documents.length);
      expect(documentsPerSecond).toBeGreaterThan(1); // Should process at least 1 doc per second
      expect(processingTime).toBeLessThan(30000); // Should complete within 30 seconds
    });

    it('should handle memory efficiently with large content', async () => {
      const initialMemory = process.memoryUsage().heapUsed;

      const files = await fileScanner.scanFiles();
      const documents = [];
      
      for (const file of files) {
        const content = fs.readFileSync(file.path, 'utf8');
        const metadata = metadataExtractor.extractMetadata(file.path, content);
        
        documents.push({
          filePath: path.relative(testDocsDir, file.path),
          content,
          metadata
        });
      }

      relationshipMapper.analyzeRelationships(documents);

      const finalMemory = process.memoryUsage().heapUsed;
      const memoryIncrease = finalMemory - initialMemory;
      const memoryPerDocument = memoryIncrease / documents.length;

      // Memory increase should be reasonable (less than 1MB per document)
      expect(memoryPerDocument).toBeLessThan(1024 * 1024);
    });
  });

  describe('Error Handling and Edge Cases', () => {
    it('should handle corrupted or invalid markdown files', async () => {
      // Create a file with invalid content
      const invalidFile = path.join(testDocsDir, 'invalid.md');
      fs.writeFileSync(invalidFile, 'Invalid markdown with \x00 null bytes and \uFFFD replacement chars');

      const files = await fileScanner.scanFiles();
      const documents = [];
      
      for (const file of files) {
        try {
          const content = fs.readFileSync(file.path, 'utf8');
          const metadata = metadataExtractor.extractMetadata(file.path, content);
          
          documents.push({
            filePath: path.relative(testDocsDir, file.path),
            content,
            metadata
          });
        } catch (error) {
          // Should handle file reading errors gracefully
          console.warn(`Failed to read file ${file.path}: ${error}`);
        }
      }

      expect(() => {
        relationshipMapper.analyzeRelationships(documents);
      }).not.toThrow();

      // Clean up
      fs.unlinkSync(invalidFile);
    });

    it('should handle files with no relationships', async () => {
      // Create an isolated file
      const isolatedFile = path.join(testDocsDir, 'isolated.md');
      fs.writeFileSync(isolatedFile, '# Isolated Document\n\nThis document has no links to other files.');

      const files = await fileScanner.scanFiles();
      const documents = [];
      
      for (const file of files) {
        const content = fs.readFileSync(file.path, 'utf8');
        const metadata = metadataExtractor.extractMetadata(file.path, content);
        
        documents.push({
          filePath: path.relative(testDocsDir, file.path),
          content,
          metadata
        });
      }

      const analysis = relationshipMapper.analyzeRelationships(documents);
      
      expect(analysis.metrics.isolatedDocuments).toBeGreaterThan(0);
      expect(analysis.recommendations.some(rec => 
        rec.includes('isolated documents')
      )).toBe(true);

      // Clean up
      fs.unlinkSync(isolatedFile);
    });
  });

  // Helper functions

  async function createTestDocuments(): Promise<void> {
    // Ensure test directory exists
    if (!fs.existsSync(testDocsDir)) {
      fs.mkdirSync(testDocsDir, { recursive: true });
    }

    // Create getting-started.md
    fs.writeFileSync(path.join(testDocsDir, 'getting-started.md'), `# Getting Started

Welcome to our platform! This guide will help you get up and running quickly.

## Prerequisites

Before you begin, make sure you have read the [User Guide](user-guide.md).

## Quick Start

1. Follow the installation steps
2. Check the [API Reference](api-reference.md) for details
3. See [Advanced Topics](advanced-topics.md) for more information

## Next Steps

- Read about [Best Practices](best-practices.md)
- Check out [Examples](examples.md)
- Review [Troubleshooting](troubleshooting.md)

For more help, see our [FAQ](faq.md) or contact support.

Also check [non-existent.md](non-existent.md) for broken link testing.
`);

    // Create api-reference.md
    fs.writeFileSync(path.join(testDocsDir, 'api-reference.md'), `# API Reference

Complete API documentation for developers.

## Authentication

See [Getting Started](getting-started.md) for authentication setup.

## Endpoints

### Users API

For user management, also see [User Guide](user-guide.md).

### Data API

Advanced usage is covered in [Advanced Topics](advanced-topics.md).

## Examples

Check [Examples](examples.md) for code samples.
`);

    // Create user-guide.md
    fs.writeFileSync(path.join(testDocsDir, 'user-guide.md'), `# User Guide

Comprehensive guide for end users.

## Introduction

This guide complements the [Getting Started](getting-started.md) documentation.

## Features

### Basic Features

Start with [Getting Started](getting-started.md) if you're new.

### Advanced Features

See [Advanced Topics](advanced-topics.md) for detailed information.

## Support

If you need help, check our [FAQ](faq.md) or [Troubleshooting](troubleshooting.md) guide.
`);

    // Create advanced-topics.md
    fs.writeFileSync(path.join(testDocsDir, 'advanced-topics.md'), `# Advanced Topics

Advanced configuration and usage patterns.

## Prerequisites

You should be familiar with the [User Guide](user-guide.md) and [API Reference](api-reference.md).

## Configuration

Advanced configuration options and [Best Practices](best-practices.md).

## Integration

See [Examples](examples.md) for integration patterns.
`);

    // Create supporting files
    const supportingFiles = [
      'best-practices.md',
      'examples.md',
      'troubleshooting.md',
      'faq.md'
    ];

    for (const fileName of supportingFiles) {
      fs.writeFileSync(path.join(testDocsDir, fileName), `# ${fileName.replace('.md', '').replace('-', ' ').replace(/\b\w/g, l => l.toUpperCase())}

This is a supporting document.

Related: [Getting Started](getting-started.md)
`);
    }
  }

  async function createLargeDocumentSet(): Promise<void> {
    // Create additional documents for performance testing
    for (let i = 1; i <= 50; i++) {
      const content = `# Document ${i}

This is document number ${i}.

## Links

- [Document ${i + 1}](doc${i + 1}.md)
- [Document ${i - 1}](doc${i - 1}.md)
- [Getting Started](getting-started.md)

## Content

${'Lorem ipsum dolor sit amet, consectetur adipiscing elit. '.repeat(100)}
`;

      fs.writeFileSync(path.join(testDocsDir, `doc${i}.md`), content);
    }
  }

  async function cleanupTestFiles(): Promise<void> {
    if (fs.existsSync(testDocsDir)) {
      const files = fs.readdirSync(testDocsDir);
      for (const file of files) {
        fs.unlinkSync(path.join(testDocsDir, file));
      }
      fs.rmdirSync(testDocsDir);
    }

    if (fs.existsSync(tempDir)) {
      fs.rmSync(tempDir, { recursive: true, force: true });
    }
  }
});