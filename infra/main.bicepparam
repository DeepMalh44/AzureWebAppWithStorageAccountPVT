using './main.bicep'

// ============================================
// Parameters
// ============================================

param location = 'eastus'
param resourceGroupName = 'rg-fileupload-demo'
param environment = 'dev'
// uniqueSuffix will be auto-generated based on subscription and resource group
