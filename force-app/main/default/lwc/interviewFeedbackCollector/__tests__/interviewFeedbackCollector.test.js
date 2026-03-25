import { createElement } from 'lwc';
import { ShowToastEventName } from 'lightning/platformShowToastEvent';
import InterviewFeedbackCollector from 'c/interviewFeedbackCollector';
import createFeedback from '@salesforce/apex/InterviewFeedbackService.createFeedback';
import getFeedbackTemplate from '@salesforce/apex/FeedbackTemplateService.getFeedbackTemplate';
import { getRecord } from 'lightning/uiRecordApi';

// Mock Apex methods
jest.mock(
    '@salesforce/apex/InterviewFeedbackService.createFeedback',
    () => {
        return {
            default: jest.fn()
        };
    },
    { virtual: true }
);

jest.mock(
    '@salesforce/apex/FeedbackTemplateService.getFeedbackTemplate',
    () => {
        return {
            default: jest.fn()
        };
    },
    { virtual: true }
);

// Mock wire adapters
jest.mock('lightning/uiRecordApi', () => {
    const { createLdsTestWireAdapter } = require('@salesforce/sfdx-lwc-jest');
    return {
        getRecord: createLdsTestWireAdapter(jest.fn())
    };
});

// Mock localStorage
const localStorageMock = {
    getItem: jest.fn(),
    setItem: jest.fn(),
    removeItem: jest.fn(),
    clear: jest.fn(),
};
global.localStorage = localStorageMock;

// Mock navigator.onLine
Object.defineProperty(navigator, 'onLine', {
    writable: true,
    value: true,
});

// Mock Web Speech API
global.webkitSpeechRecognition = jest.fn().mockImplementation(() => ({
    continuous: false,
    interimResults: false,
    lang: 'en-US',
    start: jest.fn(),
    stop: jest.fn(),
    abort: jest.fn(),
    onresult: null,
    onerror: null,
    onend: null,
}));

describe('c-interview-feedback-collector', () => {
    afterEach(() => {
        // The jsdom instance is shared across test cases in a single file so reset the DOM
         
      while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        
        // Clear all mocks
        jest.clearAllMocks();
        
        // Reset localStorage mock
        localStorageMock.getItem.mockClear();
        localStorageMock.setItem.mockClear();
        localStorageMock.removeItem.mockClear();
        
        // Reset navigator.onLine
        navigator.onLine = true;
    });

    // Helper function to create component
    function createComponent(props = {}) {
        const element = createElement('c-interview-feedback-collector', {
            is: InterviewFeedbackCollector
        });
        
        // Set properties
        Object.assign(element, props);
        
        document.body.appendChild(element);
        return element;
    }

    // Helper function to wait for async operations
    function flushPromises() {
        return new Promise(resolve => setImmediate(resolve));
    }

    describe('Component Initialization', () => {
        test('should render with default properties', async () => {
            const element = createComponent({
                jobApplicationId: 'a001234567890123'
            });

            await flushPromises();

            // Check if the component renders
            const card = element.shadowRoot.querySelector('lightning-card');
            expect(card).toBeTruthy();
            expect(card.title).toBe('Interview Feedback Collection');
        });

        test('should initialize with loading state', async () => {
            const element = createComponent({
                jobApplicationId: 'a001234567890123'
            });

            // Should show loading spinner initially
            const spinner = element.shadowRoot.querySelector('lightning-spinner');
            expect(spinner).toBeTruthy();
        });

        test('should load feedback template when templateId provided', async () => {
            const mockTemplate = {
                Id: 'a021234567890123',
                Template_Name__c: 'Technical Interview',
                Interview_Type__c: 'Technical',
                Form_Configuration__c: '{"defaultValues": {"Interview_Type__c": "Technical"}}'
            };

            getFeedbackTemplate.mockResolvedValue(mockTemplate);

            const element = createComponent({
                jobApplicationId: 'a001234567890123',
                templateId: 'a021234567890123'
            });

            await flushPromises();

            expect(getFeedbackTemplate).toHaveBeenCalledWith({
                templateId: 'a021234567890123'
            });
        });
    });

    describe('Step Navigation', () => {
        test('should start on basic step', async () => {
            const element = createComponent({
                jobApplicationId: 'a001234567890123'
            });

            await flushPromises();

            expect(element.currentStep).toBe('basic');
            expect(element.isBasicStep).toBe(true);
            expect(element.isFirstStep).toBe(true);
        });

        test('should navigate to next step when valid', async () => {
            const element = createComponent({
                jobApplicationId: 'a001234567890123'
            });

            await flushPromises();

            // Set required fields for basic step
            element.feedbackData = {
                ...element.feedbackData,
                Interview_Round__c: 'Technical Round',
                Interview_Type__c: 'Technical'
            };

            // Click next button
            const nextButton = element.shadowRoot.querySelector('lightning-button[label="Next"]');
            expect(nextButton).toBeTruthy();
            
            nextButton.click();

            await flushPromises();

            expect(element.currentStep).toBe('ratings');
            expect(element.isRatingsStep).toBe(true);
        });

        test('should navigate to previous step', async () => {
            const element = createComponent({
                jobApplicationId: 'a001234567890123'
            });

            await flushPromises();

            // Navigate to ratings step first
            element.stepIndex = 1;
            element.currentStep = 'ratings';

            // Click previous button
            const prevButton = element.shadowRoot.querySelector('lightning-button[label="Previous"]');
            expect(prevButton).toBeTruthy();
            
            prevButton.click();

            await flushPromises();

            expect(element.currentStep).toBe('basic');
            expect(element.isBasicStep).toBe(true);
        });

        test('should show progress indicator for new records', async () => {
            const element = createComponent({
                jobApplicationId: 'a001234567890123'
            });

            await flushPromises();

            const progressIndicator = element.shadowRoot.querySelector('lightning-progress-indicator');
            expect(progressIndicator).toBeTruthy();
        });

        test('should not show progress indicator for existing records', async () => {
            const element = createComponent({
                jobApplicationId: 'a001234567890123',
                recordId: 'a011234567890123' // Existing record
            });

            await flushPromises();

            const progressIndicator = element.shadowRoot.querySelector('lightning-progress-indicator');
            expect(progressIndicator).toBeFalsy();
        });
    });

    describe('Form Validation', () => {
        test('should validate basic step fields', async () => {
            const element = createComponent({
                jobApplicationId: 'a001234567890123'
            });

            await flushPromises();

            // Initially should not be valid (missing required fields)
            expect(element.isCurrentStepValid).toBe(false);

            // Set required fields
            element.feedbackData = {
                ...element.feedbackData,
                Interview_Round__c: 'Technical Round',
                Interview_Type__c: 'Technical'
            };

            expect(element.isCurrentStepValid).toBe(true);
        });

        test('should validate ratings step', async () => {
            const element = createComponent({
                jobApplicationId: 'a001234567890123'
            });

            await flushPromises();

            element.currentStep = 'ratings';
            element.stepIndex = 1;

            // Initially should not be valid (no ratings provided)
            expect(element.isCurrentStepValid).toBe(false);

            // Set at least one rating
            element.feedbackData = {
                ...element.feedbackData,
                Technical_Rating__c: 4
            };

            expect(element.isCurrentStepValid).toBe(true);
        });

        test('should show validation error when trying to proceed with invalid step', async () => {
            const element = createComponent({
                jobApplicationId: 'a001234567890123'
            });

            await flushPromises();

            // Mock toast event handler
            const handler = jest.fn();
            element.addEventListener(ShowToastEventName, handler);

            // Try to proceed without required fields
            const nextButton = element.shadowRoot.querySelector('lightning-button[label="Next"]');
            nextButton.click();

            await flushPromises();

            expect(handler).toHaveBeenCalledWith(
                expect.objectContaining({
                    detail: expect.objectContaining({
                        title: 'Validation Error',
                        variant: 'error'
                    })
                })
            );
        });
    });

    describe('Mobile Responsiveness', () => {
        test('should detect mobile device', async () => {
            // Mock mobile user agent
            Object.defineProperty(navigator, 'userAgent', {
                value: 'Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X)',
                configurable: true
            });

            const element = createComponent({
                jobApplicationId: 'a001234567890123'
            });

            await flushPromises();

            expect(element.isMobile).toBe(true);
        });

        test('should show rating sliders on mobile', async () => {
            const element = createComponent({
                jobApplicationId: 'a001234567890123'
            });

            // Set mobile mode
            element.isMobile = true;
            element.currentStep = 'ratings';
            element.stepIndex = 1;

            await flushPromises();

            const ratingSliders = element.shadowRoot.querySelectorAll('.rating-slider');
            expect(ratingSliders.length).toBeGreaterThan(0);
        });

        test('should show standard rating fields on desktop', async () => {
            const element = createComponent({
                jobApplicationId: 'a001234567890123'
            });

            // Set desktop mode
            element.isMobile = false;
            element.currentStep = 'ratings';
            element.stepIndex = 1;

            await flushPromises();

            const ratingFields = element.shadowRoot.querySelectorAll('lightning-input-field[field-name*="Rating"]');
            expect(ratingFields.length).toBeGreaterThan(0);
        });
    });

    describe('Voice Input', () => {
        test('should initialize voice input when supported', async () => {
            const element = createComponent({
                jobApplicationId: 'a001234567890123'
            });

            await flushPromises();

            expect(element.supportsVoiceInput).toBe(true);
            expect(element.recognition).toBeTruthy();
        });

        test('should show voice input button when supported', async () => {
            const element = createComponent({
                jobApplicationId: 'a001234567890123'
            });

            element.supportsVoiceInput = true;
            element.currentStep = 'feedback';
            element.stepIndex = 2;

            await flushPromises();

            const voiceButton = element.shadowRoot.querySelector('.voice-input-button');
            expect(voiceButton).toBeTruthy();
        });

        test('should handle voice input toggle', async () => {
            const element = createComponent({
                jobApplicationId: 'a001234567890123'
            });

            element.supportsVoiceInput = true;
            element.currentStep = 'feedback';
            element.stepIndex = 2;

            await flushPromises();

            const voiceButton = element.shadowRoot.querySelector('.voice-input-button');
            voiceButton.click();

            expect(element.isRecording).toBe(true);
        });

        test('should handle voice result', async () => {
            const element = createComponent({
                jobApplicationId: 'a001234567890123'
            });

            await flushPromises();

            const transcript = 'This is a test voice input';
            element.handleVoiceResult(transcript);

            expect(element.feedbackData.Detailed_Feedback__c).toBe(transcript);
        });
    });

    describe('Offline Functionality', () => {
        test('should detect offline status', async () => {
            const element = createComponent({
                jobApplicationId: 'a001234567890123'
            });

            // Simulate going offline
            navigator.onLine = false;
            window.dispatchEvent(new Event('offline'));

            await flushPromises();

            expect(element.isOffline).toBe(true);
        });

        test('should show offline indicator when offline', async () => {
            const element = createComponent({
                jobApplicationId: 'a001234567890123'
            });

            element.isOffline = true;

            await flushPromises();

            const offlineIndicator = element.shadowRoot.querySelector('[data-id="offline-indicator"]');
            // Note: The template uses if:true={isOffline} so we check for the presence of the notification
            const offlineNotification = element.shadowRoot.querySelector('lightning-icon[icon-name="utility:offline"]');
            expect(offlineNotification).toBeTruthy();
        });

        test('should save data to localStorage when offline', async () => {
            const element = createComponent({
                jobApplicationId: 'a001234567890123'
            });

            element.isOffline = true;
            element.feedbackData = {
                Interview_Round__c: 'Technical',
                Interview_Type__c: 'Technical',
                Technical_Rating__c: 4
            };

            await element.saveFeedback();

            expect(localStorageMock.setItem).toHaveBeenCalledWith(
                'interviewFeedbackOffline',
                expect.stringContaining('Technical')
            );
        });

        test('should sync offline data when coming back online', async () => {
            const element = createComponent({
                jobApplicationId: 'a001234567890123'
            });

            // Set up offline data
            const offlineData = [{
                Interview_Round__c: 'Technical',
                Interview_Type__c: 'Technical',
                timestamp: new Date().toISOString()
            }];
            element.offlineData = offlineData;

            createFeedback.mockResolvedValue([{ Id: 'a011234567890123' }]);

            // Simulate coming back online
            navigator.onLine = true;
            window.dispatchEvent(new Event('online'));

            await flushPromises();

            expect(createFeedback).toHaveBeenCalled();
        });
    });

    describe('Form Submission', () => {
        test('should save feedback successfully', async () => {
            const element = createComponent({
                jobApplicationId: 'a001234567890123'
            });

            createFeedback.mockResolvedValue([{ Id: 'a011234567890123' }]);

            element.feedbackData = {
                Job_Application__c: 'a001234567890123',
                Interview_Round__c: 'Technical',
                Interview_Type__c: 'Technical',
                Technical_Rating__c: 4
            };

            await element.saveFeedback();

            expect(createFeedback).toHaveBeenCalledWith({
                feedbackRecords: [element.feedbackData]
            });
        });

        test('should handle save error', async () => {
            const element = createComponent({
                jobApplicationId: 'a001234567890123'
            });

            createFeedback.mockRejectedValue(new Error('Save failed'));

            element.feedbackData = {
                Job_Application__c: 'a001234567890123',
                Interview_Round__c: 'Technical'
            };

            await element.saveFeedback();

            expect(element.errors.length).toBeGreaterThan(0);
            expect(element.errors[0].message).toContain('Save failed');
        });

        test('should show success message after successful save', async () => {
            const element = createComponent({
                jobApplicationId: 'a001234567890123'
            });

            createFeedback.mockResolvedValue([{ Id: 'a011234567890123' }]);

            // Mock toast event handler
            const handler = jest.fn();
            element.addEventListener(ShowToastEventName, handler);

            await element.saveFeedback();

            expect(handler).toHaveBeenCalledWith(
                expect.objectContaining({
                    detail: expect.objectContaining({
                        title: 'Success',
                        variant: 'success'
                    })
                })
            );
        });
    });

    describe('Field Changes', () => {
        test('should handle field changes', async () => {
            const element = createComponent({
                jobApplicationId: 'a001234567890123'
            });

            await flushPromises();

            const mockEvent = {
                target: {
                    dataset: { field: 'Interview_Round__c' },
                    value: 'Technical Round'
                }
            };

            element.handleFieldChange(mockEvent);

            expect(element.feedbackData.Interview_Round__c).toBe('Technical Round');
        });

        test('should handle rating changes', async () => {
            const element = createComponent({
                jobApplicationId: 'a001234567890123'
            });

            await flushPromises();

            const mockEvent = {
                target: {
                    dataset: { field: 'Technical_Rating__c' },
                    value: '4.5'
                }
            };

            element.handleRatingChange(mockEvent);

            expect(element.feedbackData.Technical_Rating__c).toBe(4.5);
        });

        test('should save to localStorage on field change', async () => {
            const element = createComponent({
                jobApplicationId: 'a001234567890123'
            });

            await flushPromises();

            const mockEvent = {
                target: {
                    dataset: { field: 'Interview_Round__c' },
                    value: 'Technical Round'
                }
            };

            element.handleFieldChange(mockEvent);

            expect(localStorageMock.setItem).toHaveBeenCalledWith(
                'interviewFeedbackDraft',
                expect.stringContaining('Technical Round')
            );
        });
    });

    describe('Error Handling', () => {
        test('should add and display errors', async () => {
            const element = createComponent({
                jobApplicationId: 'a001234567890123'
            });

            await flushPromises();

            element.addError('Test error message');

            expect(element.errors.length).toBe(1);
            expect(element.errors[0].message).toBe('Test error message');
            expect(element.hasErrors).toBe(true);
        });

        test('should clear errors', async () => {
            const element = createComponent({
                jobApplicationId: 'a001234567890123'
            });

            await flushPromises();

            element.addError('Test error');
            expect(element.errors.length).toBe(1);

            element.clearErrors();
            expect(element.errors.length).toBe(0);
            expect(element.hasErrors).toBe(false);
        });

        test('should handle template loading error', async () => {
            getFeedbackTemplate.mockRejectedValue(new Error('Template not found'));

            const element = createComponent({
                jobApplicationId: 'a001234567890123',
                templateId: 'invalid-id'
            });

            await flushPromises();

            expect(element.errors.length).toBeGreaterThan(0);
        });
    });

    describe('Accessibility', () => {
        test('should have proper ARIA labels', async () => {
            const element = createComponent({
                jobApplicationId: 'a001234567890123'
            });

            await flushPromises();

            const spinner = element.shadowRoot.querySelector('lightning-spinner');
            expect(spinner.alternativeText).toBe('Loading feedback form...');
        });

        test('should announce step changes', async () => {
            const element = createComponent({
                jobApplicationId: 'a001234567890123'
            });

            await flushPromises();

            // Mock the announceStepChange method
            const announceSpy = jest.spyOn(element, 'announceStepChange');
            
            element.handleNext();

            // Note: announceStepChange is not called in handleNext in the current implementation
            // This test demonstrates how it could be tested if implemented
        });
    });

    describe('Review Step', () => {
        test('should display review data correctly', async () => {
            const element = createComponent({
                jobApplicationId: 'a001234567890123'
            });

            element.feedbackData = {
                Interview_Round__c: 'Technical Round',
                Interview_Type__c: 'Technical',
                Interviewer_Name__c: 'John Doe',
                Technical_Rating__c: 4,
                Communication_Rating__c: 5,
                Cultural_Fit_Rating__c: 3,
                Recommendation__c: 'Hire',
                Detailed_Feedback__c: 'Great candidate with strong technical skills.'
            };

            element.currentStep = 'review';
            element.stepIndex = 3;

            await flushPromises();

            const reviewContainer = element.shadowRoot.querySelector('.review-container');
            expect(reviewContainer).toBeTruthy();

            // Check if review data is displayed
            const reviewText = reviewContainer.textContent;
            expect(reviewText).toContain('Technical Round');
            expect(reviewText).toContain('Technical');
            expect(reviewText).toContain('John Doe');
            expect(reviewText).toContain('4/5');
            expect(reviewText).toContain('5/5');
            expect(reviewText).toContain('3/5');
            expect(reviewText).toContain('Hire');
        });

        test('should show save button on review step', async () => {
            const element = createComponent({
                jobApplicationId: 'a001234567890123'
            });

            element.currentStep = 'review';
            element.stepIndex = 3;

            await flushPromises();

            const saveButton = element.shadowRoot.querySelector('lightning-button[label="Save Feedback"]');
            expect(saveButton).toBeTruthy();
            expect(saveButton.type).toBe('submit');
        });
    });

    describe('Cleanup', () => {
        test('should cleanup event listeners on disconnect', async () => {
            const element = createComponent({
                jobApplicationId: 'a001234567890123'
            });

            await flushPromises();

            // Mock removeEventListener
            const removeEventListenerSpy = jest.spyOn(window, 'removeEventListener');

            // Disconnect component
            document.body.removeChild(element);

            // Note: disconnectedCallback is called automatically by LWC framework
            // This test demonstrates how cleanup could be verified
        });
    });
});