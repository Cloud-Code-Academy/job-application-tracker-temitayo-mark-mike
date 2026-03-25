import { createElement } from 'lwc';
import CalendarIntegration from 'c/calendarIntegration';

jest.mock(
    'lightning/uiRecordApi',
    () => ({
        getRecord: jest.fn(),
        createRecord: jest.fn()
    }),
    { virtual: true }
);

describe('c-calendar-integration', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('renders with default empty state', () => {
        const element = createElement('c-calendar-integration', {
            is: CalendarIntegration
        });
        element.recordId = '001xx000003TEST';
        document.body.appendChild(element);

        expect(element.isProcessing).toBe(false);
        expect(element.showSuccessMessage).toBe(false);
        expect(element.eventSubject).toBe('');
    });

    it('accepts recordId as public property', () => {
        const element = createElement('c-calendar-integration', {
            is: CalendarIntegration
        });
        element.recordId = '001xx000003ABCD';
        document.body.appendChild(element);

        expect(element.recordId).toBe('001xx000003ABCD');
    });
});
