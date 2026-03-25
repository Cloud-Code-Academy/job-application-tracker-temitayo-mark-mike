import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getJobApplicationStats from '@salesforce/apex/ApplicationAnalyticsService.getJobApplicationStats';
import getRecentApplications from '@salesforce/apex/ApplicationAnalyticsService.getRecentApplications';

// Job Application fields for the current record
import COMPANY_NAME_FIELD from '@salesforce/schema/Job_Application__c.Company_Name__c';
import POSITION_TITLE_FIELD from '@salesforce/schema/Job_Application__c.Position_Title__c';
import STATUS_FIELD from '@salesforce/schema/Job_Application__c.Status__c';
import SALARY_FIELD from '@salesforce/schema/Job_Application__c.Salary__c';
import APPLICATION_DATE_FIELD from '@salesforce/schema/Job_Application__c.Application_Date__c';

const CURRENT_RECORD_FIELDS = [
    COMPANY_NAME_FIELD,
    POSITION_TITLE_FIELD,
    STATUS_FIELD,
    SALARY_FIELD,
    APPLICATION_DATE_FIELD
];

export default class JobApplicationDashboard extends LightningElement {
    @api recordId; // Current Job Application record ID
    
    // Component state
    isLoading = true;
    error = null;
    currentRecord = null;
    dashboardStats = null;
    recentApplications = [];
    selectedTimeframe = '30';
    showDetailedView = false;

    // Timeframe options for filtering
    timeframeOptions = [
        { label: 'Last 7 days', value: '7' },
        { label: 'Last 30 days', value: '30' },
        { label: 'Last 90 days', value: '90' },
        { label: 'All time', value: 'all' }
    ];

    // Status color mapping for visual indicators
    statusColorMap = {
        'Saved': 'slds-theme_info',
        'Applying': 'slds-theme_warning',
        'Applied': 'slds-theme_default',
        'Interviewing': 'slds-theme_success',
        'Negotiating': 'slds-theme_alt-inverse',
        'Accepted': 'slds-theme_success',
        'Closed': 'slds-theme_error'
    };

    // Wire to get current record data
    @wire(getRecord, { recordId: '$recordId', fields: CURRENT_RECORD_FIELDS })
    wiredCurrentRecord({ error, data }) {
        if (data) {
            this.currentRecord = {
                id: data.id,
                companyName: data.fields.Company_Name__c.value,
                positionTitle: data.fields.Position_Title__c.value,
                status: data.fields.Status__c.value,
                salary: data.fields.Salary__c.value,
                applicationDate: data.fields.Application_Date__c.value
            };
            this.error = null;
        } else if (error) {
            this.error = error;
            this.currentRecord = null;
            this.showToast('Error', 'Failed to load current record data', 'error');
        }
    }

    // Wire to get dashboard statistics
    @wire(getJobApplicationStats, { timeframeDays: '$selectedTimeframe' })
    wiredStats({ error, data }) {
        if (data) {
            this.dashboardStats = data;
            this.error = null;
            this.isLoading = false;
        } else if (error) {
            this.error = error;
            this.dashboardStats = null;
            this.isLoading = false;
            this.showToast('Error', 'Failed to load dashboard statistics', 'error');
        }
    }

    // Wire to get recent applications
    @wire(getRecentApplications, { limitCount: 5 })
    wiredRecentApplications({ error, data }) {
        if (data) {
            this.recentApplications = data.map(app => ({
                id: app.Id,
                name: app.Name,
                companyName: app.Company_Name__c,
                positionTitle: app.Position_Title__c,
                status: app.Status__c,
                salary: app.Salary__c,
                applicationDate: app.Application_Date__c,
                statusClass: this.getStatusClass(app.Status__c),
                formattedSalary: this.formatCurrency(app.Salary__c),
                formattedDate: this.formatDate(app.Application_Date__c)
            }));
            this.error = null;
        } else if (error) {
            this.error = error;
            this.recentApplications = [];
            this.showToast('Error', 'Failed to load recent applications', 'error');
        }
    }

    // Computed properties for dashboard metrics
    get totalApplications() {
        return this.dashboardStats?.totalApplications || 0;
    }

    get averageSalary() {
        return this.formatCurrency(this.dashboardStats?.averageSalary || 0);
    }

    get responseRate() {
        const total = this.dashboardStats?.totalApplications || 0;
        const responses = this.dashboardStats?.responsesReceived || 0;
        return total > 0 ? Math.round((responses / total) * 100) : 0;
    }

    get interviewRate() {
        const total = this.dashboardStats?.totalApplications || 0;
        const interviews = this.dashboardStats?.interviewsScheduled || 0;
        return total > 0 ? Math.round((interviews / total) * 100) : 0;
    }

    get statusBreakdown() {
        if (!this.dashboardStats?.statusBreakdown) return [];
        
        return Object.entries(this.dashboardStats.statusBreakdown).map(([status, count]) => ({
            status,
            count,
            percentage: this.totalApplications > 0 ? Math.round((count / this.totalApplications) * 100) : 0,
            cssClass: this.getStatusClass(status)
        }));
    }

    get topCompanies() {
        return this.dashboardStats?.topCompanies || [];
    }

    get salaryRange() {
        const stats = this.dashboardStats;
        if (!stats) return 'No data';
        
        const min = this.formatCurrency(stats.minSalary || 0);
        const max = this.formatCurrency(stats.maxSalary || 0);
        return `${min} - ${max}`;
    }

    get currentRecordSalary() {
        return this.formatCurrency(this.currentRecord?.salary || 0);
    }

    get currentRecordDate() {
        return this.formatDate(this.currentRecord?.applicationDate);
    }

    get currentRecordStatusClass() {
        return this.getStatusClass(this.currentRecord?.status);
    }

    get hasData() {
        return this.dashboardStats && this.totalApplications > 0;
    }

    get noDataMessage() {
        return this.selectedTimeframe === 'all' 
            ? 'No job applications found. Start by creating your first application!'
            : `No job applications found in the last ${this.selectedTimeframe} days. Try expanding your timeframe.`;
    }

    // Event handlers
    handleTimeframeChange(event) {
        this.selectedTimeframe = event.detail.value;
        this.isLoading = true;
    }

    handleToggleDetailedView() {
        this.showDetailedView = !this.showDetailedView;
    }

    handleRefresh() {
        this.isLoading = true;
        
        // Refresh all wired data
        return refreshApex(this.wiredStats)
            .then(() => refreshApex(this.wiredRecentApplications))
            .then(() => {
                this.showToast('Success', 'Dashboard data refreshed', 'success');
                this.isLoading = false;
            })
            .catch(error => {
                this.showToast('Error', 'Failed to refresh data', 'error');
                this.isLoading = false;
            });
    }

    handleApplicationClick(event) {
        const applicationId = event.currentTarget.dataset.id;
        
        // Navigate to the selected application record
        this.dispatchEvent(new CustomEvent('navigate', {
            detail: {
                type: 'standard__recordPage',
                attributes: {
                    recordId: applicationId,
                    objectApiName: 'Job_Application__c',
                    actionName: 'view'
                }
            }
        }));
    }

    // Keyboard accessibility — Enter/Space activates clickable list items
    handleApplicationKeydown(event) {
        if (event.key === 'Enter' || event.key === ' ') {
            event.preventDefault();
            this.handleApplicationClick(event);
        }
    }

    // Utility methods
    formatCurrency(amount) {
        if (!amount || amount === 0) return '$0';
        
        return new Intl.NumberFormat('en-US', {
            style: 'currency',
            currency: 'USD',
            minimumFractionDigits: 0,
            maximumFractionDigits: 0
        }).format(amount);
    }

    formatDate(dateValue) {
        if (!dateValue) return 'Not specified';
        
        const date = new Date(dateValue);
        return date.toLocaleDateString('en-US', {
            year: 'numeric',
            month: 'short',
            day: 'numeric'
        });
    }

    getStatusClass(status) {
        return this.statusColorMap[status] || 'slds-theme_default';
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title,
            message,
            variant
        }));
    }

    // Lifecycle methods
    connectedCallback() {
        // Component initialization
        this.isLoading = true;
    }

    disconnectedCallback() {
        // Cleanup if needed
    }

    errorCallback(error, stack) {
        console.error('Component error:', error, stack);
        this.showToast('Component Error', 'An unexpected error occurred', 'error');
    }
}