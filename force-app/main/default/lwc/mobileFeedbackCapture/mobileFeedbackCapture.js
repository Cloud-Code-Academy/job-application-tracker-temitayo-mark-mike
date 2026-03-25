import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { refreshApex } from '@salesforce/apex';
import createInterviewFeedback from '@salesforce/apex/InterviewFeedbackService.createInterviewFeedback';
import getJobApplications from '@salesforce/apex/InterviewFeedbackService.getJobApplicationsForUser';
import uploadFeedbackAttachment from '@salesforce/apex/InterviewFeedbackService.uploadFeedbackAttachment';
import INTERVIEW_FEEDBACK_OBJECT from '@salesforce/schema/Interview_Feedback__c';
import INTERVIEW_TYPE_FIELD from '@salesforce/schema/Interview_Feedback__c.Interview_Type__c';
import userId from '@salesforce/user/Id';

export default class MobileFeedbackCapture extends LightningElement {
    // Public Properties
    @api jobApplicationId;
    @api interviewType = '';
    @api enableOfflineMode = true;
    @api enableVoiceMemos = true;
    @api enablePhotoAttachments = true;
    @api enableLocationCapture = false;
    @api maxPhotos = 5;
    @api maxVoiceMemoLength = 300;

    // Tracked Properties
    currentStep = 'basic';
    feedbackData = {
        jobApplicationId: '',
        interviewType: '',
        interviewDate: '',
        overallRating: 3,
        quickNotes: '',
        strengths: '',
        improvements: '',
        additionalComments: ''
    };
    competencyRatings = [];
    attachedPhotos = [];
    locationData = {};
    selectedJobApplicationId = '';
    isLoading = false;
    isSubmitting = false;
    isRecording = false;
    isCapturingLocation = false;
    hasVoiceMemo = false;
    hasLocation = false;
    isOffline = false;
    hasPendingSync = false;
    showToast = false;
    toastMessage = '';
    toastVariant = 'info';
    recordingTime = '00:00';
    voiceMemoLength = 0;
    audioProgressStyle = 'width: 0%';
    loadingMessage = 'Saving feedback...';

    // Private Properties
    jobApplicationOptions = [];
    interviewTypeOptions = [];
    quickFeedbackOptions = [
        { label: 'Strong Technical Skills', value: 'technical_strong', selected: 'neutral' },
        { label: 'Good Communication', value: 'communication_good', selected: 'neutral' },
        { label: 'Problem Solving', value: 'problem_solving', selected: 'neutral' },
        { label: 'Cultural Fit', value: 'cultural_fit', selected: 'neutral' },
        { label: 'Leadership Potential', value: 'leadership', selected: 'neutral' },
        { label: 'Needs Improvement', value: 'needs_improvement', selected: 'neutral' }
    ];
    
    mediaRecorder;
    audioChunks = [];
    recordingInterval;
    recordingStartTime;
    voiceBlob;
    audioElement;
    offlineStorage = [];
    geolocationWatchId;
    
    steps = ['basic', 'ratings', 'media', 'review'];
    stepIndex = 0;

    // Wire Methods
    @wire(getObjectInfo, { objectApiName: INTERVIEW_FEEDBACK_OBJECT })
    objectInfo;

    @wire(getPicklistValues, {
        recordTypeId: '$objectInfo.data.defaultRecordTypeId',
        fieldApiName: INTERVIEW_TYPE_FIELD
    })
    wiredInterviewTypes({ error, data }) {
        if (data) {
            this.interviewTypeOptions = data.values.map(item => ({
                label: item.label,
                value: item.value
            }));
        } else if (error) {
            console.error('Error loading interview types:', error);
        }
    }

    @wire(getJobApplications, { userId: userId })
    wiredJobApplications({ error, data }) {
        if (data) {
            this.jobApplicationOptions = data.map(app => ({
                label: `${app.Position_Title__c} - ${app.Company_Name__c}`,
                value: app.Id
            }));
            
            // Pre-select if jobApplicationId is provided
            if (this.jobApplicationId) {
                this.selectedJobApplicationId = this.jobApplicationId;
                this.feedbackData.jobApplicationId = this.jobApplicationId;
            }
        } else if (error) {
            console.error('Error loading job applications:', error);
        }
    }

    // Lifecycle Methods
    connectedCallback() {
        this.initializeComponent();
        this.setupOfflineDetection();
        this.loadOfflineData();
        this.initializeCompetencyRatings();
        
        // Pre-fill interview type if provided
        if (this.interviewType) {
            this.feedbackData.interviewType = this.interviewType;
        }
        
        // Set default interview date to now
        this.feedbackData.interviewDate = new Date().toISOString().slice(0, 16);
    }

    disconnectedCallback() {
        this.cleanup();
    }

    // Computed Properties
    get isBasicStep() {
        return this.currentStep === 'basic';
    }

    get isRatingsStep() {
        return this.currentStep === 'ratings';
    }

    get isMediaStep() {
        return this.currentStep === 'media';
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

    get canProceedToNext() {
        switch (this.currentStep) {
            case 'basic':
                return this.selectedJobApplicationId && 
                       this.feedbackData.interviewType && 
                       this.feedbackData.interviewDate;
            case 'ratings':
                return this.feedbackData.overallRating > 0;
            case 'media':
                return true; // Media is optional
            case 'review':
                return true;
            default:
                return false;
        }
    }

    get canAddMorePhotos() {
        return this.attachedPhotos.length < this.maxPhotos;
    }

    get hasPhotos() {
        return this.attachedPhotos.length > 0;
    }

    get submitButtonLabel() {
        return this.isOffline ? 'Save Offline' : 'Submit Feedback';
    }

    get formattedInterviewDate() {
        if (!this.feedbackData.interviewDate) return '';
        return new Date(this.feedbackData.interviewDate).toLocaleString();
    }

    get overallRatingFillStyle() {
        const percentage = (this.feedbackData.overallRating / 5) * 100;
        return `width: ${percentage}%`;
    }

    get playButtonIcon() {
        return this.audioElement && !this.audioElement.paused ? 'utility:pause' : 'utility:play';
    }

    get toastIcon() {
        const iconMap = {
            success: 'utility:success',
            error: 'utility:error',
            warning: 'utility:warning',
            info: 'utility:info'
        };
        return iconMap[this.toastVariant] || 'utility:info';
    }

    get hasOfflineData() {
        return this.offlineStorage.length > 0;
    }

    get offlineDataCount() {
        return this.offlineStorage.length;
    }

    get locationEnabled() {
        return this.enableLocationCapture && this.hasLocation;
    }

    // Event Handlers
    handleJobApplicationChange(event) {
        this.selectedJobApplicationId = event.detail.value;
        this.feedbackData.jobApplicationId = event.detail.value;
    }

    handleInterviewTypeChange(event) {
        this.feedbackData.interviewType = event.detail.value;
    }

    handleInterviewDateChange(event) {
        this.feedbackData.interviewDate = event.detail.value;
    }

    handleQuickNotesChange(event) {
        this.feedbackData.quickNotes = event.detail.value;
    }

    handleOverallRatingChange(event) {
        this.feedbackData.overallRating = parseFloat(event.target.value);
        this.updateSliderFill(event.target);
    }

    handleCompetencyRatingChange(event) {
        const competencyName = event.target.dataset.competency;
        const rating = parseFloat(event.target.value);
        
        this.competencyRatings = this.competencyRatings.map(comp => {
            if (comp.name === competencyName) {
                return {
                    ...comp,
                    rating: rating,
                    fillStyle: `width: ${(rating / 5) * 100}%`
                };
            }
            return comp;
        });
        
        this.updateSliderFill(event.target);
    }

    handleSliderTouch(event) {
        // Provide haptic feedback on supported devices
        if (navigator.vibrate) {
            navigator.vibrate(10);
        }
        this.updateSliderFill(event.target);
    }

    handleSliderTouchEnd(event) {
        // Additional haptic feedback on release
        if (navigator.vibrate) {
            navigator.vibrate(20);
        }
    }

    handleQuickFeedbackToggle(event) {
        const value = event.target.dataset.value;
        
        this.quickFeedbackOptions = this.quickFeedbackOptions.map(option => {
            if (option.value === value) {
                const newSelected = option.selected === 'brand' ? 'neutral' : 'brand';
                return { ...option, selected: newSelected };
            }
            return option;
        });
    }

    // Navigation Methods
    handleNext() {
        if (this.canProceedToNext) {
            this.stepIndex = Math.min(this.stepIndex + 1, this.steps.length - 1);
            this.currentStep = this.steps[this.stepIndex];
            this.scrollToTop();
        }
    }

    handlePrevious() {
        this.stepIndex = Math.max(this.stepIndex - 1, 0);
        this.currentStep = this.steps[this.stepIndex];
        this.scrollToTop();
    }

    // Voice Recording Methods
    async startVoiceRecording() {
        try {
            const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
            this.mediaRecorder = new MediaRecorder(stream);
            this.audioChunks = [];
            
            this.mediaRecorder.ondataavailable = (event) => {
                this.audioChunks.push(event.data);
            };
            
            this.mediaRecorder.onstop = () => {
                this.voiceBlob = new Blob(this.audioChunks, { type: 'audio/wav' });
                this.hasVoiceMemo = true;
                this.voiceMemoLength = Math.floor((Date.now() - this.recordingStartTime) / 1000);
                stream.getTracks().forEach(track => track.stop());
            };
            
            this.mediaRecorder.start();
            this.isRecording = true;
            this.recordingStartTime = Date.now();
            this.startRecordingTimer();
            
            this.showToastMessage('Recording started', 'info');
            
        } catch (error) {
            console.error('Error starting recording:', error);
            this.showToastMessage('Could not start recording. Please check microphone permissions.', 'error');
        }
    }

    stopVoiceRecording() {
        if (this.mediaRecorder && this.isRecording) {
            this.mediaRecorder.stop();
            this.isRecording = false;
            this.stopRecordingTimer();
            this.showToastMessage('Recording saved', 'success');
        }
    }

    cancelVoiceRecording() {
        if (this.mediaRecorder && this.isRecording) {
            this.mediaRecorder.stop();
            this.isRecording = false;
            this.hasVoiceMemo = false;
            this.voiceBlob = null;
            this.stopRecordingTimer();
            this.showToastMessage('Recording cancelled', 'info');
        }
    }

    toggleVoicePlayback() {
        if (!this.audioElement && this.voiceBlob) {
            this.audioElement = new Audio(URL.createObjectURL(this.voiceBlob));
            this.audioElement.ontimeupdate = () => {
                const progress = (this.audioElement.currentTime / this.audioElement.duration) * 100;
                this.audioProgressStyle = `width: ${progress}%`;
            };
            this.audioElement.onended = () => {
                this.audioProgressStyle = 'width: 0%';
            };
        }
        
        if (this.audioElement) {
            if (this.audioElement.paused) {
                this.audioElement.play();
            } else {
                this.audioElement.pause();
            }
        }
    }

    deleteVoiceMemo() {
        this.hasVoiceMemo = false;
        this.voiceBlob = null;
        this.voiceMemoLength = 0;
        this.audioProgressStyle = 'width: 0%';
        
        if (this.audioElement) {
            this.audioElement.pause();
            this.audioElement = null;
        }
        
        this.showToastMessage('Voice memo deleted', 'info');
    }

    // Photo Methods
    triggerPhotoUpload() {
        const input = this.template.querySelector('[lwc\\:ref="photoInput"]');
        if (input) {
            input.click();
        }
    }

    handlePhotoUpload(event) {
        const files = Array.from(event.target.files);
        const remainingSlots = this.maxPhotos - this.attachedPhotos.length;
        const filesToProcess = files.slice(0, remainingSlots);
        
        filesToProcess.forEach((file, index) => {
            if (file.type.startsWith('image/')) {
                const reader = new FileReader();
                reader.onload = (e) => {
                    const photo = {
                        id: Date.now() + index,
                        name: file.name,
                        url: e.target.result,
                        file: file,
                        size: file.size
                    };
                    this.attachedPhotos = [...this.attachedPhotos, photo];
                };
                reader.readAsDataURL(file);
            }
        });
        
        if (filesToProcess.length > 0) {
            this.showToastMessage(`${filesToProcess.length} photo(s) added`, 'success');
        }
        
        // Reset input
        event.target.value = '';
    }

    deletePhoto(event) {
        const photoId = parseInt(event.target.dataset.photoId);
        this.attachedPhotos = this.attachedPhotos.filter(photo => photo.id !== photoId);
        this.showToastMessage('Photo removed', 'info');
    }

    // Location Methods
    async captureLocation() {
        if (!navigator.geolocation) {
            this.showToastMessage('Geolocation is not supported by this device', 'error');
            return;
        }
        
        this.isCapturingLocation = true;
        
        const options = {
            enableHighAccuracy: true,
            timeout: 10000,
            maximumAge: 60000
        };
        
        navigator.geolocation.getCurrentPosition(
            (position) => {
                this.locationData = {
                    latitude: position.coords.latitude.toFixed(6),
                    longitude: position.coords.longitude.toFixed(6),
                    accuracy: position.coords.accuracy,
                    timestamp: new Date().toISOString()
                };
                
                this.hasLocation = true;
                this.isCapturingLocation = false;
                this.reverseGeocode();
                this.showToastMessage('Location captured', 'success');
            },
            (error) => {
                console.error('Geolocation error:', error);
                this.isCapturingLocation = false;
                
                let message = 'Could not get location';
                switch (error.code) {
                    case error.PERMISSION_DENIED:
                        message = 'Location access denied. Please enable location permissions.';
                        break;
                    case error.POSITION_UNAVAILABLE:
                        message = 'Location information unavailable.';
                        break;
                    case error.TIMEOUT:
                        message = 'Location request timed out.';
                        break;
                }
                
                this.showToastMessage(message, 'error');
            },
            options
        );
    }

    async reverseGeocode() {
        // Simple reverse geocoding using a public API
        try {
            const response = await fetch(
                `https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=${this.locationData.latitude}&longitude=${this.locationData.longitude}&localityLanguage=en`
            );
            
            if (response.ok) {
                const data = await response.json();
                this.locationData.address = data.display_name || 
                    `${data.city || ''} ${data.principalSubdivision || ''} ${data.countryName || ''}`.trim();
            }
        } catch (error) {
            console.error('Reverse geocoding failed:', error);
            // Continue without address - coordinates are still captured
        }
    }

    clearLocation() {
        this.hasLocation = false;
        this.locationData = {};
        this.showToastMessage('Location cleared', 'info');
    }

    // Submit Methods
    async handleSubmit() {
        this.isSubmitting = true;
        this.loadingMessage = this.isOffline ? 'Saving offline...' : 'Submitting feedback...';
        
        try {
            const feedbackRecord = this.prepareFeedbackRecord();
            
            if (this.isOffline) {
                await this.saveOffline(feedbackRecord);
            } else {
                await this.submitOnline(feedbackRecord);
            }
            
        } catch (error) {
            console.error('Submit error:', error);
            this.showToastMessage('Failed to save feedback', 'error');
        } finally {
            this.isSubmitting = false;
        }
    }

    prepareFeedbackRecord() {
        const selectedQuickFeedback = this.quickFeedbackOptions
            .filter(option => option.selected === 'brand')
            .map(option => option.label);
        
        return {
            jobApplicationId: this.feedbackData.jobApplicationId,
            interviewType: this.feedbackData.interviewType,
            interviewDate: this.feedbackData.interviewDate,
            overallRating: this.feedbackData.overallRating,
            strengths: selectedQuickFeedback.join('; '),
            areasForImprovement: this.feedbackData.quickNotes,
            additionalComments: `Quick feedback: ${selectedQuickFeedback.join(', ')}`,
            competencyRatings: this.competencyRatings,
            attachments: {
                photos: this.attachedPhotos,
                voiceMemo: this.voiceBlob,
                location: this.hasLocation ? this.locationData : null
            }
        };
    }

    async submitOnline(feedbackRecord) {
        try {
            // Create the feedback record
            const result = await createInterviewFeedback({
                feedbackData: JSON.stringify(feedbackRecord)
            });
            
            // Upload attachments if any
            if (this.attachedPhotos.length > 0 || this.voiceBlob) {
                await this.uploadAttachments(result.Id);
            }
            
            this.showToastMessage('Feedback submitted successfully!', 'success');
            this.resetForm();
            
        } catch (error) {
            throw new Error(`Online submission failed: ${error.message}`);
        }
    }

    async saveOffline(feedbackRecord) {
        const offlineRecord = {
            id: Date.now(),
            timestamp: new Date().toISOString(),
            data: feedbackRecord,
            synced: false
        };
        
        this.offlineStorage.push(offlineRecord);
        this.saveToLocalStorage();
        this.hasPendingSync = true;
        
        this.showToastMessage('Feedback saved offline. Will sync when online.', 'success');
        this.resetForm();
    }

    async uploadAttachments(feedbackId) {
        const uploadPromises = [];
        
        // Upload photos
        for (const photo of this.attachedPhotos) {
            const base64Data = photo.url.split(',')[1];
            uploadPromises.push(
                uploadFeedbackAttachment({
                    feedbackId: feedbackId,
                    fileName: photo.name,
                    base64Data: base64Data,
                    contentType: photo.file.type
                })
            );
        }
        
        // Upload voice memo
        if (this.voiceBlob) {
            const reader = new FileReader();
            reader.onload = async () => {
                const base64Data = reader.result.split(',')[1];
                await uploadFeedbackAttachment({
                    feedbackId: feedbackId,
                    fileName: `voice_memo_${Date.now()}.wav`,
                    base64Data: base64Data,
                    contentType: 'audio/wav'
                });
            };
            reader.readAsDataURL(this.voiceBlob);
        }
        
        await Promise.all(uploadPromises);
    }

    // Utility Methods
    initializeComponent() {
        this.currentStep = this.steps[0];
        this.stepIndex = 0;
    }

    initializeCompetencyRatings() {
        this.competencyRatings = [
            { name: 'Technical Skills', rating: 3, fillStyle: 'width: 60%' },
            { name: 'Communication', rating: 3, fillStyle: 'width: 60%' },
            { name: 'Problem Solving', rating: 3, fillStyle: 'width: 60%' },
            { name: 'Cultural Fit', rating: 3, fillStyle: 'width: 60%' },
            { name: 'Leadership', rating: 3, fillStyle: 'width: 60%' }
        ];
    }

    setupOfflineDetection() {
        this.isOffline = !navigator.onLine;
        
        window.addEventListener('online', () => {
            this.isOffline = false;
            this.showToastMessage('Back online', 'success');
            this.syncOfflineData();
        });
        
        window.addEventListener('offline', () => {
            this.isOffline = true;
            this.showToastMessage('You are offline. Data will be saved locally.', 'warning');
        });
    }

    loadOfflineData() {
        try {
            const stored = localStorage.getItem('mobileFeedbackOffline');
            if (stored) {
                this.offlineStorage = JSON.parse(stored);
                this.hasPendingSync = this.offlineStorage.some(record => !record.synced);
            }
        } catch (error) {
            console.error('Error loading offline data:', error);
        }
    }

    saveToLocalStorage() {
        try {
            localStorage.setItem('mobileFeedbackOffline', JSON.stringify(this.offlineStorage));
        } catch (error) {
            console.error('Error saving to localStorage:', error);
        }
    }

    async syncOfflineData() {
        if (!this.hasPendingSync || this.isOffline) return;
        
        const unsyncedRecords = this.offlineStorage.filter(record => !record.synced);
        
        for (const record of unsyncedRecords) {
            try {
                await this.submitOnline(record.data);
                record.synced = true;
            } catch (error) {
                console.error('Sync failed for record:', record.id, error);
                break; // Stop syncing on first failure
            }
        }
        
        this.saveToLocalStorage();
        this.hasPendingSync = this.offlineStorage.some(record => !record.synced);
        
        if (!this.hasPendingSync) {
            this.showToastMessage('All offline data synced successfully', 'success');
        }
    }

    updateSliderFill(slider) {
        const value = parseFloat(slider.value);
        const percentage = (value / 5) * 100;
        const track = slider.nextElementSibling?.querySelector('.slider-fill');
        if (track) {
            track.style.width = `${percentage}%`;
        }
    }

    startRecordingTimer() {
        this.recordingInterval = setInterval(() => {
            const elapsed = Math.floor((Date.now() - this.recordingStartTime) / 1000);
            const minutes = Math.floor(elapsed / 60).toString().padStart(2, '0');
            const seconds = (elapsed % 60).toString().padStart(2, '0');
            this.recordingTime = `${minutes}:${seconds}`;
            
            // Auto-stop at max length
            if (elapsed >= this.maxVoiceMemoLength) {
                this.stopVoiceRecording();
            }
        }, 1000);
    }

    stopRecordingTimer() {
        if (this.recordingInterval) {
            clearInterval(this.recordingInterval);
            this.recordingInterval = null;
        }
    }

    scrollToTop() {
        const content = this.template.querySelector('.mobile-content');
        if (content) {
            content.scrollTop = 0;
        }
    }

    resetForm() {
        this.feedbackData = {
            jobApplicationId: '',
            interviewType: '',
            interviewDate: new Date().toISOString().slice(0, 16),
            overallRating: 3,
            quickNotes: '',
            strengths: '',
            improvements: '',
            additionalComments: ''
        };
        
        this.initializeCompetencyRatings();
        this.attachedPhotos = [];
        this.hasVoiceMemo = false;
        this.voiceBlob = null;
        this.hasLocation = false;
        this.locationData = {};
        this.selectedJobApplicationId = '';
        
        this.quickFeedbackOptions = this.quickFeedbackOptions.map(option => ({
            ...option,
            selected: 'neutral'
        }));
        
        this.currentStep = 'basic';
        this.stepIndex = 0;
    }

    showToastMessage(message, variant = 'info') {
        this.toastMessage = message;
        this.toastVariant = variant;
        this.showToast = true;
        
        // Auto-hide after 3 seconds
        setTimeout(() => {
            this.hideToast();
        }, 3000);
    }

    hideToast() {
        this.showToast = false;
    }

    cleanup() {
        this.stopRecordingTimer();
        
        if (this.mediaRecorder && this.isRecording) {
            this.mediaRecorder.stop();
        }
        
        if (this.audioElement) {
            this.audioElement.pause();
            this.audioElement = null;
        }
        
        if (this.geolocationWatchId) {
            navigator.geolocation.clearWatch(this.geolocationWatchId);
        }
    }
}