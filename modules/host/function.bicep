param functionAppName string
param useExistingAppServicePlan bool = false
param appServicePlanName string
param storageAccountName string
param location string
param applicationInsightsName string
param appSettings object = {}
param keyVaultName string = ''
param containerRegistryName string = ''
param containerImageName string = ''
param containerImageTag string = ''
@allowed([
  'None'
  'SystemAssigned'
  'UserAssigned'
])
param identityType string = 'None'

param identityName string = ''
param tags object = {}

param zoneRedundant bool = false

@allowed([
  'dotnet'
  'dotnetcore'
  'dotnet-isolated'
  'node'
  'python'
  'java'
  'powershell'
  'custom'
])
param runtimeName string = 'python'
param runtimeVersion string = '3.11'

@allowed(['Y1', 'EP3'])
param sku string = 'EP3'

param runFromPackage bool = false

var functionContentShareName = 'function-content-share'

module storageAccount '../storage/storage-account.bicep' = {
  name: 'func-storage-${functionAppName}'
  params: {
    location: location
    tags: tags
    name: storageAccountName
    shares: [
      {
        name: functionContentShareName
      }
    ]
  }
}

module functionApp './appservice.bicep' = {
  name: functionAppName
  params: {
    runFromPackage: runFromPackage
    appServiceName: functionAppName
    useExistingAppServicePlan: useExistingAppServicePlan
    keyVaultName: keyVaultName
    identityName: identityName
    identityType: identityType
    appServicePlanName: appServicePlanName
    location: location
    tags: tags
    sku: sku
    kind: 'functionapp,linux'
    containerImageName: containerImageName
    containerImageTag: containerImageTag
    containerRegistryName: containerRegistryName
    runtimeVersion: runtimeVersion
    runtimeName: runtimeName
    appSettings: union(appSettings, {
      WEBSITE_CONTENTSHARE: functionContentShareName
    })
    applicationInsightsName: applicationInsightsName
    storageAccountName: storageAccount.outputs.name
    zoneRedundant: zoneRedundant
    numberOfWorkers: zoneRedundant ? 3 : -1
  }
}

output identityPrincipalId string = functionApp.outputs.identityPrincipalId
output name string = functionApp.outputs.name
