targetScope = 'subscription'

// ============================================
// Parameters
// ============================================

@description('Primary location for all resources')
param location string = 'eastus'

@description('Resource group name')
param resourceGroupName string = 'rg-fileupload-demo'

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

// Storage Account with Private Endpoint
module storage 'modules/storage.bicep' = {
  scope: rg
  name: 'storage-deployment'
  params: {
    location: location
    environment: environment
    uniqueSuffix: uniqueSuffix
    subnetId: vnet.outputs.privateEndpointSubnetId
    privateDnsZoneId: vnet.outputs.privateDnsZoneId
  }
}

// App Service with VNet Integration
module appService 'modules/appservice.bicep' = {
  scope: rg
  name: 'appservice-deployment'
  params: {
    location: location
    environment: environment
    uniqueSuffix: uniqueSuffix
    storageAccountName: storage.outputs.storageAccountName
    vnetIntegrationSubnetId: vnet.outputs.appServiceSubnetId
  }
}

// Role Assignment - Grant App Service Managed Identity access to Storage
module roleAssignment 'modules/roleassignment.bicep' = {
  scope: rg
  name: 'roleassignment-deployment'
  params: {
    storageAccountName: storage.outputs.storageAccountName
    appServicePrincipalId: appService.outputs.appServicePrincipalId
  }
}

// ============================================
// Outputs
// ============================================

output resourceGroupName string = rg.name
output storageAccountName string = storage.outputs.storageAccountName
output appServiceName string = appService.outputs.appServiceName
output appServiceUrl string = appService.outputs.appServiceUrl
output appServicePrincipalId string = appService.outputs.appServicePrincipalId
