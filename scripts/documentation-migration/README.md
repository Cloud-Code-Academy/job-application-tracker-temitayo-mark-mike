# Salesforce Documentation Migrator

Automated tool to migrate markdown documentation files to Salesforce Knowledge Base articles.

## Features

- 🚀 **Automated Migration**: Convert all markdown files to Knowledge articles with one command
- 🏷️ **Smart Categorization**: Automatically categorizes articles based on content and filename patterns
- 🔗 **Link Preservation**: Maintains cross-references and document relationships
- ⏯️ **Resumable Process**: Can be interrupted and resumed without losing progress
- 📊 **Comprehensive Reporting**: Detailed migration reports with statistics and URL mappings
- 🛡️ **Error Handling**: Robust error handling with retry logic and detailed logging

## Installation

```bash
cd scripts/documentation-migration
npm install
npm run build
```

## Configuration

1. Copy the example environment file:
```bash
cp .env.example .env
```

2. Update the `.env` file with your Salesforce credentials:
```env
SF_USERNAME=your-username@example.com
SF_PASSWORD=your-password
SF_SECURITY_TOKEN=your-security-token
```

## Usage

### Basic Migration
```bash
npm run dev migrate --source ./docs
```

### Dry Run (Preview Only)
```bash
npm run dev migrate --source ./docs --dry-run
```

### Resume Interrupted Migration
```bash
npm run dev resume
```

### Generate Configuration File
```bash
npm run dev init-config
```

## Development

### Build
```bash
npm run build
```

### Test
```bash
npm test
npm run test:coverage
```

### Lint
```bash
npm run lint
npm run lint:fix
```

## Project Structure

```
src/
├── core/           # Core migration classes
├── config/         # Configuration management
├── types/          # TypeScript type definitions
├── utils/          # Utility functions
└── cli.ts          # Command-line interface

test/
├── fixtures/       # Test data
├── unit/           # Unit tests
└── integration/    # Integration tests
```

## License

MIT