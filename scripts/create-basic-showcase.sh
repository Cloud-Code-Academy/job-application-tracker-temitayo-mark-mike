#!/bin/bash

# Create diverse job application data for showcase
echo "Creating showcase data for Job Application Tracker..."

# Tech Companies - Various statuses
sf data create record --sobject Job_Application__c --values "Company_Name__c='Microsoft' Position_Title__c='Software Engineer II' Status__c='Interviewing'" --target-org capstone@taju.com
sf data create record --sobject Job_Application__c --values "Company_Name__c='Google' Position_Title__c='Product Manager' Status__c='Negotiating'" --target-org capstone@taju.com
sf data create record --sobject Job_Application__c --values "Company_Name__c='Amazon' Position_Title__c='Data Scientist' Status__c='Closed'" --target-org capstone@taju.com
sf data create record --sobject Job_Application__c --values "Company_Name__c='Meta' Position_Title__c='Frontend Developer' Status__c='Applied'" --target-org capstone@taju.com
sf data create record --sobject Job_Application__c --values "Company_Name__c='Netflix' Position_Title__c='DevOps Engineer' Status__c='Interviewing'" --target-org capstone@taju.com

# Finance Companies
sf data create record --sobject Job_Application__c --values "Company_Name__c='JPMorgan Chase' Position_Title__c='Business Analyst' Status__c='Applied'" --target-org capstone@taju.com
sf data create record --sobject Job_Application__c --values "Company_Name__c='Goldman Sachs' Position_Title__c='Quantitative Analyst' Status__c='Interviewing'" --target-org capstone@taju.com
sf data create record --sobject Job_Application__c --values "Company_Name__c='Wells Fargo' Position_Title__c='Project Manager' Status__c='Accepted'" --target-org capstone@taju.com

# Healthcare Companies
sf data create record --sobject Job_Application__c --values "Company_Name__c='Johnson & Johnson' Position_Title__c='Data Analyst' Status__c='Applied'" --target-org capstone@taju.com
sf data create record --sobject Job_Application__c --values "Company_Name__c='Pfizer' Position_Title__c='Clinical Research Associate' Status__c='Interviewing'" --target-org capstone@taju.com

# Consulting Companies
sf data create record --sobject Job_Application__c --values "Company_Name__c='McKinsey & Company' Position_Title__c='Business Analyst' Status__c='Interviewing'" --target-org capstone@taju.com
sf data create record --sobject Job_Application__c --values "Company_Name__c='Accenture' Position_Title__c='Digital Consultant' Status__c='Accepted'" --target-org capstone@taju.com
sf data create record --sobject Job_Application__c --values "Company_Name__c='Deloitte' Position_Title__c='Technology Consultant' Status__c='Applied'" --target-org capstone@taju.com

# Startups and Other Companies
sf data create record --sobject Job_Application__c --values "Company_Name__c='Stripe' Position_Title__c='Backend Engineer' Status__c='Applied'" --target-org capstone@taju.com
sf data create record --sobject Job_Application__c --values "Company_Name__c='Zoom' Position_Title__c='Customer Success Manager' Status__c='Interviewing'" --target-org capstone@taju.com
sf data create record --sobject Job_Application__c --values "Company_Name__c='Slack' Position_Title__c='Marketing Manager' Status__c='Applied'" --target-org capstone@taju.com
sf data create record --sobject Job_Application__c --values "Company_Name__c='DocuSign' Position_Title__c='Sales Development Rep' Status__c='Applied'" --target-org capstone@taju.com
sf data create record --sobject Job_Application__c --values "Company_Name__c='Shopify' Position_Title__c='Full Stack Developer' Status__c='Applied'" --target-org capstone@taju.com

echo "Showcase data creation completed!"
echo "Created 18 diverse job applications across different industries and statuses."
echo "Our triggers should have automatically created follow-up tasks for each application!"
