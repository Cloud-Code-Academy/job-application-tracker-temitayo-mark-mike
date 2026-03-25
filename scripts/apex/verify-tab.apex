// Verify tab now exists
List<TabDefinition> tabs = [SELECT Name, Label, IsCustom FROM TabDefinition WHERE Name = 'Job_Tracker_Home'];
System.debug('Tab found: ' + tabs.size());
for (TabDefinition td : tabs) {
    System.debug('  Name: ' + td.Name + ' | Label: ' + td.Label);
}

// Check tab visibility for System Administrator profile
List<PermissionSetTabSetting> tabSettings = [
    SELECT Name, Visibility, Parent.Profile.Name 
    FROM PermissionSetTabSetting 
    WHERE Name = 'Job_Tracker_Home'
];
System.debug('=== TAB VISIBILITY SETTINGS ===');
System.debug('Settings found: ' + tabSettings.size());
for (PermissionSetTabSetting pts : tabSettings) {
    System.debug('  Tab: ' + pts.Name + ' | Visibility: ' + pts.Visibility + ' | Profile: ' + pts.Parent.Profile.Name);
}
