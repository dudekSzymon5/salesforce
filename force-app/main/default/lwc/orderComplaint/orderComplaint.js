import { api, LightningElement, wire, track } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { subscribe, unsubscribe } from 'lightning/empApi';
import getOrderProducts from '@salesforce/apex/OrderComplaintController.getOrderProducts';
import submitComplaint from '@salesforce/apex/OrderComplaintController.submitComplaint';

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

    subscription = null
    caseId = null
    correlationId = null
    hasExternalProduct = false

    refundOptions = [
        { label: 'Partial Refund', value: 'Partial' },
        { label: 'Full Refund', value: 'Full' }
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
            this.errorMessage = 'Failed to load products.';
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
                this.waitingForExternal = true;
                this.isLoading = false;
            }

        } catch (exception) {
            this._unsubscribe();
            this.errorMessage = exception.body?.message || 'Something is wrong, try again.';
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
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Success',
                    message: 'Complaint registered on external system.',
                    variant: 'success'
                }));
                if (this.caseId) {
                    this._navigateToCase();
                } else {
                    this.dispatchEvent(new CloseActionScreenEvent());
                }
            }
        });
    }

    _navigateToCase() {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Success',
            message: 'Complaint submitted successfully.',
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
    }

    disconnectedCallback() {
        this._unsubscribe();
    }
}
