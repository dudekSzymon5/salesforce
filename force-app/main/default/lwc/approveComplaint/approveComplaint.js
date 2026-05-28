import { LightningElement, api, track, wire } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import getCaseProducts from '@salesforce/apex/OrderComplaintController.getCaseProducts';
import approveComplaint from '@salesforce/apex/OrderComplaintController.approveComplaint';
import labelDecisionTitle from '@salesforce/label/c.Complaint_DecisionTitle';
import labelRefundDecision from '@salesforce/label/c.Complaint_RefundDecision';
import labelRefundAmount from '@salesforce/label/c.Complaint_RefundAmount';
import labelComment from '@salesforce/label/c.Complaint_Comment';
import labelSuccess from '@salesforce/label/c.Common_Success';
import labelError from '@salesforce/label/c.Common_Error';
import labelCancel from '@salesforce/label/c.Common_Cancel';
import labelSubmit from '@salesforce/label/c.Order_Submit';
import labelColProduct from '@salesforce/label/c.Order_ColProduct';
import labelColUnitPrice from '@salesforce/label/c.Order_ColUnitPrice';
import labelRefundPartial from '@salesforce/label/c.Complaint_RefundTypePartial';
import labelRefundFull from '@salesforce/label/c.Complaint_RefundTypeFull';
import labelRefundRejected from '@salesforce/label/c.Complaint_RefundTypeRejected';
import labelDecisionSubmitted from '@salesforce/label/c.Complaint_DecisionSubmitted';
import labelErrorGeneric from '@salesforce/label/c.Complaint_ErrorGeneric';

export default class ApproveComplaint extends LightningElement {

    @api recordId;

    @track approvedRefundType = '';
    @track comments = '';
    @track caseProducts = [];
    @track productRefunds = {};

    labelDecisionTitle = labelDecisionTitle;
    labelRefundDecision = labelRefundDecision;
    labelRefundAmount = labelRefundAmount;
    labelComment = labelComment;
    labelCancel = labelCancel;
    labelSubmit = labelSubmit;
    labelColProduct = labelColProduct;
    labelColUnitPrice = labelColUnitPrice;

    refundOptions = [
        { label: labelRefundPartial, value: 'Partial' },
        { label: labelRefundFull, value: 'Full' },
        { label: labelRefundRejected, value: 'Rejected' }
    ];

    @wire(getCaseProducts, { caseId: '$recordId' })
    wiredProducts({ data }) {
        if (data) {
            this.caseProducts = data.map(product => ({
                Id: product.Id,
                name: product.Product_Name__c,
                isExternal: product.Is_External__c,
                unitPrice: product.Is_External__c ? (product.Refund_Amount__c || 0) : (product.Order_Product__r?.UnitPrice || 0),
                quantity: product.Is_External__c ? 1 : (product.Order_Product__r?.Quantity || 0),
                maxAmount: product.Is_External__c
                    ? (product.Refund_Amount__c || 0)
                    : (product.Order_Product__r?.UnitPrice || 0) * (product.Order_Product__r?.Quantity || 0)
            }));
            const refunds = {};
            this.caseProducts.forEach(product => { refunds[product.Id] = 0; });
            this.productRefunds = refunds;
        }
    }

    get localProducts() {
        return this.caseProducts.filter(product => !product.isExternal);
    }

    get externalProducts() {
        return this.caseProducts.filter(product => product.isExternal);
    }

    get hasExternalProducts() {
        return this.externalProducts.length > 0;
    }

    get externalRefundTotal() {
        return this.externalProducts.reduce((sum, product) => sum + product.maxAmount, 0);
    }

    get showPartialInput() {
        return this.approvedRefundType === 'Partial';
    }

    get showProductSummary() {
        return this.hasExternalProducts && (this.approvedRefundType === 'Full' || this.approvedRefundType === 'Partial');
    }

    get isApproveDisabled() {
        if (!this.approvedRefundType) return true;
        if (this.showPartialInput) {
            const total = this.localProducts.reduce((sum, product) => sum + (this.productRefunds[product.Id] || 0), 0);
            if (total <= 0) return true;
            if (this.localProducts.some(product => (this.productRefunds[product.Id] || 0) > product.maxAmount)) return true;
        }
        return false;
    }

    handleRefundChange(event) {
        this.approvedRefundType = event.target.value;
    }

    handleProductAmountChange(event) {
        const productId = event.target.dataset.id;
        const amount = parseFloat(event.target.value) || 0;
        this.productRefunds = { ...this.productRefunds, [productId]: amount };
    }

    handleCommentsChange(event) {
        this.comments = event.target.value;
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    async handleApprove() {
        const productRefundsJson = this.showPartialInput
            ? JSON.stringify(this.localProducts.map(product => ({ id: product.Id, amount: this.productRefunds[product.Id] || 0 })))
            : null;

        try {
            await approveComplaint({
                caseId: this.recordId,
                refundType: this.approvedRefundType,
                comment: this.comments,
                productRefundsJson: productRefundsJson
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
