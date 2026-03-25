import { createElement } from 'lwc';
import SecurityGovernanceDashboard from 'c/securityGovernanceDashboard';
import getSecurityAssessment from '@salesforce/apex/SecurityGovernanceService.getSecurityAssessment';

jest.mock(
    '@salesforce/apex/SecurityGovernanceService.getSecurityAssessment',
    () => ({ default: jest.fn() }),
    { virtual: true }
);
jest.mock(
    '@salesforce/apex/SecurityGovernanceService.validateDataAccess',
    () => ({ default: jest.fn() }),
    { virtual: true }
);
jest.mock(
    '@salesforce/apex/SecurityGovernanceService.createAuditLog',
    () => ({ default: jest.fn() }),
    { virtual: true }
);
jest.mock(
    '@salesforce/apex/SecurityGovernanceService.getComplianceReport',
    () => ({ default: jest.fn() }),
    { virtual: true }
);

describe('c-security-governance-dashboard', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('renders with default state', () => {
        const element = createElement('c-security-governance-dashboard', {
            is: SecurityGovernanceDashboard
        });
        document.body.appendChild(element);

        expect(element.isLoading).toBe(false);
    });

    it('loads security data via wire', () => {
        const element = createElement('c-security-governance-dashboard', {
            is: SecurityGovernanceDashboard
        });
        document.body.appendChild(element);

        getSecurityAssessment.emit({
            securityScore: 85,
            complianceScore: 92,
            gdprCompliant: true,
            soxCompliant: true
        });

        return Promise.resolve().then(() => {
            expect(element.errorMessage).toBe('');
        });
    });

    it('handles wire error gracefully', () => {
        const element = createElement('c-security-governance-dashboard', {
            is: SecurityGovernanceDashboard
        });
        document.body.appendChild(element);

        getSecurityAssessment.error({ message: 'Server error' });

        return Promise.resolve().then(() => {
            expect(element.errorMessage).toBe('Failed to load security assessment');
        });
    });
});
