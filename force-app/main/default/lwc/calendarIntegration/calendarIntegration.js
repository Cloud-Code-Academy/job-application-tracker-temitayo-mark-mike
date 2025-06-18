import { LightningElement, api, track, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { createRecord } from 'lightning/uiRecordApi';

// Job Application fields
import COMPANY_NAME_FIELD from '@salesforce/schema/Job_Application__c.Company_Name__c';
import POSITION_TITLE_FIELD from '@salesforce/schema/Job_Application__c.Position_Title__c';
import STATUS_FIELD from '@salesforce/schema/Job_Application__c.Status__c';

// Event object and fields
import EVENT_OBJECT from '@salesforce/schema/Event';
import SUBJECT_FIELD from '@salesforce/schema/Event.Subject';
import START_DATETIME_FIELD from '@salesforce/schema/Event.StartDateTime';
import END_DATETIME_FIELD from '@salesforce/schema/Event.EndDateTime';
import DESCRIPTION_FIELD from '@salesforce/schema/Event.Description';
import LOCATION_FIELD from '@salesforce/schema/Event.Location';
import WHAT_ID_FIELD from '@salesforce/schema/Event.WhatId';

const JOB_APPLICATION_FIELDS = [
    COMPANY_NAME_FIELD,
    POSITION_TITLE_FIELD,
    STATUS_FIELD
];

export default class CalendarIntegration extends LightningElement {
    @api recordId; // Job Application record ID
    
    // Component state
    @track eventSubject = '';
    @track startDateTime = '';
    @track endDateTime = '';
    @track description = '';
    @track location = '';
    @track interviewType = '';
    @track isProcessing = false;
    @track showSuccessMessage = false;
    @track validationMessages = [];
    @track conflictCheckResults = [];
    @track jobApplicationData = null;

    // Interview type options
    interviewTypeOptions = [
        { label: 'Phone Screen', value: 'phone_screen' },
        { label: 'Video Interview', value: 'video_interview' },
        { label: 'Technical Interview', value: 'technical_interview' },
        { label: 'Panel Interview', value: 'panel_interview' },
        { label: 'Final Interview', value: 'final_interview' },
        { label: 'Informal Chat', value: 'informal_chat' }
    ];

    // Location/Platform options
    locationOptions = [
        { label: 'Zoom', value: 'Zoom' },
        { label: 'Microsoft Teams', value: 'Microsoft Teams' },
        { label: 'Google Meet', value: 'Google Meet' },
        { label: 'Phone Call', value: 'Phone Call' },
        { label: 'Company Office', value: 'Company Office' },
        { label: 'Coffee Shop', value: 'Coffee Shop' },
        { label: 'Other', value: 'Other' }
    ];

    // Wire to get Job Application data
    @wire(getRecord, { recordId: '$recordId', fields: JOB_APPLICATION_FIELDS })
    wiredJobApplication({ error, data }) {
        if (data) {
            this.jobApplicationData = {
                Company_Name__c: data.fields.Company_Name__c.value,
                Position_Title__c: data.fields.Position_Title__c.value,
                Status__c: data.fields.Status__c.value
            };
            
            // Auto-populate subject if not already set
            if (!this.eventSubject && this.jobApplicationData) {
                this.eventSubject = `Interview - ${this.jobApplicationData.Position_Title__c} at ${this.jobApplicationData.Company_Name__c}`;
            }
        } else if (error) {
            this.showToast('Error', 'Failed to load job application data', 'error');
            console.error('Error loading job application:', error);
        }
    }

    // Computed property for time suggestions
    get timeSuggestions() {
        const suggestions = [];
        const now = new Date();
        
        // Generate suggestions for next 5 business days
        for (let i = 1; i <= 5; i++) {
            const date = new Date(now);
            date.setDate(date.getDate() + i);
            
            // Skip weekends
            if (date.getDay() === 0 || date.getDay() === 6) {
                continue;
            }
            
            // Morning slot (10:00 AM)
            const morningStart = new Date(date);
            morningStart.setHours(10, 0, 0, 0);
            const morningEnd = new Date(morningStart);
            morningEnd.setHours(11, 0, 0, 0);
            
            // Afternoon slot (2:00 PM)
            const afternoonStart = new Date(date);
            afternoonStart.setHours(14, 0, 0, 0);
            const afternoonEnd = new Date(afternoonStart);
            afternoonEnd.setHours(15, 0, 0, 0);
            
            suggestions.push({
                id: `morning-${i}`,
                label: `${this.formatDateShort(date)} 10:00 AM`,
                startDateTime: this.formatDateTimeLocal(morningStart),
                endDateTime: this.formatDateTimeLocal(morningEnd)
            });
            
            suggestions.push({
                id: `afternoon-${i}`,
                label: `${this.formatDateShort(date)} 2:00 PM`,
                startDateTime: this.formatDateTimeLocal(afternoonStart),
                endDateTime: this.formatDateTimeLocal(afternoonEnd)
            });
        }
        
        return suggestions.slice(0, 8); // Limit to 8 suggestions
    }

    // Event handlers
    handleSubjectChange(event) {
        this.eventSubject = event.target.value;
        this.clearValidationMessages();
    }

    handleStartDateTimeChange(event) {
        this.startDateTime = event.target.value;
        this.autoSetEndDateTime();
        this.clearValidationMessages();
    }

    handleEndDateTimeChange(event) {
        this.endDateTime = event.target.value;
        this.clearValidationMessages();
    }

    handleDescriptionChange(event) {
        this.description = event.target.value;
    }

    handleLocationChange(event) {
        this.location = event.target.value;
    }

    handleInterviewTypeChange(event) {
        this.interviewType = event.target.value;
        this.updateSubjectWithType();
    }

    handleTimeSuggestionClick(event) {
        const startDateTime = event.target.dataset.start;
        const endDateTime = event.target.dataset.end;
        
        this.startDateTime = startDateTime;
        this.endDateTime = endDateTime;
        this.clearValidationMessages();
    }

    handleCheckAvailability() {
        if (!this.validateBasicFields()) {
            return;
        }
        
        // Simulate availability check (in real implementation, this would query existing events)
        this.isProcessing = true;
        
        setTimeout(() => {
            this.performAvailabilityCheck();
            this.isProcessing = false;
        }, 1000);
    }

    handleClearForm() {
        this.eventSubject = this.jobApplicationData ? 
            `Interview - ${this.jobApplicationData.Position_Title__c} at ${this.jobApplicationData.Company_Name__c}` : '';
        this.startDateTime = '';
        this.endDateTime = '';
        this.description = '';
        this.location = '';
        this.interviewType = '';
        this.validationMessages = [];
        this.conflictCheckResults = [];
        this.showSuccessMessage = false;
    }

    async handleScheduleInterview() {
        if (!this.validateAllFields()) {
            return;
        }

        this.isProcessing = true;
        this.showSuccessMessage = false;

        try {
            // Prepare event record
            const eventRecord = {
                apiName: EVENT_OBJECT.objectApiName,
                fields: {
                    [SUBJECT_FIELD.fieldApiName]: this.eventSubject,
                    [START_DATETIME_FIELD.fieldApiName]: this.startDateTime,
                    [END_DATETIME_FIELD.fieldApiName]: this.endDateTime,
                    [DESCRIPTION_FIELD.fieldApiName]: this.buildEventDescription(),
                    [LOCATION_FIELD.fieldApiName]: this.location,
                    [WHAT_ID_FIELD.fieldApiName]: this.recordId
                }
            };

            // Create the event
            const result = await createRecord(eventRecord);
            
            this.showSuccessMessage = true;
            this.showToast('Success', 'Interview scheduled successfully!', 'success');
            
            // Clear form after successful creation
            setTimeout(() => {
                this.handleClearForm();
            }, 3000);

        } catch (error) {
            console.error('Error creating event:', error);
            
            // Parse validation errors from the server
            if (error.body && error.body.fieldErrors) {
                this.parseServerValidationErrors(error.body.fieldErrors);
            } else if (error.body && error.body.message) {
                this.addValidationMessage('error', error.body.message);
            } else {
                this.showToast('Error', 'Failed to schedule interview. Please try again.', 'error');
            }
        } finally {
            this.isProcessing = false;
        }
    }

    // Utility methods
    autoSetEndDateTime() {
        if (this.startDateTime) {
            const start = new Date(this.startDateTime);
            const end = new Date(start.getTime() + (60 * 60 * 1000)); // Add 1 hour
            this.endDateTime = this.formatDateTimeLocal(end);
        }
    }

    updateSubjectWithType() {
        if (this.interviewType && this.jobApplicationData) {
            const typeLabel = this.interviewTypeOptions.find(opt => opt.value === this.interviewType)?.label;
            this.eventSubject = `${typeLabel} - ${this.jobApplicationData.Position_Title__c} at ${this.jobApplicationData.Company_Name__c}`;
        }
    }

    buildEventDescription() {
        let description = this.description || '';
        
        if (this.jobApplicationData) {
            description += `\n\nJob Application Details:`;
            description += `\nCompany: ${this.jobApplicationData.Company_Name__c}`;
            description += `\nPosition: ${this.jobApplicationData.Position_Title__c}`;
            description += `\nStatus: ${this.jobApplicationData.Status__c}`;
        }
        
        if (this.interviewType) {
            const typeLabel = this.interviewTypeOptions.find(opt => opt.value === this.interviewType)?.label;
            description += `\nInterview Type: ${typeLabel}`;
        }
        
        return description.trim();
    }

    validateBasicFields() {
        this.clearValidationMessages();
        let isValid = true;

        if (!this.eventSubject) {
            this.addValidationMessage('error', 'Interview subject is required');
            isValid = false;
        }

        if (!this.startDateTime) {
            this.addValidationMessage('error', 'Start date and time is required');
            isValid = false;
        }

        if (!this.endDateTime) {
            this.addValidationMessage('error', 'End date and time is required');
            isValid = false;
        }

        return isValid;
    }

    validateAllFields() {
        if (!this.validateBasicFields()) {
            return false;
        }

        let isValid = true;
        const start = new Date(this.startDateTime);
        const end = new Date(this.endDateTime);

        // Validate end time is after start time
        if (end <= start) {
            this.addValidationMessage('error', 'End time must be after start time');
            isValid = false;
        }

        // Validate not in the past
        const now = new Date();
        if (start < now) {
            this.addValidationMessage('error', 'Cannot schedule interviews in the past');
            isValid = false;
        }

        // Validate business hours (8 AM - 6 PM)
        const startHour = start.getHours();
        const endHour = end.getHours();
        if (startHour < 8 || startHour >= 18 || endHour > 18) {
            this.addValidationMessage('warning', 'Interview is outside business hours (8 AM - 6 PM)');
        }

        // Validate weekends
        const dayOfWeek = start.getDay();
        if (dayOfWeek === 0 || dayOfWeek === 6) {
            this.addValidationMessage('warning', 'Interview is scheduled on a weekend');
        }

        return isValid;
    }

    performAvailabilityCheck() {
        // Simulate conflict detection (in real implementation, query existing events)
        this.conflictCheckResults = [];
        
        // For demo purposes, randomly show conflicts
        if (Math.random() > 0.7) {
            this.conflictCheckResults = [
                {
                    id: 'conflict1',
                    subject: 'Team Meeting',
                    startTime: '2:00 PM',
                    endTime: '3:00 PM'
                }
            ];
            this.addValidationMessage('warning', 'Potential scheduling conflicts detected');
        } else {
            this.addValidationMessage('success', 'No scheduling conflicts found');
        }
    }

    parseServerValidationErrors(fieldErrors) {
        Object.keys(fieldErrors).forEach(field => {
            fieldErrors[field].forEach(error => {
                this.addValidationMessage('error', error.message);
            });
        });
    }

    addValidationMessage(type, text) {
        const cssClass = `slds-notify slds-notify_alert slds-alert_${type}`;
        this.validationMessages.push({
            id: Date.now() + Math.random(),
            type: type.charAt(0).toUpperCase() + type.slice(1),
            text: text,
            cssClass: cssClass
        });
    }

    clearValidationMessages() {
        this.validationMessages = [];
        this.conflictCheckResults = [];
        this.showSuccessMessage = false;
    }

    formatDateTimeLocal(date) {
        const year = date.getFullYear();
        const month = String(date.getMonth() + 1).padStart(2, '0');
        const day = String(date.getDate()).padStart(2, '0');
        const hours = String(date.getHours()).padStart(2, '0');
        const minutes = String(date.getMinutes()).padStart(2, '0');
        
        return `${year}-${month}-${day}T${hours}:${minutes}`;
    }

    formatDateShort(date) {
        return date.toLocaleDateString('en-US', { 
            weekday: 'short', 
            month: 'short', 
            day: 'numeric' 
        });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title,
            message,
            variant
        }));
    }
}
