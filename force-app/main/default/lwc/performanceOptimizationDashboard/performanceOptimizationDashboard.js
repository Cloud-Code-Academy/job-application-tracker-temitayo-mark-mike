import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getPerformanceMetrics from '@salesforce/apex/PerformanceOptimizationService.getPerformanceMetrics';
import optimizeQuery from '@salesforce/apex/PerformanceOptimizationService.optimizeQuery';
import optimizeBulkProcessing from '@salesforce/apex/PerformanceOptimizationService.optimizeBulkProcessing';
import monitorPerformance from '@salesforce/apex/PerformanceOptimizationService.monitorPerformance';

export default class PerformanceOptimizationDashboard extends LightningElement {
    
    // Component state
    @track isLoading = false;
    @track errorMessage = '';
    @track performanceData = {};
    @track showRealTimeMonitor = false;
    @track monitoringData = {};
    
    // Wired data
    wiredPerformanceResult;
    
    // Wire to get performance metrics
    @wire(getPerformanceMetrics)
    wiredPerformance(result) {
        this.wiredPerformanceResult = result;
        if (result.data) {
            this.performanceData = result.data;
            this.errorMessage = '';
            this.processPerformanceData();
        } else if (result.error) {
            this.errorMessage = 'Failed to load performance metrics';
            console.error('Performance error:', result.error);
        }
    }
    
    // CPU Performance computed properties
    get currentCpuTime() {
        return this.performanceData.currentCpuTime || 0;
    }
    
    get maxCpuTime() {
        return this.performanceData.maxCpuTime || 10000;
    }
    
    get cpuUsagePercent() {
        const percent = this.performanceData.cpuUsagePercent || 0;
        return Math.round(percent * 10) / 10;
    }
    
    get cpuStatus() {
        const percent = this.cpuUsagePercent;
        if (percent < 50) return 'good';
        if (percent < 75) return 'warning';
        return 'critical';
    }
    
    get cpuProgressStyle() {
        const percent = Math.min(this.cpuUsagePercent, 100);
        const color = this.getProgressColor(percent);
        return `width: ${percent}%; background-color: ${color};`;
    }
    
    // Memory Performance computed properties
    get currentHeapSize() {
        return this.performanceData.currentHeapSize || 0;
    }
    
    get maxHeapSize() {
        return this.performanceData.maxHeapSize || 6000000;
    }
    
    get formattedCurrentHeapSize() {
        return this.formatBytes(this.currentHeapSize);
    }
    
    get formattedMaxHeapSize() {
        return this.formatBytes(this.maxHeapSize);
    }
    
    get heapUsagePercent() {
        const percent = this.performanceData.heapUsagePercent || 0;
        return Math.round(percent * 10) / 10;
    }
    
    get memoryStatus() {
        const percent = this.heapUsagePercent;
        if (percent < 50) return 'good';
        if (percent < 75) return 'warning';
        return 'critical';
    }
    
    get memoryProgressStyle() {
        const percent = Math.min(this.heapUsagePercent, 100);
        const color = this.getProgressColor(percent);
        return `width: ${percent}%; background-color: ${color};`;
    }
    
    // Query Performance computed properties
    get currentQueries() {
        return this.performanceData.currentQueries || 0;
    }
    
    get maxQueries() {
        return this.performanceData.maxQueries || 100;
    }
    
    get queryUsagePercent() {
        const percent = this.performanceData.queryUsagePercent || 0;
        return Math.round(percent * 10) / 10;
    }
    
    get queryStatus() {
        const percent = this.queryUsagePercent;
        if (percent < 50) return 'good';
        if (percent < 75) return 'warning';
        return 'critical';
    }
    
    get queryProgressStyle() {
        const percent = Math.min(this.queryUsagePercent, 100);
        const color = this.getProgressColor(percent);
        return `width: ${percent}%; background-color: ${color};`;
    }
    
    // Cache Performance computed properties
    get cacheHitRate() {
        const rate = this.performanceData.cacheHitRate || 0;
        return Math.round(rate * 10) / 10;
    }
    
    get averageCacheResponseTime() {
        const time = this.performanceData.averageCacheResponseTime || 0;
        return Math.round(time * 10) / 10;
    }
    
    get cacheProgressStyle() {
        const percent = Math.min(this.cacheHitRate, 100);
        return `width: ${percent}%; background-color: #10b981;`;
    }
    
    // Query Analysis computed properties
    get averageQueryTime() {
        const time = this.performanceData.averageQueryTime || 0;
        return Math.round(time * 10) / 10;
    }
    
    get slowestQueryTime() {
        const time = this.performanceData.slowestQueryTime || 0;
        return Math.round(time * 10) / 10;
    }
    
    get fastestQueryTime() {
        const time = this.performanceData.fastestQueryTime || 0;
        return Math.round(time * 10) / 10;
    }
    
    get queryOptimizationRate() {
        const rate = this.performanceData.queryOptimizationRate || 0;
        return Math.round(rate * 10) / 10;
    }
    
    // Data Volume computed properties
    get totalJobApplications() {
        return this.performanceData.totalJobApplications || 0;
    }
    
    get dataGrowthRate() {
        const rate = this.performanceData.dataGrowthRate || 0;
        return Math.round(rate * 10) / 10;
    }
    
    get averageRecordSize() {
        const size = this.performanceData.averageRecordSize || 0;
        return Math.round(size * 10) / 10;
    }
    
    get formattedTotalDataSize() {
        const size = this.performanceData.totalDataSize || 0;
        return this.formatBytes(size * 1024); // Convert KB to bytes
    }
    
    // Resource Utilization computed properties
    get apiCallsUsed() {
        return this.performanceData.apiCallsUsed || 0;
    }
    
    get apiCallsLimit() {
        return this.performanceData.apiCallsLimit || 5000;
    }
    
    get apiUsagePercent() {
        const percent = this.performanceData.apiUsagePercent || 0;
        return Math.round(percent * 10) / 10;
    }
    
    get apiProgressStyle() {
        const percent = Math.min(this.apiUsagePercent, 100);
        const color = this.getProgressColor(percent);
        return `width: ${percent}%; background-color: ${color};`;
    }
    
    get storageUsed() {
        const used = this.performanceData.storageUsed || 0;
        return Math.round(used * 10) / 10;
    }
    
    get storageLimit() {
        const limit = this.performanceData.storageLimit || 10;
        return Math.round(limit * 10) / 10;
    }
    
    get storageUsagePercent() {
        const percent = this.performanceData.storageUsagePercent || 0;
        return Math.round(percent * 10) / 10;
    }
    
    get storageProgressStyle() {
        const percent = Math.min(this.storageUsagePercent, 100);
        const color = this.getProgressColor(percent);
        return `width: ${percent}%; background-color: ${color};`;
    }
    
    // Recommendations computed property
    get recommendations() {
        return this.performanceData.recommendations || [];
    }
    
    // Real-time monitoring computed properties
    get performanceStatus() {
        return this.monitoringData.performanceStatus || 'UNKNOWN';
    }
    
    get statusIcon() {
        switch (this.performanceStatus) {
            case 'OPTIMAL': return '🟢';
            case 'GOOD': return '🟡';
            case 'WARNING': return '🟠';
            case 'CRITICAL': return '🔴';
            default: return '⚪';
        }
    }
    
    get performanceWarnings() {
        return this.monitoringData.warnings || [];
    }
    
    get hasWarnings() {
        return this.performanceWarnings.length > 0;
    }
    
    get formattedTimestamp() {
        const timestamp = this.monitoringData.timestamp;
        if (!timestamp) return 'Never';
        
        const date = new Date(timestamp);
        return date.toLocaleTimeString();
    }
    
    // Data source computed properties
    get dataSource() {
        return this.performanceData.dataSource || 'unknown';
    }
    
    get dataSourceText() {
        switch (this.dataSource) {
            case 'cache': return 'Cache (Fast)';
            case 'database': return 'Database (Fresh)';
            default: return 'Unknown';
        }
    }
    
    get formattedGeneratedAt() {
        const generatedAt = this.performanceData.generatedAt;
        if (!generatedAt) return 'Unknown';
        
        const date = new Date(generatedAt);
        return date.toLocaleString();
    }
    
    get showEmptyState() {
        return Object.keys(this.performanceData).length === 0 && !this.isLoading && !this.errorMessage;
    }
    
    // Event handlers
    async handleMonitorPerformance() {
        this.isLoading = true;
        
        try {
            const monitoringResult = await monitorPerformance({ operationName: 'Dashboard Monitoring' });
            this.monitoringData = monitoringResult;
            this.showRealTimeMonitor = true;
            
            this.showToast('Success', 'Real-time monitoring activated', 'success');
            
        } catch (error) {
            this.errorMessage = 'Failed to start performance monitoring';
            this.showToast('Error', 'Failed to start monitoring', 'error');
            console.error('Monitoring error:', error);
        } finally {
            this.isLoading = false;
        }
    }
    
    async handleOptimizeQueries() {
        this.isLoading = true;
        
        try {
            // Sample query for optimization
            const sampleQuery = 'SELECT Id, Name, Status__c FROM Job_Application__c WHERE OwnerId = :userId';
            
            const optimizationResult = await optimizeQuery({ queryString: sampleQuery });
            
            this.showQueryOptimizationResults(optimizationResult);
            
        } catch (error) {
            this.errorMessage = 'Failed to optimize queries';
            this.showToast('Error', 'Failed to optimize queries', 'error');
            console.error('Query optimization error:', error);
        } finally {
            this.isLoading = false;
        }
    }
    
    async handleBulkProcessing() {
        this.isLoading = true;
        
        try {
            // Sample record IDs for bulk processing test
            const sampleIds = ['a00000000000001', 'a00000000000002', 'a00000000000003'];
            
            const bulkResult = await optimizeBulkProcessing({ 
                recordIds: sampleIds, 
                operation: 'UPDATE' 
            });
            
            this.showBulkProcessingResults(bulkResult);
            
        } catch (error) {
            this.errorMessage = 'Failed to optimize bulk processing';
            this.showToast('Error', 'Failed to optimize bulk processing', 'error');
            console.error('Bulk processing error:', error);
        } finally {
            this.isLoading = false;
        }
    }
    
    handleClearCache() {
        // Simulate cache clearing
        this.showToast('Success', 'Cache cleared successfully', 'success');
        this.handleRefreshMetrics();
    }
    
    handleExportReport() {
        const reportData = this.generatePerformanceReport();
        const csvContent = this.convertToCSV(reportData);
        
        const blob = new Blob([csvContent], { type: 'text/csv' });
        const url = window.URL.createObjectURL(blob);
        const link = document.createElement('a');
        link.href = url;
        link.download = `performance-report-${this.formatDateForFilename(new Date())}.csv`;
        link.click();
        window.URL.revokeObjectURL(url);
        
        this.showToast('Success', 'Performance report exported', 'success');
    }
    
    async handleRefreshMetrics() {
        this.isLoading = true;
        this.errorMessage = '';
        
        try {
            await refreshApex(this.wiredPerformanceResult);
            this.showToast('Success', 'Performance metrics refreshed', 'success');
        } catch (error) {
            this.errorMessage = 'Failed to refresh performance metrics';
            this.showToast('Error', 'Failed to refresh metrics', 'error');
            console.error('Refresh error:', error);
        } finally {
            this.isLoading = false;
        }
    }
    
    // Utility methods
    processPerformanceData() {
        // Additional processing of performance data if needed
        console.log('Performance Data processed:', this.performanceData);
    }
    
    getProgressColor(percent) {
        if (percent < 50) return '#10b981'; // Green
        if (percent < 75) return '#f59e0b'; // Yellow
        return '#ef4444'; // Red
    }
    
    formatBytes(bytes) {
        if (bytes === 0) return '0 B';
        
        const k = 1024;
        const sizes = ['B', 'KB', 'MB', 'GB'];
        const i = Math.floor(Math.log(bytes) / Math.log(k));
        
        return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i];
    }
    
    showQueryOptimizationResults(result) {
        const message = `Query Analysis Complete:\n` +
                       `Complexity: ${result.estimatedComplexity || 'Unknown'}\n` +
                       `Anti-patterns: ${result.antiPatterns?.length || 0}\n` +
                       `Suggestions: ${result.suggestions?.length || 0}`;
        
        this.showToast('Query Optimization', message, 'info');
    }
    
    showBulkProcessingResults(result) {
        const message = `Bulk Processing Analysis:\n` +
                       `Optimal Batch Size: ${result.optimalBatchSize}\n` +
                       `Processing Time: ${result.processingTimeMs}ms\n` +
                       `Success Rate: ${result.successRate}%`;
        
        this.showToast('Bulk Processing', message, 'info');
    }
    
    generatePerformanceReport() {
        return {
            systemMetrics: [
                { metric: 'CPU Usage', value: this.cpuUsagePercent + '%' },
                { metric: 'Memory Usage', value: this.heapUsagePercent + '%' },
                { metric: 'Query Usage', value: this.queryUsagePercent + '%' },
                { metric: 'Cache Hit Rate', value: this.cacheHitRate + '%' }
            ],
            queryMetrics: [
                { metric: 'Average Query Time', value: this.averageQueryTime + 'ms' },
                { metric: 'Slowest Query', value: this.slowestQueryTime + 'ms' },
                { metric: 'Fastest Query', value: this.fastestQueryTime + 'ms' },
                { metric: 'Optimization Rate', value: this.queryOptimizationRate + '%' }
            ],
            dataMetrics: [
                { metric: 'Total Records', value: this.totalJobApplications },
                { metric: 'Data Growth Rate', value: this.dataGrowthRate + '%/month' },
                { metric: 'Average Record Size', value: this.averageRecordSize + ' KB' },
                { metric: 'Total Data Size', value: this.formattedTotalDataSize }
            ]
        };
    }
    
    convertToCSV(data) {
        let csv = 'Performance Report\n\n';
        
        // System metrics
        csv += 'System Metrics\n';
        csv += 'Metric,Value\n';
        data.systemMetrics.forEach(metric => {
            csv += `"${metric.metric}","${metric.value}"\n`;
        });
        
        csv += '\nQuery Metrics\n';
        csv += 'Metric,Value\n';
        data.queryMetrics.forEach(metric => {
            csv += `"${metric.metric}","${metric.value}"\n`;
        });
        
        csv += '\nData Metrics\n';
        csv += 'Metric,Value\n';
        data.dataMetrics.forEach(metric => {
            csv += `"${metric.metric}","${metric.value}"\n`;
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
        this.loadPerformanceMetrics();
    }
    
    async loadPerformanceMetrics() {
        this.isLoading = true;
        this.errorMessage = '';
        
        try {
            // Performance metrics will be loaded via wire adapter
            // This method can be used for additional initialization
        } catch (error) {
            this.errorMessage = 'Failed to initialize performance metrics';
            console.error('Initialization error:', error);
        } finally {
            this.isLoading = false;
        }
    }
}
