/**
 * Unit tests for LinkMapper class
 */

import { LinkMapper, MappingReport, MappingValidationResult, BrokenLink } from '../../src/core/LinkMapper';
import * as fs from 'fs';

// Mock fs module
jest.mock('fs');
const mockFs = fs as jest.Mocked<typeof fs>;

describe('LinkMapper', () => {
  let linkMapper: LinkMapper;
  const baseDirectory = '/test/docs';

  beforeEach(() => {
    linkMapper = new LinkMapper(baseDirectory);
    jest.clearAllMocks();
  });

  describe('addMapping and getAllMappings', () => {
    it('should add and retrieve mappings', () => {
      linkMapper.addMapping('docs/guide.md', '/knowledge/article/123');
      linkMapper.addMapping('docs/api.md', '/knowledge/article/456');

      const mappings = linkMapper.getAllMappings();

      expect(mappings['docs/guide.md']).toBe('/knowledge/article/123');
      expect(mappings['docs/api.md']).toBe('/knowledge/article/456');
    });

    it('should normalize paths when adding mappings', () => {
      linkMapper.addMapping('docs\\guide.md', '/knowledge/article/123');
      linkMapper.addMapping('DOCS/API.MD', '/knowledge/article/456');

      const mappings = linkMapper.getAllMappings();

      expect(mappings['docs/guide.md']).toBe('/knowledge/article/123');
      expect(mappings['docs/api.md']).toBe('/knowledge/article/456');
    });

    it('should handle duplicate mappings', () => {
      linkMapper.addMapping('docs/guide.md', '/knowledge/article/123');
      linkMapper.addMapping('docs/guide.md', '/knowledge/article/456'); // Override

      const mappings = linkMapper.getAllMappings();

      expect(mappings['docs/guide.md']).toBe('/knowledge/article/456');
    });
  });

  describe('resolveLink', () => {
    beforeEach(() => {
      linkMapper.addMapping('docs/guide.md', '/knowledge/article/123');
      linkMapper.addMapping('docs/api-reference.md', '/knowledge/article/456');
      linkMapper.addMapping('docs/subfolder/advanced.md', '/knowledge/article/789');
    });

    it('should resolve relative links correctly', () => {
      const result = linkMapper.resolveLink('guide.md', 'docs/index.md');

      expect(result).toBe('/knowledge/article/123');
    });

    it('should resolve links with relative paths', () => {
      const result = linkMapper.resolveLink('../guide.md', 'docs/subfolder/advanced.md');

      expect(result).toBe('/knowledge/article/123');
    });

    it('should resolve links to subdirectories', () => {
      const result = linkMapper.resolveLink('subfolder/advanced.md', 'docs/index.md');

      expect(result).toBe('/knowledge/article/789');
    });

    it('should handle links without .md extension', () => {
      const result = linkMapper.resolveLink('guide', 'docs/index.md');

      expect(result).toBe('/knowledge/article/123');
    });

    it('should return null for unresolvable links', () => {
      const result = linkMapper.resolveLink('nonexistent.md', 'docs/index.md');

      expect(result).toBeNull();
    });

    it('should preserve anchor links', () => {
      const result = linkMapper.resolveLink('#section-1', 'docs/guide.md');

      expect(result).toBe('#section-1');
    });

    it('should handle malformed links gracefully', () => {
      const result = linkMapper.resolveLink('', 'docs/guide.md');

      expect(result).toBeNull();
    });

    it('should perform fuzzy matching for similar paths', () => {
      // This would require implementing fuzzy matching logic
      const result = linkMapper.resolveLink('guid.md', 'docs/index.md'); // Typo in 'guide'

      // Should find the closest match
      expect(result).toBe('/knowledge/article/123');
    });
  });

  describe('getReverseMappings', () => {
    it('should return reverse mappings', () => {
      linkMapper.addMapping('docs/guide.md', '/knowledge/article/123');
      linkMapper.addMapping('docs/api.md', '/knowledge/article/456');

      const reverseMappings = linkMapper.getReverseMappings();

      expect(reverseMappings['/knowledge/article/123']).toBe('docs/guide.md');
      expect(reverseMappings['/knowledge/article/456']).toBe('docs/api.md');
    });
  });

  describe('loadMappings and saveMappings', () => {
    it('should load mappings from JSON file', () => {
      const mockMappings = {
        'docs/guide.md': '/knowledge/article/123',
        'docs/api.md': '/knowledge/article/456'
      };

      mockFs.readFileSync.mockReturnValue(JSON.stringify(mockMappings));

      linkMapper.loadMappings('/test/mappings.json');

      const mappings = linkMapper.getAllMappings();
      expect(mappings['docs/guide.md']).toBe('/knowledge/article/123');
      expect(mappings['docs/api.md']).toBe('/knowledge/article/456');
    });

    it('should save mappings to JSON file', () => {
      linkMapper.addMapping('docs/guide.md', '/knowledge/article/123');
      linkMapper.addMapping('docs/api.md', '/knowledge/article/456');

      linkMapper.saveMappings('/test/mappings.json');

      expect(mockFs.writeFileSync).toHaveBeenCalledWith(
        '/test/mappings.json',
        expect.stringContaining('"docs/guide.md": "/knowledge/article/123"'),
        'utf8'
      );
    });

    it('should throw error when loading invalid JSON', () => {
      mockFs.readFileSync.mockReturnValue('invalid json');

      expect(() => linkMapper.loadMappings('/test/invalid.json'))
        .toThrow('Failed to load mappings');
    });

    it('should throw error when saving fails', () => {
      mockFs.writeFileSync.mockImplementation(() => {
        throw new Error('Write failed');
      });

      expect(() => linkMapper.saveMappings('/test/mappings.json'))
        .toThrow('Failed to save mappings');
    });
  });

  describe('generateMappingReport', () => {
    it('should generate comprehensive mapping report', () => {
      linkMapper.addMapping('docs/guide.md', '/knowledge/article/123');
      linkMapper.addMapping('docs/api.md', '/knowledge/article/456');
      linkMapper.addMapping('docs/subfolder/advanced.md', '/knowledge/article/789');
      linkMapper.addMapping('docs/tutorial.txt', '/knowledge/article/101');

      const report = linkMapper.generateMappingReport();

      expect(report.totalMappings).toBe(4);
      expect(report.mappings).toHaveProperty('docs/guide.md');
      expect(report.statistics.extensionCounts['.md']).toBe(3);
      expect(report.statistics.extensionCounts['.txt']).toBe(1);
      expect(report.statistics.directoryCounts['docs']).toBe(3);
      expect(report.statistics.directoryCounts['docs/subfolder']).toBe(1);
      expect(report.generatedAt).toBeTruthy();
    });

    it('should handle empty mappings', () => {
      const report = linkMapper.generateMappingReport();

      expect(report.totalMappings).toBe(0);
      expect(Object.keys(report.mappings)).toHaveLength(0);
    });
  });

  describe('validateMappings', () => {
    it('should validate correct mappings', () => {
      linkMapper.addMapping('docs/guide.md', '/knowledge/article/123');
      linkMapper.addMapping('docs/api.md', '/knowledge/article/456');

      const result = linkMapper.validateMappings();

      expect(result.isValid).toBe(true);
      expect(result.issues).toHaveLength(0);
      expect(result.totalMappings).toBe(2);
    });

    it('should detect empty paths', () => {
      linkMapper.addMapping('', '/knowledge/article/123');

      const result = linkMapper.validateMappings();

      expect(result.isValid).toBe(false);
      expect(result.issues).toHaveLength(1);
      expect(result.issues[0].type).toBe('empty_path');
    });

    it('should detect empty URLs', () => {
      linkMapper.addMapping('docs/guide.md', '');

      const result = linkMapper.validateMappings();

      expect(result.isValid).toBe(false);
      expect(result.issues).toHaveLength(1);
      expect(result.issues[0].type).toBe('empty_url');
    });

    it('should detect invalid URL formats', () => {
      linkMapper.addMapping('docs/guide.md', 'invalid url with spaces');

      const result = linkMapper.validateMappings();

      expect(result.isValid).toBe(false);
      expect(result.issues).toHaveLength(1);
      expect(result.issues[0].type).toBe('invalid_url');
    });

    it('should warn about duplicate URLs', () => {
      linkMapper.addMapping('docs/guide1.md', '/knowledge/article/123');
      linkMapper.addMapping('docs/guide2.md', '/knowledge/article/123');

      const result = linkMapper.validateMappings();

      expect(result.isValid).toBe(true); // Not an error, just a warning
      expect(result.warnings.length).toBeGreaterThan(0);
      expect(result.warnings[0]).toContain('Multiple paths map to same URL');
    });
  });

  describe('findBrokenLinks', () => {
    beforeEach(() => {
      linkMapper.addMapping('docs/existing.md', '/knowledge/article/123');
    });

    it('should find broken internal links', () => {
      const content = `# Test Document

[Working Link](existing.md)
[Broken Link](nonexistent.md)
[External Link](https://example.com)
[Anchor Link](#section)`;

      const brokenLinks = linkMapper.findBrokenLinks(content, 'docs/index.md');

      expect(brokenLinks).toHaveLength(1);
      expect(brokenLinks[0].href).toBe('nonexistent.md');
      expect(brokenLinks[0].text).toBe('Broken Link');
      expect(brokenLinks[0].sourceFile).toBe('docs/index.md');
      expect(brokenLinks[0].reason).toContain('No mapping found');
    });

    it('should ignore external and anchor links', () => {
      const content = `[External](https://example.com) [Anchor](#section)`;

      const brokenLinks = linkMapper.findBrokenLinks(content, 'docs/index.md');

      expect(brokenLinks).toHaveLength(0);
    });

    it('should handle content without links', () => {
      const content = 'Just plain text without any links.';

      const brokenLinks = linkMapper.findBrokenLinks(content, 'docs/index.md');

      expect(brokenLinks).toHaveLength(0);
    });
  });

  describe('suggestLinkFixes', () => {
    beforeEach(() => {
      linkMapper.addMapping('docs/user-guide.md', '/knowledge/article/123');
      linkMapper.addMapping('docs/API-Reference.md', '/knowledge/article/456');
    });

    it('should suggest fuzzy matches', () => {
      const brokenLink: BrokenLink = {
        text: 'User Guide',
        href: 'user-guid.md', // Typo
        sourceFile: 'docs/index.md',
        position: 0,
        reason: 'No mapping found'
      };

      const suggestions = linkMapper.suggestLinkFixes(brokenLink);

      expect(suggestions.length).toBeGreaterThan(0);
      expect(suggestions[0].type).toBe('fuzzy_match');
      expect(suggestions[0].confidence).toBeGreaterThan(0.7);
    });

    it('should suggest case mismatch fixes', () => {
      const brokenLink: BrokenLink = {
        text: 'API Reference',
        href: 'api-reference.md', // Case mismatch
        sourceFile: 'docs/index.md',
        position: 0,
        reason: 'No mapping found'
      };

      const suggestions = linkMapper.suggestLinkFixes(brokenLink);

      expect(suggestions.length).toBeGreaterThan(0);
      expect(suggestions.some(s => s.type === 'case_mismatch')).toBe(true);
    });

    it('should return empty array for unfixable links', () => {
      const brokenLink: BrokenLink = {
        text: 'Completely Different',
        href: 'totally-unrelated-file.md',
        sourceFile: 'docs/index.md',
        position: 0,
        reason: 'No mapping found'
      };

      const suggestions = linkMapper.suggestLinkFixes(brokenLink);

      expect(suggestions).toHaveLength(0);
    });
  });

  describe('similarity calculation', () => {
    it('should calculate string similarity correctly', () => {
      // Access private method for testing
      const similarity1 = (linkMapper as any).calculateSimilarity('hello', 'hello');
      const similarity2 = (linkMapper as any).calculateSimilarity('hello', 'helo');
      const similarity3 = (linkMapper as any).calculateSimilarity('hello', 'world');

      expect(similarity1).toBe(1); // Identical
      expect(similarity2).toBeGreaterThan(0.8); // Very similar
      expect(similarity3).toBeLessThan(0.5); // Different
    });

    it('should handle empty strings', () => {
      const similarity1 = (linkMapper as any).calculateSimilarity('', '');
      const similarity2 = (linkMapper as any).calculateSimilarity('hello', '');

      expect(similarity1).toBe(1); // Both empty
      expect(similarity2).toBe(0); // One empty
    });
  });

  describe('edge cases', () => {
    it('should handle paths with special characters', () => {
      linkMapper.addMapping('docs/file with spaces.md', '/knowledge/article/123');
      linkMapper.addMapping('docs/file-with-émojis-🚀.md', '/knowledge/article/456');

      const mappings = linkMapper.getAllMappings();

      expect(mappings['docs/file with spaces.md']).toBe('/knowledge/article/123');
      expect(mappings['docs/file-with-émojis-🚀.md']).toBe('/knowledge/article/456');
    });

    it('should handle very long paths', () => {
      const longPath = 'docs/' + 'very-long-path-segment-'.repeat(10) + 'file.md';
      linkMapper.addMapping(longPath, '/knowledge/article/123');

      const result = linkMapper.resolveLink(longPath, 'docs/index.md');

      expect(result).toBe('/knowledge/article/123');
    });

    it('should handle circular references gracefully', () => {
      linkMapper.addMapping('docs/a.md', '/knowledge/article/123');
      linkMapper.addMapping('docs/b.md', '/knowledge/article/456');

      // This shouldn't cause infinite loops
      const result1 = linkMapper.resolveLink('../a.md', 'docs/b.md');
      const result2 = linkMapper.resolveLink('../b.md', 'docs/a.md');

      expect(result1).toBe('/knowledge/article/123');
      expect(result2).toBe('/knowledge/article/456');
    });

    it('should handle malformed file paths', () => {
      expect(() => {
        linkMapper.addMapping('docs//double-slash.md', '/knowledge/article/123');
        linkMapper.addMapping('docs/./dot-slash.md', '/knowledge/article/456');
        linkMapper.addMapping('docs/../parent.md', '/knowledge/article/789');
      }).not.toThrow();

      const mappings = linkMapper.getAllMappings();
      expect(Object.keys(mappings).length).toBe(3);
    });
  });
});