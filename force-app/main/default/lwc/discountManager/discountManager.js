import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getDiscounts from '@salesforce/apex/DiscountController.getDiscounts';
import getAssignedDiscountIds from '@salesforce/apex/DiscountController.getAssignedDiscountIds';
import getDiscountSettings from '@salesforce/apex/DiscountController.getDiscountSettings';
import saveDiscountSettings from '@salesforce/apex/DiscountController.saveDiscountSettings';
import saveDiscount from '@salesforce/apex/DiscountController.saveDiscount';
import toggleDiscounts from '@salesforce/apex/DiscountController.toggleDiscounts';
import getProductOptions from '@salesforce/apex/DiscountController.getProductOptions';
import getProductFamilies from '@salesforce/apex/DiscountController.getProductFamilies';
import getDiscountProducts from '@salesforce/apex/DiscountController.getDiscountProducts';
import saveDiscountProducts from '@salesforce/apex/DiscountController.saveDiscountProducts';
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
import LABEL_SUCCESS from '@salesforce/label/c.Common_Success';
import LABEL_ERROR from '@salesforce/label/c.Common_Error';
import LABEL_NONE from '@salesforce/label/c.Common_None';
import LABEL_MIN_QUANTITY from '@salesforce/label/c.Discount_MinQuantity';
import LABEL_TOAST_SETTINGS_SAVED from '@salesforce/label/c.Discount_ToastSettingsSaved';
import LABEL_TOAST_ACTIVATED from '@salesforce/label/c.Discount_ToastActivated';
import LABEL_TOAST_DEACTIVATED from '@salesforce/label/c.Discount_ToastDeactivated';
import LABEL_TOAST_SAVED from '@salesforce/label/c.Discount_ToastSaved';
import LABEL_ANNUAL_PREFIX from '@salesforce/label/c.Discount_AnnualPrefix';
import LABEL_ANY_TIME from '@salesforce/label/c.Discount_AnyTime';

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
        cancelClose: LABEL_CANCEL_CLOSE,
        success: LABEL_SUCCESS,
        error: LABEL_ERROR,
        none: LABEL_NONE,
        minQuantity: LABEL_MIN_QUANTITY
    };

    @track discounts = [];
    @track selectedIds = [];
    @track strategy = 'Highest Discount';
    @track minPercentage = 0;
    @track showForm = false;
    @track formDiscount = {};
    @track productOptions = [];
    rawFamilies = [];
    @track selectedProductIds = [];
    @track productSearch = '';
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

    conditionTypeOptions = [
        { label: 'Minimum Order Value', value: 'Minimum Order Value' },
        { label: 'Two For One', value: 'Two For One' }
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

    targetApplicationOptions = [
        { label: 'All Products', value: 'All Products' },
        { label: 'Specific Families', value: 'Specific Families' },
        { label: 'Specific Products', value: 'Specific Products' }
    ];

    get showMinQuantityField() {
        return this.isConditional && !this.isTwoForOne && !this.isMinOrderValue;
    }

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

    get isTwoForOne() {
        return this.formDiscount.Type__c === 'Conditional' && this.formDiscount.Condition_Type__c === 'Two For One';
    }

    get isMinOrderValue() {
        return this.formDiscount.Type__c === 'Conditional' && this.formDiscount.Condition_Type__c === 'Minimum Order Value';
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

    get showValueFields() {
        return !this.isTwoForOne;
    }

    get isSpecificFamilies() {
        return this.formDiscount.Target_Application__c === 'Specific Families';
    }

    get isSpecificProducts() {
        return this.formDiscount.Target_Application__c === 'Specific Products';
    }

    get valueMax() {
        return this.isPercentage ? 100 : undefined;
    }

    get filteredProductOptions() {
        const search = (this.productSearch || '').toLowerCase();
        return this.productOptions
            .filter(p => p.label.toLowerCase().includes(search))
            .map(p => ({ ...p, checked: this.selectedProductIds.includes(p.value) }));
    }

    get selectedFamilies() {
        const raw = this.formDiscount.Target_Families__c;
        if (!raw) return [];
        return raw.split(',').map(f => f.trim()).filter(f => f);
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
            this.productOptions = data.map(p => ({ label: p.Name, value: p.Id, family: p.Family }));
        }
    }

    @wire(getProductFamilies)
    wiredFamilies({ data }) {
        if (data) {
            this.rawFamilies = data;
        }
    }

    get familyOptions() {
        const selected = this.selectedFamilies;
        return this.rawFamilies.map(f => ({ label: f, value: f, checked: selected.includes(f) }));
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
                    ? LABEL_ANNUAL_PREFIX + d.Start_Date__c
                    : (d.Recurrence_Pattern__c || '-'))
                : ([d.Start_Date__c, d.End_Date__c].filter(Boolean).join(' – ') || LABEL_ANY_TIME),
            targetDisplay: this.buildTargetDisplay(d),
            isAssigned: this.assignedDiscountIds.has(d.Id)
        }));
    }

    buildTargetDisplay(d) {
        if (!d.Target_Application__c || d.Target_Application__c === 'All Products') return 'All Products';
        if (d.Target_Application__c === 'Specific Families') {
            return 'Families: ' + (d.Target_Families__c || '-');
        }
        return 'Specific Products';
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
            this.showToast(LABEL_SUCCESS, LABEL_TOAST_SETTINGS_SAVED, 'success');
        })
        .catch(e => {
            this.showToast(LABEL_ERROR, e.body ? e.body.message : e.message, 'error');
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
            this.showToast(LABEL_SUCCESS, LABEL_TOAST_ACTIVATED, 'success');
            this.selectedIds = [];
            refreshApex(this.wiredDiscountsResult);
        })
        .catch(e => {
            this.showToast(LABEL_ERROR, e.body ? e.body.message : e.message, 'error');
        });
    }

    handleDeactivate() {
        if (!this.selectedIds.length) return;
        toggleDiscounts({ discountIds: this.selectedIds, isActive: false })
        .then(() => {
            this.showToast(LABEL_SUCCESS, LABEL_TOAST_DEACTIVATED, 'success');
            this.selectedIds = [];
            refreshApex(this.wiredDiscountsResult);
        })
        .catch(e => {
            this.showToast(LABEL_ERROR, e.body ? e.body.message : e.message, 'error');
        });
    }

    handleNewDiscount() {
        this.formDiscount = { Target_Application__c: 'All Products' };
        this.selectedProductIds = [];
        this.productSearch = '';
        this.showForm = true;
    }

    handleEditDiscount(event) {
        const id = event.target.dataset.id;
        this.formDiscount = { ...this.discounts.find(d => d.Id === id) };
        this.selectedProductIds = [];
        this.productSearch = '';
        this.showForm = true;
        if (this.formDiscount.Target_Application__c === 'Specific Products') {
            getDiscountProducts({ discountId: id })
            .then(ids => { this.selectedProductIds = ids || []; });
        }
    }

    handleNextStep() {
        this.formStep = 2;
    }

    handlePrevStep() {
        this.formStep = 1;
    }

    handleFormChange(event) {
        const field = event.target.dataset.field;
        const value = event.target.value;
        let updated = { ...this.formDiscount, [field]: value };

        if (field === 'Type__c') {
            if (value === 'Recurring') {
                updated = { ...updated, Start_Date__c: null, End_Date__c: null, Condition_Type__c: null };
            } else {
                updated = { ...updated, Recurrence_Pattern__c: null, Start_Date__c: null, Condition_Type__c: null };
            }
        }

        if (field === 'Condition_Type__c' && value === 'Two For One') {
            updated = { ...updated, Minimum_Quantity__c: 2, Minimum_Order_Amount__c: null, Value__c: 50, Discount_Form__c: 'Percentage' };
        }
        if (field === 'Condition_Type__c' && value === 'Minimum Order Value') {
            updated = { ...updated, Minimum_Quantity__c: null };
        }

        if (field === 'Recurrence_Pattern__c' && value !== 'Custom Date') {
            updated = { ...updated, Start_Date__c: null };
        }

        if (field === 'Target_Application__c') {
            updated = { ...updated, Target_Families__c: null };
            this.selectedProductIds = [];
        }

        this.formDiscount = updated;
    }

    handleFormCheckbox(event) {
        const field = event.target.dataset.field;
        this.formDiscount = { ...this.formDiscount, [field]: event.target.checked };
    }

    handleFamilyChange(event) {
        const families = event.detail.value;
        this.formDiscount = { ...this.formDiscount, Target_Families__c: families.join(',') };
    }

    handleProductSearch(event) {
        this.productSearch = event.target.value;
    }

    handleProductSelect(event) {
        const id = event.target.dataset.id;
        const checked = event.target.checked;
        if (checked) {
            if (!this.selectedProductIds.includes(id)) {
                this.selectedProductIds = [...this.selectedProductIds, id];
            }
        } else {
            this.selectedProductIds = this.selectedProductIds.filter(pid => pid !== id);
        }
    }

    handleCloseForm() {
        this.showForm = false;
        this.formDiscount = {};
        this.selectedProductIds = [];
        this.formStep = 1;
    }

    handleSaveDiscount() {
        const discountToSave = { ...this.formDiscount };

        saveDiscount({ discount: discountToSave })
        .then(saved => {
            if (discountToSave.Target_Application__c === 'Specific Products') {
                return saveDiscountProducts({ discountId: saved.Id, productIds: this.selectedProductIds });
            }
        })
        .then(() => {
            this.showToast(LABEL_SUCCESS, LABEL_TOAST_SAVED, 'success');
            this.showForm = false;
            this.selectedProductIds = [];
            refreshApex(this.wiredDiscountsResult);
        })
        .catch(e => {
            const errorMessage = e.body?.message || e.message || e.body?.pageErrors?.[0]?.message || 'Wystąpił nieznany błąd podczas zapisu.';
            this.showToast(LABEL_ERROR, errorMessage, 'error');
        });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
