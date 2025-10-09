import LightningModal from 'lightning/modal';
import { api, track } from 'lwc';

export default class UniversalModal extends LightningModal {
    @api modalType = 'confirm'; // 'confirm', 'list', 'form', 'custom'
    @api title = 'Modal';
    @api size = 'medium'; // 'small', 'medium', 'large'
    
    // Confirm modal properties
    @api message = '';
    @api confirmLabel = 'Confirm';
    @api cancelLabel = 'Cancel';
    @api requireReason = false;
    @api variant = 'neutral'; // 'neutral', 'brand', 'destructive'
    
    // List modal properties
    @api data = [];
    @api columns = [];
    @api keyField = 'id';
    @api maxHeight = '40vh';
    
    // Form modal properties
    @api formConfig = null; // Dynamic form configuration
    
    // Custom content
    @api customContent = null;
    
    @track formData = {};
    @track reason = '';
    @track loading = false;

    get isConfirmType() {
        return this.modalType === 'confirm';
    }

    get isListType() {
        return this.modalType === 'list';
    }

    get isFormType() {
        return this.modalType === 'form';
    }

    get isCustomType() {
        return this.modalType === 'custom';
    }

    get isConfirmDisabled() {
        if (this.modalType === 'confirm') {
            return this.requireReason && !this.reason?.trim();
        }
        if (this.modalType === 'form') {
            return this.loading || !this.isFormValid();
        }
        return false;
    }

    get confirmButtonVariant() {
        return this.variant || 'neutral';
    }

    get hasData() {
        return this.data && this.data.length > 0;
    }

    get formFields() {
        return this.formConfig?.fields || [];
    }

    connectedCallback() {
        if (this.modalType === 'form' && this.formConfig) {
            this.initializeFormData();
        }
    }

    initializeFormData() {
        const initialData = {};
        if (this.formConfig?.fields) {
            this.formConfig.fields.forEach(field => {
                initialData[field.name] = field.defaultValue || '';
            });
        }
        this.formData = initialData;
    }

    isFormValid() {
        if (!this.formConfig?.fields) {
            return true;
        }
        
        return this.formConfig.fields.every(field => {
            if (field.required) {
                const value = this.formData[field.name];
                return value !== null && value !== undefined && String(value).trim() !== '';
            }
            return true;
        });
    }

    handleReasonChange(event) {
        this.reason = event.target.value;
    }

    handleFieldChange(event) {
        const fieldName = event.target.name || event.target.dataset.fieldName;
        const value = event.detail?.value !== undefined ? event.detail.value : event.target.value;
        
        this.formData = {
            ...this.formData,
            [fieldName]: value
        };
    }

    handleConfirm() {
        if (this.modalType === 'confirm') {
            if (this.requireReason && !this.reason?.trim()) {
                return;
            }
            this.close({ 
                confirmed: true, 
                reason: this.reason,
                action: 'confirm'
            });
        } else if (this.modalType === 'form') {
            if (!this.isFormValid()) {
                return;
            }
            this.loading = true;
            this.close({ 
                confirmed: true, 
                formData: this.formData,
                action: 'submit'
            });
        } else if (this.modalType === 'list') {
            this.close({ 
                confirmed: true,
                action: 'close'
            });
        } else {
            this.close({ 
                confirmed: true,
                action: 'confirm'
            });
        }
    }

    handleCancel() {
        this.close({ 
            confirmed: false,
            action: 'cancel'
        });
    }

    handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;
        
        this.close({
            confirmed: true,
            action: 'rowAction',
            rowAction: action,
            rowData: row
        });
    }
}
