param eventHubNamespaceName string
param eventHubName string
param skuName string = 'Standard'
param skuCapacity int = 1
param location string = resourceGroup().location
param tags object = {}

resource eventHubNamespace 'Microsoft.EventHub/namespaces@2024-01-01' = {
  name: eventHubNamespaceName
  location: location
  tags: tags
  sku: {
    name: skuName
    capacity: skuCapacity    
  }
}

resource eventHub 'Microsoft.EventHub/namespaces/eventhubs@2024-01-01' = {
  parent: eventHubNamespace
  name: eventHubName  
}

output namespaceId string = eventHubNamespace.id
output namespaceName string = eventHubNamespaceName
output eventHubId string = eventHub.id
output eventHubName string = eventHubName
