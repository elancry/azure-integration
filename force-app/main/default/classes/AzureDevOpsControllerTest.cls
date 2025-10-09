@IsTest
public class AzureDevOpsControllerTest {
    
   
    private class SuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            
            if (req.getMethod() == 'PATCH') {
                res.setBody('{' +
                    '"id": 123,' +
                    '"url": "https://dev.azure.com/elancry/POC/_apis/wit/workitems/123",' +
                    '"fields": {' +
                        '"System.Title": "Updated Task",' +
                        '"System.WorkItemType": "Task",' +
                        '"System.State": "Done",' +
                        '"Microsoft.VSTS.Common.Priority": 1' +
                    '}' +
                '}');
            } else {
                res.setBody('{' +
                    '"id": 456,' +
                    '"url": "https://dev.azure.com/elancry/POC/_apis/wit/workitems/456",' +
                    '"fields": {' +
                        '"System.Title": "New Task",' +
                        '"System.WorkItemType": "Task",' +
                        '"System.State": "To Do"' +
                    '}' +
                '}');
            }
            
            return res;
        }
    }
    
   
    private class ErrorMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(400);
            res.setBody('{"message":"Bad Request","typeName":"ValidationException"}');
            return res;
        }
    }
    
   
    private class WorkItemsQueryMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            
            String endpoint = req.getEndpoint();
            
            if (endpoint.contains('wiql')) {
                res.setBody('{"workItems":[{"id":123,"url":"https://dev.azure.com/elancry/POC/_apis/wit/workitems/123"}]}');
            }
            else if (endpoint.contains('workitems?ids=')) {
                res.setBody('{' +
                    '"count": 1,' +
                    '"value": [{' +
                        '"id": 123,' +
                        '"fields": {' +
                            '"System.Id": 123,' +
                            '"System.Title": "Test Task",' +
                            '"System.WorkItemType": "Task",' +
                            '"System.State": "To Do",' +
                            '"Microsoft.VSTS.Common.Priority": 2,' +
                            '"System.CreatedDate": "2025-01-01T00:00:00Z",' +
                            '"System.ChangedDate": "2025-01-02T00:00:00Z",' +
                            '"System.AssignedTo": {"displayName": "Test User"}' +
                        '}' +
                    '}]' +
                '}');
            }
            
            return res;
        }
    }
    
   
    @TestSetup
    static void setupTestData() {

        System.debug('Test setup complete');
    }
    
   
    @IsTest
    static void testGetAvailableConfigurations() {
        Test.startTest();
        List<AzureDevOpsWrappers.ConfigurationOption> configs = AzureDevOpsController.getAvailableConfigurations();
        Test.stopTest();
        
        System.assertNotEquals(null, configs, 'Configurations should not be null');
    }
    
   
    @IsTest
    static void testGetWorkItemTypes() {
        Test.startTest();
        List<AzureDevOpsWrappers.WorkItemTypeOption> types = AzureDevOpsController.getWorkItemTypes();
        Test.stopTest();
        
        System.assertNotEquals(null, types, 'Work item types should not be null');
        System.assert(types.size() > 0, 'Should return at least one work item type');
        
    }
    
   
    @IsTest
    static void testGetAvailableStates() {
        Test.startTest();
    List<AzureDevOpsWrappers.StateOption> states = AzureDevOpsController.getAvailableStatesForType(null);
        Test.stopTest();
        
        System.assertNotEquals(null, states, 'States should not be null');
        System.assert(states.size() > 0, 'Should return at least one state');
        
        Set<String> stateValues = new Set<String>();
        for (AzureDevOpsWrappers.StateOption state : states) {
            stateValues.add(state.value);
        }
        System.assert(stateValues.contains('To Do'), 'Should include To Do state');
        System.assert(stateValues.contains('Doing'), 'Should include Doing state');
        System.assert(stateValues.contains('Done'), 'Should include Done state');
    }
    
   
    @IsTest
    static void testCreateWorkItemMissingParameters() {
        Test.startTest();

        AzureDevOpsWrappers.WorkItemResult result1 = AzureDevOpsController.createWorkItem(
            null, 'Task', 'Test Title', 'Description', 'To Do', 2
        );
        System.assertEquals(false, result1.success, 'Should fail with missing configuration');

        AzureDevOpsWrappers.WorkItemResult result2 = AzureDevOpsController.createWorkItem(
            'POC_Environment', null, 'Test Title', 'Description', 'To Do', 2
        );
        System.assertEquals(false, result2.success, 'Should fail with missing work item type');

        AzureDevOpsWrappers.WorkItemResult result3 = AzureDevOpsController.createWorkItem(
            'POC_Environment', 'Task', null, 'Description', 'To Do', 2
        );
        System.assertEquals(false, result3.success, 'Should fail with missing title');
        
        Test.stopTest();
    }
    
   
    @IsTest
    static void testUpdateWorkItemSuccess() {
        Test.setMock(HttpCalloutMock.class, new SuccessMock());
        
        Test.startTest();
        AzureDevOpsWrappers.WorkItemResult result = AzureDevOpsController.updateWorkItem(
            'POC_Environment',
            123,
            'Updated Task',
            'Updated Description',
            'Done',
            1
        );
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
    }
    
   
    @IsTest
    static void testUpdateWorkItemMissingParameters() {
        Test.startTest();

        AzureDevOpsWrappers.WorkItemResult result1 = AzureDevOpsController.updateWorkItem(
            null, 123, 'Updated Title', 'Description', 'Done', 1
        );
        System.assertEquals(false, result1.success, 'Should fail with missing configuration');

        AzureDevOpsWrappers.WorkItemResult result2 = AzureDevOpsController.updateWorkItem(
            'POC_Environment', null, 'Updated Title', 'Description', 'Done', 1
        );
        System.assertEquals(false, result2.success, 'Should fail with missing work item ID');
        
        Test.stopTest();
    }
    
    @IsTest
    static void testUpdateWorkItemWithPriority() {
        Test.setMock(HttpCalloutMock.class, new SuccessMock());
        
        Test.startTest();

        AzureDevOpsWrappers.WorkItemResult result1 = AzureDevOpsController.updateWorkItem(
            'POC_Environment', 123, 'Updated Task', 'Description', 'Done', 1
        );
        System.assertNotEquals(null, result1, 'Result should not be null for priority 1');

        AzureDevOpsWrappers.WorkItemResult result2 = AzureDevOpsController.updateWorkItem(
            'POC_Environment', 123, 'Updated Task', 'Description', 'Done', 4
        );
        System.assertNotEquals(null, result2, 'Result should not be null for priority 4');

        AzureDevOpsWrappers.WorkItemResult result3 = AzureDevOpsController.updateWorkItem(
            'POC_Environment', 123, 'Updated Task', 'Description', 'Done', 5
        );
        System.assertNotEquals(null, result3, 'Result should not be null even with invalid priority');
        
        Test.stopTest();
    }
    
    @IsTest
    static void testWorkItemResultWrapper() {
        Test.startTest();
        
        AzureDevOpsWrappers.WorkItemResult result = new AzureDevOpsWrappers.WorkItemResult(
            true,
            'Success message',
            123,
            'https://dev.azure.com/test',
            'Task',
            'Test Title'
        );
        
        System.assertEquals(true, result.success, 'Success should be true');
        System.assertEquals('Success message', result.message, 'Message should match');
        System.assertEquals(123, result.workItemId, 'Work item ID should match');
        System.assertEquals('https://dev.azure.com/test', result.workItemUrl, 'URL should match');
        System.assertEquals('Task', result.workItemType, 'Work item type should match');
        System.assertEquals('Test Title', result.title, 'Title should match');
        
        Test.stopTest();
    }
    
    @IsTest
    static void testConfigurationOptionWrapper() {
        Test.startTest();
        
        AzureDevOpsWrappers.ConfigurationOption config = new AzureDevOpsWrappers.ConfigurationOption(
            'POC_Environment',
            'POC Environment (elancry/POC)',
            'elancry',
            'POC'
        );
        
        System.assertEquals('POC_Environment', config.value, 'Value should match');
        System.assertEquals('POC Environment (elancry/POC)', config.label, 'Label should match');
        System.assertEquals('elancry', config.organization, 'Organization should match');
        System.assertEquals('POC', config.project, 'Project should match');
        
        Test.stopTest();
    }
    
   
    @IsTest
    static void testWorkItemTypeOptionWrapper() {
        Test.startTest();
        
        AzureDevOpsWrappers.WorkItemTypeOption type = new AzureDevOpsWrappers.WorkItemTypeOption(
            'Task',
            'Task',
            'Task for tracking work items'
        );
        
        System.assertEquals('Task', type.value, 'Value should match');
        System.assertEquals('Task', type.label, 'Label should match');
        System.assertEquals('Task for tracking work items', type.description, 'Description should match');
        
        Test.stopTest();
    }
    
   
    @IsTest
    static void testStateOptionWrapper() {
        Test.startTest();
        
        AzureDevOpsWrappers.StateOption state = new AzureDevOpsWrappers.StateOption(
            'To Do',
            'To Do',
            'Work item is ready to be started'
        );
        
        System.assertEquals('To Do', state.value, 'Value should match');
        System.assertEquals('To Do', state.label, 'Label should match');
        System.assertEquals('Work item is ready to be started', state.description, 'Description should match');
        
        Test.stopTest();
    }
}