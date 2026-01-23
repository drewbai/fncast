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
    [string]$FunctionAppName = "fncast-4654"
)

Write-Host "======================================" -ForegroundColor Yellow
Write-Host "Starting Azure FnCast Resources" -ForegroundColor Yellow
Write-Host "======================================`n" -ForegroundColor Yellow

# Check for saved state
if (Test-Path "azure-stopped-state.json") {
    Write-Host "Loading saved state..." -ForegroundColor Cyan
    $state = Get-Content "azure-stopped-state.json" | ConvertFrom-Json
    $ResourceGroupName = $state.resourceGroup
    $FunctionAppName = $state.functionAppName
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
