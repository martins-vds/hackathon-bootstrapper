param name string
param location string = resourceGroup().location
param tags object = {}
param autoScaleEnabled bool = false
param customSubDomainName string = name
param deployments array = []

param keyVaultName string

@allowed([
  'Academic'
  'AnomalyDetector'
  'BingAutosuggest'
  'Bing.Autosuggest.v7'
  'Bing.CustomSearch'
  'Bing.Search'
  'Bing.Search.v7'
  'Bing.Speech'
  'Bing.SpellCheck'
  'Bing.SpellCheck.v7'
  'CognitiveServices'
  'ComputerVision'
  'ContentModerator'
  'ContentSafety'
  'CustomSpeech'
  'CustomVision.Prediction'
  'CustomVision.Training'
  'Emotion'
  'Face'
  'FormRecognizer'
  'ImmersiveReader'
  'LUIS'
  'LUIS.Authoring'
  'MetricsAdvisor'
  'OpenAI'
  'Personalizer'
  'QnAMaker'
  'Recommendations'
  'SpeakerRecognition'
  'Speech'
  'SpeechServices'
  'SpeechTranslation'
  'TextAnalytics'
  'TextTranslation'
  'WebLM'
])
param kind string = 'OpenAI'

@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = 'Enabled'
param sku object = {
  name: 'S0'
}

resource account 'Microsoft.CognitiveServices/accounts@2024-04-01-preview' = {
  name: name
  location: location
  tags: tags
  kind: kind
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    customSubDomainName: customSubDomainName
    publicNetworkAccess: publicNetworkAccess
    networkAcls: {
      defaultAction: publicNetworkAccess == 'Enabled' ? 'Allow' : 'Deny'
    }
    restrictOutboundNetworkAccess: false
    dynamicThrottlingEnabled: kind == 'OpenAI' ? false : autoScaleEnabled
  }
  sku: sku
}

@batchSize(1)
resource deployment 'Microsoft.CognitiveServices/accounts/deployments@2024-04-01-preview' = [
  for deployment in deployments: {
    parent: account
    name: deployment.name
    properties: {
      model: deployment.model
      raiPolicyName: deployment.?raiPolicyName ?? null
    }
    sku: {
      name: deployment.?skuName ?? 'Standard'
      capacity: deployment.capacity
    }
  }
]

module accountKey '../security/vault-secret.bicep' = {
  name: 'accountKeySecret-${account.name}'
  params: {
    keyVaultName: keyVaultName
    keyVaultSecretName: '${account.name}-key'
    keyVaultSecretValue: account.listKeys().key1
  }
}

output endpoint string = account.properties.endpoint
output id string = account.id
output name string = account.name
output skuName string = account.sku.name
output adminKeySecretUri string = accountKey.outputs.secretUri
output identityPrincipalId string = account.identity.principalId
output resourceGroup string = resourceGroup().name
