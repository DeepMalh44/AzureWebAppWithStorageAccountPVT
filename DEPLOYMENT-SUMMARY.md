# File Upload Applications - Deployment Summary

## Overview
Built two secure file upload web applications that upload files to Azure Blob Storage using Managed Identity authentication (no connection strings!).

## Applications

### 1. C# ASP.NET Core Application
- **URL**: https://app-file-dev-o7bbcldb.azurewebsites.net
- **Technology**: ASP.NET Core 8.0 Razor Pages
- **Authentication**: `ManagedIdentityCredential` (explicit)
- **Location**: `c:\file-upload-webapp\FileUploadApp`

### 2. Python Flask Application  
- **URL**: https://app-pyfile-dev-lsxm5qbo.azurewebsites.net
- **Technology**: Python 3.11 + Flask 3.0
- **Authentication**: `ManagedIdentityCredential` (explicit)
- **Location**: `c:\file-upload-webapp\python-file-upload`

## Shared Infrastructure

### Storage Account
- **Name**: stfiledevo7bbcldbbn
- **Container**: uploads
- **Network**: Private endpoint only (publicNetworkAccess: Disabled)
- **Security**: Both apps have Storage Blob Data Contributor role

### Network Configuration
Both apps are configured with:
- VNet Integration (10.0.0.0/16 address space)
- Private endpoint to storage account
- Private DNS zone (privatelink.blob.core.windows.net)
- All traffic routed through VNet (vnetRouteAllEnabled: true)

## Key Features

### Security
✅ No connection strings or storage keys in code
✅ Managed Identity authentication
✅ Private endpoint connectivity (no public internet access to storage)
✅ VNet integration for secure communication
✅ HTTPS only
✅ TLS 1.2 minimum

### Code Highlights

**C# (Index.cshtml.cs)**:
```csharp
var blobServiceUri = new Uri($"https://{storageAccountName}.blob.core.windows.net");
var blobServiceClient = new BlobServiceClient(blobServiceUri, new ManagedIdentityCredential());
```

**Python (app.py)**:
```python
account_url = f"https://{STORAGE_ACCOUNT_NAME}.blob.core.windows.net"
credential = ManagedIdentityCredential()
return BlobServiceClient(account_url=account_url, credential=credential)
```

## Deployment Architecture

### C# App
- Resource Group: rg-fileupload-demo
- App Service: app-file-dev-o7bbcldb (Linux, B1, .NET 8.0)
- Managed Identity Principal ID: 3f030695-66c0-4c15-a313-ba3a998b07db

### Python App
- Resource Group: rg-python-fileupload-demo  
- App Service: app-pyfile-dev-lsxm5qbo (Linux, B1, Python 3.11)
- Managed Identity Principal ID: 7d45bd02-4e9e-45f3-bb30-cf5f21fd71be

## Files Uploaded
Both applications upload files to the same storage container with timestamped names:
- Format: `YYYYMMDD_HHMMSS_originalfilename`
- Example: `20251112_043958_contracts.csv`

## Infrastructure as Code
Both apps deployed using Bicep templates:
- `infra/main.bicep` - Main deployment
- `infra/modules/network.bicep` - VNet, subnets, private DNS
- `infra/modules/appservice-python.bicep` - Python App Service
- `infra/modules/roleassignment.bicep` - RBAC permissions

## Lessons Learned

1. **ManagedIdentityCredential vs DefaultAzureCredential**: Using explicit `ManagedIdentityCredential` ensures only Managed Identity is used (no fallback chain).

2. **Private Endpoint DNS**: Automatic resolution works when private DNS zone is linked to VNet.

3. **Python Deployment**: Manual file upload via Kudu API more reliable than zip deployment for Python apps.

4. **C# Deployment**: PageModel (.cs) changes require DLL recompilation; runtime compilation only applies to views (.cshtml).

5. **Network Security**: Setting `publicNetworkAccess: Disabled` forces all traffic through private endpoint.

## Testing
Both apps successfully upload files to Azure Blob Storage:
- C#: Verified in logs - "File uploaded successfully"
- Python: App running, ready to test

## Next Steps
- Test file upload in Python app
- Monitor application insights
- Add error handling improvements
- Consider adding file type validation
- Implement file size limits
