# Interview Feedback Tracker Deployment Script
# This script deploys the Interview Feedback Tracker feature with proper dependency management

param(
    [Parameter(Mandatory=$true)]
    [string]$TargetOrg,
    
    [Parameter(Mandatory=$false)]
    [switch]$ValidateOnly = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$RunTests = $true,
    
    [Parameter(Mandatory=$false)]
    [string]$TestLevel = "RunLocalTests"
)

Write-Host "Starting Interview Feedback Tracker deployment to org: $TargetOrg" -ForegroundColor Green

# Set target org
sf config set target-org=$TargetOrg

# Verify org connection
Write-Host "Verifying org connection..." -ForegroundColor Yellow
$orgStatus = sf org display --json | ConvertFrom-Json
if ($orgStatus.status -ne 0) {
    Write-Error "Failed to connect to org: $TargetOrg"
    exit 1
}
Write-Host "Connected to org: $($orgStatus.result.alias)" -ForegroundColor Green

# Define deployment phases with dependencies
$deploymentPhases = @(
    @{
        Name = "Phase 1: Custom Objects and Fields"
        Components = @(
            "objects/Interview_Feedback__c",
            "objects/Feedback_Template__c", 
            "objects/Competency_Rating__c",
            "objects/Feedback_Share__c",
            "objects/Interview_Feedback_Audit__c"
        )
    },
    @{
        Name = "Phase 2: Permission Sets and Security"
        Components = @(
            "permissionsets/Interview_Feedback_Manager",
            "permissionsets/Interview_Feedback_User", 
            "permissionsets/Interview_Feedback_Viewer"
        )
    },
    @{
        Name = "Phase 3: Apex Classes and Services"
        Components = @(
            "classes/InterviewFeedbackTestDataFactory",
            "classes/InterviewFeedbackService",
            "classes/FeedbackAnalyticsService",
            "classes/FeedbackSharingService",
            "classes/FeedbackTemplateService",
            "classes/FeedbackSecurityService",
            "classes/FeedbackDataRetentionBatch",
            "classes/FeedbackDataRetentionScheduler"
        )
    },
    @{
        Name = "Phase 4: Test Classes"
        Components = @(
            "classes/InterviewFeedbackObjectTest",
            "classes/InterviewFeedbackServiceTest",
            "classes/FeedbackAnalyticsServiceTest",
            "classes/FeedbackSharingServiceTest",
            "classes/FeedbackSecurityServiceTest",
            "classes/FeedbackQueryOptimizationServiceTest",
            "classes/InterviewFeedbackComprehensiveTest",
            "classes/InterviewFeedbackErrorHandlingTest"
        )
    },
    @{
        Name = "Phase 5: Lightning Web Components"
        Components = @(
            "lwc/interviewFeedbackCollector",
            "lwc/performanceDashboard",
            "lwc/mobileFeedbackCapture"
        )
    }
)

# Execute deployment phases
foreach ($phase in $deploymentPhases) {
    Write-Host "`n$($phase.Name)" -ForegroundColor Cyan
    Write-Host "=" * $phase.Name.Length -ForegroundColor Cyan
    
    foreach ($component in $phase.Components) {
        Write-Host "Deploying: $component" -ForegroundColor Yellow
        
        $deployCommand = "sf project deploy start --source-dir force-app/main/default/$component"
        if ($ValidateOnly) {
            $deployCommand += " --dry-run"
        }
        
        $result = Invoke-Expression $deployCommand
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to deploy: $component"
            Write-Host $result -ForegroundColor Red
            exit 1
        }
        Write-Host "✓ Successfully deployed: $component" -ForegroundColor Green
    }
    
    Write-Host "Phase completed successfully!" -ForegroundColor Green
    Start-Sleep -Seconds 2
}

# Run tests if requested
if ($RunTests -and -not $ValidateOnly) {
    Write-Host "`nRunning Apex Tests..." -ForegroundColor Cyan
    Write-Host "===================" -ForegroundColor Cyan
    
    $testCommand = "sf apex run test --test-level $TestLevel --result-format human --code-coverage"
    $testResult = Invoke-Expression $testCommand
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Test execution failed"
        Write-Host $testResult -ForegroundColor Red
        exit 1
    }
    
    Write-Host "✓ All tests passed successfully!" -ForegroundColor Green
}

# Assign permission sets to current user
Write-Host "`nAssigning Permission Sets..." -ForegroundColor Cyan
Write-Host "============================" -ForegroundColor Cyan

$permissionSets = @(
    "Interview_Feedback_Manager",
    "Interview_Feedback_User"
)

foreach ($permSet in $permissionSets) {
    Write-Host "Assigning: $permSet" -ForegroundColor Yellow
    $assignResult = sf org assign permset --name $permSet
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Successfully assigned: $permSet" -ForegroundColor Green
    } else {
        Write-Warning "Failed to assign: $permSet (may already be assigned)"
    }
}

Write-Host "`n🎉 Interview Feedback Tracker deployment completed successfully!" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Run post-deployment validation script" -ForegroundColor White
Write-Host "2. Import sample data if needed" -ForegroundColor White
Write-Host "3. Configure user permissions" -ForegroundColor White
Write-Host "4. Test functionality in the org" -ForegroundColor White