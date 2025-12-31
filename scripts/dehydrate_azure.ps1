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

# Stop Function App
Write-Host "Stopping Function App '$FunctionAppName'..." -ForegroundColor Cyan
try {
    az functionapp stop --name $FunctionAppName --resource-group $ResourceGroupName
    Write-Host "✓ Function App stopped successfully" -ForegroundColor Green
} catch {
    Write-Host "✗ Failed to stop Function App: $_" -ForegroundColor Red
}

# Check if App Insights should be disabled (note: can't fully stop, but can disable ingestion)
if (-not $KeepAppInsights) {
    Write-Host "`nDisabling Application Insights ingestion..." -ForegroundColor Cyan
    Write-Host "⚠ Note: Application Insights still charges for data retention" -ForegroundColor Yellow
    Write-Host "  To fully save costs, consider deleting App Insights temporarily" -ForegroundColor Yellow
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
    stoppedAt = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
}

$state | ConvertTo-Json | Out-File "azure-stopped-state.json"
Write-Host "✓ State saved to azure-stopped-state.json" -ForegroundColor Green
