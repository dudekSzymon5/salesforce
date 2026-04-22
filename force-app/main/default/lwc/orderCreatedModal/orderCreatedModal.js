import { LightningElement, track } from 'lwc';
import { subscribe, unsubscribe } from 'lightning/empApi';

export default class OrderCreatedModal extends LightningElement {
    @track showModal = false;
    @track orderUrl = '';
    @track contractUrl = '';
    subscription = null;
    channelName = '/event/Order_Created__e';

    connectedCallback() {
        this.subscribeToEvent();
    }

    disconnectedCallback() {
        unsubscribe(this.subscription);
    }

    subscribeToEvent() {
        subscribe(this.channelName, -1, (event) => {
            const orderId = event.data.payload.Order_Id__c;
            const contractId = event.data.payload.Contract_Id__c;
            this.orderUrl = `/lightning/r/Order/${orderId}/view`;
            this.contractUrl = `/lightning/r/Contract/${contractId}/view`;
            this.showModal = true;
        }).then(response => {
            this.subscription = response;
        });
    }

    goToOrder() {
        window.open(this.orderUrl, '_blank');
    }

    goToContract() {
        window.open(this.contractUrl, '_blank');
    }

    closeModal() {
        this.showModal = false;
    }
}