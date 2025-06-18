/**
 * @description Service class for calculating take-home pay including tax deductions
 * Implements 2023 US Federal tax brackets, Social Security, and Medicare calculations
 * @author Temitayo Oluwalade
 * @date 2024
 */
public with sharing class SalaryCalculationService {
    
    // 2023 Tax rates and limits
    private static final Decimal SOCIAL_SECURITY_RATE = 0.062; // 6.20%
    private static final Decimal MEDICARE_RATE = 0.0145; // 1.45%
    private static final Decimal STANDARD_DEDUCTION_SINGLE = 13850; // 2023 standard deduction
    
    // 2023 Federal tax brackets for single filers
    private static final List<TaxBracket> TAX_BRACKETS = new List<TaxBracket>{
        new TaxBracket(0, 11000, 0.10),
        new TaxBracket(11000, 44725, 0.12),
        new TaxBracket(44725, 95375, 0.22),
        new TaxBracket(95375, 182050, 0.24),
        new TaxBracket(182050, 231250, 0.32),
        new TaxBracket(231250, 578125, 0.35),
        new TaxBracket(578125, Decimal.valueOf('999999999'), 0.37)
    };
    
    /**
     * @description Calculates take-home pay for job applications with salary
     * @param jobApplications List of Job Application records
     */
    public static void calculateTakeHomePay(List<Job_Application__c> jobApplications) {
        for (Job_Application__c jobApp : jobApplications) {
            if (jobApp.Salary__c != null && jobApp.Salary__c > 0) {
                calculateTaxesAndTakeHome(jobApp);
            }
        }
    }
    
    /**
     * @description Calculates all tax components and take-home pay for a single job application
     * @param jobApp Job Application record
     */
    private static void calculateTaxesAndTakeHome(Job_Application__c jobApp) {
        Decimal grossSalary = jobApp.Salary__c;
        
        // Calculate federal income tax
        Decimal federalTax = calculateFederalIncomeTax(grossSalary);
        
        // Calculate Social Security tax (6.20% up to wage base limit)
        Decimal socialSecurityTax = calculateSocialSecurityTax(grossSalary);
        
        // Calculate Medicare tax (1.45% on all income)
        Decimal medicareTax = calculateMedicareTax(grossSalary);
        
        // Calculate take-home pay
        Decimal totalTaxes = federalTax + socialSecurityTax + medicareTax;
        Decimal takeHomeYearly = grossSalary - totalTaxes;
        Decimal takeHomeMonthly = takeHomeYearly / 12;
        
        // Update the job application record
        jobApp.Federal_Tax__c = federalTax;
        jobApp.Social_Security_Tax__c = socialSecurityTax;
        jobApp.Medicare_Tax__c = medicareTax;
        jobApp.Take_Home_Pay_Yearly__c = takeHomeYearly;
        jobApp.Take_Home_Pay_Monthly__c = takeHomeMonthly;
    }
    
    /**
     * @description Calculates federal income tax using 2023 tax brackets
     * @param grossIncome Gross annual income
     * @return Federal income tax amount
     */
    public static Decimal calculateFederalIncomeTax(Decimal grossIncome) {
        if (grossIncome == null || grossIncome <= 0) {
            return 0;
        }
        
        // Apply standard deduction
        Decimal taxableIncome = Math.max(0, grossIncome - STANDARD_DEDUCTION_SINGLE);
        
        if (taxableIncome <= 0) {
            return 0;
        }
        
        Decimal totalTax = 0;
        Decimal remainingIncome = taxableIncome;
        
        for (TaxBracket bracket : TAX_BRACKETS) {
            if (remainingIncome <= 0) {
                break;
            }
            
            Decimal bracketWidth = bracket.upperLimit - bracket.lowerLimit;
            Decimal taxableInThisBracket = Math.min(remainingIncome, bracketWidth);
            
            if (taxableIncome > bracket.lowerLimit) {
                totalTax += taxableInThisBracket * bracket.rate;
                remainingIncome -= taxableInThisBracket;
            }
        }
        
        return totalTax.setScale(2);
    }
    
    /**
     * @description Calculates Social Security tax (6.20% up to wage base)
     * @param grossIncome Gross annual income
     * @return Social Security tax amount
     */
    public static Decimal calculateSocialSecurityTax(Decimal grossIncome) {
        if (grossIncome == null || grossIncome <= 0) {
            return 0;
        }
        
        // 2023 Social Security wage base limit
        Decimal wageBaseLimit = 160200;
        Decimal taxableWages = Math.min(grossIncome, wageBaseLimit);
        
        return (taxableWages * SOCIAL_SECURITY_RATE).setScale(2);
    }
    
    /**
     * @description Calculates Medicare tax (1.45% on all income)
     * @param grossIncome Gross annual income
     * @return Medicare tax amount
     */
    public static Decimal calculateMedicareTax(Decimal grossIncome) {
        if (grossIncome == null || grossIncome <= 0) {
            return 0;
        }

        return (grossIncome * MEDICARE_RATE).setScale(2);
    }

    /**
     * @description Calculates complete salary breakdown for Lightning Web Component
     * @param salary Gross annual salary
     * @return Map containing all tax calculations and take-home pay
     */
    @AuraEnabled(cacheable=false)
    public static Map<String, Decimal> calculateSalaryBreakdown(Decimal salary) {
        try {
            if (salary == null || salary <= 0) {
                return new Map<String, Decimal>{
                    'federalTax' => 0,
                    'socialSecurityTax' => 0,
                    'medicareTax' => 0,
                    'totalTax' => 0,
                    'takeHomeYearly' => 0,
                    'takeHomeMonthly' => 0,
                    'takeHomeBiWeekly' => 0,
                    'takeHomeWeekly' => 0
                };
            }

            // Calculate individual tax components
            Decimal federalTax = calculateFederalIncomeTax(salary);
            Decimal socialSecurityTax = calculateSocialSecurityTax(salary);
            Decimal medicareTax = calculateMedicareTax(salary);
            Decimal totalTax = federalTax + socialSecurityTax + medicareTax;

            // Calculate take-home pay in different intervals
            Decimal takeHomeYearly = salary - totalTax;
            Decimal takeHomeMonthly = takeHomeYearly / 12;
            Decimal takeHomeBiWeekly = takeHomeYearly / 26;
            Decimal takeHomeWeekly = takeHomeYearly / 52;

            return new Map<String, Decimal>{
                'federalTax' => federalTax.setScale(2),
                'socialSecurityTax' => socialSecurityTax.setScale(2),
                'medicareTax' => medicareTax.setScale(2),
                'totalTax' => totalTax.setScale(2),
                'takeHomeYearly' => takeHomeYearly.setScale(2),
                'takeHomeMonthly' => takeHomeMonthly.setScale(2),
                'takeHomeBiWeekly' => takeHomeBiWeekly.setScale(2),
                'takeHomeWeekly' => takeHomeWeekly.setScale(2)
            };

        } catch (Exception e) {
            System.debug('Error in calculateSalaryBreakdown: ' + e.getMessage());
            throw new AuraHandledException('Error calculating salary breakdown: ' + e.getMessage());
        }
    }
    
    /**
     * @description Inner class to represent tax brackets
     */
    private class TaxBracket {
        public Decimal lowerLimit;
        public Decimal upperLimit;
        public Decimal rate;
        
        public TaxBracket(Decimal lower, Decimal upper, Decimal taxRate) {
            this.lowerLimit = lower;
            this.upperLimit = upper;
            this.rate = taxRate;
        }
    }
}
