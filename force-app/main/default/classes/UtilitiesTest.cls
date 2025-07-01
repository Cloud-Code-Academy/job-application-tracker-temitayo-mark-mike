@IsTest
private class UtilitiesTest {
   
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
    static void testSendingEmail() {
        List<String> toAddresses = new List<String>();
        toAddresses.add('iowawalnut+ccatest@gmail.com');
        Utilities.sendEmail(toAddresses, null, 'TestSubject', 'TestBody');
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
            Email = 'testUser@ccatest.com',
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

}