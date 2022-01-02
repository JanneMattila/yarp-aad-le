#!/bin/bash

# Variables
aciName="yarp-aad-le"
identityName="yarp-aad-le-identity"
keyvaultName="yarp-aad-le"
resourceGroup="rg-yarp-aad-le"
location="westeurope"
image="jannemattila/yarp-aad-le"

dnsNameLabel="my-yarp-aad-le-demo"
fqdn=$(echo "https://$dnsNameLabel.$location.azurecontainer.io")
azureADAppName="my-yarp-aad-le-demo"

# Login to Azure
az login -o none

# *Explicitly* select your working context
az account set --subscription <YourSubscriptionName>

# Get current account context
accountJson=$(az account show -o json)

# Create new resource group
az group create --name $resourceGroup --location $location

# Create managed identity
# - Used for accessing Key vault for storing certificate from Let's Encrypt
# - Used for accessing application configuration values
identityJson=$(az identity create --name $identityName --resource-group $resourceGroup -o json)
identityid=$(echo $identityJson | jq -r .id)
identityobjectid=$(echo $identityJson | jq -r .principalId)
echo $identityid
echo $identityobjectid

# Create Key vault
keyvaultJson=$(az keyvault create \
  --name $keyvaultName \
  --resource-group $resourceGroup \
  --enable-rbac-authorization true \
  --location $location -o json)
keyvaultid=$(echo $keyvaultJson | jq -r .id)
keyvault=$(echo $keyvaultJson | jq -r .properties.vaultUri)
echo $keyvaultid
echo $keyvault

# Grant "Key Vault Certificates Officer" and 
#       "Key Vault Secrets User" for our managed identity
# https://docs.microsoft.com/en-us/azure/key-vault/general/rbac-guide
az role assignment create \
  --role "Key Vault Certificates Officer" \
  --assignee-object-id $identityobjectid \
  --assignee-principal-type ServicePrincipal \
  --scope $keyvaultid
az role assignment create \
  --role "Key Vault Secrets User" \
  --assignee-object-id $identityobjectid \
  --assignee-principal-type ServicePrincipal \
  --scope $keyvaultid

# Grant permissions for current user to be able manage
# all Key Vault content
me=$(echo $accountJson | jq -r .user.name)
echo $me
az role assignment create \
  --role "Key Vault Administrator" \
  --assignee $me \
  --scope $keyvaultid

# Create Azure AD App registration
cat <<EOF > required-resource-accesses.json
{
  "resourceAppId": "00000003-0000-0000-c000-000000000000",
  "resourceAccess": [
    {
      "id": "37f7f235-527c-4136-accd-4a02d197296e",
      "type": "Scope"
    }
  ]
}
EOF
cat required-resource-accesses.json
azureADAppJson=$(az ad app create \
  --display-name $azureADAppName \
  --reply-urls "$fqdn/signin-oidc" \
  --required-resource-accesses @required-resource-accesses.json -o json)
echo $azureADAppJson

# Collect variables for our application
tenantId=$(echo $accountJson | jq -r .tenantId)
tenantName=$(az rest --method get --url https://graph.microsoft.com/v1.0/domains | jq -r '.value[] | select(.isDefault == true) | {id}[]')
clientId=$(echo $azureADAppJson | jq -r .appId)
objectId=$(echo $azureADAppJson | jq -r .objectId)

echo $tenantId
echo $tenantName
echo $clientId
echo $me
echo $fqdn
echo $keyvault

# Store application configuration values to the Key Vault
az keyvault secret set --name "AzureAd--TenantId" --value $tenantId --vault-name $keyvaultName
az keyvault secret set --name "AzureAd--Domain" --value $tenantName --vault-name $keyvaultName
az keyvault secret set --name "AzureAd--ClientId" --value $clientId --vault-name $keyvaultName
az keyvault secret set --name "LettuceEncrypt--EmailAddress" --value $me --vault-name $keyvaultName
az keyvault secret set --name "LettuceEncrypt--DomainNames--0" --value $fqdn --vault-name $keyvaultName
az keyvault secret set --name "LettuceEncrypt--AzureKeyVault--AzureKeyVaultEndpoint" --value $keyvault --vault-name $keyvaultName

# Create ACI
az container create \
  --name $aciName \
  --image $image \
  --ports 80 443 \
  --cpu 1 \
  --memory 1 \
  --resource-group $resourceGroup \
  --environment-variables "KeyVault=$keyvault" "https_port=443"
  --assign-identity $identityid \
  --dns-name-label $dnsNameLabel \
  --restart-policy Always \
  --ip-address public

# Show the properties
az container show --name $aciName --resource-group $resourceGroup

# Show the logs
az container logs --name $aciName --resource-group $resourceGroup

# Open browser to ACI address
# - Validate that it proxies as excepted
# - Validate that TLS works with proper certificate
echo $fqdn

# Wipe out the resources
az ad app delete --id $objectId
az group delete --name $resourceGroup -y
az keyvault purge --name $keyvaultName # Otherwise it will be in "Deleted vaults" but name is reserved
