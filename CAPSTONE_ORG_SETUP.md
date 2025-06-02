# Capstone Org Setup Guide 🎯

## Setup Overview

This guide helps you connect your Salesforce Developer Org for the Job Application Tracker capstone project.

**Note**: Org credentials are stored in `private-learning/org-configuration/` (local only, never committed to Git)

## Quick Setup Commands

Run these commands in your VS Code terminal from the project directory:

```bash
# 1. Navigate to project (if not already there)
cd "C:\Users\tayof\Documents\job-application-tracker-temitayo-mark-mike"

# 2. Install dependencies
npm install

# 3. Authorize your capstone org
sf org login web --alias myCapstoneOrg --instance-url https://login.salesforce.com
# Use your Developer Org credentials (stored in private-learning/org-configuration/)

# 4. Set as default org for this project
sf config set target-org=myCapstoneOrg

# 5. Verify connection
sf org display

# 6. Deploy Job Application object and all metadata
sf project deploy start --source-dir force-app/main/default

# 7. Assign permission set to your user
sf org assign permset --name Job_Application_Manager

# 8. Open your org to test
sf org open

# 9. Create your feature branch
git checkout -b feature/temitayo-data-model

# 10. Commit your setup
git add .
git commit -m "feat: initial capstone org setup with Job Application object"
git push origin feature/temitayo-data-model
```

## Alternative Manual Login (if web login has issues)

If the web login doesn't work, you can use manual username/password login:

```bash
# Alternative login method
sf org login --username [your-username] --alias myCapstoneOrg
# When prompted, enter your password
```

## Verification Steps

After running the setup commands, verify everything works:

### 1. Check Org Connection
```bash
sf org display --target-org myCapstoneOrg
```
Should show your org details and confirm connection.

### 2. Check Deployment Status
```bash
sf project deploy start --dry-run --source-dir force-app/main/default
```
Should show "Component deployed successfully" for all files.

### 3. Test in Salesforce UI
1. Run `sf org open` to open Salesforce
2. Click App Launcher (9 dots icon)
3. Search for "Job Applications"
4. Click "New" button
5. Create a test Job Application record
6. Verify all fields are present and working

### 4. Check Permission Set Assignment
In Salesforce Setup:
1. Go to Setup → Users → Permission Sets
2. Click "Job Application Manager"
3. Click "Manage Assignments"
4. Verify your user is assigned

## Development Workflow

### Daily Development Commands
```bash
# Start development session
cd "C:\Users\tayof\Documents\job-application-tracker-temitayo-mark-mike"
code .

# Deploy changes after making modifications
sf project deploy start --source-dir force-app/main/default

# Open org for testing
sf org open --target-org myCapstoneOrg

# Check deployment status
sf project deploy report
```

### Working with Git
```bash
# Daily workflow
git status                              # Check what's changed
git add .                              # Stage changes
git commit -m "feat: description"     # Commit with message
git push origin feature/temitayo-data-model  # Push to GitHub

# Stay synced with team
git pull origin main                   # Get latest from main branch
git merge main                         # Merge into your feature branch
```

## AI-Powered Development Setup

Since you're using Claude 4 Sonnet for development:

### VS Code Extensions for AI Development
1. **Salesforce Extension Pack** (Essential)
2. **Claude AI Assistant** or **GitHub Copilot** (AI coding help)
3. **GitLens** (Git integration)
4. **XML Tools** (Salesforce metadata editing)
5. **Prettier** (Code formatting)

### Claude Integration Tips
- Use Claude for Apex class generation
- Get help with complex SOQL queries
- Generate test classes with proper coverage
- Design LWC components with best practices
- Create automation flows and process builders

## Troubleshooting

### Common Issues and Solutions

**Issue**: "Entity of type 'CustomObject' named 'Job_Application__c' cannot be found"
**Solution**: 
```bash
sf project deploy start --source-dir force-app/main/default/objects --target-org myCapstoneOrg
```

**Issue**: "Permission denied" errors
**Solution**: 
```bash
sf org assign permset --name Job_Application_Manager --target-org myCapstoneOrg
```

**Issue**: "INVALID_LOGIN: Invalid username, password, security token; or user locked out"
**Solution**: 
- Verify credentials in your private org configuration file
- Check if org is locked/suspended
- Try resetting password in Salesforce

**Issue**: Git push fails
**Solution**: 
```bash
git pull origin main
git merge main
git push origin feature/temitayo-data-model
```

## Solo Learning Approach

For comprehensive understanding:
1. **Document everything** in `private-learning/` directory
2. **Build each component yourself** before moving to next
3. **Test thoroughly** with sample data
4. **Ask questions** and research answers
5. **Master troubleshooting** common issues

## Team Coordination (Future)

When ready to collaborate, share:
- Repository structure and progress
- Technical architecture decisions
- Code review standards
- Development workflow processes

**Note**: Never share private learning materials or org credentials

## Next Week's Goals

With your capstone org setup complete:
- ✅ **Week 1**: Data model complete
- 🔄 **Week 2**: Build automation triggers and flows
- 🔄 **Week 3**: Create Lightning Web Components  
- 🔄 **Week 4**: Implement API integrations
- 🔄 **Week 5**: Complete testing and deployment

**You're ready to build amazing Salesforce solutions! 🚀**