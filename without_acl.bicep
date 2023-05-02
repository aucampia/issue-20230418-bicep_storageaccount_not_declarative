targetScope = 'resourceGroup'

@sys.description('The location into which the resources should be deployed.')
param location string = resourceGroup().location

@sys.description('A unique string used for resource naming.')
param projectKey string

// https://learn.microsoft.com/en-us/azure/templates/microsoft.storage/storageaccounts?pivots=deployment-language-bicep
resource storageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: 'sttmp${projectKey}'
  location: location
  sku: {
    name: 'Standard_ZRS'
  }
  kind: 'StorageV2'

  properties: {
    allowSharedKeyAccess: false
    isHnsEnabled: true
  }

  resource blobService 'blobServices' = {
    name: 'default'
    resource caputedEvents 'containers' = {
      name: 'captured-events'
    }
  }
}
