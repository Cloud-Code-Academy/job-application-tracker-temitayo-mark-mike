// Search for all custom tabs
List<TabDefinition> allTabs = [SELECT Name, Label, IsCustom FROM TabDefinition WHERE IsCustom = true ORDER BY Name];
System.debug('=== ALL CUSTOM TABS (' + allTabs.size() + ') ===');
for (TabDefinition td : allTabs) {
    System.debug('  ' + td.Name + ' → ' + td.Label);
}

// Also try searching by label
List<TabDefinition> homeTabs = [SELECT Name, Label, IsCustom FROM TabDefinition WHERE Label LIKE '%Home%' OR Label LIKE '%Job%' OR Label LIKE '%Tracker%'];
System.debug('=== TABS WITH HOME/JOB/TRACKER ===');
for (TabDefinition td : homeTabs) {
    System.debug('  ' + td.Name + ' → ' + td.Label + ' (custom: ' + td.IsCustom + ')');
}

// Check if user can see the app's tabs
List<UserAppInfo> appInfo = [SELECT AppDefinitionId FROM UserAppInfo WHERE UserId = :UserInfo.getUserId()];
System.debug('=== USER APP INFO ===');
System.debug('Apps: ' + appInfo.size());
for (UserAppInfo uai : appInfo) {
    System.debug('  AppDefId: ' + uai.AppDefinitionId);
}
