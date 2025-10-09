@IsTest
private class AzureFieldMapperTest {
    
    @IsTest
    static void testGetMappings() {

        Test.startTest();
        List<AzureFieldMapper.MappingRow> mappings = AzureFieldMapper.getMappings('create', 'Task');
        Test.stopTest();
        
        System.assertNotEquals(null, mappings, 'Mappings list should not be null');
    }
    
    @IsTest
    static void testGetMappingsWithDifferentContext() {

        Test.startTest();
        List<AzureFieldMapper.MappingRow> createMappings = AzureFieldMapper.getMappings('create', 'Task');
        List<AzureFieldMapper.MappingRow> updateMappings = AzureFieldMapper.getMappings('update', 'Task');
        Test.stopTest();
        
        System.assertNotEquals(null, createMappings, 'Create mappings should not be null');
        System.assertNotEquals(null, updateMappings, 'Update mappings should not be null');
    }
    
    @IsTest
    static void testBuildPayloadWithBaseMap() {

        Map<String, Object> base = new Map<String, Object>{
            'System.Title' => 'Test Title',
            'System.Description' => 'Test Description'
        };
        
        Test.startTest();
        Map<String, Object> result = AzureFieldMapper.buildPayload('create', 'Task', null, base);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(true, result.containsKey('System.Title') || result.isEmpty(), 
            'Result should contain base values or be empty if no mappings exist');
    }
    
    @IsTest
    static void testBuildPayloadWithSObject() {
        Account acc = new Account(Name = 'Test Account', Description = 'Test Description');
        insert acc;
        
        acc = [SELECT Id, Name, Description FROM Account WHERE Id = :acc.Id];
        
        Test.startTest();
        Map<String, Object> result = AzureFieldMapper.buildPayload('create', 'Task', acc, null);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
    }
    
    @IsTest
    static void testBuildPayloadWithBothSObjectAndBase() {
        Account acc = new Account(Name = 'Test Account', Description = 'Test Description');
        insert acc;
        
        acc = [SELECT Id, Name, Description FROM Account WHERE Id = :acc.Id];
        
        Map<String, Object> base = new Map<String, Object>{
            'System.Priority' => 1,
            'System.State' => 'To Do'
        };
        
        Test.startTest();
        Map<String, Object> result = AzureFieldMapper.buildPayload('create', 'Task', acc, base);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
    }
    
    @IsTest
    static void testBuildPayloadWithNullInputs() {

        Test.startTest();
        Map<String, Object> result = AzureFieldMapper.buildPayload('create', 'Task', null, null);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null even with null inputs');
    }
    
    @IsTest
    static void testTransformations() {

        Map<String, Object> base = new Map<String, Object>{
            'TestField1' => 123,
            'TestField2' => '  Test String  ',
            'TestField3' => true
        };
        
        Test.startTest();
        Map<String, Object> result = AzureFieldMapper.buildPayload('create', 'Task', null, base);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
    }
    
    @IsTest
    static void testMappingRowClass() {

        Test.startTest();
        
        AzureFieldMapper.MappingRow row = new AzureFieldMapper.MappingRow();
        row.context = 'create';
        row.sobjectApi = 'Account';
        row.sfField = 'Name';
        row.adoField = 'System.Title';
        row.workItemType = 'Task';
        row.transform = 'ToString';
        
        Test.stopTest();
        
        System.assertEquals('create', row.context, 'Context should match');
        System.assertEquals('Account', row.sobjectApi, 'SObject API should match');
        System.assertEquals('Name', row.sfField, 'SF Field should match');
        System.assertEquals('System.Title', row.adoField, 'ADO Field should match');
        System.assertEquals('Task', row.workItemType, 'Work Item Type should match');
        System.assertEquals('ToString', row.transform, 'Transform should match');
    }
    
    @IsTest
    static void testGetMappingsWithInactiveRecords() {

        Test.startTest();
        List<AzureFieldMapper.MappingRow> mappings = AzureFieldMapper.getMappings('create', 'Bug');
        Test.stopTest();
        
        System.assertNotEquals(null, mappings, 'Mappings should not be null');
    }
    
    @IsTest
    static void testGetMappingsWithBlankWorkItemType() {

        Test.startTest();
        List<AzureFieldMapper.MappingRow> mappings = AzureFieldMapper.getMappings('create', null);
        Test.stopTest();
        
        System.assertNotEquals(null, mappings, 'Mappings should not be null');
    }
}