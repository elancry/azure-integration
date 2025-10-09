import { LightningElement } from 'lwc';
import { showSuccessToast, showErrorToast } from 'c/toastUtils';
import getWorkItems from '@salesforce/apex/AzureDevOpsController.getWorkItems';
import deleteWorkItemWithReason from '@salesforce/apex/AzureDevOpsController.deleteWorkItemWithReason';
import UniversalModal from 'c/universalModal';

export default class AzureWorkItemList extends LightningElement {
    configName;
    maxRows = 25;

    workItems = [];
    isLoading = false;
    _lastWorkItemsSerialized = '';

    columns = [
        { label: 'ID', fieldName: 'workItemId', type: 'number' },
        { label: 'Title', fieldName: 'title', type: 'text' },
        { label: 'Type', fieldName: 'workItemType', type: 'text' },
        { type: 'action', typeAttributes: { rowActions: [{ label: 'Delete', name: 'delete' }, { label: 'Edit', name: 'edit' }] } }
    ];

    connectedCallback() {
        this.load();
    }

    async load() {
        if (!this.configName) return;
        this.isLoading = true;
        try {
            const res = await getWorkItems({ configName: this.configName, maxResults: this.maxRows });
            if (res && res.success) {
                const incoming = (res.workItems || []);
                const serialized = JSON.stringify(incoming || []);
                if (serialized !== this._lastWorkItemsSerialized) {
                    this.workItems = incoming.map(w => ({ ...w, id: `${w.workItemId}` }));
                    this._lastWorkItemsSerialized = serialized;
                }
            } else {
                showErrorToast(this, 'Load failed', res && res.message);
            }
        } catch (e) {

             
            
            showErrorToast(this, 'Load failed', e && e.message);
        } finally {
            this.isLoading = false;
        }
    }

    async handleRowAction(e) {
        const a = e.detail.action && e.detail.action.name, r = e.detail.row;
        if (a === 'delete') {
            const modalResult = await UniversalModal.open({
                size: 'small',
                modalType: 'confirm',
                title: 'Confirm Deletion',
                message: 'Are you sure you want to delete the record?',
                confirmLabel: 'Delete',
                cancelLabel: 'Cancel',
                variant: 'destructive'
            });
            
            if (!modalResult || !modalResult.confirmed) {
                return;
            }

            try {
                const res = await deleteWorkItemWithReason({ 
                    configName: this.configName, 
                    workItemId: r.workItemId, 
                    reason: modalResult.reason || null 
                });
                if (res && res.success) {
                    showSuccessToast(this, 'Deleted', res.message || 'Work item deleted');
                    this.load();
                } else {
                    showErrorToast(this, 'Delete failed', res && res.message);
                }
            } catch (err) {
                showErrorToast(this, 'Delete failed', err && err.message);
            }
        }
    }
}

