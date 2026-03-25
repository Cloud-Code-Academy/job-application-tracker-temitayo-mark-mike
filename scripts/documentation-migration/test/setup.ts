/**
 * Jest setup file for all tests
 */

// Increase timeout for all tests
jest.setTimeout(30000);

// Mock console methods to reduce noise in tests
const originalConsoleLog = console.log;
const originalConsoleWarn = console.warn;
const originalConsoleError = console.error;

// Only show console output in verbose mode
if (!process.env.VERBOSE_TESTS) {
  console.log = jest.fn();
  console.warn = jest.fn();
  console.error = jest.fn();
}

// Global test utilities
global.testUtils = {
  restoreConsole: () => {
    console.log = originalConsoleLog;
    console.warn = originalConsoleWarn;
    console.error = originalConsoleError;
  },
  
  mockConsole: () => {
    console.log = jest.fn();
    console.warn = jest.fn();
    console.error = jest.fn();
  },
  
  // Helper to create temporary directories
  createTempDir: (baseName: string): string => {
    const path = require('path');
    const fs = require('fs');
    const tempDir = path.join(__dirname, 'fixtures', 'temp', `${baseName}-${Date.now()}`);
    
    if (!fs.existsSync(tempDir)) {
      fs.mkdirSync(tempDir, { recursive: true });
    }
    
    return tempDir;
  },
  
  // Helper to clean up temporary directories
  cleanupTempDir: (tempDir: string): void => {
    const fs = require('fs');
    if (fs.existsSync(tempDir)) {
      fs.rmSync(tempDir, { recursive: true, force: true });
    }
  },
  
  // Helper to wait for a specified time
  wait: (ms: number): Promise<void> => {
    return new Promise(resolve => setTimeout(resolve, ms));
  },
  
  // Helper to generate random strings
  randomString: (length: number = 10): string => {
    return Math.random().toString(36).substring(2, 2 + length);
  }
};

// Extend Jest matchers
expect.extend({
  toBeWithinRange(received: number, floor: number, ceiling: number) {
    const pass = received >= floor && received <= ceiling;
    if (pass) {
      return {
        message: () => `expected ${received} not to be within range ${floor} - ${ceiling}`,
        pass: true,
      };
    } else {
      return {
        message: () => `expected ${received} to be within range ${floor} - ${ceiling}`,
        pass: false,
      };
    }
  },
  
  toHaveBeenCalledWithObjectContaining(received: jest.Mock, expected: any) {
    const calls = received.mock.calls;
    const pass = calls.some(call => 
      call.some(arg => 
        typeof arg === 'object' && 
        Object.keys(expected).every(key => arg[key] === expected[key])
      )
    );
    
    if (pass) {
      return {
        message: () => `expected mock not to have been called with object containing ${JSON.stringify(expected)}`,
        pass: true,
      };
    } else {
      return {
        message: () => `expected mock to have been called with object containing ${JSON.stringify(expected)}`,
        pass: false,
      };
    }
  }
});

// Global error handler for unhandled promises
process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled Rejection at:', promise, 'reason:', reason);
});

// Clean up after each test
afterEach(() => {
  // Clear all mocks
  jest.clearAllMocks();
  
  // Reset modules
  jest.resetModules();
});

// Global teardown
afterAll(() => {
  // Restore console
  if (global.testUtils) {
    global.testUtils.restoreConsole();
  }
});