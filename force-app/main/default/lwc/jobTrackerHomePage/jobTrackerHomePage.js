import { LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getApplicationAnalytics from '@salesforce/apex/ApplicationAnalyticsService.getApplicationAnalytics';
import getExecutiveKPIs from '@salesforce/apex/ExecutiveReportingService.getExecutiveKPIs';
import Id from '@salesforce/user/Id';

export default class JobTrackerHomePage extends NavigationMixin(LightningElement) {
    userId = Id;
    isLoading = true;
    hasError = false;
    errorMessage = '';
    currentTime = '';
    greeting = '';

    // Analytics data
    totalApplications = 0;
    activeApplications = 0;
    interviewRate = 0;
    successRate = 0;
    averageSalary = 0;
    maxSalary = 0;
    statusBreakdown = [];
    recentActivity = [];
    pipeline = [];

    // KPI data
    kpiData = {};
    hasKpiData = false;

    // Animation counters
    _animatedTotal = 0;
    _animatedActive = 0;
    _animatedInterview = 0;
    _animatedSuccess = 0;

    // Quick action cards
    quickActions = [
        {
            id: 'new-app',
            title: 'New Application',
            description: 'Track a new job opportunity',
            icon: 'standard:opportunity',
            gradient: 'gradient-blue',
            action: 'newApplication'
        },
        {
            id: 'dashboard',
            title: 'Analytics Dashboard',
            description: 'Deep dive into your metrics',
            icon: 'standard:dashboard',
            gradient: 'gradient-purple',
            action: 'viewDashboard'
        },
        {
            id: 'calculator',
            title: 'Salary Calculator',
            description: 'Compare offers side by side',
            icon: 'standard:currency',
            gradient: 'gradient-green',
            action: 'salaryCalc'
        },
        {
            id: 'calendar',
            title: 'Interview Calendar',
            description: 'Upcoming interviews & prep',
            icon: 'standard:event',
            gradient: 'gradient-orange',
            action: 'viewCalendar'
        }
    ];

    connectedCallback() {
        this.updateGreeting();
        this._timeInterval = setInterval(() => this.updateGreeting(), 60000);
    }

    disconnectedCallback() {
        if (this._timeInterval) {
            clearInterval(this._timeInterval);
        }
    }

    updateGreeting() {
        const now = new Date();
        const hour = now.getHours();
        if (hour < 12) {
            this.greeting = 'Good Morning';
        } else if (hour < 17) {
            this.greeting = 'Good Afternoon';
        } else {
            this.greeting = 'Good Evening';
        }
        this.currentTime = now.toLocaleDateString('en-US', {
            weekday: 'long',
            year: 'numeric',
            month: 'long',
            day: 'numeric'
        });
    }

    @wire(getApplicationAnalytics)
    wiredAnalytics(result) {
        if (result.data) {
            this.totalApplications = result.data.totalApplications || 0;
            this.activeApplications = result.data.activeApplications || 0;
            this.interviewRate = result.data.interviewRate || 0;
            this.successRate = result.data.successRate || 0;
            this.averageSalary = result.data.averageSalary || 0;
            this.maxSalary = result.data.maxSalary || 0;
            this.statusBreakdown = this.processStatusBreakdown(result.data.statusBreakdown || []);
            this.recentActivity = this.processRecentActivity(result.data.recentActivity || []);
            this.pipeline = result.data.pipeline || [];
            this.isLoading = false;
            this.hasError = false;
            this.animateCounters();
        } else if (result.error) {
            this.isLoading = false;
            this.hasError = true;
            this.errorMessage = result.error.body?.message || 'Unable to load analytics data';
        }
    }

    @wire(getExecutiveKPIs)
    wiredKPIs(result) {
        if (result.data) {
            this.kpiData = result.data;
            this.hasKpiData = true;
        }
    }

    processStatusBreakdown(breakdown) {
        const colors = {
            'Saved': '#94a3b8',
            'Applied': '#3b82f6',
            'Applying': '#60a5fa',
            'Interviewing': '#f59e0b',
            'Negotiating': '#8b5cf6',
            'Accepted': '#10b981',
            'Rejected': '#ef4444',
            'Closed': '#6b7280',
            'Withdrawn': '#6b7280'
        };
        const total = breakdown.reduce((sum, item) => sum + (item.count || 0), 0);
        return breakdown.map(item => {
            const status = item.label || item.status || 'Unknown';
            return {
                ...item,
                status: status,
                color: colors[status] || '#64748b',
                percentage: total > 0 ? Math.round((item.count / total) * 100) : 0,
                barStyle: `width: ${total > 0 ? (item.count / total) * 100 : 0}%; background-color: ${colors[status] || '#64748b'};`
            };
        });
    }

    processRecentActivity(activity) {
        return activity.slice(0, 5).map((item, index) => ({
            ...item,
            key: `activity-${index}`,
            company: item.title || item.company || '',
            position: item.subtitle || item.position || '',
            timeAgo: this.getTimeAgo(item.lastModified || item.date),
            statusClass: `status-badge status-${(item.status || 'saved').toLowerCase()}`
        }));
    }

    getTimeAgo(dateStr) {
        if (!dateStr) return '';
        const date = new Date(dateStr);
        const now = new Date();
        const diffMs = now - date;
        const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24));
        if (diffDays === 0) return 'Today';
        if (diffDays === 1) return 'Yesterday';
        if (diffDays < 7) return `${diffDays} days ago`;
        if (diffDays < 30) return `${Math.floor(diffDays / 7)} weeks ago`;
        return `${Math.floor(diffDays / 30)} months ago`;
    }

    animateCounters() {
        const duration = 1200;
        const steps = 40;
        const interval = duration / steps;
        let step = 0;

        const targets = {
            total: this.totalApplications,
            active: this.activeApplications,
            interview: this.interviewRate,
            success: this.successRate
        };

        const timer = setInterval(() => {
            step++;
            const progress = this.easeOutCubic(step / steps);

            this._animatedTotal = Math.round(targets.total * progress);
            this._animatedActive = Math.round(targets.active * progress);
            this._animatedInterview = Math.round(targets.interview * progress * 10) / 10;
            this._animatedSuccess = Math.round(targets.success * progress * 10) / 10;

            if (step >= steps) {
                clearInterval(timer);
                this._animatedTotal = targets.total;
                this._animatedActive = targets.active;
                this._animatedInterview = targets.interview;
                this._animatedSuccess = targets.success;
            }
        }, interval);
    }

    easeOutCubic(t) {
        return 1 - Math.pow(1 - t, 3);
    }

    // Formatted display values
    get displayTotal() {
        return this._animatedTotal;
    }

    get displayActive() {
        return this._animatedActive;
    }

    get displayInterviewRate() {
        return `${this._animatedInterview}%`;
    }

    get displaySuccessRate() {
        return `${this._animatedSuccess}%`;
    }

    get formattedAvgSalary() {
        return this.averageSalary > 0
            ? `$${Math.round(this.averageSalary).toLocaleString()}`
            : '$—';
    }

    get formattedMaxSalary() {
        return this.maxSalary > 0
            ? `$${Math.round(this.maxSalary).toLocaleString()}`
            : '$—';
    }

    get hasStatusBreakdown() {
        return this.statusBreakdown.length > 0;
    }

    get hasRecentActivity() {
        return this.recentActivity.length > 0;
    }

    get hasPipeline() {
        return this.pipeline.length > 0;
    }

    get interviewRateCircleStyle() {
        const pct = this.interviewRate || 0;
        const deg = (pct / 100) * 360;
        return `background: conic-gradient(#3b82f6 ${deg}deg, #e2e8f0 ${deg}deg);`;
    }

    get successRateCircleStyle() {
        const pct = this.successRate || 0;
        const deg = (pct / 100) * 360;
        return `background: conic-gradient(#10b981 ${deg}deg, #e2e8f0 ${deg}deg);`;
    }

    // Navigation actions
    handleQuickAction(event) {
        const action = event.currentTarget.dataset.action;
        switch (action) {
            case 'newApplication':
                this.createNewApplication();
                break;
            case 'viewDashboard':
                this.navigateToTab('Job_Application_Analytics');
                break;
            case 'salaryCalc':
                this.navigateToTab('Salary_Calculator');
                break;
            case 'viewCalendar':
                this.navigateToTab('Calendar');
                break;
            default:
                break;
        }
    }

    handleKeyAction(event) {
        if (event.key === 'Enter' || event.key === ' ') {
            event.preventDefault();
            this.handleQuickAction(event);
        }
    }

    createNewApplication() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Job_Application__c',
                actionName: 'new'
            }
        });
    }

    navigateToTab(tabName) {
        this[NavigationMixin.Navigate]({
            type: 'standard__navItemPage',
            attributes: {
                apiName: tabName
            }
        });
    }

    navigateToListView() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Job_Application__c',
                actionName: 'list'
            }
        });
    }

    handleRetry() {
        this.isLoading = true;
        this.hasError = false;
    }
}
