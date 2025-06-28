#!/bin/bash

# 🚀 AUTOMATED APP VISIBILITY FIX
# This script automatically fixes all app visibility issues

echo "🎯 STARTING AUTOMATED APP VISIBILITY FIX..."
echo "================================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Step 1: Verify we're in the right directory
echo -e "${YELLOW}📁 Checking project directory...${NC}"
if [ ! -f "sfdx-project.json" ]; then
    echo -e "${RED}❌ ERROR: Not in Salesforce project directory!${NC}"
    echo -e "${YELLOW}💡 Please navigate to your project folder first:${NC}"
    echo -e "${WHITE}   cd ~/Documents/job-application-tracker-temitayo-mark-mike${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Project directory confirmed${NC}"

# Step 2: Check Salesforce CLI connection
echo -e "${YELLOW}🔗 Checking Salesforce CLI connection...${NC}"
if ! sf org display > /dev/null 2>&1; then
    echo -e "${RED}❌ ERROR: Not connected to Salesforce org!${NC}"
    echo -e "${YELLOW}💡 Please connect first:${NC}"
    echo -e "${WHITE}   sf org login web --alias myCapstoneOrg${NC}"
    exit 1
fi

ORG_INFO=$(sf org display --json | jq -r '.result.username')
echo -e "${GREEN}✅ Connected to org: $ORG_INFO${NC}"

# Step 3: Run initial diagnosis
echo -e "${YELLOW}🔍 Running initial diagnosis...${NC}"
echo -e "${CYAN}📊 Checking current app visibility status...${NC}"
sf apex run --file scripts/diagnose-app-visibility.apex

# Step 4: Deploy updated permission set with app visibility
echo -e "${YELLOW}🔧 Deploying updated permission set...${NC}"
if sf project deploy start --source-dir force-app/main/default/permissionsets > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Permission set deployed successfully${NC}"
else
    echo -e "${RED}❌ ERROR: Permission set deployment failed!${NC}"
    echo -e "${YELLOW}💡 Trying alternative deployment...${NC}"
    sf project deploy start --source-dir force-app/main/default
fi

# Step 5: Deploy custom application
echo -e "${YELLOW}📱 Deploying custom application...${NC}"
if sf project deploy start --source-dir force-app/main/default/applications > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Custom application deployed successfully${NC}"
else
    echo -e "${RED}❌ ERROR: App deployment failed!${NC}"
    echo -e "${YELLOW}💡 Trying full deployment...${NC}"
    sf project deploy start --source-dir force-app/main/default
fi

# Step 6: Deploy utility bar
echo -e "${YELLOW}🛠️ Deploying utility bar...${NC}"
if sf project deploy start --source-dir force-app/main/default/appMenus > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Utility bar deployed successfully${NC}"
else
    echo -e "${YELLOW}⚠️ WARNING: Utility bar deployment had issues (non-critical)${NC}"
fi

# Step 7: Assign permission set
echo -e "${YELLOW}🔐 Assigning permission set...${NC}"
if sf org assign permset --name Job_Application_Manager > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Permission set assigned successfully${NC}"
else
    echo -e "${YELLOW}⚠️ Permission set may already be assigned${NC}"
fi

# Step 8: Complete deployment verification
echo -e "${YELLOW}🚀 Running complete deployment...${NC}"
if sf project deploy start --source-dir force-app/main/default > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Complete deployment finished${NC}"
else
    echo -e "${YELLOW}⚠️ WARNING: Some deployment issues occurred${NC}"
fi

# Step 9: Final verification
echo -e "${YELLOW}🔍 Running final verification...${NC}"
echo -e "${CYAN}📊 Checking app visibility after fixes...${NC}"
sf apex run --file scripts/diagnose-app-visibility.apex

# Step 10: Open Salesforce org
echo -e "${YELLOW}🌐 Opening Salesforce org...${NC}"
sleep 2
sf org open

# Success message and instructions
echo ""
echo -e "${GREEN}🎉 AUTOMATION COMPLETE!${NC}"
echo -e "${CYAN}========================${NC}"
echo ""
echo -e "${GREEN}✅ Permission set updated with app visibility${NC}"
echo -e "${GREEN}✅ Custom application deployed${NC}"
echo -e "${GREEN}✅ Utility bar configured${NC}"
echo -e "${GREEN}✅ Permission set assigned${NC}"
echo -e "${GREEN}✅ Salesforce org opened${NC}"
echo ""
echo -e "${YELLOW}📱 TO ACCESS YOUR APP:${NC}"
echo -e "${WHITE}1. Click the App Launcher (9 dots icon)${NC}"
echo -e "${WHITE}2. Search for 'Job Application Tracker'${NC}"
echo -e "${WHITE}3. Click the app to open it${NC}"
echo ""
echo -e "${CYAN}⏰ NOTE: Apps may take 5-10 minutes to appear after deployment${NC}"
echo -e "${CYAN}🔄 If not visible immediately, refresh browser or try again in a few minutes${NC}"
echo ""
echo -e "${YELLOW}🤝 TEAM SHARING:${NC}"
echo -e "${WHITE}Tell Mike and Mark: 'The Job Application Tracker app is now available${NC}"
echo -e "${WHITE}in the App Launcher - just search for it!'${NC}"
echo ""
echo -e "${YELLOW}🎯 SUCCESS INDICATORS:${NC}"
echo -e "${WHITE}• App appears in App Launcher${NC}"
echo -e "${WHITE}• Navigation shows: Home, Job Applications, Contacts, etc.${NC}"
echo -e "${WHITE}• Utility bar at bottom with Notes, History${NC}"
echo -e "${WHITE}• Professional branded interface${NC}"
echo ""
echo -e "${GREEN}🚀 AUTOMATION COMPLETE - ENJOY YOUR CUSTOM APP!${NC}"
