public with sharing class AzureIntegrationFacade {
    public static AzureDevOpsAdapter getAdapter(String configName) { return new AzureDevOpsAdapter(); }
    public static AzureDevOpsWrappers.AzureResult createWorkItem(String configName, String workItemType, Map<String, Object> fields) {
        return getAdapter(configName).createWorkItem(configName, workItemType, fields);
    }
    public static AzureDevOpsWrappers.AzureResult updateWorkItem(String configName, Integer workItemId, Map<String, Object> fields) {
        return getAdapter(configName).updateWorkItem(configName, workItemId, fields);
    }
    public static AzureDevOpsWrappers.AzureResult deleteWorkItem(String configName, Integer workItemId, String reason) {
        return getAdapter(configName).deleteWorkItem(configName, workItemId, reason);
    }
}