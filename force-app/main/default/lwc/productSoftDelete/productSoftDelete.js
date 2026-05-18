import { LightningElement, api } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import softDeleteProduct from '@salesforce/apex/ProductSyncSoftDeleteController.softDeleteProduct';

export default class ProductSoftDelete extends LightningElement {
    @api 
    recordId;
    isLoading = false;

    Cancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    Delete() {
        this.isLoading = true;
        softDeleteProduct({ productId: this.recordId })
            .then(() => {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Success',
                    message: 'Product has been deleted.',
                    variant: 'success'
                }));
                notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
                this.dispatchEvent(new CloseActionScreenEvent());
            })
            .catch(error => {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: error.body.message,
                    variant: 'error'
                }));
            })
            .finally(() => {
                this.isLoading = false;
            });
    }
}
