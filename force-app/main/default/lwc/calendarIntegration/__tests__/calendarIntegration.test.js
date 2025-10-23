import { createElement } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { createRecord } from 'lightning/uiRecordApi';
import CalendarIntegration from 'c/calendarIntegration';

// Mock Lightning Data Service
jest.mock('lightning/uiRecordApi', () => {
    const { createLdsTestWireAdapter } = require('@salesforce/sfdx-lwc-jest');
    return {
        getRecord: createLdsTestWireAdapter(jest.fn()),
        createRecord: jest.fn()
    };
});

// Mock platform show toast event
jest.mock('lightning/platformShowToastEvent', () => {
    return {
        ShowToastEvent: jest.fn()
    };
});

describe('c-calendar-integration', () => {
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
        const element = createElement('c-calendar-integration', {
            is: CalendarIntegration
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
        expect(card.title).toBe('📅 Interview Scheduler');

        const subjectInput = element.shadowRoot.querySelector('lightning-input[label="Interview Subject"]');
        expect(subjectInput).toBeTruthy();
    });

    it('loads job application data and auto-populates subject', async () => {
        const element = createComponent();

        // Mock record data
        const mockRecord = {
            fields: {
                Company_Name__c: { value: 'Tech Corp' },
                Position_Title__c: { value: 'Senior Developer' },
                Status__c: { value: 'Interviewing' }
            }
        };

        // Emit record data
        getRecord.emit(mockRecord);

        await flushPromises();

        // Verify data is loaded and subject is auto-populated
        expect(element.jobApplicationData).toBeTruthy();
        expect(element.eventSubject).toContain('Senior Developer');
        expect(element.eventSubject).toContain('Tech Corp');
    });

    it('handles subject change', async () => {
        const element = createComponent();
        await flushPromises();

        const subjectInput = element.shadowRoot.querySelector('lightning-input[label="Interview Subject"]');

        // Simulate user input
        subjectInput.value = 'Phone Screen Interview';
        subjectInput.dispatchEvent(new CustomEvent('change', {
            detail: { value: 'Phone Screen Interview' }
        }));

        await flushPromises();

        expect(element.eventSubject).toBe('Phone Screen Interview');
    });

    it('auto-sets end time when start time is entered', async () => {
        const element = createComponent();
        await flushPromises();

        const startInput = element.shadowRoot.querySelector('lightning-input[label="Start Date & Time"]');

        // Set start time to 10:00 AM
        const startTime = '2024-01-15T10:00';
        startInput.value = startTime;
        startInput.dispatchEvent(new CustomEvent('change', {
            detail: { value: startTime }
        }));

        await flushPromises();

        // End time should be 1 hour later (11:00 AM)
        expect(element.startDateTime).toBe(startTime);
        expect(element.endDateTime).toBe('2024-01-15T11:00');
    });

    it('handles interview type change and updates subject', async () => {
        const element = createComponent();

        // Mock record data first
        const mockRecord = {
            fields: {
                Company_Name__c: { value: 'Tech Corp' },
                Position_Title__c: { value: 'Senior Developer' },
                Status__c: { value: 'Interviewing' }
            }
        };
        getRecord.emit(mockRecord);
        await flushPromises();

        const typeCombo = element.shadowRoot.querySelector('lightning-combobox[label="Interview Type"]');

        // Select phone screen
        typeCombo.value = 'phone_screen';
        typeCombo.dispatchEvent(new CustomEvent('change', {
            detail: { value: 'phone_screen' }
        }));

        await flushPromises();

        expect(element.interviewType).toBe('phone_screen');
        expect(element.eventSubject).toContain('Phone Screen');
    });

    it('handles location change', async () => {
        const element = createComponent();
        await flushPromises();

        const locationCombo = element.shadowRoot.querySelector('lightning-combobox[label="Location/Platform"]');

        locationCombo.value = 'Zoom';
        locationCombo.dispatchEvent(new CustomEvent('change', {
            detail: { value: 'Zoom' }
        }));

        await flushPromises();

        expect(element.location).toBe('Zoom');
    });

    it('generates time suggestions for business days', () => {
        const element = createComponent();

        expect(element.timeSuggestions).toBeTruthy();
        expect(element.timeSuggestions.length).toBeGreaterThan(0);
        expect(element.timeSuggestions.length).toBeLessThanOrEqual(8);

        // Check that suggestions have required properties
        element.timeSuggestions.forEach(suggestion => {
            expect(suggestion.id).toBeTruthy();
            expect(suggestion.label).toBeTruthy();
            expect(suggestion.startDateTime).toBeTruthy();
            expect(suggestion.endDateTime).toBeTruthy();
        });
    });

    it('applies time suggestion when clicked', async () => {
        const element = createComponent();
        await flushPromises();

        const suggestionButton = element.shadowRoot.querySelector('.time-suggestion-button');
        expect(suggestionButton).toBeTruthy();

        // Simulate clicking a time suggestion
        const mockStart = '2024-01-15T10:00';
        const mockEnd = '2024-01-15T11:00';

        suggestionButton.dataset.start = mockStart;
        suggestionButton.dataset.end = mockEnd;
        suggestionButton.click();

        await flushPromises();

        expect(element.startDateTime).toBe(mockStart);
        expect(element.endDateTime).toBe(mockEnd);
    });

    it('validates required fields', async () => {
        const element = createComponent();
        await flushPromises();

        const scheduleButton = element.shadowRoot.querySelector('lightning-button[label="Schedule Interview"]');
        scheduleButton.click();

        await flushPromises();

        // Should have validation messages
        expect(element.validationMessages.length).toBeGreaterThan(0);

        // Should show error messages
        const errorAlert = element.shadowRoot.querySelector('.slds-alert_error');
        expect(errorAlert).toBeTruthy();
    });

    it('validates end time is after start time', async () => {
        const element = createComponent();

        element.eventSubject = 'Test Interview';
        element.startDateTime = '2024-01-15T14:00';
        element.endDateTime = '2024-01-15T13:00'; // Before start time

        await flushPromises();

        const result = element.validateAllFields();

        expect(result).toBe(false);
        expect(element.validationMessages.some(msg => msg.text.includes('End time must be after start time'))).toBe(true);
    });

    it('validates interview is not in the past', async () => {
        const element = createComponent();

        element.eventSubject = 'Test Interview';
        element.startDateTime = '2020-01-15T10:00'; // Past date
        element.endDateTime = '2020-01-15T11:00';

        await flushPromises();

        const result = element.validateAllFields();

        expect(result).toBe(false);
        expect(element.validationMessages.some(msg => msg.text.includes('Cannot schedule interviews in the past'))).toBe(true);
    });

    it('warns about weekend scheduling', async () => {
        const element = createComponent();

        // Find a Sunday in the future
        const nextSunday = new Date();
        nextSunday.setDate(nextSunday.getDate() + (7 - nextSunday.getDay()));

        const sundayStart = element.formatDateTimeLocal(nextSunday);
        nextSunday.setHours(nextSunday.getHours() + 1);
        const sundayEnd = element.formatDateTimeLocal(nextSunday);

        element.eventSubject = 'Weekend Interview';
        element.startDateTime = sundayStart;
        element.endDateTime = sundayEnd;

        await flushPromises();

        element.validateAllFields();

        expect(element.validationMessages.some(msg => msg.text.includes('weekend'))).toBe(true);
    });

    it('warns about non-business hours', async () => {
        const element = createComponent();

        // Set time to 7 AM (before business hours)
        const tomorrow = new Date();
        tomorrow.setDate(tomorrow.getDate() + 1);
        tomorrow.setHours(7, 0, 0, 0);

        const earlyStart = element.formatDateTimeLocal(tomorrow);
        tomorrow.setHours(8, 0, 0, 0);
        const earlyEnd = element.formatDateTimeLocal(tomorrow);

        element.eventSubject = 'Early Morning Interview';
        element.startDateTime = earlyStart;
        element.endDateTime = earlyEnd;

        await flushPromises();

        element.validateAllFields();

        expect(element.validationMessages.some(msg => msg.text.includes('business hours'))).toBe(true);
    });

    it('clears form successfully', async () => {
        const element = createComponent();

        // Set some values
        element.eventSubject = 'Test Interview';
        element.startDateTime = '2024-01-15T10:00';
        element.endDateTime = '2024-01-15T11:00';
        element.description = 'Test notes';
        element.location = 'Zoom';
        element.interviewType = 'phone_screen';

        await flushPromises();

        // Clear form
        const clearButton = element.shadowRoot.querySelector('lightning-button[label="Clear Form"]');
        clearButton.click();

        await flushPromises();

        // Verify fields are cleared
        expect(element.startDateTime).toBe('');
        expect(element.endDateTime).toBe('');
        expect(element.description).toBe('');
        expect(element.location).toBe('');
        expect(element.interviewType).toBe('');
        expect(element.validationMessages.length).toBe(0);
    });

    it('schedules interview successfully', async () => {
        const element = createComponent('a001234567890123');

        // Mock record data
        const mockRecord = {
            fields: {
                Company_Name__c: { value: 'Tech Corp' },
                Position_Title__c: { value: 'Senior Developer' },
                Status__c: { value: 'Interviewing' }
            }
        };
        getRecord.emit(mockRecord);
        await flushPromises();

        // Set valid interview data
        const tomorrow = new Date();
        tomorrow.setDate(tomorrow.getDate() + 1);
        tomorrow.setHours(14, 0, 0, 0);

        element.eventSubject = 'Technical Interview';
        element.startDateTime = element.formatDateTimeLocal(tomorrow);
        tomorrow.setHours(15, 0, 0, 0);
        element.endDateTime = element.formatDateTimeLocal(tomorrow);
        element.location = 'Zoom';
        element.interviewType = 'technical_interview';
        element.description = 'Prepare coding challenges';

        // Mock successful event creation
        createRecord.mockResolvedValue({ id: 'evt123456' });

        // Schedule the interview
        const scheduleButton = element.shadowRoot.querySelector('lightning-button[label="Schedule Interview"]');
        scheduleButton.click();

        await flushPromises();

        // Verify createRecord was called
        expect(createRecord).toHaveBeenCalled();
        const callArgs = createRecord.mock.calls[0][0];
        expect(callArgs.apiName).toBe('Event');
        expect(callArgs.fields.Subject).toBe('Technical Interview');
        expect(callArgs.fields.Location).toBe('Zoom');
        expect(callArgs.fields.WhatId).toBe('a001234567890123');
    });

    it('builds event description with job details', async () => {
        const element = createComponent();

        // Mock record data
        const mockRecord = {
            fields: {
                Company_Name__c: { value: 'Tech Corp' },
                Position_Title__c: { value: 'Senior Developer' },
                Status__c: { value: 'Interviewing' }
            }
        };
        getRecord.emit(mockRecord);
        await flushPromises();

        element.description = 'Custom notes';
        element.interviewType = 'technical_interview';

        const eventDescription = element.buildEventDescription();

        expect(eventDescription).toContain('Custom notes');
        expect(eventDescription).toContain('Tech Corp');
        expect(eventDescription).toContain('Senior Developer');
        expect(eventDescription).toContain('Interviewing');
        expect(eventDescription).toContain('Technical Interview');
    });

    it('handles error when creating event', async () => {
        const element = createComponent('a001234567890123');

        // Mock record data
        const mockRecord = {
            fields: {
                Company_Name__c: { value: 'Tech Corp' },
                Position_Title__c: { value: 'Senior Developer' },
                Status__c: { value: 'Interviewing' }
            }
        };
        getRecord.emit(mockRecord);
        await flushPromises();

        // Set valid interview data
        const tomorrow = new Date();
        tomorrow.setDate(tomorrow.getDate() + 1);
        tomorrow.setHours(14, 0, 0, 0);

        element.eventSubject = 'Test Interview';
        element.startDateTime = element.formatDateTimeLocal(tomorrow);
        tomorrow.setHours(15, 0, 0, 0);
        element.endDateTime = element.formatDateTimeLocal(tomorrow);

        // Mock error from server
        createRecord.mockRejectedValue({
            body: { message: 'Scheduling conflict detected' }
        });

        // Try to schedule
        const scheduleButton = element.shadowRoot.querySelector('lightning-button[label="Schedule Interview"]');
        scheduleButton.click();

        await flushPromises();

        // Verify error is displayed
        expect(element.validationMessages.length).toBeGreaterThan(0);
        expect(element.validationMessages.some(msg => msg.text.includes('Scheduling conflict'))).toBe(true);
    });

    it('formats datetime correctly', () => {
        const element = createComponent();

        const testDate = new Date('2024-01-15T14:30:00');
        const formatted = element.formatDateTimeLocal(testDate);

        expect(formatted).toBe('2024-01-15T14:30');
    });

    it('formats date short correctly', () => {
        const element = createComponent();

        const testDate = new Date('2024-01-15T14:30:00');
        const formatted = element.formatDateShort(testDate);

        expect(formatted).toContain('Jan');
        expect(formatted).toContain('15');
    });

    it('shows loading indicator when processing', async () => {
        const element = createComponent();

        element.isProcessing = true;
        await flushPromises();

        const spinner = element.shadowRoot.querySelector('lightning-spinner');
        expect(spinner).toBeTruthy();
        expect(spinner.alternativeText).toBe('Processing...');
    });

    it('displays success message after scheduling', async () => {
        const element = createComponent();

        element.showSuccessMessage = true;
        await flushPromises();

        const successAlert = element.shadowRoot.querySelector('.slds-alert_success');
        expect(successAlert).toBeTruthy();
        expect(successAlert.textContent).toContain('Interview scheduled successfully');
    });
});
