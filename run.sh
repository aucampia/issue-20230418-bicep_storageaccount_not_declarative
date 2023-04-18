#!/usr/bin/env bash

set -x -eo pipefail

: "${PROJECT_KEY:="fiemiu"}"
: "${AZURE_LOCATION:="westeurope"}"
: "${AZUREAD_USER_PRINCIPAL:="iwan.aucamp@iwanaucampoutlook.onmicrosoft.com"}"
: "${AZURE_RESOURCE_GROUP:="rg-${PROJECT_KEY}-000"}"

AZUREAD_USER_PRINCIPAL_ID="$(az ad user show --id "${AZUREAD_USER_PRINCIPAL}" --output tsv --query 'id')"
AZURE_SUBSCRIPTION_ID="$(az account show --output tsv --query id)"
# export PROJECT_KEY AZURE_LOCATION AZUREAD_USER_PRINCIPAL

AZURE_STORAGE_ACCOUNT_ID="/subscriptions/${AZURE_SUBSCRIPTION_ID}/resourceGroups/${AZURE_RESOURCE_GROUP}/providers/Microsoft.Storage/storageAccounts/st${PROJECT_KEY}"


# Delete the resource group if it exists
az group delete --name "${AZURE_RESOURCE_GROUP}" --yes || :

# Create the resource group
az group create --location "${AZURE_LOCATION}" --name "${AZURE_RESOURCE_GROUP}"

BICEP_PARAMETERS=( "--parameters" "userPrincipalId=${AZUREAD_USER_PRINCIPAL_ID}" "projectKey=${PROJECT_KEY}" )

# Deploy without networkAcls (000)
az deployment group create --template-file without_acl.bicep "${BICEP_PARAMETERS[@]}" --resource-group "${AZURE_RESOURCE_GROUP}" --mode Complete --name "${AZURE_RESOURCE_GROUP}"
az group export --name "${AZURE_RESOURCE_GROUP}" --resource-ids "${AZURE_STORAGE_ACCOUNT_ID}" | tee storage_account-step1.json

# Deploy with networkAcls (001)
az deployment group create --template-file with_acl.bicep "${BICEP_PARAMETERS[@]}" --resource-group "${AZURE_RESOURCE_GROUP}" --mode Complete --name "${AZURE_RESOURCE_GROUP}"
az group export --name "${AZURE_RESOURCE_GROUP}" --resource-ids "${AZURE_STORAGE_ACCOUNT_ID}" | tee storage_account-step2.json

# Deploy without networkAcls (002)
az deployment group create --template-file without_acl.bicep "${BICEP_PARAMETERS[@]}" --resource-group "${AZURE_RESOURCE_GROUP}" --mode Complete --name "${AZURE_RESOURCE_GROUP}"
az group export --name "${AZURE_RESOURCE_GROUP}" --resource-ids "${AZURE_STORAGE_ACCOUNT_ID}" | tee storage_account-step3.json
