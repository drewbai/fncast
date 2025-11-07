"""
Azure Function for ML Model Inference
Handles HTTP requests for model predictions using a model stored in Blob Storage
"""
import logging
import json
import os
import joblib
import tempfile
from typing import Dict, Any

import azure.functions as func
from azure.identity import DefaultAzureCredential
from azure.storage.blob import BlobServiceClient
from azure.keyvault.secrets import SecretClient


# Global variables for model caching
_model = None
_model_loaded = False


def get_secret_from_keyvault(secret_name: str) -> str:
    """
    Retrieve a secret from Azure Key Vault using Managed Identity
    """
    key_vault_url = os.environ.get("KEY_VAULT_URL")
    if not key_vault_url:
        raise ValueError("KEY_VAULT_URL environment variable not set")
    
    credential = DefaultAzureCredential()
    client = SecretClient(vault_url=key_vault_url, credential=credential)
    
    try:
        secret = client.get_secret(secret_name)
        return secret.value
    except Exception as e:
        logging.error(f"Failed to retrieve secret {secret_name}: {str(e)}")
        raise


def load_model_from_blob():
    """
    Load the ML model from Azure Blob Storage using Managed Identity
    """
    global _model, _model_loaded
    
    if _model_loaded:
        return _model
    
    try:
        # Get configuration from environment variables
        storage_account_name = os.environ.get("STORAGE_ACCOUNT_NAME")
        container_name = os.environ.get("MODEL_CONTAINER_NAME", "models")
        blob_name = os.environ.get("MODEL_BLOB_NAME", "model.pkl")
        
        if not storage_account_name:
            raise ValueError("STORAGE_ACCOUNT_NAME environment variable not set")
        
        # Use Managed Identity to authenticate
        account_url = f"https://{storage_account_name}.blob.core.windows.net"
        credential = DefaultAzureCredential()
        blob_service_client = BlobServiceClient(account_url=account_url, credential=credential)
        
        # Download the model
        blob_client = blob_service_client.get_blob_client(container=container_name, blob=blob_name)
        
        with tempfile.NamedTemporaryFile(delete=False, suffix='.pkl') as temp_file:
            download_stream = blob_client.download_blob()
            temp_file.write(download_stream.readall())
            temp_file_path = temp_file.name
        
        # Load the model
        _model = joblib.load(temp_file_path)
        _model_loaded = True
        
        # Clean up temp file
        os.unlink(temp_file_path)
        
        logging.info(f"Model loaded successfully from {container_name}/{blob_name}")
        return _model
    
    except Exception as e:
        logging.error(f"Failed to load model: {str(e)}")
        raise


def main(req: func.HttpRequest) -> func.HttpResponse:
    """
    Main Azure Function handler for inference requests
    
    Expected JSON payload:
    {
        "features": [value1, value2, value3, ...]
    }
    """
    logging.info('ML Inference function processing request.')
    
    try:
        # Parse request body
        try:
            req_body = req.get_json()
        except ValueError:
            return func.HttpResponse(
                json.dumps({"error": "Invalid JSON in request body"}),
                status_code=400,
                mimetype="application/json"
            )
        
        # Validate input
        if 'features' not in req_body:
            return func.HttpResponse(
                json.dumps({"error": "Missing 'features' field in request"}),
                status_code=400,
                mimetype="application/json"
            )
        
        features = req_body['features']
        
        # Load model (cached after first load)
        model = load_model_from_blob()
        
        # Make prediction
        prediction = model.predict([features])
        
        # Prepare response
        response = {
            "prediction": prediction.tolist(),
            "status": "success"
        }
        
        logging.info(f"Prediction successful: {prediction}")
        
        return func.HttpResponse(
            json.dumps(response),
            status_code=200,
            mimetype="application/json"
        )
    
    except Exception as e:
        logging.error(f"Error during inference: {str(e)}")
        return func.HttpResponse(
            json.dumps({"error": str(e), "status": "failed"}),
            status_code=500,
            mimetype="application/json"
        )
