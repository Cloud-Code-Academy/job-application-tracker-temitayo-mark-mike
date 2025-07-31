@IsTest
private class UserTriggerHandlerTest {
    
    @IsTest
    static void testUserTriggerHandler() {
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

        testUser.Email = 'testuser2@ccatest.com';
        update testUser;

    }

}