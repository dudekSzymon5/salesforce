import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class ComplaintSuccess extends NavigationMixin(LightningElement) {
    @api complaintName;
    @api deadline;
    @api complaintId;

    navigateToComplaint() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.complaintId,
                actionName: 'view'
            }
        });
    }
}