import LightningModal from 'lightning/modal';
import { api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { showSuccessToast, showErrorToast, showInfoToast } from 'c/toastUtils';
import getAvailableConfigurations from '@salesforce/apex/AzureDevOpsController.getAvailableConfigurations';
import getWorkItemTypes from '@salesforce/apex/AzureDevOpsController.getWorkItemTypes';
import getAvailableStatesForType from '@salesforce/apex/AzureDevOpsController.getAvailableStatesForType';
import createWorkItem from '@salesforce/apex/AzureDevOpsController.createWorkItem';
import hasEditPermission from '@salesforce/apex/AzureDevOpsController.hasEditPermission';
import getPriorities from '@salesforce/apex/AzureDevOpsController.getPriorities';

export default class AzureDevOpsWorkItemCreator extends LightningModal {
    @api modalTitle = 'Create New Work Item';
    
    selectedConfig = '';
    selectedWorkItemType = '';
    title = '';
    description = '';
    selectedState = 'To Do';
    selectedPriority = '2';
    configOptions = [];
    workItemTypeOptions = [];
    stateOptions = [];
    priorityOptions = [];
    isLoading = false;
    showSuccessPanel = false;
    lastCreatedWorkItem = {};

    connectedCallback() {
        this.loadConfigurations();
        this.loadTypes();
        this.loadPriorities();
        this.checkPermission();
    }

    hasEdit = false;

    async checkPermission() {
        try {
            const res = await hasEditPermission();
            this.hasEdit = !!res;
        } catch (e) {
            this.hasEdit = false;
        }
    }

    async loadConfigurations() {
        try {
            const data = await getAvailableConfigurations();
            if (Array.isArray(data)) {
                this.configOptions = data.map(c => ({
                    label: c.label,
                    value: c.value,
                    organization: c.organization,
                    project: c.project
                }));
            }
        } catch (e) {
            showErrorToast(this, 'Error loading configurations', e?.body?.message || String(e));
        }
    }

    async loadTypes() {
        try {
            const data = await getWorkItemTypes();
            if (Array.isArray(data)) this.workItemTypeOptions = data.map(t => ({ label: t.label, value: t.value, description: t.description }));
        } catch (e) {
            showErrorToast(this, 'Error loading types', e?.body?.message || String(e));
        }
    }

    async loadStatesForType() {
        try {
            const data = await getAvailableStatesForType({ workItemType: this.selectedWorkItemType });
            if (Array.isArray(data)) {
                const terminalStates = new Set(['done','closed','resolved']);
                let options = data.map(s => ({ label: s.label, value: s.value, description: s.description }));
                if (this.modalMode) {
                    options = options.filter(o => {
                        const v = (o.value || '').toString().trim().toLowerCase();
                        return !terminalStates.has(v);
                    });
                }
                this.stateOptions = options;

                if (!this.stateOptions.find(opt => opt.value === this.selectedState)) {
                    this.selectedState = this.stateOptions.length ? this.stateOptions[0].value : 'To Do';
                }
            }
        } catch (e) {
            showErrorToast(this, 'Error loading states', e?.body?.message || String(e));
        }
    }

    get selectedConfigDetails() {
        const cfg = this.configOptions.find(c => c.value === this.selectedConfig);
        return cfg ? { organization: cfg.organization, project: cfg.project } : null;
    }
    get selectedWorkItemTypeDescription() {
        const t = this.workItemTypeOptions.find(x => x.value === this.selectedWorkItemType);
        return t ? t.description : '';
    }
    get selectedStateDescription() {
        const s = this.stateOptions.find(x => x.value === this.selectedState);
        return s ? s.description : '';
    }
    async loadPriorities() {
        try {
            const data = await getPriorities();
            if (data && Array.isArray(data) && data.length > 0) {
                this.priorityOptions = data.map(p => ({ label: p.label, value: String(p.value) }));
            } else {
                this.priorityOptions = this.getDefaultPriorityOptions();
            }
        } catch (e) {
            this.priorityOptions = this.getDefaultPriorityOptions();
            showErrorToast(this, 'Error loading priorities', e?.body?.message || String(e));
        }
    }
    getDefaultPriorityOptions() {
        const defaultValues = ['1', '2', '3', '4'];
        return defaultValues.map(v => ({ label: v, value: v }));
    }
    get isCreateDisabled() {
        return this.isLoading || !this.selectedConfig || !this.selectedWorkItemType || !this.title?.trim() || !this.hasEdit;
    }

    get createButtonLabel() {
        return 'Create Work Item';
    }

    handleConfigChange(e) {
        this.selectedConfig = e.detail.value;
    }
    handleWorkItemTypeChange(e) {
        this.selectedWorkItemType = e.detail.value;
        this.loadStatesForType();
    }
    handleInputChange(e) {
        this[e.target.name] = e.detail.value;
    }
    handleStateChange(e) {
        this.selectedState = e.detail.value;
    }
    handlePriorityChange(e) {
        this.selectedPriority = e.detail.value;
    }

    async handleCreateWorkItem() {
        if (!this.hasEdit) {
            showErrorToast(this, 'Permission Denied', 'You do not have permission to create work items.');
            return;
        }
        if (!this.selectedConfig || !this.selectedWorkItemType || !this.title?.trim()) {
            showErrorToast(this, 'Validation Error', 'Configuration, type and title are required');
            return;
        }
        this.isLoading = true;
        try {
            const res = await createWorkItem({
                configName: this.selectedConfig,
                workItemType: this.selectedWorkItemType,
                title: this.title.trim(),
                description: this.description || '',
                state: this.selectedState || 'To Do',
                priority: parseInt(this.selectedPriority, 10)
            });
            if (res && res.success) {
                this.lastCreatedWorkItem = {
                    workItemId: res.workItemId,
                    workItemType: res.workItemType,
                    title: res.title,
                    workItemUrl: res.workItemUrl
                };
                
                this.close({
                    success: true,
                    workItem: this.lastCreatedWorkItem,
                    message: res.message
                });
            } else {
                showErrorToast(this, 'Creation Failed', res && res.message ? res.message : 'Unknown error');
            }
        } catch (err) {
            showErrorToast(this, 'Unexpected Error', err?.body?.message || String(err));
        } finally {
            this.isLoading = false;
        }
    }

    handleCancel() {
        this.close({ success: false });
    }

    resetFormFields() {
        this.title = '';
        this.description = '';
        this.selectedState = 'To Do';
        this.selectedPriority = '2';
    }
}
