public with sharing class PicklistUtil {
    @AuraEnabled(cacheable=true)
    public static List<AzureDevOpsWrappers.SelectOptionDTO> getPicklist(String sobjectApi, String fieldApi, Boolean activeOnly){
        Schema.SObjectType t = Schema.getGlobalDescribe().get(sobjectApi);
        if (t == null) {
            return new List<AzureDevOpsWrappers.SelectOptionDTO>();
        }
        Schema.DescribeSObjectResult d = t.getDescribe();
        if (d.fields == null || !d.fields.getMap().containsKey(fieldApi)) {
            return new List<AzureDevOpsWrappers.SelectOptionDTO>();
        }
        List<AzureDevOpsWrappers.SelectOptionDTO> out = new List<AzureDevOpsWrappers.SelectOptionDTO>();
        for (Schema.PicklistEntry pe : d.fields.getMap().get(fieldApi).getDescribe().getPicklistValues()){
            if (!activeOnly || pe.isActive()) {
                out.add(new AzureDevOpsWrappers.SelectOptionDTO(pe.getValue(), pe.getLabel()));
            }
        }
        return out;
    }
}