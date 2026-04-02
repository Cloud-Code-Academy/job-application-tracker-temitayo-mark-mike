/**
 * @description Test class for SalaryCalculationService
 * Tests tax bracket calculations, Social Security, Medicare, and take-home pay
 * @author Test Suite
 * @date 2025
 */
@IsTest
private class SalaryCalculationServiceTest {

    @TestSetup
    static void setupTestData() {
        List<Job_Application__c> apps = new List<Job_Application__c>();
        apps.add(TestDataFactory.createJobApplication('Zero Salary Co', 'Analyst', 'Applied', 0, false));
        apps.add(TestDataFactory.createJobApplication('Low Salary Co', 'Junior Dev', 'Applied', 11000, false));
        apps.add(TestDataFactory.createJobApplication('Mid-Low Co', 'Developer', 'Applied', 44725, false));
        apps.add(TestDataFactory.createJobApplication('Mid Salary Co', 'Sr Developer', 'Applied', 75000, false));
        apps.add(TestDataFactory.createJobApplication('Mid-High Co', 'Lead Dev', 'Applied', 95375, false));
        apps.add(TestDataFactory.createJobApplication('SS Cap Co', 'Manager', 'Applied', 160200, false));
        apps.add(TestDataFactory.createJobApplication('High Salary Co', 'Director', 'Applied', 578125, false));
        apps.add(TestDataFactory.createJobApplication('Very High Co', 'VP', 'Applied', 700000, false));
        insert apps;
    }

    @IsTest
    static void testFederalTaxZeroSalary() {
        Decimal result = SalaryCalculationService.calculateFederalIncomeTax(0);
        System.assertEquals(0, result, 'Zero salary should produce zero federal tax');
    }

    @IsTest
    static void testFederalTaxNullSalary() {
        Decimal result = SalaryCalculationService.calculateFederalIncomeTax(null);
        System.assertEquals(0, result, 'Null salary should produce zero federal tax');
    }

    @IsTest
    static void testFederalTaxNegativeSalary() {
        Decimal result = SalaryCalculationService.calculateFederalIncomeTax(-50000);
        System.assertEquals(0, result, 'Negative salary should produce zero federal tax');
    }

    @IsTest
    static void testFederalTaxBelowStandardDeduction() {
        // $11,000 - taxableIncome = 11000 - 13850 = 0 (capped at 0)
        Decimal result = SalaryCalculationService.calculateFederalIncomeTax(11000);
        System.assertEquals(0, result, 'Salary below standard deduction should produce zero federal tax');
    }

    @IsTest
    static void testFederalTaxFirstBracket() {
        // $24,850 = 13850 deduction + 11000 taxable -> 11000 * 0.10 = 1100.00
        Decimal result = SalaryCalculationService.calculateFederalIncomeTax(24850);
        System.assertEquals(1100.00, result, 'Should tax at 10% for income in first bracket');
    }

    @IsTest
    static void testFederalTaxSecondBracket() {
        // $44,725: taxable = 44725 - 13850 = 30875
        // 10% on 11000 = 1100, 12% on (30875-11000=19875) = 2385
        // Total = 3485.00
        Decimal result = SalaryCalculationService.calculateFederalIncomeTax(44725);
        System.assertEquals(3485.00, result, 'Should calculate through second bracket correctly');
    }

    @IsTest
    static void testFederalTaxMidRange75K() {
        // $75,000: taxable = 75000 - 13850 = 61150
        // 10% on 11000 = 1100
        // 12% on (44725-11000=33725) = 4047
        // 22% on (61150-44725=16425) = 3613.50
        // Total = 8760.50
        Decimal result = SalaryCalculationService.calculateFederalIncomeTax(75000);
        System.assertEquals(8760.50, result, 'Should calculate through third bracket correctly for $75K');
    }

    @IsTest
    static void testFederalTax95375() {
        // $95,375: taxable = 95375 - 13850 = 81525
        // 10% on 11000 = 1100
        // 12% on 33725 = 4047
        // 22% on (81525-44725=36800) = 8096
        // Total = 13243.00
        Decimal result = SalaryCalculationService.calculateFederalIncomeTax(95375);
        System.assertEquals(13243.00, result, 'Should calculate through third bracket boundary');
    }

    @IsTest
    static void testSocialSecurityTaxBasic() {
        // $75,000 * 6.2% = 4650.00
        Decimal result = SalaryCalculationService.calculateSocialSecurityTax(75000);
        System.assertEquals(4650.00, result, 'Social Security should be 6.2% of salary');
    }

    @IsTest
    static void testSocialSecurityTaxAtCap() {
        // $160,200 * 6.2% = 9932.40
        Decimal result = SalaryCalculationService.calculateSocialSecurityTax(160200);
        System.assertEquals(9932.40, result, 'Social Security should cap at wage base limit');
    }

    @IsTest
    static void testSocialSecurityTaxAboveCap() {
        // $700,000 -> capped at 160200 * 6.2% = 9932.40
        Decimal result = SalaryCalculationService.calculateSocialSecurityTax(700000);
        System.assertEquals(9932.40, result, 'Social Security should not exceed wage base cap');
    }

    @IsTest
    static void testSocialSecurityTaxNull() {
        Decimal result = SalaryCalculationService.calculateSocialSecurityTax(null);
        System.assertEquals(0, result, 'Null salary should produce zero SS tax');
    }

    @IsTest
    static void testSocialSecurityTaxNegative() {
        Decimal result = SalaryCalculationService.calculateSocialSecurityTax(-10000);
        System.assertEquals(0, result, 'Negative salary should produce zero SS tax');
    }

    @IsTest
    static void testMedicareTaxBasic() {
        // $75,000 * 1.45% = 1087.50
        Decimal result = SalaryCalculationService.calculateMedicareTax(75000);
        System.assertEquals(1087.50, result, 'Medicare should be 1.45% of salary');
    }

    @IsTest
    static void testMedicareTaxNull() {
        Decimal result = SalaryCalculationService.calculateMedicareTax(null);
        System.assertEquals(0, result, 'Null salary should produce zero Medicare tax');
    }

    @IsTest
    static void testMedicareTaxNegative() {
        Decimal result = SalaryCalculationService.calculateMedicareTax(-5000);
        System.assertEquals(0, result, 'Negative salary should produce zero Medicare tax');
    }

    @IsTest
    static void testCalculateTakeHomePayMidRange() {
        Job_Application__c jobApp = [
            SELECT Id, Salary__c, Federal_Tax__c, Social_Security_Tax__c,
                   Medicare_Tax__c, Take_Home_Pay_Yearly__c, Take_Home_Pay_Monthly__c
            FROM Job_Application__c
            WHERE Company_Name__c = 'Mid Salary Co'
            LIMIT 1
        ];

        List<Job_Application__c> apps = new List<Job_Application__c>{ jobApp };

        Test.startTest();
        SalaryCalculationService.calculateTakeHomePay(apps);
        Test.stopTest();

        Job_Application__c updated = apps[0];
        // $75,000: federalTax=8760.50, SS=4650.00, Medicare=1087.50
        System.assertEquals(8760.50, updated.Federal_Tax__c, 'Federal tax should be $8,760.50');
        System.assertEquals(4650.00, updated.Social_Security_Tax__c, 'SS tax should be $4,650.00');
        System.assertEquals(1087.50, updated.Medicare_Tax__c, 'Medicare tax should be $1,087.50');

        Decimal expectedTotalTax = 8760.50 + 4650.00 + 1087.50; // 14498.00
        Decimal expectedYearly = 75000 - expectedTotalTax; // 60502.00
        Decimal expectedMonthly = (expectedYearly / 12).setScale(2);
        System.assertEquals(expectedYearly, updated.Take_Home_Pay_Yearly__c, 'Yearly take-home should match');
        System.assertEquals(expectedMonthly, updated.Take_Home_Pay_Monthly__c, 'Monthly take-home should match');
    }

    @IsTest
    static void testCalculateTakeHomePaySkipsNullSalary() {
        Job_Application__c jobApp = new Job_Application__c(
            Company_Name__c = 'No Salary Co',
            Position_Title__c = 'Intern',
            Status__c = 'Applied'
        );

        List<Job_Application__c> apps = new List<Job_Application__c>{ jobApp };

        Test.startTest();
        SalaryCalculationService.calculateTakeHomePay(apps);
        Test.stopTest();

        System.assertEquals(null, apps[0].Federal_Tax__c, 'Federal tax should remain null for null salary');
    }

    @IsTest
    static void testCalculateTakeHomePaySkipsZeroSalary() {
        Job_Application__c jobApp = [
            SELECT Id, Salary__c, Federal_Tax__c
            FROM Job_Application__c
            WHERE Company_Name__c = 'Zero Salary Co'
            LIMIT 1
        ];

        List<Job_Application__c> apps = new List<Job_Application__c>{ jobApp };

        Test.startTest();
        SalaryCalculationService.calculateTakeHomePay(apps);
        Test.stopTest();

        System.assertEquals(null, apps[0].Federal_Tax__c, 'Federal tax should remain null for zero salary');
    }

    @IsTest
    static void testCalculateSalaryBreakdownMidRange() {
        Test.startTest();
        Map<String, Decimal> result = SalaryCalculationService.calculateSalaryBreakdown(75000);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result map should not be null');
        System.assertEquals(8760.50, result.get('federalTax'), 'Federal tax should match');
        System.assertEquals(4650.00, result.get('socialSecurityTax'), 'SS tax should match');
        System.assertEquals(1087.50, result.get('medicareTax'), 'Medicare tax should match');

        Decimal expectedTotal = (8760.50 + 4650.00 + 1087.50).setScale(2);
        System.assertEquals(expectedTotal, result.get('totalTax'), 'Total tax should match');

        Decimal expectedYearly = (75000 - expectedTotal).setScale(2);
        System.assertEquals(expectedYearly, result.get('takeHomeYearly'), 'Yearly take-home should match');
        System.assert(result.containsKey('takeHomeMonthly'), 'Should contain monthly take-home');
        System.assert(result.containsKey('takeHomeBiWeekly'), 'Should contain bi-weekly take-home');
        System.assert(result.containsKey('takeHomeWeekly'), 'Should contain weekly take-home');
    }

    @IsTest
    static void testCalculateSalaryBreakdownZero() {
        Test.startTest();
        Map<String, Decimal> result = SalaryCalculationService.calculateSalaryBreakdown(0);
        Test.stopTest();

        System.assertEquals(0, result.get('federalTax'), 'Zero salary should return zero federal tax');
        System.assertEquals(0, result.get('totalTax'), 'Zero salary should return zero total tax');
        System.assertEquals(0, result.get('takeHomeYearly'), 'Zero salary should return zero yearly take-home');
    }

    @IsTest
    static void testCalculateSalaryBreakdownNull() {
        Test.startTest();
        Map<String, Decimal> result = SalaryCalculationService.calculateSalaryBreakdown(null);
        Test.stopTest();

        System.assertEquals(0, result.get('federalTax'), 'Null salary should return zero federal tax');
        System.assertEquals(0, result.get('totalTax'), 'Null salary should return zero total tax');
    }

    @IsTest
    static void testCalculateSalaryBreakdownNegative() {
        Test.startTest();
        Map<String, Decimal> result = SalaryCalculationService.calculateSalaryBreakdown(-50000);
        Test.stopTest();

        System.assertEquals(0, result.get('federalTax'), 'Negative salary should return zero');
        System.assertEquals(0, result.get('totalTax'), 'Negative salary should return zero total tax');
    }

    @IsTest
    static void testCalculateTakeHomePayHighSalary() {
        Job_Application__c jobApp = [
            SELECT Id, Salary__c, Federal_Tax__c, Social_Security_Tax__c,
                   Medicare_Tax__c, Take_Home_Pay_Yearly__c, Take_Home_Pay_Monthly__c
            FROM Job_Application__c
            WHERE Company_Name__c = 'Very High Co'
            LIMIT 1
        ];

        List<Job_Application__c> apps = new List<Job_Application__c>{ jobApp };

        Test.startTest();
        SalaryCalculationService.calculateTakeHomePay(apps);
        Test.stopTest();

        Job_Application__c updated = apps[0];
        // $700K: SS capped at 160200*6.2%=9932.40, Medicare=700000*1.45%=10150.00
        System.assertEquals(9932.40, updated.Social_Security_Tax__c, 'SS should cap at wage base');
        System.assertEquals(10150.00, updated.Medicare_Tax__c, 'Medicare should be 1.45% of full salary');
        System.assert(updated.Federal_Tax__c > 0, 'Federal tax should be positive for $700K salary');
        System.assert(updated.Take_Home_Pay_Yearly__c > 0, 'Yearly take-home should be positive');
        System.assert(updated.Take_Home_Pay_Monthly__c > 0, 'Monthly take-home should be positive');
    }

    @IsTest
    static void testCalculateTakeHomePayBulk() {
        List<Job_Application__c> apps = [
            SELECT Id, Salary__c, Federal_Tax__c, Social_Security_Tax__c,
                   Medicare_Tax__c, Take_Home_Pay_Yearly__c, Take_Home_Pay_Monthly__c
            FROM Job_Application__c
            WHERE Salary__c > 0
        ];

        Test.startTest();
        SalaryCalculationService.calculateTakeHomePay(apps);
        Test.stopTest();

        for (Job_Application__c app : apps) {
            System.assert(app.Federal_Tax__c != null, 'Federal tax should be populated for salary > 0');
            System.assert(app.Social_Security_Tax__c != null, 'SS tax should be populated');
            System.assert(app.Medicare_Tax__c != null, 'Medicare tax should be populated');
            System.assert(app.Take_Home_Pay_Yearly__c != null, 'Yearly take-home should be populated');
            System.assert(app.Take_Home_Pay_Monthly__c != null, 'Monthly take-home should be populated');
        }
    }
}
