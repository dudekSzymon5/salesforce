import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
import getProducts from '@salesforce/apex/ProductSearchController.getProducts';
import getProductFamilies from '@salesforce/apex/ProductSearchController.getProductFamilies';
import createOrder from '@salesforce/apex/ProductSearchController.createOrder';

export default class ProductSearchModal extends NavigationMixin(LightningElement) {
    @api recordId;

    @track step = 'search'; // 'search' | 'summary'
    @track searchName = '';
    @track searchFamily = '';
    @track products = [];
    @track selectedProducts = {}; // { pricebookEntryId: { ...product, quantity } }
    @track quantities = {};
    @track isLoading = false;
    @track familyOptions = [{ label: 'Wszystkie', value: '' }];

    get isSearchStep() { return this.step === 'search'; }
    get isSummaryStep() { return this.step === 'summary'; }
    get isNextDisabled() { return Object.keys(this.selectedProducts).length === 0; }

    get selectedProductsList() {
        return Object.values(this.selectedProducts).map(p => ({
            ...p,
            total: p.unitPrice * p.quantity
        }));
    }

    get totalAmount() {
        return this.selectedProductsList.reduce((sum, p) => sum + p.total, 0);
    }

    @wire(getProductFamilies)
    wiredFamilies({ data, error }) {
        if (data) {
            this.familyOptions = [
                { label: 'Wszystkie', value: '' },
                ...data.map(f => ({ label: f, value: f }))
            ];
        }
    }

    handleSearchName(event) {
        this.searchName = event.target.value;
    }

    handleSearchFamily(event) {
        this.searchFamily = event.target.value;
    }

    handleSearch() {
        this.isLoading = true;
        getProducts({
            searchName: this.searchName,
            searchFamily: this.searchFamily,
            opportunityId: this.recordId
        })
        .then(data => {
            this.products = data;
            this.isLoading = false;
        })
        .catch(() => {
            this.isLoading = false;
        });
    }

    handleProductSelect(event) {
        const id = event.target.dataset.id;
        const checked = event.target.checked;
        const product = this.products.find(p => p.Id === id);

        if (checked) {
            this.selectedProducts = {
                ...this.selectedProducts,
                [id]: {
                    pricebookEntryId: id,
                    name: product.Product2.Name,
                    unitPrice: product.UnitPrice,
                    quantity: this.quantities[id] || 1
                }
            };
        } else {
            const updated = { ...this.selectedProducts };
            delete updated[id];
            this.selectedProducts = updated;
        }
    }

    handleQuantityChange(event) {
        const id = event.target.dataset.id;
        const qty = parseFloat(event.target.value) || 1;
        this.quantities = { ...this.quantities, [id]: qty };

        if (this.selectedProducts[id]) {
            this.selectedProducts = {
                ...this.selectedProducts,
                [id]: { ...this.selectedProducts[id], quantity: qty }
            };
        }
    }

    handleNext() {
        this.step = 'summary';
    }

    handleBack() {
        this.step = 'search';
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleSubmit() {
        const items = this.selectedProductsList.map(p => ({
            pricebookEntryId: p.pricebookEntryId,
            quantity: p.quantity,
            unitPrice: p.unitPrice
        }));

        createOrder({ opportunityId: this.recordId, items })
        .then(orderId => {
            this.dispatchEvent(new CloseActionScreenEvent());
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: orderId,
                    actionName: 'view'
                }
            });
        });
    }
}