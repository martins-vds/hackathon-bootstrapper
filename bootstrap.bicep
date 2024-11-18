@minLength(1)
@maxLength(64)
@description('Name of the hackathon')
param hackName string

@minLength(1)
@description('Location of the resources to deploy')
param location string = resourceGroup().location

@description('Object IDs of the teams participating in the hackathon')
param hackTeams objectId[] = []

@description('Tags to apply to all resources')
param tags object = {}

@description('Size of the virtual machine to use for the machine learning workspace compute')
@allowed([
  'Standard_A2_v2'
  'Standard_D2s_v3'
])
param hackComputeVmSize string = 'Standard_A2_v2'

@description('Object IDs of the users who will have access to the machine learning workspace')
param hackComputeUsers array = []

type objectId = string

var abbrs = loadJsonContent('abbreviations.json')
var roles = loadJsonContent('azure_roles.json')

var resourceToken = toLower(uniqueString(subscription().id, hackName, location))

var requiredTags = {
  HackathonName: hackName
}

var allTags = union(tags, requiredTags)

module vault 'modules/security/vault.bicep' = {
  name: 'keyvault'
  params: {
    tags: allTags
    keyVaultName: '${abbrs.keyVaultVaults}${resourceToken}'
  }
}

// Monitor application with Azure Monitor
module monitoring 'modules/monitor/monitoring.bicep' = {
  name: 'monitoring'
  params: {
    location: location
    tags: allTags
    logAnalyticsName: '${abbrs.operationalInsightsWorkspaces}${resourceToken}'
    applicationInsightsName: '${abbrs.insightsComponents}${resourceToken}'
    applicationInsightsDashboardName: '${abbrs.portalDashboards}${resourceToken}'
  }
}

module storage 'modules/storage/storage-account.bicep' = [
  for (_, index) in hackTeams: {
    name: 'storage-team-${index}'
    params: {
      name: '${abbrs.storageStorageAccounts}${resourceToken}${index}'
      tags: allTags
      keyVaultName: vault.outputs.keyVaultName
      deleteRetentionPolicy: {
        enabled: true
        days: 2
      }
    }
  }
]

module openAi 'modules/ai/cognitiveservices.bicep' = [
  for (_, index) in hackTeams: {
    name: 'openai-team-${index}'
    params: {
      name: '${abbrs.cognitiveServicesAccounts}aoai-${resourceToken}-${index}'
      tags: allTags
      keyVaultName: vault.outputs.keyVaultName
      kind: 'OpenAI'
    }
  }
]

module eventHub 'modules/event-hub.bicep' = [
  for (_, index) in hackTeams: {
    name: 'event-hub-team-${index}'
    params: {
      location: location
      tags: allTags
      eventHubNamespaceName: '${abbrs.eventHubNamespaces}${resourceToken}-${index}'
      eventHubName: '${abbrs.eventHubNamespacesEventHubs}${resourceToken}-${index}'
    }
  }
]

module cosmos 'modules/database/cosmos/cosmos-account.bicep' = [
  for (_, index) in hackTeams: {
    name: 'cosmos-team-${index}'
    params: {
      accountName: '${abbrs.documentDBDatabaseAccounts}${resourceToken}-${index}'
      databaseName: '${abbrs.sqlServersDatabases}${resourceToken}-${index}'
      location: location
      tags: allTags
      principalIds: hackTeams
      kind: 'GlobalDocumentDB'
      keyVaultName: vault.outputs.keyVaultName
    }
  }
]

module formRecognizer 'modules/ai/cognitiveservices.bicep' = [
  for (_, index) in hackTeams: {
    name: 'formrecognizer-team-${index}'
    params: {
      name: '${abbrs.cognitiveServicesFormRecognizer}${resourceToken}-${index}'
      kind: 'FormRecognizer'
      tags: allTags
      keyVaultName: vault.outputs.keyVaultName
    }
  }
]

module computerVision 'modules/ai/cognitiveservices.bicep' = [
  for (_, index) in hackTeams: {
    name: 'computerVision-team-${index}'
    params: {
      name: '${abbrs.cognitiveServicesAccounts}vision-${resourceToken}-${index}'
      kind: 'ComputerVision'
      tags: allTags
      keyVaultName: vault.outputs.keyVaultName
    }
  }
]

module speechServices 'modules/ai/cognitiveservices.bicep' = [
  for (_, index) in hackTeams: {
    name: 'speechServices-team-${index}'
    params: {
      name: '${abbrs.cognitiveServicesAccounts}speech-${resourceToken}-${index}'
      kind: 'SpeechServices'
      tags: allTags
      keyVaultName: vault.outputs.keyVaultName
    }
  }
]

module containerRegistry 'modules/host/container-registry.bicep' = [
  for (_, index) in hackTeams: {
    name: 'container-registry-team-${index}'
    params: {
      name: '${abbrs.containerRegistryRegistries}${resourceToken}${index}'
      workspaceId: monitoring.outputs.logAnalyticsWorkspaceId
      tags: allTags
      sku: {
        name: 'Premium'
      }
    }
  }
]

module appService 'modules/host/appservice.bicep' = [
  for (_, index) in hackTeams: {
    name: 'app-service-team-${index}'
    params: {
      runFromPackage: true
      identityType: 'SystemAssigned'
      appServiceName: '${abbrs.webSitesAppService}${resourceToken}-${index}'
      appServicePlanName: '${abbrs.webServerFarms}${resourceToken}-${index}'
      location: location
      tags: allTags
      runtimeName: 'node'
      runtimeVersion: '20-lts'
      applicationInsightsName: monitoring.outputs.applicationInsightsName
    }
  }
]

module azureFunction 'modules/host/function.bicep' = [
  for (_, index) in hackTeams: {
    name: 'function-app-team-${index}'
    params: {
      location: location
      runFromPackage: true
      keyVaultName: vault.outputs.keyVaultName
      identityType: 'SystemAssigned'
      appServicePlanName: '${abbrs.webServerFarms}function-${resourceToken}-${index}'
      functionAppName: '${abbrs.webSitesFunctions}${resourceToken}-${index}'
      tags: allTags
      storageAccountName: '${abbrs.storageStorageAccounts}function${resourceToken}${index}'
      applicationInsightsName: monitoring.outputs.applicationInsightsName
    }
  }
]

module searchService 'modules/search/search-services.bicep' = [
  for (_, index) in hackTeams: {
    name: 'search-service-team-${index}'
    params: {
      name: '${abbrs.searchSearchServices}${resourceToken}-${index}'
      tags: allTags
      authOptions: {
        aadOrApiKey: {
          aadAuthFailureMode: 'http401WithBearerChallenge'
        }
      }
      keyVaultName: vault.outputs.keyVaultName
    }
  }
]

module mlWorkspace 'modules/ai/machinelearning.bicep' = {
  name: 'machine-learning-workspace'
  params: {
    applicationInsightsId: monitoring.outputs.applicationInsightsId
    keyVaultId: vault.outputs.id
    workspaceName: '${abbrs.machineLearningServicesWorkspaces}${resourceToken}'
    workspaceStorageName: '${abbrs.storageStorageAccounts}mlw${resourceToken}'
    workspaceComputeVmSize: hackComputeVmSize
    workspaceComputeUsers: hackComputeUsers
    tags: allTags
  }
}

module rbca 'modules/security/rbac.bicep' = {
  name: 'role-assignment'
  params: {
    principalIds: hackTeams
    roles: [
      roles.AcrDelete
      roles.AcrPull
      roles.AcrPush
      roles.ApplicationInsightsComponentContributor
      roles.AzureEventHubsDataOwner
      roles.AzureMLDataScientist
      roles.CognitiveServicesContributor
      roles.CognitiveServicesCustomVisionContributor
      roles.CognitiveServicesCustomVisionDeployment
      roles.CognitiveServicesOpenAIContributor
      roles.CosmosDBOperator
      roles.DocumentDBAccountContributor
      roles.KeyVaultAdministrator
      roles.KeyVaultCertificateUser
      roles.KeyVaultCryptoUser
      roles.KeyVaultSecretsUser
      roles.MonitoringContributor
      roles.SearchIndexDataContributor
      roles.SearchServiceContributor
      roles.StorageAccountContributor
      roles.StorageBlobDataOwner
      roles.StorageFileDataPrivilegedContributor
      roles.StorageQueueDataContributor
      roles.StorageTableDataContributor
      roles.WebPlanContributor
      roles.WebsiteContributor
    ]
  }
}
