import { LightningElement, api, track } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import approveComplaint from '@salesforce/apex/OrderComplaintController.approveComplaint';

export default class ApproveComplaint extends LightningElement {

    @api recordId;

    @track approvedRefundType = '';
    @track refundAmount = null;
    @track comments = '';

    refundOptions = [
        { label: 'Partial Refund', value: 'Partial' },
        { label: 'Full Refund', value: 'Full' },
        { label: 'Rejected', value: 'Rejected' }
    ];

    get showPartialInput() {
        return this.approvedRefundType === 'Partial';
    }

    get isApproveDisabled() {
        if (!this.approvedRefundType) return true;
        if (this.showPartialInput && (!this.refundAmount || this.refundAmount <= 0)) return true;
        return false;
    }

    handleRefundChange(event) {
        this.approvedRefundType = event.target.value;
        if (this.approvedRefundType !== 'Partial') this.refundAmount = null;
    }

    handleAmountChange(event) {
        this.refundAmount = parseFloat(event.target.value);
    }

    handleCommentsChange(event) {
        this.comments = event.target.value;
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    async handleApprove() {
        try {
            await approveComplaint({
                caseId: this.recordId,
                refundType: this.approvedRefundType,
                refundAmount: this.refundAmount,
                comment: this.comments
            });
            this.dispatchEvent(new ShowToastEvent({
                title: 'Success',
                message: 'Decision submitted.',
                variant: 'success'
            }));
            this.dispatchEvent(new CloseActionScreenEvent());
        } catch (exception) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: exception.body?.message || 'Something went wrong.',
                variant: 'error'
            }));
        }
    }
}
