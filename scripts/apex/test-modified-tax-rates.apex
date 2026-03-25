// Test modified tax rates to understand impact
// Let's manually calculate what happens if we increase Social Security rate from 6.2% to 7.0%

Decimal salary = 100000;
Decimal originalSSRate = 0.062;
Decimal modifiedSSRate = 0.070;

// Original calculation
Decimal originalSSTax = salary * originalSSRate;
Decimal modifiedSSTax = salary * modifiedSSRate;
Decimal difference = modifiedSSTax - originalSSTax;

System.debug('=== Tax Rate Modification Impact ===');
System.debug('Salary: $' + salary);
System.debug('Original SS Rate (6.2%): $' + originalSSTax);
System.debug('Modified SS Rate (7.0%): $' + modifiedSSTax);
System.debug('Annual Difference: $' + difference);
System.debug('Monthly Difference: $' + (difference/12).setScale(2));

// Test with different federal tax brackets
System.debug('\n=== Federal Tax Bracket Analysis ===');
// Current system: 22% bracket starts at $44,725
// Let's see what happens if it started at $40,000 instead

Decimal income = 60000;
Decimal standardDeduction = 13850;
Decimal taxableIncome = income - standardDeduction; // $46,150

// Current brackets: 10% up to $11K, 12% from $11K to $44,725, 22% from $44,725+
Decimal currentTax = (11000 * 0.10) + ((44725 - 11000) * 0.12) + ((taxableIncome - 44725) * 0.22);

// Modified brackets: 10% up to $11K, 12% from $11K to $40,000, 22% from $40,000+
Decimal modifiedTax = (11000 * 0.10) + ((40000 - 11000) * 0.12) + ((taxableIncome - 40000) * 0.22);

System.debug('$60K salary with current brackets: $' + currentTax.setScale(2));
System.debug('$60K salary with modified brackets: $' + modifiedTax.setScale(2));
System.debug('Tax increase from bracket change: $' + (modifiedTax - currentTax).setScale(2));