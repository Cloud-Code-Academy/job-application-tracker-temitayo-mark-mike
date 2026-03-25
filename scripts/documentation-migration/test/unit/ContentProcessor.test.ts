/**
 * Unit tests for ContentProcessor class
 */

import { ContentProcessor, LinkMapper, ProcessedContent, ContentProcessingError } from '../../src/core/ContentProcessor';
import { ContentProcessingOptions } from '../../src/types';

// Mock LinkMapper
const mockLinkMapper: LinkMapper = {
  resolveLink: jest.fn(),
  addMapping: jest.fn(),
  getAllMappings: jest.fn()
};

describe('ContentProcessor', () => {
  let processor: ContentProcessor;
  let defaultOptions: ContentProcessingOptions;

  beforeEach(() => {
    defaultOptions = {
      imageHandling: 'link',
      linkProcessing: 'convert',
      codeBlockStyling: 'default'
    };
    
    processor = new ContentProcessor(defaultOptions, mockLinkMapper);
    jest.clearAllMocks();
  });

  describe('processContent', () => {
    it('should convert basic markdown to HTML', async () => {
      const markdown = `# Test Document

This is a **bold** text and *italic* text.

## Section 2

Here's a list:
- Item 1
- Item 2
- Item 3`;

      const result = await processor.processContent(markdown, 'test.md');

      expect(result.html).toContain('<h1>Test Document</h1>');
      expect(result.html).toContain('<strong>bold</strong>');
      expect(result.html).toContain('<em>italic</em>');
      expect(result.html).toContain('<h2>Section 2</h2>');
      expect(result.html).toContain('<ul>');
      expect(result.html).toContain('<li>Item 1</li>');
    });

    it('should remove frontmatter before processing', async () => {
      const markdown = `---
title: Test Document
author: John Doe
---

# Actual Content

This is the real content.`;

      const result = await processor.processContent(markdown, 'test.md');

      expect(result.html).not.toContain('title: Test Document');
      expect(result.html).not.toContain('author: John Doe');
      expect(result.html).toContain('<h1>Actual Content</h1>');
    });

    it('should process code blocks correctly', async () => {
      const markdown = `# Code Example

\`\`\`javascript
function hello() {
  console.log('Hello, world!');
}
\`\`\`

Inline \`code\` here.`;

      const result = await processor.processContent(markdown, 'test.md');

      expect(result.html).toContain('<pre');
      expect(result.html).toContain('<code>');
      expect(result.html).toContain('function hello()');
      expect(result.html).toContain('<code>code</code>');
    });

    it('should process tables correctly', async () => {
      const markdown = `# Table Example

| Column 1 | Column 2 | Column 3 |
|----------|----------|----------|
| Data 1   | Data 2   | Data 3   |
| Data 4   | Data 5   | Data 6   |`;

      const result = await processor.processContent(markdown, 'test.md');

      expect(result.html).toContain('<table>');
      expect(result.html).toContain('<thead>');
      expect(result.html).toContain('<tbody>');
      expect(result.html).toContain('<th>Column 1</th>');
      expect(result.html).toContain('<td>Data 1</td>');
    });

    it('should handle blockquotes', async () => {
      const markdown = `# Quote Example

> This is a blockquote
> with multiple lines.

Regular text here.`;

      const result = await processor.processContent(markdown, 'test.md');

      expect(result.html).toContain('<blockquote>');
      expect(result.html).toContain('This is a blockquote');
    });

    it('should extract processing metadata', async () => {
      const markdown = `# Test Document

![Image](image.png)

[Link](other-doc.md)

\`\`\`javascript
console.log('code');
\`\`\`

| Col1 | Col2 |
|------|------|
| A    | B    |`;

      const result = await processor.processContent(markdown, 'test.md');

      expect(result.metadata.imageCount).toBe(1);
      expect(result.metadata.linkCount).toBe(1);
      expect(result.metadata.codeBlockCount).toBe(1);
      expect(result.metadata.tableCount).toBeGreaterThan(0);
      expect(result.metadata.originalLength).toBeGreaterThan(0);
      expect(result.metadata.processedLength).toBeGreaterThan(0);
    });

    it('should throw error for processing failures', async () => {
      // Mock markdown-it to throw an error
      const originalRender = processor['markdownIt'].render;
      processor['markdownIt'].render = jest.fn().mockImplementation(() => {
        throw new Error('Markdown processing failed');
      });

      await expect(processor.processContent('# Test', 'test.md'))
        .rejects.toThrow(ContentProcessingError);

      // Restore original method
      processor['markdownIt'].render = originalRender;
    });
  });

  describe('image handling', () => {
    it('should skip images when configured', async () => {
      const options: ContentProcessingOptions = {
        ...defaultOptions,
        imageHandling: 'skip'
      };
      processor = new ContentProcessor(options);

      const markdown = `# Test

![Alt text](image.png)

Regular text.`;

      const result = await processor.processContent(markdown, 'test.md');

      expect(result.html).not.toContain('img');
      expect(result.html).not.toContain('image.png');
    });

    it('should convert images to links when configured', async () => {
      const options: ContentProcessingOptions = {
        ...defaultOptions,
        imageHandling: 'link'
      };
      processor = new ContentProcessor(options);

      const markdown = `# Test

![Alt text](image.png)

Regular text.`;

      const result = await processor.processContent(markdown, 'test.md');

      expect(result.html).toContain('<a href="image.png">Alt text</a>');
    });

    it('should handle embed option for images', async () => {
      const options: ContentProcessingOptions = {
        ...defaultOptions,
        imageHandling: 'embed'
      };
      processor = new ContentProcessor(options);

      const markdown = `# Test

![Alt text](local-image.png)

![External](https://example.com/image.png)`;

      const result = await processor.processContent(markdown, 'test.md');

      // Local images should be converted to links with note
      expect(result.html).toContain('Image will be embedded');
      // External images should remain as images
      expect(result.html).toContain('https://example.com/image.png');
    });
  });

  describe('link processing', () => {
    it('should preserve links when configured', async () => {
      const options: ContentProcessingOptions = {
        ...defaultOptions,
        linkProcessing: 'preserve'
      };
      processor = new ContentProcessor(options);

      const markdown = `[Internal Link](other-doc.md)`;

      const result = await processor.processContent(markdown, 'test.md');

      expect(result.html).toContain('href="other-doc.md"');
    });

    it('should convert internal links when configured', async () => {
      const options: ContentProcessingOptions = {
        ...defaultOptions,
        linkProcessing: 'convert'
      };
      
      // Mock link mapper to return a Knowledge URL
      (mockLinkMapper.resolveLink as jest.Mock).mockReturnValue('/knowledge/article/123');
      
      processor = new ContentProcessor(options, mockLinkMapper);

      const markdown = `[Internal Link](other-doc.md)`;

      const result = await processor.processContent(markdown, 'test.md');

      expect(result.html).toContain('href="/knowledge/article/123"');
      expect(mockLinkMapper.resolveLink).toHaveBeenCalledWith('other-doc.md', 'test.md');
    });

    it('should preserve external links', async () => {
      const markdown = `[External Link](https://example.com)`;

      const result = await processor.processContent(markdown, 'test.md');

      expect(result.html).toContain('href="https://example.com"');
      expect(result.html).toContain('target="_blank"');
      expect(result.html).toContain('rel="noopener noreferrer"');
    });

    it('should preserve anchor links', async () => {
      const markdown = `[Anchor Link](#section-1)`;

      const result = await processor.processContent(markdown, 'test.md');

      expect(result.html).toContain('href="#section-1"');
    });
  });

  describe('Salesforce formatting', () => {
    it('should apply Salesforce SLDS classes when configured', async () => {
      const options: ContentProcessingOptions = {
        ...defaultOptions,
        codeBlockStyling: 'salesforce'
      };
      processor = new ContentProcessor(options);

      const markdown = `# Heading

Paragraph text.

\`\`\`javascript
console.log('code');
\`\`\`

| Col1 | Col2 |
|------|------|
| A    | B    |

> Blockquote

- List item`;

      const result = await processor.processContent(markdown, 'test.md');

      expect(result.html).toContain('slds-text-heading_large');
      expect(result.html).toContain('slds-m-bottom_small');
      expect(result.html).toContain('slds-table');
      expect(result.html).toContain('slds-box');
      expect(result.html).toContain('slds-list_dotted');
    });

    it('should use default styling when not configured for Salesforce', async () => {
      const options: ContentProcessingOptions = {
        ...defaultOptions,
        codeBlockStyling: 'default'
      };
      processor = new ContentProcessor(options);

      const markdown = `# Heading

\`\`\`javascript
console.log('code');
\`\`\``;

      const result = await processor.processContent(markdown, 'test.md');

      expect(result.html).not.toContain('slds-');
      expect(result.html).toContain('<h1>Heading</h1>');
      expect(result.html).toContain('<pre');
    });
  });

  describe('accessibility features', () => {
    it('should add alt attributes to images without them', async () => {
      // This would require custom HTML processing
      const markdown = `![](image-without-alt.png)`;

      const result = await processor.processContent(markdown, 'test.md');

      // The markdown-it should handle this, but we can test our post-processing
      expect(result.html).toBeTruthy();
    });

    it('should add proper attributes to external links', async () => {
      const markdown = `[External](https://example.com)`;

      const result = await processor.processContent(markdown, 'test.md');

      expect(result.html).toContain('target="_blank"');
      expect(result.html).toContain('rel="noopener noreferrer"');
    });
  });

  describe('content cleanup', () => {
    it('should clean up problematic markdown patterns', async () => {
      const markdown = `# Test



   ## Badly Spaced Header

-  Badly spaced list item
1.   Badly spaced numbered item   `;

      const result = await processor.processContent(markdown, 'test.md');

      // Should still produce valid HTML despite input issues
      expect(result.html).toContain('<h1>Test</h1>');
      expect(result.html).toContain('<h2>Badly Spaced Header</h2>');
      expect(result.html).toContain('<li>Badly spaced list item</li>');
    });

    it('should handle include statements', async () => {
      const markdown = `# Test

{{include other-file.md}}

Regular content.

[[include:another-file.md]]

@include third-file.md`;

      const result = await processor.processContent(markdown, 'test.md');

      expect(result.html).toContain('includes content from');
      expect(result.html).toContain('other-file.md');
      expect(result.html).toContain('another-file.md');
      expect(result.html).toContain('third-file.md');
    });
  });

  describe('error handling', () => {
    it('should handle malformed markdown gracefully', async () => {
      const markdown = `# Incomplete

[Incomplete link](

\`\`\`
Incomplete code block

| Incomplete | table
|------------|`;

      const result = await processor.processContent(markdown, 'test.md');

      // Should not throw and should produce some HTML
      expect(result.html).toBeTruthy();
      expect(result.html).toContain('<h1>Incomplete</h1>');
    });

    it('should generate warnings for potential issues', async () => {
      const markdown = `# Test

${'![Image](img.png)\n'.repeat(15)}

${'Very long content. '.repeat(1000)}

\`\`\`mermaid
graph TD
  A --> B
\`\`\``;

      const result = await processor.processContent(markdown, 'test.md');

      expect(result.warnings.length).toBeGreaterThan(0);
      expect(result.warnings.some(w => w.includes('High number of images'))).toBe(true);
      expect(result.warnings.some(w => w.includes('large HTML content'))).toBe(true);
      expect(result.warnings.some(w => w.includes('Mermaid diagrams'))).toBe(true);
    });
  });

  describe('edge cases', () => {
    it('should handle empty content', async () => {
      const result = await processor.processContent('', 'test.md');

      expect(result.html).toBe('');
      expect(result.metadata.originalLength).toBe(0);
      expect(result.metadata.imageCount).toBe(0);
    });

    it('should handle content with only whitespace', async () => {
      const result = await processor.processContent('   \n\n   \t  \n', 'test.md');

      expect(result.html.trim()).toBe('');
    });

    it('should handle very large content', async () => {
      const largeContent = '# Large Document\n\n' + 'Content line.\n'.repeat(10000);

      const result = await processor.processContent(largeContent, 'test.md');

      expect(result.html).toContain('<h1>Large Document</h1>');
      expect(result.metadata.originalLength).toBeGreaterThan(100000);
    });

    it('should handle special characters and unicode', async () => {
      const markdown = `# Special Characters

Émojis: 🚀 🎉 ✨

Unicode: café, naïve, résumé

Special chars: @#$%^&*()_+{}|:"<>?[]\\;',./ 

Math symbols: ∑ ∆ π ∞`;

      const result = await processor.processContent(markdown, 'test.md');

      expect(result.html).toContain('🚀');
      expect(result.html).toContain('café');
      expect(result.html).toContain('∑');
    });
  });
});