import { createElement } from 'lwc';
import { ShowToastEventName } from 'lightning/platformShowToastEvent';
import MobileFeedbackCapture from 'c/mobileFeedbackCapture';
import createInterviewFeedback from '@salesforce/apex/InterviewFeedbackService.createInterviewFeedback';
import getJobApplications from '@salesforce/apex/InterviewFeedbackService.getJobApplicationsForUser';
import uploadFeedbackAttachment from '@salesforce/apex/InterviewFeedbackService.uploadFeedbackAttachment';

// Mock Apex methods
jest.mock(
    '@salesforce/apex/InterviewFeedbackService.createInterviewFeedback',
    () => {
        return { default: jest.fn() };
    },
    { virtual: true }
);

jest.mock(
    '@salesforce/apex/InterviewFeedbackService.getJobApplicationsForUser',
    () => {
        const { createApexTestWireAdapter } = require('@salesforce/sfdx-lwc-jest');
        return {
            default: createApexTestWireAdapter(jest.fn())
        };
    },
    { virtual: true }
);

jest.mock(
    '@salesforce/apex/InterviewFeedbackService.uploadFeedbackAttachment',
    () => {
        return { default: jest.fn() };
    },
    { virtual: true }
);

// Mock UI API
jest.mock('lightning/uiObjectInfoApi', () => {
    const { createApexTestWireAdapter } = require('@salesforce/sfdx-lwc-jest');
    return {
        getObjectInfo: createApexTestWireAdapter(jest.fn()),
        getPicklistValues: createApexTestWireAdapter(jest.fn())
    };
}, { virtual: true });

// Mock user ID
jest.mock('@salesforce/user/Id', () => {
    return { default: 'mockUserId' };
}, { virtual: true });

// Mock MediaRecorder
global.MediaRecorder = jest.fn().mockImplementation(() => ({
    start: jest.fn(),
    stop: jest.fn(),
    ondataavailable: null,
    onstop: null
}));

// Mock getUserMedia
global.navigator.mediaDevices = {
    getUserMedia: jest.fn(() => Promise.resolve({
        getTracks: () => [{ stop: jest.fn() }]
    }))
};

// Mock geolocation
global.navigator.geolocation = {
    getCurrentPosition: jest.fn(),
    clearWatch: jest.fn()
};

// Mock vibrate
global.navigator.vibrate = jest.fn();

// Mock FileReader
global.FileReader = jest.fn().mockImplementation(() => ({
    readAsDataURL: jest.fn(),
    onload: null,
    result: 'data:image/jpeg;base64,mockbase64data'
}));

// Mock URL.createObjectURL
global.URL.createObjectURL = jest.fn(() => 'mock-url');

// Mock localStorage
const localStorageMock = {
    getItem: jest.fn(),
    setItem: jest.fn(),
    removeItem: jest.fn(),
    clear: jest.fn()
};
global.localStorage = localStorageMock;

describe('c-mobile-feedback-capture', () => {
    let element;

    // Mock data
    const mockJobApplications = [
        {
            Id: 'job1',
            Position_Title__c: 'Software Engineer',
            Company_Name__c: 'Tech Corp'
        },
        {
            Id: 'job2',
            Position_Title__c: 'Product Manager',
            Company_Name__c: 'Innovation Inc'
        }
    ];

    const mockInterviewTypes = {
        values: [
            { label: 'Technical', value: 'Technical' },
            { label: 'Behavioral', value: 'Behavioral' },
            { label: 'System Design', value: 'System Design' }
        ]
    };

    const mockObjectInfo = {
        defaultRecordTypeId: 'mockRecordTypeId'
    };

    beforeEach(() => {
        element = createElement('c-mobile-feedback-capture', {
            is: MobileFeedbackCapture
        });

        // Reset mocks
        jest.clearAllMocks();
        createInterviewFeedback.mockResolvedValue({ Id: 'feedback123' });
        uploadFeedbackAttachment.mockResolvedValue();
        localStorageMock.getItem.mockReturnValue(null);
    });

    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    describe('Component Initialization', () => {
        it('should render with default properties', () => {
            document.body.appendChild(element);

            expect(element.enableOfflineMode).toBe(true);
            expect(element.enableVoiceMemos).toBe(true);
            expect(element.enablePhotoAttachments).toBe(true);
            expect(element.enableLocationCapture).toBe(false);
            expect(element.maxPhotos).toBe(5);
            expect(element.maxVoiceMemoLength).toBe(300);
        });

        it('should start on basic step', () => {
            document.body.appendChild(element);

            expect(element.currentStep).toBe('basic');
            expect(element.isBasicStep).toBe(true);
        });

        it('should initialize competency ratings', () => {
            document.body.appendChild(element);

            expect(element.competencyRatings).toHaveLength(5);
            expect(element.competencyRatings[0].name).toBe('Technical Skills');
            expect(element.competencyRatings[0].rating).toBe(3);
        });

        it('should pre-fill job application if provided', () => {
            element.jobApplicationId = 'job1';
            document.body.appendChild(element);

            expect(element.selectedJobApplicationId).toBe('job1');
            expect(element.feedbackData.jobApplicationId).toBe('job1');
        });
    });

    describe('Step Navigation', () => {
        beforeEach(() => {
            document.body.appendChild(element);
            // Set required fields for navigation
            element.selectedJobApplicationId = 'job1';
            element.feedbackData.jobApplicationId = 'job1';
            element.feedbackData.interviewType = 'Technical';
            element.feedbackData.interviewDate = '2024-01-15T10:00';
        });

        it('should navigate to next step when requirements are met', async () => {
            const nextButton = element.shadowRoot.querySelector('lightning-button[label="Next"]');
            
            nextButton.click();
            await Promise.resolve();

            expect(element.currentStep).toBe('ratings');
            expect(element.isRatingsStep).toBe(true);
        });

        it('should navigate to previous step', async () => {
            // Go to ratings step first
            element.handleNext();
            await Promise.resolve();

            const prevButton = element.shadowRoot.querySelector('lightning-button[label="Previous"]');
            prevButton.click();
            await Promise.resolve();

            expect(element.currentStep).toBe('basic');
            expect(element.isBasicStep).toBe(true);
        });

        it('should disable next button when requirements not met', () => {
            element.selectedJobApplicationId = '';
            
            const nextButton = element.shadowRoot.querySelector('lightning-button[label="Next"]');
            expect(nextButton.disabled).toBe(true);
        });

        it('should show submit button on last step', async () => {
            // Navigate to last step
            element.currentStep = 'review';
            element.stepIndex = 3;
            await Promise.resolve();

            const submitButton = element.shadowRoot.querySelector('lightning-button[label*="Submit"]');
            expect(submitButton).toBeTruthy();
        });
    });

    describe('Form Input Handling', () => {
        beforeEach(() => {
            document.body.appendChild(element);
        });

        it('should handle job application selection', async () => {
            const combobox = element.shadowRoot.querySelector('lightning-combobox[name="jobApplication"]');
            
            combobox.dispatchEvent(new CustomEvent('change', {
                detail: { value: 'job1' }
            }));
            await Promise.resolve();

            expect(element.selectedJobApplicationId).toBe('job1');
            expect(element.feedbackData.jobApplicationId).toBe('job1');
        });

        it('should handle interview type selection', async () => {
            const radioGroup = element.shadowRoot.querySelector('lightning-radio-group[name="interviewType"]');
            
            radioGroup.dispatchEvent(new CustomEvent('change', {
                detail: { value: 'Technical' }
            }));
            await Promise.resolve();

            expect(element.feedbackData.interviewType).toBe('Technical');
        });

        it('should handle interview date change', async () => {
            const dateInput = element.shadowRoot.querySelector('lightning-input[name="interviewDate"]');
            
            dateInput.dispatchEvent(new CustomEvent('change', {
                detail: { value: '2024-01-15T10:00' }
            }));
            await Promise.resolve();

            expect(element.feedbackData.interviewDate).toBe('2024-01-15T10:00');
        });

        it('should handle quick notes input', async () => {
            const textarea = element.shadowRoot.querySelector('lightning-textarea[name="quickNotes"]');
            
            textarea.dispatchEvent(new CustomEvent('change', {
                detail: { value: 'Great interview experience' }
            }));
            await Promise.resolve();

            expect(element.feedbackData.quickNotes).toBe('Great interview experience');
        });
    });

    describe('Rating Sliders', () => {
        beforeEach(async () => {
            document.body.appendChild(element);
            element.currentStep = 'ratings';
            await Promise.resolve();
        });

        it('should handle overall rating change', async () => {
            const slider = element.shadowRoot.querySelector('.overall-slider');
            
            slider.value = '4.5';
            slider.dispatchEvent(new CustomEvent('change'));
            await Promise.resolve();

            expect(element.feedbackData.overallRating).toBe(4.5);
        });

        it('should handle competency rating change', async () => {
            const slider = element.shadowRoot.querySelector('.competency-slider');
            slider.dataset.competency = 'Technical Skills';
            slider.value = '4';
            
            slider.dispatchEvent(new CustomEvent('change'));
            await Promise.resolve();

            const techSkills = element.competencyRatings.find(c => c.name === 'Technical Skills');
            expect(techSkills.rating).toBe(4);
        });

        it('should provide haptic feedback on touch', async () => {
            const slider = element.shadowRoot.querySelector('.touch-slider');
            
            slider.dispatchEvent(new CustomEvent('touchmove'));
            await Promise.resolve();

            expect(navigator.vibrate).toHaveBeenCalledWith(10);
        });

        it('should toggle quick feedback buttons', async () => {
            const button = element.shadowRoot.querySelector('.quick-feedback-btn');
            button.dataset.value = 'technical_strong';
            
            button.click();
            await Promise.resolve();

            const option = element.quickFeedbackOptions.find(o => o.value === 'technical_strong');
            expect(option.selected).toBe('brand');
        });
    });

    describe('Voice Recording', () => {
        beforeEach(async () => {
            document.body.appendChild(element);
            element.currentStep = 'media';
            element.enableVoiceMemos = true;
            await Promise.resolve();
        });

        it('should start voice recording', async () => {
            const recordButton = element.shadowRoot.querySelector('lightning-button[label="Start Recording"]');
            
            recordButton.click();
            await Promise.resolve();

            expect(navigator.mediaDevices.getUserMedia).toHaveBeenCalledWith({ audio: true });
        });

        it('should handle recording permission denied', async () => {
            navigator.mediaDevices.getUserMedia.mockRejectedValue(new Error('Permission denied'));
            
            const recordButton = element.shadowRoot.querySelector('lightning-button[label="Start Recording"]');
            recordButton.click();
            await Promise.resolve();

            expect(element.showToast).toBe(true);
            expect(element.toastVariant).toBe('error');
        });

        it('should stop recording', async () => {
            element.isRecording = true;
            element.mediaRecorder = { stop: jest.fn() };
            await Promise.resolve();

            const stopButton = element.shadowRoot.querySelector('lightning-button[label="Stop"]');
            stopButton.click();
            await Promise.resolve();

            expect(element.mediaRecorder.stop).toHaveBeenCalled();
            expect(element.isRecording).toBe(false);
        });

        it('should cancel recording', async () => {
            element.isRecording = true;
            element.mediaRecorder = { stop: jest.fn() };
            await Promise.resolve();

            const cancelButton = element.shadowRoot.querySelector('lightning-button[label="Cancel"]');
            cancelButton.click();
            await Promise.resolve();

            expect(element.hasVoiceMemo).toBe(false);
            expect(element.voiceBlob).toBe(null);
        });

        it('should delete voice memo', async () => {
            element.hasVoiceMemo = true;
            element.voiceBlob = new Blob(['test'], { type: 'audio/wav' });
            await Promise.resolve();

            const deleteButton = element.shadowRoot.querySelector('.delete-button');
            deleteButton.click();
            await Promise.resolve();

            expect(element.hasVoiceMemo).toBe(false);
            expect(element.voiceBlob).toBe(null);
        });
    });

    describe('Photo Attachments', () => {
        beforeEach(async () => {
            document.body.appendChild(element);
            element.currentStep = 'media';
            element.enablePhotoAttachments = true;
            await Promise.resolve();
        });

        it('should trigger photo upload', async () => {
            const uploadButton = element.shadowRoot.querySelector('.photo-upload-btn');
            const mockInput = { click: jest.fn() };
            
            // Mock the ref query
            element.template.querySelector = jest.fn().mockReturnValue(mockInput);
            
            uploadButton.click();
            await Promise.resolve();

            expect(mockInput.click).toHaveBeenCalled();
        });

        it('should handle photo upload', async () => {
            const mockFile = new File(['test'], 'test.jpg', { type: 'image/jpeg' });
            const mockEvent = {
                target: {
                    files: [mockFile],
                    value: ''
                }
            };

            // Mock FileReader
            const mockReader = {
                onload: null,
                readAsDataURL: jest.fn(),
                result: 'data:image/jpeg;base64,mockdata'
            };
            global.FileReader.mockImplementation(() => mockReader);

            element.handlePhotoUpload(mockEvent);
            
            // Simulate FileReader onload
            mockReader.onload({ target: { result: 'data:image/jpeg;base64,mockdata' } });
            await Promise.resolve();

            expect(element.attachedPhotos).toHaveLength(1);
            expect(element.attachedPhotos[0].name).toBe('test.jpg');
        });

        it('should delete photo', async () => {
            element.attachedPhotos = [{ id: 123, name: 'test.jpg', url: 'mock-url' }];
            await Promise.resolve();

            const deleteButton = element.shadowRoot.querySelector('.delete-photo-btn');
            deleteButton.dataset.photoId = '123';
            
            deleteButton.click();
            await Promise.resolve();

            expect(element.attachedPhotos).toHaveLength(0);
        });

        it('should respect max photos limit', () => {
            element.maxPhotos = 2;
            element.attachedPhotos = [
                { id: 1, name: 'photo1.jpg' },
                { id: 2, name: 'photo2.jpg' }
            ];

            expect(element.canAddMorePhotos).toBe(false);
        });
    });

    describe('Location Capture', () => {
        beforeEach(async () => {
            document.body.appendChild(element);
            element.currentStep = 'media';
            element.enableLocationCapture = true;
            await Promise.resolve();
        });

        it('should capture location successfully', async () => {
            const mockPosition = {
                coords: {
                    latitude: 37.7749,
                    longitude: -122.4194,
                    accuracy: 10
                }
            };

            navigator.geolocation.getCurrentPosition.mockImplementation((success) => {
                success(mockPosition);
            });

            const locationButton = element.shadowRoot.querySelector('.location-btn');
            locationButton.click();
            await Promise.resolve();

            expect(element.hasLocation).toBe(true);
            expect(element.locationData.latitude).toBe('37.774900');
            expect(element.locationData.longitude).toBe('-122.419400');
        });

        it('should handle location permission denied', async () => {
            const mockError = { code: 1 }; // PERMISSION_DENIED
            
            navigator.geolocation.getCurrentPosition.mockImplementation((success, error) => {
                error(mockError);
            });

            const locationButton = element.shadowRoot.querySelector('.location-btn');
            locationButton.click();
            await Promise.resolve();

            expect(element.isCapturingLocation).toBe(false);
            expect(element.showToast).toBe(true);
            expect(element.toastMessage).toContain('Location access denied');
        });

        it('should clear location', async () => {
            element.hasLocation = true;
            element.locationData = { latitude: '37.7749', longitude: '-122.4194' };
            await Promise.resolve();

            const clearButton = element.shadowRoot.querySelector('.clear-location-btn');
            clearButton.click();
            await Promise.resolve();

            expect(element.hasLocation).toBe(false);
            expect(element.locationData).toEqual({});
        });
    });

    describe('Offline Functionality', () => {
        beforeEach(() => {
            document.body.appendChild(element);
        });

        it('should detect offline status', () => {
            Object.defineProperty(navigator, 'onLine', {
                writable: true,
                value: false
            });

            element.setupOfflineDetection();
            expect(element.isOffline).toBe(true);
        });

        it('should save feedback offline', async () => {
            element.isOffline = true;
            element.feedbackData = {
                jobApplicationId: 'job1',
                interviewType: 'Technical',
                overallRating: 4
            };

            await element.saveOffline(element.feedbackData);

            expect(element.offlineStorage).toHaveLength(1);
            expect(element.hasPendingSync).toBe(true);
            expect(localStorageMock.setItem).toHaveBeenCalled();
        });

        it('should sync offline data when online', async () => {
            element.offlineStorage = [{
                id: 123,
                data: { jobApplicationId: 'job1' },
                synced: false
            }];
            element.hasPendingSync = true;
            element.isOffline = false;

            await element.syncOfflineData();

            expect(createInterviewFeedback).toHaveBeenCalled();
            expect(element.offlineStorage[0].synced).toBe(true);
        });

        it('should load offline data from localStorage', () => {
            const mockData = JSON.stringify([{
                id: 123,
                data: { test: 'data' },
                synced: false
            }]);
            
            localStorageMock.getItem.mockReturnValue(mockData);
            
            element.loadOfflineData();

            expect(element.offlineStorage).toHaveLength(1);
            expect(element.hasPendingSync).toBe(true);
        });
    });

    describe('Form Submission', () => {
        beforeEach(async () => {
            document.body.appendChild(element);
            element.currentStep = 'review';
            element.feedbackData = {
                jobApplicationId: 'job1',
                interviewType: 'Technical',
                interviewDate: '2024-01-15T10:00',
                overallRating: 4,
                quickNotes: 'Great interview'
            };
        });

        it('should submit feedback online', async () => {
            element.isOffline = false;
            
            await element.handleSubmit();

            expect(createInterviewFeedback).toHaveBeenCalled();
            expect(element.showToast).toBe(true);
            expect(element.toastMessage).toContain('successfully');
        });

        it('should save feedback offline when offline', async () => {
            element.isOffline = true;
            
            await element.handleSubmit();

            expect(element.offlineStorage).toHaveLength(1);
            expect(element.hasPendingSync).toBe(true);
        });

        it('should upload attachments after creating feedback', async () => {
            element.attachedPhotos = [{
                id: 1,
                name: 'test.jpg',
                url: 'data:image/jpeg;base64,mockdata',
                file: { type: 'image/jpeg' }
            }];
            element.voiceBlob = new Blob(['test'], { type: 'audio/wav' });

            await element.handleSubmit();

            expect(uploadFeedbackAttachment).toHaveBeenCalledTimes(1); // Photo upload
        });

        it('should handle submission errors', async () => {
            createInterviewFeedback.mockRejectedValue(new Error('Network error'));
            
            await element.handleSubmit();

            expect(element.showToast).toBe(true);
            expect(element.toastVariant).toBe('error');
        });
    });

    describe('Toast Messages', () => {
        beforeEach(() => {
            document.body.appendChild(element);
        });

        it('should show toast message', () => {
            element.showToastMessage('Test message', 'success');

            expect(element.showToast).toBe(true);
            expect(element.toastMessage).toBe('Test message');
            expect(element.toastVariant).toBe('success');
        });

        it('should auto-hide toast after timeout', async () => {
            jest.useFakeTimers();
            
            element.showToastMessage('Test message');
            expect(element.showToast).toBe(true);

            jest.advanceTimersByTime(3000);
            expect(element.showToast).toBe(false);

            jest.useRealTimers();
        });

        it('should hide toast manually', () => {
            element.showToast = true;
            
            element.hideToast();
            
            expect(element.showToast).toBe(false);
        });
    });

    describe('Accessibility', () => {
        beforeEach(() => {
            document.body.appendChild(element);
        });

        it('should have proper ARIA labels', () => {
            const sliders = element.shadowRoot.querySelectorAll('.touch-slider');
            sliders.forEach(slider => {
                expect(slider.getAttribute('role')).toBeTruthy();
            });
        });

        it('should support keyboard navigation', () => {
            const buttons = element.shadowRoot.querySelectorAll('lightning-button');
            buttons.forEach(button => {
                expect(button.tabIndex).not.toBe(-1);
            });
        });

        it('should have proper form labels', () => {
            const inputs = element.shadowRoot.querySelectorAll('lightning-input, lightning-combobox, lightning-textarea');
            inputs.forEach(input => {
                const label = element.shadowRoot.querySelector(`label[for="${input.id}"]`);
                expect(label || input.label).toBeTruthy();
            });
        });
    });

    describe('Responsive Design', () => {
        beforeEach(() => {
            document.body.appendChild(element);
        });

        it('should adapt to mobile viewport', () => {
            const container = element.shadowRoot.querySelector('.mobile-feedback-container');
            expect(container).toBeTruthy();
            
            const styles = getComputedStyle(container);
            expect(styles.display).toBe('flex');
            expect(styles.flexDirection).toBe('column');
        });

        it('should have touch-friendly controls', () => {
            const sliders = element.shadowRoot.querySelectorAll('.touch-slider');
            sliders.forEach(slider => {
                const styles = getComputedStyle(slider);
                expect(parseInt(styles.height)).toBeGreaterThanOrEqual(44); // Minimum touch target
            });
        });
    });
});