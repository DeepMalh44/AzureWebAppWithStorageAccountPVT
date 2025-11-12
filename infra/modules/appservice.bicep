// ============================================
// Parameters
// ============================================

@description('Location for all resources')
param location string

@description('Environment name')
param environment string

@description('Unique suffix for resource names')
param uniqueSuffix string

@description('Storage account name')
param storageAccountName string

@description('VNet Integration Subnet ID')
param vnetIntegrationSubnetId string

// ============================================
// Variables
// ============================================

var appServicePlanName = 'plan-fileupload-${environment}-${uniqueSuffix}'
var appServiceName = 'app-fileupload-${environment}-${uniqueSuffix}'

// ============================================
// App Service Plan
// ============================================

resource appServicePlan 'Microsoft.Web/serverfarms@2024-04-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: 'B1'
    tier: 'Basic'
    capacity: 1
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

// ============================================
// App Service
// ============================================

resource appService 'Microsoft.Web/sites@2024-04-01' = {
  name: appServiceName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    virtualNetworkSubnetId: vnetIntegrationSubnetId
    siteConfig: {
      linuxFxVersion: 'DOTNETCORE|8.0'
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      http20Enabled: true
      alwaysOn: true
      vnetRouteAllEnabled: true
      appSettings: [
        {
          name: 'AzureStorage__AccountName'
          value: storageAccountName
        }
        {
          name: 'AzureStorage__ContainerName'
          value: 'uploads'
        }
        {
          name: 'ASPNETCORE_ENVIRONMENT'
          value: environment == 'prod' ? 'Production' : 'Development'
        }
      ]
    }
  }
}

// ============================================
// Outputs
// ============================================

output appServiceId string = appService.id
output appServiceName string = appService.name
output appServiceUrl string = 'https://${appService.properties.defaultHostName}'
output appServicePrincipalId string = appService.identity.principalId
