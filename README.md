# Azure File Upload Web App

File upload applications that demonstrate secure Azure Blob Storage integration using Managed Identity authentication with private endpoints. This repository contains two implementations:

- **C# ASP.NET Core** - Enterprise-ready web application
- **Python Flask** - Lightweight alternative with identical functionality

## Architecture

This solution deploys:

- **Azure App Service**: Hosts the ASP.NET Core web application
- **Azure Storage Account**: Stores uploaded files in blob containers
  - Public access disabled
  - Private endpoint enabled
  - Accessible only through private network
- **Virtual Network**: Provides network isolation
  - App Service integration subnet
  - Private endpoint subnet
- **Private DNS Zone**: Enables private endpoint name resolution
- **Managed Identity**: Secure authentication between App Service and Storage

## Prerequisites

- Azure subscription
- Azure CLI installed
- .NET 8.0 SDK installed
- Visual Studio Code or Visual Studio 2022

## Project Structure

```plaintext
file-upload-webapp/
├── FileUploadApp/              # C# ASP.NET Core Web Application
│   ├── Pages/                  # Razor Pages
│   ├── wwwroot/                # Static files
│   ├── Program.cs              # Application entry point
│   └── appsettings.json        # Configuration
├── python-file-upload/         # Python Flask Web Application
│   ├── app.py                  # Flask application
│   ├── requirements.txt        # Python dependencies
│   ├── templates/              # HTML templates
│   ├── startup.txt             # Gunicorn startup command
│   └── infra/                  # Python app infrastructure (Bicep)
│       ├── main.bicep          # Main deployment file
│       ├── main.bicepparam     # Parameters file
│       └── modules/            # Bicep modules
├── infra/                      # C# app infrastructure (Bicep)
│   ├── main.bicep              # Main deployment file
│   ├── main.bicepparam         # Parameters file
│   └── modules/                # Bicep modules
│       ├── network.bicep       # VNet, subnets, DNS
│       ├── storage.bicep       # Storage account with private endpoint
│       ├── appservice.bicep    # App Service Plan and Web App
│       └── roleassignment.bicep # RBAC configuration
└── README.md                   # This file
```

## Live Demo

- **C# App**: https://app-file-dev-o7bbcldb.azurewebsites.net
- **Python App**: https://app-pyfile-dev-lsxm5qbo.azurewebsites.net

Both applications share the same Azure Storage account and use identical security configurations.

## Deployment Steps

### Option 1: Deploy C# ASP.NET Core App

#### 1. Deploy Infrastructure

```powershell
# Login to Azure
az login

# Set your subscription (if you have multiple)
az account set --subscription "<your-subscription-id>"

# Deploy the infrastructure
az deployment sub create `
  --location eastus `
  --template-file infra/main.bicep `
  --parameters infra/main.bicepparam
```

This deployment creates:

- Resource group
- Virtual network with subnets
- Storage account with private endpoint and private DNS
- App Service with VNet integration
- Managed Identity configuration
- RBAC role assignments

#### 2. Update Application Configuration

After deployment, update the `appsettings.json` file with your storage account name:

```json
{
  "AzureStorage": {
    "AccountName": "<your-storage-account-name>",
    "ContainerName": "uploads"
  }
}
```

You can get the storage account name from the deployment outputs:

```powershell
az deployment sub show `
  --name main `
  --query properties.outputs.storageAccountName.value
```

#### 3. Build and Publish the Application

```powershell
# Navigate to the project directory
cd FileUploadApp

# Build the application
dotnet build

# Publish the application
dotnet publish -c Release -o ./publish
```

#### 4. Deploy to Azure App Service

```powershell
# Get the App Service name from deployment outputs
$appServiceName = az deployment sub show `
  --name main `
  --query properties.outputs.appServiceName.value `
  --output tsv

# Deploy the application
az webapp deployment source config-zip `
  --resource-group rg-fileupload-demo `
  --name $appServiceName `
  --src ./publish.zip
```

Or create a zip file and deploy via VS Code Azure extension.

### Option 2: Deploy Python Flask App

#### 1. Deploy Infrastructure

```powershell
# Navigate to the Python app infrastructure directory
cd python-file-upload/infra

# Deploy the infrastructure
az deployment sub create `
  --location eastus `
  --template-file main.bicep `
  --parameters main.bicepparam
```

This creates a separate VNet and App Service for the Python app, but uses the same shared storage account.

#### 2. Deploy the Application

```powershell
# Navigate back to the Python app directory
cd ..

# Create deployment package
Remove-Item deploy.zip -ErrorAction SilentlyContinue
Compress-Archive -Path app.py,requirements.txt,templates,startup.txt -DestinationPath deploy.zip -Force

# Get the App Service name
$pythonAppName = az deployment sub show `
  --name main `
  --query properties.outputs.appServiceName.value `
  --output tsv

# Deploy using zip
az webapp deploy `
  --resource-group rg-python-fileupload-demo `
  --name $pythonAppName `
  --src-path deploy.zip `
  --type zip
```

The Python app automatically:

- Detects `requirements.txt` and installs dependencies
- Uses Gunicorn as the WSGI server
- Configures Managed Identity for Azure Storage access

## Technology Comparison

| Feature | C# ASP.NET Core | Python Flask |
|---------|----------------|--------------|
| **Runtime** | .NET 8.0 | Python 3.11 |
| **Web Server** | Kestrel | Gunicorn |
| **Template Engine** | Razor Pages | Jinja2 |
| **Authentication** | Azure.Identity SDK | azure-identity |
| **Storage SDK** | Azure.Storage.Blobs | azure-storage-blob |
| **Deployment Size** | ~50 MB | ~15 MB |
| **Startup Time** | ~3-5 seconds | ~2-3 seconds |
| **Memory Usage** | ~100-150 MB | ~50-80 MB |
| **Best For** | Enterprise apps, complex workflows | Microservices, APIs, rapid prototyping |

Both implementations provide identical functionality and security features.

## Local Development

### C# Application

For local development, you can use Azure CLI authentication:

1. Login to Azure CLI:
   ```powershell
   az login
   ```

2. Update `appsettings.Development.json`:
   ```json
   {
     "AzureStorage": {
       "AccountName": "<your-storage-account-name>",
       "ContainerName": "uploads"
     }
   }
   ```

3. Run the application:
   
   ```powershell
   dotnet run
   ```

**Note**: Local development will connect to storage over the public network unless you configure VPN or private network access.

### Python Application

1. Install Python dependencies:

   ```powershell
   cd python-file-upload
   pip install -r requirements.txt
   ```

2. Set environment variables:

   ```powershell
   $env:STORAGE_ACCOUNT_NAME = "<your-storage-account-name>"
   $env:CONTAINER_NAME = "uploads"
   ```

3. Run the Flask application:

   ```powershell
   python app.py
   ```

4. Open browser to `http://localhost:8000`

**Note**: The Python app uses `ManagedIdentityCredential` which falls back to Azure CLI credentials in local development.

## Key Features

### Managed Identity Authentication
- No connection strings or keys in configuration
- App Service uses its system-assigned managed identity
- Automatic credential rotation
- Azure RBAC for access control

### Private Endpoint
- Storage account accessible only through private network
- No public internet exposure
- Private DNS resolution for blob.core.windows.net

### VNet Integration
- App Service integrated with dedicated subnet
- All outbound traffic routes through VNet
- Can access private endpoint resources

### Security Best Practices
- HTTPS only
- TLS 1.2 minimum
- Public access disabled on storage
- Network isolation
- Azure RBAC (Storage Blob Data Contributor role)

## Troubleshooting

### Storage Account Not Accessible

If the app can't access the storage account:

1. Verify managed identity is enabled:
   ```powershell
   az webapp identity show --name <app-name> --resource-group rg-fileupload-demo
   ```

2. Check role assignment:
   ```powershell
   az role assignment list --assignee <principal-id> --scope <storage-account-id>
   ```

3. Verify VNet integration:
   ```powershell
   az webapp vnet-integration list --name <app-name> --resource-group rg-fileupload-demo
   ```

### Private Endpoint Issues

1. Check private endpoint connection:
   ```powershell
   az network private-endpoint show --name <pe-name> --resource-group rg-fileupload-demo
   ```

2. Verify DNS resolution from App Service (using Kudu):
   ```bash
   nslookup <storage-account-name>.blob.core.windows.net
   ```
   Should resolve to 10.0.2.x (private IP)

## Clean Up

To delete all resources:

```powershell
az group delete --name rg-fileupload-demo --yes
```

## Additional Resources

- [Azure Managed Identity](https://learn.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/overview)
- [Azure Private Endpoints](https://learn.microsoft.com/en-us/azure/private-link/private-endpoint-overview)
- [App Service VNet Integration](https://learn.microsoft.com/en-us/azure/app-service/overview-vnet-integration)
- [Azure Storage Security](https://learn.microsoft.com/en-us/azure/storage/common/storage-security-guide)
