public inherited sharing class Utilities {
    
    public static Cache.OrgPartition orgPart = Cache.Org.getPartition('local.CCA');
    
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

    public static Boolean isHolidayOrWeekend(Date d) {
        List<Date> holidayDates = (List<Date>) orgPart.get('HolidayList');
        if(holidayDates == null) {
            List<Holiday> holidays = [SELECT Id, ActivityDate FROM Holiday];
            holidayDates  = new List<Date>();
            for(Holiday h : holidays){
                holidayDates.add(h.ActivityDate);
            }
            orgPart.put('HolidayList', holidayDates, 86400);
        }

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

    public static Date convertStringToDate (String dateString) {
        Date result = convertStringToDatetime(dateString).date();
        return result;
    }

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