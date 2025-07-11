public inherited sharing class Utilities {
    
    // **********************************************************************************************************
    // Local declarations
    // Create instance of org cache partition.
    public static Cache.OrgPartition orgPart = Cache.Org.getPartition('local.JobApplTracker');
    
    // **********************************************************************************************************
    // Returns a List<ob_Application_Task__c> of email addresses of Sys Admins and Users with IsErrorEmailRecipient__c = true.  
    public static List<Job_Application_Task__c> getJobAppTasks() {
        // Get the Job Appl. Tasks from the Org Cache
        List<Job_Application_Task__c> listJobApplTasks = (List<Job_Application_Task__c>) orgPart.get('JobApplTasks');
        // If the Cache is null, 'refill' it
        if (listJobApplTasks == null) {
            // Initialize a List<> and execute query for refill
            updateJobApplTasks();
            List<Job_Application_Task__c> JobApplTasks = (List<Job_Application_Task__c>) orgPart.get('JobApplTasks');
            return jobApplTasks;
        } else {
            return listJobApplTasks;
        }
    }

    // **********************************************************************************************************
    // Refreshes the Job_Application_Task__c in Cache.org()
    public static void updateJobApplTasks() {
        List<Job_Application_Task__c> jobApplTasks = [SELECT Id, Active, Job_Appl_Status__c, Task_Comment__c, Task_Priority__c, Task_Subject__c, Due_Date_Adjust__c FROM Job_Application_Task__c ];
        orgPart.put('JobApplTasks', jobApplTasks, 86400);
    }
    
    
    // **********************************************************************************************************
    // Returns a List<String> of email addresses of Sys Admins and Users with IsErrorEmailRecipient__c = true.  
    public static List<String> getErrorEmailRecipients() {
        // Get the List<String> of email addresses from the Org Cache
        List<String> listEmailString = (List<String>) orgPart.get('ErrorEmailAddressString');
        // If the Cache is null, 'refill' it
        if (listEmailString == null) {
            // TO DO - combine lines 17(18?) -> 25 into new method, can be used elsewhere
            // List<User> listErrorUsers = updateErrorEmailInOrgPart()
            List<String> listRefreshEmailString = new List<String>(); 
            List<User> listErrorUsers = [SELECT Email FROM User WHERE Profile.Name = 'System Administrator' OR IsErrorEmailRecipient__c = true LIMIT 150]; 
            for (User usr : listErrorUsers) {
                if (usr.Email != null) { 
                    listRefreshEmailString.add(usr.Email);
                }
            }
            // Refresh the Org Cache 
            orgPart.put('ErrorEmailAddressString', listRefreshEmailString, 86400);
            return listRefreshEmailString;
        } else {
            return listEmailString;
        }
    }

    // **********************************************************************************************************
    public static List<String> updateErrorEmailInOrgPart(List<User> listEmailErrorUsers) {
        // Parse the List<User> and populate a List<String> of email addresses, then update the OrgPart
        List<String> tempStringList = new List<String>();
        return tempStringList;
    }

    // **********************************************************************************************************
    // Sends 'Error' email to Sys Admins and Users with IsErrorEmailRecipient__c = true.
    public static void sendErrorEmail(String errorSubject, String errorBody) {
        List<Messaging.SendEmailResult> listErrorEmailResult = sendEmail(getErrorEmailRecipients(), null, errorSubject, errorBody);
    }

    // **********************************************************************************************************
    // Returns a List<> of SendEmailResults from sending single email.    
    public static List<Messaging.SendEmailResult> sendEmail(List<String> toAddresses, String fromAddress, String subject, String body) {
    
        // Create instance of Single Email message
        Messaging.SingleEmailMessage emailMessage = new Messaging.SingleEmailMessage();

        // If the fromAddress is not provided (=null), then use the Org Wide Email Address (assumes only one (1)).
        if(fromAddress == null) {
            List<OrgWideEmailAddress> listAddr = [SELECT Id FROM OrgWideEmailAddress LIMIT 1];
            if (listAddr.size() > 0) {
                emailMessage.setOrgWideEmailAddressId(listAddr[0].Id);
            } else {
                throw new IllegalArgumentException('Failed to find OrgWideEmailAddress: ' + JSON.serializePretty(listAddr));
            }
        }

        // Set parts of email message
        emailMessage.setSubject(subject);
        emailMessage.setPlainTextBody(body);
        emailMessage.setToAddresses(toAddresses);

        // Intantiate a List<> to hold the results of the email sent (one result per recipient)
        List<Messaging.SendEmailResult> listEmailResult = new List<Messaging.SendEmailResult>();
    
        if(toAddresses.size() > 0){
            listEmailResult = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {emailMessage});
        } else {
            System.debug('Warning: No email recipients were provided. No email was sent');
        }
        return listEmailResult;
    }

    
    // **********************************************************************************************************
    // Adds working/business days to a date and returns the later (daysToAdd > 0) or earlier (daysToAdd < 0) date.
    public static Date addWorkingDays (Date startingDate, Integer daysToAdd) {
        Integer count = 0;
        if(daysToAdd > 0) {
            while (count < daysToAdd) {
                startingDate = startingDate.addDays(1);
                if(!isHolidayOrWeekend(startingDate)) {
                    count++;
                }
            }
        } else {
            while (count > daysToAdd) {
                startingDate = startingDate.addDays(-1);
                if(!isHolidayOrWeekend(startingDate)) {
                    count--;
                }
            }
        }
        return startingDate;
    }

    // **********************************************************************************************************
    // Accesses the Holiday sObj data for the org, used in addworkingdays().
    public static Boolean isHolidayOrWeekend(Date d) {
        List<Date> holidayDates = (List<Date>) orgPart.get('HolidayList');
        if(holidayDates == null) {
            List<Holiday> holidays = [SELECT Id, Name, ActivityDate FROM Holiday];
            holidayDates  = new List<Date>();
            for(Holiday h : holidays){
                holidayDates.add(h.ActivityDate);
            }
            orgPart.put('HolidayList', holidayDates, 86400);
        }

        System.debug('Holidays List: ' + JSON.serializePretty(holidayDates));

        if (d.toStartOfWeek() == d) { // Sunday
            return true;
        }
        else if (d.toStartOfWeek().addDays(6) == d) { // Saturday
            return true;
        }
        else if(holidayDates.contains(d)) {
            return true;
        } else {
            return false;
        }
    }

    // **********************************************************************************************************
    // Returns a Salesforce date based on various string formats.
    public static Date convertStringToDate (String dateString) {
        Date result = convertStringToDatetime(dateString).date();
        return result;
    }

    // **********************************************************************************************************
    // Returns a Salesforce datetime based on various string formats. 
    public static Datetime convertStringToDatetime (String datetimeString) {
        String originalValue = datetimeString;
        Datetime result;
        /*
        Valid Date Formats:
        YYYY
        MM/YYYY
        MM/DD/YYYY
        YYYY-MM-DD
        YYYY-MM-DD HH:MM:SS
        NOTE: Year can be two or four digits. The month and day can be tripped of leading zeros.
         */
        List<String> validRegexOptions = new List<String>{
                '([0-9]{0,4})', // YYYY
                '(0?[1-9]|1[0-2])/([0-9]{0,4})', // MM/YYYY
                '(0?[1-9]|1[0-2])/(0?[1-9]|[12][0-9]|3[01])/([0-9]{0,4})', // MM/DD/YYYY
                '(0*[1-9][0-9]{0,3}|[1-9][0-9]{0,3}|9999)-(0?[1-9]|1[0-2])-(0?[1-9]|[12][0-9]|3[01])', // YYYY-MM-DD
                '(0*[1-9][0-9]{0,3}|[1-9][0-9]{0,3}|9999)-(0?[1-9]|1[0-2])-(0?[1-9]|[12][0-9]|3[01]) [0-9]{2}:[0-9]{2}:[0-9]{2}' // YYYY-MM-DD HH:MM:SS
        };
        String regexPattern = '^(?:' + String.join(validRegexOptions, '|') + '?)$';
        try{
            if(datetimeString != null && datetimeString != '') {
                datetimeString = datetimeString.trim();
                Boolean validFormat = Pattern.matches(regexPattern,datetimeString);
                if(validFormat) {
                    if(datetimeString.length() <= 4 && datetimeString.isNumeric()) {
                        if(datetimeString.length() == 2) {
                            datetimeString = Integer.valueOf(datetimeString) > 50 ? '19' + datetimeString : '20' + datetimeString;
                        }
                        if(datetimeString.length() == 4) {
                            datetimeString = datetimeString + '-01-01';
                        }
                    }
                    if(datetimeString.contains('/')) {
                        List<String> tmpList = datetimeString.split('/');
                        if(datetimeString.countMatches('/') == 1) {
                            String month = tmpList[0];
                            String year = tmpList[1].length() == 2 ? Integer.valueOf(tmpList[1]) > 50 ? '19' + tmpList[1] : '20' + tmpList[1] : tmpList[1];
                            datetimeString = year + '-' + month + '-01';
                        } else if(datetimeString.countMatches('/') == 2) {
                            String month = tmpList[0];
                            String day = tmpList[1];
                            String year = tmpList[2].length() == 2 ? Integer.valueOf(tmpList[2]) > 50 ? '19' + tmpList[2] : '20' + tmpList[2] : tmpList[2];
                            datetimeString = year + '-' + month + '-' + day;
                        }
                    }
                    if(datetimeString.contains('-')) {
                        if(!datetimeString.contains(':')) {
                            datetimeString = datetimeString + ' 00:00:00';
                        }
                        result = Datetime.valueOf(datetimeString);
                    }
                } else {
                    throw new IllegalArgumentException('Invalid Format. Did not match Regex pattern.');
                }
                if(result == null) {
                    throw new IllegalArgumentException('Invalid Format');
                }
            }
        } catch (Exception e) {
            throw new IllegalArgumentException('Failed to convert string to datetime: ' + e + '\nPassed Value: ' + originalValue + '\nValid Formats: \nYYYY\n' + 'MM/YYYY\n' + 'MM/DD/YYYY\n' + 'YYYY-MM-DD\n' + 'YYYY-MM-DD HH:MM:SS');
        }
        return result;
    }

}