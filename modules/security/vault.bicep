@description('Specifies the name of the key vault.')
param keyVaultName string = 'kv${uniqueString(resourceGroup().id)}'

@description('Specifies the SKU to use for the key vault.')
param keyVaultSku object = {
  name: 'standard'
  family: 'A'
}

@description('Specifies the Azure location where the resources should be created.')
param location string = resourceGroup().location

@allowed([
  'Disabled'
  'Enabled'
])
param publicNetworkAccess string = 'Enabled'

param accessPolicies keyVaultAccessPolicy[] = []

param tags object = {}

type keyVaultAccessPolicy = {
  objectId: string
  permissions: {
    keys: string[]
    secrets: string[]
    certificates: string[]
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  tags: tags
  properties: {
    enableRbacAuthorization: true
    tenantId: tenant().tenantId
    sku: keyVaultSku
    publicNetworkAccess: publicNetworkAccess
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: publicNetworkAccess == 'Enabled' ? 'Allow' : 'Deny'
    }
    accessPolicies: [
      for policy in accessPolicies: {
        tenantId: tenant().tenantId
        objectId: policy.objectId
        permissions: policy.permissions
      }
    ]
  }
}

output id string = keyVault.id
output keyVaultName string = keyVault.name
