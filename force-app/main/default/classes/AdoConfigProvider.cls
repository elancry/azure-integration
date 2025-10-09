public with sharing class AdoConfigProvider {
    private static Map<String, Azure_DevOps_Connection__mdt> connByDevName;
    private static List<AzureDevOpsWrappers.WorkItemTypeDTO> typeCache;
    private static Map<String, List<AzureDevOpsWrappers.StateDTO>> statesByType;
    private static List<AzureDevOpsWrappers.PriorityDTO> priorityCache;
    private static Map<String, AzureDevOpsWrappers.UiMapDTO> uiMapByKey;
    
    @AuraEnabled(cacheable=true)
    public static List<AzureDevOpsWrappers.ConfigDTO> getConfigurations(){
        ensureConnections();
        List<AzureDevOpsWrappers.ConfigDTO> outList = new List<AzureDevOpsWrappers.ConfigDTO>();
        for (Azure_DevOps_Connection__mdt m : connByDevName.values()){
            outList.add(new AzureDevOpsWrappers.ConfigDTO(m.DeveloperName, m.Label, m.Organization__c, m.Project__c, m.BaseUrl__c, m.NamedCredential__c, m.ApiVersion__c));
        }
        return outList;
    }
    @AuraEnabled(cacheable=true)
    public static List<AzureDevOpsWrappers.WorkItemTypeDTO> getWorkItemTypes(String connectionDevName){
        ensureTypes();
        if (String.isBlank(connectionDevName)) {
            return typeCache;
        }
        List<AzureDevOpsWrappers.WorkItemTypeDTO> filtered = new List<AzureDevOpsWrappers.WorkItemTypeDTO>();
        for (AzureDevOpsWrappers.WorkItemTypeDTO t : typeCache){
            if (String.isBlank(t.connection) || t.connection == connectionDevName) {
                filtered.add(t);
            }
        }
        return filtered;
    }
    @AuraEnabled(cacheable=true)
    public static List<AzureDevOpsWrappers.StateDTO> getStatesForType(String workItemType){
        ensureStates();
        return statesByType.containsKey(workItemType) ? statesByType.get(workItemType) : new List<AzureDevOpsWrappers.StateDTO>();
    }
    @AuraEnabled(cacheable=true)
    public static List<AzureDevOpsWrappers.PriorityDTO> getPriorities(){ ensurePriorities(); return priorityCache; }
    public static Map<String, AzureDevOpsWrappers.UiMapDTO> getUiMapByKey(){ ensureUiMap(); return uiMapByKey; }
    public static Azure_DevOps_Connection__mdt getConnection(String devName){ ensureConnections(); return connByDevName.get(devName); }
    public static AzureDevOpsWrappers.WorkItemTypeDTO getType(String typeDevName){
        ensureTypes();
        for (AzureDevOpsWrappers.WorkItemTypeDTO t : typeCache) {
            if (t.value == typeDevName) {
                return t;
            }
        }
        return null;
    }
    private static void ensureConnections(){
        if (connByDevName != null) {
            return;
        }
        connByDevName = new Map<String, Azure_DevOps_Connection__mdt>();
        for (Azure_DevOps_Connection__mdt c : Azure_DevOps_Connection__mdt.getAll().values()){
            if (c.IsActive__c == true) {
                connByDevName.put(c.DeveloperName, c);
            }
        }
    }
    private static void ensureTypes(){
        if (typeCache != null) {
            return;
        }
        typeCache = new List<AzureDevOpsWrappers.WorkItemTypeDTO>();
        for (Azure_Work_Item_Type__mdt r : Azure_Work_Item_Type__mdt.getAll().values()){
            if (r.IsActive__c == true){
                typeCache.add(new AzureDevOpsWrappers.WorkItemTypeDTO(r.DeveloperName, r.Label, r.Description__c, r.Default_State__c, r.Icon_Name__c, r.Connection__c));
            }
        }
    }
    private static void ensureStates(){
        if (statesByType != null) {
            return;
        }
        statesByType = new Map<String, List<AzureDevOpsWrappers.StateDTO>>();
        for (Azure_Work_Item_State__mdt r : Azure_Work_Item_State__mdt.getAll().values()){
            if (r.IsActive__c == true){
                if (!statesByType.containsKey(r.Work_Item_Type__c)) {
                    statesByType.put(r.Work_Item_Type__c, new List<AzureDevOpsWrappers.StateDTO>());
                }
                statesByType.get(r.Work_Item_Type__c).add(new AzureDevOpsWrappers.StateDTO(r.DeveloperName, r.Label, r.Description__c, r.Ui_Class__c, r.Work_Item_Type__c));
            }
        }
    }
    private static void ensurePriorities(){
        if (priorityCache != null) {
            return;
        }
        List<AzureDevOpsWrappers.PriorityDTO> tmp = new List<AzureDevOpsWrappers.PriorityDTO>();
        Map<String, Azure_Priority__mdt> all = Azure_Priority__mdt.getAll();
        for (Azure_Priority__mdt r : all.values()){
            if (r.IsActive__c == true) {
                tmp.add(new AzureDevOpsWrappers.PriorityDTO(String.valueOf(r.Priority_Value__c), r.Label, r.Ui_Class__c));
            }
        }
        tmp.sort(new ComparatorPriority(all));
        priorityCache = tmp;
    }
    private class ComparatorPriority implements System.Comparator<AzureDevOpsWrappers.PriorityDTO> {
        Map<String, Azure_Priority__mdt> meta;
        ComparatorPriority(Map<String, Azure_Priority__mdt> m){ meta = m; }
        public Integer compare(AzureDevOpsWrappers.PriorityDTO a, AzureDevOpsWrappers.PriorityDTO b){
            Integer sa = getOrder(a);
            Integer sb = getOrder(b);
            if (sa == null && sb == null) {
                return String.valueOf(a.label).toLowerCase().compareTo(String.valueOf(b.label).toLowerCase());
            }
            if (sa == null) {
                return 1;
            }
            if (sb == null) {
                return -1;
            }
            return sa == sb ? String.valueOf(a.label).toLowerCase().compareTo(String.valueOf(b.label).toLowerCase()) : (sa < sb ? -1 : 1);
        }
        private Integer getOrder(AzureDevOpsWrappers.PriorityDTO p){
            for (Azure_Priority__mdt r : meta.values()){
                if (String.valueOf(r.Priority_Value__c) == p.value) {
                    return (Integer) r.Sort_Order__c;
                }
            }
            return null;
        }
    }
    private static void ensureUiMap(){
        if (uiMapByKey != null) {
            return;
        }
        uiMapByKey = new Map<String, AzureDevOpsWrappers.UiMapDTO>();
        try {
            for (Azure_UI_Mapping__mdt r : Azure_UI_Mapping__mdt.getAll().values()){
                if (r.IsActive__c == true){
                    uiMapByKey.put(r.Context__c + '::' + r.Key__c, new AzureDevOpsWrappers.UiMapDTO(r.Context__c, r.Key__c, r.Icon_Name__c, r.Ui_Class__c));
                }
            }
        } catch (Exception ignore) {
            // Silently ignore metadata access errors - UI mapping will remain empty
            System.debug(LoggingLevel.FINE, 'Unable to load UI mappings: ' + ignore.getMessage());
        }
    }
}