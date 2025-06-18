import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getSecurityAssessment from '@salesforce/apex/SecurityGovernanceService.getSecurityAssessment';
import validateDataAccess from '@salesforce/apex/SecurityGovernanceService.validateDataAccess';
import createAuditLog from '@salesforce/apex/SecurityGovernanceService.createAuditLog';
import getComplianceReport from '@salesforce/apex/SecurityGovernanceService.getComplianceReport';

export default class SecurityGovernanceDashboard extends LightningElement {
    
    // Component state
    @track isLoading = false;
    @track errorMessage = '';
    @track securityData = {};
    
    // Wired data
    wiredSecurityResult;
    
    // Wire to get security assessment data
    @wire(getSecurityAssessment)
    wiredSecurity(result) {
        this.wiredSecurityResult = result;
        if (result.data) {
            this.securityData = result.data;
            this.errorMessage = '';
            this.processSecurityData();
        } else if (result.error) {
            this.errorMessage = 'Failed to load security assessment';
            console.error('Security error:', result.error);
        }
    }
    
    // Computed properties for security metrics
    get securityScore() {
        return this.securityData.securityScore || 0;
    }
    
    get securityLevel() {
        const score = this.securityScore;
        if (score >= 80) return 'HIGH';
        if (score >= 60) return 'MEDIUM';
        return 'LOW';
    }
    
    get complianceScore() {
        return this.securityData.complianceScore || 0;
    }
    
    get complianceLevel() {
        const score = this.complianceScore;
        if (score >= 80) return 'good';
        if (score >= 60) return 'neutral';
        return 'poor';
    }
    
    get complianceChecks() {
        // Count passed compliance checks
        let passed = 0;
        if (this.securityData.gdprCompliant) passed++;
        if (this.securityData.soxCompliant) passed++;
        if (this.securityData.dataEncrypted) passed++;
        if (this.securityData.auditTrailEnabled) passed++;
        if (this.securityData.accessControlsActive) passed++;
        return `${passed}/5`;
    }
    
    get accessibleFields() {
        return this.securityData.accessibleFields || 0;
    }
    
    get accessPercentage() {
        return this.securityData.accessPercentage || 0;
    }
    
    get totalAuditEntries() {
        return this.securityData.totalAuditEntries || 0;
    }
    
    get auditRetentionDays() {
        return this.securityData.auditRetentionDays || 0;
    }
    
    // User profile computed properties
    get userName() {
        return this.securityData.userName || 'Unknown User';
    }
    
    get profileName() {
        return this.securityData.profileName || 'Unknown Profile';
    }
    
    get roleName() {
        return this.securityData.roleName || 'No Role';
    }
    
    get formattedLastLogin() {
        const lastLogin = this.securityData.lastLogin;
        if (!lastLogin) return 'Never';
        
        const date = new Date(lastLogin);
        return date.toLocaleDateString() + ' ' + date.toLocaleTimeString();
    }
    
    get accountAge() {
        return this.securityData.accountAge || 0;
    }
    
    get isActive() {
        return this.securityData.isActive || false;
    }
    
    // Compliance status computed properties
    get gdprStatus() {
        return this.securityData.gdprCompliant ? 'compliant' : 'non-compliant';
    }
    
    get gdprIcon() {
        return this.securityData.gdprCompliant ? '✅' : '❌';
    }
    
    get soxStatus() {
        return this.securityData.soxCompliant ? 'compliant' : 'non-compliant';
    }
    
    get soxIcon() {
        return this.securityData.soxCompliant ? '✅' : '❌';
    }
    
    get encryptionStatus() {
        return this.securityData.dataEncrypted ? 'enabled' : 'disabled';
    }
    
    get encryptionIcon() {
        return this.securityData.dataEncrypted ? '✅' : '❌';
    }
    
    get auditStatus() {
        return this.securityData.auditTrailEnabled ? 'enabled' : 'disabled';
    }
    
    get auditIcon() {
        return this.securityData.auditTrailEnabled ? '✅' : '❌';
    }
    
    get accessControlStatus() {
        return this.securityData.accessControlsActive ? 'active' : 'inactive';
    }
    
    get accessControlIcon() {
        return this.securityData.accessControlsActive ? '✅' : '❌';
    }
    
    // Recommendations computed property
    get recommendations() {
        return this.securityData.recommendations || [];
    }
    
    // Data access computed properties
    get ownedRecords() {
        return this.securityData.ownedRecords || 0;
    }
    
    get recentAccess() {
        return this.securityData.recentAccess || 0;
    }
    
    get dataRetention() {
        return this.securityData.dataRetention || 0;
    }
    
    // Audit trail computed properties
    get recentEntries() {
        return this.securityData.recentEntries || 0;
    }
    
    get criticalEvents() {
        return this.securityData.criticalEvents || 0;
    }
    
    get formattedLastAudit() {
        const lastAudit = this.securityData.lastAuditDate;
        if (!lastAudit) return 'Never';
        
        const date = new Date(lastAudit);
        return date.toLocaleDateString() + ' ' + date.toLocaleTimeString();
    }
    
    get showEmptyState() {
        return Object.keys(this.securityData).length === 0 && !this.isLoading && !this.errorMessage;
    }
    
    // Event handlers
    async handleGenerateReport() {
        this.isLoading = true;
        
        try {
            const reportData = await getComplianceReport({ reportType: 'SECURITY' });
            
            // Create and download report
            this.generateReportFile(reportData);
            
            this.showToast('Success', 'Compliance report generated successfully', 'success');
            
        } catch (error) {
            this.errorMessage = 'Failed to generate compliance report';
            this.showToast('Error', 'Failed to generate report', 'error');
            console.error('Report generation error:', error);
        } finally {
            this.isLoading = false;
        }
    }
    
    async handleValidateAccess() {
        this.isLoading = true;
        
        try {
            // Get some sample record IDs for validation
            const sampleRecordIds = ['a00000000000001']; // Would get actual IDs in real implementation
            
            const validationResult = await validateDataAccess({ 
                recordIds: sampleRecordIds, 
                operation: 'READ' 
            });
            
            this.showAccessValidationResults(validationResult);
            
        } catch (error) {
            this.errorMessage = 'Failed to validate data access';
            this.showToast('Error', 'Failed to validate access', 'error');
            console.error('Access validation error:', error);
        } finally {
            this.isLoading = false;
        }
    }
    
    async handleCreateAuditLog() {
        this.isLoading = true;
        
        try {
            const success = await createAuditLog({ 
                operation: 'SECURITY_ASSESSMENT', 
                recordId: null, 
                details: 'Manual security assessment initiated from dashboard' 
            });
            
            if (success) {
                this.showToast('Success', 'Audit log entry created', 'success');
                // Refresh the assessment to show updated audit counts
                await refreshApex(this.wiredSecurityResult);
            } else {
                this.showToast('Warning', 'Failed to create audit log entry', 'warning');
            }
            
        } catch (error) {
            this.errorMessage = 'Failed to create audit log';
            this.showToast('Error', 'Failed to create audit log', 'error');
            console.error('Audit log error:', error);
        } finally {
            this.isLoading = false;
        }
    }
    
    async handleRefreshAssessment() {
        this.isLoading = true;
        this.errorMessage = '';
        
        try {
            await refreshApex(this.wiredSecurityResult);
            this.showToast('Success', 'Security assessment refreshed', 'success');
        } catch (error) {
            this.errorMessage = 'Failed to refresh security assessment';
            this.showToast('Error', 'Failed to refresh assessment', 'error');
            console.error('Refresh error:', error);
        } finally {
            this.isLoading = false;
        }
    }
    
    // Utility methods
    processSecurityData() {
        // Additional processing of security data if needed
        console.log('Security Data processed:', this.securityData);
    }
    
    generateReportFile(reportData) {
        const reportContent = this.formatReportContent(reportData);
        
        const blob = new Blob([reportContent], { type: 'text/plain' });
        const url = window.URL.createObjectURL(blob);
        const link = document.createElement('a');
        link.href = url;
        link.download = `security-compliance-report-${this.formatDateForFilename(new Date())}.txt`;
        link.click();
        window.URL.revokeObjectURL(url);
    }
    
    formatReportContent(reportData) {
        let content = 'SECURITY & COMPLIANCE REPORT\n';
        content += '================================\n\n';
        content += `Generated: ${new Date().toLocaleString()}\n`;
        content += `Generated By: ${this.userName}\n\n`;
        
        content += 'SECURITY METRICS:\n';
        content += `-----------------\n`;
        content += `Security Score: ${this.securityScore}/100\n`;
        content += `Compliance Score: ${this.complianceScore}%\n`;
        content += `Field Access: ${this.accessPercentage}%\n`;
        content += `Audit Entries: ${this.totalAuditEntries}\n\n`;
        
        content += 'COMPLIANCE STATUS:\n';
        content += '------------------\n';
        content += `GDPR Compliant: ${this.securityData.gdprCompliant ? 'Yes' : 'No'}\n`;
        content += `SOX Compliant: ${this.securityData.soxCompliant ? 'Yes' : 'No'}\n`;
        content += `Data Encrypted: ${this.securityData.dataEncrypted ? 'Yes' : 'No'}\n`;
        content += `Audit Trail: ${this.securityData.auditTrailEnabled ? 'Enabled' : 'Disabled'}\n`;
        content += `Access Controls: ${this.securityData.accessControlsActive ? 'Active' : 'Inactive'}\n\n`;
        
        content += 'RECOMMENDATIONS:\n';
        content += '----------------\n';
        this.recommendations.forEach(rec => {
            content += `${rec.priority}: ${rec.title}\n`;
            content += `  ${rec.description}\n`;
            content += `  Impact: ${rec.impact}\n\n`;
        });
        
        return content;
    }
    
    showAccessValidationResults(validationResult) {
        const message = `Access Validation Complete:\n` +
                       `Total Records: ${validationResult.totalRecords}\n` +
                       `Accessible: ${validationResult.accessibleRecords}\n` +
                       `Restricted: ${validationResult.restrictedRecords}`;
        
        this.showToast('Validation Complete', message, 'info');
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
        this.loadSecurityAssessment();
    }
    
    async loadSecurityAssessment() {
        this.isLoading = true;
        this.errorMessage = '';
        
        try {
            // Security assessment will be loaded via wire adapter
            // This method can be used for additional initialization
        } catch (error) {
            this.errorMessage = 'Failed to initialize security assessment';
            console.error('Initialization error:', error);
        } finally {
            this.isLoading = false;
        }
    }
}
