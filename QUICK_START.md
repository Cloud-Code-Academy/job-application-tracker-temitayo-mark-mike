# Quick Start Commands for Temitayo's Capstone Project

# Copy and paste these commands one by one in Command Prompt or VS Code Terminal

# 1. Navigate to your project
cd "C:\Users\tayof\Documents\job-application-tracker-temitayo-mark-mike"

# 2. Open VS Code
code .

# 3. Install project dependencies (run in VS Code terminal)
npm install

# 4. Authorize your capstone org (will open browser)
sf org login web --alias myCapstoneOrg --instance-url https://login.salesforce.com
# Login with: capstone@taju.com / Olusammy11

# 5. Set as default org
sf config set target-org=myCapstoneOrg

# 6. Verify connection
sf org display

# 7. Deploy Job Application metadata
sf project deploy start --source-dir force-app/main/default

# 8. Assign permissions
sf org assign permset --name Job_Application_Manager

# 9. Open Salesforce to test
sf org open

# 10. Create feature branch
git checkout -b feature/temitayo-data-model

# 11. Commit initial setup
git add .
git commit -m "feat: initial capstone org setup with Job Application object"
git push origin feature/temitayo-data-model

# SUCCESS! 🎉 Your capstone project is ready for development!