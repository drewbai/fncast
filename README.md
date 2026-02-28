# FnCast

🔎 Live Health: https://fncast-4654.azurewebsites.net/api/health • Local: http://localhost:7071/api/health

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

Local env setup (optional but recommended):

- Create a `.env` file (ignored) using the template in [.env.example](.env.example), set:
  - `FUNCTION_URL` (e.g., https://fncast-4654.azurewebsites.net)
  - `FUNCTION_KEY` (function-level key for `/api/predict`)
  - `STORAGE_ACCOUNT_NAME`, `MODEL_CONTAINER_NAME`, `MODEL_BLOB_NAME`
  - optionally `KEY_VAULT_URL`
- VS Code debug configs in [.vscode/launch.json](.vscode/launch.json) load `.env` and pass values to scripts.

1. Install Python dependencies:

```powershell
Task: "pip install (functions)"

# Or manually
${env:azureFunctions_pythonVenv}\Scripts\python -m pip install -r requirements.txt
```

2. Provision Azure resources (resource group, storage, App Insights, function app, service principal). The script now accepts `-SubscriptionId` so you can pin deployments to `a3ffe731-0f80-47fa-ad62-50ea1cab3605` (or any other subscription):

```powershell
pwsh ./scripts/setup_azure.ps1 -SubscriptionId a3ffe731-0f80-47fa-ad62-50ea1cab3605
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

Test local endpoints (PowerShell, CMD, Bash):

PowerShell (use curl.exe, include function key):

```powershell
# Health
curl.exe "http://localhost:7071/api/health"

# Inference (function-auth requires key)
curl.exe -X POST "http://localhost:7071/api/predict?code=<your_function_key>" `
  -H "Content-Type: application/json" `
  -d '{"features":[0.5,-0.3,1.2,0.8,-0.5,0.1,0.9,-0.2,0.6,0.4]}'
```

CMD (Windows Command Prompt):

```cmd
rem Health
curl http://localhost:7071/api/health

rem Inference
curl -X POST http://localhost:7071/api/predict?code=<your_function_key> ^
  -H "Content-Type: application/json" ^
  -d "{\"features\":[0.5,-0.3,1.2,0.8,-0.5,0.1,0.9,-0.2,0.6,0.4]}"
```

Bash (macOS/Linux):

```bash
# Health
curl "http://localhost:7071/api/health"

# Inference
curl -X POST "http://localhost:7071/api/predict?code=<your_function_key>" \
  -H "Content-Type: application/json" \
  -d '{"features":[0.5,-0.3,1.2,0.8,-0.5,0.1,0.9,-0.2,0.6,0.4]}'
```

Note: You can pass the key via header instead of query string:

```bash
-H "x-functions-key: <your_function_key>"
Using VS Code launch configs (no fishing):

- Train model: Debug → "Train sample model"
- Upload model: Debug → "Upload model to Blob" (reads storage/model values from `.env`)
- Test cloud predict: Debug → "Test cloud function (predict)" (reads URL/key from `.env`)

#### Sample VS Code launch.json

You can copy this into your local [.vscode/launch.json](.vscode/launch.json) or adapt as needed. It loads variables from `.env` and adds `justMyCode` for cleaner debugging.

```jsonc
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Attach to Python Functions",
      "type": "python",
      "request": "attach",
      "port": 9091,
      "preLaunchTask": "func: host start"
    },
    {
      "name": "Train sample model",
      "type": "python",
      "request": "launch",
      "program": "${workspaceFolder}/scripts/train_model.py",
      "console": "integratedTerminal",
      "envFile": "${workspaceFolder}/.env",
      "justMyCode": true
    },
    {
      "name": "Upload model to Blob",
      "type": "python",
      "request": "launch",
      "program": "${workspaceFolder}/scripts/upload_model.py",
      "console": "integratedTerminal",
      "envFile": "${workspaceFolder}/.env",
      "justMyCode": true,
      "args": [
        "--storage-account",
        "${env:STORAGE_ACCOUNT_NAME}",
        "--container",
        "${env:MODEL_CONTAINER_NAME}",
        "--model-file",
        "${env:MODEL_BLOB_NAME}"
      ]
    },
    {
      "name": "Test cloud function (predict)",
      "type": "python",
      "request": "launch",
      "program": "${workspaceFolder}/scripts/test_function.py",
      "console": "integratedTerminal",
      "envFile": "${workspaceFolder}/.env",
      "justMyCode": true,
      "args": [
        "--url",
        "${env:FUNCTION_URL}",
        "--key",
        "${env:FUNCTION_KEY}"
      ]
    }
  ]
}
```

#### Sample .env

Copy this into a local `.env` (ignored) and update the function key. These defaults match the Bicep parameters (`projectName=fncast`, `environment=dev`).

```ini
# --- Cloud function (dev) ---
FUNCTION_URL=https://fncast-dev-func.azurewebsites.net
FUNCTION_KEY=<paste_function_key_here>

# --- Storage & Model ---
STORAGE_ACCOUNT_NAME=fncastdevstorage
MODEL_CONTAINER_NAME=models
MODEL_BLOB_NAME=model.pkl

# --- Key Vault (optional for local runs) ---
KEY_VAULT_URL=https://fncast-dev-kv.vault.azure.net/

# --- Alternative (existing public app) ---
# FUNCTION_URL=https://fncast-4654.azurewebsites.net
# FUNCTION_KEY=<paste_function_key_here>
```
```

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

---

## Parity with fncast-dotnet

To align with the sister project [fnCast-dotNet](https://github.com/drewbai/fnCast-dotNet), this repo now includes:

- New endpoints and triggers:
  - [HttpIngestFunction/__init__.py](HttpIngestFunction/__init__.py) — POST `/api/ingest` supporting `text/plain` and `application/json` payloads with placeholder inference modes configured via `INFERENCE_MODE` (`Uppercase` | `Lowercase` | `Echo`).
  - [QueueIngestFunction/__init__.py](QueueIngestFunction/__init__.py) — Azure Storage Queue trigger (`fncast-events`) mirroring the dotnet queue ingest.
  - [EventGridIngestFunction/__init__.py](EventGridIngestFunction/__init__.py) — Event Grid trigger for ingesting custom topic events.
- Infra additions in [infrastructure/main.bicep](infrastructure/main.bicep): provisions a Storage Queue (`fncast-events`) and an Event Grid topic with outputs for quick wiring.
- Docs & demos:
  - One‑click requests in [docs/requests.http](docs/requests.http) for health and ingest.
  - Quick demo script [docs/scripts/demo-presentation.ps1](docs/scripts/demo-presentation.ps1).
  - Queue producer [docs/scripts/publish-queue-message.ps1](docs/scripts/publish-queue-message.ps1).
  - Event Grid publisher [docs/scripts/publish-eventgrid.ps1](docs/scripts/publish-eventgrid.ps1).
  - Diagrams in [docs/diagrams.md](docs/diagrams.md) and Postman collection in [docs/postman/fncast.postman_collection.json](docs/postman/fncast.postman_collection.json).

Quick demo locally:

```powershell
# Start the Functions host (ensure deps installed)
func host start

# Run the presentation demo
./docs/scripts/demo-presentation.ps1 -FunctionsBaseUrl http://localhost:7071
```

Configure inference behavior:

```powershell
$env:INFERENCE_MODE = 'Uppercase'  # or 'Lowercase', 'Echo'
```

Optional: Publish a test message to the queue (requires Storage connection string):

```powershell
./docs/scripts/publish-queue-message.ps1 -ConnectionString '<storage-connection-string>' -Message 'hello'
```

Publish an Event Grid demo event:

```powershell
./docs/scripts/publish-eventgrid.ps1 -ResourceGroup <rg> -TopicName <topic> -Subject demo -Data '{"message":"hello"}'
```

After deploying via Bicep, you can create an Event Grid subscription pointing to `EventGridIngestFunction` using the Function key, similar to the dotnet README.

## CI

- Build & Test: [\.github/workflows/ci.yml](.github/workflows/ci.yml) runs Python 3.11, installs dependencies, and executes `pytest` on push/PR.
- Deploy Functions: [\.github/workflows/deploy-functions.yml](.github/workflows/deploy-functions.yml) publishes the app to Azure using repository variable `AZURE_FUNCTIONAPP_NAME` and secret `AZURE_FUNCTIONAPP_PUBLISH_PROFILE`.

## Local Queues (Azurite)

For local queue testing, install and run Azurite, then set `AzureWebJobsStorage=UseDevelopmentStorage=true` in `local.settings.json`:

```powershell
npm install -g azurite
azurite -l .azurite --silent --skipApiVersionCheck
```

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
 - **CI/CD**: GitHub Actions

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
├── .github/workflows/azure-functions-deploy.yml  # GitHub Actions pipeline
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
az group create --name fncast-rg --location westus2

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

GitHub Actions pipeline includes:
- **Build**: Install dependencies, create deployment package
- **Test**: Run unit tests with coverage
- **Deploy**: Deploy to Azure Functions

Set these secrets in GitHub Actions (Settings → Secrets and variables → Actions):
- `AZURE_FUNCTION_APP_NAME`
- `AZURE_CREDENTIALS` (JSON from service principal creation; use `--sdk-auth`)
- `AZURE_FUNCTIONAPP_PUBLISH_PROFILE` (XML publish profile)
- `AZURE_FUNCTIONAPP_PUBLISH_PROFILE_STAGING` (XML publish profile for staging, if used)

Generate `AZURE_CREDENTIALS` with a least-privilege service principal (paste the JSON output into the GitHub secret):

```powershell
# Get your subscription id if needed
az account show --query id -o tsv

# Create SP scoped to the resource group
az ad sp create-for-rbac `
  --name fncast-ci `
  --role Contributor `
  --scopes /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/fncast-rg `
  --sdk-auth

# Copy the JSON output into the GitHub Action secret named AZURE_CREDENTIALS
```

For a staging resource group, create a separate principal and scope:

```powershell
az ad sp create-for-rbac `
  --name fncast-ci-staging `
  --role Contributor `
  --scopes /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/fncast-rg-staging `
  --sdk-auth
```

Least-privilege tips:
- Scope the role to the minimal target (resource group or even a single function app):
  ```powershell
  # Scope to a single Function App resource
  az ad sp create-for-rbac `
    --name fncast-ci-app `
    --role Contributor `
    --scopes /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/fncast-rg/providers/Microsoft.Web/sites/fncast-dev-func `
    --sdk-auth
  ```
- If you use `AZURE_FUNCTIONAPP_PUBLISH_PROFILE`, you can deploy without broad `Contributor` on the RG; the publish profile grants access only to the app.
- Keep separate principals for dev/staging/prod and rotate credentials periodically.

## 🎓 Lessons Learned

Track your progress in OneNote:
- **Dev Notes**: Architecture decisions, code patterns
- **CI/CD**: Pipeline configuration, deployment steps
- **Lessons**: What worked, what didn't, improvements

## 📦 Deliverables

-- ✅ `functionapp.zip` with inference logic
-- ✅ Bicep infrastructure templates
-- ✅ GitHub Actions pipeline
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

---

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

## 7. Operational: Dehydrate/Rehydrate

- Dehydrate: stops the Function App and aggressively disables telemetry at the app level by clearing `APPINSIGHTS_INSTRUMENTATIONKEY` and `APPLICATIONINSIGHTS_CONNECTION_STRING`. It also disables Application Insights public ingestion and query access to minimize costs. It saves restart state in [azure-stopped-state.json](azure-stopped-state.json).

```powershell
pwsh ./scripts/dehydrate_azure.ps1
# Optional maximal savings (delete AI; will be recreated on rehydrate):
pwsh ./scripts/dehydrate_azure.ps1 -DeleteAppInsights
```

- Rehydrate: restores telemetry settings from App Insights (using names in [azure-config.json](azure-config.json)) and starts the Function App, then performs a health check.

```powershell
pwsh ./scripts/rehydrate_azure.ps1 -SubscriptionId a3ffe731-0f80-47fa-ad62-50ea1cab3605
```

Notes:
- Ensure [azure-config.json](azure-config.json) has `resourceGroup`, `functionAppName`, and `appInsightsName` set for your environment.
- App Insights retention charges may still apply even when telemetry is disabled at the app level; we also disable public ingestion/query access. For maximal savings, you can use `-DeleteAppInsights` to delete the component and let rehydrate recreate it.

## 8. Hybrid CI/CD (GitHub Actions + Azure DevOps)

**CI authority (GitHub Actions):**
- Build, lint, test, and package the Function App.
- Publish a deployable artifact named `functionapp.zip` as a GitHub Actions artifact (for example, `functionapp`).

**CD authority (Azure DevOps Pipelines):**
- Download the GitHub Actions artifact using the GitHub API.
- Deploy the artifact to Azure Functions using an Azure DevOps service connection (RBAC; no publish profiles).
- Use Azure DevOps environments for approvals and release governance.

**Artifact flow:**
1) GitHub Actions produces `functionapp.zip` and uploads it as an artifact.
2) Azure DevOps pipeline `azure-pipelines.yml` downloads the latest successful artifact.
3) Azure DevOps deploys the zip to the target Function App.

**Why hybrid:**
- Keeps CI logic centralized in GitHub Actions (no duplication).
- Uses Azure DevOps release governance (approvals, audit, environment checks) in line with AZ-400 best practices.
