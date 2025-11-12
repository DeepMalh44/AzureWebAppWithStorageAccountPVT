# Python File Upload App

Python Flask web application that uploads files to Azure Blob Storage using Managed Identity authentication.

## Features
- Simple file upload interface
- Azure Blob Storage integration
- Managed Identity authentication (no connection strings!)
- Same security setup as C# version (VNet, Private Endpoint)

## Technology Stack
- Python 3.11
- Flask 3.0
- Azure Storage Blob SDK
- Azure Identity (ManagedIdentityCredential)
- Gunicorn (production server)

## Local Development
```bash
pip install -r requirements.txt
python app.py
```

## Azure Deployment
Deployed to Azure App Service (Linux) with:
- System-assigned Managed Identity
- VNet integration
- Private endpoint to storage account
- Storage Blob Data Contributor role

## Files
- `app.py` - Main Flask application
- `templates/index.html` - Upload UI
- `requirements.txt` - Python dependencies
- `startup.txt` - Azure App Service startup command
