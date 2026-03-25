/**
 * Global teardown for Jest tests
 */

import * as fs from 'fs';
import * as path from 'path';

export default async function globalTeardown() {
  console.log('🧹 Cleaning up test environment...');
  
  // Clean up temporary test files
  const tempDir = path.join(__dirname, 'fixtures', 'temp');
  if (fs.existsSync(tempDir)) {
    try {
      fs.rmSync(tempDir, { recursive: true, force: true });
    } catch (error) {
      console.warn('Warning: Could not clean up temp directory:', error);
    }
  }
  
  // Clean up any test artifacts
  const testArtifacts = [
    path.join(__dirname, '..', 'test-results'),
    path.join(__dirname, '..', '.migration-progress.json'),
    path.join(__dirname, '..', 'migration-report-*.json')
  ];
  
  for (const artifact of testArtifacts) {
    if (artifact.includes('*')) {
      // Handle glob patterns
      const dir = path.dirname(artifact);
      const pattern = path.basename(artifact);
      
      if (fs.existsSync(dir)) {
        const files = fs.readdirSync(dir);
        const matchingFiles = files.filter(file => 
          file.match(pattern.replace('*', '.*'))
        );
        
        for (const file of matchingFiles) {
          try {
            fs.unlinkSync(path.join(dir, file));
          } catch (error) {
            console.warn(`Warning: Could not clean up ${file}:`, error);
          }
        }
      }
    } else if (fs.existsSync(artifact)) {
      try {
        if (fs.statSync(artifact).isDirectory()) {
          fs.rmSync(artifact, { recursive: true, force: true });
        } else {
          fs.unlinkSync(artifact);
        }
      } catch (error) {
        console.warn(`Warning: Could not clean up ${artifact}:`, error);
      }
    }
  }
  
  console.log('✅ Test environment cleanup complete');
}