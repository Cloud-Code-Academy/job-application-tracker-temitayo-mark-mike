@echo off
echo ========================================
echo QUICK CUSTOM APP FIX
echo ========================================

echo Checking Salesforce connection...
sf org display
if errorlevel 1 (
    echo ERROR: Not connected to Salesforce
    echo Run: sf org login web --alias myCapstoneOrg
    pause
    exit
)

echo.
echo Deploying custom app...
sf project deploy start --source-dir force-app/main/default/applications

echo.
echo Deploying permission set...
sf project deploy start --source-dir force-app/main/default/permissionsets

echo.
echo Assigning permission set...
sf org assign permset --name Job_Application_Manager

echo.
echo Running investigation...
sf apex run --file scripts/deep-app-investigation.apex

echo.
echo Opening Salesforce...
sf org open

echo.
echo ========================================
echo MANUAL VERIFICATION STEPS:
echo ========================================
echo 1. Check Lightning Experience (URL has lightning.force.com)
echo 2. Setup - Apps - App Manager
echo 3. Look for "Job Application Tracker"
echo 4. App Launcher (9 dots) - Search "Job Application Tracker"
echo 5. If not found, create manually in App Manager
echo.
pause
