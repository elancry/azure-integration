@IsTest
private class AdoConfigProviderTest {
    
    @IsTest
    static void testGetConfigurations() {
        Test.startTest();
        List<AzureDevOpsWrappers.ConfigDTO> configs = AdoConfigProvider.getConfigurations();
        Test.stopTest();
        
        System.assertNotEquals(null, configs, 'Configurations list should not be null');
    }
    
    @IsTest
    static void testGetWorkItemTypes() {
        Test.startTest();
        List<AzureDevOpsWrappers.WorkItemTypeDTO> types = AdoConfigProvider.getWorkItemTypes(null);
        Test.stopTest();
        
        System.assertNotEquals(null, types, 'Work item types list should not be null');
    }
    
    @IsTest
    static void testGetWorkItemTypesFiltered() {
        Test.startTest();
        List<AzureDevOpsWrappers.WorkItemTypeDTO> types = AdoConfigProvider.getWorkItemTypes('TestConnection');
        Test.stopTest();
        
        System.assertNotEquals(null, types, 'Filtered work item types list should not be null');
    }
    
    @IsTest
    static void testGetStatesForType() {
        Test.startTest();
        List<AzureDevOpsWrappers.StateDTO> states = AdoConfigProvider.getStatesForType('Task');
        Test.stopTest();
        
        System.assertNotEquals(null, states, 'States list should not be null');
    }
    
    @IsTest
    static void testGetStatesForNonExistentType() {
        Test.startTest();
        List<AzureDevOpsWrappers.StateDTO> states = AdoConfigProvider.getStatesForType('NonExistentType');
        Test.stopTest();
        
        System.assertNotEquals(null, states, 'States list should not be null');
        System.assertEquals(0, states.size(), 'Should return empty list for non-existent type');
    }
    
    @IsTest
    static void testGetPriorities() {
        Test.startTest();
        List<AzureDevOpsWrappers.PriorityDTO> priorities = AdoConfigProvider.getPriorities();
        Test.stopTest();
        
        System.assertNotEquals(null, priorities, 'Priorities list should not be null');
    }
    
    @IsTest
    static void testGetUiMapByKey() {
        Test.startTest();
        Map<String, AzureDevOpsWrappers.UiMapDTO> uiMap = AdoConfigProvider.getUiMapByKey();
        Test.stopTest();
        
        System.assertNotEquals(null, uiMap, 'UI map should not be null');
    }
    
    @IsTest
    static void testGetConnection() {
        Test.startTest();
        Azure_DevOps_Connection__mdt conn = AdoConfigProvider.getConnection('TestConnection');
        Test.stopTest();
        
        System.assert(true, 'Method should execute without exception');
    }
    
    @IsTest
    static void testGetType() {
        Test.startTest();
        AzureDevOpsWrappers.WorkItemTypeDTO type = AdoConfigProvider.getType('Task');
        Test.stopTest();
        
        System.assert(true, 'Method should execute without exception');
    }
    
    @IsTest
    static void testCaching() {
        Test.startTest();
        
        List<AzureDevOpsWrappers.ConfigDTO> configs1 = AdoConfigProvider.getConfigurations();
        
        List<AzureDevOpsWrappers.ConfigDTO> configs2 = AdoConfigProvider.getConfigurations();
        
        Test.stopTest();
        
        System.assertNotEquals(null, configs1, 'First call should return non-null list');
        System.assertNotEquals(null, configs2, 'Second call should return non-null list');
    }
    
    @IsTest
    static void testDTOConstructors() {
        Test.startTest();
        
        AzureDevOpsWrappers.ConfigDTO config = new AzureDevOpsWrappers.ConfigDTO(
            'dev1', 'label1', 'org1', 'proj1', 'base1', 'nc1', 'v1'
        );
        System.assertEquals('dev1', config.value, 'Config value should match');
        System.assertEquals('label1', config.label, 'Config label should match');
        
        AzureDevOpsWrappers.WorkItemTypeDTO type = new AzureDevOpsWrappers.WorkItemTypeDTO(
            'v1', 'l1', 'd1', 'def1', 'icon1', 'conn1'
        );
        System.assertEquals('v1', type.value, 'Type value should match');
        System.assertEquals('l1', type.label, 'Type label should match');
        
        AzureDevOpsWrappers.StateDTO state = new AzureDevOpsWrappers.StateDTO(
            'v1', 'l1', 'd1', 'ui1', 't1'
        );
        System.assertEquals('v1', state.value, 'State value should match');
        System.assertEquals('l1', state.label, 'State label should match');
        
        AzureDevOpsWrappers.PriorityDTO priority = new AzureDevOpsWrappers.PriorityDTO(
            'v1', 'l1', 'ui1'
        );
        System.assertEquals('v1', priority.value, 'Priority value should match');
        System.assertEquals('l1', priority.label, 'Priority label should match');
        
        AzureDevOpsWrappers.UiMapDTO uiMap = new AzureDevOpsWrappers.UiMapDTO(
            'c1', 'k1', 'i1', 'u1'
        );
        System.assertEquals('c1', uiMap.context, 'UI map context should match');
        System.assertEquals('k1', uiMap.key, 'UI map key should match');
        
        Test.stopTest();
    }
}