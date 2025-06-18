# Simple App Check - No complex formatting
Write-Host "Checking Custom App Status..."

# Check files exist
if (Test-Path "force-app/main/default/applications/Job_Application_Tracker.app-meta.xml") {
    Write-Host "✅ App file exists"
} else {
    Write-Host "❌ App file missing"
}

# Check connection
try {
    sf org display
    Write-Host "✅ Connected to Salesforce"
} catch {
    Write-Host "❌ Not connected to Salesforce"
    Write-Host "Run: sf org login web --alias myCapstoneOrg"
    exit
}

# Deploy app
Write-Host "Deploying custom app..."
sf project deploy start --source-dir force-app/main/default/applications

# Deploy permission set
Write-Host "Deploying permission set..."
sf project deploy start --source-dir force-app/main/default/permissionsets

# Assign permission set
Write-Host "Assigning permission set..."
sf org assign permset --name Job_Application_Manager

# Run investigation
Write-Host "Running investigation..."
sf apex run --file scripts/deep-app-investigation.apex

# Open Salesforce
Write-Host "Opening Salesforce..."
sf org open

Write-Host ""
Write-Host "MANUAL STEPS:"
Write-Host "1. Check if you're in Lightning Experience"
Write-Host "2. Go to Setup > Apps > App Manager"
Write-Host "3. Look for 'Job Application Tracker'"
Write-Host "4. Check App Launcher (9 dots icon)"
Write-Host "5. If still not working, create manually:"
Write-Host "   Setup > App Manager > New Lightning App"
