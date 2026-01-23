# AZ-204 Exam Coverage Mapping

This document maps FnCast and FluxOps portfolio projects to **AZ-204: Developing Solutions for Microsoft Azure** exam objectives.

---

## 📊 Exam Domain Breakdown

| Domain | Weight | FnCast | FluxOps | Combined Coverage |
|--------|--------|--------|---------|-------------------|
| **1. Azure Compute** | 25-30% | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **2. Azure Storage** | 15-20% | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **3. Azure Security** | 20-25% | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **4. Monitoring & Optimize** | 15-20% | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **5. Azure Integration** | 10-15% | ⭐⭐ | ⭐⭐ | ⭐⭐⭐ |

**Legend**: ⭐ = Poor, ⭐⭐⭐ = Good, ⭐⭐⭐⭐⭐ = Excellent

---

## 1️⃣ Develop Azure Compute Solutions (25-30%)

### Azure App Service Web Apps

| Topic | FnCast | FluxOps | Code Examples |
|-------|--------|---------|---------------|
| Create and configure App Service | ❌ | ✅ | FluxOps: `infra/terraform/modules/function_app/` |
| Deploy code to App Service | ❌ | ✅ | FluxOps: `.gitlab-ci.yml` deploy stage |
| Configure deployment slots | ❌ | ❌ | **GAP** |
| Scale App Service | ❌ | ✅ | FluxOps: `variables.tf` (SKU configuration) |
| Configure App Service settings | ❌ | ✅ | FluxOps: Function App environment variables |

**Study Focus**: FluxOps demonstrates App Service Plan, Function App hosting, scaling options

---

### Azure Functions

| Topic | FnCast | FluxOps | Code Examples |
|-------|--------|---------|---------------|
| **Create Azure Functions** | ✅ | ✅ | Both projects have function apps |
| HTTP triggers | ✅ | ✅ | FnCast: `InferenceFunction/`, FluxOps: `function_app.py` |
| Blob triggers | ❌ | ✅ | FluxOps: `blob_trigger()` in `function_app.py` |
| Timer triggers | ❌ | ❌ | **GAP** |
| Queue triggers | ❌ | ❌ | **GAP** |
| Input/output bindings | ⚠️ | ⚠️ | Limited - mostly using SDK |
| Durable Functions | ❌ | ❌ | **GAP** |
| Function authorization | ✅ | ⚠️ | FnCast: Function keys mentioned in README |

**Study Resources**:
- **FnCast**: `InferenceFunction/__init__.py` - HTTP trigger pattern
- **FluxOps**: `src/function_app/function_app.py` - Multiple triggers

**Key Code Snippets**:

```python
# FnCast - HTTP Trigger (InferenceFunction)
import azure.functions as func

def main(req: func.HttpRequest) -> func.HttpResponse:
    # Load model from Blob Storage using Managed Identity
    # Perform inference
    # Return predictions
```

```python
# FluxOps - Blob Trigger
@app.blob_trigger(arg_name="myblob", path="models/{name}",
                  connection="AzureWebJobsStorage")
def blob_trigger(myblob: func.InputStream):
    # Triggered when new model uploaded
```

---

### Container Solutions

| Topic | FnCast | FluxOps | Code Examples |
|-------|--------|---------|---------------|
| Azure Container Instances | ❌ | ❌ | **GAP** |
| Azure Container Apps | ❌ | ❌ | **GAP** |
| Azure Container Registry | ❌ | ❌ | **GAP** |
| Docker containerization | ❌ | ❌ | **GAP** |

**Recommendation**: Add Dockerfile to one project to demonstrate containerization skills

---

## 2️⃣ Develop for Azure Storage (15-20%)

### Azure Blob Storage

| Topic | FnCast | FluxOps | Code Examples |
|-------|--------|---------|---------------|
| **Create and configure storage** | ✅ | ✅ | Both use Bicep/Terraform for storage accounts |
| Upload/download blobs | ✅ | ✅ | FnCast: `upload_model.py`, FluxOps: ML model storage |
| Blob properties & metadata | ⚠️ | ⚠️ | Basic usage |
| Blob lifecycle management | ❌ | ❌ | **GAP** |
| Blob versioning | ❌ | ✅ | FluxOps: `storage/main.tf` enables versioning |
| Access tiers (Hot/Cool/Archive) | ❌ | ⚠️ | FluxOps: Configurable via variables |
| SAS tokens | ❌ | ❌ | **GAP** - Using Managed Identity instead |
| Storage SDK usage | ✅ | ✅ | Both projects use azure-storage-blob |

**Study Resources**:
- **FnCast**: `scripts/upload_model.py` - BlobServiceClient usage
- **FluxOps**: `infra/terraform/modules/storage/main.tf` - Storage configuration

**Key Code Snippets**:

```python
# FnCast - Blob Storage Access with Managed Identity
from azure.storage.blob import BlobServiceClient
from azure.identity import DefaultAzureCredential

credential = DefaultAzureCredential()
blob_service = BlobServiceClient(
    account_url=f"https://{account_name}.blob.core.windows.net",
    credential=credential
)
```

```hcl
# FluxOps - Terraform Storage Account
resource "azurerm_storage_account" "main" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
  
  blob_properties {
    versioning_enabled = true
  }
}
```

---

### Azure Cosmos DB

| Topic | FnCast | FluxOps | Code Examples |
|-------|--------|---------|---------------|
| Create Cosmos DB resources | ❌ | ❌ | **MAJOR GAP** |
| Perform CRUD operations | ❌ | ❌ | **MAJOR GAP** |
| Manage consistency levels | ❌ | ❌ | **MAJOR GAP** |
| Partition strategies | ❌ | ❌ | **MAJOR GAP** |

**Recommendation**: Add Cosmos DB to store prediction logs or telemetry data

---

## 3️⃣ Implement Azure Security (20-25%)

### Managed Identities

| Topic | FnCast | FluxOps | Code Examples |
|-------|--------|---------|---------------|
| **System-assigned identity** | ✅ | ✅ | Both Function Apps use system-assigned MI |
| User-assigned identity | ❌ | ❌ | **GAP** |
| Access Azure resources with MI | ✅ | ✅ | Blob Storage, Key Vault access |
| DefaultAzureCredential | ✅ | ✅ | Both use azure-identity library |

**Study Resources**:
- **FnCast**: `infrastructure/main.bicep` - Managed Identity configuration
- **FluxOps**: `infra/terraform/modules/function_app/main.tf`

**Key Code Snippets**:

```bicep
// FnCast - Enable Managed Identity (Bicep)
resource functionApp 'Microsoft.Web/sites@2022-03-01' = {
  name: functionAppName
  identity: {
    type: 'SystemAssigned'
  }
}
```

```hcl
# FluxOps - Enable Managed Identity (Terraform)
resource "azurerm_linux_function_app" "main" {
  name = var.function_app_name
  
  identity {
    type = "SystemAssigned"
  }
}
```

---

### Azure Key Vault

| Topic | FnCast | FluxOps | Code Examples |
|-------|--------|---------|---------------|
| **Create and configure Key Vault** | ✅ | ✅ | Both have Key Vault in IaC |
| Store secrets | ✅ | ✅ | Connection strings, API keys |
| Access policies | ✅ | ✅ | Grant access to Managed Identity |
| RBAC for Key Vault | ⚠️ | ⚠️ | Using access policies, not RBAC |
| Secret rotation | ❌ | ❌ | **GAP** |
| Key Vault references in App Config | ⚠️ | ⚠️ | Referenced but not deeply explored |

**Study Resources**:
- **FnCast**: `infrastructure/main.bicep` - Key Vault setup
- **FluxOps**: `infra/terraform/modules/key_vault/main.tf`

---

### App Configuration

| Topic | FnCast | FluxOps | Code Examples |
|-------|--------|---------|---------------|
| Azure App Configuration service | ❌ | ❌ | **GAP** |
| Feature flags | ❌ | ❌ | **GAP** |
| Key Vault references | ❌ | ❌ | **GAP** |

**Recommendation**: Good candidate for enhancement

---

## 4️⃣ Monitor, Troubleshoot, and Optimize (15-20%)

### Application Insights

| Topic | FnCast | FluxOps | Code Examples |
|-------|--------|---------|---------------|
| **Configure Application Insights** | ✅ | ✅ | Both have App Insights configured |
| Custom telemetry | ⚠️ | ⚠️ | Basic logging, no custom events |
| Log queries (KQL) | ❌ | ❌ | **GAP** - No example queries |
| Availability tests | ❌ | ❌ | **GAP** |
| Performance monitoring | ✅ | ✅ | Automatic with App Insights |
| Application Map | ✅ | ✅ | Available in Azure Portal |

**Study Resources**:
- **FnCast**: Application Insights mentioned in README
- **FluxOps**: `infra/terraform/modules/app_insights/main.tf`

---

### Azure Monitor

| Topic | FnCast | FluxOps | Code Examples |
|-------|--------|---------|---------------|
| Metrics and alerts | ⚠️ | ⚠️ | Infrastructure exists, not configured |
| Log Analytics workspace | ❌ | ✅ | FluxOps: `app_insights/main.tf` |
| Diagnostic settings | ⚠️ | ⚠️ | Basic configuration |

---

### Caching

| Topic | FnCast | FluxOps | Code Examples |
|-------|--------|---------|---------------|
| Azure Cache for Redis | ❌ | ❌ | **MAJOR GAP** |
| CDN | ❌ | ❌ | **GAP** |
| In-memory caching | ⚠️ | ✅ | FluxOps: Model caching in `function_app.py` |

**Study Resources**:
- **FluxOps**: `src/function_app/function_app.py` - `_model_cache` variable

```python
# FluxOps - In-memory model caching
_model_cache = None

def load_model_from_blob():
    global _model_cache
    if _model_cache is not None:
        return _model_cache
    # Load model...
    _model_cache = model
    return model
```

---

## 5️⃣ Connect to and Consume Azure Services (10-15%)

### API Management

| Topic | FnCast | FluxOps | Code Examples |
|-------|--------|---------|---------------|
| Create APIM instance | ❌ | ❌ | **MAJOR GAP** |
| Configure policies | ❌ | ❌ | **MAJOR GAP** |
| Secure APIs | ⚠️ | ⚠️ | Using function keys only |

**Recommendation**: High-value addition for AZ-204

---

### Event-Based Solutions

| Topic | FnCast | FluxOps | Code Examples |
|-------|--------|---------|---------------|
| **Azure Event Grid** | ❌ | ❌ | **MAJOR GAP** |
| Azure Event Hubs | ❌ | ❌ | **MAJOR GAP** |
| Azure Service Bus | ❌ | ❌ | **MAJOR GAP** |
| Event Grid triggers | ❌ | ❌ | **MAJOR GAP** |

**Recommendation**: Critical gap - event-driven architecture is important for AZ-204

---

### Message-Based Solutions

| Topic | FnCast | FluxOps | Code Examples |
|-------|--------|---------|---------------|
| Azure Queue Storage | ❌ | ❌ | **GAP** |
| Azure Service Bus queues | ❌ | ❌ | **MAJOR GAP** |
| Azure Service Bus topics | ❌ | ❌ | **MAJOR GAP** |

---

## 📈 Coverage Summary

### Strong Areas ✅
- **Azure Functions** - Both projects demonstrate HTTP triggers, deployment, configuration
- **Blob Storage** - Upload/download, SDK usage, Managed Identity access
- **Managed Identity** - System-assigned identity, DefaultAzureCredential
- **Key Vault** - Secret storage, access policies
- **Application Insights** - Monitoring and logging
- **IaC** - Bicep (FnCast) and Terraform (FluxOps)
- **CI/CD** - GitLab and GitHub Actions

### Moderate Areas ⚠️
- **Function bindings** - Limited variety (mostly HTTP, one blob trigger)
- **Caching** - In-memory only, no Redis
- **Custom telemetry** - Basic logging, no custom events/metrics
- **RBAC** - Using access policies instead of RBAC model

### Critical Gaps ❌
1. **Cosmos DB** (15-20% of exam) - No coverage
2. **Event Grid / Event Hubs** (10-15% of exam) - No coverage
3. **Service Bus** (10-15% of exam) - No coverage
4. **API Management** (10-15% of exam) - No coverage
5. **Azure Cache for Redis** (5-10% of exam) - No coverage
6. **Containers** (5-10% of exam) - No coverage
7. **Durable Functions** (5-10% of exam) - No coverage

---

## 🎯 Recommended Enhancements (Priority Order)

### High Priority (Closes Major Gaps)

**1. Add Cosmos DB to FnCast** ⭐⭐⭐⭐⭐
- Store prediction logs/history
- Demonstrates: CRUD operations, partition keys, consistency levels
- **Impact**: Covers 15-20% of exam content

**2. Add Event Grid trigger to FluxOps** ⭐⭐⭐⭐⭐
- Trigger function on blob upload events
- Demonstrates: Event-driven architecture, Event Grid subscriptions
- **Impact**: Covers 10-15% of exam content

**3. Add Service Bus queue to FnCast** ⭐⭐⭐⭐
- Queue predictions for batch processing
- Demonstrates: Message queues, queue triggers, dead-letter queues
- **Impact**: Covers 10-15% of exam content

---

### Medium Priority (Strengthens Existing Coverage)

**4. Add Azure Cache for Redis** ⭐⭐⭐⭐
- Cache frequent predictions or model metadata
- Project: Either (FnCast preferred)
- **Impact**: Covers 5-10% of exam content

**5. Add API Management layer** ⭐⭐⭐
- Front FnCast API with APIM
- Demonstrates: Policies, rate limiting, API versioning
- **Impact**: Covers 10-15% of exam content

**6. Add Durable Functions example** ⭐⭐⭐
- Multi-step ML workflow (train → validate → deploy)
- Project: FluxOps
- **Impact**: Covers 5-10% of exam content

---

### Low Priority (Nice to Have)

**7. Add Timer trigger**
- Scheduled model retraining
- Project: FluxOps

**8. Add Queue trigger**
- Process items from Storage Queue
- Project: Either

**9. Containerize one project**
- Create Dockerfile, deploy to Container Apps
- Project: FnCast (smaller, simpler)

---

## 📚 Study Recommendations by Project

### Study FnCast For:
- ✅ Azure Functions basics (HTTP triggers)
- ✅ Blob Storage SDK usage
- ✅ Managed Identity implementation
- ✅ Key Vault integration
- ✅ Bicep IaC syntax
- ✅ Python Azure Functions development

### Study FluxOps For:
- ✅ Terraform IaC patterns
- ✅ Modular infrastructure design
- ✅ Multiple function triggers (HTTP + Blob)
- ✅ CI/CD pipeline patterns (GitLab + GitHub)
- ✅ Model caching strategies
- ✅ Comprehensive testing approach

### Study External Resources For:
- ❌ Cosmos DB operations
- ❌ Event Grid / Event Hubs
- ❌ Service Bus messaging
- ❌ API Management
- ❌ Azure Cache for Redis
- ❌ Durable Functions
- ❌ Container solutions

---

## 🗓️ Suggested Study Plan

### Week 1-2: Strengthen Existing Code
- Deep dive into FnCast Function App code
- Review FluxOps Terraform modules
- Practice deploying both projects
- **Lab**: Modify function triggers, add error handling

### Week 3-4: Add Cosmos DB (High Priority Gap)
- Learn Cosmos DB concepts (partition keys, consistency)
- Add Cosmos DB to FnCast for prediction logging
- Practice CRUD operations
- **Lab**: Query prediction history, analyze partition strategy

### Week 5-6: Add Event-Driven Architecture
- Learn Event Grid concepts
- Add Event Grid trigger to FluxOps
- Add Service Bus queue to FnCast
- **Lab**: Trace event flow, handle failures

### Week 7-8: Advanced Topics
- Add Redis caching
- Explore API Management
- Study Durable Functions (external examples)
- **Lab**: Performance tuning, monitoring

### Week 9-10: Practice & Review
- Deploy both projects from scratch
- Troubleshoot common issues
- Practice exam questions
- Review Azure documentation

---

## 📖 Key Documentation Links

### Official Microsoft Learn Paths
- [AZ-204 Learning Path](https://learn.microsoft.com/en-us/certifications/exams/az-204)
- [Azure Functions Documentation](https://learn.microsoft.com/en-us/azure/azure-functions/)
- [Azure Storage Documentation](https://learn.microsoft.com/en-us/azure/storage/)
- [Azure Cosmos DB Documentation](https://learn.microsoft.com/en-us/azure/cosmos-db/)
- [Azure Key Vault Documentation](https://learn.microsoft.com/en-us/azure/key-vault/)

### Hands-On Labs
- [Microsoft Learn Sandbox](https://learn.microsoft.com/en-us/training/)
- [Azure Free Account](https://azure.microsoft.com/free/)

---

## 💡 Quick Reference: Where to Find Code

| Concept | FnCast Location | FluxOps Location |
|---------|----------------|------------------|
| Function App code | `InferenceFunction/__init__.py` | `src/function_app/function_app.py` |
| IaC - Function App | `infrastructure/main.bicep` | `infra/terraform/modules/function_app/` |
| IaC - Storage | `infrastructure/main.bicep` | `infra/terraform/modules/storage/` |
| IaC - Key Vault | `infrastructure/main.bicep` | `infra/terraform/modules/key_vault/` |
| Managed Identity setup | `infrastructure/main.bicep` | `infra/terraform/modules/function_app/main.tf` |
| CI/CD Pipeline | `.gitlab-ci.yml`, `.github/workflows/` | `.gitlab-ci.yml`, `.github/workflows/` |
| Testing | `tests/test_inference.py` | `src/ml_pipeline/tests/` |
| Deployment scripts | `scripts/upload_model.py` | `scripts/validate-setup.ps1` |

---

## ✅ Self-Assessment Checklist

Before taking AZ-204, ensure you can:

**Azure Functions**
- [ ] Create Function Apps via CLI/Portal/IaC
- [ ] Implement HTTP, blob, timer, queue triggers
- [ ] Configure function app settings and app settings
- [ ] Deploy functions using multiple methods
- [ ] Implement function authorization
- [ ] Scale function apps

**Azure Storage**
- [ ] Create storage accounts with different options
- [ ] Upload/download blobs using SDK
- [ ] Configure lifecycle management
- [ ] Implement SAS tokens
- [ ] Use Managed Identity with storage

**Azure Security**
- [ ] Enable and use Managed Identities
- [ ] Store and retrieve secrets from Key Vault
- [ ] Configure RBAC for Azure resources
- [ ] Implement secure authentication patterns

**Monitoring**
- [ ] Configure Application Insights
- [ ] Write KQL queries for logs
- [ ] Set up alerts and metrics
- [ ] Interpret performance data

**Integration**
- [ ] Publish/consume messages with Service Bus
- [ ] Implement Event Grid handlers
- [ ] Configure API Management policies

---

**Document Version**: 1.0  
**Last Updated**: November 15, 2025  
**Next Review**: After adding Cosmos DB integration

---

**Study Tip**: Use both projects to demonstrate breadth (different IaC tools, different Azure services patterns) rather than depth in one area.
