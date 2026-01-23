# FnCast

## Try It Now

Quick checks you can run immediately:

### Local

1. Start the Functions host (from repo root):

```powershell
func host start
```

2. Health check:

```powershell
curl http://localhost:7071/api/health
```

3. Prediction (sample payload):

```powershell
curl -X POST http://localhost:7071/api/predict ^
  -H "Content-Type: application/json" ^
  -d "{\"features\":[0.5,-0.3,1.2,0.8,-0.5,0.1,0.9,-0.2,0.6,0.4]}"
```

### Cloud

- Health (production): https://fncast-4654.azurewebsites.net/api/health

- Prediction requires a function key. Retrieve it via Azure CLI, then call with `?code=<FUNCTION_KEY>`:

```powershell
az functionapp function keys list `
  --name fncast-4654 `
  --resource-group rg-fncast `
  --function-name InferenceFunction `
  --query default -o tsv

curl -X POST "https://fncast-4654.azurewebsites.net/api/predict?code=<FUNCTION_KEY>" ^
  -H "Content-Type: application/json" ^
  -d "{\"features\":[0.5,-0.3,1.2,0.8,-0.5,0.1,0.9,-0.2,0.6,0.4]}"
```

Tip: Staging environment (if configured) is available at `https://fncast-4654-staging.azurewebsites.net`.

## 1. Executive Summary

FnCast is a production‑grade, serverless compute and event‑driven automation project built on Azure Functions (Python). It delivers a secure, scalable HTTP API for machine learning inference backed by Azure Blob Storage, Azure Key Vault, and Application Insights. The design emphasizes operational excellence: minimal operational overhead via the consumption plan, strong identity and access controls with Managed Identity + RBAC, and robust observability integrated out‑of‑the‑box.

This project exists to demonstrate how to take an ML artifact from training to runtime in a cloud‑native, serverless architecture—without exposing secrets, while maintaining auditability and cost efficiency. It targets real outcomes important to engineering leaders: clear separation between infrastructure and application code (IaC with Bicep), practical CI/CD integration (GitHub Actions‑ready), and hardened operational controls (App settings, Key Vault, and strict auth levels).

## 2. What This Project Demonstrates

- Cloud‑native serverless API for ML inference on Azure Functions (Python)
- Secure secret management with Azure Key Vault and Managed Identity
- Data access via Azure Blob Storage with role‑based permissions
- Infrastructure as Code using Bicep with environment parameters
- Production observability with Application Insights and sampling controls
- Automated environment lifecycle scripts (cost saving and restart flows)
- Unit‑tested function endpoints with fast local iteration

## 3. Skills & Competencies Mapping

- **Cloud:** Azure Functions, Storage Accounts, Application Insights, Key Vault
- **DevOps:** GitHub Actions‑ready workflow, service principal provisioning, repeatable environment setup
- **IaC:** Bicep templates for function app, storage, insights, vault, and RBAC role assignments
- **Serverless:** HTTP triggers with function/anonymous auth levels, consumption plan scaling (`Y1`)
- **Observability:** App Insights, host sampling, structured logs, testable endpoints
- **Security:** Managed Identity (system‑assigned), RBAC (Blob Data Contributor, Key Vault Secrets User), HTTPS only
- **Python engineering:** Azure Functions (Python 3.11), structured handlers, model IO with `joblib`, unit tests with `pytest`

## 4. Architecture Overview

```
                        +---------------------------+
                        |        Client (HTTP)      |
                        |  - /api/health (GET)      |
                        |  - /api/predict (POST)    |
                        +-------------+-------------+
                                      |
                                      v
                          +-----------+-----------+
                          |     Azure Functions   |
                          |   (Python, ~4, 3.11)  |
                          |  - HealthCheckFunction |
                          |  - InferenceFunction   |
                          +-----------+-----------+
                                      |
                    Managed Identity   |   Structured Logs
                                      |          |
                                      v          v
       +---------------------+   +----+----+   +--------------------+
       | Azure Blob Storage  |   | KeyVault |   | ApplicationInsights |
       |  models/container   |   |  Secrets |   |   Telemetry/Queries |
       +----------+----------+   +---------+   +----------+---------+
                  ^                                   ^
                  |                                   |
            Model uploads                      Queries/Monitoring
            (scripts/upload_model.py)          (App Insights)
```

**Why this design:**
- Serverless fast path for ML inference with minimal operational toil and elastic scale.
- Strong identity posture: the function app uses a system‑assigned Managed Identity to access Blob Storage and Key Vault (no embedded credentials).
- Separation of concerns: IaC declares resources and RBAC, app code focuses on handling requests and model IO.
- Observability first: Application Insights integrated via host settings and app environment.

**Key tradeoffs and benefits:**
- Consumption plan (`Y1`) reduces cost at low traffic but introduces cold starts; acceptable for non‑latency‑critical workloads.
- Model loading from Blob on first request caches in memory; improves steady‑state latency at the cost of initial warm‑up.
- RBAC+Managed Identity removes secret sprawl; requires deliberate role assignments (handled in Bicep).
- HTTP function auth: `function` level for `/api/predict` balances security and ease of use; `anonymous` for `/api/health` improves operability.

## 5. Project Structure

```
d:/src/FnCast
├── AZ204_EXAM_MAPPING_FNCAST.md
├── AZ204_FNCAST_MATRIX.md
├── github-secrets.json
├── host.json
├── local.settings.json
├── pyproject.toml
├── README.md
├── requirements-dev.txt
├── requirements.txt
├── HealthCheckFunction/
│   ├── __init__.py            # GET /api/health (anonymous); returns service status
│   └── function.json          # HTTP trigger and binding config
├── InferenceFunction/
│   ├── __init__.py            # POST /api/predict (function auth); loads model from Blob via MI
│   └── function.json          # HTTP trigger and binding config
├── infrastructure/
│   ├── main.bicep             # Function App, Storage, Key Vault, App Insights, RBAC
│   └── parameters.json        # Name, environment, and location parameters
├── scripts/
│   ├── setup_azure.ps1        # Provision RG, Storage, Insights, Function App, SP for CI/CD
│   ├── dehydrate_azure.ps1    # Stop resources to minimize costs; saves state
│   ├── rehydrate_azure.ps1    # Restart resources; validates health
│   ├── train_model.py         # Sample training pipeline; saves `model.pkl`
│   └── upload_model.py        # Uploads `model.pkl` to Blob with Managed Identity
└── tests/
    ├── test_health.py         # Unit tests for health endpoint
    └── test_inference.py      # Unit tests for inference endpoint
```

## 6. Quick Start Guide

### Prerequisites
- Windows with PowerShell, Python 3.11, and Git
- Azure CLI (`az`) and Azure Functions Core Tools
- An Azure subscription and rights to create resources

### Setup Steps

1. Install Python dependencies:

```powershell
Task: "pip install (functions)"

# Or manually
${env:azureFunctions_pythonVenv}\Scripts\python -m pip install -r requirements.txt
```

2. Provision Azure resources (resource group, storage, App Insights, function app, service principal):

pwsh ./scripts/setup_azure.ps1
```

3. Train and upload a sample model:

```powershell
python ./scripts/train_model.py
```

4. Configure local settings (dev only) in `local.settings.json` (already scaffolded): ensure `KEY_VAULT_URL`, `STORAGE_ACCOUNT_NAME`, `MODEL_CONTAINER_NAME`, `MODEL_BLOB_NAME` are correct.


- Start the function host:

```powershell
# VS Code task (background)
Task: func: 0  # starts `func host start`

# Or manually
func host start
```
curl -X POST http://localhost:7071/api/predict ^
  -H "Content-Type: application/json" ^
  -d "{\"features\":[0.5,-0.3,1.2,0.8,-0.5,0.1,0.9,-0.2,0.6,0.4]}"

```powershell
pytest -q
```

### Deployment Steps

- GitHub Actions (recommended): Use `setup_azure.ps1` to create a service principal and publish profile, then add secrets:
  - `AZURE_FUNCTION_APP_NAME`
  - `AZURE_CREDENTIALS` (JSON from the script)
  - `AZURE_FUNCTIONAPP_PUBLISH_PROFILE` (XML from the script)

- Azure CLI deploy (alternative):

```powershell
az functionapp deployment source config-zip `
  --name <functionAppName> `
```

## 7. CI/CD Pipeline

**Stages:**
- Build: install dependencies, lint, run unit tests
- Package: prepare function app artifact
- Deploy: publish to Azure Function App using service principal credentials

**Flow Diagram:**

```
Git Push → GitHub Actions → Build → Test → Package → Deploy → Validate Health
```

**What is automated:**
## 8. Security Best Practices

- **Secrets:** No embedded credentials. The app retrieves secrets via Azure Key Vault (`KEY_VAULT_URL`); `DefaultAzureCredential` resolves Managed Identity in Azure.
## 9. Monitoring & Observability

- **What is tracked:** Request/exception telemetry, traces, and custom logs via Application Insights; sampling configured in `host.json` to reduce noise.
- **How to view logs:** App Insights Logs (Kusto) in the Azure Portal; validate function health with `rehydrate_azure.ps1` post‑start.
- **Example queries:**

```kusto
requests
| where url endswith "/api/predict"
| summarize count() by resultCode

traces
| where message contains "ML Inference"
| project timestamp, message, severityLevel

exceptions
| where innermostMessage contains "Failed to load model"
| summarize count() by problemId
```

## 10. Cost Model

- **Dev vs prod:** Consumption plan (`Y1`) charges per execution and resources consumed; idle costs are minimal. Storage and Insights have baseline retention/storage costs.
- **Optimization notes:**
  - Use `dehydrate_azure.ps1` to stop the function app when idle; `rehydrate_azure.ps1` to restart.
  - Tune Application Insights sampling (`host.json`).
  - Right‑size retention policies in App Insights; compress/optimize model size.

## 11. Cleanup Instructions

```powershell
# Stop function app to immediately cut execution costs
pwsh ./scripts/dehydrate_azure.ps1

# Optionally remove all resources (irreversible)
az group delete --name <rg-fncast> --yes --no-wait
```

## 12. Learning Outcomes

- Demonstrated secure, serverless ML inference on Azure with Managed Identity and RBAC.
- Authored IaC (Bicep) for complete environment provisioning including role assignments.
- Implemented observability and meaningful tests for endpoints.
- Operationalized cost controls and environment lifecycle with PowerShell scripts.

## 13. Resume‑Ready Highlights

- Built a production‑grade Azure Functions (Python) ML inference API with Managed Identity, Key Vault, Blob Storage, and Application Insights.
- Authored end‑to‑end IaC in Bicep including RBAC role assignments for least‑privilege access.
- Implemented CI/CD (GitHub Actions‑ready) with service principal provisioning and secure secret handling.
- Added unit tests and local developer workflow (Functions Core Tools, pytest) for fast iteration.
- Reduced operational cost via automated dehydrate/rehydrate scripts and host sampling.

## 14. License + Final Notes

This repository is provided for educational and portfolio demonstration purposes. If you plan to use FnCast in production, review network isolation, private endpoints, and compliance requirements, and extend CI/CD automation with environment‑specific gates and secrets rotation.
# FnCast - Serverless ML Inference API

🎯 **Goal**: Deploy a lightweight ML model as a serverless API using Azure Functions, with secure access via Key Vault and Blob Storage.

## 🧱 Architecture

```
┌─────────────────┐
│   HTTP Client   │
└────────┬────────┘
         │
         v
┌─────────────────────────────────────────┐
│      Azure Function App                 │
│  ┌──────────────────────────────────┐  │
│  │  InferenceFunction (HTTP POST)   │  │
│  │  - Loads model from Blob         │  │
│  │  - Makes predictions             │  │
│  └──────────────────────────────────┘  │
│                                         │
│  ┌──────────────────────────────────┐  │
│  │  HealthCheckFunction (HTTP GET)  │  │
│  └──────────────────────────────────┘  │
│                                         │
│  Managed Identity ──┐                  │
└─────────────────────┼──────────────────┘
                      │
         ┌────────────┴────────────┐
         │                         │
         v                         v
┌─────────────────┐       ┌─────────────────┐
│  Blob Storage   │       │   Key Vault     │
│  - model.pkl    │       │  - Secrets      │
└─────────────────┘       └─────────────────┘
         │
         v
┌─────────────────┐
│ App Insights    │
│ - Logs/Metrics  │
└─────────────────┘
```

## 🛠️ Tech Stack

- **Runtime**: Python 3.11
- **Framework**: Azure Functions (HTTP Triggers)
- **ML**: scikit-learn, joblib
- **Storage**: Azure Blob Storage
- **Security**: Azure Key Vault, Managed Identity
- **Monitoring**: Application Insights
- **IaC**: Bicep
- **CI/CD**: GitLab CI/CD

## 📁 Project Structure

```
FnCast/
├── InferenceFunction/          # ML inference endpoint
│   ├── __init__.py
│   └── function.json
├── HealthCheckFunction/        # Health check endpoint
│   ├── __init__.py
│   └── function.json
├── infrastructure/             # Infrastructure as Code
│   ├── main.bicep
│   └── parameters.json
├── scripts/                    # Utility scripts
│   ├── train_model.py
│   ├── upload_model.py
│   └── test_function.py
├── tests/                      # Unit tests
│   ├── test_inference.py
│   └── test_health.py
├── .gitlab-ci.yml             # CI/CD pipeline
├── requirements.txt           # Python dependencies
├── host.json                  # Function app config
├── local.settings.json        # Local dev settings
└── README.md
```

## 🚀 Getting Started

### Prerequisites

- Python 3.11+
- Azure CLI
- Azure Functions Core Tools
- Azure subscription

### Local Development

1. **Clone and setup**:
```bash
cd FnCast
python -m venv venv
venv\Scripts\activate  # Windows
pip install -r requirements.txt
```

2. **Train a sample model**:
```bash
python scripts/train_model.py
```

3. **Configure local settings**:
Edit `local.settings.json` with your Azure resource details.

4. **Run locally**:
```bash
func start
```

5. **Test endpoints**:
```bash
# Health check
curl http://localhost:7071/api/health

# Inference
curl -X POST http://localhost:7071/api/predict \
  -H "Content-Type: application/json" \
  -d '{"features": [0.5, -0.3, 1.2, 0.8, -0.5, 0.1, 0.9, -0.2, 0.6, 0.4]}'
```

## ☁️ Azure Deployment

### 1. Deploy Infrastructure

```bash
# Login to Azure
az login

# Create resource group
az group create --name fncast-rg --location eastus

# Deploy Bicep template
az deployment group create \
  --resource-group fncast-rg \
  --template-file infrastructure/main.bicep \
  --parameters infrastructure/parameters.json
```

### 2. Upload Model to Blob Storage

```bash
python scripts/upload_model.py \
  --storage-account <your-storage-account> \
  --container models \
  --model-file model.pkl
```

### 3. Deploy Function App

```bash
# Create deployment package
func azure functionapp publish <function-app-name>

# Or use zip deploy
zip -r functionapp.zip . -x "*.git*" "tests/*" "scripts/*"
az functionapp deployment source config-zip \
  --resource-group fncast-rg \
  --name <function-app-name> \
  --src functionapp.zip
```

### 4. Test Deployment

```bash
python scripts/test_function.py \
  --url https://<function-app-name>.azurewebsites.net \
  --key <function-key>
```

## 🔒 Security

- **Managed Identity**: Function app uses system-assigned managed identity
- **Key Vault**: Secrets stored securely in Azure Key Vault
- **RBAC**: Least-privilege access with Azure RBAC
- **Function Keys**: API authentication via function keys
- **HTTPS Only**: All traffic encrypted in transit

## 📊 Monitoring

- **Application Insights**: Real-time monitoring and logging
- **Metrics**: Request count, response time, failure rate
- **Logs**: Detailed execution logs and errors

View in Azure Portal:
```
Resource Group > Application Insights > Logs
```

## 🧪 Testing

Run unit tests:
```bash
pytest tests/ --cov=. --cov-report=term-missing
```

## 📝 API Documentation

### POST /api/predict
Performs inference using the trained model.

**Request**:
```json
{
  "features": [0.5, -0.3, 1.2, 0.8, -0.5, 0.1, 0.9, -0.2, 0.6, 0.4]
}
```

**Response**:
```json
{
  "prediction": [1],
  "status": "success"
}
```

### GET /api/health
Health check endpoint.

**Response**:
```json
{
  "status": "healthy",
  "service": "FnCast ML Inference API",
  "version": "1.0.0"
}
```

## 🔄 CI/CD Pipeline

GitLab CI/CD pipeline includes:
- **Build**: Install dependencies, create deployment package
- **Test**: Run unit tests with coverage
- **Deploy**: Deploy to Azure Functions

Set these variables in GitLab:
- `AZURE_SUBSCRIPTION_ID`
- `AZURE_RESOURCE_GROUP`
- `AZURE_FUNCTION_APP_NAME`
- `AZURE_CLIENT_ID`
- `AZURE_CLIENT_SECRET`
- `AZURE_TENANT_ID`

## 🎓 Lessons Learned

Track your progress in OneNote:
- **Dev Notes**: Architecture decisions, code patterns
- **CI/CD**: Pipeline configuration, deployment steps
- **Lessons**: What worked, what didn't, improvements

## 📦 Deliverables

- ✅ `functionapp.zip` with inference logic
- ✅ Bicep infrastructure templates
- ✅ GitLab CI/CD pipeline
- ✅ Unit tests with coverage
- ✅ README with setup and usage guide
- ✅ Sample scripts for training and testing

## 🤝 Contributing

1. Create a feature branch
2. Make your changes
3. Run tests: `pytest tests/`
4. Submit a pull request

## 📄 License

MIT License - See LICENSE file for details

## 🆘 Troubleshooting

### Model not loading
- Check Managed Identity has "Storage Blob Data Contributor" role
- Verify model exists in blob storage
- Check function app environment variables

### Function not responding
- Check Application Insights logs
- Verify function app is running
- Test health endpoint first

### Authentication errors
- Ensure Managed Identity is enabled
- Verify RBAC role assignments
- Check Key Vault access policies

## 📞 Support

For issues or questions, please open an issue in the repository.

---

**Built with ❤️ using Azure Functions**
