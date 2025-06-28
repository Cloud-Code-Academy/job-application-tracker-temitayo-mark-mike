// DEEP INVESTIGATION: Why custom app isn't appearing
System.debug('=== DEEP CUSTOM APP INVESTIGATION ===');

// 1. Check current user profile and permissions
User currentUser = [
    SELECT Id, Name, Email, Profile.Name, Profile.Id, UserType, IsActive
    FROM User 
    WHERE Id = :UserInfo.getUserId()
];

System.debug('👤 USER DETAILS:');
System.debug('  • Name: ' + currentUser.Name);
System.debug('  • Email: ' + currentUser.Email);
System.debug('  • Profile: ' + currentUser.Profile.Name);
System.debug('  • Profile ID: ' + currentUser.Profile.Id);
System.debug('  • User Type: ' + currentUser.UserType);
System.debug('  • Active: ' + currentUser.IsActive);

// 2. Check all permission set assignments
List<PermissionSetAssignment> allPermSets = [
    SELECT PermissionSet.Name, PermissionSet.Label, PermissionSet.Type
    FROM PermissionSetAssignment 
    WHERE AssigneeId = :UserInfo.getUserId()
];

System.debug('🔐 ALL PERMISSION SETS (' + allPermSets.size() + '):');
Boolean hasJobAppManager = false;
for (PermissionSetAssignment psa : allPermSets) {
    System.debug('  • ' + psa.PermissionSet.Label + ' (' + psa.PermissionSet.Name + ') - Type: ' + psa.PermissionSet.Type);
    if (psa.PermissionSet.Name == 'Job_Application_Manager') {
        hasJobAppManager = true;
    }
}

System.debug('✅ Has Job_Application_Manager: ' + hasJobAppManager);

// 3. Check Lightning Experience
System.debug('⚡ LIGHTNING EXPERIENCE CHECK:');
String uiTheme = UserInfo.getUiThemeDisplayed();
System.debug('  • UI Theme: ' + uiTheme);
System.debug('  • Is Lightning: ' + (uiTheme == 'Theme4d' ? 'YES ✅' : 'NO ❌ (This could be the issue!)'));

// 4. Check organization info
System.debug('🏢 ORGANIZATION INFO:');
System.debug('  • Org ID: ' + UserInfo.getOrganizationId());
System.debug('  • Org Name: ' + UserInfo.getOrganizationName());

// 5. Test object access in detail
System.debug('📊 DETAILED OBJECT ACCESS CHECK:');
try {
    Schema.DescribeSObjectResult jobAppDescribe = Job_Application__c.SObjectType.getDescribe();
    System.debug('  • Object Label: ' + jobAppDescribe.getLabel());
    System.debug('  • Object API Name: ' + jobAppDescribe.getName());
    System.debug('  • Accessible: ' + jobAppDescribe.isAccessible());
    System.debug('  • Createable: ' + jobAppDescribe.isCreateable());
    System.debug('  • Custom: ' + jobAppDescribe.isCustom());
    System.debug('  • Deployable: ' + jobAppDescribe.isDeletable());
    
    // Try to query records
    List<Job_Application__c> records = [SELECT Id, Name, Company_Name__c FROM Job_Application__c LIMIT 3];
    System.debug('  • Records Found: ' + records.size());
    
} catch (Exception e) {
    System.debug('❌ Object Access Error: ' + e.getMessage());
}

// 6. Check tab access
System.debug('📋 TAB ACCESS CHECK:');
try {
    // This will tell us if the tab is accessible
    List<Schema.DescribeTabSetResult> tabSets = Schema.describeTabs();
    Boolean foundJobAppTab = false;
    
    for (Schema.DescribeTabSetResult tabSet : tabSets) {
        for (Schema.DescribeTabResult tab : tabSet.getTabs()) {
            if (tab.getSObjectName() == 'Job_Application__c') {
                foundJobAppTab = true;
                System.debug('  • Job Applications Tab Found: ✅');
                System.debug('  • Tab Label: ' + tab.getLabel());
                System.debug('  • Tab Available: ' + tab.isAvailable());
                break;
            }
        }
        if (foundJobAppTab) break;
    }
    
    if (!foundJobAppTab) {
        System.debug('  • Job Applications Tab: ❌ NOT FOUND');
    }
    
} catch (Exception e) {
    System.debug('❌ Tab Check Error: ' + e.getMessage());
}

// 7. Provide specific troubleshooting steps
System.debug('');
System.debug('🔧 SPECIFIC TROUBLESHOOTING STEPS:');
System.debug('');

if (uiTheme != 'Theme4d') {
    System.debug('❗ CRITICAL ISSUE: You\'re not in Lightning Experience!');
    System.debug('💡 SOLUTION: Switch to Lightning Experience');
    System.debug('   1. Click your profile picture (top right)');
    System.debug('   2. Select "Switch to Lightning Experience"');
    System.debug('   3. Custom apps only work in Lightning!');
    System.debug('');
}

if (!hasJobAppManager) {
    System.debug('❗ ISSUE: Job Application Manager permission set not assigned');
    System.debug('💡 SOLUTION: Run this command:');
    System.debug('   sf org assign permset --name Job_Application_Manager');
    System.debug('');
}

System.debug('🎯 CUSTOM APP TROUBLESHOOTING CHECKLIST:');
System.debug('');
System.debug('1. ✅ Check Lightning Experience (CRITICAL)');
System.debug('   • Must be in Lightning, not Classic');
System.debug('   • Custom apps don\'t work in Classic');
System.debug('');
System.debug('2. ✅ Verify App Deployment');
System.debug('   • Go to Setup → Apps → App Manager');
System.debug('   • Look for "Job Application Tracker"');
System.debug('   • Should show as "Active"');
System.debug('');
System.debug('3. ✅ Check Permission Assignment');
System.debug('   • Setup → Permission Sets → Job Application Manager');
System.debug('   • Check "Manage Assignments"');
System.debug('   • Your user should be listed');
System.debug('');
System.debug('4. ✅ Clear Browser Cache');
System.debug('   • Ctrl+Shift+Delete (Windows)');
System.debug('   • Cmd+Shift+Delete (Mac)');
System.debug('   • Clear all Salesforce cookies');
System.debug('');
System.debug('5. ✅ Try Incognito/Private Mode');
System.debug('   • Open new incognito window');
System.debug('   • Login to Salesforce');
System.debug('   • Check App Launcher');
System.debug('');

System.debug('🚨 IMMEDIATE ACTIONS TO TRY:');
System.debug('1. Switch to Lightning Experience (if not already)');
System.debug('2. Clear browser cache completely');
System.debug('3. Log out and back in');
System.debug('4. Check Setup → Apps → App Manager');
System.debug('5. Try different browser');
System.debug('');

System.debug('📱 ALTERNATIVE ACCESS METHODS:');
System.debug('• Direct URL: /lightning/app/c__Job_Application_Tracker');
System.debug('• Setup → Apps → App Manager → Job Application Tracker → View');
System.debug('• Global Search: Search for "Job Application Tracker"');
System.debug('');

System.debug('=== INVESTIGATION COMPLETE ===');
System.debug('Run the troubleshooting steps above based on the findings!');
