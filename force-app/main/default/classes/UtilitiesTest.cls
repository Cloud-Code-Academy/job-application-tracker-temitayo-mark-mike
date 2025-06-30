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



}