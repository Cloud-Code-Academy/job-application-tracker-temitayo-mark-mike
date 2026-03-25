# Interview Feedback Tracker Deployment Validation Script
# This script validates that all components were deployed successfully

param(
    [Parameter(Mandatory=$true)]
    [string]$TargetOrg
)

Write-Host "Validating Interview Feedback Tracker deployment in org: $TargetOrg" -ForegroundColor Green

# Set target org
sf config set target-org=$TargetOrg

# Validation checks
$validationResults = @()

# Check Custom Objects
Write-Host "`nValidating Custom Objects..." -ForegroundColor Cyan
$customObjects = @(
    "Interview_Feedback__c",
    "Feedback_Template__c", 
    "Competency_Rating__c",
    "Feedback_Share__c",
    "Interview_Feedback_Audit__c"
)

foreach ($obj in $customObjects) {
    try {
        $query = "SELECT COUNT() FROM $obj LIMIT 1"
        $result = sf data query --query $query --json | ConvertFrom-Json
        if ($result.status -eq 0) {
            Write-Host "✓ $obj - Available" -ForegroundColor Green
            $validationResults += @{Object = $obj; Status = "Success"; Message = "Object accessible"}
        }
    }
    catch {
        Write-Host "✗ $obj - Not accessible" -ForegroundColor Red
        $validationResults += @{Object = $obj; Status = "Failed"; Message = "Object not accessible"}
    }
}

# Check Apex Classes
Write-Host "`nValidating Apex Classes..." -ForegroundColor Cyan
$apexClasses = @(
    "InterviewFeedbackService",
    "FeedbackAnalyticsService",
    "FeedbackSharingService",
    "FeedbackTemplateService",
    "FeedbackSecurityService",
    "InterviewFeedbackTestDataFactory"
)

foreach ($class in $apexClasses) {
    try {
        $query = "SELECT Id, Name FROM ApexClass WHERE Name = '$class'"
        $result = sf data query --query $query --json | ConvertFrom-Json
        if ($result.result.records.Count -gt 0) {
            Write-Host "✓ $class - Deployed" -ForegroundColor Green
            $validationResults += @{Object = $class; Status = "Success"; Message = "Class deployed"}
        } else {
            Write-Host "✗ $class - Not found" -ForegroundColor Red
            $validationResults += @{Object = $class; Status = "Failed"; Message = "Class not found"}
        }
    }
    catch {
        Write-Host "✗ $class - Error checking" -ForegroundColor Red
        $validationResults += @{Object = $class; Status = "Failed"; Message = "Error during validation"}
    }
}

# Check Permission Sets
Write-Host "`nValidating Permission Sets..." -ForegroundColor Cyan
$permissionSets = @(
    "Interview_Feedback_Manager",
    "Interview_Feedback_User",
    "Interview_Feedback_Viewer"
)

foreach ($permSet in $permissionSets) {
    try {
        $query = "SELECT Id, Name FROM PermissionSet WHERE Name = '$permSet'"
        $result = sf data query --query $query --json | ConvertFrom-Json
        if ($result.result.records.Count -gt 0) {
            Write-Host "✓ $permSet - Available" -ForegroundColor Green
            $validationResults += @{Object = $permSet; Status = "Success"; Message = "Permission set available"}
        } else {
            Write-Host "✗ $permSet - Not found" -ForegroundColor Red
            $validationResults += @{Object = $permSet; Status = "Failed"; Message = "Permission set not found"}
        }
    }
    catch {
        Write-Host "✗ $permSet - Error checking" -ForegroundColor Red
        $validationResults += @{Object = $permSet; Status = "Failed"; Message = "Error during validation"}
    }
}

# Check Lightning Web Components
Write-Host "`nValidating Lightning Web Components..." -ForegroundColor Cyan
$lwcComponents = @(
    "interviewFeedbackCollector",
    "performanceDashboard", 
    "mobileFeedbackCapture"
)

foreach ($component in $lwcComponents) {
    if (Test-Path "force-app/main/default/lwc/$component/$component.js") {
        Write-Host "✓ $component - Source files present" -ForegroundColor Green
        $validationResults += @{Object = $component; Status = "Success"; Message = "LWC files present"}
    } else {
        Write-Host "✗ $component - Source files missing" -ForegroundColor Red
        $validationResults += @{Object = $component; Status = "Failed"; Message = "LWC files missing"}
    }
}

# Run a basic functionality test
Write-Host "`nRunning Basic Functionality Test..." -ForegroundColor Cyan
try {
    $testScript = @"
// Create test data
InterviewFeedbackTestDataFactory factory = new InterviewFeedbackTestDataFactory();
Job_Application__c jobApp = factory.createJobApplication();
insert jobApp;

Interview_Feedback__c feedback = factory.createInterviewFeedback(jobApp.Id);
insert feedback;

// Test service functionality
InterviewFeedbackService.FeedbackAnalysis analysis = InterviewFeedbackService.analyzeFeedback(jobApp.Id);
System.debug('Analysis completed: ' + (analysis != null));

// Test analytics
List<FeedbackAnalyticsService.PerformanceTrend> trends = FeedbackAnalyticsService.calculateTrends(jobApp.Id, 30);
System.debug('Trends calculated: ' + (trends != null));

System.debug('Basic functionality test completed successfully');
"@
    
    $testScript | Out-File -FilePath "temp_validation_test.apex" -Encoding UTF8
    $result = sf apex run --file temp_validation_test.apex
    Remove-Item "temp_validation_test.apex" -Force
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Basic functionality test passed" -ForegroundColor Green
        $validationResults += @{Object = "Functionality"; Status = "Success"; Message = "Basic operations working"}
    } else {
        Write-Host "✗ Basic functionality test failed" -ForegroundColor Red
        $validationResults += @{Object = "Functionality"; Status = "Failed"; Message = "Basic operations failed"}
    }
}
catch {
    Write-Host "✗ Could not run functionality test" -ForegroundColor Red
    $validationResults += @{Object = "Functionality"; Status = "Failed"; Message = "Could not execute test"}
}

# Generate validation report
Write-Host "`nValidation Summary" -ForegroundColor Cyan
Write-Host "=================" -ForegroundColor Cyan

$successCount = ($validationResults | Where-Object { $_.Status -eq "Success" }).Count
$failureCount = ($validationResults | Where-Object { $_.Status -eq "Failed" }).Count
$totalCount = $validationResults.Count

Write-Host "Total Checks: $totalCount" -ForegroundColor White
Write-Host "Successful: $successCount" -ForegroundColor Green
Write-Host "Failed: $failureCount" -ForegroundColor Red

if ($failureCount -eq 0) {
    Write-Host "`n🎉 All validation checks passed! Deployment is successful." -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n⚠️  Some validation checks failed. Please review the issues above." -ForegroundColor Yellow
    
    Write-Host "`nFailed Components:" -ForegroundColor Red
    foreach ($failure in ($validationResults | Where-Object { $_.Status -eq "Failed" })) {
        Write-Host "- $($failure.Object): $($failure.Message)" -ForegroundColor Red
    }
    exit 1
}