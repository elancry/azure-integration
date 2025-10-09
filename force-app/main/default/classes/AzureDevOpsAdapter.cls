public with sharing class AzureDevOpsAdapter {
    public AzureDevOpsWrappers.AzureResult createWorkItem(String configName, String workItemType, Map<String, Object> fields) {
        return AzureDevOpsService.createWorkItem(configName, workItemType, fields);
    }
    public AzureDevOpsWrappers.AzureResult updateWorkItem(String configName, Integer workItemId, Map<String, Object> fields) {
        return AzureDevOpsService.updateWorkItem(configName, workItemId, fields);
    }
    public AzureDevOpsWrappers.AzureResult deleteWorkItem(String configName, Integer workItemId, String reason) {
        return AzureDevOpsService.deleteWorkItem(configName, workItemId, reason);
    }
}