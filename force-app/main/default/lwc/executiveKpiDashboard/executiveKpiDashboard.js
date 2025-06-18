import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import getExecutiveKPIs from '@salesforce/apex/ExecutiveReportingService.getExecutiveKPIs';
import getMonthlyPerformanceReport from '@salesforce/apex/ExecutiveReportingService.getMonthlyPerformanceReport';
import getQuarterlyBusinessReview from '@salesforce/apex/ExecutiveReportingService.getQuarterlyBusinessReview';

export default class ExecutiveKpiDashboard extends NavigationMixin(LightningElement) {
    
    // Component state
    @track isLoading = false;
    @track errorMessage = '';
    @track kpiData = {};
    @track selectedTimePeriod = 'current';
    
    // Wired data
    wiredKPIResult;
    
    // Time period options
    timePeriodOptions = [
        { label: 'Current Period', value: 'current' },
        { label: 'Last 30 Days', value: 'last30' },
        { label: 'Last Quarter', value: 'lastQuarter' },
        { label: 'Year to Date', value: 'ytd' },
        { label: 'Custom Range', value: 'custom' }
    ];
    
    // Wire to get KPI data
    @wire(getExecutiveKPIs)
    wiredKPIs(result) {
        this.wiredKPIResult = result;
        if (result.data) {
            this.kpiData = result.data;
            this.errorMessage = '';
            this.processKPIData();
        } else if (result.error) {
            this.errorMessage = 'Failed to load KPI data';
            console.error('KPI error:', result.error);
        }
    }
    
    // Computed properties for KPI metrics
    get thisWeekApplications() {
        return this.kpiData.thisWeekApplications || 0;
    }
    
    get weekOverWeekGrowth() {
        const growth = this.kpiData.weekOverWeekGrowth || 0;
        return Math.abs(growth).toFixed(1);
    }
    
    get weekOverWeekTrend() {
        const growth = this.kpiData.weekOverWeekGrowth || 0;
        return growth >= 0 ? 'positive' : 'negative';
    }
    
    get interviewingCount() {
        return this.kpiData.interviewingCount || 0;
    }
    
    get applicationToInterview() {
        const rate = this.kpiData.applicationToInterview || 0;
        return rate.toFixed(1);
    }
    
    get acceptedCount() {
        return this.kpiData.acceptedCount || 0;
    }
    
    get overallSuccessRate() {
        const rate = this.kpiData.overallSuccessRate || 0;
        return rate.toFixed(1);
    }
    
    get averageResponseTime() {
        const time = this.kpiData.averageResponseTime || 0;
        return time.toFixed(1);
    }
    
    get formattedAppsPerWeek() {
        const apps = this.kpiData.applicationsPerWeek || 0;
        return apps.toFixed(1);
    }
    
    get applicationsPerDay() {
        const apps = this.kpiData.applicationsPerDay || 0;
        return apps.toFixed(1);
    }
    
    // Conversion funnel computed properties
    get appliedCount() {
        return this.kpiData.appliedCount || 0;
    }
    
    get negotiatingCount() {
        return this.kpiData.negotiatingCount || 0;
    }
    
    get interviewToNegotiation() {
        const rate = this.kpiData.interviewToNegotiation || 0;
        return rate.toFixed(1);
    }
    
    get negotiationToAcceptance() {
        const rate = this.kpiData.negotiationToAcceptance || 0;
        return rate.toFixed(1);
    }
    
    // Funnel bar styles
    get appliedBarStyle() {
        return 'width: 100%; background-color: #3b82f6;';
    }
    
    get interviewingBarStyle() {
        const percentage = this.calculateFunnelPercentage(this.interviewingCount, this.appliedCount);
        return `width: ${percentage}%; background-color: #f59e0b;`;
    }
    
    get negotiatingBarStyle() {
        const percentage = this.calculateFunnelPercentage(this.negotiatingCount, this.appliedCount);
        return `width: ${percentage}%; background-color: #8b5cf6;`;
    }
    
    get acceptedBarStyle() {
        const percentage = this.calculateFunnelPercentage(this.acceptedCount, this.appliedCount);
        return `width: ${percentage}%; background-color: #10b981;`;
    }
    
    // Market insights computed properties
    get topCompanies() {
        const companies = this.kpiData.topCompanies || [];
        return this.processInsightData(companies);
    }
    
    get topPositions() {
        const positions = this.kpiData.topPositions || [];
        return this.processInsightData(positions);
    }
    
    get marketDiversification() {
        return this.kpiData.marketDiversification || 0;
    }
    
    get positionDiversification() {
        return this.kpiData.positionDiversification || 0;
    }
    
    // Forecasting computed properties
    get projectedMonthlyApplications() {
        const projected = this.kpiData.projectedMonthlyApplications || 0;
        return Math.round(projected);
    }
    
    get projectedQuarterlyApplications() {
        const projected = this.kpiData.projectedQuarterlyApplications || 0;
        return Math.round(projected);
    }
    
    get projectedMonthlyOffers() {
        const projected = this.kpiData.projectedMonthlyOffers || 0;
        return Math.round(projected * 10) / 10; // Round to 1 decimal
    }
    
    // Performance indicators
    get responseRateIndicator() {
        const rate = parseFloat(this.applicationToInterview);
        if (rate >= 30) return 'good';
        if (rate >= 15) return 'neutral';
        return 'poor';
    }
    
    get responseRateText() {
        const rate = parseFloat(this.applicationToInterview);
        if (rate >= 30) return 'Excellent';
        if (rate >= 15) return 'Good';
        return 'Needs Improvement';
    }
    
    get showEmptyState() {
        return this.thisWeekApplications === 0 && !this.isLoading && !this.errorMessage;
    }
    
    // Event handlers
    handleTimePeriodChange(event) {
        this.selectedTimePeriod = event.detail.value;
        this.loadKPIData();
    }
    
    async handleGenerateReport() {
        this.isLoading = true;
        
        try {
            let reportData;
            const currentDate = new Date();
            
            switch (this.selectedTimePeriod) {
                case 'lastQuarter':
                    const quarter = Math.floor((currentDate.getMonth()) / 3) + 1;
                    reportData = await getQuarterlyBusinessReview({ 
                        year: currentDate.getFullYear(), 
                        quarter: quarter 
                    });
                    this.generateQuarterlyReport(reportData);
                    break;
                    
                case 'last30':
                    reportData = await getMonthlyPerformanceReport({ 
                        year: currentDate.getFullYear(), 
                        month: currentDate.getMonth() + 1 
                    });
                    this.generateMonthlyReport(reportData);
                    break;
                    
                default:
                    await refreshApex(this.wiredKPIResult);
                    this.showToast('Success', 'Dashboard refreshed successfully', 'success');
            }
            
        } catch (error) {
            this.errorMessage = 'Failed to generate report';
            this.showToast('Error', 'Failed to generate report', 'error');
            console.error('Report generation error:', error);
        } finally {
            this.isLoading = false;
        }
    }
    
    handleExportDashboard() {
        const dashboardData = this.generateExportData();
        const csvContent = this.convertToCSV(dashboardData);
        
        const blob = new Blob([csvContent], { type: 'text/csv' });
        const url = window.URL.createObjectURL(blob);
        const link = document.createElement('a');
        link.href = url;
        link.download = `executive-dashboard-${this.formatDateForFilename(new Date())}.csv`;
        link.click();
        window.URL.revokeObjectURL(url);
        
        this.showToast('Success', 'Dashboard data exported successfully', 'success');
    }
    
    handleAddApplications() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Job_Application__c',
                actionName: 'new'
            }
        });
    }
    
    // Utility methods
    processKPIData() {
        // Additional processing of KPI data if needed
        console.log('KPI Data processed:', this.kpiData);
    }
    
    calculateFunnelPercentage(current, total) {
        if (total === 0) return 0;
        return Math.round((current / total) * 100);
    }
    
    processInsightData(insights) {
        if (!insights || insights.length === 0) return [];
        
        const maxCount = Math.max(...insights.map(item => item.count));
        
        return insights.map(item => ({
            ...item,
            fillStyle: `width: ${(item.count / maxCount) * 100}%; background-color: #3b82f6;`
        }));
    }
    
    async loadKPIData() {
        this.isLoading = true;
        this.errorMessage = '';
        
        try {
            await refreshApex(this.wiredKPIResult);
        } catch (error) {
            this.errorMessage = 'Failed to load KPI data';
            console.error('KPI loading error:', error);
        } finally {
            this.isLoading = false;
        }
    }
    
    generateQuarterlyReport(data) {
        // Process quarterly report data
        console.log('Quarterly Report:', data);
        this.showToast('Success', 'Quarterly report generated', 'success');
    }
    
    generateMonthlyReport(data) {
        // Process monthly report data
        console.log('Monthly Report:', data);
        this.showToast('Success', 'Monthly report generated', 'success');
    }
    
    generateExportData() {
        return {
            kpis: [
                { metric: 'This Week Applications', value: this.thisWeekApplications },
                { metric: 'Week over Week Growth', value: this.weekOverWeekGrowth + '%' },
                { metric: 'Interview Conversion Rate', value: this.applicationToInterview + '%' },
                { metric: 'Overall Success Rate', value: this.overallSuccessRate + '%' },
                { metric: 'Average Response Time', value: this.averageResponseTime + ' days' },
                { metric: 'Weekly Velocity', value: this.formattedAppsPerWeek }
            ],
            funnel: [
                { stage: 'Applied', count: this.appliedCount },
                { stage: 'Interviewing', count: this.interviewingCount },
                { stage: 'Negotiating', count: this.negotiatingCount },
                { stage: 'Accepted', count: this.acceptedCount }
            ],
            forecasting: [
                { metric: 'Projected Monthly Applications', value: this.projectedMonthlyApplications },
                { metric: 'Projected Quarterly Applications', value: this.projectedQuarterlyApplications },
                { metric: 'Projected Monthly Offers', value: this.projectedMonthlyOffers }
            ]
        };
    }
    
    convertToCSV(data) {
        let csv = 'Executive Dashboard Export\n\n';
        
        // KPIs section
        csv += 'Key Performance Indicators\n';
        csv += 'Metric,Value\n';
        data.kpis.forEach(kpi => {
            csv += `"${kpi.metric}","${kpi.value}"\n`;
        });
        
        csv += '\nConversion Funnel\n';
        csv += 'Stage,Count\n';
        data.funnel.forEach(stage => {
            csv += `"${stage.stage}","${stage.count}"\n`;
        });
        
        csv += '\nForecasting\n';
        csv += 'Metric,Value\n';
        data.forecasting.forEach(forecast => {
            csv += `"${forecast.metric}","${forecast.value}"\n`;
        });
        
        return csv;
    }
    
    formatDateForFilename(date) {
        return date.toISOString().split('T')[0];
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
        this.loadKPIData();
    }
}
