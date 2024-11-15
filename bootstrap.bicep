@minLength(1)
@maxLength(64)
@description('Prefix for all resources')
param hackName string

@minLength(1)
@description('Primary location for all resources')
param location string = resourceGroup().location

@description('Principal Ids for each hackathon team')
param teamObjectIds objectId[] = []

param tags object = {}

type objectId = string

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

module storage 'modules/storage/storage-account.bicep' = [
  for (_, index) in teamObjectIds: {
    name: 'storage-team-${index}'
    params: {
      name: '${abbrs.storageStorageAccounts}${resourceToken}${index}'
      tags: tags
      keyVaultName: vault.outputs.keyVaultName
      deleteRetentionPolicy: {
        enabled: true
        days: 2
      }
    }
  }
]

module openAi 'modules/ai/cognitiveservices.bicep' = [
  for (_, index) in teamObjectIds: {
    name: 'openai-team-${index}'
    params: {
      name: '${abbrs.cognitiveServicesAccounts}aoai-${resourceToken}-${index}'
      tags: tags
      keyVaultName: vault.outputs.keyVaultName
      kind: 'OpenAI'
    }
  }
]

module eventHub 'modules/event-hub.bicep' = [
  for (_, index) in teamObjectIds: {
    name: 'event-hub-team-${index}'
    params: {
      location: location
      tags: tags
      eventHubNamespaceName: '${abbrs.eventHubNamespaces}${resourceToken}-${index}'
      eventHubName: '${abbrs.eventHubNamespacesEventHubs}${resourceToken}-${index}'
    }
  }
]

module cosmos 'modules/database/cosmos/cosmos-account.bicep' = [
  for (_, index) in teamObjectIds: {
    name: 'cosmos-team-${index}'
    params: {
      accountName: '${abbrs.documentDBDatabaseAccounts}${resourceToken}-${index}'
      databaseName: '${abbrs.sqlServersDatabases}${resourceToken}-${index}'
      location: location
      tags: tags
      principalIds: teamObjectIds
      kind: 'GlobalDocumentDB'
      keyVaultName: vault.outputs.keyVaultName
    }
  }
]

module formRecognizer 'modules/ai/cognitiveservices.bicep' = [
  for (_, index) in teamObjectIds: {
    name: 'formrecognizer-team-${index}'
    params: {
      name: '${abbrs.cognitiveServicesFormRecognizer}${resourceToken}-${index}'
      kind: 'FormRecognizer'
      tags: tags
      keyVaultName: vault.outputs.keyVaultName
    }
  }
]

module computerVision 'modules/ai/cognitiveservices.bicep' = [
  for (_, index) in teamObjectIds: {
    name: 'computerVision-team-${index}'
    params: {
      name: '${abbrs.cognitiveServicesAccounts}vision-${resourceToken}-${index}'
      kind: 'ComputerVision'
      tags: tags
      keyVaultName: vault.outputs.keyVaultName
    }
  }
]

module speechServices 'modules/ai/cognitiveservices.bicep' = [
  for (_, index) in teamObjectIds: {
    name: 'speechServices-team-${index}'
    params: {
      name: '${abbrs.cognitiveServicesAccounts}speech-${resourceToken}-${index}'
      kind: 'SpeechServices'
      tags: tags
      keyVaultName: vault.outputs.keyVaultName
    }
  }
]

module containerRegistry 'modules/host/container-registry.bicep' = [
  for (_, index) in teamObjectIds: {
    name: 'container-registry-team-${index}'
    params: {
      name: '${abbrs.containerRegistryRegistries}${resourceToken}${index}'
      workspaceId: monitoring.outputs.logAnalyticsWorkspaceId
      tags: tags
      sku: {
        name: 'Premium'
      }
    }
  }
]

module appService 'modules/host/appservice.bicep' = [
  for (_, index) in teamObjectIds: {
    name: 'app-service-team-${index}'
    params: {
      runFromPackage: true
      identityType: 'SystemAssigned'
      appServiceName: '${abbrs.webSitesAppService}${resourceToken}-${index}'
      appServicePlanName: '${abbrs.webServerFarms}${resourceToken}-${index}'
      location: location
      tags: tags
      runtimeName: 'node'
      runtimeVersion: '20-lts'
      applicationInsightsName: monitoring.outputs.applicationInsightsName
    }
  }
]

module azureFunction 'modules/host/function.bicep' = [
  for (_, index) in teamObjectIds: {
    name: 'function-app-team-${index}'
    params: {
      location: location
      runFromPackage: true
      keyVaultName: vault.outputs.keyVaultName
      identityType: 'SystemAssigned'
      appServicePlanName: '${abbrs.webServerFarms}function-${resourceToken}-${index}'
      functionAppName: '${abbrs.webSitesFunctions}${resourceToken}-${index}'
      tags: tags
      storageAccountName: '${abbrs.storageStorageAccounts}function${resourceToken}${index}'
      applicationInsightsName: monitoring.outputs.applicationInsightsName
    }
  }
]

module searchService 'modules/search/search-services.bicep' = [
  for (_, index) in teamObjectIds: {
    name: 'search-service-team-${index}'
    params: {
      name: '${abbrs.searchSearchServices}${resourceToken}-${index}'
      tags: tags
      authOptions: {
        aadOrApiKey: {
          aadAuthFailureMode: 'http401WithBearerChallenge'
        }
      }
      keyVaultName: vault.outputs.keyVaultName
    }
  }
]
