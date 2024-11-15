param name string
param location string = resourceGroup().location
param tags object = {}

@allowed(['Hot', 'Cool', 'Premium'])
param accessTier string = 'Hot'
param allowBlobPublicAccess bool = false
param allowCrossTenantReplication bool = true
param allowSharedKeyAccess bool = true
param defaultToOAuthAuthentication bool = false
param deleteRetentionPolicy object = {}
@allowed(['AzureDnsZone', 'Standard'])
param dnsEndpointType string = 'Standard'
param kind string = 'StorageV2'
param minimumTlsVersion string = 'TLS1_2'
@allowed(['Enabled', 'Disabled'])
param publicNetworkAccess string = 'Disabled'
param sku object = { name: 'Standard_LRS' }
param containers array = []
param shares array = []
param queues array = []
param virtualNetworkRules array = []

param keyVaultName string = ''

resource storage 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: name
  location: location
  tags: tags
  kind: kind
  sku: sku
  properties: {
    accessTier: accessTier
    allowBlobPublicAccess: allowBlobPublicAccess
    allowCrossTenantReplication: allowCrossTenantReplication
    allowSharedKeyAccess: allowSharedKeyAccess
    defaultToOAuthAuthentication: defaultToOAuthAuthentication
    dnsEndpointType: dnsEndpointType
    minimumTlsVersion: minimumTlsVersion
    networkAcls: {
      bypass: 'AzureServices'
      virtualNetworkRules: virtualNetworkRules
      defaultAction: 'Deny'
    }
    publicNetworkAccess: empty(virtualNetworkRules) ? publicNetworkAccess : 'Enabled'
  }

  resource blobServices 'blobServices' = if (!empty(containers)) {
    name: 'default'
    properties: {
      deleteRetentionPolicy: deleteRetentionPolicy
    }
    resource container 'containers' = [
      for container in containers: {
        name: container.name
        properties: {
          publicAccess: container.?publicAccess ?? 'None'
        }
      }
    ]
  }

  resource fileServices 'fileServices' = if (!empty(shares)) {
    name: 'default'

    resource share 'shares' = [
      for share in shares: {
        name: share.name
      }
    ]
  }

  resource queueServices 'queueServices' = if (!empty(queues)){
    name: 'default'

    resource queue 'queues' = [
      for queue in queues: {
        name: queue.name
      }
    ]
  }
}

module connectionStringSecret '../security/vault-secret.bicep' = if(!empty(keyVaultName)) {
  name: '${storage.name}-cs-secret'
  params: {
    keyVaultName: keyVaultName
    keyVaultSecretName: '${storage.name}-cs'
    keyVaultSecretValue: 'DefaultEndpointsProtocol=https;AccountName=${storage.name};AccountKey=${storage.listkeys().keys[0].value}'
  }
}

output name string = storage.name
output primaryEndpoints object = storage.properties.primaryEndpoints
output connectionStringSecretUri string = empty(keyVaultName) ? '' : connectionStringSecret.outputs.secretUri
