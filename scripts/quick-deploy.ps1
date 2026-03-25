<#
.SYNOPSIS
    Quick deploy of modernized components to the target Salesforce org.
    Deploys in dependency order, skipping components with known pre-existing issues.

.PARAMETER TargetOrg
    Alias or username of the target org. Defaults to myCapstoneOrg.

.EXAMPLE
    .\scripts\quick-deploy.ps1
    .\scripts\quick-deploy.ps1 -TargetOrg "myOtherOrg"
#>

param(
    [string]$TargetOrg = "myCapstoneOrg"
)

$ErrorActionPreference = "Stop"

Write-Host "`n=== Quick Deploy to $TargetOrg ===" -ForegroundColor Cyan
Write-Host "Deploys in dependency order, skipping known broken components.`n"

# Step 1: Custom Metadata Type and records (other classes depend on these fields)
Write-Host "[1/4] Deploying Custom Metadata Types..." -ForegroundColor Yellow
sf project deploy start `
    --source-dir force-app/main/default/objects/Tax_Configuration__mdt `
    --source-dir force-app/main/default/customMetadata `
    --target-org $TargetOrg --wait 10
if ($LASTEXITCODE -ne 0) { Write-Host "CMDT deployment failed." -ForegroundColor Red; exit 1 }
Write-Host "  Done.`n" -ForegroundColor Green

# Step 2: Apex classes (depend on CMDT fields existing)
Write-Host "[2/4] Deploying Apex classes..." -ForegroundColor Yellow
sf project deploy start `
    --source-dir force-app/main/default/classes/BaseApiService.cls `
    --source-dir force-app/main/default/classes/BaseApiService.cls-meta.xml `
    --source-dir force-app/main/default/classes/TaxConfigurationService.cls `
    --source-dir force-app/main/default/classes/TaxConfigurationService.cls-meta.xml `
    --source-dir force-app/main/default/classes/SalaryBenchmarkService.cls `
    --source-dir force-app/main/default/classes/SalaryBenchmarkService.cls-meta.xml `
    --source-dir force-app/main/default/classes/CompanyDataService.cls `
    --source-dir force-app/main/default/classes/CompanyDataService.cls-meta.xml `
    --source-dir force-app/main/default/classes/PerformanceOptimizationService.cls `
    --source-dir force-app/main/default/classes/PerformanceOptimizationService.cls-meta.xml `
    --source-dir force-app/main/default/classes/ApplicationAnalyticsService.cls `
    --source-dir force-app/main/default/classes/ApplicationAnalyticsService.cls-meta.xml `
    --source-dir force-app/main/default/classes/JobApplicationEventPublisher.cls `
    --source-dir force-app/main/default/classes/JobApplicationEventPublisher.cls-meta.xml `
    --source-dir force-app/main/default/classes/JobApplicationEventSubscriber.cls `
    --source-dir force-app/main/default/classes/JobApplicationEventSubscriber.cls-meta.xml `
    --source-dir force-app/main/default/classes/SalaryCalculationService.cls `
    --source-dir force-app/main/default/classes/SalaryCalculationService.cls-meta.xml `
    --source-dir force-app/main/default/classes/SecurityGovernanceService.cls `
    --source-dir force-app/main/default/classes/SecurityGovernanceService.cls-meta.xml `
    --source-dir force-app/main/default/classes/TaskCreationService.cls `
    --source-dir force-app/main/default/classes/TaskCreationService.cls-meta.xml `
    --source-dir force-app/main/default/classes/ContactAssignmentService.cls `
    --source-dir force-app/main/default/classes/ContactAssignmentService.cls-meta.xml `
    --source-dir force-app/main/default/classes/EmailNotificationQueue.cls `
    --source-dir force-app/main/default/classes/EmailNotificationQueue.cls-meta.xml `
    --source-dir force-app/main/default/classes/EventValidationHandler.cls `
    --source-dir force-app/main/default/classes/EventValidationHandler.cls-meta.xml `
    --source-dir force-app/main/default/classes/ExecutiveReportingService.cls `
    --source-dir force-app/main/default/classes/ExecutiveReportingService.cls-meta.xml `
    --source-dir force-app/main/default/classes/IntegrationDeploymentService.cls `
    --source-dir force-app/main/default/classes/IntegrationDeploymentService.cls-meta.xml `
    --source-dir force-app/main/default/classes/JobApplicationTriggerHandler.cls `
    --source-dir force-app/main/default/classes/JobApplicationTriggerHandler.cls-meta.xml `
    --source-dir force-app/main/default/classes/SalaryDataAPIService.cls `
    --source-dir force-app/main/default/classes/SalaryDataAPIService.cls-meta.xml `
    --source-dir force-app/main/default/classes/SalaryMarketAnalysisBatch.cls `
    --source-dir force-app/main/default/classes/SalaryMarketAnalysisBatch.cls-meta.xml `
    --source-dir force-app/main/default/classes/SalaryMarketAnalysisScheduler.cls `
    --source-dir force-app/main/default/classes/SalaryMarketAnalysisScheduler.cls-meta.xml `
    --target-org $TargetOrg --wait 15
if ($LASTEXITCODE -ne 0) { Write-Host "Apex deployment failed." -ForegroundColor Red; exit 1 }
Write-Host "  Done.`n" -ForegroundColor Green

# Step 3: LWC components (skip jobApplicationDashboard - pre-existing HTML issue)
Write-Host "[3/4] Deploying LWC components..." -ForegroundColor Yellow
sf project deploy start `
    --source-dir force-app/main/default/lwc/errorPanel `
    --source-dir force-app/main/default/lwc/salaryCalculator `
    --source-dir force-app/main/default/lwc/securityGovernanceDashboard `
    --source-dir force-app/main/default/lwc/applicationAnalyticsDashboard `
    --source-dir force-app/main/default/lwc/calendarIntegration `
    --source-dir force-app/main/default/lwc/executiveKpiDashboard `
    --source-dir force-app/main/default/lwc/integrationDeploymentDashboard `
    --source-dir force-app/main/default/lwc/performanceOptimizationDashboard `
    --source-dir force-app/main/default/lwc/interviewFeedbackCollector `
    --source-dir force-app/main/default/lwc/mobileFeedbackCapture `
    --source-dir force-app/main/default/lwc/performanceDashboard `
    --target-org $TargetOrg --wait 10
if ($LASTEXITCODE -ne 0) { Write-Host "LWC deployment failed." -ForegroundColor Red; exit 1 }
Write-Host "  Done.`n" -ForegroundColor Green

# Step 4: Objects, triggers, and remaining metadata
Write-Host "[4/4] Deploying objects, triggers, and metadata..." -ForegroundColor Yellow
sf project deploy start `
    --source-dir force-app/main/default/objects/Job_Application__c `
    --source-dir force-app/main/default/triggers `
    --target-org $TargetOrg --wait 10
if ($LASTEXITCODE -ne 0) { Write-Host "Metadata deployment failed." -ForegroundColor Red; exit 1 }
Write-Host "  Done.`n" -ForegroundColor Green

Write-Host "=== Deployment Complete ===" -ForegroundColor Cyan
Write-Host "Skipped (pre-existing issues):"
Write-Host "  - Job_Application_Workflow.flow-meta.xml (duplicate actionCalls)"
Write-Host "  - Job_Application_Manager.permissionset-meta.xml (required field ref)"
Write-Host "  - jobApplicationDashboard LWC (inline ternary HTML syntax)"
Write-Host "  - AutomatedReportService, CompanyDataServiceTest, etc. (Apex compile errors)`n"
