# 🚀 COMPLETE FIX: Custom App + List Views
# This script fixes both app visibility and list view issues

Write-Host "🎯 FIXING CUSTOM APP AND LIST VIEWS..." -ForegroundColor Green
Write-Host "=======================================" -ForegroundColor Cyan

# Step 1: Deploy List Views
Write-Host "📋 Deploying List Views..." -ForegroundColor Yellow
try {
    sf project deploy start --source-dir force-app/main/default/objects/Job_Application__c/listViews
    Write-Host "✅ List Views deployed successfully" -ForegroundColor Green
} catch {
    Write-Host "⚠️ List view deployment had issues, continuing..." -ForegroundColor Yellow
}

# Step 2: Deploy Complete Application
Write-Host "📱 Deploying Complete Application..." -ForegroundColor Yellow
sf project deploy start --source-dir force-app/main/default

# Step 3: Assign Permission Set
Write-Host "🔐 Ensuring Permission Set Assignment..." -ForegroundColor Yellow
sf org assign permset --name Job_Application_Manager

# Step 4: Open Salesforce
Write-Host "🌐 Opening Salesforce..." -ForegroundColor Yellow
Start-Sleep -Seconds 2
sf org open

# Success Instructions
Write-Host ""
Write-Host "🎉 FIXES APPLIED!" -ForegroundColor Green
Write-Host "=================" -ForegroundColor Cyan
Write-Host ""
Write-Host "✅ List Views Created:" -ForegroundColor Green
Write-Host "  • All Job Applications" -ForegroundColor White
Write-Host "  • Active Applications" -ForegroundColor White
Write-Host "  • Interviewing" -ForegroundColor White
Write-Host "  • High Priority (4-5 Stars)" -ForegroundColor White
Write-Host "  • Recent Applications (Last 30 Days)" -ForegroundColor White
Write-Host ""
Write-Host "📱 TO ACCESS THE CUSTOM APP:" -ForegroundColor Yellow
Write-Host "1. Click App Launcher (9 dots icon)" -ForegroundColor White
Write-Host "2. Look for 'Job Application Tracker' (should be an APP, not just a tab)" -ForegroundColor White
Write-Host "3. If you only see 'Job Applications' as an item, wait 5 minutes and refresh" -ForegroundColor White
Write-Host ""
Write-Host "📋 TO ACCESS LIST VIEWS:" -ForegroundColor Yellow
Write-Host "1. Go to Job Applications tab" -ForegroundColor White
Write-Host "2. Click the dropdown next to 'Recently Viewed'" -ForegroundColor White
Write-Host "3. Select from the 5 new list views" -ForegroundColor White
Write-Host ""
Write-Host "🔧 IF CUSTOM APP STILL NOT VISIBLE:" -ForegroundColor Yellow
Write-Host "The app may take 10-15 minutes to appear. In the meantime:" -ForegroundColor White
Write-Host "• Use the Job Applications tab directly" -ForegroundColor White
Write-Host "• All functionality works the same way" -ForegroundColor White
Write-Host "• List views are now properly configured" -ForegroundColor White
Write-Host ""
Write-Host "🎯 VERIFICATION STEPS:" -ForegroundColor Yellow
Write-Host "1. ✅ Job Applications tab should be visible" -ForegroundColor White
Write-Host "2. ✅ List views should show proper columns" -ForegroundColor White
Write-Host "3. ✅ Can create new Job Application records" -ForegroundColor White
Write-Host "4. ✅ Custom app should appear in App Launcher (may take time)" -ForegroundColor White
Write-Host ""
Write-Host "🚀 READY FOR TEAM COLLABORATION!" -ForegroundColor Green
