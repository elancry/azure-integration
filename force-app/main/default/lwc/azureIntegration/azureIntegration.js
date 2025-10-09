import getWorkItems from '@salesforce/apex/AzureDevOpsController.getWorkItems';
import createWorkItem from '@salesforce/apex/AzureDevOpsController.createWorkItem';
import updateWorkItem from '@salesforce/apex/AzureDevOpsController.updateWorkItem';
import deleteWorkItemWithReason from '@salesforce/apex/AzureDevOpsController.deleteWorkItemWithReason';

/**
 * Small client-side wrapper around Apex Azure integration endpoints.
 * All methods return the raw Apex response or throw an error.
 */
export async function fetchWorkItems({ configName, workItemType = null, state = null, maxResults = 50 }) {
    return await getWorkItems({ configName, workItemType, state, maxResults });
}

export async function create({ configName, workItemType, title, description, state, priority }) {
    return await createWorkItem({ configName, workItemType, title, description, state, priority });
}

export async function update({ configName, workItemId, title, description, state, priority }) {
    return await updateWorkItem({ configName, workItemId, title, description, state, priority });
}

export async function remove({ configName, workItemId, reason }) {
    return await deleteWorkItemWithReason({ configName, workItemId, reason });
}

