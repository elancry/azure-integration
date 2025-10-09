public with sharing class AzureDevOpsRepository {
    public class PatchOp {
        public String op;
        public String path;
        public Object value;
        public PatchOp(String op, String path, Object value) {
            this.op = op;
            this.path = path;
            this.value = value;
        }
    }
    public static HttpResponse sendRequest(String method, String endpoint, String body, Map<String, String> headers) { //NOPMD HTTP request method requires all HTTP parameters
        try {
            return AzureDevOpsCallout.send(method, endpoint, body, headers);
        } catch (System.CalloutException ex) {
            throw new AzureDevOpsService.AzureDevOpsException('HTTP callout failed: ' + ex.getMessage());
        }
    }
    public static AzureDevOpsWrappers.AzureResult parseResponse(HttpResponse resp) {
        return parseResponse(resp, null, null);
    }
    public static AzureDevOpsWrappers.AzureResult parseDeleteResponse(HttpResponse resp, AzureDevOpsWrappers.AzureConfig config, Integer workItemId) {
        return parseResponse(resp, config, workItemId);
    }
    private static AzureDevOpsWrappers.AzureResult parseResponse(HttpResponse resp, AzureDevOpsWrappers.AzureConfig config, Integer workItemId) {
        Integer status = resp.getStatusCode();
        String body = resp.getBody() == null ? '' : resp.getBody();
        
        if (status < 200 || status >= 300) {
            throw new AzureDevOpsService.AzureDevOpsException('Azure DevOps returned status ' + status + ': ' + body);
        }
        
        AzureDevOpsWrappers.AzureResult result = parseResponseBody(body);
        enrichResultWithConfig(result, config, workItemId);
        return result;
    }
    
    private static AzureDevOpsWrappers.AzureResult parseResponseBody(String body) {
        AzureDevOpsWrappers.AzureResult result = new AzureDevOpsWrappers.AzureResult();
        
        if (String.isBlank(body)) {
            return result;
        }
        
        try {
            Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(body);
            parseIdField(parsed, result);
            parseUrlField(parsed, result);
            parseFieldsMap(parsed, result);
        } catch (Exception ex) {
            // Silently ignore JSON parsing errors - will return result with available data
            System.debug(LoggingLevel.FINE, 'Unable to parse response JSON: ' + ex.getMessage());
        }
        
        return result;
    }
    
    private static void parseIdField(Map<String, Object> parsed, AzureDevOpsWrappers.AzureResult result) {
        if (!parsed.containsKey('id')) {
            return;
        }
        
        try {
            result.id = Integer.valueOf(String.valueOf(parsed.get('id')));
        } catch (Exception e) {
            // Silently ignore ID parsing errors - will use workItemId parameter if available
            System.debug(LoggingLevel.FINE, 'Unable to parse work item ID: ' + e.getMessage());
        }
    }
    
    private static void parseUrlField(Map<String, Object> parsed, AzureDevOpsWrappers.AzureResult result) {
        if (parsed.containsKey('url')) {
            result.url = (String) parsed.get('url');
        }
    }
    
    private static void parseFieldsMap(Map<String, Object> parsed, AzureDevOpsWrappers.AzureResult result) {
        if (parsed.containsKey('fields')) {
            result.fields = (Map<String, Object>) parsed.get('fields');
        }
    }
    
    private static void enrichResultWithConfig(AzureDevOpsWrappers.AzureResult result, AzureDevOpsWrappers.AzureConfig config, Integer workItemId) {
        if (config == null || workItemId == null) {
            return;
        }
        
        if (result.id == null) {
            result.id = workItemId;
        }
        
        if (String.isBlank(result.url)) {
            result.url = 'https://dev.azure.com/' + config.organization + '/' + config.project + '/_workitems/edit/' + workItemId;
        }
    }
}