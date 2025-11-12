targetScope = 'subscription'

// ============================================
// Parameters
// ============================================

@description('Primary location for all resources')
param location string = 'eastus'

@description('Resource group name')
param resourceGroupName string = 'rg-python-fileupload-demo'

@description('Environment name')
@allowed([
  'dev'
  'test'
  'prod'
])
param environment string = 'dev'

@description('Unique suffix for resource names')
param uniqueSuffix string = uniqueString(subscription().subscriptionId, resourceGroupName)

// ============================================
// Resource Group
// ============================================

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
}

// ============================================
// Modules
// ============================================

// Virtual Network Module
module vnet 'modules/network.bicep' = {
  scope: rg
  name: 'vnet-deployment'
  params: {
    location: location
    environment: environment
    uniqueSuffix: uniqueSuffix
  }
}

// Storage Account with Private Endpoint (reusing existing storage account)
// NOTE: Using the same storage account as C# app: stfiledevo7bbcldbbn
// We just need to grant the Python app's Managed Identity the same permissions

// App Service (Python) with VNet Integration
module appService 'modules/appservice-python.bicep' = {
  scope: rg
  name: 'appservice-python-deployment'
  params: {
    location: location
    environment: environment
    uniqueSuffix: uniqueSuffix
    storageAccountName: 'stfiledevo7bbcldbbn'  // Using existing storage account
    vnetIntegrationSubnetId: vnet.outputs.appServiceSubnetId
  }
}

// Role Assignment - Grant Python App Service Managed Identity access to Storage
module roleAssignment 'modules/roleassignment.bicep' = {
  scope: resourceGroup('rg-fileupload-demo')  // Storage is in the C# app's resource group
  name: 'roleassignment-python-deployment'
  params: {
    storageAccountName: 'stfiledevo7bbcldbbn'
    appServicePrincipalId: appService.outputs.appServicePrincipalId
  }
}

// ============================================
// Outputs
// ============================================

output resourceGroupName string = rg.name
output appServiceName string = appService.outputs.appServiceName
output appServiceUrl string = appService.outputs.appServiceUrl
output appServicePrincipalId string = appService.outputs.appServicePrincipalId
