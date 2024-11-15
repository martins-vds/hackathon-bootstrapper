@minLength(1)
@maxLength(64)
@description('Prefix for all resources')
param hackName string

@minLength(1)
@description('Primary location for all resources')
param location string

param tags object = {}

var abbrs = loadJsonContent('abbreviations.json')
var roles = loadJsonContent('azure_roles.json')

var resourceToken = toLower(uniqueString(subscription().id, hackName, location))

module vault 'modules/security/vault.bicep' = {
  name: 'keyvault'
  params: {
    tags: tags
    keyVaultName: '${abbrs.keyVaultVaults}${resourceToken}'    
  }
}

// Monitor application with Azure Monitor
module monitoring 'modules/monitor/monitoring.bicep' = {
  name: 'monitoring'
  params: {
    location: location
    tags: tags
    logAnalyticsName: '${abbrs.operationalInsightsWorkspaces}${resourceToken}'
    applicationInsightsName: '${abbrs.insightsComponents}${resourceToken}'
    applicationInsightsDashboardName: '${abbrs.portalDashboards}${resourceToken}'
  }
}
