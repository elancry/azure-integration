public with sharing class AzureFieldMapper {
    public class MappingRow {
        public String context;
        public String sobjectApi;
        public String sfField;
        public String adoField;
        public String workItemType;
        public String transform;
    }
    public static List<MappingRow> getMappings(String context, String workItemType){
        List<MappingRow> outList = new List<MappingRow>();
        try {
            for (Azure_Field_Mapping__mdt r : Azure_Field_Mapping__mdt.getAll().values()){
                if (r.IsActive__c != true || r.Context__c != context) {
                    continue;
                }
                if (!String.isBlank(r.Work_Item_Type__c) && r.Work_Item_Type__c != workItemType) {
                    continue;
                }
                MappingRow m = new MappingRow();
                m.context = r.Context__c;
                m.sobjectApi = r.SObject__c;
                m.sfField = r.Sf_Field__c;
                m.adoField = r.Ado_Field__c;
                m.workItemType = r.Work_Item_Type__c;
                m.transform = r.Transform__c;
                outList.add(m);
            }
        } catch (Exception ignore) {
            // Silently ignore metadata access errors - continue with empty mapping list
            System.debug(LoggingLevel.FINE, 'Unable to load field mappings: ' + ignore.getMessage());
        }
        return outList;
    }
    public static Map<String, Object> buildPayload(String context, String workItemType, SObject recordCtx, Map<String, Object> base){ //NOPMD Field mapping method requires all mapping parameters
        Map<String, Object> result = base != null ? new Map<String, Object>(base) : new Map<String, Object>();
        Map<String, Object> accessibleValues = new Map<String, Object>();
        if (recordCtx != null) {
            try {
                accessibleValues.putAll(recordCtx.getPopulatedFieldsAsMap());
            } catch (Exception ex) {
                // Silently ignore field access errors - continue with empty values
                System.debug(LoggingLevel.FINE, 'Unable to access record fields: ' + ex.getMessage());
            }
        }
        for (MappingRow m : getMappings(context, workItemType)){
            Object v = null;
            if (!String.isBlank(m.sobjectApi) && recordCtx != null && recordCtx.getSObjectType().getDescribe().getName() == m.sobjectApi && accessibleValues.containsKey(m.sfField)){
                v = accessibleValues.get(m.sfField);
            } else if (base != null && base.containsKey(m.sfField)){
                v = base.get(m.sfField);
            }
            v = applyTransform(v, m.transform);
            if (v != null) {
                result.put(m.adoField, v);
            }
        }
        return result;
    }
    private static Object applyTransform(Object v, String key){
        if (String.isBlank(key) || v == null) {
            return v;
        }
        if (key == 'ToString') {
            return String.valueOf(v);
        }
        if (key == 'ToInteger') {
            return Integer.valueOf(String.valueOf(v));
        }
        if (key == 'Trim') {
            return String.valueOf(v).trim();
        }
        return v;
    }
}