public without sharing class JoobleJobFlowHandler { 
    public class Job {
        public String title;
        public String location;
        public String snippet;
        public String salary;
        public String link;
        public String company;
    }

    public class JoobleResponse {
        public Integer totalCount;
        public List<Job> jobs;
    }

    @InvocableMethod(label='Fetch Jobs from Jooble' description='Fetches jobs using Jooble API and creates Job__c records.')
    public static void fetchJobsFromJooble(List<String> dummyInput) {
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://jooble.org/api/f1e40af3-7595-4d4b-ad7e-0119f303a2ef'); 
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody('{"keywords":"Salesforce Developer", "location":"Texas", "page":"1"}');

        HttpResponse res = http.send(req);
        if (res.getStatusCode() != 200) {
            System.debug('Error response: ' + res.getBody());
            return;
        }

        JoobleResponse parsed = (JoobleResponse) JSON.deserialize(res.getBody(), JoobleResponse.class);
        List<Job__c> jobList = new List<Job__c>();

        // Caches to avoid duplicate inserts
        Map<String, Id> companyNameToAccountId = new Map<String, Id>();
        Map<String, Id> companyNameToContactId = new Map<String, Id>();

        for (Job job : parsed.jobs) {
            Decimal parsedSalary = tryParseDecimal(job.salary);
            Id employerId = getOrCreateEmployer(job.company, companyNameToAccountId);
            Id contactId = getOrCreatePrimaryContact(job.company, employerId, companyNameToContactId);

            jobList.add(new Job__c(
                Name = job.title,
                Salary__c = parsedSalary,
                Employer__c = employerId,
                Primary_Contact__c = contactId,
                Imported_from_Jooble__c = true
            ));
        }

        if (!jobList.isEmpty()) {
            insert jobList;
        }
    }

    public static String stripHtml(String input) {
        if (String.isBlank(input)) return '';
        String noHtml = input.replaceAll('<[^>]+>', '');
        noHtml = noHtml.replaceAll('&nbsp;', ' ').replaceAll('&amp;', '&');
        return noHtml.trim();
    }

    public static Decimal tryParseDecimal(String salary) {
        if (String.isBlank(salary)) return null;
        String numeric = salary.replaceAll('[^0-9.]', '');
        try {
            return Decimal.valueOf(numeric);
        } catch (Exception e) {
            return null;
        }
    }

    public static Id getOrCreateEmployer(String companyName, Map<String, Id> cache) {
        if (String.isBlank(companyName)) return null;

        companyName = companyName.trim();
        if (cache.containsKey(companyName)) {
            return cache.get(companyName);
        }

        Account existing = null;
        try {
            existing = [SELECT Id FROM Account WHERE Name = :companyName LIMIT 1];
        } catch (Exception e) {
            existing = null;
        }

        if (existing != null) {
            cache.put(companyName, existing.Id);
            return existing.Id;
        } else {
            Account newAcct = new Account(Name = companyName);
            insert newAcct;
            cache.put(companyName, newAcct.Id);
            return newAcct.Id;
        }
    }

    public static Id getOrCreatePrimaryContact(String companyName, Id employerId, Map<String, Id> cache) {
        if (String.isBlank(companyName)) return null;

        companyName = companyName.trim();
        if (cache.containsKey(companyName)) {
            return cache.get(companyName);
        }

        Contact existing = null;
        try {
            existing = [SELECT Id FROM Contact WHERE LastName = :companyName AND AccountId = :employerId LIMIT 1];
        } catch (Exception e) {
            existing = null;
        }

        if (existing != null) {
            cache.put(companyName, existing.Id);
            return existing.Id;
        } else {
            Contact newContact = new Contact(
                LastName = companyName,
                AccountId = employerId
            );
            insert newContact;
            cache.put(companyName, newContact.Id);
            return newContact.Id;
        }
    }
}