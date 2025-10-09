public interface IAzureAdapter {
    AzureDevOpsWrappers.AzureResult createWorkItem(String configName, String workItemType, Map<String, Object> fields);
    AzureDevOpsWrappers.AzureResult updateWorkItem(String configName, Integer workItemId, Map<String, Object> fields);
    AzureDevOpsWrappers.AzureResult deleteWorkItem(String configName, Integer workItemId, String reason);
}