import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import getApplicationAnalytics from '@salesforce/apex/ApplicationAnalyticsService.getApplicationAnalytics';

export default class ApplicationAnalyticsDashboard extends NavigationMixin(LightningElement) {
    
    // Component state
    @track isLoading = false;
    @track errorMessage = '';
    @track analyticsData = {};
    
    // Wired data
    wiredAnalyticsResult;
    
    // Wire to get analytics data
    @wire(getApplicationAnalytics)
    wiredAnalytics(result) {
        this.wiredAnalyticsResult = result;
        if (result.data) {
            this.analyticsData = result.data;
            this.errorMessage = '';
        } else if (result.error) {
            this.errorMessage = 'Failed to load analytics data';
            console.error('Analytics error:', result.error);
        }
    }
    
    // Computed properties for metrics
    get totalApplications() {
        return this.analyticsData.totalApplications || 0;
    }
    
    get activeApplications() {
        return this.analyticsData.activeApplications || 0;
    }
    
    get interviewRate() {
        const rate = this.analyticsData.interviewRate || 0;
        return Math.round(rate * 10) / 10; // Round to 1 decimal place
    }
    
    get successRate() {
        const rate = this.analyticsData.successRate || 0;
        return Math.round(rate * 10) / 10;
    }
    
    get statusBreakdown() {
        const breakdown = this.analyticsData.statusBreakdown || [];
        const total = this.totalApplications;
        
        const colors = {
            'Applied': '#1589ee',
            'Interviewing': '#ff9500',
            'Negotiating': '#9333ea',
            'Accepted': '#10b981',
            'Closed': '#6b7280'
        };
        
        return breakdown.map(item => {
            const percentage = total > 0 ? (item.count / total) * 100 : 0;
            return {
                ...item,
                colorStyle: `background-color: ${colors[item.label] || '#6b7280'}`,
                fillStyle: `width: ${percentage}%; background-color: ${colors[item.label] || '#6b7280'}`
            };
        });
    }
    
    get recentActivity() {
        const activities = this.analyticsData.recentActivity || [];
        
        const iconMap = {
            'Applied': '📝',
            'Interviewing': '🎤',
            'Negotiating': '💼',
            'Accepted': '🎉',
            'Closed': '❌'
        };
        
        const colorMap = {
            'Applied': 'background-color: #e0f2fe',
            'Interviewing': 'background-color: #fff3e0',
            'Negotiating': 'background-color: #f3e8ff',
            'Accepted': 'background-color: #ecfdf5',
            'Closed': 'background-color: #f9fafb'
        };
        
        return activities.map(activity => ({
            ...activity,
            icon: iconMap[activity.status] || '📋',
            iconStyle: colorMap[activity.status] || 'background-color: #f9fafb',
            timeAgo: this.formatTimeAgo(activity.lastModified)
        }));
    }
    
    get pipelineStages() {
        const pipeline = this.analyticsData.pipeline || [];
        
        return pipeline.map(stage => ({
            ...stage,
            applications: stage.applications.map(app => ({
                ...app,
                dateFormatted: this.formatDate(app.applicationDate)
            }))
        }));
    }
    
    get averageSalary() {
        const avg = this.analyticsData.averageSalary || 0;
        return this.formatCurrency(avg);
    }
    
    get highestSalary() {
        const highest = this.analyticsData.highestSalary || 0;
        return this.formatCurrency(highest);
    }
    
    get salaryRange() {
        const min = this.analyticsData.minSalary || 0;
        const max = this.analyticsData.maxSalary || 0;
        
        if (min === 0 && max === 0) {
            return 'No data';
        }
        
        return `${this.formatCurrency(min)} - ${this.formatCurrency(max)}`;
    }
    
    get showEmptyState() {
        return this.totalApplications === 0 && !this.isLoading && !this.errorMessage;
    }
    
    // Event handlers
    handleApplicationClick(event) {
        const applicationId = event.currentTarget.dataset.id;
        
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: applicationId,
                objectApiName: 'Job_Application__c',
                actionName: 'view'
            }
        });
    }
    
    handleNewApplication() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Job_Application__c',
                actionName: 'new'
            }
        });
    }
    
    async handleRefresh() {
        this.isLoading = true;
        this.errorMessage = '';
        
        try {
            await refreshApex(this.wiredAnalyticsResult);
            this.showToast('Success', 'Analytics refreshed successfully', 'success');
        } catch (error) {
            this.errorMessage = 'Failed to refresh analytics';
            this.showToast('Error', 'Failed to refresh analytics', 'error');
            console.error('Refresh error:', error);
        } finally {
            this.isLoading = false;
        }
    }
    
    handleExportData() {
        // Create CSV data
        const csvData = this.generateCSVData();
        
        // Create and download file
        const blob = new Blob([csvData], { type: 'text/csv' });
        const url = window.URL.createObjectURL(blob);
        const link = document.createElement('a');
        link.href = url;
        link.download = `job-applications-${this.formatDateForFilename(new Date())}.csv`;
        link.click();
        window.URL.revokeObjectURL(url);
        
        this.showToast('Success', 'Analytics data exported successfully', 'success');
    }
    
    // Utility methods
    formatCurrency(amount) {
        if (!amount || amount === 0) {
            return '$0';
        }
        
        return new Intl.NumberFormat('en-US', {
            style: 'currency',
            currency: 'USD',
            minimumFractionDigits: 0,
            maximumFractionDigits: 0
        }).format(amount);
    }
    
    formatDate(dateString) {
        if (!dateString) return '';
        
        const date = new Date(dateString);
        return date.toLocaleDateString('en-US', {
            month: 'short',
            day: 'numeric'
        });
    }
    
    formatTimeAgo(dateString) {
        if (!dateString) return '';
        
        const date = new Date(dateString);
        const now = new Date();
        const diffInSeconds = Math.floor((now - date) / 1000);
        
        if (diffInSeconds < 60) {
            return 'Just now';
        } else if (diffInSeconds < 3600) {
            const minutes = Math.floor(diffInSeconds / 60);
            return `${minutes} minute${minutes > 1 ? 's' : ''} ago`;
        } else if (diffInSeconds < 86400) {
            const hours = Math.floor(diffInSeconds / 3600);
            return `${hours} hour${hours > 1 ? 's' : ''} ago`;
        } else {
            const days = Math.floor(diffInSeconds / 86400);
            return `${days} day${days > 1 ? 's' : ''} ago`;
        }
    }
    
    formatDateForFilename(date) {
        return date.toISOString().split('T')[0];
    }
    
    generateCSVData() {
        const headers = ['Company', 'Position', 'Status', 'Application Date', 'Salary'];
        const rows = [];
        
        // Add headers
        rows.push(headers.join(','));
        
        // Add data from pipeline
        this.pipelineStages.forEach(stage => {
            stage.applications.forEach(app => {
                const row = [
                    `"${app.company}"`,
                    `"${app.position}"`,
                    `"${stage.name}"`,
                    `"${app.applicationDate}"`,
                    `"${app.salary || 'N/A'}"`
                ];
                rows.push(row.join(','));
            });
        });
        
        return rows.join('\n');
    }
    
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title,
            message,
            variant
        }));
    }
    
    // Lifecycle hooks
    connectedCallback() {
        // Component initialization
        this.loadAnalytics();
    }
    
    async loadAnalytics() {
        this.isLoading = true;
        this.errorMessage = '';
        
        try {
            // Analytics will be loaded via wire adapter
            // This method can be used for additional initialization
        } catch (error) {
            this.errorMessage = 'Failed to initialize analytics';
            console.error('Initialization error:', error);
        } finally {
            this.isLoading = false;
        }
    }
}
