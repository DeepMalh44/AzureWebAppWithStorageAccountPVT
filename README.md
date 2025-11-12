# Azure File Upload Web App

A simple ASP.NET Core web application that uploads files to Azure Blob Storage using Managed Identity authentication with private endpoints.

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

```
file-upload-webapp/
├── FileUploadApp/              # ASP.NET Core Web Application
│   ├── Services/               # Business logic
│   ├── Pages/                  # Razor Pages
│   ├── wwwroot/                # Static files
│   └── appsettings.json        # Configuration
├── infra/                      # Infrastructure as Code (Bicep)
│   ├── main.bicep              # Main deployment file
│   ├── main.bicepparam         # Parameters file
│   └── modules/                # Bicep modules
│       ├── network.bicep       # VNet, subnets, DNS
│       ├── storage.bicep       # Storage account with private endpoint
│       ├── appservice.bicep    # App Service Plan and Web App
│       └── roleassignment.bicep # RBAC configuration
└── README.md                   # This file
```

## Deployment Steps

### 1. Deploy Infrastructure

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

### 2. Update Application Configuration

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

### 3. Build and Publish the Application

```powershell
# Navigate to the project directory
cd FileUploadApp

# Build the application
dotnet build

# Publish the application
dotnet publish -c Release -o ./publish
```

### 4. Deploy to Azure App Service

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

## Local Development

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
