public with sharing class AzureDevOpsCallout {
    public static HttpResponse send(String method, String endpoint, String body, Map<String, String> headers) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod(method);
        if (headers != null) {
            for (String k : headers.keySet()) req.setHeader(k, headers.get(k));
        }
        if (!String.isBlank(body)) req.setBody(body);
        Http http = new Http();
        try {
            return http.send(req);
        } catch (System.CalloutException ex) {
            throw new System.CalloutException('HTTP callout failed: ' + ex.getMessage());
        }
    }
}