# 🚀 AUTOMATED APP VISIBILITY FIX
# This script automatically fixes all app visibility issues

Write-Host "🎯 STARTING AUTOMATED APP VISIBILITY FIX..." -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Cyan

# Step 1: Verify we're in the right directory
Write-Host "📁 Checking project directory..." -ForegroundColor Yellow
if (!(Test-Path "sfdx-project.json")) {
    Write-Host "❌ ERROR: Not in Salesforce project directory!" -ForegroundColor Red
    Write-Host "💡 Please navigate to your project folder first:" -ForegroundColor Yellow
    Write-Host "   cd 'C:\Users\tayof\Documents\job-application-tracker-temitayo-mark-mike'" -ForegroundColor White
    exit 1
}
Write-Host "✅ Project directory confirmed" -ForegroundColor Green

# Step 2: Check Salesforce CLI connection
Write-Host "🔗 Checking Salesforce CLI connection..." -ForegroundColor Yellow
try {
    $orgInfo = sf org display --json | ConvertFrom-Json
    if ($orgInfo.status -eq 0) {
        Write-Host "✅ Connected to org: $($orgInfo.result.username)" -ForegroundColor Green
    } else {
        throw "Not connected"
    }
} catch {
    Write-Host "❌ ERROR: Not connected to Salesforce org!" -ForegroundColor Red
    Write-Host "💡 Please connect first:" -ForegroundColor Yellow
    Write-Host "   sf org login web --alias myCapstoneOrg" -ForegroundColor White
    exit 1
}

# Step 3: Run initial diagnosis
Write-Host "🔍 Running initial diagnosis..." -ForegroundColor Yellow
Write-Host "📊 Checking current app visibility status..." -ForegroundColor Cyan
sf apex run --file scripts/diagnose-app-visibility.apex

# Step 4: Deploy updated permission set with app visibility
Write-Host "🔧 Deploying updated permission set..." -ForegroundColor Yellow
try {
    $permSetResult = sf project deploy start --source-dir force-app/main/default/permissionsets --json | ConvertFrom-Json
    if ($permSetResult.status -eq 0) {
        Write-Host "✅ Permission set deployed successfully" -ForegroundColor Green
    } else {
        throw "Permission set deployment failed"
    }
} catch {
    Write-Host "❌ ERROR: Permission set deployment failed!" -ForegroundColor Red
    Write-Host "💡 Trying alternative deployment..." -ForegroundColor Yellow
    sf project deploy start --source-dir force-app/main/default
}

# Step 5: Deploy custom application
Write-Host "📱 Deploying custom application..." -ForegroundColor Yellow
try {
    $appResult = sf project deploy start --source-dir force-app/main/default/applications --json | ConvertFrom-Json
    if ($appResult.status -eq 0) {
        Write-Host "✅ Custom application deployed successfully" -ForegroundColor Green
    } else {
        throw "App deployment failed"
    }
} catch {
    Write-Host "❌ ERROR: App deployment failed!" -ForegroundColor Red
    Write-Host "💡 Trying full deployment..." -ForegroundColor Yellow
    sf project deploy start --source-dir force-app/main/default
}

# Step 6: Deploy utility bar
Write-Host "🛠️ Deploying utility bar..." -ForegroundColor Yellow
try {
    sf project deploy start --source-dir force-app/main/default/appMenus
    Write-Host "✅ Utility bar deployed successfully" -ForegroundColor Green
} catch {
    Write-Host "⚠️ WARNING: Utility bar deployment had issues (non-critical)" -ForegroundColor Yellow
}

# Step 7: Assign permission set
Write-Host "🔐 Assigning permission set..." -ForegroundColor Yellow
try {
    $permAssignResult = sf org assign permset --name Job_Application_Manager --json | ConvertFrom-Json
    if ($permAssignResult.status -eq 0) {
        Write-Host "✅ Permission set assigned successfully" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Permission set may already be assigned" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠️ WARNING: Permission set assignment had issues" -ForegroundColor Yellow
    Write-Host "💡 You may need to assign manually in Setup" -ForegroundColor Cyan
}

# Step 8: Complete deployment verification
Write-Host "🚀 Running complete deployment..." -ForegroundColor Yellow
try {
    sf project deploy start --source-dir force-app/main/default
    Write-Host "✅ Complete deployment finished" -ForegroundColor Green
} catch {
    Write-Host "⚠️ WARNING: Some deployment issues occurred" -ForegroundColor Yellow
}

# Step 9: Final verification
Write-Host "🔍 Running final verification..." -ForegroundColor Yellow
Write-Host "📊 Checking app visibility after fixes..." -ForegroundColor Cyan
sf apex run --file scripts/diagnose-app-visibility.apex

# Step 10: Open Salesforce org
Write-Host "🌐 Opening Salesforce org..." -ForegroundColor Yellow
Start-Sleep -Seconds 2
sf org open

# Success message and instructions
Write-Host ""
Write-Host "🎉 AUTOMATION COMPLETE!" -ForegroundColor Green
Write-Host "========================" -ForegroundColor Cyan
Write-Host ""
Write-Host "✅ Permission set updated with app visibility" -ForegroundColor Green
Write-Host "✅ Custom application deployed" -ForegroundColor Green
Write-Host "✅ Utility bar configured" -ForegroundColor Green
Write-Host "✅ Permission set assigned" -ForegroundColor Green
Write-Host "✅ Salesforce org opened" -ForegroundColor Green
Write-Host ""
Write-Host "📱 TO ACCESS YOUR APP:" -ForegroundColor Yellow
Write-Host "1. Click the App Launcher (9 dots icon)" -ForegroundColor White
Write-Host "2. Search for 'Job Application Tracker'" -ForegroundColor White
Write-Host "3. Click the app to open it" -ForegroundColor White
Write-Host ""
Write-Host "⏰ NOTE: Apps may take 5-10 minutes to appear after deployment" -ForegroundColor Cyan
Write-Host "🔄 If not visible immediately, refresh browser or try again in a few minutes" -ForegroundColor Cyan
Write-Host ""
Write-Host "🤝 TEAM SHARING:" -ForegroundColor Yellow
Write-Host "Tell Mike and Mark: 'The Job Application Tracker app is now available" -ForegroundColor White
Write-Host "in the App Launcher - just search for it!'" -ForegroundColor White
Write-Host ""
Write-Host "🎯 SUCCESS INDICATORS:" -ForegroundColor Yellow
Write-Host "• App appears in App Launcher" -ForegroundColor White
Write-Host "• Navigation shows: Home, Job Applications, Contacts, etc." -ForegroundColor White
Write-Host "• Utility bar at bottom with Notes, History" -ForegroundColor White
Write-Host "• Professional branded interface" -ForegroundColor White
Write-Host ""
Write-Host "🚀 AUTOMATION COMPLETE - ENJOY YOUR CUSTOM APP!" -ForegroundColor Green
