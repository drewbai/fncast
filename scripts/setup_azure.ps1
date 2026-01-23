#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Sets up Azure resources for the FnCast Function App
.DESCRIPTION
    This script creates:
    - Resource Group
    - Storage Account
    - Application Insights
    - Function App
    - Service Principal for CI/CD
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName = "rg-fncast",
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "eastus",
    
    [Parameter(Mandatory=$false)]
    [string]$FunctionAppName = "fncast-$(Get-Random -Minimum 1000 -Maximum 9999)",
    
    [Parameter(Mandatory=$false)]
    [string]$StorageAccountName = "stfncast$(Get-Random -Minimum 1000 -Maximum 9999)",
    
    [Parameter(Mandatory=$false)]
    [string]$AppInsightsName = "ai-fncast"
)

# Login to Azure (if not already logged in)
Write-Host "Checking Azure login status..." -ForegroundColor Cyan
$account = az account show 2>$null | ConvertFrom-Json
if (-not $account) {
    Write-Host "Not logged in. Please log in to Azure..." -ForegroundColor Yellow
    az login
    $account = az account show | ConvertFrom-Json
}

Write-Host "Using subscription: $($account.name) ($($account.id))" -ForegroundColor Green

# Create Resource Group
Write-Host "`nCreating resource group '$ResourceGroupName' in '$Location'..." -ForegroundColor Cyan
az group create --name $ResourceGroupName --location $Location

# Create Storage Account
Write-Host "`nCreating storage account '$StorageAccountName'..." -ForegroundColor Cyan
az storage account create `
    --name $StorageAccountName `
    --resource-group $ResourceGroupName `
    --location $Location `
    --sku Standard_LRS `
    --kind StorageV2

# Create Application Insights
Write-Host "`nCreating Application Insights '$AppInsightsName'..." -ForegroundColor Cyan
az monitor app-insights component create `
    --app $AppInsightsName `
    --location $Location `
    --resource-group $ResourceGroupName `
    --application-type web

# Get Application Insights Instrumentation Key
$instrumentationKey = (az monitor app-insights component show `
    --app $AppInsightsName `
    --resource-group $ResourceGroupName `
    --query instrumentationKey -o tsv)

# Create Function App
Write-Host "`nCreating Function App '$FunctionAppName'..." -ForegroundColor Cyan
az functionapp create `
    --name $FunctionAppName `
    --resource-group $ResourceGroupName `
    --storage-account $StorageAccountName `
    --consumption-plan-location $Location `
    --runtime python `
    --runtime-version 3.12 `
    --functions-version 4 `
    --os-type Linux `
    --app-insights $AppInsightsName

# Create Service Principal for GitHub Actions
Write-Host "`nCreating service principal for CI/CD..." -ForegroundColor Cyan
$subscriptionId = $account.id
$spName = "sp-fncast-github"

$sp = az ad sp create-for-rbac `
    --name $spName `
    --role Contributor `
    --scopes "/subscriptions/$subscriptionId/resourceGroups/$ResourceGroupName" `
    --sdk-auth | ConvertFrom-Json

# Output configuration
Write-Host "`n========================================" -ForegroundColor Green
Write-Host "Azure Resources Created Successfully!" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green

Write-Host "Resource Group: " -NoNewline -ForegroundColor Cyan
Write-Host $ResourceGroupName

Write-Host "Function App Name: " -NoNewline -ForegroundColor Cyan
Write-Host $FunctionAppName

Write-Host "Function App URL: " -NoNewline -ForegroundColor Cyan
Write-Host "https://$FunctionAppName.azurewebsites.net"

Write-Host "`n========================================" -ForegroundColor Yellow
Write-Host "GitHub Secrets Configuration" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Yellow

Write-Host "Add these secrets to your GitHub repository:" -ForegroundColor Yellow
Write-Host "(Settings > Secrets and variables > Actions > New repository secret)`n"

Write-Host "1. AZURE_FUNCTION_APP_NAME" -ForegroundColor Cyan
Write-Host "   Value: $FunctionAppName`n"

Write-Host "2. AZURE_CREDENTIALS" -ForegroundColor Cyan
Write-Host "   Value (copy the entire JSON below):"
Write-Host ($sp | ConvertTo-Json -Depth 10)

Write-Host "`n3. AZURE_FUNCTIONAPP_PUBLISH_PROFILE" -ForegroundColor Cyan
Write-Host "   Getting publish profile..."
$publishProfile = az functionapp deployment list-publishing-profiles `
    --name $FunctionAppName `
    --resource-group $ResourceGroupName `
    --xml

Write-Host "   Value (copy the entire XML below):"
Write-Host $publishProfile

# Save configuration to file
$config = @{
    resourceGroup = $ResourceGroupName
    functionAppName = $FunctionAppName
    storageAccountName = $StorageAccountName
    appInsightsName = $AppInsightsName
    location = $Location
    subscriptionId = $subscriptionId
}

$config | ConvertTo-Json | Out-File "azure-config.json"
Write-Host "`n✓ Configuration saved to azure-config.json" -ForegroundColor Green

# Save secrets for easy reference
$secrets = @{
    AZURE_FUNCTION_APP_NAME = $FunctionAppName
    AZURE_CREDENTIALS = $sp
}

$secrets | ConvertTo-Json -Depth 10 | Out-File "github-secrets.json"
Write-Host "✓ GitHub secrets saved to github-secrets.json (DO NOT commit this file!)" -ForegroundColor Green

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "Next Steps:" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "1. Add the secrets above to your GitHub repository"
Write-Host "2. Push your code to GitHub"
Write-Host "3. The GitHub Actions workflow will automatically deploy your function"
Write-Host "4. Test your function at: https://$FunctionAppName.azurewebsites.net/api/health`n"
