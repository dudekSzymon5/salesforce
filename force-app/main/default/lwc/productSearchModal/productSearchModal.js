import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
import getProducts from '@salesforce/apex/ProductSearchController.getProducts';
import getProductFamilies from '@salesforce/apex/ProductSearchController.getProductFamilies';
import createOrder from '@salesforce/apex/ProductSearchController.createOrder';
import applyDiscountsToOrder from '@salesforce/apex/DiscountController.applyDiscountsToOrder';

export default class ProductSearchModal extends NavigationMixin(LightningElement) {
    @api recordId;

    @track step = 'search';
    @track searchName = '';
    @track searchFamily = '';
    @track products = [];
    @track selectedProducts = {};
    @track quantities = {};
    @track isLoading = false;
    @track familyOptions = [{ label: 'All', value: '' }];
    @track appliedDiscounts = [];
    @track _orderId;

    get isSearchStep() { return this.step === 'search'; }
    get isSummaryStep() { return this.step === 'summary'; }
    get isDiscountStep() { return this.step === 'discounts'; }
    get isNextDisabled() { return Object.keys(this.selectedProducts).length === 0; }

    get hasDiscounts() {
        return this.appliedDiscounts && this.appliedDiscounts.length > 0;
    }

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
                { label: 'All', value: '' },
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
            this._orderId = orderId;
            return applyDiscountsToOrder({ 
                orderId: orderId, 
                orderAmount: this.totalAmount 
            });
        })
        .then(discounts => {
            this.appliedDiscounts = discounts || [];
            this.step = 'discounts';
        })
        .catch(error => {
            console.error('Error:', JSON.stringify(error));
            this.step = 'discounts';
            this.appliedDiscounts = [];
        });
    }

    handleFinish() {
        this.dispatchEvent(new CloseActionScreenEvent());
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this._orderId,
                actionName: 'view'
            }
        });
    }
}