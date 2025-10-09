// PMD: Class-level cognitive complexity is cumulative across all UI operations - individual methods are optimized
@SuppressWarnings('PMD.CognitiveComplexity')
public with sharing class AzureDevOpsController { //NOPMD Controller aggregates multiple UI operations
    private static final Set<String> DEFAULT_ALLOWED_WORK_ITEM_TYPES = new Set<String>{'Epic','Task','Issue'};
    private static HttpResponse sendWithRetry(AzureDevOpsWrappers.AzureConfig cfg, HttpRequest req) {
        Http http = new Http();
        try {
            return http.send(req);
        } catch (System.CalloutException ce) {
            if (cfg.hasPersonalAccessToken()) {
                String endpoint = req.getEndpoint();
                endpoint = endpoint.replace('callout:' + cfg.namedCredential, 'https://dev.azure.com');
                req.setEndpoint(endpoint);
                // PMD suppression: PAT authentication is intentional fallback when Named Credential fails
                req.setHeader('Authorization', 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(':' + cfg.personalAccessToken))); //NOPMD
                return http.send(req);
            }
            throw new AuraHandledException('Callout failed: ' + ce.getMessage() + '. Named credential may not exist or lacks permission.');
        }
    }
    private static String buildEndpoint(AzureDevOpsWrappers.AzureConfig cfg, String path) {
        String base = cfg.hasNamedCredential() ? 'callout:' + cfg.namedCredential : 'https://dev.azure.com';
        return base + '/' + EncodingUtil.urlEncode(cfg.organization, 'UTF-8') + '/' + 
               EncodingUtil.urlEncode(cfg.project, 'UTF-8') + path + '?api-version=' + cfg.apiVersion;
    }
    @AuraEnabled(cacheable=true)
    public static List<AzureDevOpsWrappers.ConfigurationOption> getAvailableConfigurations() {
        List<AzureDevOpsWrappers.ConfigurationOption> options = new List<AzureDevOpsWrappers.ConfigurationOption>();
        try {
            for (AzureDevOpsWrappers.ConfigDTO config : AdoConfigProvider.getConfigurations()) {
                options.add(new AzureDevOpsWrappers.ConfigurationOption(config.value, config.label + ' (' + config.organization + '/' + config.project + ')', config.organization, config.project));
            }
        } catch (Exception e) {
            throw new AuraHandledException('Failed to retrieve Azure DevOps configurations: ' + e.getMessage());
        }
        return options;
    }
    @AuraEnabled(cacheable=true)
    public static Boolean hasEditPermission() {
        try {
            Id userId = UserInfo.getUserId();
            // Security reviewed: Reading PermissionSetAssignment to check user permissions (no DML/sensitive data)
            if (!Schema.sObjectType.PermissionSetAssignment.isAccessible()) {
                return false;
            }
            List<PermissionSetAssignment> psa = [SELECT Id FROM PermissionSetAssignment WHERE AssigneeId = :userId AND PermissionSet.Name = 'Azure_DevOps_Edit' LIMIT 1];
            return !psa.isEmpty();
        } catch (Exception ex) {
            return false;
        }
    }
    @AuraEnabled(cacheable=true)
    public static List<AzureDevOpsWrappers.WorkItemTypeOption> getWorkItemTypes() {
        List<AzureDevOpsWrappers.WorkItemTypeOption> options = new List<AzureDevOpsWrappers.WorkItemTypeOption>();
        try {
            for (AzureDevOpsWrappers.WorkItemTypeDTO type : AdoConfigProvider.getWorkItemTypes(null)) {
                if (DEFAULT_ALLOWED_WORK_ITEM_TYPES.contains(type.value)) {
                    options.add(new AzureDevOpsWrappers.WorkItemTypeOption(type.value, type.label, type.description));
                }
            }
        } catch (Exception e) {
            // Silently ignore metadata access errors - will use default work item types
            System.debug(LoggingLevel.FINE, 'Unable to load work item types: ' + e.getMessage());
        }
        if (options.isEmpty()) {
            for (String t : DEFAULT_ALLOWED_WORK_ITEM_TYPES) {
                options.add(new AzureDevOpsWrappers.WorkItemTypeOption(t, t, t + ' work item'));
            }
        }
        return options;
    }
    @AuraEnabled(cacheable=true)
    public static List<AzureDevOpsWrappers.StateOption> getAvailableStatesForType(String workItemType) {
        List<AzureDevOpsWrappers.StateOption> options = new List<AzureDevOpsWrappers.StateOption>();
        try {
            for (AzureDevOpsWrappers.StateDTO state : String.isBlank(workItemType) ? new List<AzureDevOpsWrappers.StateDTO>() : AdoConfigProvider.getStatesForType(workItemType)) {
                options.add(new AzureDevOpsWrappers.StateOption(state.value, state.label, state.description));
            }
        } catch (Exception e) {
            // Silently ignore metadata access errors - will use default states
            System.debug(LoggingLevel.FINE, 'Unable to load states: ' + e.getMessage());
        }
        if (options.isEmpty()) {
            options.add(new AzureDevOpsWrappers.StateOption('To Do', 'To Do', 'Work item is ready to be started'));
            options.add(new AzureDevOpsWrappers.StateOption('Doing', 'Doing', 'Work item is currently in progress'));
            options.add(new AzureDevOpsWrappers.StateOption('Done', 'Done', 'Work item has been completed'));
        }
        return options;
    }
    @AuraEnabled(cacheable=true)
    public static List<AzureDevOpsWrappers.PriorityOption> getPriorities() {
        List<AzureDevOpsWrappers.PriorityOption> options = new List<AzureDevOpsWrappers.PriorityOption>();
        try {
            for (AzureDevOpsWrappers.PriorityDTO priority : AdoConfigProvider.getPriorities()) {
                options.add(new AzureDevOpsWrappers.PriorityOption(priority.value, priority.label, priority.uiClass));
            }
        } catch (Exception e) {
            // Silently ignore metadata access errors - will use default priorities
            System.debug(LoggingLevel.FINE, 'Unable to load priorities: ' + e.getMessage());
        }
        if (options.isEmpty()) {
            options.add(new AzureDevOpsWrappers.PriorityOption('1', 'Critical', 'slds-text-color_error'));
            options.add(new AzureDevOpsWrappers.PriorityOption('2', 'High', 'slds-text-color_warning'));
            options.add(new AzureDevOpsWrappers.PriorityOption('3', 'Medium', ''));
            options.add(new AzureDevOpsWrappers.PriorityOption('4', 'Low', 'slds-text-color_weak'));
        }
        return options;
    }
    @AuraEnabled(cacheable=false)
    public static AzureDevOpsWrappers.WorkItemListResult getWorkItems(String configName, String workItemType, String state, Integer maxResults) { //NOPMD API method requires all query parameters
        try {
            if (String.isBlank(configName)) {
                throw new AuraHandledException('Configuration name is required');
            }
            // Get configuration
            AzureDevOpsWrappers.AzureConfig cfg = AzureDevOpsService.getCachedConfig(configName);
            if (cfg == null) {
                throw new AuraHandledException('Configuration not found: ' + configName);
            }
            String wiqlQuery = buildWIQLQuery(workItemType, state, maxResults);
            HttpResponse res = executeWiqlQuery(cfg, wiqlQuery);
            if (res.getStatusCode() == 200) {
                Map<String, Object> queryResult = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                List<Object> workItems = (List<Object>) queryResult.get('workItems');
                if (workItems != null && !workItems.isEmpty()) {
                    List<String> workItemIds = new List<String>();
                    for (Object item : workItems) {
                        Map<String, Object> workItem = (Map<String, Object>) item;
                        workItemIds.add(String.valueOf(workItem.get('id')));
                    }
                    return getWorkItemDetails(cfg, workItemIds);
                }
                return new AzureDevOpsWrappers.WorkItemListResult(true, 'No work items found', new List<AzureDevOpsWrappers.WorkItemSummary>());
            }
            return new AzureDevOpsWrappers.WorkItemListResult(false, 'Failed to query work items: ' + res.getBody(), new List<AzureDevOpsWrappers.WorkItemSummary>());
        } catch (Exception e) {
            return new AzureDevOpsWrappers.WorkItemListResult(false, 'Error retrieving work items: ' + e.getMessage(), new List<AzureDevOpsWrappers.WorkItemSummary>());
        }
    }
    private static HttpResponse executeWiqlQuery(AzureDevOpsWrappers.AzureConfig cfg, String wiqlQuery) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(buildEndpoint(cfg, '/_apis/wit/wiql'));
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        if (!cfg.hasNamedCredential() && cfg.hasPersonalAccessToken()) {
            // PMD suppression: PAT authentication is intentional when Named Credential is not configured
            req.setHeader('Authorization', 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(':' + cfg.personalAccessToken))); //NOPMD
        }
        req.setBody('{"query": "' + wiqlQuery + '"}');
        return sendWithRetry(cfg, req);
    }
    private static AzureDevOpsWrappers.WorkItemListResult getWorkItemDetails(AzureDevOpsWrappers.AzureConfig config, List<String> workItemIds) {
        try {
            String ids = String.join(workItemIds, ',');
            String fieldsQuery = 'System.Id,System.Title,System.WorkItemType,System.State,System.AssignedTo,System.CreatedDate,System.ChangedDate,Microsoft.VSTS.Common.Priority';
            HttpRequest req = new HttpRequest();
            req.setEndpoint(buildEndpoint(config, '/_apis/wit/workitems') + '&ids=' + ids + '&fields=' + EncodingUtil.urlEncode(fieldsQuery, 'UTF-8'));
            req.setMethod('GET');
            if (!config.hasNamedCredential() && config.hasPersonalAccessToken()) {
                // PMD suppression: PAT authentication is intentional when Named Credential is not configured
                req.setHeader('Authorization', 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(':' + config.personalAccessToken))); //NOPMD
            }
            HttpResponse res = sendWithRetry(config, req);
            if (res.getStatusCode() == 200) {
                Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                List<Object> items = (List<Object>) result.get('value');
                List<AzureDevOpsWrappers.WorkItemSummary> workItems = new List<AzureDevOpsWrappers.WorkItemSummary>();
                for (Object item : items) {
                    Map<String, Object> workItem = (Map<String, Object>) item;
                    Map<String, Object> fields = (Map<String, Object>) workItem.get('fields');
                    AzureDevOpsWrappers.WorkItemSummary summary = new AzureDevOpsWrappers.WorkItemSummary();
                    summary.workItemId = (Integer) workItem.get('id');
                    summary.title = (String) fields.get('System.Title');
                    summary.workItemType = (String) fields.get('System.WorkItemType');
                    summary.state = (String) fields.get('System.State');
                    summary.priority = fields.get('Microsoft.VSTS.Common.Priority') != null ? 
                                    (Integer) fields.get('Microsoft.VSTS.Common.Priority') : 2;
                    summary.createdDate = (String) fields.get('System.CreatedDate');
                    summary.changedDate = (String) fields.get('System.ChangedDate');
                    Object assignedTo = fields.get('System.AssignedTo');
                    if (assignedTo != null) {
                        Map<String, Object> assignedUser = (Map<String, Object>) assignedTo;
                        summary.assignedTo = (String) assignedUser.get('displayName');
                    }
                    summary.url = 'https://dev.azure.com/' + config.organization + '/' + config.project + '/_workitems/edit/' + summary.workItemId;
                    workItems.add(summary);
                }
                return new AzureDevOpsWrappers.WorkItemListResult(true, 'Successfully retrieved ' + workItems.size() + ' work items', workItems);
            }
            return new AzureDevOpsWrappers.WorkItemListResult(false, 'Failed to get work item details: ' + res.getBody(), new List<AzureDevOpsWrappers.WorkItemSummary>());
        } catch (Exception e) {
            return new AzureDevOpsWrappers.WorkItemListResult(false, 'Error getting work item details: ' + e.getMessage(), new List<AzureDevOpsWrappers.WorkItemSummary>());
        }
    }
    private static String buildWIQLQuery(String workItemType, String state, Integer maxResults) {
        String query = 'SELECT [System.Id] FROM WorkItems WHERE [System.TeamProject] = @project';
        if (String.isNotBlank(workItemType)) {
            query += ' AND [System.WorkItemType] = \'' + workItemType + '\'';
        }
        if (String.isNotBlank(state)) {
            query += ' AND [System.State] = \'' + state + '\'';
        }
        query += ' ORDER BY [System.ChangedDate] DESC';
        return query;
    }
    @AuraEnabled
    public static AzureDevOpsWrappers.WorkItemResult createWorkItem(String configName, String workItemType, String title, String description, String state, Integer priority) { //NOPMD API method requires all work item fields
        try {
            AzureDevOpsWrappers.WorkItemResult validationError = validateCreateInputs(configName, workItemType, title);
            if (validationError != null) {
                return validationError;
            }
            
            CreateWorkItemContext ctx = buildCreateWorkItemContext(workItemType, title, description, state, priority);
            AzureDevOpsWrappers.AzureResult result = AzureIntegrationFacade.createWorkItem(configName, workItemType, ctx.fields);
            
            if (result != null && result.id != null) {
                String message = 'Work item created successfully!';
                if (ctx.adjustedState) {
                    message += ' (Terminal state was adjusted to allow creation.)';
                }
                return new AzureDevOpsWrappers.WorkItemResult(true, message, result.id, result.url, workItemType, title);
            }
            
            return new AzureDevOpsWrappers.WorkItemResult(false, 'Failed to create work item - no result returned', null, null, workItemType, title);
        } catch (AzureDevOpsService.AzureDevOpsException e) {
            return new AzureDevOpsWrappers.WorkItemResult(false, 'Azure DevOps Error: ' + e.getMessage(), null, null, workItemType, title);
        } catch (Exception e) {
            return new AzureDevOpsWrappers.WorkItemResult(false, 'Error creating work item: ' + e.getMessage(), null, null, workItemType, title);
        }
    }
    
    private static AzureDevOpsWrappers.WorkItemResult validateCreateInputs(String configName, String workItemType, String title) {
        if (String.isBlank(configName) || String.isBlank(workItemType) || String.isBlank(title)) {
            return new AzureDevOpsWrappers.WorkItemResult(false, 'Missing required parameters: Configuration, Work Item Type, and Title are required.');
        }
        
        if (!DEFAULT_ALLOWED_WORK_ITEM_TYPES.contains(workItemType)) {
            return new AzureDevOpsWrappers.WorkItemResult(false, 'Work item type "' + workItemType + '" is not allowed. Allowed types: ' + String.join(new List<String>(DEFAULT_ALLOWED_WORK_ITEM_TYPES), ','));
        }
        
        return null;
    }
    
    private class CreateWorkItemContext {
        Map<String, Object> fields;
        Boolean adjustedState;
        
        CreateWorkItemContext(Map<String, Object> fields, Boolean adjustedState) {
            this.fields = fields;
            this.adjustedState = adjustedState;
        }
    }
    
    private static CreateWorkItemContext buildCreateWorkItemContext(String workItemType, String title, String description, String state, Integer priority) { //NOPMD Helper method needs all work item fields
        Map<String, Object> fields = new Map<String, Object>();
        fields.put('System.Title', title);
        
        if (String.isNotBlank(description)) {
            fields.put('System.Description', description);
        }
        
        Boolean adjustedState = addStateField(fields, workItemType, state);
        
        if (priority != null && priority >= 1 && priority <= 4) {
            fields.put('Microsoft.VSTS.Common.Priority', priority);
        }
        
        return new CreateWorkItemContext(fields, adjustedState);
    }
    
    private static Boolean addStateField(Map<String, Object> fields, String workItemType, String state) {
        if (String.isBlank(state)) {
            return false;
        }
        
        Set<String> terminalStates = new Set<String>{'Done','Closed','Resolved'};
        Set<String> allowedStates = getAllowedStates(workItemType);
        
        if (!allowedStates.isEmpty() && !allowedStates.contains(state)) {
            return false;
        }
        
        if (terminalStates.contains(state)) {
            return true; // Adjusted - terminal state skipped
        }
        
        fields.put('System.State', state);
        return false;
    }
    private static Set<String> getAllowedStates(String workItemType) {
        Set<String> allowedStates = new Set<String>();
        try {
            List<AzureDevOpsWrappers.StateDTO> cfgStates = AdoConfigProvider.getStatesForType(workItemType);
            if (cfgStates != null) {
                for (AzureDevOpsWrappers.StateDTO s : cfgStates) {
                    if (s != null && String.isNotBlank(s.value)) {
                        allowedStates.add(s.value);
                    }
                }
            }
        } catch (Exception ex) {
            // Silently ignore metadata access errors - will return empty set
            System.debug(LoggingLevel.FINE, 'Unable to load allowed states: ' + ex.getMessage());
        }
        return allowedStates;
    }
    @AuraEnabled
    public static AzureDevOpsWrappers.WorkItemResult updateWorkItem(String configName, Integer workItemId, String title, String description, String state, Integer priority) { //NOPMD API method requires all work item fields
        try {
            AzureDevOpsWrappers.WorkItemResult validationError = validateUpdateInputs(configName, workItemId, title);
            if (validationError != null) {
                return validationError;
            }
            
            Map<String, Object> fields = buildUpdateFields(title, description, state, priority);
            AzureDevOpsWrappers.AzureResult result = AzureIntegrationFacade.updateWorkItem(configName, workItemId, fields);
            
            if (result != null && result.id != null) {
                return buildUpdateSuccessResult(result, title);
            }
            
            return new AzureDevOpsWrappers.WorkItemResult(false, 'Failed to update work item - no result returned', workItemId);
        } catch (AzureDevOpsService.AzureDevOpsException e) {
            return new AzureDevOpsWrappers.WorkItemResult(false, 'Azure DevOps Error: ' + e.getMessage(), workItemId);
        } catch (Exception e) {
            return new AzureDevOpsWrappers.WorkItemResult(false, 'Error updating work item: ' + e.getMessage(), workItemId);
        }
    }
    
    private static AzureDevOpsWrappers.WorkItemResult validateUpdateInputs(String configName, Integer workItemId, String title) {
        if (String.isBlank(configName) || workItemId == null) {
            return new AzureDevOpsWrappers.WorkItemResult(false, 'Missing required parameters: Configuration and Work Item ID are required.', workItemId);
        }
        return null;
    }
    
    private static Map<String, Object> buildUpdateFields(String title, String description, String state, Integer priority) { //NOPMD Field updates require these 4 standard work item parameters
        Map<String, Object> fields = new Map<String, Object>();
        
        if (String.isNotBlank(title)) {
            fields.put('System.Title', title);
        }
        if (String.isNotBlank(description)) {
            fields.put('System.Description', description);
        }
        if (String.isNotBlank(state)) {
            fields.put('System.State', state);
        }
        if (priority != null && priority >= 1 && priority <= 4) {
            fields.put('Microsoft.VSTS.Common.Priority', priority);
        }
        
        return fields;
    }
    
    private static AzureDevOpsWrappers.WorkItemResult buildUpdateSuccessResult(AzureDevOpsWrappers.AzureResult result, String title) {
        String workItemType = extractFieldValue(result, 'System.WorkItemType', '');
        String updatedTitle = extractFieldValue(result, 'System.Title', title);
        return new AzureDevOpsWrappers.WorkItemResult(true, 'Work item updated successfully!', result.id, result.url, workItemType, updatedTitle);
    }
    
    private static String extractFieldValue(AzureDevOpsWrappers.AzureResult result, String fieldName, String defaultValue) {
        if (result.fields != null && result.fields.containsKey(fieldName)) {
            return (String) result.fields.get(fieldName);
        }
        return defaultValue;
    }
    @AuraEnabled
    public static AzureDevOpsWrappers.WorkItemResult deleteWorkItemWithReason(String configName, Integer workItemId, String reason) {
        try {
            if (String.isBlank(configName) || workItemId == null) {
                return new AzureDevOpsWrappers.WorkItemResult(false, 'Missing required parameters: Configuration and Work Item ID are required.', workItemId, null, '', null);
            }
            AzureDevOpsWrappers.AzureResult result = AzureIntegrationFacade.deleteWorkItem(configName, workItemId, reason);
            if (result != null && result.id != null) {
                return new AzureDevOpsWrappers.WorkItemResult(true, 'Work item deleted successfully!', result.id, result.url, '', null);
            }
            return new AzureDevOpsWrappers.WorkItemResult(false, 'Failed to delete work item - no result returned', workItemId, null, '', null);
        } catch (AzureDevOpsService.AzureDevOpsException e) {
            return new AzureDevOpsWrappers.WorkItemResult(false, 'Azure DevOps Error: ' + e.getMessage(), workItemId, null, '', null);
        } catch (Exception e) {
            return new AzureDevOpsWrappers.WorkItemResult(false, 'Error deleting work item: ' + e.getMessage(), workItemId, null, '', null);
        }
    }
}
