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
