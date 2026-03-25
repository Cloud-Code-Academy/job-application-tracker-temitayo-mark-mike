// Check the Location picklist values
Schema.DescribeFieldResult locationField = Job_Application__c.Location__c.getDescribe();
List<Schema.PicklistEntry> locationValues = locationField.getPicklistValues();
System.debug('=== LOCATION PICKLIST VALUES ===');
System.debug('Restricted: ' + locationField.isRestrictedPicklist());
for (Schema.PicklistEntry pe : locationValues) {
    System.debug('  ' + pe.getValue() + ' (active: ' + pe.isActive() + ')');
}

// Check Status picklist too
Schema.DescribeFieldResult statusField = Job_Application__c.Status__c.getDescribe();
List<Schema.PicklistEntry> statusValues = statusField.getPicklistValues();
System.debug('=== STATUS PICKLIST VALUES ===');
for (Schema.PicklistEntry pe : statusValues) {
    System.debug('  ' + pe.getValue() + ' (active: ' + pe.isActive() + ')');
}
