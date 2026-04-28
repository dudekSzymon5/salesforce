import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
import getProducts from '@salesforce/apex/ProductSearchController.getProducts';
import getProductFamilies from '@salesforce/apex/ProductSearchController.getProductFamilies';
import createOrder from '@salesforce/apex/ProductSearchController.createOrder';
import applyDiscountsToOrder from '@salesforce/apex/DiscountController.applyDiscountsToOrder';
import previewDiscounts from '@salesforce/apex/DiscountController.previewDiscounts';
import LABEL_SELECT_PRODUCTS from '@salesforce/label/c.Order_SelectProducts';
import LABEL_PRODUCT_NAME from '@salesforce/label/c.Order_ProductName';
import LABEL_SEARCH_PLACEHOLDER from '@salesforce/label/c.Order_SearchPlaceholder';
import LABEL_PRODUCT_FAMILY from '@salesforce/label/c.Order_ProductFamily';
import LABEL_SEARCH from '@salesforce/label/c.Order_Search';
import LABEL_COL_FAMILY from '@salesforce/label/c.Order_ColFamily';
import LABEL_COL_PRICE from '@salesforce/label/c.Order_ColPrice';
import LABEL_COL_QUANTITY from '@salesforce/label/c.Order_ColQuantity';
import LABEL_ORDER_SUMMARY from '@salesforce/label/c.Order_Summary';
import LABEL_COL_PRODUCT from '@salesforce/label/c.Order_ColProduct';
import LABEL_COL_UNIT_PRICE from '@salesforce/label/c.Order_ColUnitPrice';
import LABEL_COL_TOTAL from '@salesforce/label/c.Order_ColTotal';
import LABEL_SUBTOTAL from '@salesforce/label/c.Order_Subtotal';
import LABEL_APPLIED_DISCOUNTS from '@salesforce/label/c.Order_AppliedDiscounts';
import LABEL_COL_DISCOUNT from '@salesforce/label/c.Order_ColDiscount';
import LABEL_COL_ORIGINAL_PRICE from '@salesforce/label/c.Order_ColOriginalPrice';
import LABEL_COL_DISCOUNT_VALUE from '@salesforce/label/c.Order_ColDiscountValue';
import LABEL_COL_PRICE_AFTER_DISCOUNT from '@salesforce/label/c.Order_ColPriceAfterDiscount';
import LABEL_TOTAL_AFTER_DISCOUNTS from '@salesforce/label/c.Order_TotalAfterDiscounts';
import LABEL_NO_DISCOUNTS from '@salesforce/label/c.Order_NoDiscounts';
import LABEL_SUBMIT from '@salesforce/label/c.Order_Submit';
import LABEL_CANCEL from '@salesforce/label/c.Common_Cancel';
import LABEL_BACK from '@salesforce/label/c.Common_Back';
import LABEL_NEXT from '@salesforce/label/c.Common_Next';
import LABEL_SELECT from '@salesforce/label/c.Common_Select';
import LABEL_NAME from '@salesforce/label/c.Common_Name';

export default class ProductSearchModal extends NavigationMixin(LightningElement) {
    label = {
        selectProducts: LABEL_SELECT_PRODUCTS,
        productName: LABEL_PRODUCT_NAME,
        searchPlaceholder: LABEL_SEARCH_PLACEHOLDER,
        productFamily: LABEL_PRODUCT_FAMILY,
        search: LABEL_SEARCH,
        colFamily: LABEL_COL_FAMILY,
        colPrice: LABEL_COL_PRICE,
        colQuantity: LABEL_COL_QUANTITY,
        orderSummary: LABEL_ORDER_SUMMARY,
        colProduct: LABEL_COL_PRODUCT,
        colUnitPrice: LABEL_COL_UNIT_PRICE,
        colTotal: LABEL_COL_TOTAL,
        subtotal: LABEL_SUBTOTAL,
        appliedDiscounts: LABEL_APPLIED_DISCOUNTS,
        colDiscount: LABEL_COL_DISCOUNT,
        colOriginalPrice: LABEL_COL_ORIGINAL_PRICE,
        colDiscountValue: LABEL_COL_DISCOUNT_VALUE,
        colPriceAfterDiscount: LABEL_COL_PRICE_AFTER_DISCOUNT,
        totalAfterDiscounts: LABEL_TOTAL_AFTER_DISCOUNTS,
        noDiscounts: LABEL_NO_DISCOUNTS,
        submit: LABEL_SUBMIT,
        cancel: LABEL_CANCEL,
        back: LABEL_BACK,
        next: LABEL_NEXT,
        select: LABEL_SELECT,
        name: LABEL_NAME
    };

    _recordId;

    @api
    get recordId() {
        return this._recordId;
    }
    set recordId(value) {
        this._recordId = value;
        if (value) {
            this.handleSearch();
        }
    }

    @track step = 'search';
    @track searchName = '';
    @track searchFamily = '';
    @track products = [];
    @track selectedProducts = {};
    @track quantities = {};
    @track isLoading = false;
    @track familyOptions = [{ label: 'All', value: '' }];
    @track discountPreviews = [];
    @track _orderId;

    get isSearchStep() { return this.step === 'search'; }
    get isSummaryStep() { return this.step === 'summary'; }
    get isNextDisabled() { return Object.keys(this.selectedProducts).length === 0; }

    get hasDiscounts() {
        return this.discountPreviews && this.discountPreviews.length > 0;
    }

    get productsWithSelection() {
        return this.products.map(p => ({
            ...p,
            isSelected: !!this.selectedProducts[p.Id],
            currentQuantity: this.quantities[p.Id] || 1,
            isSinglePurchase: !!p.Product2.Single_Purchase_Only__c
        }));
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

    get discountedTotal() {
        if (!this.hasDiscounts) return this.totalAmount;
        return this.discountPreviews[this.discountPreviews.length - 1].discountedPrice;
    }

    @wire(getProductFamilies)
    wiredFamilies({ data }) {
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
        })
        .catch(() => {})
        .finally(() => {
            this.isLoading = false;
        });
    }

    handleProductSelect(event) {
        const id = event.target.dataset.id;
        const checked = event.target.checked;
        const product = this.products.find(p => p.Id === id);

        if (checked) {
            const isSingle = !!product.Product2.Single_Purchase_Only__c;
            const quantity = isSingle ? 1 : (this.quantities[id] || 1);
            if (isSingle) {
                this.quantities = { ...this.quantities, [id]: 1 };
            }
            this.selectedProducts = {
                ...this.selectedProducts,
                [id]: {
                    pricebookEntryId: id,
                    name: product.Product2.Name,
                    unitPrice: product.UnitPrice,
                    quantity
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
        this.isLoading = true;
        previewDiscounts({ orderAmount: this.totalAmount })
            .then(data => {
                this.discountPreviews = data || [];
            })
            .catch(() => {
                this.discountPreviews = [];
            })
            .finally(() => {
                this.isLoading = false;
                this.step = 'summary';
            });
    }

    handleBack() {
        this.step = 'search';
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleSubmit() {
        this.isLoading = true;
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
            .then(() => {
                this.dispatchEvent(new CloseActionScreenEvent());
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: this._orderId,
                        actionName: 'view'
                    }
                });
            })
            .catch(error => {
                console.error('Error:', JSON.stringify(error));
                this.isLoading = false;
            });
    }
}
