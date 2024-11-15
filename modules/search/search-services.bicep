param name string
param location string = resourceGroup().location
param tags object = {}
param ipRules IpRule[] = []
param replicas int = 1

param sku object = {
  name: 'standard'
}

param authOptions object = {}

@allowed([
  'free'
  'standard'
  'disabled'
])
param semanticSearch string = 'free'

param keyVaultName string

@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = 'Enabled'

type IpRule = {
  value: string
}

resource search 'Microsoft.Search/searchServices@2024-06-01-preview' = {
  name: name
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    authOptions: authOptions
    disableLocalAuth: false
    disabledDataExfiltrationOptions: []
    encryptionWithCmk: {
      enforcement: 'Unspecified'
    }
    hostingMode: 'default'
    networkRuleSet: {
      bypass: 'AzureServices'
      ipRules: ipRules
    }
    partitionCount: 1
    publicNetworkAccess: publicNetworkAccess
    replicaCount: replicas
    semanticSearch: semanticSearch
  }
  sku: sku
}

module adminKeySecret '../security/vault-secret.bicep' = {
  name: 'accountKeySecret-${search.name}'
  params: {
    keyVaultName: keyVaultName
    keyVaultSecretName: '${search.name}-key'
    keyVaultSecretValue: search.listAdminKeys().primaryKey
  }
}

output id string = search.id
output endpoint string = 'https://${name}.search.windows.net/'
output name string = search.name
output skuName string = sku.name
output adminKeySecretUri string = adminKeySecret.outputs.secretUri
output identityPrincipalId string = search.identity.principalId
