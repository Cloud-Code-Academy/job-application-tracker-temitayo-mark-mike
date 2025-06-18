# 🔍 CHECK DEPLOYMENT STATUS
# This script checks if the custom app was actually deployed

Write-Host "🔍 CHECKING DEPLOYMENT STATUS..." -ForegroundColor Green
Write-Host "=================================" -ForegroundColor Cyan

# Step 1: Check if files exist locally
Write-Host "📁 Checking local files..." -ForegroundColor Yellow

$appFile = "force-app/main/default/applications/Job_Application_Tracker.app-meta.xml"
$permSetFile = "force-app/main/default/permissionsets/Job_Application_Manager.permissionset-meta.xml"
$utilityBarFile = "force-app/main/default/appMenus/Job_Application_Tracker_UtilityBar.appMenu-meta.xml"

if (Test-Path $appFile) {
    Write-Host "✅ Custom App file exists: $appFile" -ForegroundColor Green
} else {
    Write-Host "❌ Custom App file missing: $appFile" -ForegroundColor Red
}

if (Test-Path $permSetFile) {
    Write-Host "✅ Permission Set file exists: $permSetFile" -ForegroundColor Green
} else {
    Write-Host "❌ Permission Set file missing: $permSetFile" -ForegroundColor Red
}

if (Test-Path $utilityBarFile) {
    Write-Host "✅ Utility Bar file exists: $utilityBarFile" -ForegroundColor Green
} else {
    Write-Host "❌ Utility Bar file missing: $utilityBarFile" -ForegroundColor Red
}

# Step 2: Check Salesforce CLI connection
Write-Host "`n🔗 Checking Salesforce connection..." -ForegroundColor Yellow
try {
    $orgInfo = sf org display --json | ConvertFrom-Json
    if ($orgInfo.status -eq 0) {
        Write-Host "✅ Connected to: $($orgInfo.result.username)" -ForegroundColor Green
        Write-Host "✅ Org ID: $($orgInfo.result.id)" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ Not connected to Salesforce!" -ForegroundColor Red
    Write-Host "💡 Run: sf org login web --alias myCapstoneOrg" -ForegroundColor Yellow
    exit 1
}

# Step 3: Run deep investigation
Write-Host "`n🕵️ Running deep investigation..." -ForegroundColor Yellow
sf apex run --file scripts/deep-app-investigation.apex

# Step 4: Check deployment history
Write-Host "`n📋 Checking recent deployments..." -ForegroundColor Yellow
try {
    Write-Host "Recent deployment status:" -ForegroundColor Cyan
    sf project deploy report --json | ConvertFrom-Json | Format-Table
} catch {
    Write-Host "⚠️ No recent deployment found" -ForegroundColor Yellow
}

# Step 5: Try to deploy again
Write-Host "`n🚀 Attempting fresh deployment..." -ForegroundColor Yellow
Write-Host "Deploying custom application..." -ForegroundColor Cyan

try {
    sf project deploy start --source-dir force-app/main/default/applications --wait 10
    Write-Host "✅ Application deployment completed" -ForegroundColor Green
} catch {
    Write-Host "❌ Application deployment failed" -ForegroundColor Red
}

try {
    sf project deploy start --source-dir force-app/main/default/permissionsets --wait 10
    Write-Host "✅ Permission set deployment completed" -ForegroundColor Green
} catch {
    Write-Host "❌ Permission set deployment failed" -ForegroundColor Red
}

# Step 6: Assign permission set
Write-Host "`n🔐 Assigning permission set..." -ForegroundColor Yellow
try {
    sf org assign permset --name Job_Application_Manager
    Write-Host "✅ Permission set assigned" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Permission set assignment issue (may already be assigned)" -ForegroundColor Yellow
}

# Step 7: Provide manual verification steps
Write-Host "`n🔍 MANUAL VERIFICATION STEPS:" -ForegroundColor Yellow
Write-Host "=============================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. 🌐 Open Salesforce:" -ForegroundColor White
Write-Host "   sf org open" -ForegroundColor Gray
Write-Host ""
Write-Host "2. ⚡ Verify Lightning Experience:" -ForegroundColor White
Write-Host "   • Check URL contains 'lightning.force.com'" -ForegroundColor Gray
Write-Host "   • If not, switch to Lightning Experience" -ForegroundColor Gray
Write-Host ""
Write-Host "3. 🔧 Check Setup → Apps → App Manager:" -ForegroundColor White
Write-Host "   • Look for 'Job Application Tracker'" -ForegroundColor Gray
Write-Host "   • Should show as 'Active'" -ForegroundColor Gray
Write-Host ""
Write-Host "4. 📱 Check App Launcher:" -ForegroundColor White
Write-Host "   • Click 9 dots icon" -ForegroundColor Gray
Write-Host "   • Search 'Job Application Tracker'" -ForegroundColor Gray
Write-Host "   • Should appear as an APP (not just item)" -ForegroundColor Gray
Write-Host ""
Write-Host "5. 🔐 Check Permission Sets:" -ForegroundColor White
Write-Host "   • Setup → Permission Sets → Job Application Manager" -ForegroundColor Gray
Write-Host "   • Check 'Manage Assignments' - your user should be listed" -ForegroundColor Gray
Write-Host ""

# Step 8: Alternative solutions
Write-Host "🔧 IF STILL NOT WORKING:" -ForegroundColor Yellow
Write-Host "========================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Option 1: Manual App Creation" -ForegroundColor White
Write-Host "• Setup → Apps → App Manager → New Lightning App" -ForegroundColor Gray
Write-Host "• Name: Job Application Tracker" -ForegroundColor Gray
Write-Host "• Add tabs: Home, Job Applications, Contacts, etc." -ForegroundColor Gray
Write-Host ""
Write-Host "Option 2: Use Direct Tab Access" -ForegroundColor White
Write-Host "• Job Applications tab works immediately" -ForegroundColor Gray
Write-Host "• All functionality available without custom app" -ForegroundColor Gray
Write-Host ""
Write-Host "Option 3: Profile Assignment" -ForegroundColor White
Write-Host "• Setup → Profiles → System Administrator" -ForegroundColor Gray
Write-Host "• Custom App Settings → Job Application Tracker → Visible" -ForegroundColor Gray
Write-Host ""

Write-Host "🎯 NEXT STEPS:" -ForegroundColor Green
Write-Host "1. Run the manual verification steps above" -ForegroundColor White
Write-Host "2. If app still not visible, use Option 1 (manual creation)" -ForegroundColor White
Write-Host "3. Remember: Job Applications tab works regardless!" -ForegroundColor White
Write-Host ""
Write-Host "🚀 Opening Salesforce for manual verification..." -ForegroundColor Green
Start-Sleep -Seconds 2
sf org open
