#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Restart/Rehydrate Azure FnCast resources
.DESCRIPTION
    This script restarts the Azure Function App and other resources
    that were stopped by the dehydrate script.
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName = "rg-fncast",
    
    [Parameter(Mandatory=$false)]
    [string]$FunctionAppName = "fncast-4654",
    
    [Parameter(Mandatory=$false)]
    [string]$AppInsightsName = "ai-fncast"
)

Write-Host "======================================" -ForegroundColor Yellow
Write-Host "Starting Azure FnCast Resources" -ForegroundColor Yellow
Write-Host "======================================`n" -ForegroundColor Yellow

# Load azure-config.json if present
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

# Check for saved state
if (Test-Path "azure-stopped-state.json") {
    Write-Host "Loading saved state..." -ForegroundColor Cyan
    $state = Get-Content "azure-stopped-state.json" | ConvertFrom-Json
    if ($state.resourceGroup) { $ResourceGroupName = $state.resourceGroup }
    if ($state.functionAppName) { $FunctionAppName = $state.functionAppName }
    if ($state.appInsightsName) { $AppInsightsName = $state.appInsightsName }
    $aiDeleted = $state.aiDeleted
    $aiSnapshot = $state.aiSnapshot
    $aiAccessState = $state.aiAccess
    Write-Host "✓ State loaded from azure-stopped-state.json" -ForegroundColor Green
    Write-Host "  Stopped at: $($state.stoppedAt)`n" -ForegroundColor Gray
}

# Check Azure login
Write-Host "Checking Azure login..." -ForegroundColor Cyan
$account = az account show 2>$null | ConvertFrom-Json
if (-not $account) {
    Write-Host "Not logged in. Please log in to Azure..." -ForegroundColor Red
    az login
    $account = az account show | ConvertFrom-Json
}

Write-Host "✓ Using subscription: $($account.name)`n" -ForegroundColor Green

# Ensure App Insights exists (recreate if deleted) and re-enable ingestion/query
if ($AppInsightsName) {
    Write-Host "Restoring Application Insights component..." -ForegroundColor Cyan
    $aiExists = $false
    try {
        $ai = az monitor app-insights component show --app $AppInsightsName --resource-group $ResourceGroupName | ConvertFrom-Json
        if ($ai) { $aiExists = $true }
    } catch { $aiExists = $false }

    if (-not $aiExists) {
        Write-Host "App Insights not found; recreating '$AppInsightsName'..." -ForegroundColor Cyan
        try {
            $location = if ($aiSnapshot -and $aiSnapshot.location) { $aiSnapshot.location } elseif ($DefaultLocation) { $DefaultLocation } else { 'eastus' }
            $applicationType = if ($aiSnapshot -and $aiSnapshot.applicationType) { $aiSnapshot.applicationType } else { 'web' }
            $workspaceId = if ($aiSnapshot) { $aiSnapshot.workspaceResourceId } else { $null }
            $createCmd = @("az","monitor","app-insights","component","create","--app",$AppInsightsName,"--location",$location,"--resource-group",$ResourceGroupName,"--application-type",$applicationType,"--kind","web")
            if ($workspaceId) { $createCmd += @("--workspace", $workspaceId) }
            & $createCmd | Out-Null
            Write-Host "✓ Application Insights recreated" -ForegroundColor Green
            # Refresh
            $ai = az monitor app-insights component show --app $AppInsightsName --resource-group $ResourceGroupName | ConvertFrom-Json
        } catch {
            Write-Host "✗ Failed to recreate App Insights: $_" -ForegroundColor Red
        }
    }

    # Re-enable public access if previously disabled
    try {
        az monitor app-insights component update --app $AppInsightsName --resource-group $ResourceGroupName --ingestion-access Enabled --query-access Enabled | Out-Null
        Write-Host "✓ Application Insights public access re-enabled" -ForegroundColor Green
    } catch {
        Write-Host "⚠ Failed to re-enable public access: $_" -ForegroundColor Yellow
    }

    # Restore telemetry settings on Function App
    Write-Host "Restoring telemetry settings from App Insights..." -ForegroundColor Cyan
    try {
        $connString = $ai.connectionString
        $ikey = $ai.instrumentationKey
        $settingsToSet = @()
        if ($connString) { $settingsToSet += "APPLICATIONINSIGHTS_CONNECTION_STRING=$connString" }
        if ($ikey) { $settingsToSet += "APPINSIGHTS_INSTRUMENTATIONKEY=$ikey" }
        if ($settingsToSet.Count -gt 0) {
            az functionapp config appsettings set --name $FunctionAppName --resource-group $ResourceGroupName --settings $settingsToSet | Out-Null
            Write-Host "✓ Telemetry settings restored on Function App" -ForegroundColor Green
        } else {
            Write-Host "⚠ App Insights returned no connection info; skipping restore" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "⚠ Failed to query/restore App Insights telemetry: $_" -ForegroundColor Yellow
    }
} else {
    Write-Host "No App Insights name provided; skipping telemetry restore" -ForegroundColor Yellow
}

# Start Function App
Write-Host "Starting Function App '$FunctionAppName'..." -ForegroundColor Cyan
try {
    az functionapp start --name $FunctionAppName --resource-group $ResourceGroupName
    Write-Host "✓ Function App started successfully" -ForegroundColor Green
} catch {
    Write-Host "✗ Failed to start Function App: $_" -ForegroundColor Red
}

# Wait a moment for the app to initialize
Write-Host "`nWaiting for Function App to initialize..." -ForegroundColor Cyan
Start-Sleep -Seconds 5

# Get Function App URL
$functionApp = az functionapp show --name $FunctionAppName --resource-group $ResourceGroupName | ConvertFrom-Json
$appUrl = "https://$($functionApp.defaultHostName)"

# Display summary
Write-Host "`n======================================" -ForegroundColor Green
Write-Host "Resources Started Successfully!" -ForegroundColor Green
Write-Host "======================================`n" -ForegroundColor Green

Write-Host "Function App Status:" -ForegroundColor Cyan
Write-Host "✓ State: Running" -ForegroundColor Green
Write-Host "✓ URL: $appUrl" -ForegroundColor Green
Write-Host "✓ Health Check: $appUrl/api/health" -ForegroundColor Green

Write-Host "`nTesting health endpoint..." -ForegroundColor Cyan
try {
    $response = Invoke-RestMethod -Uri "$appUrl/api/health" -Method Get -TimeoutSec 10
    Write-Host "✓ Health check passed!" -ForegroundColor Green
    Write-Host "  Response: $($response | ConvertTo-Json -Compress)" -ForegroundColor Gray
} catch {
    Write-Host "⚠ Health check failed (app may still be warming up)" -ForegroundColor Yellow
    Write-Host "  You can test manually: $appUrl/api/health" -ForegroundColor Gray
}

Write-Host "`nYour Azure Function App is now running!`n" -ForegroundColor Green

# Clean up state file
if (Test-Path "azure-stopped-state.json") {
    Remove-Item "azure-stopped-state.json"
    Write-Host "✓ Cleaned up state file`n" -ForegroundColor Green
}
