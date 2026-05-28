import { api, LightningElement, wire, track } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { subscribe, unsubscribe } from 'lightning/empApi';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import getOrderProducts from '@salesforce/apex/OrderComplaintController.getOrderProducts';
import submitComplaint from '@salesforce/apex/OrderComplaintController.submitComplaint';
import labelSuccess from '@salesforce/label/c.Common_Success';
import labelCancel from '@salesforce/label/c.Common_Cancel';
import labelSubmit from '@salesforce/label/c.Order_Submit';
import labelColProduct from '@salesforce/label/c.Order_ColProduct';
import labelColQuantity from '@salesforce/label/c.Order_ColQuantity';
import labelColUnitPrice from '@salesforce/label/c.Order_ColUnitPrice';
import labelRefundPartial from '@salesforce/label/c.Complaint_RefundTypePartial';
import labelRefundFull from '@salesforce/label/c.Complaint_RefundTypeFull';
import labelNewComplaintTitle from '@salesforce/label/c.Complaint_NewComplaintTitle';
import labelComplaintReason from '@salesforce/label/c.Complaint_Reason';
import labelRefundExpectation from '@salesforce/label/c.Complaint_RefundExpectation';
import labelWaitingSpinner from '@salesforce/label/c.Complaint_WaitingSpinner';
import labelWaitingMessage from '@salesforce/label/c.Complaint_WaitingMessage';
import labelErrorLoadProducts from '@salesforce/label/c.Complaint_ErrorLoadProducts';
import labelExternalRegistered from '@salesforce/label/c.Complaint_ExternalRegistered';
import labelSubmittedSuccess from '@salesforce/label/c.Complaint_SubmittedSuccess';
import labelErrorRetry from '@salesforce/label/c.Complaint_ErrorRetry';
import labelStatusFailed from '@salesforce/label/c.Complaint_StatusFailed';

const WHERE_TO_RESPONSE = '/event/External_Complaint_Response__e';

export default class OrderComplaint extends NavigationMixin(LightningElement) {
    @api recordId

    @track products = []
    @track selectedProductIds = []
    @track reason = ''
    @track expectedRefundType = ''
    @track errorMessage = ''
    @track isLoading = false
    @track waitingForExternal = false

    labelNewComplaintTitle = labelNewComplaintTitle;
    labelComplaintReason = labelComplaintReason;
    labelRefundExpectation = labelRefundExpectation;
    labelWaitingSpinner = labelWaitingSpinner;
    labelWaitingMessage = labelWaitingMessage;
    labelCancel = labelCancel;
    labelSubmit = labelSubmit;
    labelColProduct = labelColProduct;
    labelColQuantity = labelColQuantity;
    labelColUnitPrice = labelColUnitPrice;

    subscription = null
    externalResponseTimeout = null
    caseId = null
    correlationId = null
    hasExternalProduct = false

    refundOptions = [
        { label: labelRefundPartial, value: 'Partial' },
        { label: labelRefundFull, value: 'Full' }
    ];

    @wire(getOrderProducts, { orderId: '$recordId' })
    wiredProducts({ data, error }) {
        if (data) {
            this.products = data.map(item => ({
                Id: item.Id,
                name: item.Product2.Name,
                quantity: item.Quantity,
                unitPrice: item.UnitPrice,
                isExternal: item.Product2.Is_External__c
            }))
        } else if (error) {
            this.errorMessage = labelErrorLoadProducts;
        }
    }

    handleProductSelect(event) {
        const id = event.target.dataset.id;
        if (event.target.checked) {
            this.selectedProductIds = [...this.selectedProductIds, id];
        } else {
            this.selectedProductIds = this.selectedProductIds.filter(i => i !== id);
        }
        this.hasExternalProduct = this.products
            .filter(p => this.selectedProductIds.includes(p.Id))
            .some(p => p.isExternal);
    }

    handleReasonChange(event) { this.reason = event.target.value; }
    handleRefundChange(event) { this.expectedRefundType = event.target.value; }

    get isSubmitDisabled() {
        return !this.reason || !this.expectedRefundType || this.selectedProductIds.length === 0;
    }

    handleCancel() {
        this._unsubscribe();
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    async handleSubmit() {
        this.isLoading = true;
        this.errorMessage = '';

        try {
            if (this.hasExternalProduct) {
                await this._subscribeToExternalResponse();
            }

            const result = await submitComplaint({
                orderId: this.recordId,
                reason: this.reason,
                expectedRefundType: this.expectedRefundType,
                selectedOrderItemsId: this.selectedProductIds
            });

            this.caseId = result.caseId;
            this.correlationId = result.correlationId;

            if (!this.correlationId) {
                this._navigateToCase();
            } else {
                notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
                this.waitingForExternal = true;
                this.isLoading = false;
                this.externalResponseTimeout = setTimeout(() => {
                    this._unsubscribe();
                    this.waitingForExternal = false;
                    this.errorMessage = labelErrorRetry;
                }, 15000);
            }

        } catch (exception) {
            this._unsubscribe();
            this.errorMessage = exception.body?.message || labelErrorRetry;
            this.isLoading = false;
            this.waitingForExternal = false;
        }
    }

    async _subscribeToExternalResponse() {
        this.subscription = await subscribe(WHERE_TO_RESPONSE, -1, (event) => {
            const payload = event.data.payload;
            if (payload.Case_Id__c === this.correlationId) {
                this._unsubscribe();
                this.waitingForExternal = false;
                if (payload.Status__c === labelStatusFailed) {
                    this.errorMessage = payload.Error_Message__c || labelErrorRetry;
                } else {
                    this.dispatchEvent(new ShowToastEvent({
                        title: labelSuccess,
                        message: labelExternalRegistered,
                        variant: 'success'
                    }));
                     this.dispatchEvent(new CloseActionScreenEvent());
                }
            }
        });
    }

    _navigateToCase() {
        this.dispatchEvent(new ShowToastEvent({
            title: labelSuccess,
            message: labelSubmittedSuccess,
            variant: 'success'
        }));
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: { recordId: this.caseId, actionName: 'view' }
        });
    }

    _unsubscribe() {
        if (this.subscription) {
            unsubscribe(this.subscription);
            this.subscription = null;
        }
        if (this.externalResponseTimeout) {
            clearTimeout(this.externalResponseTimeout);
            this.externalResponseTimeout = null;
        }
    }

    disconnectedCallback() {
        this._unsubscribe();
    }
}
