param workspaceName string
param location string = resourceGroup().location
param keyVaultId string
param applicationInsightsId string
param teamObjectIds array = []
param tags object = {}

resource workspace 'Microsoft.MachineLearningServices/workspaces@2024-04-01' = {
  name: workspaceName
  location: location
  tags: tags
  properties: {
    friendlyName: workspaceName
    keyVault: keyVaultId
    applicationInsights: applicationInsightsId
  }

  resource compute 'computes' = [
    for (principalId, index) in teamObjectIds: {
      name: 'compute-team-${index}'
      properties: {
        computeType: 'ComputeInstance'
        computeLocation: location
        properties: {
          vmSize: 'Standard_DS3_v2'
          personalComputeInstanceSettings: {
            assignedUser: {
              objectId: principalId
              tenantId: subscription().tenantId
            }
          }
        }
      }
    }
  ]
}
