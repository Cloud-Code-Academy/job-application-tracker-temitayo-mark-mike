/**
 * Unit tests for RelationshipMapper class
 */

import { RelationshipMapper, DocumentInfo, CrossReference, RelatedArticle, RelationshipAnalysis } from '../../src/core/RelationshipMapper';
import { LinkMapper } from '../../src/core/LinkMapper';
import { FileMetadata } from '../../src/types';

// Mock LinkMapper
jest.mock('../../src/core/LinkMapper');
const MockLinkMapper = LinkMapper as jest.MockedClass<typeof LinkMapper>;

describe('RelationshipMapper', () => {
  let relationshipMapper: RelationshipMapper;
  let mockLinkMapper: jest.Mocked<LinkMapper>;
  const baseDirectory = '/test/docs';

  beforeEach(() => {
    mockLinkMapper = new MockLinkMapper(baseDirectory) as jest.Mocked<LinkMapper>;
    relationshipMapper = new RelationshipMapper(baseDirectory, mockLinkMapper);
    jest.clearAllMocks();
  });

  const createMockDocument = (
    filePath: string,
    title: string,
    content: string,
    category: string = 'General',
    tags: string[] = []
  ): DocumentInfo => ({
    filePath,
    content,
    metadata: {
      title,
      category,
      tags,
      wordCount: content.split(' ').length,
      readingTime: Math.ceil(content.split(' ').length / 200),
      difficulty: 'Beginner'
    } as FileMetadata
  });

  describe('analyzeRelationships', () => {
    it('should analyze relationships between documents', () => {
      const documents: DocumentInfo[] = [
        createMockDocument(
          'docs/guide.md',
          'User Guide',
          'This is a guide. See [API Reference](api.md) for details.',
          'Documentation',
          ['guide', 'tutorial']
        ),
        createMockDocument(
          'docs/api.md',
          'API Reference',
          'API documentation. Related to [User Guide](guide.md).',
          'Documentation',
          ['api', 'reference']
        ),
        createMockDocument(
          'docs/faq.md',
          'FAQ',
          'Frequently asked questions about the API.',
          'Support',
          ['faq', 'help']
        )
      ];

      const analysis = relationshipMapper.analyzeRelationships(documents);

      expect(analysis).toBeDefined();
      expect(analysis.documentGraph).toBeDefined();
      expect(analysis.crossReferences).toBeDefined();
      expect(analysis.relatedArticles).toBeDefined();
      expect(analysis.metrics).toBeDefined();
      expect(analysis.recommendations).toBeDefined();
    });

    it('should handle empty document list', () => {
      const documents: DocumentInfo[] = [];

      const analysis = relationshipMapper.analyzeRelationships(documents);

      expect(analysis.metrics.totalDocuments).toBe(0);
      expect(analysis.metrics.totalRelationships).toBe(0);
      expect(Object.keys(analysis.crossReferences)).toHaveLength(0);
      expect(Object.keys(analysis.relatedArticles)).toHaveLength(0);
    });

    it('should identify cross-references correctly', () => {
      const documents: DocumentInfo[] = [
        createMockDocument(
          'docs/guide.md',
          'User Guide',
          'See [API Reference](api.md) and check setup.md for installation.'
        ),
        createMockDocument(
          'docs/api.md',
          'API Reference',
          'API documentation.'
        )
      ];

      const analysis = relationshipMapper.analyzeRelationships(documents);

      expect(analysis.crossReferences['docs/guide.md']).toBeDefined();
      expect(analysis.crossReferences['docs/guide.md'].length).toBeGreaterThan(0);
      
      const references = analysis.crossReferences['docs/guide.md'];
      expect(references.some(ref => ref.target === 'api.md')).toBe(true);
      expect(references.some(ref => ref.target === 'setup.md')).toBe(true);
    });

    it('should find related articles based on content similarity', () => {
      const documents: DocumentInfo[] = [
        createMockDocument(
          'docs/auth-guide.md',
          'Authentication Guide',
          'How to authenticate with the API using tokens and OAuth.',
          'Security',
          ['authentication', 'security', 'api']
        ),
        createMockDocument(
          'docs/security-best-practices.md',
          'Security Best Practices',
          'Best practices for API security and authentication.',
          'Security',
          ['security', 'best-practices', 'api']
        ),
        createMockDocument(
          'docs/getting-started.md',
          'Getting Started',
          'Introduction to using our platform.',
          'Tutorial',
          ['tutorial', 'introduction']
        )
      ];

      const analysis = relationshipMapper.analyzeRelationships(documents);

      expect(analysis.relatedArticles['docs/auth-guide.md']).toBeDefined();
      const relatedToAuth = analysis.relatedArticles['docs/auth-guide.md'];
      
      // Should find security best practices as related due to shared category and tags
      expect(relatedToAuth.some(rel => rel.filePath === 'docs/security-best-practices.md')).toBe(true);
      
      // Should have higher relevance score for security doc than getting started
      const securityRelation = relatedToAuth.find(rel => rel.filePath === 'docs/security-best-practices.md');
      const gettingStartedRelation = relatedToAuth.find(rel => rel.filePath === 'docs/getting-started.md');
      
      if (securityRelation && gettingStartedRelation) {
        expect(securityRelation.relevanceScore).toBeGreaterThan(gettingStartedRelation.relevanceScore);
      }
    });
  });

  describe('generateRelatedArticlesContent', () => {
    beforeEach(() => {
      mockLinkMapper.resolveLink.mockImplementation((href, sourceFile) => {
        if (href === 'docs/api.md') return '/knowledge/article/123';
        if (href === 'docs/tutorial.md') return '/knowledge/article/456';
        return null;
      });
    });

    it('should generate HTML content for related articles', () => {
      const documents: DocumentInfo[] = [
        createMockDocument('docs/guide.md', 'User Guide', 'Guide content'),
        createMockDocument('docs/api.md', 'API Reference', 'API content'),
        createMockDocument('docs/tutorial.md', 'Tutorial', 'Tutorial content')
      ];

      relationshipMapper.analyzeRelationships(documents);

      const content = relationshipMapper.generateRelatedArticlesContent('docs/guide.md');

      if (content) {
        expect(content).toContain('<div class="related-articles">');
        expect(content).toContain('<h4>Related Articles</h4>');
        expect(content).toContain('<ul>');
        expect(content).toContain('</ul>');
        expect(content).toContain('</div>');
      }
    });

    it('should return undefined when no related articles exist', () => {
      const documents: DocumentInfo[] = [
        createMockDocument('docs/isolated.md', 'Isolated Document', 'Completely unique content')
      ];

      relationshipMapper.analyzeRelationships(documents);

      const content = relationshipMapper.generateRelatedArticlesContent('docs/isolated.md');

      expect(content).toBeUndefined();
    });

    it('should limit related articles to top 10', () => {
      // Create many related documents
      const documents: DocumentInfo[] = [
        createMockDocument('docs/main.md', 'Main Document', 'Main content', 'Category', ['tag1', 'tag2'])
      ];

      // Add 15 related documents
      for (let i = 1; i <= 15; i++) {
        documents.push(createMockDocument(
          `docs/related${i}.md`,
          `Related Document ${i}`,
          'Related content',
          'Category',
          ['tag1', 'tag2']
        ));
      }

      relationshipMapper.analyzeRelationships(documents);

      const content = relationshipMapper.generateRelatedArticlesContent('docs/main.md');

      if (content) {
        // Count the number of <li> elements (should be max 10)
        const liCount = (content.match(/<li>/g) || []).length;
        expect(liCount).toBeLessThanOrEqual(10);
      }
    });
  });

  describe('findBrokenRelationships', () => {
    it('should identify broken internal links', () => {
      const documents: DocumentInfo[] = [
        createMockDocument(
          'docs/guide.md',
          'User Guide',
          'See [Missing File](missing.md) and [Another Missing](nonexistent.md).'
        )
      ];

      relationshipMapper.analyzeRelationships(documents);

      const brokenRelationships = relationshipMapper.findBrokenRelationships();

      expect(brokenRelationships.length).toBeGreaterThan(0);
      expect(brokenRelationships[0].sourceFile).toBe('docs/guide.md');
      expect(brokenRelationships[0].referenceType).toBe('internal_link');
      expect(brokenRelationships[0].reason).toContain('Target file not found');
    });

    it('should return empty array when no broken relationships exist', () => {
      const documents: DocumentInfo[] = [
        createMockDocument(
          'docs/guide.md',
          'User Guide',
          'See [API Reference](api.md).'
        ),
        createMockDocument(
          'docs/api.md',
          'API Reference',
          'API documentation.'
        )
      ];

      relationshipMapper.analyzeRelationships(documents);

      const brokenRelationships = relationshipMapper.findBrokenRelationships();

      expect(brokenRelationships).toHaveLength(0);
    });
  });

  describe('generateRelationshipReport', () => {
    it('should generate comprehensive relationship report', () => {
      const documents: DocumentInfo[] = [
        createMockDocument(
          'docs/guide.md',
          'User Guide',
          'See [API Reference](api.md).',
          'Documentation',
          ['guide']
        ),
        createMockDocument(
          'docs/api.md',
          'API Reference',
          'API documentation.',
          'Documentation',
          ['api']
        ),
        createMockDocument(
          'docs/isolated.md',
          'Isolated Document',
          'No links to other documents.',
          'Other',
          ['isolated']
        )
      ];

      relationshipMapper.analyzeRelationships(documents);

      const report = relationshipMapper.generateRelationshipReport();

      expect(report.summary).toBeDefined();
      expect(report.summary.totalDocuments).toBe(3);
      expect(report.topConnectedDocuments).toBeDefined();
      expect(report.isolatedDocuments).toBeDefined();
      expect(report.brokenRelationships).toBeDefined();
      expect(report.relationshipTypes).toBeDefined();
      expect(report.recommendations).toBeDefined();

      // Should identify isolated document
      expect(report.isolatedDocuments).toContain('docs/isolated.md');
    });

    it('should provide recommendations based on analysis', () => {
      const documents: DocumentInfo[] = [
        // Create many isolated documents to trigger recommendations
        ...Array.from({ length: 10 }, (_, i) => 
          createMockDocument(
            `docs/isolated${i}.md`,
            `Isolated Document ${i}`,
            `Unique content ${i}`,
            `Category${i}`,
            [`tag${i}`]
          )
        )
      ];

      relationshipMapper.analyzeRelationships(documents);

      const report = relationshipMapper.generateRelationshipReport();

      expect(report.recommendations.length).toBeGreaterThan(0);
      expect(report.recommendations.some(rec => 
        rec.includes('isolated documents')
      )).toBe(true);
    });
  });

  describe('updateRelationshipsPostMigration', () => {
    it('should update link mappings after successful migration', () => {
      const migrationResults = [
        {
          success: true,
          filePath: 'docs/guide.md',
          articleId: 'ka123456789',
          title: 'User Guide'
        },
        {
          success: true,
          filePath: 'docs/api.md',
          articleId: 'ka987654321',
          title: 'API Reference'
        },
        {
          success: false,
          filePath: 'docs/failed.md',
          error: 'Migration failed'
        }
      ];

      relationshipMapper.updateRelationshipsPostMigration(migrationResults);

      // Should call addMapping for successful migrations
      expect(mockLinkMapper.addMapping).toHaveBeenCalledWith(
        'docs/guide.md',
        '/lightning/r/Knowledge__kav/ka123456789/view'
      );
      expect(mockLinkMapper.addMapping).toHaveBeenCalledWith(
        'docs/api.md',
        '/lightning/r/Knowledge__kav/ka987654321/view'
      );

      // Should not call addMapping for failed migrations
      expect(mockLinkMapper.addMapping).not.toHaveBeenCalledWith(
        'docs/failed.md',
        expect.any(String)
      );
    });
  });

  describe('exportRelationshipData', () => {
    it('should export all relationship data', () => {
      const documents: DocumentInfo[] = [
        createMockDocument('docs/guide.md', 'User Guide', 'Guide content'),
        createMockDocument('docs/api.md', 'API Reference', 'API content')
      ];

      relationshipMapper.analyzeRelationships(documents);

      mockLinkMapper.getAllMappings.mockReturnValue({
        'docs/guide.md': '/knowledge/article/123',
        'docs/api.md': '/knowledge/article/456'
      });

      const exportData = relationshipMapper.exportRelationshipData();

      expect(exportData.documentGraph).toBeDefined();
      expect(exportData.crossReferences).toBeDefined();
      expect(exportData.relatedArticles).toBeDefined();
      expect(exportData.linkMappings).toBeDefined();
      expect(exportData.generatedAt).toBeDefined();
      expect(new Date(exportData.generatedAt)).toBeInstanceOf(Date);
    });
  });

  describe('edge cases and error handling', () => {
    it('should handle documents with no content', () => {
      const documents: DocumentInfo[] = [
        createMockDocument('docs/empty.md', 'Empty Document', '')
      ];

      expect(() => {
        relationshipMapper.analyzeRelationships(documents);
      }).not.toThrow();
    });

    it('should handle documents with malformed markdown links', () => {
      const documents: DocumentInfo[] = [
        createMockDocument(
          'docs/malformed.md',
          'Malformed Links',
          'Bad link: [text](incomplete and [another]()'
        )
      ];

      expect(() => {
        relationshipMapper.analyzeRelationships(documents);
      }).not.toThrow();
    });

    it('should handle circular references gracefully', () => {
      const documents: DocumentInfo[] = [
        createMockDocument(
          'docs/a.md',
          'Document A',
          'See [Document B](b.md)'
        ),
        createMockDocument(
          'docs/b.md',
          'Document B',
          'See [Document A](a.md)'
        )
      ];

      expect(() => {
        relationshipMapper.analyzeRelationships(documents);
      }).not.toThrow();

      const analysis = relationshipMapper.analyzeRelationships(documents);
      expect(analysis.metrics.totalDocuments).toBe(2);
    });

    it('should handle very large document sets efficiently', () => {
      // Create a large number of documents
      const documents: DocumentInfo[] = Array.from({ length: 100 }, (_, i) => 
        createMockDocument(
          `docs/doc${i}.md`,
          `Document ${i}`,
          `Content for document ${i}. See [Document ${(i + 1) % 100}](doc${(i + 1) % 100}.md).`
        )
      );

      const startTime = Date.now();
      const analysis = relationshipMapper.analyzeRelationships(documents);
      const endTime = Date.now();

      expect(analysis.metrics.totalDocuments).toBe(100);
      expect(endTime - startTime).toBeLessThan(5000); // Should complete within 5 seconds
    });

    it('should handle special characters in file paths and content', () => {
      const documents: DocumentInfo[] = [
        createMockDocument(
          'docs/special-chars-éñ.md',
          'Special Characters Document',
          'Content with émojis 🚀 and [link to file](other-file-ñ.md)'
        )
      ];

      expect(() => {
        relationshipMapper.analyzeRelationships(documents);
      }).not.toThrow();
    });
  });

  describe('relationship scoring and ranking', () => {
    it('should score relationships based on multiple factors', () => {
      const documents: DocumentInfo[] = [
        createMockDocument(
          'docs/main.md',
          'Main Document',
          'Main content about authentication and security',
          'Security',
          ['auth', 'security', 'api']
        ),
        createMockDocument(
          'docs/same-category.md',
          'Same Category Document',
          'Different content but same category',
          'Security',
          ['different', 'tags']
        ),
        createMockDocument(
          'docs/shared-tags.md',
          'Shared Tags Document',
          'Content about authentication',
          'Different Category',
          ['auth', 'security']
        ),
        createMockDocument(
          'docs/content-similar.md',
          'Content Similar Document',
          'Content about authentication and security practices',
          'Different Category',
          ['different', 'tags']
        )
      ];

      const analysis = relationshipMapper.analyzeRelationships(documents);
      const relatedToMain = analysis.relatedArticles['docs/main.md'];

      if (relatedToMain && relatedToMain.length > 0) {
        // Should be sorted by relevance score
        for (let i = 1; i < relatedToMain.length; i++) {
          expect(relatedToMain[i - 1].relevanceScore).toBeGreaterThanOrEqual(
            relatedToMain[i].relevanceScore
          );
        }

        // Document with same category and shared tags should have high score
        const sharedTagsDoc = relatedToMain.find(rel => rel.filePath === 'docs/shared-tags.md');
        if (sharedTagsDoc) {
          expect(sharedTagsDoc.relevanceScore).toBeGreaterThan(0.3);
        }
      }
    });
  });
});