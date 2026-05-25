import { LightningElement, api, track, wire } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import getCaseLocalTotal from '@salesforce/apex/OrderComplaintController.getMaxRefundAmount'
import approveComplaint from '@salesforce/apex/OrderComplaintController.approveComplaint';
import labelSuccess from '@salesforce/label/c.Common_Success';
import labelError from '@salesforce/label/c.Common_Error';
import labelRefundPartial from '@salesforce/label/c.Complaint_RefundTypePartial';
import labelRefundFull from '@salesforce/label/c.Complaint_RefundTypeFull';
import labelRefundRejected from '@salesforce/label/c.Complaint_RefundTypeRejected';
import labelDecisionSubmitted from '@salesforce/label/c.Complaint_DecisionSubmitted';
import labelErrorGeneric from '@salesforce/label/c.Complaint_ErrorGeneric';


export default class ApproveComplaint extends LightningElement {

    @api recordId;

    @track approvedRefundType = '';
    @track refundAmount = null;
    @track comments = '';

    refundOptions = [
        { label: labelRefundPartial, value: 'Partial' },
        { label: labelRefundFull, value: 'Full' },
        { label: labelRefundRejected, value: 'Rejected' }
    ];

    @wire(getCaseLocalTotal, { caseId: '$recordId' })
    wiredTotal ({data}) { //-> Destrukturyzacja wyciąga pole {data} z odpowiedzi
        if (data != null) {
            this.maxRefundAmount = data;
        }
    }
    @track maxRefundAmount = null;

    get showPartialInput() {
        return this.approvedRefundType === 'Partial';
    }

    get maxRefundLabel() {
        return this.maxRefundAmount != null ? `Maximum refund: ${this.maxRefundAmount}` : '';
    }

    get isApproveDisabled() {
        if (!this.approvedRefundType) return true;
        if (this.showPartialInput && (!this.refundAmount || this.refundAmount <= 0)) return true;
        if (this.showPartialInput && this.maxRefundAmount != null && this.refundAmount > this.maxRefundAmount) return true;
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
            notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
            this.dispatchEvent(new ShowToastEvent({
                title: labelSuccess,
                message: labelDecisionSubmitted,
                variant: 'success'
            }));
            this.dispatchEvent(new CloseActionScreenEvent());
        } catch (exception) {
            this.dispatchEvent(new ShowToastEvent({
                title: labelError,
                message: exception.body?.message || labelErrorGeneric,
                variant: 'error'
            }));
        }
    }
}
