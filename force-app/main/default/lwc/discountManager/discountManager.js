import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getDiscounts from '@salesforce/apex/DiscountController.getDiscounts';
import getAssignedDiscountIds from '@salesforce/apex/DiscountController.getAssignedDiscountIds';
import getDiscountSettings from '@salesforce/apex/DiscountController.getDiscountSettings';
import saveDiscountSettings from '@salesforce/apex/DiscountController.saveDiscountSettings';
import saveDiscount from '@salesforce/apex/DiscountController.saveDiscount';
import toggleDiscounts from '@salesforce/apex/DiscountController.toggleDiscounts';
import getProductOptions from '@salesforce/apex/DiscountController.getProductOptions';
import { refreshApex } from '@salesforce/apex';
import LABEL_TITLE from '@salesforce/label/c.Discount_Title';
import LABEL_GLOBAL_SETTINGS from '@salesforce/label/c.Discount_GlobalSettings';
import LABEL_STRATEGY from '@salesforce/label/c.Discount_Strategy';
import LABEL_MIN_PERCENTAGE from '@salesforce/label/c.Discount_MinPercentage';
import LABEL_SAVE_SETTINGS from '@salesforce/label/c.Discount_SaveSettings';
import LABEL_DISCOUNTS from '@salesforce/label/c.Discount_Discounts';
import LABEL_ACTIVATE_SELECTED from '@salesforce/label/c.Discount_ActivateSelected';
import LABEL_DEACTIVATE_SELECTED from '@salesforce/label/c.Discount_DeactivateSelected';
import LABEL_NEW_DISCOUNT from '@salesforce/label/c.Discount_NewDiscount';
import LABEL_COL_FORM from '@salesforce/label/c.Discount_ColForm';
import LABEL_COL_SCHEDULE from '@salesforce/label/c.Discount_ColSchedule';
import LABEL_COL_ACTIONS from '@salesforce/label/c.Discount_ColActions';
import LABEL_EDIT from '@salesforce/label/c.Discount_Edit';
import LABEL_EDIT_TITLE from '@salesforce/label/c.Discount_EditTitle';
import LABEL_NEW_TITLE from '@salesforce/label/c.Discount_NewTitle';
import LABEL_DISCOUNT_FORM from '@salesforce/label/c.Discount_Form';
import LABEL_RECURRENCE_PATTERN from '@salesforce/label/c.Discount_RecurrencePattern';
import LABEL_CUSTOM_DATE from '@salesforce/label/c.Discount_CustomDateLabel';
import LABEL_MIN_ORDER_AMOUNT from '@salesforce/label/c.Discount_MinOrderAmount';
import LABEL_CANCEL from '@salesforce/label/c.Common_Cancel';
import LABEL_SAVE from '@salesforce/label/c.Common_Save';
import LABEL_NAME from '@salesforce/label/c.Common_Name';
import LABEL_SELECT from '@salesforce/label/c.Common_Select';
import LABEL_SELECT_ALL from '@salesforce/label/c.Common_SelectAll';
import LABEL_ACTIVE from '@salesforce/label/c.Common_Active';
import LABEL_TYPE from '@salesforce/label/c.Common_Type';
import LABEL_VALUE from '@salesforce/label/c.Common_Value';
import LABEL_START_DATE from '@salesforce/label/c.Common_StartDate';
import LABEL_END_DATE from '@salesforce/label/c.Common_EndDate';
import LABEL_CANCEL_CLOSE from '@salesforce/label/c.Common_CancelClose';

export default class DiscountManager extends LightningElement {
    label = {
        title: LABEL_TITLE,
        globalSettings: LABEL_GLOBAL_SETTINGS,
        strategy: LABEL_STRATEGY,
        minPercentage: LABEL_MIN_PERCENTAGE,
        saveSettings: LABEL_SAVE_SETTINGS,
        discounts: LABEL_DISCOUNTS,
        activateSelected: LABEL_ACTIVATE_SELECTED,
        deactivateSelected: LABEL_DEACTIVATE_SELECTED,
        newDiscount: LABEL_NEW_DISCOUNT,
        colForm: LABEL_COL_FORM,
        colSchedule: LABEL_COL_SCHEDULE,
        colActions: LABEL_COL_ACTIONS,
        edit: LABEL_EDIT,
        editTitle: LABEL_EDIT_TITLE,
        newTitle: LABEL_NEW_TITLE,
        discountForm: LABEL_DISCOUNT_FORM,
        recurrencePattern: LABEL_RECURRENCE_PATTERN,
        customDate: LABEL_CUSTOM_DATE,
        minOrderAmount: LABEL_MIN_ORDER_AMOUNT,
        cancel: LABEL_CANCEL,
        save: LABEL_SAVE,
        name: LABEL_NAME,
        select: LABEL_SELECT,
        selectAll: LABEL_SELECT_ALL,
        active: LABEL_ACTIVE,
        type: LABEL_TYPE,
        value: LABEL_VALUE,
        startDate: LABEL_START_DATE,
        endDate: LABEL_END_DATE,
        cancelClose: LABEL_CANCEL_CLOSE
    };

    @track discounts = [];
    @track selectedIds = [];
    @track strategy = 'Highest Discount';
    @track minPercentage = 0;
    @track showForm = false;
    @track formDiscount = {};
    @track productOptions = [];
    assignedDiscountIds = new Set();
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
        return this.formDiscount.Id ? LABEL_EDIT_TITLE : LABEL_NEW_TITLE;
    }

    get isRecurring() {
        return this.formDiscount.Type__c === 'Recurring';
    }

    get isConditional() {
        return this.formDiscount.Type__c === 'Conditional';
    }

    get showDateRange() {
        return this.formDiscount.Type__c === 'One-Time' || this.formDiscount.Type__c === 'Conditional';
    }

    get showCustomDate() {
        return this.formDiscount.Type__c === 'Recurring' && this.formDiscount.Recurrence_Pattern__c === 'Custom Date';
    }

    get isPercentage() {
        return this.formDiscount.Discount_Form__c === 'Percentage';
    }

    get showMinimumQuantity() {
    const target = this.formDiscount.Target_Product__c;
    const trigger = this.formDiscount.Trigger_Product__c;
    return (target && target !== '') || (trigger && trigger !== '');
    }

    get valueMax() {
        return this.isPercentage ? 100 : undefined;
    }

    @wire(getDiscountSettings)
    wiredSettings({ data }) {
        if (data) {
            this.strategy = data.Discount_Strategy__c;
            this.minPercentage = data.Minimum_Discount_Percentage__c;
        }
    }

    @wire(getProductOptions)
    wiredProducts({ data }) {
        if (data) {
            this.productOptions = [
                { label: '— None —', value: '' },
                ...data.map(p => ({ label: p.Name, value: p.Id }))
            ];
        }
    }

    @wire(getAssignedDiscountIds)
    wiredAssignedIds({ data }) {
        if (data) {
            this.assignedDiscountIds = new Set(data);
            this.mapDiscounts();
        }
    }

    @wire(getDiscounts)
    wiredDiscounts(result) {
        this.wiredDiscountsResult = result;
        if (result.data) {
            this.mapDiscounts();
        }
    }

    mapDiscounts() {
        const data = this.wiredDiscountsResult && this.wiredDiscountsResult.data;
        if (!data) return;
        this.discounts = data.map(d => ({
            ...d,
            activeIcon: d.Is_Active__c ? 'utility:check' : 'utility:close',
            isSelected: false,
            scheduleDisplay: d.Type__c === 'Recurring'
                ? (d.Recurrence_Pattern__c === 'Custom Date' && d.Start_Date__c
                    ? 'Annual: ' + d.Start_Date__c
                    : (d.Recurrence_Pattern__c || '-'))
                : ([d.Start_Date__c, d.End_Date__c].filter(Boolean).join(' – ') || 'Any time'),
            targetProductDisplay: d.Target_Product__r ? d.Target_Product__r.Name : '-',
            triggerProductDisplay: d.Trigger_Product__r ? d.Trigger_Product__r.Name : '-',
            isAssigned: this.assignedDiscountIds.has(d.Id)
        }));
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
        this.discounts = this.discounts.map(d => ({ ...d, isSelected: checked }));
    }

    handleSelectDiscount(event) {
        const id = event.target.dataset.id;
        const checked = event.target.checked;
        if (checked) {
            this.selectedIds = [...this.selectedIds, id];
        } else {
            this.selectedIds = this.selectedIds.filter(i => i !== id);
        }
        this.discounts = this.discounts.map(d => d.Id === id ? { ...d, isSelected: checked } : d);
    }

    handleActivate() {
        if (!this.selectedIds.length) return;
        toggleDiscounts({ discountIds: this.selectedIds, isActive: true })
        .then(() => {
            this.showToast('Success', 'Discounts activated', 'success');
            this.selectedIds = [];
            refreshApex(this.wiredDiscountsResult);
        });
    }

    handleDeactivate() {
        if (!this.selectedIds.length) return;
        toggleDiscounts({ discountIds: this.selectedIds, isActive: false })
        .then(() => {
            this.showToast('Success', 'Discounts deactivated', 'success');
            this.selectedIds = [];
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
        const value = event.target.value;
        let updated = { ...this.formDiscount, [field]: value };

        if (field === 'Type__c') {
            if (value === 'Recurring') {
                updated = { ...updated, Start_Date__c: null, End_Date__c: null };
            } else {
                updated = { ...updated, Recurrence_Pattern__c: null, Start_Date__c: null };
            }
        }

        if (field === 'Recurrence_Pattern__c' && value !== 'Custom Date') {
            updated = { ...updated, Start_Date__c: null };
        }

        this.formDiscount = updated;
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
        const discountToSave = { ...this.formDiscount };
        if (!discountToSave.Target_Product__c) discountToSave.Target_Product__c = null;
        if (!discountToSave.Trigger_Product__c) discountToSave.Trigger_Product__c = null;

        if (!discountToSave.Trigger_Product__c && !discountToSave.Target_Product__c) {
            discountToSave.Minimum_Quantity__c = null;
        }

        saveDiscount({ discount: discountToSave })
        .then(() => {
            this.showToast('Success', 'Discount saved', 'success');
            this.showForm = false;
            refreshApex(this.wiredDiscountsResult);
        })
        .catch(e => {
            const errorMessage = e.body?.message || e.message || e.body?.pageErrors?.[0]?.message || 'Wystąpił nieznany błąd podczas zapisu.';
            
            this.showToast('Error', errorMessage, 'error'); 
        });
    }
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}