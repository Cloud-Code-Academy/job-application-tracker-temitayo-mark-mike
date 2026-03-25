---
title: Large Document for Performance Testing
category: Performance
tags: [performance, large, testing]
difficulty: Intermediate
---

# Large Document for Performance Testing

This is a large document designed to test performance with substantial content.

## Introduction

${'This is a paragraph with substantial content that repeats to create a large document. '.repeat(50)}

## Code Blocks

Here's a large code block:

```javascript
// Large JavaScript code block for testing
class LargeClass {
  constructor() {
    this.data = [];
    this.initialized = false;
  }

${Array.from({ length: 100 }, (_, i) => `  method${i}() {
    console.log('Method ${i} called');
    return this.data.filter(item => item.id === ${i});
  }`).join('\n\n')}
}

// Usage example
const instance = new LargeClass();
${Array.from({ length: 50 }, (_, i) => `instance.method${i}();`).join('\n')}
```

## Large Table

| Column 1 | Column 2 | Column 3 | Column 4 | Column 5 | Column 6 |
|----------|----------|----------|----------|----------|----------|
${Array.from({ length: 100 }, (_, i) => `| Row ${i} Col 1 | Row ${i} Col 2 | Row ${i} Col 3 | Row ${i} Col 4 | Row ${i} Col 5 | Row ${i} Col 6 |`).join('\n')}

## Many Links

This section contains many links to test link processing performance:

${Array.from({ length: 50 }, (_, i) => `[Link ${i}](document-${i}.md)`).join(' ')}

## Repeated Content Sections

${Array.from({ length: 20 }, (_, i) => `### Section ${i}

This is section ${i} with substantial content. ${'Lorem ipsum dolor sit amet, consectetur adipiscing elit. '.repeat(20)}

#### Subsection ${i}.1

More content for subsection ${i}.1. ${'Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. '.repeat(15)}

#### Subsection ${i}.2

Additional content for subsection ${i}.2. ${'Ut enim ad minim veniam, quis nostrud exercitation ullamco. '.repeat(15)}

`).join('\n')}

## Images

${Array.from({ length: 10 }, (_, i) => `![Image ${i}](images/image-${i}.png)`).join('\n')}

## Conclusion

${'This concludes the large document used for performance testing. '.repeat(30)}

---

*This document contains approximately ${(50 + 100 * 20 + 100 * 6 + 50 + 20 * (20 + 15 + 15) + 30)} words for performance testing.*