import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';

const FIELDS = ['Job__c.Salary__c'];

export default class TakeHomePayEstimator extends LightningElement {
  @api recordId;
  salary = 50000;

  @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
  job({ data, error }) {
    if (data && data.fields.Salary__c && data.fields.Salary__c.value) {
      this.salary = data.fields.Salary__c.value;
    }
  }

  handleSalaryChange(event) {
    this.salary = Number(event.target.value);
  }

  get formattedSalary() {
    return this.salary.toLocaleString('en-US', { style: 'currency', currency: 'USD' });
  }

  get federalTax() {
    return parseFloat(this.calculateFederalTax(this.salary)).toFixed(2);
  }

  get socialSecurity() {
    return (this.salary * 0.062).toFixed(2);
  }

  get medicare() {
    return (this.salary * 0.0145).toFixed(2);
  }

  get takeHome() {
    const tax = parseFloat(this.calculateFederalTax(this.salary));
    const ss = this.salary * 0.062;
    const medicare = this.salary * 0.0145;
    return (this.salary - tax - ss - medicare).toFixed(2);
  }

  get sixMonth() {
    return (parseFloat(this.takeHome) / 2).toFixed(2);
  }

  get monthly() {
    return (parseFloat(this.takeHome) / 12).toFixed(2);
  }

  get biWeekly() {
    return (parseFloat(this.takeHome) / 26).toFixed(2);
  }

  calculateFederalTax(income) {
    const brackets = [
      { limit: 11000, rate: 0.10 },
      { limit: 44725, rate: 0.12 },
      { limit: 95375, rate: 0.22 },
      { limit: 182100, rate: 0.24 },
      { limit: 231250, rate: 0.32 },
      { limit: 578125, rate: 0.35 },
      { limit: Infinity, rate: 0.37 }
    ];

    let tax = 0;
    let prevLimit = 0;

    for (const bracket of brackets) {
      if (income > bracket.limit) {
        tax += (bracket.limit - prevLimit) * bracket.rate;
        prevLimit = bracket.limit;
      } else {
        tax += (income - prevLimit) * bracket.rate;
        break;
      }
    }

    return tax;
  }
}
