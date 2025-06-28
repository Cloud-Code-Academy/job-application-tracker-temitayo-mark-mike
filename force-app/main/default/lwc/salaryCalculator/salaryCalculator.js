import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import calculateSalaryBreakdown from '@salesforce/apex/SalaryCalculationService.calculateSalaryBreakdown';

// Job Application fields
import SALARY_FIELD from '@salesforce/schema/Job_Application__c.Salary__c';
import FEDERAL_TAX_FIELD from '@salesforce/schema/Job_Application__c.Federal_Tax__c';
import SOCIAL_SECURITY_TAX_FIELD from '@salesforce/schema/Job_Application__c.Social_Security_Tax__c';
import MEDICARE_TAX_FIELD from '@salesforce/schema/Job_Application__c.Medicare_Tax__c';
import TAKE_HOME_YEARLY_FIELD from '@salesforce/schema/Job_Application__c.Take_Home_Pay_Yearly__c';
import TAKE_HOME_MONTHLY_FIELD from '@salesforce/schema/Job_Application__c.Take_Home_Pay_Monthly__c';

const FIELDS = [
    SALARY_FIELD,
    FEDERAL_TAX_FIELD,
    SOCIAL_SECURITY_TAX_FIELD,
    MEDICARE_TAX_FIELD,
    TAKE_HOME_YEARLY_FIELD,
    TAKE_HOME_MONTHLY_FIELD
];

// Tax calculation constants (2023 rates)
const TAX_CONSTANTS = {
    STANDARD_DEDUCTION: 13850,
    SOCIAL_SECURITY_RATE: 0.062,
    SOCIAL_SECURITY_WAGE_BASE: 160200,
    MEDICARE_RATE: 0.0145,
    TAX_BRACKETS: [
        { min: 0, max: 11000, rate: 0.10 },
        { min: 11000, max: 44725, rate: 0.12 },
        { min: 44725, max: 95375, rate: 0.22 },
        { min: 95375, max: 182050, rate: 0.24 },
        { min: 182050, max: 231250, rate: 0.32 },
        { min: 231250, max: 578125, rate: 0.35 },
        { min: 578125, max: Infinity, rate: 0.37 }
    ]
};

export default class SalaryCalculator extends LightningElement {
    @api recordId; // Job Application record ID
    
    // Component state
    @track salary = 0;
    @track federalTax = 0;
    @track socialSecurityTax = 0;
    @track medicareTax = 0;
    @track takeHomeYearly = 0;
    @track takeHomeMonthly = 0;
    @track isCalculating = false;
    @track calculationError = null;
    @track selectedMethod = 'client';

    // Calculation method options
    calculationMethods = [
        { label: 'Real-time (Client)', value: 'client' },
        { label: 'Precise (Server)', value: 'server' }
    ];

    // Wire to get record data
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data }) {
        if (data) {
            this.salary = data.fields.Salary__c.value || 0;
            this.federalTax = data.fields.Federal_Tax__c.value || 0;
            this.socialSecurityTax = data.fields.Social_Security_Tax__c.value || 0;
            this.medicareTax = data.fields.Medicare_Tax__c.value || 0;
            this.takeHomeYearly = data.fields.Take_Home_Pay_Yearly__c.value || 0;
            this.takeHomeMonthly = data.fields.Take_Home_Pay_Monthly__c.value || 0;
            
            // If salary exists but no calculations, calculate them
            if (this.salary > 0 && this.takeHomeYearly === 0) {
                this.calculateTakeHome();
            }
        } else if (error) {
            this.handleError('Error loading record data', error);
        }
    }

    // Computed properties for formatting
    get formattedFederalTax() {
        return this.formatCurrency(this.federalTax);
    }

    get formattedSocialSecurityTax() {
        return this.formatCurrency(this.socialSecurityTax);
    }

    get formattedMedicareTax() {
        return this.formatCurrency(this.medicareTax);
    }

    get formattedTotalTax() {
        const total = this.federalTax + this.socialSecurityTax + this.medicareTax;
        return this.formatCurrency(total);
    }

    get formattedYearlyTakeHome() {
        return this.formatCurrency(this.takeHomeYearly);
    }

    get formattedMonthlyTakeHome() {
        return this.formatCurrency(this.takeHomeMonthly);
    }

    get formattedBiWeeklyTakeHome() {
        return this.formatCurrency(this.takeHomeYearly / 26);
    }

    get formattedWeeklyTakeHome() {
        return this.formatCurrency(this.takeHomeYearly / 52);
    }

    // Tax percentages
    get federalTaxPercentage() {
        return this.salary > 0 ? ((this.federalTax / this.salary) * 100).toFixed(1) : '0.0';
    }

    get socialSecurityPercentage() {
        return this.salary > 0 ? ((this.socialSecurityTax / this.salary) * 100).toFixed(1) : '0.0';
    }

    get medicarePercentage() {
        return this.salary > 0 ? ((this.medicareTax / this.salary) * 100).toFixed(1) : '0.0';
    }

    get totalTaxPercentage() {
        const total = this.federalTax + this.socialSecurityTax + this.medicareTax;
        return this.salary > 0 ? ((total / this.salary) * 100).toFixed(1) : '0.0';
    }

    get isClientSideCalculation() {
        return this.selectedMethod === 'client';
    }

    // Event handlers
    handleSalaryChange(event) {
        this.salary = parseFloat(event.target.value) || 0;
        this.calculationError = null;
        
        // Validate input
        if (this.salary < 0) {
            this.calculationError = 'Salary cannot be negative';
            return;
        }
        
        if (this.salary > 10000000) {
            this.calculationError = 'Salary amount seems unusually high';
            return;
        }

        // Debounced calculation
        this.debounceCalculation();
    }

    handleMethodChange(event) {
        this.selectedMethod = event.detail.value;
        if (this.salary > 0) {
            this.calculateTakeHome();
        }
    }

    handleReset() {
        this.salary = 0;
        this.federalTax = 0;
        this.socialSecurityTax = 0;
        this.medicareTax = 0;
        this.takeHomeYearly = 0;
        this.takeHomeMonthly = 0;
        this.calculationError = null;
    }

    async handleSaveToRecord() {
        if (!this.recordId) {
            this.showToast('Error', 'No record ID available', 'error');
            return;
        }

        try {
            this.isCalculating = true;
            
            const fields = {};
            fields.Id = this.recordId;
            fields[SALARY_FIELD.fieldApiName] = this.salary;
            fields[FEDERAL_TAX_FIELD.fieldApiName] = this.federalTax;
            fields[SOCIAL_SECURITY_TAX_FIELD.fieldApiName] = this.socialSecurityTax;
            fields[MEDICARE_TAX_FIELD.fieldApiName] = this.medicareTax;
            fields[TAKE_HOME_YEARLY_FIELD.fieldApiName] = this.takeHomeYearly;
            fields[TAKE_HOME_MONTHLY_FIELD.fieldApiName] = this.takeHomeMonthly;

            await updateRecord({ fields });
            
            this.showToast('Success', 'Salary calculations saved to record', 'success');
            
        } catch (error) {
            this.handleError('Error saving to record', error);
        } finally {
            this.isCalculating = false;
        }
    }

    // Calculation methods
    debounceCalculation() {
        // Clear existing timeout
        if (this.calculationTimeout) {
            clearTimeout(this.calculationTimeout);
        }
        
        // Set new timeout for debounced calculation
        this.calculationTimeout = setTimeout(() => {
            this.calculateTakeHome();
        }, 300); // 300ms debounce
    }

    async calculateTakeHome() {
        if (this.salary <= 0) {
            this.resetCalculations();
            return;
        }

        try {
            this.isCalculating = true;
            this.calculationError = null;

            if (this.selectedMethod === 'client') {
                this.calculateClientSide();
            } else {
                await this.calculateServerSide();
            }
        } catch (error) {
            this.handleError('Calculation error', error);
        } finally {
            this.isCalculating = false;
        }
    }

    calculateClientSide() {
        // Client-side calculation using JavaScript
        this.federalTax = this.calculateFederalTax(this.salary);
        this.socialSecurityTax = this.calculateSocialSecurityTax(this.salary);
        this.medicareTax = this.calculateMedicareTax(this.salary);
        
        const totalTax = this.federalTax + this.socialSecurityTax + this.medicareTax;
        this.takeHomeYearly = this.salary - totalTax;
        this.takeHomeMonthly = this.takeHomeYearly / 12;
    }

    async calculateServerSide() {
        // Server-side calculation using Apex
        const result = await calculateSalaryBreakdown({ salary: this.salary });
        
        this.federalTax = result.federalTax || 0;
        this.socialSecurityTax = result.socialSecurityTax || 0;
        this.medicareTax = result.medicareTax || 0;
        this.takeHomeYearly = result.takeHomeYearly || 0;
        this.takeHomeMonthly = result.takeHomeMonthly || 0;
    }

    // Tax calculation methods (client-side)
    calculateFederalTax(grossSalary) {
        const taxableIncome = Math.max(0, grossSalary - TAX_CONSTANTS.STANDARD_DEDUCTION);
        
        if (taxableIncome <= 0) return 0;
        
        let totalTax = 0;
        let remainingIncome = taxableIncome;
        
        for (const bracket of TAX_CONSTANTS.TAX_BRACKETS) {
            if (remainingIncome <= 0) break;
            
            const bracketWidth = bracket.max - bracket.min;
            const taxableInBracket = Math.min(remainingIncome, bracketWidth);
            
            if (taxableIncome > bracket.min) {
                totalTax += taxableInBracket * bracket.rate;
                remainingIncome -= taxableInBracket;
            }
        }
        
        return Math.round(totalTax * 100) / 100; // Round to 2 decimal places
    }

    calculateSocialSecurityTax(grossSalary) {
        const taxableWages = Math.min(grossSalary, TAX_CONSTANTS.SOCIAL_SECURITY_WAGE_BASE);
        return Math.round(taxableWages * TAX_CONSTANTS.SOCIAL_SECURITY_RATE * 100) / 100;
    }

    calculateMedicareTax(grossSalary) {
        return Math.round(grossSalary * TAX_CONSTANTS.MEDICARE_RATE * 100) / 100;
    }

    // Utility methods
    resetCalculations() {
        this.federalTax = 0;
        this.socialSecurityTax = 0;
        this.medicareTax = 0;
        this.takeHomeYearly = 0;
        this.takeHomeMonthly = 0;
    }

    formatCurrency(amount) {
        return new Intl.NumberFormat('en-US', {
            style: 'currency',
            currency: 'USD',
            minimumFractionDigits: 0,
            maximumFractionDigits: 0
        }).format(amount || 0);
    }

    handleError(title, error) {
        console.error(title, error);
        this.calculationError = error.body?.message || error.message || 'An unexpected error occurred';
        this.showToast(title, this.calculationError, 'error');
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title,
            message,
            variant
        }));
    }
}
