/**
 * UNIVERSAL MODAL - Usage Examples
 * ================================
 * 
 * This file demonstrates how to use the UniversalModal component
 * for different modal types: confirm, list, form, and custom
 */

import UniversalModal from 'c/universalModal';
import UniversalModalHelper from 'c/universalModalHelper';

// ============================================================
// EXAMPLE 1: CONFIRMATION MODAL (Simple Yes/No)
// ============================================================
async function showSimpleConfirmation() {
    const result = await UniversalModal.open({
        size: 'small',
        modalType: 'confirm',
        title: 'Confirm Action',
        message: 'Are you sure you want to proceed?',
        confirmLabel: 'Yes, Proceed',
        cancelLabel: 'Cancel',
        variant: 'brand'
    });

    if (result && result.confirmed) {
        console.log('User confirmed');
    } else {
        console.log('User cancelled');
    }
}

// ============================================================
// EXAMPLE 2: CONFIRMATION MODAL (With Required Reason)
// ============================================================
async function showDeleteConfirmation() {
    const result = await UniversalModal.open({
        size: 'small',
        modalType: 'confirm',
        title: 'Confirm Deletion',
        message: 'Are you sure you want to delete this work item?',
        confirmLabel: 'Delete',
        cancelLabel: 'Cancel',
        variant: 'destructive',
        requireReason: true
    });

    if (result && result.confirmed) {
        console.log('Deleting with reason:', result.reason);
        // Call your delete method here
    }
}

// ============================================================
// EXAMPLE 3: LIST MODAL (Display Data Table)
// ============================================================
async function showListModal() {
    const data = [
        { id: '1', name: 'Task 1', status: 'Active', priority: 'High' },
        { id: '2', name: 'Task 2', status: 'Completed', priority: 'Medium' },
        { id: '3', name: 'Task 3', status: 'Active', priority: 'Low' }
    ];

    const columns = [
        { label: 'Name', fieldName: 'name', type: 'text' },
        { label: 'Status', fieldName: 'status', type: 'text' },
        { label: 'Priority', fieldName: 'priority', type: 'text' },
        {
            type: 'action',
            typeAttributes: {
                rowActions: [
                    { label: 'View', name: 'view' },
                    { label: 'Edit', name: 'edit' }
                ]
            }
        }
    ];

    const result = await UniversalModal.open({
        size: 'medium',
        modalType: 'list',
        title: 'Available Work Items',
        data: data,
        columns: columns,
        keyField: 'id',
        maxHeight: '500px'
    });

    if (result && result.action === 'rowAction') {
        console.log('Row action:', result.rowAction, 'on row:', result.rowData);
    }
}

// ============================================================
// EXAMPLE 4: FORM MODAL (Dynamic Form Fields)
// ============================================================
async function showFormModal() {
    // Create form fields using helper
    const fields = [
        UniversalModalHelper.createField('title', 'text', {
            label: 'Title',
            required: true,
            placeholder: 'Enter work item title',
            icon: 'utility:text'
        }),
        UniversalModalHelper.createField('description', 'textarea', {
            label: 'Description',
            placeholder: 'Enter description',
            rows: 4,
            icon: 'utility:description'
        }),
        UniversalModalHelper.createField('workItemType', 'combobox', {
            label: 'Work Item Type',
            required: true,
            placeholder: 'Select type',
            options: [
                { label: 'Task', value: 'Task' },
                { label: 'Bug', value: 'Bug' },
                { label: 'Epic', value: 'Epic' }
            ],
            icon: 'utility:task',
            defaultValue: 'Task'
        }),
        UniversalModalHelper.createField('priority', 'combobox', {
            label: 'Priority',
            required: true,
            options: [
                { label: '1 - Critical', value: '1' },
                { label: '2 - High', value: '2' },
                { label: '3 - Medium', value: '3' },
                { label: '4 - Low', value: '4' }
            ],
            defaultValue: '2',
            icon: 'utility:priority',
            helpText: 'Select the priority level for this work item'
        })
    ];

    const formConfig = UniversalModalHelper.createFormConfig(fields);

    const result = await UniversalModal.open({
        size: 'large',
        modalType: 'form',
        title: 'Create New Work Item',
        formConfig: formConfig,
        confirmLabel: 'Create',
        cancelLabel: 'Cancel',
        variant: 'brand'
    });

    if (result && result.confirmed) {
        console.log('Form submitted with data:', result.formData);
        // result.formData will contain: { title: '...', description: '...', workItemType: '...', priority: '...' }
    }
}

// ============================================================
// EXAMPLE 5: REPLACING EXISTING MODALS
// ============================================================

// BEFORE: Using ConfirmModal
/*
const result = await ConfirmModal.open({
    size: 'small',
    title: 'Confirm Deletion',
    message: 'Are you sure you want to delete the record?',
    confirmLabel: 'Delete',
    cancelLabel: 'Cancel'
});
*/

// AFTER: Using UniversalModal
async function replaceConfirmModal() {
    const result = await UniversalModal.open({
        size: 'small',
        modalType: 'confirm',  // Just add this line
        title: 'Confirm Deletion',
        message: 'Are you sure you want to delete the record?',
        confirmLabel: 'Delete',
        cancelLabel: 'Cancel',
        variant: 'destructive'
    });

    if (result && result.confirmed) {
        // Handle confirmation
    }
}

// BEFORE: Using GenericModal
/*
await GenericModal.open({
    size: 'medium',
    title: 'List',
    data: items,
    columns: columns
});
*/

// AFTER: Using UniversalModal
async function replaceGenericModal() {
    await UniversalModal.open({
        size: 'medium',
        modalType: 'list',  // Just add this line
        title: 'List',
        data: items,
        columns: columns,
        keyField: 'id'
    });
}

// BEFORE: Using AzureDevOpsWorkItemCreator (dedicated component)
/*
const result = await AzureDevOpsWorkItemCreator.open({
    size: 'large',
    modalTitle: 'Create New Work Item'
});
*/

// AFTER: Using UniversalModal with dynamic form
async function replaceWorkItemCreator() {
    // First, fetch your configurations and options
    const configOptions = await getAvailableConfigurations();
    const typeOptions = await getWorkItemTypes();
    const priorityOptions = await getPriorities();

    // Create form fields dynamically
    const fields = [
        UniversalModalHelper.createField('configuration', 'combobox', {
            label: 'Azure DevOps Configuration',
            required: true,
            options: configOptions,
            icon: 'utility:connected_apps'
        }),
        UniversalModalHelper.createField('workItemType', 'combobox', {
            label: 'Work Item Type',
            required: true,
            options: typeOptions,
            icon: 'utility:task'
        }),
        UniversalModalHelper.createField('title', 'text', {
            label: 'Title',
            required: true,
            placeholder: 'Enter work item title',
            icon: 'utility:text'
        }),
        UniversalModalHelper.createField('description', 'textarea', {
            label: 'Description',
            placeholder: 'Enter detailed description (optional)',
            rows: 4,
            icon: 'utility:description'
        }),
        UniversalModalHelper.createField('priority', 'combobox', {
            label: 'Priority',
            options: priorityOptions,
            defaultValue: '2',
            icon: 'utility:priority'
        })
    ];

    const formConfig = UniversalModalHelper.createFormConfig(fields);

    const result = await UniversalModal.open({
        size: 'large',
        modalType: 'form',
        title: 'Create New Work Item',
        formConfig: formConfig,
        confirmLabel: 'Create Work Item',
        cancelLabel: 'Cancel',
        variant: 'brand'
    });

    if (result && result.confirmed) {
        // Call Apex to create work item
        const createResult = await createWorkItem({
            configName: result.formData.configuration,
            workItemType: result.formData.workItemType,
            title: result.formData.title,
            description: result.formData.description,
            priority: parseInt(result.formData.priority, 10)
        });

        return createResult;
    }
}

// ============================================================
// BENEFITS OF UNIVERSAL MODAL
// ============================================================
/*
1. SINGLE COMPONENT: One modal handles all use cases
2. CONSISTENT API: Same pattern for all modals
3. DYNAMIC FORMS: No need to create new components for forms
4. EASY MIGRATION: Minimal changes to existing code
5. MAINTAINABLE: Update one component, all modals benefit
6. FLEXIBLE: Supports confirm, list, form, and custom content
7. TYPE-SAFE: Configuration-driven, reduces errors
*/
