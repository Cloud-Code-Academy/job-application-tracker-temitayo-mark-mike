# LWC Testing Script with Jest (PowerShell)
# Comprehensive testing workflow for Lightning Web Components
# Author: Learning Journey - Task 7.3
# Date: 2025-01-08

Write-Host "🧪 Lightning Web Components Testing with Jest" -ForegroundColor Blue
Write-Host "=============================================" -ForegroundColor Blue
Write-Host ""

# Function to print colored output
function Write-Status {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Check if Node.js is installed
try {
    $nodeVersion = node --version
    Write-Success "Node.js version check passed: $nodeVersion"
} catch {
    Write-Error "Node.js is not installed. Please install Node.js 18+ to run Jest tests."
    exit 1
}

# Check if npm is installed
try {
    $npmVersion = npm --version
    Write-Success "npm version: $npmVersion"
} catch {
    Write-Error "npm is not installed. Please install npm to manage dependencies."
    exit 1
}

# Install dependencies if node_modules doesn't exist
if (-not (Test-Path "node_modules")) {
    Write-Status "Installing npm dependencies..."
    npm install
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Dependencies installed successfully"
    } else {
        Write-Error "Failed to install dependencies"
        exit 1
    }
} else {
    Write-Status "Dependencies already installed"
}

# Check if Jest is available
try {
    $jestVersion = npx jest --version
    Write-Success "Jest version: $jestVersion"
} catch {
    Write-Error "Jest is not available. Installing Jest dependencies..."
    npm install --save-dev jest @salesforce/sfdx-lwc-jest
    Write-Success "Jest dependencies installed"
}

Write-Host ""
Write-Status "Starting LWC test execution..."
Write-Host ""

# Function to run specific test type
function Run-TestType {
    param(
        [string]$TestType,
        [string]$Description,
        [string]$Command
    )
    
    Write-Host "📋 $Description" -ForegroundColor Yellow
    Write-Host "Command: $Command" -ForegroundColor Gray
    Write-Host "----------------------------------------" -ForegroundColor Gray
    
    Invoke-Expression $Command
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "$TestType tests completed successfully"
    } else {
        Write-Error "$TestType tests failed"
        return $false
    }
    
    Write-Host ""
    return $true
}

# Test execution menu
Write-Host "🧪 LWC Testing Options:" -ForegroundColor Yellow
Write-Host "1. Run all tests"
Write-Host "2. Run tests with coverage"
Write-Host "3. Run tests in watch mode"
Write-Host "4. Run specific test file"
Write-Host "5. Run tests with debug output"
Write-Host ""

$choice = Read-Host "Choose an option (1-5)"

switch ($choice) {
    "1" {
        Write-Status "Running all LWC tests..."
        Run-TestType "Unit" "All LWC unit tests" "npm test"
    }
    "2" {
        Write-Status "Running tests with coverage report..."
        Run-TestType "Coverage" "Tests with coverage analysis" "npm run test:coverage"
    }
    "3" {
        Write-Status "Running tests in watch mode..."
        Write-Warning "Press 'q' to quit watch mode"
        Run-TestType "Watch" "Interactive test watching" "npm run test:watch"
    }
    "4" {
        Write-Host ""
        Write-Host "Available test files:" -ForegroundColor Yellow
        Get-ChildItem -Path "force-app/main/default/lwc" -Recurse -Filter "*.test.js" | ForEach-Object {
            $relativePath = $_.FullName -replace [regex]::Escape((Get-Location).Path + "\force-app\main\default\lwc\"), ""
            Write-Host $relativePath
        }
        Write-Host ""
        $pattern = Read-Host "Enter test file pattern (e.g., jobApplicationDashboard)"
        Run-TestType "Specific" "Tests matching pattern: $pattern" "npm test -- --testNamePattern=$pattern"
    }
    "5" {
        Write-Status "Running tests with debug output..."
        Run-TestType "Debug" "Tests with verbose debugging" "npm run test:debug"
    }
    default {
        Write-Error "Invalid option selected"
        exit 1
    }
}

Write-Host ""
Write-Success "🎉 LWC testing completed!"
Write-Host ""

# Display coverage information if available
if (Test-Path "coverage") {
    Write-Status "📊 Coverage report generated in ./coverage directory"
    Write-Status "Open ./coverage/lcov-report/index.html in your browser to view detailed coverage"
}

# Display next steps
Write-Host ""
Write-Host "🚀 Next Steps:" -ForegroundColor Yellow
Write-Host "• Review test results and fix any failing tests"
Write-Host "• Check coverage report for areas needing more tests"
Write-Host "• Consider adding integration tests for complex workflows"
Write-Host "• Set up continuous integration to run tests automatically"
Write-Host ""

Write-Success "Happy testing! 🧪✨"