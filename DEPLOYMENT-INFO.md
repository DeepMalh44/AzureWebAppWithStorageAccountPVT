# Deployment Information

## Deployment Date
November 11, 2025

## Azure Resources Deployed

### Resource Group
- **Name**: `rg-fileupload-demo`
- **Location**: East US

### Storage Account
- **Name**: `stfiledevo7bbcldbbn`
- **SKU**: Standard_LRS
- **Public Access**: Disabled
- **Container**: `uploads`
- **Features**:
  - Private endpoint enabled
  - TLS 1.2 minimum
  - 7-day soft delete retention
  - Public blob access disabled

### Virtual Network
- **Name**: `vnet-file-dev-o7bbcldb`
- **Address Space**: 10.0.0.0/16
- **Subnets**:
  - `snet-appservice` (10.0.1.0/24) - For App Service integration
  - `snet-privateendpoints` (10.0.2.0/24) - For private endpoints

### Private DNS Zone
- **Name**: `privatelink.blob.core.windows.net`
- **Purpose**: DNS resolution for storage private endpoint

### App Service Plan
- **Name**: `plan-file-dev-o7bbcldb`
- **SKU**: B1 (Basic)
- **OS**: Linux

### App Service (Web App)
- **Name**: `app-file-dev-o7bbcldb`
- **URL**: https://app-file-dev-o7bbcldb.azurewebsites.net
- **Runtime**: .NET Core 8.0
- **Managed Identity**: System-assigned (enabled)
- **Principal ID**: `3f030695-66c0-4c15-a313-ba3a998b07db`
- **Features**:
  - VNet integration enabled
  - HTTPS only
  - TLS 1.2 minimum
  - Connected to storage via private endpoint

### RBAC Configuration
- **Role**: Storage Blob Data Contributor
- **Assignee**: App Service managed identity
- **Scope**: Storage account `stfiledevo7bbcldbbn`

## Application Configuration

The following app settings are configured:

```json
{
  "AzureStorage__AccountName": "stfiledevo7bbcldbbn",
  "AzureStorage__ContainerName": "uploads",
  "ASPNETCORE_ENVIRONMENT": "Development"
}
```

## Security Features

✅ **No connection strings or keys** - Uses managed identity  
✅ **Storage account has public access disabled**  
✅ **Private endpoint connectivity only**  
✅ **VNet integration for App Service**  
✅ **TLS 1.2 minimum**  
✅ **HTTPS only**  
✅ **Network isolation with private DNS**  

## Testing the Application

1. Open: https://app-file-dev-o7bbcldb.azurewebsites.net
2. Click "Choose file" to select a file
3. Click "Upload" to upload to Azure Storage
4. Files are stored securely in the private storage account

## Verification Commands

Check App Service status:
```bash
az webapp show --name app-file-dev-o7bbcldb --resource-group rg-fileupload-demo --query "{name:name, state:state, url:defaultHostName}"
```

Check Storage Account:
```bash
az storage account show --name stfiledevo7bbcldbbn --resource-group rg-fileupload-demo --query "{name:name, publicAccess:publicNetworkAccess, privateEndpoints:privateEndpointConnections[].id}"
```

List uploaded files (requires authentication):
```bash
az storage blob list --account-name stfiledevo7bbcldbbn --container-name uploads --auth-mode login
```

## Troubleshooting

### View Application Logs
```bash
az webapp log tail --name app-file-dev-o7bbcldb --resource-group rg-fileupload-demo
```

### Check Managed Identity
```bash
az webapp identity show --name app-file-dev-o7bbcldb --resource-group rg-fileupload-demo
```

### Verify VNet Integration
```bash
az webapp vnet-integration list --name app-file-dev-o7bbcldb --resource-group rg-fileupload-demo
```

## Clean Up Resources

To delete all deployed resources:
```bash
az group delete --name rg-fileupload-demo --yes --no-wait
```

## Next Steps

- Test file upload functionality
- Monitor application performance in Azure Portal
- Configure custom domain (optional)
- Set up Application Insights for monitoring (optional)
- Configure backup policies (optional)
