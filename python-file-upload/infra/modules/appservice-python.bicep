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

var appServicePlanName = 'plan-pyfile-${environment}-${take(uniqueSuffix, 8)}'
var appServiceName = 'app-pyfile-${environment}-${take(uniqueSuffix, 8)}'

// ============================================
// App Service Plan (Python)
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
// App Service (Python)
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
      linuxFxVersion: 'PYTHON|3.11'
      ftpsState: 'FtpsOnly'
      minTlsVersion: '1.2'
      http20Enabled: true
      alwaysOn: true
      vnetRouteAllEnabled: true
      appCommandLine: 'gunicorn --bind 0.0.0.0:8000 --timeout 600 --log-level info app:app'
      appSettings: [
        {
          name: 'SCM_DO_BUILD_DURING_DEPLOYMENT'
          value: 'true'
        }
        {
          name: 'WEBSITE_HTTPLOGGING_RETENTION_DAYS'
          value: '7'
        }
      ]
    }
  }
}

// Enable basic authentication for deployment
resource basicAuthScm 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2024-04-01' = {
  parent: appService
  name: 'scm'
  properties: {
    allow: true
  }
}

resource basicAuthFtp 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2024-04-01' = {
  parent: appService
  name: 'ftp'
  properties: {
    allow: true
  }
}

// ============================================
// Outputs
// ============================================

output appServiceId string = appService.id
output appServiceName string = appService.name
output appServiceUrl string = 'https://${appService.properties.defaultHostName}'
output appServicePrincipalId string = appService.identity.principalId
