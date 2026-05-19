import { LightningElement, api, track } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import approveComplaint from '@salesforce/apex/OrderComplaintController.approveComplaint';

export default class ApproveComplaint extends LightningElement {
    
    @api recordId; 

    @track approvedRefundType = '';
    @track comments = '';
    
    refundOptions = [
        { label: 'Partial Refund', value: 'Partial' },
        { label: 'Full Refund', value: 'Full' },
        { label: 'Rejected', value: 'Rejected' }
    ];

    get isApproveDisabled() {
        return !this.approvedRefundType;
    }

    handleRefundChange(event) {
        this.approvedRefundType = event.target.value;
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
                comments: this.comments
            });
            this.dispatchEvent(new ShowToastEvent({
                title: 'Success',
                message: 'Decision submitted.',
                variant: 'success'
            }));
            this.dispatchEvent(new CloseActionScreenEvent());
        } catch(exception) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: exception.body?.message || 'Something went wrong.',
                variant: 'error'
            }));
        }
    }
}