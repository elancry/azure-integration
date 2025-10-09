@IsTest
public class AzureDevOpsServiceTest {

    private class SuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            
            if (req.getMethod() == 'POST' && req.getEndpoint().contains('wiql')) {
                res.setBody('{"workItems": [{"id": 123}, {"id": 456}]}');
            } else if (req.getMethod() == 'GET' && req.getEndpoint().contains('ids=')) {
                res.setBody('{"value": [{"id": 123,"url": "https://dev.azure.com/org/proj/_apis/wit/workitems/123","fields": {"System.Id": 123,"System.Title": "Test Task","System.WorkItemType": "Task","System.State": "To Do","Microsoft.VSTS.Common.Priority": 2}}]}');
            } else if (req.getMethod() == 'DELETE') {
                res.setBody('');
            } else {
                res.setBody('{"id": 123,"url": "https://dev.azure.com/org/proj/_apis/wit/workitems/123","fields": {"System.Id": 123,"System.Title": "Test Task","System.WorkItemType": "Task","System.State": "To Do","Microsoft.VSTS.Common.Priority": 2}}');
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

    @IsTest 
    static void testCreateWorkItemWithConfigSuccess() {
        Test.setMock(HttpCalloutMock.class, new SuccessMock());
        
        Map<String, Object> fields = new Map<String, Object>{
            'System.Title' => 'Test Task',
            'System.Description' => 'Test Description',
            'System.State' => 'To Do'
        };
        
        Test.startTest();
        try {
            AzureDevOpsWrappers.AzureResult result = AzureDevOpsService.createWorkItem('POC_Environment', 'Task', fields);
            System.assertNotEquals(null, result, 'Result should not be null');
            System.assertEquals(123, result.id, 'Work item ID should match');
        } catch (AzureDevOpsService.AzureDevOpsException e) {
            System.assert(e.getMessage().contains('Configuration not found') || 
                         e.getMessage().contains('must have either'), 
                         'Exception should be about configuration');
        }
        Test.stopTest();
    }

    @IsTest 
    static void testUpdateWorkItemWithConfigSuccess() {
        Test.setMock(HttpCalloutMock.class, new SuccessMock());
        
        Map<String, Object> fields = new Map<String, Object>{
            'System.Title' => 'Updated Task',
            'System.State' => 'Done'
        };
        
        Test.startTest();
        try {
            AzureDevOpsWrappers.AzureResult result = AzureDevOpsService.updateWorkItem('POC_Environment', 123, fields);
            System.assertNotEquals(null, result, 'Result should not be null');
        } catch (AzureDevOpsService.AzureDevOpsException e) {
            System.assert(e.getMessage().contains('Configuration not found') || 
                         e.getMessage().contains('must have either'), 
                         'Exception should be about configuration');
        }
        Test.stopTest();
    }

    @IsTest 
    static void testCreateWorkItemWithPATSuccess() {
        Test.setMock(HttpCalloutMock.class, new SuccessMock());
        
        AzureDevOpsWrappers.AzureConfig config = new AzureDevOpsWrappers.AzureConfig(
            'elancry', 'POC', null, '6.0', 'testPAT'
        );
        
        Map<String, Object> fields = new Map<String, Object>{
            'System.Title' => 'Test Task',
            'System.Description' => 'Test Description'
        };
        
        Test.startTest();
        AzureDevOpsWrappers.AzureResult result = AzureDevOpsService.createWorkItem('testPAT', config, 'Task', fields);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(123, result.id, 'Work item ID should match');
    }

    @IsTest 
    static void testUpdateWorkItemWithPATSuccess() {
        Test.setMock(HttpCalloutMock.class, new SuccessMock());
        
        AzureDevOpsWrappers.AzureConfig config = new AzureDevOpsWrappers.AzureConfig(
            'elancry', 'POC', null, '6.0', 'testPAT'
        );
        
        Map<String, Object> fields = new Map<String, Object>{
            'System.Title' => 'Updated Task',
            'System.State' => 'Done'
        };
        
        Test.startTest();
        AzureDevOpsWrappers.AzureResult result = AzureDevOpsService.updateWorkItem('testPAT', config, 123, fields);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(123, result.id, 'Work item ID should match');
    }

    @IsTest 
    static void testCreateWorkItemError() {
        Test.setMock(HttpCalloutMock.class, new ErrorMock());
        
        AzureDevOpsWrappers.AzureConfig config = new AzureDevOpsWrappers.AzureConfig(
            'elancry', 'POC', null, '6.0', 'testPAT'
        );
        
        Map<String, Object> fields = new Map<String, Object>{
            'System.Title' => 'Test Task'
        };
        
        Test.startTest();
        try {
            AzureDevOpsService.createWorkItem('testPAT', config, 'Task', fields);
            System.assert(false, 'Should throw exception on 400 error');
        } catch (AzureDevOpsService.AzureDevOpsException e) {
            System.assert(e.getMessage().contains('400'), 'Exception should mention status code');
        }
        Test.stopTest();
    }

    @IsTest 
    static void testMissingParameters() {
        AzureDevOpsWrappers.AzureConfig config = new AzureDevOpsWrappers.AzureConfig(
            'elancry', 'POC', null, '6.0', 'testPAT'
        );
        
        Map<String, Object> fields = new Map<String, Object>{'System.Title' => 'Test'};
        
        Test.startTest();

        try {
            AzureDevOpsService.createWorkItem(null, config, 'Task', fields);
            System.assert(false, 'Should throw exception for missing PAT');
        } catch (AzureDevOpsService.AzureDevOpsException e) {
            System.assert(e.getMessage().contains('Missing required parameters'), 
                         'Exception should mention missing parameters');
        }

        try {
            AzureDevOpsService.createWorkItem('testPAT', config, null, fields);
            System.assert(false, 'Should throw exception for missing work item type');
        } catch (AzureDevOpsService.AzureDevOpsException e) {
            System.assert(e.getMessage().contains('Missing required parameters'), 
                         'Exception should mention missing parameters');
        }
        
        Test.stopTest();
    }

    @IsTest
    static void testDeleteWorkItemWithPATSuccess() {
        Test.setMock(HttpCalloutMock.class, new SuccessMock());

        AzureDevOpsWrappers.AzureConfig config = new AzureDevOpsWrappers.AzureConfig(
            'elancry', 'POC', null, '6.0', 'testPAT'
        );

        Test.startTest();
        AzureDevOpsWrappers.AzureResult result = AzureDevOpsService.deleteWorkItem('testPAT', config, 123);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(123, result.id, 'Work item ID should match');
    }

    @IsTest
    static void testDeleteWorkItemError() {
        Test.setMock(HttpCalloutMock.class, new ErrorMock());

        AzureDevOpsWrappers.AzureConfig config = new AzureDevOpsWrappers.AzureConfig(
            'elancry', 'POC', null, '6.0', 'testPAT'
        );

        Test.startTest();
        try {
            AzureDevOpsService.deleteWorkItem('testPAT', config, 123);
            System.assert(false, 'Should throw exception on 400 error');
        } catch (AzureDevOpsService.AzureDevOpsException e) {
            System.assert(e.getMessage().contains('400'), 'Exception should mention status code');
        }
        Test.stopTest();
    }
}