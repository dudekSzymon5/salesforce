import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getDiscounts from '@salesforce/apex/DiscountController.getDiscounts';
import getDiscountSettings from '@salesforce/apex/DiscountController.getDiscountSettings';
import saveDiscountSettings from '@salesforce/apex/DiscountController.saveDiscountSettings';
import saveDiscount from '@salesforce/apex/DiscountController.saveDiscount';
import toggleDiscounts from '@salesforce/apex/DiscountController.toggleDiscounts';
import { refreshApex } from '@salesforce/apex';

export default class DiscountManager extends LightningElement {
    @track discounts = [];
    @track selectedIds = [];
    @track strategy = 'Highest Discount';
    @track minPercentage = 0;
    @track showForm = false;
    @track formDiscount = {};
    wiredDiscountsResult;

    strategyOptions = [
        { label: 'Highest Discount', value: 'Highest Discount' },
        { label: 'Lowest Discount', value: 'Lowest Discount' },
        { label: 'Combine Discounts', value: 'Combine Discounts' }
    ];

    typeOptions = [
        { label: 'Recurring', value: 'Recurring' },
        { label: 'One-Time', value: 'One-Time' },
        { label: 'Conditional', value: 'Conditional' }
    ];

    formOptions = [
        { label: 'Percentage', value: 'Percentage' },
        { label: 'Amount', value: 'Amount' }
    ];

    recurrenceOptions = [
        { label: 'Last Day of Month', value: 'Last Day of Month' },
        { label: 'Every Monday', value: 'Every Monday' },
        { label: 'Black Friday', value: 'Black Friday' },
        { label: 'Custom Date', value: 'Custom Date' }
    ];

    get hasDiscounts() {
    return this.discounts && this.discounts.length > 0;
    }

    get formTitle() {
        return this.formDiscount.Id ? 'Edit Discount' : 'New Discount';
    }

    get isRecurring() {
        return this.formDiscount.Type__c === 'Recurring';
    }

    get isConditional() {
        return this.formDiscount.Type__c === 'Conditional';
    }

    @wire(getDiscountSettings)
    wiredSettings({ data }) {
        if (data) {
            this.strategy = data.Discount_Strategy__c;
            this.minPercentage = data.Minimum_Discount_Percentage__c;
        }
    }

    @wire(getDiscounts)
    wiredDiscounts(result) {
        this.wiredDiscountsResult = result;
        if (result.data) {
            this.discounts = result.data.map(d => ({
                ...d,
                activeIcon: d.Is_Active__c ? 'utility:check' : 'utility:close'
            }));
        }
    }

    handleStrategyChange(event) {
        this.strategy = event.target.value;
    }

    handleMinPercentageChange(event) {
        this.minPercentage = event.target.value;
    }

    handleSaveSettings() {
        saveDiscountSettings({ strategy: this.strategy, minPercentage: this.minPercentage })
        .then(() => {
            this.showToast('Success', 'Settings saved', 'success');
        })
        .catch(e => {
            this.showToast('Error', e.body.message, 'error');
        });
    }

    handleSelectAll(event) {
        const checked = event.target.checked;
        this.selectedIds = checked ? this.discounts.map(d => d.Id) : [];
    }

    handleSelectDiscount(event) {
        const id = event.target.dataset.id;
        const checked = event.target.checked;
        if (checked) {
            this.selectedIds = [...this.selectedIds, id];
        } else {
            this.selectedIds = this.selectedIds.filter(i => i !== id);
        }
    }

    handleActivate() {
        if (!this.selectedIds.length) return;
        toggleDiscounts({ discountIds: this.selectedIds, isActive: true })
        .then(() => {
            this.showToast('Success', 'Discounts activated', 'success');
            refreshApex(this.wiredDiscountsResult);
        });
    }

    handleDeactivate() {
        if (!this.selectedIds.length) return;
        toggleDiscounts({ discountIds: this.selectedIds, isActive: false })
        .then(() => {
            this.showToast('Success', 'Discounts deactivated', 'success');
            refreshApex(this.wiredDiscountsResult);
        });
    }

    handleNewDiscount() {
        this.formDiscount = {};
        this.showForm = true;
    }

    handleEditDiscount(event) {
        const id = event.target.dataset.id;
        this.formDiscount = { ...this.discounts.find(d => d.Id === id) };
        this.showForm = true;
    }

    handleFormChange(event) {
        const field = event.target.dataset.field;
        this.formDiscount = { ...this.formDiscount, [field]: event.target.value };
    }

    handleFormCheckbox(event) {
        const field = event.target.dataset.field;
        this.formDiscount = { ...this.formDiscount, [field]: event.target.checked };
    }

    handleCloseForm() {
        this.showForm = false;
        this.formDiscount = {};
    }

    handleSaveDiscount() {
        saveDiscount({ discount: this.formDiscount })
        .then(() => {
            this.showToast('Success', 'Discount saved', 'success');
            this.showForm = false;
            refreshApex(this.wiredDiscountsResult);
        })
        .catch(e => {
            this.showToast('Error', e.body.message, 'error');
        });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}