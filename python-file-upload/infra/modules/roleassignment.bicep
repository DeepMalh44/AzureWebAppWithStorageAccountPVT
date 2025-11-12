// ============================================
// Parameters
// ============================================

@description('Storage Account Name')
param storageAccountName string

@description('App Service Principal ID')
param appServicePrincipalId string

// ============================================
// Variables
// ============================================

// Storage Blob Data Contributor role ID
var storageBlobDataContributorRoleId = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'

// ============================================
// Existing Resources
// ============================================

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: storageAccountName
}

// ============================================
// Role Assignment
// ============================================

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccount.id, appServicePrincipalId, storageBlobDataContributorRoleId)
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', storageBlobDataContributorRoleId)
    principalId: appServicePrincipalId
    principalType: 'ServicePrincipal'
  }
}

// ============================================
// Outputs
// ============================================

output roleAssignmentId string = roleAssignment.id
