# Salesforce Azure DevOps Integration - AI Coding Instructions

## Project Overview

This is a **Salesforce Lightning Web Component (LWC)** application that integrates with **Azure DevOps Work Items API**. It enables creating, updating, deleting, and viewing Azure DevOps work items (Tasks, Bugs, Epics) directly from Salesforce.

**Tech Stack:** Salesforce Apex (backend), Lightning Web Components (frontend), Azure DevOps REST API v6.0  
**API Version:** Salesforce API 62.0+

---

## Architecture Patterns

### Layered Architecture (Critical)
The codebase follows strict **3-tier separation** - never bypass layers:

1. **Controller Layer** (`AzureDevOpsController.cls`)
   - LWC-facing `@AuraEnabled` methods
   - Validates inputs, transforms UI data to service DTOs
   - **DO NOT** call Azure APIs directly - delegate to Facade/Service

2. **Service Layer** (`AzureDevOpsService.cls`, `AzureIntegrationFacade.cls`)
   - Business logic and authentication orchestration
   - Implements **dual-auth fallback**: Named Credential → Personal Access Token
   - Caches configurations via `AzureDevOpsCacheUtil` (300s TTL)

3. **Repository Layer** (`AzureDevOpsRepository.cls`)
   - HTTP callout execution only
   - Builds JSON-Patch payloads (`[{"op":"add","path":"/fields/System.Title","value":"..."}]`)
   - Parses Azure API responses to `AzureDevOpsWrappers.AzureResult`

**Example:** Creating a work item flows: `LWC → Controller.createWorkItem() → Facade.createWorkItem() → Service.createWorkItem() → Repository.sendRequest()`

### Configuration-Driven Design
All Azure DevOps settings are stored in **Custom Metadata Types** (never hardcode):

- `Azure_DevOps_Connection__mdt` - Organization/Project/Auth configs (accessed via `AdoConfigProvider`)
- `Azure_Work_Item_Type__mdt` - Allowed work item types (Task, Bug, Epic)
- `Azure_Work_Item_State__mdt` - Valid states per work item type (To Do, Doing, Done)
- `Azure_Priority__mdt` - Priority mappings (1=Critical → 4=Low)

**Pattern:** Always call `AdoConfigProvider.getConfigurations()` or `AdoConfigProvider.getConnection(devName)` instead of direct SOQL queries.

### Universal Modal System
**Single reusable modal** (`universalModal` LWC) replaces all dialog types. When adding new modals:

```javascript
import UniversalModal from 'c/universalModal';

// Confirmation
await UniversalModal.open({
    modalType: 'confirm',
    message: 'Delete this item?',
    variant: 'destructive', // Use for delete actions
    requireReason: true     // Adds required textarea
});

// Dynamic form
import UniversalModalHelper from 'c/universalModalHelper';
const fields = [
    UniversalModalHelper.createField('title', 'text', { required: true }),
    UniversalModalHelper.createField('type', 'combobox', { 
        options: [...], 
        icon: 'utility:task' 
    })
];
await UniversalModal.open({
    modalType: 'form',
    formConfig: UniversalModalHelper.createFormConfig(fields)
});
```
**See `docs/UNIVERSAL_MODAL_GUIDE.md` for complete examples** - always prefer this over creating new modal components.

---

## Critical Implementation Rules

### Authentication Patterns
**Dual-auth fallback** is implemented everywhere:
1. Try Named Credential (`callout:AzureDevOps_POC/...`)
2. If fails, retry with PAT (Personal Access Token) authentication
3. PAT uses `Authorization: Basic <base64(:token)>` header

**Example (from `AzureDevOpsService.cls`):**
```apex
if (config.hasNamedCredential()) {
    try {
        return createWorkItemWithNamedCredential(config, type, fields);
    } catch (AzureDevOpsException ex) {
        if (config.hasPersonalAccessToken()) {
            return createWorkItem(config.personalAccessToken, config, type, fields);
        }
        throw ex;
    }
}
```

### Terminal State Handling
Azure DevOps **rejects work item creation** with terminal states (Done, Closed, Resolved). Always remove these:
```apex
// Service layer automatically strips terminal states on create
private static Map<String, Object> removeTerminalState(Map<String, Object> fields) {
    Set<String> terminalStates = new Set<String>{'Done','Closed','Resolved'};
    if (fields.containsKey('System.State') && terminalStates.contains(...)) {
        copy.remove('System.State');
    }
    return copy;
}
```

### Azure API JSON-Patch Format
All create/update operations use **JSON-Patch** (`application/json-patch+json`):
```json
[
  {"op": "add", "path": "/fields/System.Title", "value": "My Task"},
  {"op": "add", "path": "/fields/System.State", "value": "To Do"},
  {"op": "add", "path": "/fields/Microsoft.VSTS.Common.Priority", "value": 2}
]
```
**Never send plain JSON** - use `buildPatchBody()` helper in Service layer.

### Caching Strategy
Use `AzureDevOpsCacheUtil.getOrCompute()` for configuration lookups:
```apex
private static AzureConfig getConfig(String configName) {
    String cacheKey = CONFIG_CACHE_PREFIX + configName;
    ConfigSupplier supplier = new ConfigSupplier(configName);
    return (AzureConfig) AzureDevOpsCacheUtil.getOrCompute(cacheKey, 300, supplier);
}
```
**Why:** Reduces metadata queries. Cache falls back to in-memory Map if platform cache unavailable.

---

## Testing & Deployment

### Test Patterns
All tests use **HttpCalloutMock** for Azure API responses:
```apex
@IsTest
private class SuccessMock implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(200);
        res.setBody('{"id": 123, "url": "...", "fields": {...}}');
        return res;
    }
}

Test.setMock(HttpCalloutMock.class, new SuccessMock());
AzureDevOpsWrappers.AzureResult result = AzureDevOpsService.createWorkItem(...);
```
**Never mock at service layer** - mock HTTP callouts only.

### PMD Suppressions
The codebase uses specific PMD suppressions with comments explaining why:
- `@SuppressWarnings('PMD.CognitiveComplexity')` - Service/Controller classes aggregate multiple operations
- `//NOPMD` inline - For intentional PAT authentication, DTOs with many parameters

**Pattern:** Always add explanatory comments when suppressing PMD warnings.

### Deployment Commands
```powershell
# Authorize org
sf org login web -a MyOrg

# Deploy to org
sf project deploy start -o MyOrg

# Run Apex tests
sf apex run test --test-level RunLocalTests -o MyOrg

# Create scratch org
sf org create scratch -f config/project-scratch-def.json -a MyScratch
```

---

## Common Workflows

### Adding a New Work Item Field
1. Update `AzureDevOpsController.createWorkItem()` signature to accept new parameter
2. Add field to `fields` map in `buildCreateWorkItemContext()`
3. Update `universalModalHelper` form config if UI-facing
4. Azure API accepts any `System.*` or `Microsoft.VSTS.*` field automatically

### Adding a New Configuration
1. Create `Azure_DevOps_Connection__mdt` record:
   ```xml
   <customMetadata>
       <label>My Environment</label>
       <values>
           <field>Organization__c</field>
           <value>my-org</value>
       </values>
       <values>
           <field>Project__c</field>
           <value>my-project</value>
       </values>
       <values>
           <field>NamedCredential__c</field>
           <value>AzureDevOps_MyEnv</value>
       </values>
   </customMetadata>
   ```
2. No code changes needed - `AdoConfigProvider` auto-discovers active configs

### Debugging Failed Callouts
1. Check `System.debug()` logs for endpoint URLs
2. Verify Named Credential exists in Setup → Named Credentials
3. Test PAT manually: `Authorization: Basic <base64(:PAT)>`
4. Confirm Remote Site Settings allow `https://dev.azure.com`

---

## Key Files Reference

| File | Purpose |
|------|---------|
| `AzureDevOpsService.cls` | Core business logic, dual-auth, JSON-Patch builder |
| `AdoConfigProvider.cls` | Custom metadata access, caching work item types/states |
| `AzureDevOpsController.cls` | LWC API endpoints, permission checks |
| `universalModal/` | Reusable modal for confirms/forms/lists (see `docs/UNIVERSAL_MODAL_GUIDE.md`) |
| `AzureDevOpsCacheUtil.cls` | Platform cache wrapper with in-memory fallback |
| `Azure_DevOps_Connection__mdt` | Connection configs (org/project/auth) |

---

## Code Conventions

- **Error Handling:** Use `AzureDevOpsService.AzureDevOpsException` for domain errors, `AuraHandledException` for LWC responses
- **Nullability:** Always check `String.isBlank()`, never `== null` for strings
- **Field Names:** Azure fields use dot notation: `System.Title`, `Microsoft.VSTS.Common.Priority`
- **Permissions:** Check `Azure_DevOps_Edit` permission set for write operations (see `hasEditPermission()`)
- **LWC Imports:** Use `@wire` for cacheable Apex, direct `await` for non-cacheable

**When in doubt, follow existing patterns in `AzureDevOpsController.cls` or `AzureDevOpsService.cls`.**
