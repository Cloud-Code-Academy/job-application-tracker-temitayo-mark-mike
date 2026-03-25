import { LightningElement, api } from 'lwc';

export default class ErrorPanel extends LightningElement {
    @api friendlyMessage = 'Something went wrong.';
    @api errorDetails;
    @api showRetry = false;

    showDetails = false;

    get hasErrorDetails() {
        return this.errorDetails && this.errorDetails.length > 0;
    }

    get iconName() {
        return 'utility:error';
    }

    toggleDetails() {
        this.showDetails = !this.showDetails;
    }

    handleRetry() {
        this.dispatchEvent(new CustomEvent('retry'));
    }
}
