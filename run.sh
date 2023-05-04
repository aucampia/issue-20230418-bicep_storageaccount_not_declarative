#!/usr/bin/env bash

set -x -eo pipefail

: "${PROJECT_KEY:="axdzls"}" # chosen from `pwgen -0As 6`
: "${AZURE_LOCATION:="westeurope"}"
: "${AZUREAD_USER_PRINCIPAL:="$(az ad signed-in-user show --output tsv --query userPrincipalName)"}"
: "${AZURE_RESOURCE_GROUP:="rg-tmp-${PROJECT_KEY}-000"}"

AZUREAD_USER_PRINCIPAL_ID="$(az ad user show --id "${AZUREAD_USER_PRINCIPAL}" --output tsv --query 'id')"
AZURE_SUBSCRIPTION_ID="$(az account show --output tsv --query id)"

AZURE_STORAGE_ACCOUNT_ID="/subscriptions/${AZURE_SUBSCRIPTION_ID}/resourceGroups/${AZURE_RESOURCE_GROUP}/providers/Microsoft.Storage/storageAccounts/sttmp${PROJECT_KEY}"

1>&2 declare -p PROJECT_KEY AZURE_LOCATION AZURE_RESOURCE_GROUP AZURE_SUBSCRIPTION_ID AZURE_STORAGE_ACCOUNT_ID AZUREAD_USER_PRINCIPAL AZUREAD_USER_PRINCIPAL_ID

if ! "$(az group exists --name "${AZURE_RESOURCE_GROUP}")"
then
    # Create the resource group if it does not exist
    az group create --location "${AZURE_LOCATION}" --name "${AZURE_RESOURCE_GROUP}"
fi

BICEP_PARAMETERS=( "--parameters" "userPrincipalId=${AZUREAD_USER_PRINCIPAL_ID}" "projectKey=${PROJECT_KEY}" )

az bicep version

read -p "Press enter to continue"

# Deploy without networkAcls (000)
az deployment group create --template-file without_acl.bicep "${BICEP_PARAMETERS[@]}" --resource-group "${AZURE_RESOURCE_GROUP}" --mode Complete --name "${AZURE_RESOURCE_GROUP}"
az group export --name "${AZURE_RESOURCE_GROUP}" --resource-ids "${AZURE_STORAGE_ACCOUNT_ID}" | tee storage_account-step1.json

read -p "Press enter to continue"


# Deploy with networkAcls (001)
az deployment group create --template-file with_acl.bicep "${BICEP_PARAMETERS[@]}" --resource-group "${AZURE_RESOURCE_GROUP}" --mode Complete --name "${AZURE_RESOURCE_GROUP}"
az group export --name "${AZURE_RESOURCE_GROUP}" --resource-ids "${AZURE_STORAGE_ACCOUNT_ID}" | tee storage_account-step2.json

read -p "Press enter to continue"

# Deploy without networkAcls (002)
az deployment group create --template-file without_acl.bicep "${BICEP_PARAMETERS[@]}" --resource-group "${AZURE_RESOURCE_GROUP}" --mode Complete --name "${AZURE_RESOURCE_GROUP}"
az group export --name "${AZURE_RESOURCE_GROUP}" --resource-ids "${AZURE_STORAGE_ACCOUNT_ID}" | tee storage_account-step3.json
