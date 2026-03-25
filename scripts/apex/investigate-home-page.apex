// 1. Check current user info
System.debug('=== CURRENT USER ===');
User u = [SELECT Id, Name, ProfileId, Profile.Name FROM User WHERE Id = :UserInfo.getUserId()];
System.debug('User: ' + u.Name);
System.debug('Profile: ' + u.Profile.Name);

// 3. Check if the custom tab exists
List<TabDefinition> tabs = [SELECT Name, Label, IsCustom, SobjectName FROM TabDefinition WHERE Name = 'Job_Tracker_Home'];
System.debug('=== TAB DEFINITION ===');
System.debug('Found: ' + tabs.size());
for (TabDefinition td : tabs) {
    System.debug('  Name: ' + td.Name + ' | Label: ' + td.Label + ' | Custom: ' + td.IsCustom);
}

// 4. Check app
List<AppDefinition> apps = [SELECT DeveloperName, Label, Description FROM AppDefinition WHERE DeveloperName = 'Job_Application_Tracker'];
System.debug('=== APP DEFINITION ===');
System.debug('Found: ' + apps.size());
for (AppDefinition ad : apps) {
    System.debug('  Name: ' + ad.DeveloperName + ' | Label: ' + ad.Label);
}

// 5. Check permission set assignments for current user
List<PermissionSetAssignment> psas = [SELECT PermissionSet.Name, PermissionSet.Label FROM PermissionSetAssignment WHERE AssigneeId = :UserInfo.getUserId()];
System.debug('=== PERMISSION SETS ASSIGNED ===');
for (PermissionSetAssignment psa : psas) {
    System.debug('  ' + psa.PermissionSet.Name + ' (' + psa.PermissionSet.Label + ')');
}

// 6. Check if data service works
try {
    Map<String, Object> analytics = ApplicationAnalyticsService.getApplicationAnalytics();
    System.debug('=== DATA SERVICE ===');
    System.debug('Analytics keys: ' + analytics.keySet());
    System.debug('Total Apps: ' + analytics.get('totalApplications'));
} catch (Exception e) {
    System.debug('=== DATA SERVICE ERROR ===');
    System.debug(e.getMessage());
}

// 7. Check tab settings for the profile
List<PermissionSet> profilePS = [SELECT Id, Name, ProfileId, Profile.Name FROM PermissionSet WHERE ProfileId = :u.ProfileId];
System.debug('=== PROFILE PERMISSION SET ===');
for (PermissionSet ps : profilePS) {
    System.debug('  PS ID: ' + ps.Id + ' | Name: ' + ps.Name + ' | Profile: ' + ps.Profile.Name);
}
