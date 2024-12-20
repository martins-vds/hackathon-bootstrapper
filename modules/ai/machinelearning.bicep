param workspaceName string
param workspaceStorageName string
@allowed([
  'Standard_A2_v2'
  'Standard_D2s_v3'
])
param workspaceComputeVmSize string = 'Standard_A2_v2'
param location string = resourceGroup().location
param keyVaultId string
param applicationInsightsId string
param workspaceComputeUsers array = []
param tags object = {}

module storage '../storage/storage-account.bicep' = {
  name: 'workspace-storage'
  params: {
    name: workspaceStorageName
  }
}

resource workspace 'Microsoft.MachineLearningServices/workspaces@2024-04-01-preview' = {
  name: workspaceName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  tags: tags
  properties: {
    friendlyName: workspaceName
    keyVault: keyVaultId
    applicationInsights: applicationInsightsId
    storageAccount: storage.outputs.id
  }

  resource compute 'computes' = [
    for (principalId, index) in workspaceComputeUsers: {
      name: 'hackusercompute${index}'
      location: location
      properties: {
        computeType: 'ComputeInstance'
        computeLocation: location
        description: 'Compute instance for team member ${take(principalId, 8)}...'
        properties: {
          vmSize: workspaceComputeVmSize
          personalComputeInstanceSettings: {
            assignedUser: {
              objectId: principalId
              tenantId: subscription().tenantId
            }
          }
          enableNodePublicIp: true
          idleTimeBeforeShutdown: 'PT30M'          
        }
      }
    }
  ]
}
