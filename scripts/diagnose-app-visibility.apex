// Comprehensive diagnosis of app visibility issues
System.debug('=== DIAGNOSING APP VISIBILITY ISSUES ===');

// 1. Check current user information
User currentUser = [SELECT Id, Name, Email, Profile.Name, UserRole.Name FROM User WHERE Id = :UserInfo.getUserId()];
System.debug('👤 Current User: ' + currentUser.Name);
System.debug('📧 Email: ' + currentUser.Email);
System.debug('🏷️ Profile: ' + currentUser.Profile.Name);
System.debug('🎭 Role: ' + (currentUser.UserRole?.Name ?? 'No Role'));

// 2. Check permission set assignments
List<PermissionSetAssignment> permSets = [
    SELECT PermissionSet.Name, PermissionSet.Label 
    FROM PermissionSetAssignment 
    WHERE AssigneeId = :UserInfo.getUserId()
];
System.debug('🔐 Permission Sets Assigned: ' + permSets.size());
for (PermissionSetAssignment psa : permSets) {
    System.debug('  • ' + psa.PermissionSet.Label + ' (' + psa.PermissionSet.Name + ')');
}

// 3. Check if Job Application Manager permission set is assigned
Boolean hasJobAppManager = false;
for (PermissionSetAssignment psa : permSets) {
    if (psa.PermissionSet.Name == 'Job_Application_Manager') {
        hasJobAppManager = true;
        break;
    }
}
System.debug('✅ Has Job Application Manager: ' + hasJobAppManager);

// 4. Check object access
try {
    Schema.DescribeSObjectResult jobAppDescribe = Job_Application__c.SObjectType.getDescribe();
    System.debug('📊 Job Application Object Access:');
    System.debug('  • Accessible: ' + jobAppDescribe.isAccessible());
    System.debug('  • Createable: ' + jobAppDescribe.isCreateable());
    System.debug('  • Updateable: ' + jobAppDescribe.isUpdateable());
    System.debug('  • Deletable: ' + jobAppDescribe.isDeletable());
} catch (Exception e) {
    System.debug('❌ Error accessing Job Application object: ' + e.getMessage());
}

// 5. Check tab visibility
try {
    List<Job_Application__c> testRecords = [SELECT Id, Name FROM Job_Application__c LIMIT 1];
    System.debug('📋 Can query Job Applications: ✅ (' + testRecords.size() + ' records found)');
} catch (Exception e) {
    System.debug('❌ Cannot query Job Applications: ' + e.getMessage());
}

// 6. Check Lightning Experience
System.debug('⚡ Lightning Experience Check:');
System.debug('  • User Interface: ' + (UserInfo.getUiThemeDisplayed() == 'Theme4d' ? 'Lightning' : 'Classic'));

// 7. Provide solutions
System.debug('');
System.debug('🔧 SOLUTIONS TO TRY:');
System.debug('');

if (!hasJobAppManager) {
    System.debug('❗ ISSUE: Job Application Manager permission set not assigned');
    System.debug('💡 SOLUTION: Run this command:');
    System.debug('   sf org assign permset --name Job_Application_Manager');
    System.debug('');
}

System.debug('🎯 APP VISIBILITY CHECKLIST:');
System.debug('1. ✅ Deploy custom app: sf project deploy start --source-dir force-app/main/default');
System.debug('2. ✅ Assign permission set: sf org assign permset --name Job_Application_Manager');
System.debug('3. ✅ Refresh browser completely (Ctrl+F5)');
System.debug('4. ✅ Check App Launcher (9 dots) → Search "Job Application Tracker"');
System.debug('5. ✅ If still not visible, check Setup → Apps → App Manager');
System.debug('');

System.debug('🔍 ALTERNATIVE ACCESS METHODS:');
System.debug('• Direct Tab: Look for "Job Applications" tab in any app');
System.debug('• Global Search: Search for "Job Application" in the search bar');
System.debug('• Setup: Setup → Object Manager → Job Application → Tab');
System.debug('');

System.debug('📱 CUSTOM APP TROUBLESHOOTING:');
System.debug('• App may take 5-10 minutes to appear after deployment');
System.debug('• Try logging out and back in');
System.debug('• Clear browser cache and cookies');
System.debug('• Check if you\'re in Lightning Experience (not Classic)');
System.debug('');

System.debug('🎉 ONCE WORKING:');
System.debug('• App Launcher → "Job Application Tracker"');
System.debug('• Should see all tabs: Home, Job Applications, Contacts, etc.');
System.debug('• Utility bar at bottom with Notes, History, Rich Text');
System.debug('');

System.debug('=== DIAGNOSIS COMPLETE ===');
