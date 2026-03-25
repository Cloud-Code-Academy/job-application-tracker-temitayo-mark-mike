/**
 * Global setup for Jest tests
 */

import * as fs from 'fs';
import * as path from 'path';

export default async function globalSetup() {
  console.log('🚀 Setting up test environment...');
  
  // Create test fixtures directory
  const fixturesDir = path.join(__dirname, 'fixtures');
  if (!fs.existsSync(fixturesDir)) {
    fs.mkdirSync(fixturesDir, { recursive: true });
  }
  
  // Create temp directory for tests
  const tempDir = path.join(fixturesDir, 'temp');
  if (!fs.existsSync(tempDir)) {
    fs.mkdirSync(tempDir, { recursive: true });
  }
  
  // Set environment variables for testing
  process.env.NODE_ENV = 'test';
  process.env.LOG_LEVEL = 'error'; // Reduce log noise
  
  // Create .gitkeep file in fixtures directory
  const gitkeepPath = path.join(fixturesDir, '.gitkeep');
  if (!fs.existsSync(gitkeepPath)) {
    fs.writeFileSync(gitkeepPath, '');
  }
  
  console.log('✅ Test environment setup complete');
}