targetScope = 'resourceGroup'

@sys.description('The location into which the resources should be deployed.')
param location string = resourceGroup().location

@sys.description('A unique string used for resource naming.')
param projectKey string

@sys.description('The user principal ID of the user running the example.')
param userPrincipalId string

// az role definition list | jq '[.[] | { (.roleName): .name }] | add' | sed -e 's/"/'"'"'/g' -e 's/,$//g' | view -
var wellKnownRoles = {
  'Storage Blob Data Contributor': 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
}

// https://learn.microsoft.com/en-us/azure/templates/microsoft.storage/storageaccounts?pivots=deployment-language-bicep
resource storageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: 'st${projectKey}'
  location: location
  sku: {
    name: 'Standard_ZRS'
  }
  kind: 'StorageV2'

  properties: {
    allowSharedKeyAccess: false
    isHnsEnabled: true

    networkAcls: {
      // https://learn.microsoft.com/en-us/azure/templates/microsoft.storage/storageaccounts?pivots=deployment-language-bicep#networkruleset
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      ipRules: [
        {
            action: 'Allow'
            value: '80.213.0.0/16'
        }
      ]
      virtualNetworkRules: []
    }
  }

  resource blobService 'blobServices' = {
    name: 'default'
    resource caputedEvents 'containers' = {
      name: 'captured-events'
    }
  }
}

resource roleAssignments001 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
    name: guid(storageAccount.id, userPrincipalId, wellKnownRoles['Storage Blob Data Contributor'])
    scope: storageAccount
    properties: {
        principalId: userPrincipalId
        roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', wellKnownRoles['Storage Blob Data Contributor'])
        principalType: 'User'
    }
}
