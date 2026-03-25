import { createElement } from 'lwc';
import { ShowToastEventName } from 'lightning/platformShowToastEvent';
import PerformanceDashboard from 'c/performanceDashboard';
import generateDashboardData from '@salesforce/apex/FeedbackAnalyticsService.generateDashboardData';
import generateRecommendations from '@salesforce/apex/FeedbackAnalyticsService.generateRecommendations';

// Mock Apex methods
jest.mock(
    '@salesforce/apex/FeedbackAnalyticsService.generateDashboardData',
    () => {
        const { createApexTestWireAdapter } = require('@salesforce/sfdx-lwc-jest');
        return {
            default: createApexTestWireAdapter(jest.fn())
        };
    },
    { virtual: true }
);

jest.mock(
    '@salesforce/apex/FeedbackAnalyticsService.generateRecommendations',
    () => {
        return { default: jest.fn() };
    },
    { virtual: true }
);

// Mock Chart.js
global.Chart = jest.fn().mockImplementation(() => ({
    destroy: jest.fn(),
    update: jest.fn()
}));

// Mock platform resource loader
jest.mock('lightning/platformResourceLoader', () => {
    return {
        loadScript: jest.fn(() => Promise.resolve())
    };
});

// Mock user ID
jest.mock('@salesforce/user/Id', () => {
    return { default: 'mockUserId' };
}, { virtual: true });

describe('c-performance-dashboard', () => {
    let element;

    // Mock dashboard data
    const mockDashboardData = {
        averageOverallRating: 4.2,
        totalFeedbackRecords: 15,
        successRate: 73.3,
        totalApplicationsWithFeedback: 8,
        performanceTrend: {
            percentageChange: 12.5,
            monthlyData: [
                { month: 'Jan', averageRating: 3.8 },
                { month: 'Feb', averageRating: 4.1 },
                { month: 'Mar', averageRating: 4.2 }
            ]
        },
        competencyBreakdown: [
            { competency: 'Technical Skills', averageRating: 4.5 },
            { competency: 'Communication', averageRating: 4.0 },
            { competency: 'Problem Solving', averageRating: 4.2 }
        ],
        interviewTypeDistribution: [
            { type: 'Technical', count: 8 },
            { type: 'Behavioral', count: 5 },
            { type: 'System Design', count: 2 }
        ],
        ratingDistribution: [
            { rating: 5, count: 6 },
            { rating: 4, count: 7 },
            { rating: 3, count: 2 }
        ],
        recentFeedback: [
            {
                feedbackId: 'fb1',
                interviewType: 'Technical',
                rating: 4,
                formattedDate: '2024-01-15'
            },
            {
                feedbackId: 'fb2',
                interviewType: 'Behavioral',
                rating: 5,
                formattedDate: '2024-01-14'
            }
        ]
    };

    const mockRecommendations = [
        {
            message: 'Focus on improving technical skills based on recent feedback',
            actionLabel: 'View Details',
            type: 'improvement'
        },
        {
            message: 'Schedule more behavioral interviews to balance your portfolio',
            actionLabel: 'Schedule Interview',
            type: 'action'
        }
    ];

    beforeEach(() => {
        element = createElement('c-performance-dashboard', {
            is: PerformanceDashboard
        });

        // Reset mocks
        jest.clearAllMocks();
        generateRecommendations.mockResolvedValue(mockRecommendations);
    });

    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    describe('Component Initialization', () => {
        it('should render with default properties', () => {
            document.body.appendChild(element);

            expect(element.height).toBe(600);
            expect(element.showFilters).toBe(true);
            expect(element.autoRefresh).toBe(false);
            expect(element.defaultDateRange).toBe('90');
        });

        it('should show loading state initially', () => {
            document.body.appendChild(element);

            const spinner = element.shadowRoot.querySelector('lightning-spinner');
            expect(spinner).toBeTruthy();
        });

        it('should render filter controls when showFilters is true', () => {
            element.showFilters = true;
            document.body.appendChild(element);

            const dateRangeFilter = element.shadowRoot.querySelector('lightning-combobox[name="dateRange"]');
            const interviewTypeFilter = element.shadowRoot.querySelector('lightning-combobox[name="interviewType"]');
            
            expect(dateRangeFilter).toBeTruthy();
            expect(interviewTypeFilter).toBeTruthy();
        });

        it('should hide filter controls when showFilters is false', () => {
            element.showFilters = false;
            document.body.appendChild(element);

            const filterSection = element.shadowRoot.querySelector('.slds-card__header');
            expect(filterSection).toBeFalsy();
        });
    });

    describe('Data Loading', () => {
        it('should display dashboard data when loaded successfully', async () => {
            document.body.appendChild(element);

            // Emit data through the wire adapter
            generateDashboardData.emit(mockDashboardData);

            await Promise.resolve();

            // Check if metrics are displayed
            const metricCards = element.shadowRoot.querySelectorAll('.metric-card');
            expect(metricCards.length).toBe(4);

            // Check specific metric values
            const metricValues = element.shadowRoot.querySelectorAll('.metric-value');
            expect(metricValues[0].textContent).toBe('4.2');
            expect(metricValues[1].textContent).toBe('15');
            expect(metricValues[2].textContent).toBe('73.3%');
            expect(metricValues[3].textContent).toBe('8');
        });

        it('should handle loading errors gracefully', async () => {
            document.body.appendChild(element);

            const mockError = {
                body: { message: 'Test error message' },
                ok: false,
                status: 400,
                statusText: 'Bad Request'
            };

            // Emit error through the wire adapter
            generateDashboardData.error(mockError);

            await Promise.resolve();

            // Check if error is displayed
            const errorMessages = element.shadowRoot.querySelectorAll('.slds-notify_alert');
            expect(errorMessages.length).toBeGreaterThan(0);
        });

        it('should load recommendations after dashboard data', async () => {
            document.body.appendChild(element);

            generateDashboardData.emit(mockDashboardData);
            await Promise.resolve();

            expect(generateRecommendations).toHaveBeenCalledWith({
                dateRange: '90',
                interviewType: '',
                jobApplicationId: undefined
            });
        });
    });

    describe('Filter Interactions', () => {
        beforeEach(async () => {
            document.body.appendChild(element);
            generateDashboardData.emit(mockDashboardData);
            await Promise.resolve();
        });

        it('should update date range filter', async () => {
            const dateRangeFilter = element.shadowRoot.querySelector('lightning-combobox[name="dateRange"]');
            
            dateRangeFilter.dispatchEvent(new CustomEvent('change', {
                detail: { value: '30' }
            }));

            await Promise.resolve();

            expect(element.selectedDateRange).toBe('30');
        });

        it('should update interview type filter', async () => {
            const interviewTypeFilter = element.shadowRoot.querySelector('lightning-combobox[name="interviewType"]');
            
            interviewTypeFilter.dispatchEvent(new CustomEvent('change', {
                detail: { value: 'Technical' }
            }));

            await Promise.resolve();

            expect(element.selectedInterviewType).toBe('Technical');
        });

        it('should refresh data when refresh button is clicked', async () => {
            const refreshButton = element.shadowRoot.querySelector('lightning-button[label="Refresh"]');
            
            refreshButton.click();
            await Promise.resolve();

            // Should show loading state
            expect(element.isLoading).toBe(true);
        });
    });

    describe('Chart Rendering', () => {
        beforeEach(async () => {
            document.body.appendChild(element);
            generateDashboardData.emit(mockDashboardData);
            await Promise.resolve();
        });

        it('should render chart canvases', () => {
            const trendChart = element.shadowRoot.querySelector('[lwc\\:ref="trendChart"]');
            const competencyChart = element.shadowRoot.querySelector('[lwc\\:ref="competencyChart"]');
            const typeChart = element.shadowRoot.querySelector('[lwc\\:ref="typeChart"]');
            const ratingChart = element.shadowRoot.querySelector('[lwc\\:ref="ratingChart"]');

            expect(trendChart).toBeTruthy();
            expect(competencyChart).toBeTruthy();
            expect(typeChart).toBeTruthy();
            expect(ratingChart).toBeTruthy();
        });

        it('should have proper chart height based on component height', () => {
            element.height = 800;
            
            const expectedHeight = Math.floor(800 * 0.4);
            expect(element.chartHeight).toBe(`height: ${expectedHeight}px;`);
        });
    });

    describe('Insights and Recommendations', () => {
        beforeEach(async () => {
            document.body.appendChild(element);
            generateDashboardData.emit(mockDashboardData);
            await Promise.resolve();
        });

        it('should display insights based on performance data', () => {
            const insightsContainer = element.shadowRoot.querySelector('.insights-container');
            expect(insightsContainer).toBeTruthy();

            // Should show positive insight for high rating
            const insightItems = element.shadowRoot.querySelectorAll('.insight-item');
            expect(insightItems.length).toBeGreaterThan(0);
        });

        it('should display recommendations', async () => {
            // Wait for recommendations to load
            await Promise.resolve();

            const recommendationsContainer = element.shadowRoot.querySelector('.recommendations-container');
            expect(recommendationsContainer).toBeTruthy();

            const recommendationItems = element.shadowRoot.querySelectorAll('.recommendation-item');
            expect(recommendationItems.length).toBe(mockRecommendations.length);
        });

        it('should handle recommendation actions', async () => {
            await Promise.resolve();

            const actionButtons = element.shadowRoot.querySelectorAll('.recommendation-item lightning-button');
            if (actionButtons.length > 0) {
                // Mock toast event handler
                const handler = jest.fn();
                element.addEventListener(ShowToastEventName, handler);

                actionButtons[0].click();
                await Promise.resolve();

                expect(handler).toHaveBeenCalled();
            }
        });
    });

    describe('Recent Activity', () => {
        beforeEach(async () => {
            document.body.appendChild(element);
            generateDashboardData.emit(mockDashboardData);
            await Promise.resolve();
        });

        it('should display recent feedback activity', () => {
            const activityContainer = element.shadowRoot.querySelector('.recent-activity-container');
            expect(activityContainer).toBeTruthy();

            const activityItems = element.shadowRoot.querySelectorAll('.activity-item');
            expect(activityItems.length).toBe(mockDashboardData.recentFeedback.length);
        });

        it('should show proper rating display for each activity', () => {
            const ratingDisplays = element.shadowRoot.querySelectorAll('.rating-display');
            expect(ratingDisplays.length).toBe(mockDashboardData.recentFeedback.length);

            const firstRating = ratingDisplays[0].querySelector('.rating-value');
            expect(firstRating.textContent).toBe('4');
        });
    });

    describe('Export Functionality', () => {
        beforeEach(async () => {
            document.body.appendChild(element);
            generateDashboardData.emit(mockDashboardData);
            await Promise.resolve();
        });

        it('should handle export button click', async () => {
            // Mock URL.createObjectURL and related methods
            global.URL.createObjectURL = jest.fn(() => 'mock-url');
            global.URL.revokeObjectURL = jest.fn();
            
            // Mock document.createElement for download link
            const mockLink = {
                href: '',
                download: '',
                click: jest.fn()
            };
            jest.spyOn(document, 'createElement').mockReturnValue(mockLink);

            const exportButton = element.shadowRoot.querySelector('lightning-button[label="Export"]');
            
            // Mock toast event handler
            const handler = jest.fn();
            element.addEventListener(ShowToastEventName, handler);

            exportButton.click();
            await Promise.resolve();

            expect(mockLink.click).toHaveBeenCalled();
            expect(handler).toHaveBeenCalledWith(
                expect.objectContaining({
                    detail: expect.objectContaining({
                        title: 'Success',
                        variant: 'success'
                    })
                })
            );
        });
    });

    describe('Performance Trends', () => {
        it('should calculate positive trend correctly', async () => {
            const dataWithPositiveTrend = {
                ...mockDashboardData,
                performanceTrend: {
                    percentageChange: 15.5,
                    monthlyData: []
                }
            };

            document.body.appendChild(element);
            generateDashboardData.emit(dataWithPositiveTrend);
            await Promise.resolve();

            const trend = element.ratingTrend;
            expect(trend.isPositive).toBe(true);
            expect(trend.isNegative).toBe(false);
            expect(trend.percentage).toBe('15.5');
        });

        it('should calculate negative trend correctly', async () => {
            const dataWithNegativeTrend = {
                ...mockDashboardData,
                performanceTrend: {
                    percentageChange: -8.2,
                    monthlyData: []
                }
            };

            document.body.appendChild(element);
            generateDashboardData.emit(dataWithNegativeTrend);
            await Promise.resolve();

            const trend = element.ratingTrend;
            expect(trend.isPositive).toBe(false);
            expect(trend.isNegative).toBe(true);
            expect(trend.percentage).toBe('8.2');
        });
    });

    describe('Offline Handling', () => {
        it('should detect offline status', async () => {
            // Mock navigator.onLine
            Object.defineProperty(navigator, 'onLine', {
                writable: true,
                value: false
            });

            document.body.appendChild(element);
            await Promise.resolve();

            expect(element.isOffline).toBe(true);
        });

        it('should show offline banner when offline', async () => {
            Object.defineProperty(navigator, 'onLine', {
                writable: true,
                value: false
            });

            element.isOffline = true;
            document.body.appendChild(element);
            await Promise.resolve();

            const offlineBanner = element.shadowRoot.querySelector('.offline-banner');
            expect(offlineBanner).toBeTruthy();
        });
    });

    describe('Accessibility', () => {
        beforeEach(async () => {
            document.body.appendChild(element);
            generateDashboardData.emit(mockDashboardData);
            await Promise.resolve();
        });

        it('should have proper ARIA labels and roles', () => {
            const card = element.shadowRoot.querySelector('lightning-card');
            expect(card).toBeTruthy();

            const charts = element.shadowRoot.querySelectorAll('canvas');
            charts.forEach(chart => {
                expect(chart.getAttribute('role')).toBeTruthy();
            });
        });

        it('should support keyboard navigation', () => {
            const buttons = element.shadowRoot.querySelectorAll('lightning-button');
            buttons.forEach(button => {
                expect(button.tabIndex).not.toBe(-1);
            });
        });
    });
});