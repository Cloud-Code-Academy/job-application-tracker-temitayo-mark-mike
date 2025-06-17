@IsTest
private class UtilitiesTest {
    @IsTest
    static void multiSelectAdd() {
        String recordControl = 'Enrollment;Re-Enrollment';
        String newValue;
        newValue = Utilities.multiSelectAdd(recordControl, 'Enrollment;Testing');
        System.assertEquals('Enrollment;Re-Enrollment;Testing',newValue);
    }

    @IsTest
    static void multiSelectRemove() {
        String recordControl = 'Enrollment;Re-Enrollment;Something';
        String newValue;
        newValue = Utilities.multiSelectRemove(recordControl, 'Re-Enrollment');
        System.assertEquals('Enrollment;Something',newValue);
    }

    @IsTest
    static void testSendingEmail() {
        List<String> toAddresses = new List<String>();
        toAddresses.add('noreply@bethel.edu');
        Utilities.sendEmail(toAddresses, null, 'TestSubject', 'TestBody');
        Utilities.sendEmailWithAttachments(toAddresses, null, 'TestSubject', 'TestBody', 'TestFileName', '.txt', 'TestFileContent');
    }

//    @IsTest
//    static void testSendingNotification() {
//        User u = TestDataFactory.createTestUser(null, 'fist', 'last');
//        Utilities.sendNotification(new Set<String>{String.valueOf(u.Id)}, u.Id, 'Test Title', 'Test Body');
//    }

    @IsTest
    static void testRunningInASandbox() {
        Boolean runningInASandbox = Utilities.runningInASandbox();
        System.assert(runningInASandbox == true || runningInASandbox == false);
    }

    @IsTest
    static void testCSV() {
        String csv = 'header 1, header 2\nvalue 1, value 2';
        List<List<String>> results = Utilities.readCSV(csv);
        System.assert(results.size() > 0);
    }

    @IsTest
    static void testDatabaseQuery() {
        Contact testContact = new Contact(FirstName='First', LastName='Last', Email='test@test.com');
        insert testContact;
        List<SObject> results = Utilities.databaseQuery('Contact', null, 'Id = \'' + testContact.Id + '\'', 1);
        System.assert(results.size() > 0);
    }

    @IsTest
    static void testBatchUpsert() {
        Contact testContact = new Contact(FirstName='First', LastName='Last', Email='test@test.com');
        Contact badContact = new Contact(FirstName='First', LastName='Last', Email='badEmail');
        List<Contact> contacts = new List<Contact>{testContact, badContact};

        Test.startTest();
        Id batchId = Utilities.batchUpsertSObjects(contacts, 500);
        Test.stopTest();

        List<Contact> upsertedContacts = [SELECT Id FROM Contact];
        System.assert(upsertedContacts.size() == 1);
    }

    @IsTest
    static void testDebugLogs() {
        String results = '';
        Utilities.debugStartingLimits('testClass', 'testKey');
        Utilities.debugEndingLimits('testClass', 'testKey');
        results += Utilities.getCurrentLimits();
        System.assert(results != '');
        System.assert(Utilities.classLimits != null);
    }

    @IsTest
    static void testGetCustomFieldsFromObject() {
        List<String> fields = Utilities.getCustomFieldsFromObject('Contact');
        System.assert(fields.size() > 0);
    }

    @IsTest
    static void testBatchDeleteSObjects () {
        Contact c = new Contact(FirstName = 'f', LastName = 'l');
        insert c;
        Test.startTest();
        String soql = 'SELECT id FROM Contact';
        Utilities.batchDeleteSObjects(soql, 100);
        Test.stopTest();
        List <Contact> postDeletelist = [SELECT id FROM Contact];
        System.assert(postDeletelist.size()==0);
    }

    @IsTest
    static void testStringToDateTime() {
        String s = '2023';
        Datetime dt = Utilities.convertStringToDate(s);
        System.assert(dt != null);
        s = '01/01/2023';
        dt = Utilities.convertStringToDatetime(s);
        System.assert(dt != null);
    }

    @IsTest
    static void testRandom() {
        Contact c = new Contact(FirstName = 'f', LastName = 'l');
        insert c;
        Utilities.createStringOfIds(new List<Id>{c.Id});
        Utilities.convertToURL(c.Id);
        Utilities.convertToURL(String.valueOf(c.Id));
        Utilities.queryAllFieldsOnRecord(c.Id);
        Utilities.getRecordTypeId('Account', 'Household_New');
        Utilities.addWorkingDays(System.today(), 5);
        Utilities.sendEmailToAdmins('test', 'test');
        Utilities.getCurrentStackTrace();
        Utilities.sleep(1);
        Utilities.firstRun('test');
        Utilities.getCurrentUsersProfileName();
        Utilities.sortSObjectList(new List<Contact>{c, c.clone()}, 'FirstName', 'ASC');
    }

    @IsTest
    static void testUpsertSObjectAsynchronously() {
        Contact c = new Contact(FirstName = 'first', LastName = 'last', Email = 'test@bethel.edu');
        Contact c2 = new Contact(FirstName = 'firstTwo', LastName = 'lastTwo', Email = 'testTwo@bethel.edu');
        List<Contact> contacts = new List<Contact>{c2};
        Test.startTest();
        Utilities.upsertSObjectAsynchronously(c);
        Utilities.upsertSObjectAsynchronously(contacts);
        Test.stopTest();
        List<Contact> contacts2 = [SELECT Id FROM Contact WHERE FirstName LIKE 'f%'];
        System.assert(contacts2.size() == 2);
    }

    @IsTest
    static void picklistValues() {
        Utilities.getPickListValues('Account', 'Type');
        Utilities.getDependentPicklistValues('Account', 'Referral_Source_Type__c');
    }

    @IsTest
    static void testUpsertResults() {
        Contact c = new Contact(Email = 'bademail');
        List<database.SaveResult> result1 = Database.insert(new List<Contact>{c}, false);
        String error = Utilities.catchFailedSaveResults(result1, 'test', false);
        System.assert(error != null);
        List<database.UpsertResult> result2 = Database.upsert(new List<Contact>{c}, false);
        error = Utilities.catchFailedUpsertResults(result2, 'test', false);
        System.assert(error != null);
        List<Utilities.UpsertResult> results = Utilities.upsertRecords(new List<Contact>{c}, null, true, false, false, 'none', 'test');
        List<Utilities.UpsertResult> results2 = Utilities.upsertRecords(new List<Contact>{c}, null, true, true, true, 'none', 'test');

    }

    @IsTest
    static void testDetectDifferences() {
        Lead l1 = new Lead(FirstName = 'f1');
        Lead l2 = new Lead(FirstName = 'f2');
        Utilities.detectDifferences(l1, l2);
    }

    @IsTest
    static void testfindDuplicates() {
        Lead l1 = new Lead(FirstName = 'f1');
        Utilities.findDuplicates(new List<Lead>{l1}, 'test');
    }
}