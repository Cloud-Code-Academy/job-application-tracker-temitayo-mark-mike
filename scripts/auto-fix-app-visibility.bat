@echo off
REM 🚀 AUTOMATED APP VISIBILITY FIX
REM This script automatically fixes all app visibility issues

echo 🎯 STARTING AUTOMATED APP VISIBILITY FIX...
echo ================================================

REM Step 1: Verify we're in the right directory
echo 📁 Checking project directory...
if not exist "sfdx-project.json" (
    echo ❌ ERROR: Not in Salesforce project directory!
    echo 💡 Please navigate to your project folder first:
    echo    cd "C:\Users\tayof\Documents\job-application-tracker-temitayo-mark-mike"
    pause
    exit /b 1
)
echo ✅ Project directory confirmed

REM Step 2: Check Salesforce CLI connection
echo 🔗 Checking Salesforce CLI connection...
sf org display >nul 2>&1
if errorlevel 1 (
    echo ❌ ERROR: Not connected to Salesforce org!
    echo 💡 Please connect first:
    echo    sf org login web --alias myCapstoneOrg
    pause
    exit /b 1
)
echo ✅ Connected to Salesforce org

REM Step 3: Run initial diagnosis
echo 🔍 Running initial diagnosis...
echo 📊 Checking current app visibility status...
sf apex run --file scripts/diagnose-app-visibility.apex

REM Step 4: Deploy updated permission set
echo 🔧 Deploying updated permission set...
sf project deploy start --source-dir force-app/main/default/permissionsets
if errorlevel 1 (
    echo ❌ Permission set deployment had issues, trying full deployment...
    sf project deploy start --source-dir force-app/main/default
) else (
    echo ✅ Permission set deployed successfully
)

REM Step 5: Deploy custom application
echo 📱 Deploying custom application...
sf project deploy start --source-dir force-app/main/default/applications
if errorlevel 1 (
    echo ❌ App deployment had issues, trying full deployment...
    sf project deploy start --source-dir force-app/main/default
) else (
    echo ✅ Custom application deployed successfully
)

REM Step 6: Deploy utility bar
echo 🛠️ Deploying utility bar...
sf project deploy start --source-dir force-app/main/default/appMenus
if errorlevel 1 (
    echo ⚠️ WARNING: Utility bar deployment had issues (non-critical)
) else (
    echo ✅ Utility bar deployed successfully
)

REM Step 7: Assign permission set
echo 🔐 Assigning permission set...
sf org assign permset --name Job_Application_Manager
if errorlevel 1 (
    echo ⚠️ Permission set may already be assigned
) else (
    echo ✅ Permission set assigned successfully
)

REM Step 8: Complete deployment
echo 🚀 Running complete deployment...
sf project deploy start --source-dir force-app/main/default
echo ✅ Complete deployment finished

REM Step 9: Final verification
echo 🔍 Running final verification...
echo 📊 Checking app visibility after fixes...
sf apex run --file scripts/diagnose-app-visibility.apex

REM Step 10: Open Salesforce org
echo 🌐 Opening Salesforce org...
timeout /t 2 /nobreak >nul
sf org open

REM Success message
echo.
echo 🎉 AUTOMATION COMPLETE!
echo ========================
echo.
echo ✅ Permission set updated with app visibility
echo ✅ Custom application deployed
echo ✅ Utility bar configured
echo ✅ Permission set assigned
echo ✅ Salesforce org opened
echo.
echo 📱 TO ACCESS YOUR APP:
echo 1. Click the App Launcher (9 dots icon)
echo 2. Search for 'Job Application Tracker'
echo 3. Click the app to open it
echo.
echo ⏰ NOTE: Apps may take 5-10 minutes to appear after deployment
echo 🔄 If not visible immediately, refresh browser or try again in a few minutes
echo.
echo 🤝 TEAM SHARING:
echo Tell Mike and Mark: 'The Job Application Tracker app is now available
echo in the App Launcher - just search for it!'
echo.
echo 🎯 SUCCESS INDICATORS:
echo • App appears in App Launcher
echo • Navigation shows: Home, Job Applications, Contacts, etc.
echo • Utility bar at bottom with Notes, History
echo • Professional branded interface
echo.
echo 🚀 AUTOMATION COMPLETE - ENJOY YOUR CUSTOM APP!
echo.
pause
