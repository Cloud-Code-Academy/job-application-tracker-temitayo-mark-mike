import { createElement } from 'lwc';
import ErrorPanel from 'c/errorPanel';

describe('c-error-panel', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('displays friendly message', () => {
        const element = createElement('c-error-panel', { is: ErrorPanel });
        element.friendlyMessage = 'Failed to load data.';
        document.body.appendChild(element);

        const heading = element.shadowRoot.querySelector('h3');
        expect(heading.textContent).toBe('Failed to load data.');
    });

    it('shows retry button when showRetry is true', () => {
        const element = createElement('c-error-panel', { is: ErrorPanel });
        element.showRetry = true;
        document.body.appendChild(element);

        return Promise.resolve().then(() => {
            const retryButton = element.shadowRoot.querySelector('button.slds-button_brand');
            expect(retryButton).not.toBeNull();
            expect(retryButton.textContent).toBe('Try Again');
        });
    });

    it('hides retry button when showRetry is false', () => {
        const element = createElement('c-error-panel', { is: ErrorPanel });
        element.showRetry = false;
        document.body.appendChild(element);

        return Promise.resolve().then(() => {
            const retryButton = element.shadowRoot.querySelector('button.slds-button_brand');
            expect(retryButton).toBeNull();
        });
    });

    it('dispatches retry event on button click', () => {
        const element = createElement('c-error-panel', { is: ErrorPanel });
        element.showRetry = true;
        document.body.appendChild(element);

        const handler = jest.fn();
        element.addEventListener('retry', handler);

        return Promise.resolve().then(() => {
            const retryButton = element.shadowRoot.querySelector('button.slds-button_brand');
            retryButton.click();
            expect(handler).toHaveBeenCalledTimes(1);
        });
    });

    it('toggles error details visibility', () => {
        const element = createElement('c-error-panel', { is: ErrorPanel });
        element.errorDetails = 'Stack trace: line 42';
        document.body.appendChild(element);

        return Promise.resolve().then(() => {
            const toggleButton = element.shadowRoot.querySelector('button.slds-button_neutral');
            expect(toggleButton).not.toBeNull();

            // Details hidden initially
            let detailsBox = element.shadowRoot.querySelector('#error-details');
            expect(detailsBox).toBeNull();

            // Click to show details
            toggleButton.click();
            return Promise.resolve();
        }).then(() => {
            const detailsBox = element.shadowRoot.querySelector('#error-details');
            expect(detailsBox).not.toBeNull();
            expect(detailsBox.textContent).toContain('Stack trace: line 42');
        });
    });
});
