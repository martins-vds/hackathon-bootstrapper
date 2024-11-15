@minLength(1)
@maxLength(64)
@description('Prefix for all resources')
param hackName string

@minLength(1)
@description('Primary location for all resources')
param location string

param identities identity[] = []

param tags object = {}

type identity = {
  principalId : string
  principalType: 'User' | 'ServicePrincipal' | 'Group'
}

var abbrs = loadJsonContent('abbreviations.json')
var roles = loadJsonContent('azure_roles.json')

var resourceToken = toLower(uniqueString(subscription().id, hackName, location))

var principalIds = map(identities, i => i.principalId)

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

module storage 'modules/storage/storage-account.bicep' = {
  name: 'storage'
  params: {
    name: '${abbrs.storageStorageAccounts}${resourceToken}'
    tags: tags
    publicNetworkAccess: 'Disabled'
    keyVaultName: vault.outputs.keyVaultName
    deleteRetentionPolicy: {
      enabled: true
      days: 2
    }
  }
}

module openAi 'modules/ai/cognitiveservices.bicep' = {
  name: 'openai'
  params: {
    name: '${abbrs.cognitiveServicesAccounts}aoai-${resourceToken}'
    tags: tags
    keyVaultName: vault.outputs.keyVaultName
    kind: 'OpenAI'    
  }
}

module eventHub 'modules/event-hub.bicep' = {
  name: 'event-hub'
  params: {
    location: location
    tags: tags
    eventHubNamespaceName: '${abbrs.eventHubNamespaces}${resourceToken}'
    eventHubName: '${abbrs.eventHubNamespacesEventHubs}${resourceToken}'
  }
}

module cosmos 'modules/database/cosmos/cosmos-account.bicep' = {
  name: 'cosmos-sql'
  params: {
    accountName: '${abbrs.documentDBDatabaseAccounts}${resourceToken}'
    databaseName: '${abbrs.sqlServersDatabases}${resourceToken}'
    location: location
    tags: tags
    principalIds: principalIds
    kind: 'GlobalDocumentDB'
    keyVaultName: vault.outputs.keyVaultName
  }
}

module formRecognizer 'modules/ai/cognitiveservices.bicep' = {
  name: 'formrecognizer'
  params: {
    name: '${abbrs.cognitiveServicesFormRecognizer}${resourceToken}'
    kind: 'FormRecognizer'
    tags: tags    
    keyVaultName: vault.outputs.keyVaultName
  }
}

module containerRegistry 'modules/host/container-registry.bicep' = {
  name: 'container-registry'
  params: {
    name: '${abbrs.containerRegistryRegistries}${resourceToken}'
    workspaceId: monitoring.outputs.logAnalyticsWorkspaceId
    tags: tags
    sku: {
      name: 'Premium'
    }    
  }
}

module appService 'modules/host/appservice.bicep' = {
  name: 'app-service'
  params: {
    runFromPackage: true
    identityType: 'SystemAssigned'
    appServiceName: '${abbrs.webSitesAppService}${resourceToken}'
    appServicePlanName: '${abbrs.webServerFarms}${resourceToken}'
    location: location
    tags: tags
    runtimeName: 'node'
    runtimeVersion: '20-lts'
    applicationInsightsName: monitoring.outputs.applicationInsightsName
  }
}

module azureFunction 'modules/host/function.bicep' = {
  name: 'function-app'
  params: {
    location: location
    runFromPackage: true
    keyVaultName: vault.outputs.keyVaultName
    identityType: 'SystemAssigned'
    appServicePlanName: '${abbrs.webServerFarms}function-${resourceToken}'
    functionAppName: '${abbrs.webSitesFunctions}${resourceToken}'
    tags: tags
    storageAccountName: '${abbrs.storageStorageAccounts}function${resourceToken}'
    applicationInsightsName: monitoring.outputs.applicationInsightsName
  }    
}
