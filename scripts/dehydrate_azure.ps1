#!/usr/bin/env pwsh
<#
.SYNOPSISaz 
    Stop/Dehydrate Azure FnCast resources to save costs
.DESCRIPTION
    This script stops the Azure Function App and optionally deallocates other resources
    to minimize Azure costs when not in use.
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName = "rg-fncast",
    
    [Parameter(Mandatory=$false)]
    [string]$FunctionAppName = "fncast-4654",
    
    [Parameter(Mandatory=$false)]
    [string]$AppInsightsName = "ai-fncast",
    
    [Parameter(Mandatory=$false)]
    [switch]$DeleteAppInsights,
    
    [Parameter(Mandatory=$false)]
    [switch]$KeepAppInsights
)

Write-Host "======================================" -ForegroundColor Yellow
Write-Host "Stopping Azure FnCast Resources" -ForegroundColor Yellow
Write-Host "======================================`n" -ForegroundColor Yellow

# Check Azure login
Write-Host "Checking Azure login..." -ForegroundColor Cyan
$account = az account show 2>$null | ConvertFrom-Json
if (-not $account) {
    Write-Host "Not logged in. Please log in to Azure..." -ForegroundColor Red
    az login
    $account = az account show | ConvertFrom-Json
}

Write-Host "✓ Using subscription: $($account.name)`n" -ForegroundColor Green

# Load azure-config.json if present to override defaults
$cfgPath = "azure-config.json"
if (Test-Path $cfgPath) {
    Write-Host "Loading configuration from azure-config.json..." -ForegroundColor Cyan
    try {
        $cfg = Get-Content $cfgPath | ConvertFrom-Json
        if ($cfg.resourceGroup) { $ResourceGroupName = $cfg.resourceGroup }
        if ($cfg.functionAppName) { $FunctionAppName = $cfg.functionAppName }
        if ($cfg.appInsightsName) { $AppInsightsName = $cfg.appInsightsName }
        $DefaultLocation = $cfg.location
        Write-Host "✓ Config loaded: RG=$ResourceGroupName, FA=$FunctionAppName, AI=$AppInsightsName" -ForegroundColor Green
    } catch {
        Write-Host "⚠ Failed to parse azure-config.json; using defaults" -ForegroundColor Yellow
    }
}

# Stop Function App
Write-Host "Stopping Function App '$FunctionAppName'..." -ForegroundColor Cyan
try {
    az functionapp stop --name $FunctionAppName --resource-group $ResourceGroupName
    Write-Host "✓ Function App stopped successfully" -ForegroundColor Green
} catch {
    Write-Host "✗ Failed to stop Function App: $_" -ForegroundColor Red
}

# Aggressively dehydrate telemetry by clearing Function App telemetry settings
Write-Host "`nChecking Function App telemetry settings..." -ForegroundColor Cyan
try {
    $appSettings = az functionapp config appsettings list --name $FunctionAppName --resource-group $ResourceGroupName | ConvertFrom-Json
    $aiKeySetting = $appSettings | Where-Object { $_.name -eq "APPINSIGHTS_INSTRUMENTATIONKEY" }
    $aiConnSetting = $appSettings | Where-Object { $_.name -eq "APPLICATIONINSIGHTS_CONNECTION_STRING" }

    $hadInstrumentationKey = ($aiKeySetting -and $aiKeySetting.value -and $aiKeySetting.value -ne "")
    $hadConnectionString = ($aiConnSetting -and $aiConnSetting.value -and $aiConnSetting.value -ne "")

    $settingsToClear = @()
    if ($hadInstrumentationKey) { $settingsToClear += "APPINSIGHTS_INSTRUMENTATIONKEY=" }
    if ($hadConnectionString) { $settingsToClear += "APPLICATIONINSIGHTS_CONNECTION_STRING=" }

    if ($settingsToClear.Count -gt 0) {
        Write-Host "Clearing telemetry settings on Function App..." -ForegroundColor Cyan
        az functionapp config appsettings set --name $FunctionAppName --resource-group $ResourceGroupName --settings $settingsToClear
        Write-Host "✓ Telemetry disabled at app level" -ForegroundColor Green
    } else {
        Write-Host "No telemetry settings found to clear" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠ Failed to inspect/clear telemetry settings: $_" -ForegroundColor Yellow
}

# Disable App Insights public ingestion/query access (aggressive dehydration)
if (-not $KeepAppInsights -and $AppInsightsName) {
    Write-Host "`nDisabling Application Insights public ingestion/query access..." -ForegroundColor Cyan
    try {
        # Record current status
        $aiBefore = az monitor app-insights component show --app $AppInsightsName --resource-group $ResourceGroupName | ConvertFrom-Json
        $ingBefore = $aiBefore.ingestionPublicNetworkAccess
        $qryBefore = $aiBefore.queryPublicNetworkAccess
        
        az monitor app-insights component update --app $AppInsightsName --resource-group $ResourceGroupName --ingestion-access Disabled --query-access Disabled | Out-Null
        Write-Host "✓ Application Insights public access disabled" -ForegroundColor Green
        $aiAccess = @{ before = @{ ingestion = $ingBefore; query = $qryBefore }; after = @{ ingestion = 'Disabled'; query = 'Disabled' } }
    } catch {
        Write-Host "⚠ Failed to disable App Insights access: $_" -ForegroundColor Yellow
        $aiAccess = @{ error = $_.ToString() }
    }
}

# Optionally delete App Insights entirely for maximal savings
if ($DeleteAppInsights -and $AppInsightsName) {
    Write-Host "`nDeleting Application Insights '$AppInsightsName' for maximal cost savings..." -ForegroundColor Cyan
    try {
        # Capture properties for potential recreation
        $aiProps = az monitor app-insights component show --app $AppInsightsName --resource-group $ResourceGroupName | ConvertFrom-Json
        $aiSnapshot = @{
            name = $AppInsightsName
            location = $aiProps.location
            applicationType = ($aiProps.applicationType ?? 'web')
            workspaceResourceId = $aiProps.workspaceResourceId
        }
        az monitor app-insights component delete --app $AppInsightsName --resource-group $ResourceGroupName
        Write-Host "✓ Application Insights deleted" -ForegroundColor Green
        $aiDeleted = $true
    } catch {
        Write-Host "✗ Failed to delete Application Insights: $_" -ForegroundColor Red
        # If component already deleted, keep a default snapshot from config for idempotent recreate
        if (-not $aiSnapshot) {
            $aiSnapshot = @{
                name = $AppInsightsName
                location = ($DefaultLocation ? $DefaultLocation : 'eastus')
                applicationType = 'web'
                workspaceResourceId = $null
            }
        }
        $aiDeleted = $true
    }
}

# Display cost-saving summary
Write-Host "`n======================================" -ForegroundColor Green
Write-Host "Resources Stopped Successfully!" -ForegroundColor Green
Write-Host "======================================`n" -ForegroundColor Green

Write-Host "Cost Savings:" -ForegroundColor Cyan
Write-Host "✓ Function App (Consumption Plan): Stopped - No execution charges" -ForegroundColor Green
Write-Host "✓ Storage Account: Still active (minimal cost ~$0.02/GB/month)" -ForegroundColor Yellow
Write-Host "✓ Application Insights: Still active (retention charges apply)" -ForegroundColor Yellow

Write-Host "`nNote: Consumption Plan only charges for executions." -ForegroundColor White
Write-Host "Stopping the app prevents new executions, saving execution costs." -ForegroundColor White

Write-Host "`nTo restart resources, run: .\scripts\rehydrate_azure.ps1`n" -ForegroundColor Cyan

# Save state for restart
$state = @{
    resourceGroup = $ResourceGroupName
    functionAppName = $FunctionAppName
    appInsightsName = $AppInsightsName
    cleared = @{ instrumentationKey = $hadInstrumentationKey; connectionString = $hadConnectionString }
    aiAccess = $aiAccess
    aiDeleted = $aiDeleted
    aiSnapshot = $aiSnapshot
    stoppedAt = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
}

$state | ConvertTo-Json | Out-File "azure-stopped-state.json"
Write-Host "✓ State saved to azure-stopped-state.json" -ForegroundColor Green
