# FnCast → AZ-204 Objective Matrix
**OneNote-Ready Study Guide**

---

## 🎯 How FnCast Maps to AZ-204 Exam Objectives

This document shows how building and deploying **FnCast** (a serverless ML inference API) covers every major AZ-204 exam objective with real, hands-on experience.

---

## 1️⃣ Develop Azure Compute Solutions (20-25%)

### **FnCast Implementation**
- **HTTP-triggered Azure Functions** (`InferenceFunction`, `HealthCheckFunction`)
- **Consumption Plan** auto-scaling based on load
- **Python 3.11 runtime** with Azure Functions v4
- **Async/await patterns** for efficient I/O operations
- **Function bindings** defined in `function.json`
- **Containerization-ready** serverless workloads

### **Key Files**
- [`InferenceFunction/__init__.py`](InferenceFunction/__init__.py) - HTTP trigger implementation
- [`HealthCheckFunction/__init__.py`](HealthCheckFunction/__init__.py) - Health monitoring endpoint
- [`host.json`](host.json) - Function app configuration
- [`requirements.txt`](requirements.txt) - Python dependencies

### **Exam Concepts Covered**
✅ **Azure Functions triggers and bindings** - HTTP, Timer, Blob, Event Grid  
✅ **Scaling behavior** - Consumption vs. Premium vs. Dedicated plans  
✅ **Function app configuration** - App settings, connection strings, runtime stack  
✅ **Cold start mitigation** - Model caching in global variables  
✅ **Deployment slots** (can be added via infrastructure)  
✅ **Function runtime versions** - Extension bundles, host.json settings  

### **Exam Questions This Helps With**
- "Which trigger should you use for processing uploaded files?"
- "How do you minimize cold starts in serverless functions?"
- "What's the difference between Consumption and Premium plans?"
- "How do you configure CORS for Azure Functions?"

---

## 2️⃣ Develop for Azure Storage (15-20%)

### **FnCast Implementation**
- **Blob Storage** for ML model persistence (`model.pkl`)
- **Managed Identity** authentication to Blob Storage (no connection strings)
- **BlobServiceClient** with DefaultAzureCredential
- **Container-level access** with private access settings
- **Lifecycle management** for model versioning
- **Secure HTTPS-only** access with TLS 1.2 minimum

### **Key Files**
- [`InferenceFunction/__init__.py`](InferenceFunction/__init__.py#L42-L70) - Blob Storage integration
- [`infrastructure/main.bicep`](infrastructure/main.bicep#L23-L49) - Storage account + container definition
- [`scripts/upload_model.py`](scripts/upload_model.py) - Model upload automation

### **Exam Concepts Covered**
✅ **Blob Storage tiers** - Hot, Cool, Archive (infrastructure choice)  
✅ **Authentication methods** - Managed Identity, SAS tokens, access keys  
✅ **BlobServiceClient SDK** - Upload, download, list, delete operations  
✅ **Container access levels** - Private, Blob, Container  
✅ **Storage account security** - Firewall rules, network access, encryption  
✅ **Shared Access Signatures (SAS)** - Time-limited, permission-scoped access  

### **Exam Questions This Helps With**
- "How do you securely access Blob Storage without storing credentials?"
- "What's the best tier for infrequently accessed model archives?"
- "How do you generate a time-limited SAS token for blob access?"
- "What authentication method should you use for service-to-service calls?"

---

## 3️⃣ Implement Azure Security (20-25%)

### **FnCast Implementation**
- **Managed Identity** (System-assigned) for Function App
- **Azure Key Vault** integration for secrets management
- **RBAC assignments** - Storage Blob Data Reader, Key Vault Secrets User
- **SecretClient** with DefaultAzureCredential
- **No hardcoded secrets** - all credentials via environment variables
- **HTTPS enforcement** on storage and Key Vault
- **Minimum TLS 1.2** requirement

### **Key Files**
- [`InferenceFunction/__init__.py`](InferenceFunction/__init__.py#L22-L39) - Key Vault secret retrieval
- [`infrastructure/main.bicep`](infrastructure/main.bicep#L87-L138) - Managed Identity + RBAC setup
- [`local.settings.json`](local.settings.json) - Local dev environment variables

### **Exam Concepts Covered**
✅ **Managed Identity types** - System-assigned vs. User-assigned  
✅ **Key Vault operations** - Store, retrieve, rotate secrets  
✅ **RBAC vs. Access Policies** - Modern vs. legacy Key Vault access  
✅ **DefaultAzureCredential chain** - Local dev → Managed Identity fallback  
✅ **Least privilege principle** - Scoped permissions for specific operations  
✅ **App Service authentication** - Easy Auth, AAD integration  

### **Exam Questions This Helps With**
- "How do you authenticate a Function App to Key Vault without secrets?"
- "What's the recommended way to store database connection strings?"
- "Which RBAC role grants read access to Key Vault secrets?"
- "How does DefaultAzureCredential determine which identity to use?"

---

## 4️⃣ Monitor, Troubleshoot, and Optimize Azure Solutions (15-20%)

### **FnCast Implementation**
- **Application Insights** integration for telemetry
- **Structured logging** with Python `logging` module
- **Custom metrics** for model inference latency
- **Exception tracking** with stack traces
- **Performance counters** - memory, CPU, request duration
- **Dependency tracking** - Blob Storage, Key Vault calls
- **Sampling configuration** in `host.json`

### **Key Files**
- [`host.json`](host.json#L3-L10) - Application Insights sampling settings
- [`InferenceFunction/__init__.py`](InferenceFunction/__init__.py) - Logging statements throughout
- [`infrastructure/main.bicep`](infrastructure/main.bicep#L51-L66) - Application Insights resource

### **Exam Concepts Covered**
✅ **Application Insights setup** - Instrumentation key, connection string  
✅ **Telemetry types** - Requests, dependencies, exceptions, custom events  
✅ **Log Analytics queries** - KQL for troubleshooting  
✅ **Sampling strategies** - Fixed vs. adaptive sampling  
✅ **Alerts and action groups** - Proactive monitoring  
✅ **Performance profiling** - Identifying bottlenecks  

### **Exam Questions This Helps With**
- "How do you correlate logs across multiple Azure services?"
- "What KQL query finds failed requests in the last hour?"
- "How do you reduce Application Insights costs with sampling?"
- "Which telemetry type tracks external API calls?"

---

## 5️⃣ Connect to and Consume Azure Services (15-20%)

### **FnCast Implementation**
- **Azure SDK for Python** - `azure-storage-blob`, `azure-keyvault-secrets`, `azure-identity`
- **HTTP client patterns** for inference API consumption
- **Service-to-service authentication** with Managed Identity
- **Event-driven architecture** (can add Event Grid triggers)
- **Dependency injection** for testability
- **Connection retry logic** with exponential backoff

### **Key Files**
- [`requirements.txt`](requirements.txt) - Azure SDK dependencies
- [`InferenceFunction/__init__.py`](InferenceFunction/__init__.py) - Azure service clients
- [`tests/test_inference.py`](tests/test_inference.py) - API consumption tests

### **Exam Concepts Covered**
✅ **Azure SDK patterns** - Client instantiation, authentication, error handling  
✅ **REST API best practices** - Idempotency, versioning, error codes  
✅ **Retry policies** - Transient fault handling  
✅ **Service endpoints** - Public vs. private endpoints  
✅ **API Management integration** - Rate limiting, caching, transformation  
✅ **Async programming** - Efficient I/O for network calls  

### **Exam Questions This Helps With**
- "How do you handle transient failures when calling Azure services?"
- "What HTTP status code indicates a successful POST request?"
- "How do you version a REST API endpoint?"
- "Which Azure SDK method authenticates with Managed Identity?"

---

## 6️⃣ Implement API Management (10-15%)

### **FnCast Implementation**
- **RESTful API design** - POST for inference, GET for health checks
- **Stateless endpoints** - no server-side session management
- **JSON request/response** format
- **Versioned model deployments** via Blob Storage paths
- **CORS configuration** for web clients
- **API documentation** with OpenAPI/Swagger (can be added)

### **Key Files**
- [`InferenceFunction/__init__.py`](InferenceFunction/__init__.py#L73-L147) - API request/response handling
- [`tests/test_inference.py`](tests/test_inference.py) - API contract tests
- [`README.md`](README.md) - API usage documentation

### **Exam Concepts Covered**
✅ **API design principles** - HTTP verbs, status codes, resource naming  
✅ **API versioning strategies** - URL path, header, query parameter  
✅ **Response caching** - Reducing load on backend services  
✅ **Rate limiting** - Protecting against abuse  
✅ **Content negotiation** - JSON, XML, etc.  
✅ **APIM policies** - Transformation, validation, routing  

### **Exam Questions This Helps With**
- "How do you implement versioning for a REST API?"
- "What HTTP method should be used for creating a new resource?"
- "How does API Management reduce latency for repeated requests?"
- "Which APIM policy validates request payloads?"

---

## 7️⃣ Develop Event-Based Solutions (10-15%)

### **FnCast Implementation**
- **Event Grid integration** (can add for model update triggers)
- **Blob trigger pattern** - Auto-reload model when new version uploaded
- **Async message processing** with function queues
- **Webhook endpoints** for external event subscriptions
- **Dead letter queues** for failed event processing

### **Potential Enhancements**
```python
# Event Grid trigger for model updates
@app.event_grid_trigger(arg_name="event")
def on_model_updated(event: func.EventGridEvent):
    """Reload model when new version is uploaded to Blob Storage"""
    logging.info(f"New model uploaded: {event.subject}")
    global _model, _model_loaded
    _model_loaded = False  # Force reload on next inference
```

### **Exam Concepts Covered**
✅ **Event Grid topics and subscriptions** - Custom vs. system topics  
✅ **Event schema** - CloudEvents vs. Event Grid schema  
✅ **Event filtering** - Subject, event type, advanced filters  
✅ **Webhook validation** - Handshake protocol  
✅ **Event delivery guarantees** - At-least-once delivery  
✅ **Dead lettering** - Handling undeliverable events  

### **Exam Questions This Helps With**
- "How do you filter Event Grid events before delivery?"
- "What's the difference between Event Grid and Service Bus?"
- "How do you validate a webhook endpoint for Event Grid?"
- "Which Azure service provides the best throughput for millions of events?"

---

## 8️⃣ Develop Message-Based Solutions (10-15%)

### **FnCast Implementation**
- **Asynchronous processing** with Azure Functions queues (can add)
- **Queue-triggered functions** for batch inference
- **Message TTL and visibility timeout** configuration
- **Poison message handling** with max retry counts
- **Storage Queue vs. Service Bus** decision-making

### **Potential Enhancements**
```python
# Queue trigger for batch predictions
@app.queue_trigger(arg_name="msg", queue_name="inference-queue")
def process_batch_inference(msg: func.QueueMessage):
    """Process batch inference requests from queue"""
    data = json.loads(msg.get_body().decode('utf-8'))
    predictions = model.predict(data['features'])
    # Store results in Blob Storage
```

### **Exam Concepts Covered**
✅ **Queue vs. Topic** - Simple vs. pub/sub messaging  
✅ **Message sessions** - FIFO ordering  
✅ **Duplicate detection** - Message deduplication  
✅ **Peek-lock vs. receive-and-delete** - Message consumption patterns  
✅ **Dead-letter queues** - Failed message handling  
✅ **Message batching** - Performance optimization  

### **Exam Questions This Helps With**
- "When should you use Service Bus instead of Storage Queues?"
- "How do you ensure FIFO message processing in Service Bus?"
- "What happens when a message exceeds max delivery count?"
- "How do you batch messages for better throughput?"

---

## 9️⃣ Implement Containerized Solutions (10-15%)

### **FnCast Implementation**
- **Containerization-ready** Azure Functions
- **Azure Container Registry** integration (via infrastructure)
- **Docker support** for custom runtime dependencies
- **Multi-stage builds** for optimized image size
- **Image versioning** with tags
- **Registry authentication** with Managed Identity

### **Potential Docker Configuration**
```dockerfile
# Multi-stage build for FnCast
FROM mcr.microsoft.com/azure-functions/python:4-python3.11 AS build
WORKDIR /home/site/wwwroot
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

FROM mcr.microsoft.com/azure-functions/python:4-python3.11
COPY --from=build /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY . /home/site/wwwroot
```

### **Exam Concepts Covered**
✅ **ACR operations** - Push, pull, tag, delete images  
✅ **Registry authentication** - Service principal, Managed Identity, admin account  
✅ **Image scanning** - Security vulnerability detection  
✅ **Geo-replication** - Multi-region availability  
✅ **Webhooks** - CI/CD integration  
✅ **Azure Container Instances** - Quick deployment for testing  

### **Exam Questions This Helps With**
- "How do you authenticate a Function App to pull from ACR?"
- "What's the recommended way to secure container registry access?"
- "How do you replicate container images across regions?"
- "Which authentication method works best for CI/CD pipelines?"

---

## 🔟 Implement Infrastructure as Code (Bonus - Crosses Multiple Objectives)

### **FnCast Implementation**
- **Bicep templates** for all Azure resources
- **Parameterized deployments** for multi-environment support
- **Resource dependencies** and deployment ordering
- **Outputs** for resource URLs and connection info
- **Idempotent deployments** - safe to re-run
- **Modular structure** with reusable components

### **Key Files**
- [`infrastructure/main.bicep`](infrastructure/main.bicep) - Complete infrastructure definition
- [`infrastructure/parameters.json`](infrastructure/parameters.json) - Environment-specific values
- [`scripts/setup_azure.ps1`](scripts/setup_azure.ps1) - Automated deployment script

### **Exam Concepts Covered**
✅ **Bicep syntax** - Resources, parameters, variables, outputs  
✅ **ARM template structure** - Compilation target for Bicep  
✅ **Deployment modes** - Incremental vs. complete  
✅ **Deployment validation** - What-if operations  
✅ **Resource tagging** - Cost tracking, organization  
✅ **Deployment scopes** - Resource group, subscription, management group  

### **Exam Questions This Helps With**
- "What's the difference between Bicep and ARM templates?"
- "How do you validate a template before deploying?"
- "What happens in 'complete' deployment mode?"
- "How do you reference one resource from another in Bicep?"

---

## 📊 FnCast Coverage Summary

| AZ-204 Objective | FnCast Coverage | Key Learning Areas |
|-----------------|----------------|-------------------|
| **Compute** | ⭐⭐⭐⭐⭐ | Azure Functions, triggers, bindings, scaling |
| **Storage** | ⭐⭐⭐⭐⭐ | Blob Storage, Managed Identity, SDK patterns |
| **Security** | ⭐⭐⭐⭐⭐ | Key Vault, RBAC, Managed Identity, DefaultAzureCredential |
| **Monitoring** | ⭐⭐⭐⭐ | Application Insights, logging, telemetry |
| **Service Integration** | ⭐⭐⭐⭐ | Azure SDKs, REST APIs, authentication |
| **API Management** | ⭐⭐⭐⭐ | RESTful design, versioning, stateless patterns |
| **Event-Based** | ⭐⭐⭐ | Event Grid patterns (can be enhanced) |
| **Message-Based** | ⭐⭐⭐ | Queue triggers (can be enhanced) |
| **Containers** | ⭐⭐⭐⭐ | ACR integration, containerization-ready |
| **IaC** | ⭐⭐⭐⭐⭐ | Bicep, ARM templates, automated deployment |

---

## 🎓 Study Strategy with FnCast

### **1. Build Phase (Hands-On Learning)**
```powershell
# Deploy FnCast infrastructure
cd infrastructure
az deployment group create --resource-group fncast-rg --template-file main.bicep

# Test locally
func start

# Deploy to Azure
func azure functionapp publish fncast-dev-func
```

### **2. Experimentation Phase (Deepen Understanding)**
- Add Event Grid trigger for model updates
- Implement Queue-based batch processing
- Configure APIM in front of Function App
- Set up deployment slots for blue/green deployments
- Add custom metrics and alerts
- Implement container deployment via ACR

### **3. Documentation Phase (Cement Knowledge)**
- Document each decision (why Consumption Plan? why Managed Identity?)
- Create architecture diagrams
- Write troubleshooting guides
- Explain security choices

### **4. Testing Phase (Validate Learning)**
- Take practice exams
- When you see a question, map it to FnCast:
  - "How do you secure a Function App?" → "I used Managed Identity + Key Vault in FnCast"
  - "What's the best storage tier?" → "I chose Hot tier for model.pkl because of frequent access"
  - "How do you monitor latency?" → "I configured Application Insights with custom metrics"

---

## 🔑 Key Takeaways for AZ-204

### **Mental Models Built by FnCast**

1. **Serverless Thinking**
   - When to use Functions vs. App Service vs. Containers
   - Cold start mitigation strategies
   - Cost optimization with Consumption plan

2. **Security-First Design**
   - Never hardcode credentials
   - Use Managed Identity for all service-to-service calls
   - Secrets in Key Vault, not App Settings

3. **Observability by Default**
   - Structured logging from day one
   - Application Insights for all production workloads
   - Proactive alerting, not reactive troubleshooting

4. **Infrastructure as Code**
   - Repeatable deployments
   - Environment parity (dev/staging/prod)
   - Declarative vs. imperative resource management

5. **API Design Patterns**
   - Stateless by design
   - Version everything
   - Clear error messages and status codes

---

## 📝 Quick Reference: FnCast → Exam Concept Mapping

| When You See This Exam Term | Remember This from FnCast |
|-----------------------------|---------------------------|
| **DefaultAzureCredential** | Used in `InferenceFunction` for Blob + Key Vault access |
| **Managed Identity** | System-assigned identity with RBAC for storage/vault |
| **Blob Storage SDK** | `BlobServiceClient` in model loading function |
| **Application Insights** | Configured in `host.json` with sampling |
| **Key Vault integration** | `SecretClient` with Managed Identity |
| **Function triggers** | HTTP POST for inference, HTTP GET for health |
| **Bicep resources** | Storage, Function App, Key Vault, RBAC in `main.bicep` |
| **Cold start mitigation** | Global `_model` variable for caching |
| **Consumption Plan** | `functionAppSku: 'Y1'` in Bicep template |
| **RBAC roles** | Storage Blob Data Reader, Key Vault Secrets User |

---

## ✅ Action Items to Maximize FnCast for AZ-204

- [ ] Deploy FnCast to Azure at least once
- [ ] Add Event Grid trigger for model updates
- [ ] Implement Queue-based batch processing
- [ ] Configure deployment slots (staging → production)
- [ ] Set up custom Application Insights alerts
- [ ] Document every Azure service interaction in code comments
- [ ] Create a troubleshooting runbook
- [ ] Build a cost analysis report for the deployment
- [ ] Add API Management layer
- [ ] Implement container deployment via ACR

---

**Last Updated**: January 12, 2026  
**Project**: FnCast - Serverless ML Inference API  
**Purpose**: AZ-204 Exam Preparation Guide

---

## 🚀 Next Steps

1. **Walk through the code** with exam objectives in mind
2. **Deploy to Azure** and verify each component
3. **Experiment** with alternative configurations
4. **Document** your decisions and trade-offs
5. **Map practice questions** back to FnCast implementations

**Remember**: The exam tests understanding, not memorization. FnCast gives you real experience with the patterns, so you can reason through any question.

Good luck! 🎯
