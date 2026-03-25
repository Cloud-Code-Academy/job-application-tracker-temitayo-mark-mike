import { createElement } from 'lwc';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
import SalaryCalculator from 'c/salaryCalculator';
import calculateSalaryBreakdown from '@salesforce/apex/SalaryCalculationService.calculateSalaryBreakdown';

// Mock Apex method
jest.mock(
    '@salesforce/apex/SalaryCalculationService.calculateSalaryBreakdown',
    () => {
        const { createApexTestWireAdapter } = require('@salesforce/sfdx-lwc-jest');
        return {
            default: createApexTestWireAdapter(jest.fn())
        };
    },
    { virtual: true }
);

// Mock Lightning Data Service
jest.mock('lightning/uiRecordApi', () => {
    const { createLdsTestWireAdapter } = require('@salesforce/sfdx-lwc-jest');
    return {
        getRecord: createLdsTestWireAdapter(jest.fn()),
        updateRecord: jest.fn()
    };
});

// Mock platform show toast event
jest.mock('lightning/platformShowToastEvent', () => {
    return {
        ShowToastEvent: jest.fn()
    };
});

describe('c-salary-calculator', () => {
    afterEach(() => {
        // Clean up DOM after each test
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        
        // Clear all mocks
        jest.clearAllMocks();
    });

    // Helper function to create component
    function createComponent(recordId = 'a001234567890123') {
        const element = createElement('c-salary-calculator', {
            is: SalaryCalculator
        });
        element.recordId = recordId;
        document.body.appendChild(element);
        return element;
    }

    // Helper function to wait for async operations
    function flushPromises() {
        return new Promise(resolve => setImmediate(resolve));
    }

    it('renders correctly with default values', () => {
        const element = createComponent();

        // Check that the component renders
        expect(element).toBeTruthy();
        
        // Check for key elements
        const card = element.shadowRoot.querySelector('lightning-card');
        expect(card).toBeTruthy();
        expect(card.title).toBe('💰 Salary Calculator');

        const salaryInput = element.shadowRoot.querySelector('lightning-input[label="Annual Salary"]');
        expect(salaryInput).toBeTruthy();
    });

    it('handles salary input changes', async () => {
        const element = createComponent();
        await flushPromises();

        const salaryInput = element.shadowRoot.querySelector('lightning-input[label="Annual Salary"]');
        
        // Simulate user input
        salaryInput.value = 100000;
        salaryInput.dispatchEvent(new CustomEvent('change', {
            detail: { value: 100000 }
        }));

        await flushPromises();

        // Check that salary was updated
        expect(element.salary).toBe(100000);
    });

    it('calculates client-side taxes correctly', async () => {
        const element = createComponent();
        await flushPromises();

        // Set salary and trigger calculation
        element.salary = 100000;
        element.selectedMethod = 'client';
        
        // Trigger calculation
        await element.calculateTakeHome();

        // Verify calculations (approximate values)
        expect(element.federalTax).toBeGreaterThan(0);
        expect(element.socialSecurityTax).toBeCloseTo(6200, 0); // 6.2% of 100k
        expect(element.medicareTax).toBeCloseTo(1450, 0); // 1.45% of 100k
        expect(element.takeHomeYearly).toBeLessThan(100000);
        expect(element.takeHomeMonthly).toBeCloseTo(element.takeHomeYearly / 12, 2);
    });

    it('handles server-side calculation', async () => {
        const element = createComponent();
        
        // Mock server response
        const mockResponse = {
            federalTax: 15000,
            socialSecurityTax: 6200,
            medicareTax: 1450,
            totalTax: 22650,
            takeHomeYearly: 77350,
            takeHomeMonthly: 6445.83,
            takeHomeBiWeekly: 2975,
            takeHomeWeekly: 1487.5
        };
        
        calculateSalaryBreakdown.mockResolvedValue(mockResponse);

        element.salary = 100000;
        element.selectedMethod = 'server';
        
        await element.calculateTakeHome();

        // Verify server values are used
        expect(element.federalTax).toBe(15000);
        expect(element.socialSecurityTax).toBe(6200);
        expect(element.medicareTax).toBe(1450);
        expect(element.takeHomeYearly).toBe(77350);
        expect(element.takeHomeMonthly).toBe(6445.83);
    });

    it('validates salary input correctly', async () => {
        const element = createComponent();
        await flushPromises();

        const salaryInput = element.shadowRoot.querySelector('lightning-input[label="Annual Salary"]');
        
        // Test negative salary
        salaryInput.value = -1000;
        salaryInput.dispatchEvent(new CustomEvent('change', {
            detail: { value: -1000 }
        }));

        await flushPromises();

        expect(element.calculationError).toBe('Salary cannot be negative');

        // Test extremely high salary
        salaryInput.value = 15000000;
        salaryInput.dispatchEvent(new CustomEvent('change', {
            detail: { value: 15000000 }
        }));

        await flushPromises();

        expect(element.calculationError).toBe('Salary amount seems unusually high');
    });

    it('formats currency correctly', () => {
        const element = createComponent();

        // Test currency formatting
        expect(element.formatCurrency(100000)).toBe('$100,000');
        expect(element.formatCurrency(1234.56)).toBe('$1,235');
        expect(element.formatCurrency(0)).toBe('$0');
        expect(element.formatCurrency(null)).toBe('$0');
    });

    it('calculates tax percentages correctly', async () => {
        const element = createComponent();
        
        element.salary = 100000;
        element.federalTax = 15000;
        element.socialSecurityTax = 6200;
        element.medicareTax = 1450;

        await flushPromises();

        expect(element.federalTaxPercentage).toBe('15.0');
        expect(element.socialSecurityPercentage).toBe('6.2');
        expect(element.medicarePercentage).toBe('1.5');
        expect(element.totalTaxPercentage).toBe('22.7');
    });

    it('handles reset functionality', async () => {
        const element = createComponent();
        
        // Set some values
        element.salary = 100000;
        element.federalTax = 15000;
        element.socialSecurityTax = 6200;
        element.medicareTax = 1450;
        element.takeHomeYearly = 77350;
        element.takeHomeMonthly = 6445.83;

        await flushPromises();

        // Find and click reset button
        const resetButton = element.shadowRoot.querySelector('lightning-button[label="Reset"]');
        expect(resetButton).toBeTruthy();
        
        resetButton.click();

        await flushPromises();

        // Verify all values are reset
        expect(element.salary).toBe(0);
        expect(element.federalTax).toBe(0);
        expect(element.socialSecurityTax).toBe(0);
        expect(element.medicareTax).toBe(0);
        expect(element.takeHomeYearly).toBe(0);
        expect(element.takeHomeMonthly).toBe(0);
        expect(element.calculationError).toBeNull();
    });

    it('handles record data loading', async () => {
        const element = createComponent();
        
        // Mock record data
        const mockRecord = {
            fields: {
                Salary__c: { value: 85000 },
                Federal_Tax__c: { value: 12000 },
                Social_Security_Tax__c: { value: 5270 },
                Medicare_Tax__c: { value: 1232.5 },
                Take_Home_Pay_Yearly__c: { value: 66497.5 },
                Take_Home_Pay_Monthly__c: { value: 5541.46 }
            }
        };

        // Emit record data
        getRecord.emit(mockRecord);

        await flushPromises();

        // Verify data is loaded
        expect(element.salary).toBe(85000);
        expect(element.federalTax).toBe(12000);
        expect(element.socialSecurityTax).toBe(5270);
        expect(element.medicareTax).toBe(1232.5);
        expect(element.takeHomeYearly).toBe(66497.5);
        expect(element.takeHomeMonthly).toBe(5541.46);
    });

    it('handles save to record functionality', async () => {
        const element = createComponent('a001234567890123');
        
        // Set some calculated values
        element.salary = 100000;
        element.federalTax = 15000;
        element.socialSecurityTax = 6200;
        element.medicareTax = 1450;
        element.takeHomeYearly = 77350;
        element.takeHomeMonthly = 6445.83;

        await flushPromises();

        // Mock successful update
        updateRecord.mockResolvedValue({});

        // Find and click save button
        const saveButton = element.shadowRoot.querySelector('lightning-button[label="Save to Record"]');
        expect(saveButton).toBeTruthy();
        
        saveButton.click();

        await flushPromises();

        // Verify updateRecord was called with correct data
        expect(updateRecord).toHaveBeenCalledWith({
            fields: expect.objectContaining({
                Id: 'a001234567890123',
                'Salary__c': 100000,
                'Federal_Tax__c': 15000,
                'Social_Security_Tax__c': 6200,
                'Medicare_Tax__c': 1450,
                'Take_Home_Pay_Yearly__c': 77350,
                'Take_Home_Pay_Monthly__c': 6445.83
            })
        });
    });

    it('handles calculation method changes', async () => {
        const element = createComponent();
        await flushPromises();

        const radioGroup = element.shadowRoot.querySelector('lightning-radio-group');
        expect(radioGroup).toBeTruthy();

        // Change to server method
        radioGroup.dispatchEvent(new CustomEvent('change', {
            detail: { value: 'server' }
        }));

        await flushPromises();

        expect(element.selectedMethod).toBe('server');
        expect(element.isClientSideCalculation).toBe(false);
    });

    it('displays loading state correctly', async () => {
        const element = createComponent();
        
        element.isCalculating = true;
        await flushPromises();

        const spinner = element.shadowRoot.querySelector('lightning-spinner');
        expect(spinner).toBeTruthy();
        expect(spinner.alternativeText).toBe('Calculating...');
    });

    it('displays error messages correctly', async () => {
        const element = createComponent();
        
        element.calculationError = 'Test error message';
        await flushPromises();

        const errorAlert = element.shadowRoot.querySelector('.slds-alert_error');
        expect(errorAlert).toBeTruthy();
        expect(errorAlert.textContent).toContain('Test error message');
    });
});
