// PMD: Class-level cognitive complexity is cumulative across all service operations - individual methods are optimized
@SuppressWarnings('PMD.CognitiveComplexity')
public with sharing class AzureDevOpsService { //NOPMD Service aggregates CRUD operations with auth fallback
    
    private static final String CONFIG_CACHE_PREFIX = 'azure_config_';
    private static Map<String, String> buildAuthHeader(String pat) {
        return new Map<String, String>{'Authorization' => 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(':' + pat))};
    }
    private static String buildEndpoint(AzureDevOpsWrappers.AzureConfig config, String path) {
        return 'https://dev.azure.com/' + EncodingUtil.urlEncode(config.organization, 'UTF-8') + '/' + 
            EncodingUtil.urlEncode(config.project, 'UTF-8') + path + '?api-version=' + config.apiVersion;
    }
    private static String buildNamedCredentialEndpoint(AzureDevOpsWrappers.AzureConfig config, String path) {
        return 'callout:' + config.namedCredential + '/' + EncodingUtil.urlEncode(config.organization, 'UTF-8') + '/' + 
            EncodingUtil.urlEncode(config.project, 'UTF-8') + path + '?api-version=' + config.apiVersion;
    }
    public static AzureDevOpsWrappers.AzureResult createWorkItem(String configName, String workItemType, Map<String, Object> fields) {
        AzureDevOpsWrappers.AzureConfig config = getConfig(configName);
        
        if (config.hasNamedCredential()) {
            return tryNamedCredentialOrFallback(config, workItemType, fields, null);
        }
        
        if (config.hasPersonalAccessToken()) {
            return createWorkItem(config.personalAccessToken, config, workItemType, fields);
        }
        
        throw new AzureDevOpsException('Configuration "' + configName + '" must have either Named Credential or Personal Access Token configured');
    }
    
    private static AzureDevOpsWrappers.AzureResult tryNamedCredentialOrFallback( //NOPMD Helper method needs all operation parameters
        AzureDevOpsWrappers.AzureConfig config, 
        String workItemType, 
        Map<String, Object> fields,
        Integer workItemId
    ) {
        try {
            if (workItemId == null) {
                return createWorkItemWithNamedCredential(config, workItemType, fields);
            } else {
                return updateWorkItemWithNamedCredential(config, workItemId, fields);
            }
        } catch (AzureDevOpsException ex) {
            if (config.hasPersonalAccessToken()) {
                if (workItemId == null) {
                    return createWorkItem(config.personalAccessToken, config, workItemType, fields);
                } else {
                    return updateWorkItem(config.personalAccessToken, config, workItemId, fields);
                }
            }
            throw ex;
        }
    }
    public static AzureDevOpsWrappers.AzureResult createWorkItem(String pat, AzureDevOpsWrappers.AzureConfig config, String workItemType, Map<String, Object> fields) { //NOPMD API method requires all parameters
        if (String.isBlank(pat) || config == null || String.isBlank(workItemType)) {
            throw new AzureDevOpsException('Missing required parameters');
        }
        fields = removeTerminalState(fields);
        String encodedType = EncodingUtil.urlEncode(workItemType, 'UTF-8').replace('+', '%20');
        String endpoint = buildEndpoint(config, '/_apis/wit/workitems/$' + encodedType);
        Map<String, String> headers = new Map<String, String>{'Content-Type' => 'application/json-patch+json'};
        headers.putAll(buildAuthHeader(pat));
        return AzureDevOpsRepository.parseResponse(AzureDevOpsRepository.sendRequest('POST', endpoint, buildPatchBody(fields), headers));
    }
    public static AzureDevOpsWrappers.AzureResult createWorkItemForPOC(String pat, String workItemType, Map<String, Object> fields) {
        AzureDevOpsWrappers.AzureConfig config = getConfig('POC_Environment');
        return createWorkItem(pat, config, workItemType, fields);
    }
    public static AzureDevOpsWrappers.AzureResult createWorkItemWithNamedCredential(AzureDevOpsWrappers.AzureConfig config, String workItemType, Map<String, Object> fields) {
        if (config == null || String.isBlank(workItemType)) {
            throw new AzureDevOpsException('Missing required parameters');
        }
        String encodedType = EncodingUtil.urlEncode(workItemType, 'UTF-8').replace('+', '%20');
        String endpoint = buildNamedCredentialEndpoint(config, '/_apis/wit/workitems/$' + encodedType);
        fields = removeTerminalState(fields);
        Map<String, String> headers = new Map<String, String>{'Content-Type' => 'application/json-patch+json'};
        return AzureDevOpsRepository.parseResponse(AzureDevOpsRepository.sendRequest('POST', endpoint, buildPatchBody(fields), headers));
    }
    public static AzureDevOpsWrappers.AzureResult createWorkItemWithNamedCredential(String workItemType, Map<String, Object> fields) {
        AzureDevOpsWrappers.AzureConfig config = getConfig('POC_Environment');
        return createWorkItemWithNamedCredential(config, workItemType, fields);
    }
    public static AzureDevOpsWrappers.AzureResult updateWorkItem(String configName, Integer workItemId, Map<String, Object> fields) {
        AzureDevOpsWrappers.AzureConfig config = getConfig(configName);
        
        if (config.hasNamedCredential()) {
            return tryNamedCredentialOrFallback(config, null, fields, workItemId);
        }
        
        if (config.hasPersonalAccessToken()) {
            return updateWorkItem(config.personalAccessToken, config, workItemId, fields);
        }
        
        throw new AzureDevOpsException('Configuration "' + configName + '" must have either Named Credential or Personal Access Token configured');
    }
    public static AzureDevOpsWrappers.AzureResult updateWorkItem(String pat, AzureDevOpsWrappers.AzureConfig config, Integer workItemId, Map<String, Object> fields) { //NOPMD API method requires all parameters
        if (String.isBlank(pat) || config == null || workItemId == null) {
            throw new AzureDevOpsException('Missing required parameters');
        }
        Map<String, String> headers = new Map<String, String>{'Content-Type' => 'application/json-patch+json'};
        headers.putAll(buildAuthHeader(pat));
        return AzureDevOpsRepository.parseResponse(AzureDevOpsRepository.sendRequest('PATCH', buildEndpoint(config, '/_apis/wit/workitems/' + workItemId), buildPatchBody(fields), headers));
    }
    public static AzureDevOpsWrappers.AzureResult updateWorkItemWithNamedCredential(AzureDevOpsWrappers.AzureConfig config, Integer workItemId, Map<String, Object> fields) {
        if (config == null || workItemId == null) {
            throw new AzureDevOpsException('Missing required parameters');
        }
        Map<String, String> headers = new Map<String, String>{'Content-Type' => 'application/json-patch+json'};
        return AzureDevOpsRepository.parseResponse(AzureDevOpsRepository.sendRequest('PATCH', buildNamedCredentialEndpoint(config, '/_apis/wit/workitems/' + workItemId), buildPatchBody(fields), headers));
    }
    public static AzureDevOpsWrappers.AzureResult deleteWorkItem(String configName, Integer workItemId) {
        AzureDevOpsWrappers.AzureConfig config = getConfig(configName);
        
        if (config.hasNamedCredential()) {
            return tryDeleteWithFallback(config, workItemId);
        }
        
        if (config.hasPersonalAccessToken()) {
            return deleteWorkItem(config.personalAccessToken, config, workItemId);
        }
        
        throw new AzureDevOpsException('Configuration "' + configName + '" must have either Named Credential or Personal Access Token configured');
    }
    
    private static AzureDevOpsWrappers.AzureResult tryDeleteWithFallback(AzureDevOpsWrappers.AzureConfig config, Integer workItemId) {
        try {
            return deleteWorkItemWithNamedCredential(config, workItemId);
        } catch (AzureDevOpsException ex) {
            if (config.hasPersonalAccessToken()) {
                return deleteWorkItem(config.personalAccessToken, config, workItemId);
            }
            throw ex;
        }
    }
    public static AzureDevOpsWrappers.AzureResult deleteWorkItem(String configName, Integer workItemId, String reason) {
        AzureDevOpsWrappers.AzureResult result = deleteWorkItem(configName, workItemId);
        return result;
    }
    public static AzureDevOpsWrappers.AzureResult deleteWorkItem(String pat, AzureDevOpsWrappers.AzureConfig config, Integer workItemId) {
        if (String.isBlank(pat) || config == null || workItemId == null) {
            throw new AzureDevOpsException('Missing required parameters');
        }
        return AzureDevOpsRepository.parseDeleteResponse(AzureDevOpsRepository.sendRequest('DELETE', buildEndpoint(config, '/_apis/wit/workitems/' + workItemId), null, buildAuthHeader(pat)), config, workItemId);
    }
    public static AzureDevOpsWrappers.AzureResult deleteWorkItemWithNamedCredential(AzureDevOpsWrappers.AzureConfig config, Integer workItemId) {
        if (config == null || workItemId == null) {
            throw new AzureDevOpsException('Missing required parameters');
        }
        return AzureDevOpsRepository.parseDeleteResponse(AzureDevOpsRepository.sendRequest('DELETE', buildNamedCredentialEndpoint(config, '/_apis/wit/workitems/' + workItemId), null, null), config, workItemId);
    }
    public static AzureDevOpsWrappers.AzureConfig getCachedConfig(String configName) { return getConfig(configName); }
    private static AzureDevOpsWrappers.AzureConfig getConfig(String configName) {
        String cacheKey = CONFIG_CACHE_PREFIX + configName;
        ConfigSupplier supplier = new ConfigSupplier(configName);
        return (AzureDevOpsWrappers.AzureConfig) AzureDevOpsCacheUtil.getOrCompute(cacheKey, 300, supplier);
    }
    private class ConfigSupplier implements AzureDevOpsCacheUtil.CacheSupplier {
        private String configName;
        public ConfigSupplier(String configName) { this.configName = configName; }
        public Object compute() {
            Azure_DevOps_Connection__mdt configRecord = AdoConfigProvider.getConnection(configName);
            if (configRecord == null) {
                throw new AzureDevOpsException('Configuration not found: ' + configName + '. Please create an Azure_DevOps_Connection__mdt record with this name.');
            }
            return new AzureDevOpsWrappers.AzureConfig(configRecord.Organization__c, configRecord.Project__c, configRecord.NamedCredential__c, configRecord.ApiVersion__c, configRecord.AccessToken__c);
        }
    }
    private static Map<String, Object> removeTerminalState(Map<String, Object> fields) {
        if (fields == null) {
            return fields;
        }
        Set<String> terminalStates = new Set<String>{'Done','Closed','Resolved'};
        if (fields.containsKey('System.State') && terminalStates.contains(String.valueOf(fields.get('System.State')))) {
            Map<String, Object> copy = new Map<String, Object>(fields);
            copy.remove('System.State');
            return copy;
        }
        return fields;
    }
    private static String buildPatchBody(Map<String, Object> fields) {
        List<Object> ops = new List<Object>();
        if (fields != null) {
            for (String key : fields.keySet()) {
                ops.add(new Map<String, Object>{'op' => 'add', 'path' => '/fields/' + key, 'value' => fields.get(key)});
            }
        }
        return JSON.serialize(ops);
    }

    public class AzureDevOpsException extends Exception {}

}
