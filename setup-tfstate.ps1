# Bootstrap Terraform remote-state storage and configure azd environment.
# PowerShell equivalent of setup-tfstate.sh

$ErrorActionPreference = "Stop"

$SUBSCRIPTION_ID = (az account show --query id -o tsv)
$SUB_CLEAN = ($SUBSCRIPTION_ID -replace '-','').Substring(0,12)

$TFSTATE_RG = "rg-tfstate"
$TFSTATE_SA = "sttf$SUB_CLEAN"
$TFSTATE_CONTAINER = "tfstate"
$LOCATION = if ($env:AZURE_LOCATION) { $env:AZURE_LOCATION } else { "eastus2" }

Write-Output "==> Terraform state backend"
Write-Output "    Resource group:  $TFSTATE_RG"
Write-Output "    Storage account: $TFSTATE_SA"
Write-Output "    Container:       $TFSTATE_CONTAINER"
Write-Output "    Location:        $LOCATION"

# Create resources (idempotent)
az group create --name $TFSTATE_RG --location $LOCATION --output none

az storage account create `
  --name $TFSTATE_SA `
  --resource-group $TFSTATE_RG `
  --location $LOCATION `
  --sku Standard_LRS `
  --allow-blob-public-access false `
  --public-network-access Enabled `
  --output none 2>$null

az storage container create `
  --name $TFSTATE_CONTAINER `
  --account-name $TFSTATE_SA `
  --auth-mode login `
  --output none 2>$null

# Store values in azd environment
azd env set RS_STORAGE_ACCOUNT $TFSTATE_SA 2>$null
azd env set RS_CONTAINER_NAME $TFSTATE_CONTAINER 2>$null
azd env set RS_RESOURCE_GROUP $TFSTATE_RG 2>$null

# Assign Storage Blob Data Contributor for Azure AD backend auth
$STORAGE_ACCOUNT_ID = (az storage account show `
  --name $TFSTATE_SA `
  --resource-group $TFSTATE_RG `
  --query id -o tsv)

# Only assign role when running locally
if (-not $env:ARM_CLIENT_ID) {
  $PRINCIPAL_ID = az ad signed-in-user show --query id -o tsv 2>$null
  if ($PRINCIPAL_ID) {
    Write-Output "    Assigning Storage Blob Data Contributor to user $PRINCIPAL_ID..."
    az role assignment create `
      --assignee-object-id $PRINCIPAL_ID `
      --assignee-principal-type User `
      --role "Storage Blob Data Contributor" `
      --scope $STORAGE_ACCOUNT_ID `
      --output none 2>$null
    Write-Output "    Waiting 30s for role assignment propagation..."
    Start-Sleep -Seconds 30
  }
}

# Set OIDC flag: CI uses OIDC tokens, local uses Azure CLI
if ($env:CI) {
  azd env set USE_OIDC true 2>$null
} else {
  azd env set USE_OIDC false 2>$null
}

Write-Output "==> Environment configured. You can now run: azd up"
