import LightningModal from 'lightning/modal';
import { api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { showSuccessToast, showErrorToast } from 'c/toastUtils';
import getAvailableStatesForType from '@salesforce/apex/AzureDevOpsController.getAvailableStatesForType';
import updateWorkItem from '@salesforce/apex/AzureDevOpsController.updateWorkItem';
import getPriorities from '@salesforce/apex/AzureDevOpsController.getPriorities';

export default class AzureDevOpsWorkItemEditor extends LightningModal {
    @api workItemId;
    @api workItemType;
    @api initialTitle = '';
    @api initialDescription = '';
    @api initialState = '';
    @api initialPriority = '2';
    @api configName;
    @api currentTitle;
    @api currentDescription;
    @api currentState;
    @api currentPriority;

    @track title = '';
    @track description = '';
    @track state = '';
    @track priority = '2';
    @track stateOptions = [];
    @track isSaving = false;
    @track priorityOptions = [];

    get modalTitle() {
        return `Edit ${this.workItemType || 'Work Item'}`;
    }
    get isLoading() {
        return this.isSaving;
    }
    get selectedState() {
        return this.state;
    }
    get selectedPriority() {
        return this.priority;
    }
    get priorityOptions() {
        return [
            { label: '1', value: '1' },
            { label: '2', value: '2' },
            { label: '3', value: '3' },
            { label: '4', value: '4' }
        ];
    }
    get selectedStateDescription() {
        const s = this.stateOptions.find(x => x.value === this.state);
        return s ? s.label : '';
    }
    get hasChanges() {
        return (
            this.title !== (this.initialTitle || '') ||
            this.description !== (this.initialDescription || '') ||
            this.state !== (this.initialState || '') ||
            this.priority !== (this.initialPriority || '2')
        );
    }
    get isSaveDisabled() {
        return this.isSaving || !this.hasChanges || !this.title?.trim();
    }

    connectedCallback() {
        this.title = this.currentTitle ?? this.initialTitle ?? '';
        this.description = this.currentDescription ?? this.initialDescription ?? '';
        this.state = this.currentState ?? this.initialState ?? '';
        this.priority = String(this.currentPriority ?? this.initialPriority ?? '2');
    }

    @wire(getAvailableStatesForType, { workItemType: '$workItemType' })
    wiredStates({ error, data }) {
        if (data) this.stateOptions = data.map(s => ({ label: s.label, value: s.value }));
        else if (error) showErrorToast(this, 'Error loading states', error.body?.message);
    }

    @wire(getPriorities)
    wiredPriorities({ error, data }) {
        if (data) {
            this.priorityOptions = data.map(p => ({ label: p.label, value: p.value }));
            if (!this.priorityOptions || this.priorityOptions.length === 0) {
                this.priorityOptions = [
                    { label: '1', value: '1' },
                    { label: '2', value: '2' },
                    { label: '3', value: '3' },
                    { label: '4', value: '4' }
                ];
            }
        } else if (error) {
            this.priorityOptions = [
                { label: '1', value: '1' },
                { label: '2', value: '2' },
                { label: '3', value: '3' },
                { label: '4', value: '4' }
            ];
            showErrorToast(this, 'Error loading priorities', error.body?.message || String(error));
        }
    }

    handleInputChange(e) {
        const name = e.target.name;
        this[name] = e.detail?.value ?? e.target.value;
    }
    handleStateChange(e) {
        this.state = e.detail?.value ?? e.target.value;
    }
    handlePriorityChange(e) {
        this.priority = String(e.detail?.value ?? e.target.value);
    }
    handleReset() {
        this.title = this.initialTitle || '';
        this.description = this.initialDescription || '';
        this.state = this.initialState || '';
        this.priority = this.initialPriority || '2';
    }

    async handleSave() {
        if (!this.configName || !this.workItemId) {
            showErrorToast(this, 'Validation Error', 'Missing configuration or work item id');
            return;
        }
        this.isSaving = true;
        try {
            const workItemIdInt = Number.isInteger(this.workItemId) ? this.workItemId : parseInt(this.workItemId, 10);
            const priorityInt = Number.isInteger(this.priority) ? this.priority : parseInt(this.priority, 10);
            const res = await updateWorkItem({
                configName: this.configName,
                workItemId: workItemIdInt,
                title: this.title,
                description: this.description,
                state: this.state,
                priority: priorityInt
            });
            if (res && res.success) {
                showSuccessToast(this, 'Saved', res.message || 'Work item updated');
                this.close({
                    success: true,
                    workItemId: workItemIdInt,
                    result: res
                });
            } else {
                showErrorToast(this, 'Update Failed', res && res.message ? res.message : 'Unknown error');
            }
        } catch (err) {
            showErrorToast(this, 'Unexpected Error', err?.body?.message || String(err));
        } finally {
            this.isSaving = false;
        }
    }

    handleCancel() {
        this.close({ success: false });
    }
}

