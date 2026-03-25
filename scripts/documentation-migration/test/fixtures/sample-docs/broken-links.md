---
title: Document with Broken Links
category: Test
tags: [test, broken-links]
difficulty: Beginner
---

# Document with Broken Links

This document contains various types of broken links for testing.

## Internal Broken Links

- [Non-existent file](non-existent.md)
- [Another missing file](../missing/file.md)
- [Broken relative link](./broken/path.md)

## Working Links

- [Getting Started](getting-started.md) - This should work
- [API Reference](api-reference.md) - This should also work

## Mixed Content

Some text with [broken link](missing-doc.md) and [working link](troubleshooting.md).

## External Links (should be preserved)

- [Google](https://google.com)
- [GitHub](https://github.com)

## Anchor Links

- [Section 1](#section-1)
- [Non-existent anchor](#non-existent-anchor)

### Section 1

This section exists for the anchor link test.