@IsTest
private class PicklistUtilTest {
    
    @IsTest
    static void testGetPicklistActiveOnly() {

        Test.startTest();
        List<AzureDevOpsWrappers.SelectOptionDTO> options = PicklistUtil.getPicklist('Account', 'Type', true);
        Test.stopTest();
        
        System.assertNotEquals(null, options, 'Options list should not be null');
        System.assertNotEquals(0, options.size(), 'Should have picklist values for Account Type');
    }
    
    @IsTest
    static void testGetPicklistAllValues() {

        Test.startTest();
        List<AzureDevOpsWrappers.SelectOptionDTO> options = PicklistUtil.getPicklist('Account', 'Type', false);
        Test.stopTest();
        
        System.assertNotEquals(null, options, 'Options list should not be null');
        System.assertNotEquals(0, options.size(), 'Should have picklist values for Account Type');
    }
    
    @IsTest
    static void testGetPicklistLeadStatus() {

        Test.startTest();
        List<AzureDevOpsWrappers.SelectOptionDTO> options = PicklistUtil.getPicklist('Lead', 'Status', true);
        Test.stopTest();
        
        System.assertNotEquals(null, options, 'Options list should not be null');
        System.assertNotEquals(0, options.size(), 'Should have picklist values for Lead Status');
        
        if (!options.isEmpty()) {
            AzureDevOpsWrappers.SelectOptionDTO firstOption = options[0];
            System.assertNotEquals(null, firstOption.value, 'Option value should not be null');
            System.assertNotEquals(null, firstOption.label, 'Option label should not be null');
        }
    }
    
    @IsTest
    static void testGetPicklistOpportunityStage() {

        Test.startTest();
        List<AzureDevOpsWrappers.SelectOptionDTO> options = PicklistUtil.getPicklist('Opportunity', 'StageName', true);
        Test.stopTest();
        
        System.assertNotEquals(null, options, 'Options list should not be null');
        System.assertNotEquals(0, options.size(), 'Should have picklist values for Opportunity StageName');
    }
    
    @IsTest
    static void testGetPicklistInvalidSObject() {

        Test.startTest();
        List<AzureDevOpsWrappers.SelectOptionDTO> options = PicklistUtil.getPicklist('InvalidObject', 'Type', true);
        Test.stopTest();
        
        System.assertNotEquals(null, options, 'Options list should not be null');
        System.assertEquals(0, options.size(), 'Should return empty list for invalid SObject');
    }
    
    @IsTest
    static void testGetPicklistInvalidField() {

        Test.startTest();
        List<AzureDevOpsWrappers.SelectOptionDTO> options = PicklistUtil.getPicklist('Account', 'InvalidField', true);
        Test.stopTest();
        
        System.assertNotEquals(null, options, 'Options list should not be null');
        System.assertEquals(0, options.size(), 'Should return empty list for invalid field');
    }
    
    @IsTest
    static void testGetPicklistNonPicklistField() {

        Test.startTest();
        List<AzureDevOpsWrappers.SelectOptionDTO> options = PicklistUtil.getPicklist('Account', 'Name', true);
        Test.stopTest();
        
        System.assertNotEquals(null, options, 'Options list should not be null');
        System.assertEquals(0, options.size(), 'Should return empty list for non-picklist field');
    }
    
    @IsTest
    static void testSelectOptionDTOConstructor() {

        Test.startTest();
        
        AzureDevOpsWrappers.SelectOptionDTO option = new AzureDevOpsWrappers.SelectOptionDTO('value1', 'Label 1');
        
        Test.stopTest();
        
        System.assertEquals('value1', option.value, 'Value should match');
        System.assertEquals('Label 1', option.label, 'Label should match');
    }
    
    @IsTest
    static void testGetPicklistCasePriority() {

        Test.startTest();
        List<AzureDevOpsWrappers.SelectOptionDTO> options = PicklistUtil.getPicklist('Case', 'Priority', true);
        Test.stopTest();
        
        System.assertNotEquals(null, options, 'Options list should not be null');
        System.assertNotEquals(0, options.size(), 'Should have picklist values for Case Priority');
    }
    
    @IsTest
    static void testGetPicklistMultipleCalls() {

        Test.startTest();
        
        List<AzureDevOpsWrappers.SelectOptionDTO> options1 = PicklistUtil.getPicklist('Account', 'Type', true);
        List<AzureDevOpsWrappers.SelectOptionDTO> options2 = PicklistUtil.getPicklist('Account', 'Type', false);
        List<AzureDevOpsWrappers.SelectOptionDTO> options3 = PicklistUtil.getPicklist('Lead', 'Status', true);
        
        Test.stopTest();
        
        System.assertNotEquals(null, options1, 'First call should return non-null list');
        System.assertNotEquals(null, options2, 'Second call should return non-null list');
        System.assertNotEquals(null, options3, 'Third call should return non-null list');
    }
    
    @IsTest
    static void testAuraEnabledAnnotation() {
        Test.startTest();
        List<AzureDevOpsWrappers.SelectOptionDTO> options = PicklistUtil.getPicklist('Account', 'Type', true);
        Test.stopTest();
        
        System.assertNotEquals(null, options, 'Cacheable method should execute successfully');
    }
}