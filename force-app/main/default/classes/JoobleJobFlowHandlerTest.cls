@isTest
public without sharing class JoobleJobFlowHandlerTest {

    // Mock callout for Jooble that returns multiple job listings
    private class JoobleMockCallout implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);

            res.setBody('{' +
                '"totalCount": 2,' +
                '"jobs": [' +
                    '{' +
                        '"title": "Salesforce Developer",' +
                        '"location": "Austin, TX",' +
                        '"snippet": "Duration: 12 Months <br> Great opportunity with AWS and Apex.",' +
                        '"salary": "$110000",' +
                        '"link": "https://jooble.org/desc/111",' +
                        '"company": "BulkTestCo"' +
                    '},' +
                    '{' +
                        '"title": "Senior Salesforce Developer",' +
                        '"location": "Dallas, TX",' +
                        '"snippet": "Duration: 6 Months <br> Lead development efforts on SFDC projects.",' +
                        '"salary": "$130000",' +
                        '"link": "https://jooble.org/desc/222",' +
                        '"company": "BulkTestCo"' +
                    '}' +
                ']' +
            '}');
            return res;
        }
    }

    @isTest
    static void testFetchJobsFromJooble_bulkScenario() {
        // Register the mock callout
        Test.setMock(HttpCalloutMock.class, new JoobleMockCallout());

        // Invoke the flow method with dummy input
        Test.startTest();
        JoobleJobFlowHandler.fetchJobsFromJooble(new List<String>{ 'start' });
        Test.stopTest();

        // Verify multiple Job__c records
        List<Job__c> jobs = [
            SELECT Id, Name, Salary__c, Employer__c, Primary_Contact__c, Imported_from_Jooble__c
            FROM Job__c
            WHERE Imported_from_Jooble__c = true
        ];
        System.assertEquals(2, jobs.size(), 'Two Job__c records should be inserted');

        // All jobs should be related to the same employer/contact
        Set<Id> employerIds = new Set<Id>();
        Set<Id> contactIds = new Set<Id>();
        for (Job__c job : jobs) {
            System.assertNotEquals(null, job.Employer__c, 'Employer should be populated');
            System.assertNotEquals(null, job.Primary_Contact__c, 'Primary Contact should be populated');
            System.assert(job.Salary__c > 0, 'Salary should be parsed');
            employerIds.add(job.Employer__c);
            contactIds.add(job.Primary_Contact__c);
        }

        System.assertEquals(1, employerIds.size(), 'Only one Account should be created and reused');
        System.assertEquals(1, contactIds.size(), 'Only one Contact should be created and reused');

        // Validate Account + Contact creation
        List<Account> accounts = [SELECT Id FROM Account WHERE Name = 'BulkTestCo'];
        List<Contact> contacts = [SELECT Id FROM Contact WHERE LastName = 'BulkTestCo'];

        System.assertEquals(1, accounts.size(), 'One Account should exist');
        System.assertEquals(1, contacts.size(), 'One Contact should exist');
    }
}