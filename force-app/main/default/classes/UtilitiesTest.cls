@IsTest
private class UtilitiesTest {
   
    @IsTest
    static void testGetJobApplTasks() {
        // Test Utilities.getJobAppTasks()
        Integer numJobApplTasks = [SELECT Count() FROM Job_Application_Task__c];
        List<Job_Application_Task__c> listJobApplTasks = Utilities.getJobAppTasks();
        Integer numJobApplTasksFromCache = listJobApplTasks.size();
        System.assert(numJobApplTasks == numJobApplTasksFromCache, 'The number of records in the Job_Application_Task__c sObj should equal the number of records returned from the cache.');
    }

    @IsTest
    static void testUpdateJobApplTasks() {
        // Test Utilities.updateJobApplTasks()
        Job_Application_Task__c newJobApplTask = new Job_Application_Task__c();
        newJobApplTask.Active__c = true;
        newJobApplTask.Job_Appl_Status__c = 'Applying';
        newJobApplTask.Task_Subject__c = 'Test';
        newJobApplTask.Task_Comment__c = 'Test';
        newJobApplTask.Task_Priority__c = 'High';
        newJobApplTask.Due_Date_Adjust__c = 0;
        insert newJobApplTask;
        Integer numJobApplTasks = [SELECT Count() FROM Job_Application_Task__c];
        List<Job_Application_Task__c> listJobApplTasks = Utilities.getJobAppTasks();
        Integer numJobApplTasksFromCache = listJobApplTasks.size();
        System.assert(numJobApplTasks == numJobApplTasksFromCache, 'The number of records in the Job_Application_Task__c sObj should equal the number of records returned from the cache.');
    }
    

    @IsTest
    static void testGetDefaultPrimaryContact() {
        Contact cont = new Contact();
        cont.LastName = '<unknown_contact>';
        insert cont;
        Contact defaultPrimCont = Utilities.getDefaultPrimaryContact();
        System.assert(cont.LastName == defaultPrimCont.LastName, 'The inserted Contact should be the same as what is returned from the orgPart.');
    }

    @IsTest
    static void testUpdateDefaultPrimaryContact() {
        Contact cont = new Contact();
        cont.LastName = '<unknown_contact>';
        insert cont;
        Utilities.updateDefaultPrimaryContact();
        Contact defaultPrimCont = Utilities.getDefaultPrimaryContact();
        System.assertEquals(defaultPrimCont.LastName, Cont.LastName);
    }


    @IsTest
    static void testSendingEmail() {
        List<String> toAddresses = new List<String>();
        toAddresses.add('iowawalnut+ccatest@gmail.com');
        Utilities.sendEmail(toAddresses, null, 'TestSubject', 'TestBody');
    }

    @IsTest
    static void testSendingErrorEmail() {
        Utilities.sendErrorEmail('testErrorSubject', 'testErrorBody');
    }

    @IsTest
    static void testGetErrorEmailRecipients() {
        // Get the ProfileId for Sys Admins
        Profile testProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        // Instantiate a new User record 
        User testUser = new User(
            Username = 'testUser@ccatest.com',
            FirstName = 'testUserFirst', 
            LastName = 'testUserLast',
            Alias = 'testU',
            ProfileId= testProfile.Id,
            Email = 'testuser@ccatest.com',
            IsErrorEmailRecipient__c = true,
            TimeZoneSidKey = 'America/Chicago',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        // Insert the new User Record
        insert testUser;
        // Query the User sObj for records with IsErrorEmailRecipient__c = true
        List<String> testErrorString = Utilities.getErrorEmailRecipients();
        String s = testErrorString[0];
        System.debug(s);
        List<User> testErrorEmailAddress = [SELECT Email FROM User WHERE Username LIKE 'testUser%' AND IsErrorEmailRecipient__c = true]; 
        String errorAddress = testErrorEmailAddress[0].Email;
        System.assertEquals(testUser.Email, errorAddress);
    }

    @IsTest
    static void testAddWorkingDays() {
        Date today = Date.newInstance(2025, 7, 30);
        Date yesterday = Utilities.addWorkingDays(today, -1);
        System.assertEquals(yesterday, Date.newInstance(2025, 7, 29));
        Date tomorrow = Utilities.addWorkingDays(today, 1);
        System.assertEquals(tomorrow, Date.newInstance(2025, 7, 31));
        Date saturday = Date.newInstance(2025, 8, 2);
        System.assert(Utilities.isHolidayOrWeekend(saturday) == true);
        Date sunday = date.newInstance(2025, 8, 3);
        System.assert(Utilities.isHolidayOrWeekend(sunday) == true);
        Date fourthOfJuly = date.newInstance(2025, 7, 4);
        System.assert(Utilities.isHolidayOrWeekend(fourthOfJuly) == true);
        Date monday = Utilities.addWorkingDays(saturday, 1);
        System.assertNotEquals(Date.newInstance(2025, 8, 3), monday);
        
    }
    
    
    
    @IsTest
    static void testStringToDateTime() {
        // Test datetime
        String strTestYear = '2025';
        Datetime dtTestDateTime = Utilities.convertStringToDate(strTestYear);
        System.assert(dtTestDateTime != null);
        
        // Test date
        String strTestDate = '01/01/2025';
        dtTestDateTime = Utilities.convertStringToDatetime(strTestDate);
        System.assert(dtTestDateTime != null);
    }

    @IsTest
    static void testBatchUpsert() {
        
        List<Opportunity> opportunitiesToInsert = new List<Opportunity>();
        for (Integer i = 0; i < 100; i++) {
            Opportunity opp = new Opportunity(
                Name = 'Test Opportunity ' + i,
                CloseDate = Date.today().addDays(i),
                StageName = 'Prospecting',
                Amount = 6000 // The initial Amount is greater than 5000
            );
            opportunitiesToInsert.add(opp);
        }

        Test.startTest();
        Id BatchId = Utilities.batchUpsert(opportunitiesToInsert, 100);
        Test.stopTest();

        List<Opportunity> opps = [SELECT Id FROM Opportunity];
        System.assertEquals(100, opps.size(),'Number of inserted records/Opps is incorrect');
        
        
        
    }

}