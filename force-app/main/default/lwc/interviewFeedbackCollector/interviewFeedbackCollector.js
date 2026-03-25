import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import createFeedback from '@salesforce/apex/InterviewFeedbackService.createFeedback';
import getFeedbackTemplate from '@salesforce/apex/FeedbackTemplateService.getFeedbackTemplate';

// Job Application fields
import JOB_APPLICATION_OBJECT from '@salesforce/schema/Job_Application__c';
import POSITION_TITLE_FIELD from '@salesforce/schema/Job_Application__c.Position_Title__c';
import COMPANY_NAME_FIELD from '@salesforce/schema/Job_Application__c.Company_Name__c';

// Interview Feedback fields
import INTERVIEW_FEEDBACK_OBJECT from '@salesforce/schema/Interview_Feedback__c';
import JOB_APPLICATION_FIELD from '@salesforce/schema/Interview_Feedback__c.Job_Application__c';
import INTERVIEW_ROUND_FIELD from '@salesforce/schema/Interview_Feedback__c.Interview_Round__c';
import INTERVIEW_TYPE_FIELD from '@salesforce/schema/Interview_Feedback__c.Interview_Type__c';
import INTERVIEWER_NAME_FIELD from '@salesforce/schema/Interview_Feedback__c.Interviewer_Name__c';
import INTERVIEWER_EMAIL_FIELD from '@salesforce/schema/Interview_Feedback__c.Interviewer_Email__c';
import INTERVIEW_DATE_FIELD from '@salesforce/schema/Interview_Feedback__c.Interview_Date__c';
import DURATION_MINUTES_FIELD from '@salesforce/schema/Interview_Feedback__c.Duration_Minutes__c';
import TECHNICAL_RATING_FIELD from '@salesforce/schema/Interview_Feedback__c.Technical_Rating__c';
import COMMUNICATION_RATING_FIELD from '@salesforce/schema/Interview_Feedback__c.Communication_Rating__c';
import CULTURAL_FIT_RATING_FIELD from '@salesforce/schema/Interview_Feedback__c.Cultural_Fit_Rating__c';
import DETAILED_FEEDBACK_FIELD from '@salesforce/schema/Interview_Feedback__c.Detailed_Feedback__c';
import STRENGTHS_FIELD from '@salesforce/schema/Interview_Feedback__c.Strengths__c';
import AREAS_FOR_IMPROVEMENT_FIELD from '@salesforce/schema/Interview_Feedback__c.Areas_for_Improvement__c';
import RECOMMENDATION_FIELD from '@salesforce/schema/Interview_Feedback__c.Recommendation__c';
import IS_CONFIDENTIAL_FIELD from '@salesforce/schema/Interview_Feedback__c.Is_Confidential__c';
import FEEDBACK_STATUS_FIELD from '@salesforce/schema/Interview_Feedback__c.Feedback_Status__c';

const JOB_APPLICATION_FIELDS = [POSITION_TITLE_FIELD, COMPANY_NAME_FIELD];

export default class InterviewFeedbackCollector extends LightningElement {
    // Public properties
    @api jobApplicationId;
    @api interviewType;
    @api templateId;
    @api recordId; // For editing existing feedback

    // Tracked properties
    feedbackData = {};
    errors = [];
    isLoading = false;
    isSaving = false;
    showSuccessMessage = false;
    currentStep = 'basic';
    isOffline = false;
    isRecording = false;
    supportsVoiceInput = false;
    isMobile = false;

    // Step management
    steps = ['basic', 'ratings', 'feedback', 'review'];
    stepIndex = 0;

    // Voice recognition
    recognition = null;
    offlineData = [];

    // Wire to get Job Application data
    @wire(getRecord, { recordId: '$jobApplicationId', fields: JOB_APPLICATION_FIELDS })
    jobApplication;

    // Lifecycle hooks
    connectedCallback() {
        this.initializeComponent();
        this.setupOfflineHandling();
        this.checkMobileDevice();
        this.initializeVoiceInput();
        this.loadOfflineData();
    }

    disconnectedCallback() {
        this.cleanup();
    }

    // Getters
    get hasErrors() {
        return this.errors && this.errors.length > 0;
    }

    get showProgressIndicator() {
        return !this.isLoading && !this.recordId; // Only show for new records
    }

    get isBasicStep() {
        return this.currentStep === 'basic';
    }

    get isRatingsStep() {
        return this.currentStep === 'ratings';
    }

    get isFeedbackStep() {
        return this.currentStep === 'feedback';
    }

    get isReviewStep() {
        return this.currentStep === 'review';
    }

    get isFirstStep() {
        return this.stepIndex === 0;
    }

    get isLastStep() {
        return this.stepIndex === this.steps.length - 1;
    }

    get isCurrentStepValid() {
        switch (this.currentStep) {
            case 'basic':
                return this.feedbackData.Interview_Round__c && 
                       this.feedbackData.Interview_Type__c;
            case 'ratings':
                return this.feedbackData.Technical_Rating__c || 
                       this.feedbackData.Communication_Rating__c || 
                       this.feedbackData.Cultural_Fit_Rating__c;
            case 'feedback':
                return true; // Optional step
            case 'review':
                return true;
            default:
                return false;
        }
    }

    get isCurrentStepInvalid() {
        return !this.isCurrentStepValid;
    }

    get positionTitle() {
        return getFieldValue(this.jobApplication.data, POSITION_TITLE_FIELD);
    }

    get companyName() {
        return getFieldValue(this.jobApplication.data, COMPANY_NAME_FIELD);
    }

    // Initialization methods
    initializeComponent() {
        this.isLoading = true;
        
        // Initialize feedback data with default values
        this.feedbackData = {
            Job_Application__c: this.jobApplicationId,
            Interview_Type__c: this.interviewType || '',
            Interview_Round__c: '',
            Interviewer_Name__c: '',
            Interviewer_Email__c: '',
            Interview_Date__c: new Date().toISOString().split('T')[0],
            Duration_Minutes__c: 60,
            Technical_Rating__c: 3,
            Communication_Rating__c: 3,
            Cultural_Fit_Rating__c: 3,
            Detailed_Feedback__c: '',
            Strengths__c: '',
            Areas_for_Improvement__c: '',
            Recommendation__c: '',
            Is_Confidential__c: false,
            Feedback_Status__c: 'Draft'
        };

        // Load template if provided
        if (this.templateId) {
            this.loadFeedbackTemplate();
        } else {
            this.isLoading = false;
        }
    }

    setupOfflineHandling() {
        // Listen for online/offline events
        window.addEventListener('online', this.handleOnline.bind(this));
        window.addEventListener('offline', this.handleOffline.bind(this));
        
        // Check initial connection status
        this.isOffline = !navigator.onLine;
    }

    checkMobileDevice() {
        // Simple mobile detection
        this.isMobile = /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent) ||
                       window.innerWidth <= 768;
        
        // Listen for resize events
        window.addEventListener('resize', () => {
            this.isMobile = window.innerWidth <= 768;
        });
    }

    initializeVoiceInput() {
        // Check for Web Speech API support
        if ('webkitSpeechRecognition' in window || 'SpeechRecognition' in window) {
            this.supportsVoiceInput = true;
            const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
            this.recognition = new SpeechRecognition();
            
            this.recognition.continuous = false;
            this.recognition.interimResults = false;
            this.recognition.lang = 'en-US';
            
            this.recognition.onresult = (event) => {
                const transcript = event.results[0][0].transcript;
                this.handleVoiceResult(transcript);
            };
            
            this.recognition.onerror = (event) => {
                console.error('Speech recognition error:', event.error);
                this.isRecording = false;
                this.showToast('Error', 'Voice input failed. Please try again.', 'error');
            };
            
            this.recognition.onend = () => {
                this.isRecording = false;
            };
        }
    }

    loadOfflineData() {
        try {
            const stored = localStorage.getItem('interviewFeedbackOffline');
            if (stored) {
                this.offlineData = JSON.parse(stored);
            }
        } catch (error) {
            console.error('Error loading offline data:', error);
        }
    }

    cleanup() {
        window.removeEventListener('online', this.handleOnline.bind(this));
        window.removeEventListener('offline', this.handleOffline.bind(this));
        
        if (this.recognition) {
            this.recognition.abort();
        }
    }

    // Template loading
    async loadFeedbackTemplate() {
        try {
            const template = await getFeedbackTemplate({ templateId: this.templateId });
            if (template) {
                this.applyTemplate(template);
            }
        } catch (error) {
            console.error('Error loading template:', error);
            this.addError('Failed to load feedback template');
        } finally {
            this.isLoading = false;
        }
    }

    applyTemplate(template) {
        // Apply template configuration to form
        if (template.Interview_Type__c) {
            this.feedbackData.Interview_Type__c = template.Interview_Type__c;
        }
        
        // Parse template configuration if available
        if (template.Form_Configuration__c) {
            try {
                const config = JSON.parse(template.Form_Configuration__c);
                this.applyTemplateConfiguration(config);
            } catch (error) {
                console.error('Error parsing template configuration:', error);
            }
        }
    }

    applyTemplateConfiguration(config) {
        // Apply dynamic form configuration
        // This could include custom fields, validation rules, etc.
        if (config.defaultValues) {
            Object.assign(this.feedbackData, config.defaultValues);
        }
    }

    // Event handlers
    handleFieldChange(event) {
        const fieldName = event.target.dataset.field || event.target.fieldName;
        const value = event.target.value || event.detail.value;
        
        this.feedbackData = {
            ...this.feedbackData,
            [fieldName]: value
        };
        
        // Clear any existing errors for this field
        this.clearFieldError(fieldName);
        
        // Save to local storage for offline support
        this.saveToLocalStorage();
    }

    handleRatingChange(event) {
        const fieldName = event.target.dataset.field;
        const value = parseFloat(event.target.value);
        
        this.feedbackData = {
            ...this.feedbackData,
            [fieldName]: value
        };
        
        this.saveToLocalStorage();
    }

    handleNext() {
        if (this.isCurrentStepValid) {
            this.stepIndex = Math.min(this.stepIndex + 1, this.steps.length - 1);
            this.currentStep = this.steps[this.stepIndex];
        } else {
            this.showToast('Validation Error', 'Please complete all required fields before proceeding.', 'error');
        }
    }

    handlePrevious() {
        this.stepIndex = Math.max(this.stepIndex - 1, 0);
        this.currentStep = this.steps[this.stepIndex];
    }

    handleSubmit(event) {
        event.preventDefault();
        this.saveFeedback();
    }

    handleSuccess(event) {
        this.showSuccessMessage = true;
        this.clearLocalStorage();
        this.showToast('Success', 'Interview feedback saved successfully!', 'success');
        
        // Reset form after successful save
        setTimeout(() => {
            this.resetForm();
        }, 2000);
    }

    handleError(event) {
        console.error('Form submission error:', event.detail);
        this.addError('Failed to save feedback: ' + event.detail.message);
    }

    // Voice input handlers
    toggleVoiceInput() {
        if (!this.supportsVoiceInput) {
            this.showToast('Not Supported', 'Voice input is not supported in this browser.', 'warning');
            return;
        }
        
        if (this.isRecording) {
            this.recognition.stop();
        } else {
            this.startVoiceRecording();
        }
    }

    startVoiceRecording() {
        try {
            this.isRecording = true;
            this.recognition.start();
        } catch (error) {
            console.error('Error starting voice recognition:', error);
            this.isRecording = false;
            this.showToast('Error', 'Failed to start voice recording.', 'error');
        }
    }

    handleVoiceResult(transcript) {
        // Append voice input to detailed feedback
        const currentFeedback = this.feedbackData.Detailed_Feedback__c || '';
        const newFeedback = currentFeedback + (currentFeedback ? ' ' : '') + transcript;
        
        this.feedbackData = {
            ...this.feedbackData,
            Detailed_Feedback__c: newFeedback
        };
        
        this.saveToLocalStorage();
        this.showToast('Voice Input', 'Voice input added successfully!', 'success');
    }

    // Offline handling
    handleOnline() {
        this.isOffline = false;
        this.syncOfflineData();
    }

    handleOffline() {
        this.isOffline = true;
    }

    async syncOfflineData() {
        if (this.offlineData.length === 0) return;
        
        try {
            for (const data of this.offlineData) {
                await this.saveFeedbackToServer(data);
            }
            
            this.offlineData = [];
            this.clearLocalStorage();
            this.showToast('Sync Complete', 'Offline data has been synchronized.', 'success');
        } catch (error) {
            console.error('Error syncing offline data:', error);
            this.showToast('Sync Failed', 'Failed to sync offline data.', 'error');
        }
    }

    // Data persistence
    saveToLocalStorage() {
        try {
            localStorage.setItem('interviewFeedbackDraft', JSON.stringify(this.feedbackData));
        } catch (error) {
            console.error('Error saving to local storage:', error);
        }
    }

    clearLocalStorage() {
        try {
            localStorage.removeItem('interviewFeedbackDraft');
            localStorage.removeItem('interviewFeedbackOffline');
        } catch (error) {
            console.error('Error clearing local storage:', error);
        }
    }

    // Form submission
    async saveFeedback() {
        this.isSaving = true;
        this.clearErrors();
        
        try {
            if (this.isOffline) {
                this.saveOffline();
            } else {
                await this.saveFeedbackToServer(this.feedbackData);
                this.handleSuccess({ detail: { id: 'new-record' } });
            }
        } catch (error) {
            console.error('Error saving feedback:', error);
            this.addError('Failed to save feedback: ' + error.body?.message || error.message);
        } finally {
            this.isSaving = false;
        }
    }

    async saveFeedbackToServer(feedbackData) {
        const feedbackList = [feedbackData];
        return await createFeedback({ feedbackRecords: feedbackList });
    }

    saveOffline() {
        this.offlineData.push({
            ...this.feedbackData,
            timestamp: new Date().toISOString()
        });
        
        try {
            localStorage.setItem('interviewFeedbackOffline', JSON.stringify(this.offlineData));
            this.showToast('Saved Offline', 'Feedback saved offline. Will sync when connection is restored.', 'info');
            this.resetForm();
        } catch (error) {
            console.error('Error saving offline:', error);
            this.addError('Failed to save feedback offline');
        }
    }

    // Utility methods
    resetForm() {
        this.stepIndex = 0;
        this.currentStep = 'basic';
        this.showSuccessMessage = false;
        this.initializeComponent();
    }

    addError(message) {
        const error = {
            id: Date.now().toString(),
            message: message
        };
        this.errors = [...this.errors, error];
    }

    clearErrors() {
        this.errors = [];
    }

    clearFieldError(fieldName) {
        // Remove any field-specific errors
        this.errors = this.errors.filter(error => !error.field || error.field !== fieldName);
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

    // Validation methods
    validateCurrentStep() {
        const errors = [];
        
        switch (this.currentStep) {
            case 'basic':
                if (!this.feedbackData.Interview_Round__c) {
                    errors.push({ field: 'Interview_Round__c', message: 'Interview Round is required' });
                }
                if (!this.feedbackData.Interview_Type__c) {
                    errors.push({ field: 'Interview_Type__c', message: 'Interview Type is required' });
                }
                break;
            case 'ratings':
                // At least one rating should be provided
                if (!this.feedbackData.Technical_Rating__c && 
                    !this.feedbackData.Communication_Rating__c && 
                    !this.feedbackData.Cultural_Fit_Rating__c) {
                    errors.push({ message: 'Please provide at least one rating' });
                }
                break;
        }
        
        return errors;
    }

    // Accessibility methods
    announceStepChange() {
        const stepNames = {
            basic: 'Basic Information',
            ratings: 'Ratings',
            feedback: 'Detailed Feedback',
            review: 'Review'
        };
        
        const announcement = `Now on step ${this.stepIndex + 1} of ${this.steps.length}: ${stepNames[this.currentStep]}`;
        
        // Create a temporary element for screen reader announcement
        const announcement_element = document.createElement('div');
        announcement_element.setAttribute('aria-live', 'polite');
        announcement_element.setAttribute('aria-atomic', 'true');
        announcement_element.setAttribute('class', 'slds-assistive-text');
        announcement_element.textContent = announcement;
        
        document.body.appendChild(announcement_element);
        
        setTimeout(() => {
            document.body.removeChild(announcement_element);
        }, 1000);
    }
}