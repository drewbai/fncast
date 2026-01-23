"""
Script to upload the trained model to Azure Blob Storage
"""

import argparse

from azure.identity import DefaultAzureCredential
from azure.storage.blob import BlobServiceClient


def upload_model_to_blob(
    storage_account_name: str,
    container_name: str,
    model_file_path: str,
    blob_name: str = "model.pkl",
):
    """
    Upload a model file to Azure Blob Storage using Managed Identity
    """
    try:
        # Create BlobServiceClient using Managed Identity
        account_url = f"https://{storage_account_name}.blob.core.windows.net"
        credential = DefaultAzureCredential()
        blob_service_client = BlobServiceClient(account_url=account_url, credential=credential)

        # Get container client (create if doesn't exist)
        container_client = blob_service_client.get_container_client(container_name)
        try:
            container_client.create_container()
            print(f"Created container: {container_name}")
        except Exception:
            print(f"Container {container_name} already exists")

        # Upload the model
        blob_client = blob_service_client.get_blob_client(container=container_name, blob=blob_name)

        print(f"Uploading {model_file_path} to {container_name}/{blob_name}...")
        with open(model_file_path, "rb") as data:
            blob_client.upload_blob(data, overwrite=True)

        print("✓ Model uploaded successfully!")
        print(f"  URL: {blob_client.url}")

    except Exception as e:
        print(f"✗ Failed to upload model: {str(e)}")
        raise


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Upload ML model to Azure Blob Storage")
    parser.add_argument("--storage-account", required=True, help="Azure Storage Account name")
    parser.add_argument("--container", default="models", help="Blob container name")
    parser.add_argument("--model-file", default="model.pkl", help="Path to model file")
    parser.add_argument("--blob-name", default="model.pkl", help="Name for the blob")

    args = parser.parse_args()

    upload_model_to_blob(
        storage_account_name=args.storage_account,
        container_name=args.container,
        model_file_path=args.model_file,
        blob_name=args.blob_name,
    )
