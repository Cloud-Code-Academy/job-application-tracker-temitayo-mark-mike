// Check all existing tabs in the app
List<TabDefinition> allCustomTabs = [SELECT Name, Label, IsCustom FROM TabDefinition WHERE IsCustom = true];
System.debug('=== ALL CUSTOM TABS ===');
for (TabDefinition td : allCustomTabs) {
    System.debug('  ' + td.Name + ' → ' + td.Label);
}

// Check for tabs matching our navigation targets
String[] targetTabs = new String[]{'Job_Application_Analytics', 'Salary_Calculator', 'Calendar'};
List<TabDefinition> matchedTabs = [SELECT Name, Label, IsCustom FROM TabDefinition WHERE Name IN :targetTabs];
System.debug('=== TARGET TABS FOUND ===');
System.debug('Found: ' + matchedTabs.size() + ' of 3 expected');
for (TabDefinition td : matchedTabs) {
    System.debug('  FOUND: ' + td.Name + ' → ' + td.Label);
}

// Check which LWC-backed FlexiPages exist
// We can't query FlexiPage directly, but let's check for navable items
List<AppMenuItem> menuItems = [SELECT Name, Label, Type, ApplicationId FROM AppMenuItem WHERE Type = 'TabSet' OR Type = 'Tab' ORDER BY Label];
System.debug('=== APP MENU ITEMS ===');
for (AppMenuItem ami : menuItems) {
    System.debug('  ' + ami.Name + ' → ' + ami.Label + ' (' + ami.Type + ')');
}
