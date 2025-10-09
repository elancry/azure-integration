import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { showSuccessToast, showErrorToast, showInfoToast } from 'c/toastUtils';
import getWorkItems from '@salesforce/apex/AzureDevOpsController.getWorkItems';
import getAvailableConfigurations from '@salesforce/apex/AzureDevOpsController.getAvailableConfigurations';
import deleteWorkItemWithReason from '@salesforce/apex/AzureDevOpsController.deleteWorkItemWithReason';
import UniversalModal from 'c/universalModal';
import AzureDevOpsWorkItemCreator from 'c/azureDevOpsWorkItemCreator';
import AzureDevOpsWorkItemEditor from 'c/azureDevOpsWorkItemEditor';
import hasEditPermission from '@salesforce/apex/AzureDevOpsController.hasEditPermission';

export default class AzureDevOpsWorkItemManager extends LightningElement {
    @api
    maxRows = 10;
    @api
    showHeader = false;
    @api
    showFilters = false;
    @api
    height = '400px';
    @api
    defaultConfiguration = 'standard';


    workItems = [];
    filteredWorkItems = [];
    configurations = [];
    _cachedConfigOptions = null;
    _cachedConfigOptionsForHash = '';
    _cachedTypeFilterOptions = null;
    _cachedTypeFilterHash = '';
    _cachedStateFilterOptions = null;
    _cachedStateFilterHash = '';
    isLoading = false;
    error = null;
    selectedConfig = '';
    selectedTypeFilter = '';
    selectedStateFilter = '';
    searchTerm = '';
    sortedBy = 'title';
    sortedDirection = 'asc';
    workItemStats = { total: 0, inProgress: 0, completed: 0 };

    columns = [];
    hasEdit = false;

    buildColumns() {
        const base = [
            { label: 'ID', fieldName: 'workItemId', type: 'number', sortable: true, initialWidth: 80 },
            { label: 'Title', fieldName: 'title', type: 'text', sortable: true, wrapText: true, initialWidth: 300 },
            { label: 'Type', fieldName: 'workItemType', type: 'text', sortable: true, initialWidth: 120 },
            { label: 'State', fieldName: 'state', type: 'text', sortable: true, initialWidth: 110 },
            { label: 'Assigned To', fieldName: 'assignedTo', type: 'text', sortable: true, initialWidth: 150 },
            { label: 'Created Date', fieldName: 'createdDate', type: 'date', sortable: true, initialWidth: 130 },
            { label: 'Priority', fieldName: 'priority', type: 'text', sortable: true, initialWidth: 100 }
        ];

        const actions = [];
        if (this.hasEdit) {
            actions.push({ label: 'Edit', name: 'edit' });
            actions.push({ label: 'Delete', name: 'delete' });
        }
        actions.push({ label: 'Open in Azure', name: 'open_azure' });

        base.push({
            type: 'action',
            typeAttributes: {
                rowActions: actions
            },
            initialWidth: 100
        });

        return base;
    }

    connectedCallback() {
        this.loadInitialData();
        this.checkPermission();
    }

    async checkPermission() {
        try {
            const res = await hasEditPermission();
            this.hasEdit = !!res;
        } catch (e) {
            this.hasEdit = false;
        }
        this.columns = this.buildColumns();
    }

    get configOptions() {
        const hash = JSON.stringify(this.configurations || []);
        if (this._cachedConfigOptionsForHash !== hash) {
            this._cachedConfigOptions = [
                { label: 'All Configurations', value: '' },
                ...this.configurations.map(c => ({ label: c.label, value: c.value }))
            ];
            this._cachedConfigOptionsForHash = hash;
        }
        return this._cachedConfigOptions;
    }
    get typeFilterOptions() {
        const hash = JSON.stringify(this.workItems.map(i => i.workItemType || ''));
        if (this._cachedTypeFilterHash !== hash) {
            this._cachedTypeFilterOptions = [
                { label: 'All Types', value: '' },
                ...Array.from(new Set(this.workItems.map(i => i.workItemType))).map(t => ({ label: t, value: t }))
            ];
            this._cachedTypeFilterHash = hash;
        }
        return this._cachedTypeFilterOptions;
    }
    get stateFilterOptions() {
        const hash = JSON.stringify(this.workItems.map(i => i.state || ''));
        if (this._cachedStateFilterHash !== hash) {
            this._cachedStateFilterOptions = [
                { label: 'All States', value: '' },
                ...Array.from(new Set(this.workItems.map(i => i.state))).map(s => ({ label: s, value: s }))
            ];
            this._cachedStateFilterHash = hash;
        }
        return this._cachedStateFilterOptions;
    }
    get showEmptyState() {
        return !this.isLoading && this.filteredWorkItems.length === 0;
    }

    async loadInitialData() {
        this.isLoading = true;
        try {
            this.configurations = (await getAvailableConfigurations()) || [];
            if (this.configurations.length) {
                this.selectedConfig = this.configurations[0].value;
                await this.loadWorkItems();
            }
        } catch (e) {
            this.handleError('Failed to load', e);
        } finally {
            this.isLoading = false;
        }
    }

    get createDisabled() {
        return !this.hasEdit;
    }
    async loadWorkItems() {
        if (!this.selectedConfig) return;
        this.isLoading = true;
        try {
            const res = await getWorkItems({
                configName: this.selectedConfig,
                workItemType: this.selectedTypeFilter || null,
                state: this.selectedStateFilter || null,
                maxResults: this.maxRows || 50
            });
            if (res && res.success) {
                this.workItems = (res.workItems || []).map(w => ({ ...w, id: `${w.workItemId}` }));
                this.applyFilters();
                this.calculateStats();
            } else this.handleError('Failed to load work items', res && res.message);
        } catch (e) {
            this.handleError('Failed to load work items', e);
        } finally {
            this.isLoading = false;
        }
    }

    applyFilters() {
        let f = [...this.workItems];
        const s = this.searchTerm?.toLowerCase();
        if (s)
            f = f.filter(
                i =>
                    (i.title || '').toLowerCase().includes(s) ||
                    String(i.workItemId).includes(s) ||
                    (i.assignedTo || '').toLowerCase().includes(s)
            );
        if (this.selectedTypeFilter) f = f.filter(i => i.workItemType === this.selectedTypeFilter);
        if (this.selectedStateFilter) f = f.filter(i => i.state === this.selectedStateFilter);
        this.sortData(f);
        this.filteredWorkItems = f;
    }
    sortData(d) {
        const k = this.sortedBy;
        const rev = this.sortedDirection === 'desc' ? -1 : 1;
        d.sort((a, b) => {
            let va = a[k],
                vb = b[k];
            if (typeof va === 'string') {
                va = va.toLowerCase();
                vb = vb.toLowerCase();
            }
            return va < vb ? -1 * rev : va > vb ? 1 * rev : 0;
        });
    }
    calculateStats() {
        this.workItemStats.total = this.workItems.length;
        this.workItemStats.inProgress = this.workItems.filter(i =>
            ['Active', 'Doing', 'In Progress'].includes(i.state)
        ).length;
        this.workItemStats.completed = this.workItems.filter(i =>
            ['Closed', 'Done', 'Resolved'].includes(i.state)
        ).length;
    }

    async handleCreateWorkItem() {
        const result = await AzureDevOpsWorkItemCreator.open({
            size: 'large',
            modalTitle: 'Create New Work Item'
        });

        if (result && result.success) {
            showSuccessToast(this, 'Success!', result.message || 'Work item created');
            this.loadWorkItems();
        }
    }
    handleRefresh() {
        this.loadWorkItems();
    }
    handleConfigFilterChange(e) {
        this.selectedConfig = e.detail.value;
        this.loadWorkItems();
    }
    handleTypeFilterChange(e) {
        this.selectedTypeFilter = e.detail.value;
        this.applyFilters();
    }
    handleStateFilterChange(e) {
        this.selectedStateFilter = e.detail.value;
        this.applyFilters();
    }
    handleSearchChange(e) {
        this.searchTerm = e.target.value;
        clearTimeout(this._searchT);
        this._searchT = setTimeout(() => this.applyFilters(), 250);
    }

    handleRowAction(e) {
        const a = e.detail.action && e.detail.action.name,
            r = e.detail.row;
        if (!a || !r) return;
        if (a === 'open_azure') {
            if (r.url) {
                try {
                    window.open(r.url, '_blank');
                } catch (err) {
                    showErrorToast(this, 'Open Failed', 'Unable to open work item URL.');
                }
            } else showInfoToast(this, 'No URL', 'No external URL available');
        } else if (a === 'edit') {
            this.handleEditAction(r);
        } else if (a === 'delete') {
            this.handleDeleteAction(r);
        } else showInfoToast(this, 'Action', 'Unknown action: ' + a);
    }

    async handleEditAction(row) {
        const result = await AzureDevOpsWorkItemEditor.open({
            size: 'medium',
            workItemId: row.workItemId || row.id,
            configName: this.selectedConfig,
            currentTitle: row.title || '',
            currentDescription: row.description || '',
            currentState: row.state || '',
            currentPriority: row.priority || '2',
            workItemType: row.workItemType || '',
            initialTitle: row.title || '',
            initialDescription: row.description || '',
            initialState: row.state || '',
            initialPriority: row.priority || '2'
        });

        if (result && result.success) {
            showSuccessToast(this, 'Updated', 'Work item updated successfully');
            this.loadWorkItems();
        }
    }

    async handleDeleteAction(row) {
        const id = row.workItemId || row.id;
        const conf = this.selectedConfig;
        
        const modalResult = await UniversalModal.open({
            size: 'small',
            modalType: 'confirm',
            title: 'Confirm Deletion',
            message: 'Are you sure you want to delete the record?',
            confirmLabel: 'Delete',
            cancelLabel: 'Cancel',
            variant: 'destructive',
            requireReason: false
        });

        if (!modalResult || !modalResult.confirmed) {
            return;
        }

        try {
            const res = await deleteWorkItemWithReason({ 
                configName: conf, 
                workItemId: id, 
                reason: modalResult.reason || null 
            });
            if (res && res.success) {
                showSuccessToast(this, 'Deleted', res.message || 'Work item deleted');
                this.loadWorkItems();
            } else {
                showErrorToast(this, 'Delete Failed', res && res.message ? res.message : 'Unknown error');
            }
        } catch (e) {
            this.handleError('Delete failed', e);
        }
    }

    handleSort(e) {
        this.sortedBy = e.detail.fieldName;
        this.sortedDirection = e.detail.sortDirection;
        this.applyFilters();
    }
    handleError(title, err) {
        this.error = err;
        try {
            this.dispatchEvent(
                new ShowToastEvent({ title, message: err && err.message ? err.message : String(err), variant: 'error' })
            );
        } catch (_) {}
    }
}

