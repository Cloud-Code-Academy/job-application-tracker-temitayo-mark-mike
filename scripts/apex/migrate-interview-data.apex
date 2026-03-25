// Interview Data Migration Script
// Run this script to migrate existing interview data to the new Interview Feedback Tracker structure

System.debug('Starting Interview Data Migration...');

// Option 1: Migrate specific Job Applications
List<Id> specificJobAppIds = new List<Id>{
    // Add specific Job Application IDs here if needed
    // '003XXXXXXXXXXXXXXX'
};

if (!specificJobAppIds.isEmpty()) {
    System.debug('Migrating specific Job Applications: ' + specificJobAppIds.size());
    InterviewFeedbackDataMigration.MigrationResult result = 
        InterviewFeedbackDataMigration.migrateInterviewData(specificJobAppIds);
    System.debug('Migration Result: ' + result.getSummary());
    
    if (!result.errors.isEmpty()) {
        System.debug('Errors encountered:');
        for (String error : result.errors) {
            System.debug('- ' + error);
        }
    }
} else {
    // Option 2: Start batch migration for all eligible records
    System.debug('Starting batch migration for all eligible records...');
    
    // Check how many records will be migrated
    Integer recordCount = [
        SELECT COUNT() 
        FROM Job_Application__c 
        WHERE Interview_Notes__c != null
        AND Id NOT IN (
            SELECT Job_Application__c 
            FROM Interview_Feedback__c 
            WHERE Job_Application__c != null
        )
    ];
    
    System.debug('Found ' + recordCount + ' Job Applications to migrate');
    
    if (recordCount > 0) {
        InterviewFeedbackDataMigration.startBatchMigration();
        System.debug('Batch migration started. Check batch job status in Setup > Apex Jobs');
    } else {
        System.debug('No records found for migration');
    }
}

// Verify migration results
System.debug('Checking migration results...');
Integer migratedCount = [SELECT COUNT() FROM Interview_Feedback__c WHERE Feedback_Source__c = 'Self'];
System.debug('Total Interview Feedback records created: ' + migratedCount);

System.debug('Migration script completed');

/*
Post-Migration Steps:
1. Review migrated data for accuracy
2. Update any incorrect ratings or categorizations
3. Train users on the new Interview Feedback Tracker features
4. Consider archiving old interview notes fields after validation
*/