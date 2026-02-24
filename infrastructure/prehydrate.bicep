targetScope = 'subscription'

@description('Project name prefix used across resources')
param projectName string = 'fncast'

@description('Deployment environment (dev, staging, prod, etc.)')
param environment string = 'develop'

@description('Azure region for the resource group and nested deployment')
param location string = 'westus2'

@description('Optional tags applied to the resource group')
param tags object = {
  project: projectName
  environment: environment
}

var resourceGroupName = 'rg-${projectName}-${environment}'

// Create or update the resource group that will host FnCast artifacts
resource fncastResourceGroup 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

// Deploy the core FnCast infrastructure into the resource group
module fncast 'main.bicep' = {
  name: 'fncast-core'
  scope: fncastResourceGroup
  params: {
    projectName: projectName
    environment: environment
    location: location
  }
}

// Surface key outputs from the nested deployment
output resourceGroupName string = fncastResourceGroup.name
output functionAppName string = fncast.outputs.functionAppName
output functionAppUrl string = fncast.outputs.functionAppUrl
output storageAccountName string = fncast.outputs.storageAccountName
output eventGridTopicName string = fncast.outputs.eventGridTopicName
output keyVaultName string = fncast.outputs.keyVaultName
