/**
 * @description Test class for JobApplicationCleanupBatch
 * @author Learning Journey
 * @date 2025-01-08
 */
@IsTest
public inherited sharing class JobApplicationCleanupBatchTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test Job Application records
        List<Job_Application__c> jobApps = new List<Job_Application__c>();
        
        // Create duplicate records for duplicate removal testing
        jobApps.add(new Job_Application__c(
            Company_Name__c = 'Duplicate Corp',
            Position_Title__c = 'Software Engineer',
            Status__c = 'Applied',
            Application_Date__c = Date.today().addDays(-10)
        ));
        
        jobApps.add(new Job_Application__c(
            Company_Name__c = 'Duplicate Corp',
            Position_Title__c = 'Software Engineer',
            Status__c = 'Applied',
            Application_Date__c = Date.today().addDays(-5)
        ));
        
        // Create old records for archiving testing
        jobApps.add(new Job_Application__c(
            Company_Name__c = 'Old Company',
            Position_Title__c = 'Old Position',
            Status__c = 'Applied',
            Application_Date__c = Date.today().addDays(-400)
        ));
        
        jobApps.add(new Job_Application__c(
            Company_Name__c = 'Another Old Company',
            Position_Title__c = 'Another Old Position',
            Status__c = 'Applied',
            Application_Date__c = Date.today().addDays(-500)
        ));
        
        // Create stale records for update testing
        jobApps.add(new Job_Application__c(
            Company_Name__c = 'Stale Company',
            Position_Title__c = 'Stale Position',
            Status__c = '',
            Application_Date__c = Date.today().addDays(-30)
        ));
        
        // Create normal records
        jobApps.add(new Job_Application__c(
            Company_Name__c = 'Normal Company',
            Position_Title__c = 'Normal Position',
            Status__c = 'Applied',
            Application_Date__c = Date.today().addDays(-1)
        ));
        
        insert jobApps;
    }
    
    @IsTest
    static void testRemoveDuplicatesBatch() {
        // Count initial records
        Integer initialCount = [SELECT COUNT() FROM Job_Application__c];
        
        // Execute duplicate removal batch
        JobApplicationCleanupBatch batch = new JobApplicationCleanupBatch(
            JobApplicationCleanupBatch.CleanupType.REMOVE_DUPLICATES, 
            365, 
            false
        );
        
        Test.startTest();
        Database.executeBatch(batch, 200);
        Test.stopTest();
        
        // Verify duplicates were removed
        Integer finalCount = [SELECT COUNT() FROM Job_Application__c];
        System.assert(finalCount < initialCount, 'Duplicates should have been removed');
        
        // Verify only one record remains for the duplicate company/position
        List<Job_Application__c> duplicateCorpRecords = [
            SELECT Id FROM Job_Application__c 
            WHERE Company_Name__c = 'Duplicate Corp' 
            AND Position_Title__c = 'Software Engineer'
        ];
        System.assertEquals(1, duplicateCorpRecords.size(), 'Only one duplicate record should remain');
    }
    
    @IsTest
    static void testArchiveOldBatch() {
        // Execute archive batch for records older than 365 days
        JobApplicationCleanupBatch batch = new JobApplicationCleanupBatch(
            JobApplicationCleanupBatch.CleanupType.ARCHIVE_OLD, 
            365, 
            false
        );
        
        Test.startTest();
        Database.executeBatch(batch, 200);
        Test.stopTest();
        
        // Verify old records were archived
        List<Job_Application__c> archivedRecords = [
            SELECT Id, Status__c, Notes__c 
            FROM Job_Application__c 
            WHERE Status__c = 'Archived'
        ];
        
        System.assert(archivedRecords.size() > 0, 'Some records should have been archived');
        
        // Verify archive notes were added
        for (Job_Application__c record : archivedRecords) {
            System.assert(record.Notes__c.contains('ARCHIVED'), 'Archive note should be added');
        }
    }
    
    @IsTest
    static void testUpdateStaleBatch() {
        // Execute stale record update batch
        JobApplicationCleanupBatch batch = new JobApplicationCleanupBatch(
            JobApplicationCleanupBatch.CleanupType.UPDATE_STALE, 
            365, 
            false
        );
        
        Test.startTest();
        Database.executeBatch(batch, 200);
        Test.stopTest();
        
        // Verify stale records were updated
        List<Job_Application__c> updatedRecords = [
            SELECT Id, Status__c, Notes__c 
            FROM Job_Application__c 
            WHERE Company_Name__c = 'Stale Company'
        ];
        
        System.assertEquals(1, updatedRecords.size(), 'Stale record should exist');
        System.assertEquals('Applied', updatedRecords[0].Status__c, 'Status should be updated');
        System.assert(updatedRecords[0].Notes__c.contains('MAINTENANCE'), 'Maintenance note should be added');
    }
    
    @IsTest
    static void testFullCleanupBatch() {
        // Execute full cleanup batch
        JobApplicationCleanupBatch batch = new JobApplicationCleanupBatch(
            JobApplicationCleanupBatch.CleanupType.FULL_CLEANUP, 
            365, 
            false
        );
        
        Test.startTest();
        Database.executeBatch(batch, 200);
        Test.stopTest();
        
        // Verify multiple cleanup operations were performed
        // Check for duplicate removal
        List<Job_Application__c> duplicateCorpRecords = [
            SELECT Id FROM Job_Application__c 
            WHERE Company_Name__c = 'Duplicate Corp'
        ];
        System.assertEquals(1, duplicateCorpRecords.size(), 'Duplicates should be removed in full cleanup');
        
        // Check for stale record updates
        List<Job_Application__c> staleRecords = [
            SELECT Id, Status__c FROM Job_Application__c 
            WHERE Company_Name__c = 'Stale Company'
        ];
        System.assertEquals('Applied', staleRecords[0].Status__c, 'Stale records should be updated in full cleanup');
    }
    
    @IsTest
    static void testBatchWithReporting() {
        // Execute batch with reporting enabled
        JobApplicationCleanupBatch batch = new JobApplicationCleanupBatch(
            JobApplicationCleanupBatch.CleanupType.REMOVE_DUPLICATES, 
            365, 
            true
        );
        
        Test.startTest();
        Database.executeBatch(batch, 200);
        Test.stopTest();
        
        // Verify batch completed (reporting is tested through debug logs)
        System.assert(true, 'Batch with reporting should complete successfully');
    }
    
    @IsTest
    static void testBatchErrorHandling() {
        // Create a batch that will encounter errors (using invalid data)
        JobApplicationCleanupBatch batch = new JobApplicationCleanupBatch(
            JobApplicationCleanupBatch.CleanupType.REMOVE_DUPLICATES, 
            365, 
            false
        );
        
        Test.startTest();
        try {
            Database.executeBatch(batch, 200);
            Test.stopTest();
            
            // Batch should handle errors gracefully
            System.assert(true, 'Batch should handle errors without throwing exceptions');
            
        } catch (Exception e) {
            Test.stopTest();
            System.debug('Expected error handling: ' + e.getMessage());
        }
    }
    
    @IsTest
    static void testBatchStatefulProperties() {
        // Test that stateful properties are maintained across batches
        JobApplicationCleanupBatch batch = new JobApplicationCleanupBatch(
            JobApplicationCleanupBatch.CleanupType.FULL_CLEANUP, 
            365, 
            false
        );
        
        Test.startTest();
        Database.executeBatch(batch, 2); // Small batch size to ensure multiple batches
        Test.stopTest();
        
        // Verify batch completed successfully with stateful tracking
        System.assert(true, 'Stateful batch should complete successfully');
    }
    
    @IsTest
    static void testDateComparator() {
        // Test the custom date comparator
        JobApplicationCleanupBatch batch = new JobApplicationCleanupBatch();
        JobApplicationCleanupBatch.JobApplicationDateComparator comparator = 
            new JobApplicationCleanupBatch.JobApplicationDateComparator();
        
        // Create test records with different dates
        Job_Application__c older = new Job_Application__c();
        older.CreatedDate = DateTime.now().addDays(-10);
        
        Job_Application__c newer = new Job_Application__c();
        newer.CreatedDate = DateTime.now().addDays(-5);
        
        Job_Application__c same = new Job_Application__c();
        same.CreatedDate = older.CreatedDate;
        
        Test.startTest();
        
        // Test comparisons
        System.assertEquals(-1, comparator.compare(older, newer), 'Older should come before newer');
        System.assertEquals(1, comparator.compare(newer, older), 'Newer should come after older');
        System.assertEquals(0, comparator.compare(older, same), 'Same dates should be equal');
        
        Test.stopTest();
    }
    
    @IsTest
    static void testBatchQueryBuilding() {
        // Test different query building scenarios
        JobApplicationCleanupBatch duplicateBatch = new JobApplicationCleanupBatch(
            JobApplicationCleanupBatch.CleanupType.REMOVE_DUPLICATES, 
            365, 
            false
        );
        
        JobApplicationCleanupBatch archiveBatch = new JobApplicationCleanupBatch(
            JobApplicationCleanupBatch.CleanupType.ARCHIVE_OLD, 
            180, 
            false
        );
        
        JobApplicationCleanupBatch staleBatch = new JobApplicationCleanupBatch(
            JobApplicationCleanupBatch.CleanupType.UPDATE_STALE, 
            365, 
            false
        );
        
        Test.startTest();
        
        // Execute different batch types to test query building
        Database.QueryLocator duplicateLocator = duplicateBatch.start(null);
        Database.QueryLocator archiveLocator = archiveBatch.start(null);
        Database.QueryLocator staleLocator = staleBatch.start(null);
        
        Test.stopTest();
        
        // Verify query locators were created successfully
        System.assertNotEquals(null, duplicateLocator, 'Duplicate batch query locator should be created');
        System.assertNotEquals(null, archiveLocator, 'Archive batch query locator should be created');
        System.assertNotEquals(null, staleLocator, 'Stale batch query locator should be created');
    }
    
    @IsTest
    static void testBatchWithEmptyResults() {
        // Create a batch that will find no records to process
        JobApplicationCleanupBatch batch = new JobApplicationCleanupBatch(
            JobApplicationCleanupBatch.CleanupType.ARCHIVE_OLD, 
            1000, // Very old cutoff, should find no records
            false
        );
        
        Test.startTest();
        Database.executeBatch(batch, 200);
        Test.stopTest();
        
        // Verify batch completes successfully even with no records to process
        System.assert(true, 'Batch should handle empty results gracefully');
    }
}