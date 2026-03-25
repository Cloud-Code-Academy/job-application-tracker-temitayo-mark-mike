import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { loadScript } from 'lightning/platformResourceLoader';
import { refreshApex } from '@salesforce/apex';
import { CurrentPageReference } from 'lightning/navigation';
import generateDashboardData from '@salesforce/apex/FeedbackAnalyticsService.generateDashboardData';
import generateRecommendations from '@salesforce/apex/FeedbackAnalyticsService.generateRecommendations';
import calculatePerformanceTrends from '@salesforce/apex/FeedbackAnalyticsService.calculatePerformanceTrends';
import CHARTJS from '@salesforce/resourceUrl/ChartJS';
import userId from '@salesforce/user/Id';

export default class PerformanceDashboard extends LightningElement {
    // Public Properties
    @api height = 600;
    @api showFilters = true;
    @api autoRefresh = false;
    @api defaultDateRange = '90';
    @api recordId; // Job Application ID when used on record page

    // Tracked Properties
    dashboardData = {};
    insights = [];
    recommendations = [];
    errors = [];
    isLoading = true;
    isOffline = false;
    selectedDateRange = '90';
    selectedInterviewType = '';

    // Private Properties
    chartJsInitialized = false;
    refreshInterval;
    charts = {};
    wiredDashboardResult;
    
    // Filter Options
    dateRangeOptions = [
        { label: 'Last 30 Days', value: '30' },
        { label: 'Last 60 Days', value: '60' },
        { label: 'Last 90 Days', value: '90' },
        { label: 'Last 6 Months', value: '180' },
        { label: 'Last Year', value: '365' },
        { label: 'All Time', value: 'all' }
    ];

    interviewTypeOptions = [
        { label: 'All Types', value: '' },
        { label: 'Technical', value: 'Technical' },
        { label: 'Behavioral', value: 'Behavioral' },
        { label: 'System Design', value: 'System Design' },
        { label: 'Cultural Fit', value: 'Cultural Fit' },
        { label: 'Final Round', value: 'Final Round' }
    ];

    // Wire Methods
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.selectedDateRange = currentPageReference.state?.dateRange || this.defaultDateRange;
            this.selectedInterviewType = currentPageReference.state?.interviewType || '';
        }
    }

    @wire(generateDashboardData, { 
        dateRange: '$selectedDateRange', 
        interviewType: '$selectedInterviewType',
        jobApplicationId: '$recordId'
    })
    wiredDashboard(result) {
        this.wiredDashboardResult = result;
        if (result.data) {
            this.dashboardData = result.data;
            this.processInsights();
            this.loadRecommendations();
            this.isLoading = false;
            this.renderCharts();
        } else if (result.error) {
            this.handleError('Failed to load dashboard data', result.error);
            this.isLoading = false;
        }
    }

    // Lifecycle Methods
    connectedCallback() {
        this.selectedDateRange = this.defaultDateRange;
        this.loadChartJs();
        this.setupAutoRefresh();
        this.checkOnlineStatus();
    }

    disconnectedCallback() {
        this.clearAutoRefresh();
        this.destroyCharts();
    }

    renderedCallback() {
        if (this.chartJsInitialized && this.dashboardData && Object.keys(this.dashboardData).length > 0) {
            this.renderCharts();
        }
    }

    // Computed Properties
    get chartHeight() {
        return `height: ${Math.floor(this.height * 0.4)}px;`;
    }

    get hasInsights() {
        return this.insights && this.insights.length > 0;
    }

    get hasRecommendations() {
        return this.recommendations && this.recommendations.length > 0;
    }

    get hasRecentActivity() {
        return this.dashboardData.recentFeedback && this.dashboardData.recentFeedback.length > 0;
    }

    get hasErrors() {
        return this.errors && this.errors.length > 0;
    }

    get ratingTrend() {
        if (!this.dashboardData.performanceTrend) {
            return { isPositive: false, isNegative: false, percentage: '0' };
        }
        
        const trend = this.dashboardData.performanceTrend;
        const percentage = Math.abs(trend.percentageChange || 0).toFixed(1);
        
        return {
            isPositive: trend.percentageChange > 0,
            isNegative: trend.percentageChange < 0,
            percentage: percentage
        };
    }

    // Event Handlers
    handleDateRangeChange(event) {
        this.selectedDateRange = event.detail.value;
        this.refreshDashboard();
    }

    handleInterviewTypeChange(event) {
        this.selectedInterviewType = event.detail.value;
        this.refreshDashboard();
    }

    handleRefresh() {
        this.isLoading = true;
        this.errors = [];
        this.refreshDashboard();
    }

    handleExport() {
        try {
            const exportData = this.prepareExportData();
            this.downloadCSV(exportData);
            this.showToast('Success', 'Dashboard data exported successfully', 'success');
        } catch (error) {
            this.handleError('Export failed', error);
        }
    }

    // Chart Methods
    async loadChartJs() {
        try {
            await loadScript(this, CHARTJS);
            this.chartJsInitialized = true;
            if (this.dashboardData && Object.keys(this.dashboardData).length > 0) {
                this.renderCharts();
            }
        } catch (error) {
            this.handleError('Failed to load Chart.js library', error);
        }
    }

    renderCharts() {
        if (!this.chartJsInitialized || !this.dashboardData) return;

        // Destroy existing charts
        this.destroyCharts();

        // Render all charts
        this.renderTrendChart();
        this.renderCompetencyChart();
        this.renderTypeChart();
        this.renderRatingChart();
    }

    renderTrendChart() {
        const canvas = this.template.querySelector('[lwc\\:ref="trendChart"]');
        if (!canvas || !this.dashboardData.performanceTrend) return;

        const ctx = canvas.getContext('2d');
        const trendData = this.dashboardData.performanceTrend.monthlyData || [];

        this.charts.trend = new Chart(ctx, {
            type: 'line',
            data: {
                labels: trendData.map(item => item.month),
                datasets: [{
                    label: 'Average Rating',
                    data: trendData.map(item => item.averageRating),
                    borderColor: '#1589ee',
                    backgroundColor: 'rgba(21, 137, 238, 0.1)',
                    borderWidth: 3,
                    fill: true,
                    tension: 0.4,
                    pointBackgroundColor: '#1589ee',
                    pointBorderColor: '#ffffff',
                    pointBorderWidth: 2,
                    pointRadius: 6
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        display: false
                    },
                    tooltip: {
                        backgroundColor: 'rgba(0, 0, 0, 0.8)',
                        titleColor: '#ffffff',
                        bodyColor: '#ffffff',
                        borderColor: '#1589ee',
                        borderWidth: 1
                    }
                },
                scales: {
                    y: {
                        beginAtZero: true,
                        max: 5,
                        grid: {
                            color: 'rgba(0, 0, 0, 0.1)'
                        },
                        ticks: {
                            stepSize: 1
                        }
                    },
                    x: {
                        grid: {
                            display: false
                        }
                    }
                }
            }
        });
    }

    renderCompetencyChart() {
        const canvas = this.template.querySelector('[lwc\\:ref="competencyChart"]');
        if (!canvas || !this.dashboardData.competencyBreakdown) return;

        const ctx = canvas.getContext('2d');
        const competencyData = this.dashboardData.competencyBreakdown;

        this.charts.competency = new Chart(ctx, {
            type: 'radar',
            data: {
                labels: competencyData.map(item => item.competency),
                datasets: [{
                    label: 'Average Rating',
                    data: competencyData.map(item => item.averageRating),
                    borderColor: '#04844b',
                    backgroundColor: 'rgba(4, 132, 75, 0.2)',
                    borderWidth: 2,
                    pointBackgroundColor: '#04844b',
                    pointBorderColor: '#ffffff',
                    pointBorderWidth: 2
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        display: false
                    }
                },
                scales: {
                    r: {
                        beginAtZero: true,
                        max: 5,
                        ticks: {
                            stepSize: 1
                        }
                    }
                }
            }
        });
    }

    renderTypeChart() {
        const canvas = this.template.querySelector('[lwc\\:ref="typeChart"]');
        if (!canvas || !this.dashboardData.interviewTypeDistribution) return;

        const ctx = canvas.getContext('2d');
        const typeData = this.dashboardData.interviewTypeDistribution;

        this.charts.type = new Chart(ctx, {
            type: 'doughnut',
            data: {
                labels: typeData.map(item => item.type),
                datasets: [{
                    data: typeData.map(item => item.count),
                    backgroundColor: [
                        '#1589ee',
                        '#04844b',
                        '#fe9339',
                        '#c23934',
                        '#706e6b',
                        '#8b5cf6'
                    ],
                    borderWidth: 2,
                    borderColor: '#ffffff'
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        position: 'bottom',
                        labels: {
                            padding: 20,
                            usePointStyle: true
                        }
                    }
                }
            }
        });
    }

    renderRatingChart() {
        const canvas = this.template.querySelector('[lwc\\:ref="ratingChart"]');
        if (!canvas || !this.dashboardData.ratingDistribution) return;

        const ctx = canvas.getContext('2d');
        const ratingData = this.dashboardData.ratingDistribution;

        this.charts.rating = new Chart(ctx, {
            type: 'bar',
            data: {
                labels: ratingData.map(item => `${item.rating} Stars`),
                datasets: [{
                    label: 'Count',
                    data: ratingData.map(item => item.count),
                    backgroundColor: '#1589ee',
                    borderColor: '#1589ee',
                    borderWidth: 1
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        display: false
                    }
                },
                scales: {
                    y: {
                        beginAtZero: true,
                        ticks: {
                            stepSize: 1
                        }
                    }
                }
            }
        });
    }

    destroyCharts() {
        Object.values(this.charts).forEach(chart => {
            if (chart) {
                chart.destroy();
            }
        });
        this.charts = {};
    }

    // Data Processing Methods
    processInsights() {
        if (!this.dashboardData) return;

        const insights = [];
        const data = this.dashboardData;

        // Performance insights
        if (data.averageOverallRating >= 4.0) {
            insights.push({
                id: 'high-performance',
                type: 'positive',
                badgeClass: 'insight-positive',
                message: `Excellent performance with ${data.averageOverallRating}/5 average rating`
            });
        } else if (data.averageOverallRating < 3.0) {
            insights.push({
                id: 'low-performance',
                type: 'warning',
                badgeClass: 'insight-warning',
                message: `Performance below average at ${data.averageOverallRating}/5 - focus on improvement areas`
            });
        }

        // Trend insights
        if (data.performanceTrend && data.performanceTrend.percentageChange > 10) {
            insights.push({
                id: 'positive-trend',
                type: 'positive',
                badgeClass: 'insight-positive',
                message: `Strong upward trend with ${data.performanceTrend.percentageChange.toFixed(1)}% improvement`
            });
        }

        // Activity insights
        if (data.totalFeedbackRecords < 5) {
            insights.push({
                id: 'low-activity',
                type: 'info',
                badgeClass: 'insight-info',
                message: 'Limited feedback data - consider conducting more interviews for better insights'
            });
        }

        this.insights = insights;
    }

    async loadRecommendations() {
        try {
            const result = await generateRecommendations({
                dateRange: this.selectedDateRange,
                interviewType: this.selectedInterviewType,
                jobApplicationId: this.recordId
            });
            
            this.recommendations = result.map((rec, index) => ({
                id: `rec-${index}`,
                message: rec.message,
                hasAction: rec.actionLabel && rec.actionLabel.length > 0,
                actionLabel: rec.actionLabel,
                actionHandler: () => this.handleRecommendationAction(rec)
            }));
        } catch (error) {
            console.error('Failed to load recommendations:', error);
        }
    }

    handleRecommendationAction(recommendation) {
        // Handle recommendation actions (e.g., navigate to specific records, create tasks, etc.)
        this.showToast('Info', `Action: ${recommendation.actionLabel}`, 'info');
    }

    // Utility Methods
    refreshDashboard() {
        return refreshApex(this.wiredDashboardResult);
    }

    setupAutoRefresh() {
        if (this.autoRefresh) {
            this.refreshInterval = setInterval(() => {
                this.refreshDashboard();
            }, 300000); // 5 minutes
        }
    }

    clearAutoRefresh() {
        if (this.refreshInterval) {
            clearInterval(this.refreshInterval);
            this.refreshInterval = null;
        }
    }

    checkOnlineStatus() {
        this.isOffline = !navigator.onLine;
        window.addEventListener('online', () => {
            this.isOffline = false;
            this.refreshDashboard();
        });
        window.addEventListener('offline', () => {
            this.isOffline = true;
        });
    }

    prepareExportData() {
        const data = [];
        
        // Add summary metrics
        data.push(['Metric', 'Value']);
        data.push(['Average Rating', this.dashboardData.averageOverallRating]);
        data.push(['Total Interviews', this.dashboardData.totalFeedbackRecords]);
        data.push(['Success Rate', `${this.dashboardData.successRate}%`]);
        data.push(['Applications with Feedback', this.dashboardData.totalApplicationsWithFeedback]);
        data.push(['']);

        // Add competency breakdown
        if (this.dashboardData.competencyBreakdown) {
            data.push(['Competency', 'Average Rating']);
            this.dashboardData.competencyBreakdown.forEach(comp => {
                data.push([comp.competency, comp.averageRating]);
            });
            data.push(['']);
        }

        // Add recent feedback
        if (this.dashboardData.recentFeedback) {
            data.push(['Date', 'Interview Type', 'Rating']);
            this.dashboardData.recentFeedback.forEach(feedback => {
                data.push([feedback.formattedDate, feedback.interviewType, feedback.rating]);
            });
        }

        return data;
    }

    downloadCSV(data) {
        const csv = data.map(row => row.join(',')).join('\n');
        const blob = new Blob([csv], { type: 'text/csv' });
        const url = window.URL.createObjectURL(blob);
        const link = document.createElement('a');
        link.href = url;
        link.download = `interview-performance-${new Date().toISOString().split('T')[0]}.csv`;
        link.click();
        window.URL.revokeObjectURL(url);
    }

    handleError(message, error) {
        console.error(message, error);
        this.errors.push({
            id: Date.now(),
            message: `${message}: ${error.body?.message || error.message || 'Unknown error'}`
        });
        this.showToast('Error', message, 'error');
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title,
            message,
            variant
        }));
    }
}