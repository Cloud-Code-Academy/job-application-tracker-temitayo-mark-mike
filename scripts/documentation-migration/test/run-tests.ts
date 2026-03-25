#!/usr/bin/env ts-node

/**
 * Comprehensive test runner with reporting and analysis
 */

import { execSync } from 'child_process';
import * as fs from 'fs';
import * as path from 'path';
import chalk from 'chalk';

interface TestSuite {
  name: string;
  command: string;
  timeout: number;
  description: string;
}

interface TestResult {
  suite: string;
  success: boolean;
  duration: number;
  output: string;
  error?: string;
}

class TestRunner {
  private results: TestResult[] = [];
  private startTime: number = 0;

  private testSuites: TestSuite[] = [
    {
      name: 'Unit Tests',
      command: 'npm run test:unit',
      timeout: 60000,
      description: 'Fast unit tests for individual components'
    },
    {
      name: 'Integration Tests',
      command: 'npm run test:integration',
      timeout: 120000,
      description: 'Integration tests for component interactions'
    },
    {
      name: 'Performance Tests',
      command: 'npm run test:performance',
      timeout: 300000,
      description: 'Performance and scalability tests'
    }
  ];

  async runAllTests(): Promise<void> {
    console.log(chalk.blue.bold('🧪 Starting Comprehensive Test Suite\n'));
    this.startTime = Date.now();

    // Run linting first
    await this.runLinting();

    // Run test suites
    for (const suite of this.testSuites) {
      await this.runTestSuite(suite);
    }

    // Generate coverage report
    await this.generateCoverageReport();

    // Display results
    this.displayResults();

    // Exit with appropriate code
    const hasFailures = this.results.some(result => !result.success);
    process.exit(hasFailures ? 1 : 0);
  }

  private async runLinting(): Promise<void> {
    console.log(chalk.yellow('🔍 Running linting checks...'));
    
    try {
      const output = execSync('npm run lint', { 
        encoding: 'utf8',
        timeout: 30000
      });
      
      console.log(chalk.green('✅ Linting passed\n'));
    } catch (error: any) {
      console.log(chalk.red('❌ Linting failed:'));
      console.log(error.stdout || error.message);
      console.log(chalk.yellow('💡 Run "npm run lint:fix" to auto-fix issues\n'));
    }
  }

  private async runTestSuite(suite: TestSuite): Promise<void> {
    console.log(chalk.blue(`🏃 Running ${suite.name}...`));
    console.log(chalk.gray(`   ${suite.description}`));
    
    const startTime = Date.now();
    
    try {
      const output = execSync(suite.command, {
        encoding: 'utf8',
        timeout: suite.timeout,
        stdio: 'pipe'
      });
      
      const duration = Date.now() - startTime;
      
      this.results.push({
        suite: suite.name,
        success: true,
        duration,
        output
      });
      
      console.log(chalk.green(`✅ ${suite.name} passed (${this.formatDuration(duration)})\n`));
      
    } catch (error: any) {
      const duration = Date.now() - startTime;
      
      this.results.push({
        suite: suite.name,
        success: false,
        duration,
        output: error.stdout || '',
        error: error.stderr || error.message
      });
      
      console.log(chalk.red(`❌ ${suite.name} failed (${this.formatDuration(duration)})`));
      console.log(chalk.red('Error output:'));
      console.log(error.stdout || error.message);
      console.log('');
    }
  }

  private async generateCoverageReport(): Promise<void> {
    console.log(chalk.yellow('📊 Generating coverage report...'));
    
    try {
      const output = execSync('npm run test:coverage', {
        encoding: 'utf8',
        timeout: 120000,
        stdio: 'pipe'
      });
      
      console.log(chalk.green('✅ Coverage report generated\n'));
      
      // Parse coverage summary if available
      this.parseCoverageSummary();
      
    } catch (error: any) {
      console.log(chalk.red('❌ Coverage report generation failed:'));
      console.log(error.stdout || error.message);
      console.log('');
    }
  }

  private parseCoverageSummary(): void {
    const coveragePath = path.join(__dirname, '..', 'coverage', 'coverage-summary.json');
    
    if (fs.existsSync(coveragePath)) {
      try {
        const coverageData = JSON.parse(fs.readFileSync(coveragePath, 'utf8'));
        const total = coverageData.total;
        
        console.log(chalk.blue('📈 Coverage Summary:'));
        console.log(`   Lines: ${this.formatCoverage(total.lines)}`);
        console.log(`   Functions: ${this.formatCoverage(total.functions)}`);
        console.log(`   Branches: ${this.formatCoverage(total.branches)}`);
        console.log(`   Statements: ${this.formatCoverage(total.statements)}`);
        console.log('');
        
      } catch (error) {
        console.log(chalk.yellow('⚠️  Could not parse coverage summary'));
      }
    }
  }

  private formatCoverage(coverage: any): string {
    const pct = coverage.pct;
    const color = pct >= 80 ? chalk.green : pct >= 60 ? chalk.yellow : chalk.red;
    return color(`${pct}% (${coverage.covered}/${coverage.total})`);
  }

  private displayResults(): void {
    const totalDuration = Date.now() - this.startTime;
    const successful = this.results.filter(r => r.success).length;
    const failed = this.results.filter(r => !r.success).length;
    
    console.log(chalk.blue.bold('📋 Test Results Summary'));
    console.log('='.repeat(50));
    
    this.results.forEach(result => {
      const status = result.success ? chalk.green('✅ PASS') : chalk.red('❌ FAIL');
      const duration = this.formatDuration(result.duration);
      console.log(`${status} ${result.suite} (${duration})`);
    });
    
    console.log('='.repeat(50));
    console.log(`Total: ${this.results.length} suites`);
    console.log(`Passed: ${chalk.green(successful)}`);
    console.log(`Failed: ${failed > 0 ? chalk.red(failed) : failed}`);
    console.log(`Duration: ${this.formatDuration(totalDuration)}`);
    
    if (failed > 0) {
      console.log(chalk.red.bold('\n❌ Some tests failed. Check the output above for details.'));
    } else {
      console.log(chalk.green.bold('\n🎉 All tests passed!'));
    }
    
    // Generate test report
    this.generateTestReport();
  }

  private generateTestReport(): void {
    const reportPath = path.join(__dirname, '..', 'test-results', 'test-report.json');
    const reportDir = path.dirname(reportPath);
    
    if (!fs.existsSync(reportDir)) {
      fs.mkdirSync(reportDir, { recursive: true });
    }
    
    const report = {
      timestamp: new Date().toISOString(),
      totalDuration: Date.now() - this.startTime,
      results: this.results,
      summary: {
        total: this.results.length,
        passed: this.results.filter(r => r.success).length,
        failed: this.results.filter(r => !r.success).length
      }
    };
    
    fs.writeFileSync(reportPath, JSON.stringify(report, null, 2));
    console.log(chalk.blue(`\n📄 Test report saved to: ${reportPath}`));
  }

  private formatDuration(ms: number): string {
    if (ms < 1000) return `${ms}ms`;
    if (ms < 60000) return `${(ms / 1000).toFixed(1)}s`;
    return `${(ms / 60000).toFixed(1)}m`;
  }
}

// CLI interface
async function main() {
  const args = process.argv.slice(2);
  
  if (args.includes('--help') || args.includes('-h')) {
    console.log(`
Usage: ts-node test/run-tests.ts [options]

Options:
  --help, -h     Show this help message
  --unit         Run only unit tests
  --integration  Run only integration tests
  --performance  Run only performance tests
  --coverage     Run tests with coverage
  --verbose      Enable verbose output

Examples:
  ts-node test/run-tests.ts                 # Run all tests
  ts-node test/run-tests.ts --unit          # Run only unit tests
  ts-node test/run-tests.ts --coverage      # Run with coverage
`);
    process.exit(0);
  }
  
  if (args.includes('--unit')) {
    execSync('npm run test:unit', { stdio: 'inherit' });
    return;
  }
  
  if (args.includes('--integration')) {
    execSync('npm run test:integration', { stdio: 'inherit' });
    return;
  }
  
  if (args.includes('--performance')) {
    execSync('npm run test:performance', { stdio: 'inherit' });
    return;
  }
  
  if (args.includes('--coverage')) {
    execSync('npm run test:coverage', { stdio: 'inherit' });
    return;
  }
  
  if (args.includes('--verbose')) {
    process.env.VERBOSE_TESTS = 'true';
  }
  
  // Run comprehensive test suite
  const runner = new TestRunner();
  await runner.runAllTests();
}

// Run if called directly
if (require.main === module) {
  main().catch(error => {
    console.error(chalk.red('Test runner failed:'), error);
    process.exit(1);
  });
}

export { TestRunner };