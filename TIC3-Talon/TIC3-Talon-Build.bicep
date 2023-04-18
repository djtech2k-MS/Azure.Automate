// BEGIN Parameter Value Setup
@description('Specifies the Event Hub name and the Namespace name.')
param evtHubName string = 'My-Talon-EventHub'

@description('Specifies the Azure location for all resources.')
param location string = resourceGroup().location

@description('Specifies the messaging tier for Event Hub Namespace.  Standard is Required for TIC 3.0.')
@allowed([
  'Basic'
  'Standard'
])
param eventHubSku string = 'Standard'

@description('Specifies the Minimum TLS Version for Event Hub Namespace.')
param eventHubMinTLS string = '1.2'

@description('Specifies the Auto Inflate Option for Event Hub Namespace.')
param eventHubAutoInf bool = false

@description('Specifies the DisableLocalAuth/SAS  Option for Event Hub Namespace.')
param eventHubDisableLocAuth bool = false

@description('Specifies the Auto Inflate Max Throughput Units Option for Event Hub Namespace.')
param eventHubInfUnits int = 0

@description('Specifies the Message Retention in Days Option for Event Hub Namespace.')
param eventHubRetention int = 7

@description('Specifies the Partition Count Option for Event Hub Namespace.')
param eventHubPartitionCount int = 1

@description('Specifies the role definition ID used in the role assignment.')
param roleDefinitionID string = 'a638d3c7-ab3a-418d-83e6-5f17a39d4fde'

@description('Specifies the principal ID assigned to the role.')
param principalId string
// END Parameter Value Setup

var eventHubNamespaceName = '${evtHubName}-ns'
var eventHubName = evtHubName
var roleAssignmentName= guid(principalId, roleDefinitionID, resourceGroup().id)


resource eventHubNamespace 'Microsoft.EventHub/namespaces@2022-01-01-preview' = {
  name: eventHubNamespaceName
  location: location
  sku: {
    name: eventHubSku
    tier: eventHubSku
    capacity: 1
  }
  properties: {
    isAutoInflateEnabled: eventHubAutoInf
    maximumThroughputUnits: eventHubInfUnits
    minimumTlsVersion: eventHubMinTLS
    disableLocalAuth: eventHubDisableLocAuth
  }
}

resource eventHub 'Microsoft.EventHub/namespaces/eventhubs@2022-01-01-preview' = {
  parent: eventHubNamespace
  name: eventHubName
  properties: {
    messageRetentionInDays: eventHubRetention
    partitionCount: eventHubPartitionCount
  }
}



resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: roleAssignmentName
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionID)
    principalId: principalId
  }
}
