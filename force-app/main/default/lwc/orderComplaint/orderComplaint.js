import { api, LightningElement, wire, track } from 'lwc';
import {CloseActionScreenEvent} from 'lightning/actions';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import {NavigationMixin} from 'lightning/navigation';
import getOrderProducts from '@salesforce/apex/OrderComplaintController.getOrderProducts';
import submitComplaint from '@salesforce/apex/OrderComplaintController.submitComplaint';

export default class OrderComplaint extends NavigationMixin(LightningElement) {
    @api recordId

    @track products = []
    @track selectedProductIds = []
    @track reason = ''
    @track expectedRefundType = ''
    @track errorMessage = ''
    @track isLoading = false
    
    refundOptions = [
        {label: 'Partial Refund', value: 'Partial'},
        {label: 'Full Refund', value: 'Full'}
    ];

    @wire(getOrderProducts, {orderId: '$recordId'})
    wiredProducts ({data, error}) {
        if (data) {
            this.products = data.map(item => ({
                Id: item.Id,
                name: item.Product2.Name,
                quantity: item.Quantity,
                unitPrice: item.UnitPrice
            }))
        } else if (error) {
            this.errorMessage = 'Failed to load products.';
        }
    }

    handleProductSelect(event) {
        const id = event.target. dataset.id;
        if (event.target.checked) {
            this.selectedProductIds = [...this.selectedProductIds, id];
        } else {
            this.selectedProductIds = this.selectedProductIds.filter (i => i !== id);
        }
    }

    handleReasonChange(event) {
        this.reason = event.target.value;
    }

    handleRefundChange(event) {
        this.expectedRefundType = event.target.value;
    }

    get isSubmitDisabled() {
        return !this.reason || !this.expectedRefundType || this.selectedProductIds.length === 0;
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    async handleSubmit() {
        this.isLoading = true;
        this.errorMessage = '';

        try {
            const caseId = await submitComplaint({
                orderId: this.recordId,
                reason: this.reason,
                expectedRefundType: this.expectedRefundType,
                selectedOrderItemsId: this.selectedProductIds
            })
            
            this.dispatchEvent(new ShowToastEvent({
                title: 'Success',
                message: 'Complaint submitted successfully.',
                variant: 'success'
            }));

            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: { recordId: caseId, actionName: 'view' }
            });

            this.dispatchEvent(new CloseActionScreenEvent());
        
        } catch(exception) {
            this.errorMessage = exception.body?.message || 'Something is wrong, try again.';
        } finally {
            this.isLoading = false;
        }
    }
}