// Test the LWC salary breakdown method
Map<String, Decimal> result50K = SalaryCalculationService.calculateSalaryBreakdown(50000);
System.debug('=== $50,000 Salary Breakdown ===');
System.debug('Federal Tax: $' + result50K.get('federalTax'));
System.debug('Social Security Tax: $' + result50K.get('socialSecurityTax'));
System.debug('Medicare Tax: $' + result50K.get('medicareTax'));
System.debug('Total Tax: $' + result50K.get('totalTax'));
System.debug('Take Home Yearly: $' + result50K.get('takeHomeYearly'));
System.debug('Take Home Monthly: $' + result50K.get('takeHomeMonthly'));
System.debug('Take Home Bi-Weekly: $' + result50K.get('takeHomeBiWeekly'));
System.debug('Take Home Weekly: $' + result50K.get('takeHomeWeekly'));

System.debug('\n=== $100,000 Salary Breakdown ===');
Map<String, Decimal> result100K = SalaryCalculationService.calculateSalaryBreakdown(100000);
System.debug('Federal Tax: $' + result100K.get('federalTax'));
System.debug('Social Security Tax: $' + result100K.get('socialSecurityTax'));
System.debug('Medicare Tax: $' + result100K.get('medicareTax'));
System.debug('Total Tax: $' + result100K.get('totalTax'));
System.debug('Take Home Yearly: $' + result100K.get('takeHomeYearly'));
System.debug('Take Home Monthly: $' + result100K.get('takeHomeMonthly'));

System.debug('\n=== Edge Case: $0 Salary ===');
Map<String, Decimal> resultZero = SalaryCalculationService.calculateSalaryBreakdown(0);
System.debug('Take Home Yearly: $' + resultZero.get('takeHomeYearly'));

System.debug('\n=== Edge Case: Null Salary ===');
Map<String, Decimal> resultNull = SalaryCalculationService.calculateSalaryBreakdown(null);
System.debug('Take Home Yearly: $' + resultNull.get('takeHomeYearly'));