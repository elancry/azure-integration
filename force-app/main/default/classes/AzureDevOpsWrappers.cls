public with sharing class AzureDevOpsWrappers {
    // === AZURE SERVICE DTOs ===
    public class AzureResult {
        public Integer id;
        public String url;
        public Map<String, Object> fields;
    }
    
    public class AzureConfig {
        public String organization;
        public String project;
        public String namedCredential;
        public String apiVersion;
        public String personalAccessToken;
        
        // Primary constructor with required fields only
        public AzureConfig(String org, String proj) {
            this(org, proj, null, null, null);
        }
        
        // Full constructor (internal use)
        public AzureConfig(String org, String proj, String cred, String version, String pat) { //NOPMD DTO requires all config parameters
            this.organization = org;
            this.project = proj;
            this.namedCredential = cred;
            this.apiVersion = String.isNotBlank(version) ? version : '6.0';
            this.personalAccessToken = pat;
        }
        
        public Boolean hasNamedCredential() {
            return String.isNotBlank(this.namedCredential) && !this.namedCredential.equals('null');
        }
        public Boolean hasPersonalAccessToken() {
            return String.isNotBlank(this.personalAccessToken);
        }
    }
    
    // === CONFIGURATION DTOs ===
    public class ConfigDTO {
        @AuraEnabled public String value;
        @AuraEnabled public String label;
        @AuraEnabled public String organization;
        @AuraEnabled public String project;
        @AuraEnabled public String baseUrl;
        @AuraEnabled public String namedCredential;
        @AuraEnabled public String apiVersion;
        
        // Constructor with minimal required fields
        public ConfigDTO(String dev, String lab, String org, String proj){ //NOPMD 4 parameters needed for basic config
            this(dev, lab, org, proj, null, null, null);
        }
        
        // Full constructor
        public ConfigDTO(String dev, String lab, String org, String proj, String base, String nc, String api){ //NOPMD DTO requires all metadata fields
            value=dev;
            label=lab;
            organization=org;
            project=proj;
            baseUrl=base;
            namedCredential=nc;
            apiVersion=api;
        }
    }
    public class ConfigurationOption {
        @AuraEnabled public String value { get; set; }
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String organization { get; set; }
        @AuraEnabled public String project { get; set; }
        public ConfigurationOption(String value, String label, String organization, String project) { //NOPMD 4 parameters needed for configuration option
            this.value = value;
            this.label = label;
            this.organization = organization;
            this.project = project;
        }
    }
    
    // === WORK ITEM TYPE DTOs ===
    public class WorkItemTypeDTO {
        @AuraEnabled public String value;
        @AuraEnabled public String label;
        @AuraEnabled public String description;
        @AuraEnabled public String defaultState;
        @AuraEnabled public String iconName;
        @AuraEnabled public String connection;
        
        // Constructor with essential fields
        public WorkItemTypeDTO(String v, String l, String d){
            this(v, l, d, null, null, null);
        }
        
        // Full constructor
        public WorkItemTypeDTO(String v, String l, String d, String def, String icon, String conn){ //NOPMD DTO requires all metadata fields
            value=v;
            label=l;
            description=d;
            defaultState=def;
            iconName=icon;
            connection=conn;
        }
    }
    public class WorkItemTypeOption {
        @AuraEnabled public String value { get; set; }
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String description { get; set; }
        public WorkItemTypeOption(String value, String label, String description) {
            this.value = value;
            this.label = label;
            this.description = description;
        }
    }
    
    // === STATE DTOs ===
    public class StateDTO {
        @AuraEnabled public String value;
        @AuraEnabled public String label;
        @AuraEnabled public String description;
        @AuraEnabled public String uiClass;
        @AuraEnabled public String workItemType;
        
        // Constructor with essential fields
        public StateDTO(String v, String l, String d){ 
            this(v, l, d, null, null);
        }
        
        // Full constructor
        public StateDTO(String v, String l, String d, String ui, String t){ //NOPMD DTO requires all metadata fields 
            value=v;
            label=l;
            description=d;
            uiClass=ui;
            workItemType=t;
        }
    }
    public class StateOption {
        @AuraEnabled public String value { get; set; }
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String description { get; set; }
        public StateOption(String value, String label, String description) {
            this.value = value;
            this.label = label;
            this.description = description;
        }
    }
    
    // === PRIORITY DTOs ===
    public class PriorityDTO {
        @AuraEnabled public String value;
        @AuraEnabled public String label;
        @AuraEnabled public String uiClass;
        public PriorityDTO(String v, String l, String ui){ 
            value=v;
            label=l;
            uiClass=ui;
        }
    }
    public class PriorityOption {
        @AuraEnabled public String value { get; set; }
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String uiClass { get; set; }
        public PriorityOption(String value, String label, String uiClass) {
            this.value = value;
            this.label = label;
            this.uiClass = uiClass;
        }
    }
    
    // === UI MAPPING & UTILITY DTOs ===
    public class UiMapDTO {
        @AuraEnabled public String context;
        @AuraEnabled public String key;
        @AuraEnabled public String iconName;
        @AuraEnabled public String uiClass;
        
        // Constructor with essential fields
        public UiMapDTO(String c, String k){ 
            this(c, k, null, null);
        }
        
        // Full constructor
        public UiMapDTO(String c, String k, String i, String u){ //NOPMD DTO requires all metadata fields 
            context=c;
            key=k;
            iconName=i;
            uiClass=u;
        }
    }
    
    public class SelectOptionDTO { 
        @AuraEnabled public String value;
        @AuraEnabled public String label;
        public SelectOptionDTO(String v, String l){
            value = v;
            label = l;
        }
    }
    
    // === WORK ITEM RESULT DTOs ===
    public class WorkItemResult {
        @AuraEnabled public Boolean success { get; set; }
        @AuraEnabled public String message { get; set; }
        @AuraEnabled public Integer workItemId { get; set; }
        @AuraEnabled public String workItemUrl { get; set; }
        @AuraEnabled public String workItemType { get; set; }
        @AuraEnabled public String title { get; set; }
        
        // Constructor with essential result fields
        public WorkItemResult(Boolean success, String message) {
            this(success, message, null, null, null, null);
        }
        
        // Constructor with work item ID only (used for error responses)
        public WorkItemResult(Boolean success, String message, Integer workItemId) {
            this(success, message, workItemId, null, null, null);
        }
        
        // Constructor with work item identification
        public WorkItemResult(Boolean success, String message, Integer workItemId, String workItemUrl) { //NOPMD Result DTO needs core result fields
            this(success, message, workItemId, workItemUrl, null, null);
        }
        
        // Full constructor
        public WorkItemResult(Boolean success, String message, Integer workItemId, String workItemUrl, String workItemType, String title) { //NOPMD Result DTO requires all result fields
            this.success = success;
            this.message = message;
            this.workItemId = workItemId;
            this.workItemUrl = workItemUrl;
            this.workItemType = workItemType;
            this.title = title;
        }
    }
    public class WorkItemListResult {
        @AuraEnabled public Boolean success { get; set; }
        @AuraEnabled public String message { get; set; }
        @AuraEnabled public List<WorkItemSummary> workItems { get; set; }
        public WorkItemListResult(Boolean success, String message, List<WorkItemSummary> workItems) {
            this.success = success;
            this.message = message;
            this.workItems = workItems;
        }
    }
    public class WorkItemSummary {
        @AuraEnabled public Integer workItemId { get; set; }
        @AuraEnabled public String title { get; set; }
        @AuraEnabled public String workItemType { get; set; }
        @AuraEnabled public String state { get; set; }
        @AuraEnabled public Integer priority { get; set; }
        @AuraEnabled public String assignedTo { get; set; }
        @AuraEnabled public String createdDate { get; set; }
        @AuraEnabled public String changedDate { get; set; }
        @AuraEnabled public String url { get; set; }
    }
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
    public class MappingRow {
        public String context;
        public String sobjectApi;
        public String sfField;
        public String adoField;
        public String workItemType;
        public String transform;
    }
}
