#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Run Ruff linter and formatter on the codebase
.DESCRIPTION
    This script runs Ruff to check and format Python code
#>

param(
    [Parameter(Mandatory=$false)]
    [switch]$Fix,
    
    [Parameter(Mandatory=$false)]
    [switch]$Format
)

Write-Host "Running Ruff on FnCast project..." -ForegroundColor Cyan

if ($Fix) {
    Write-Host "`nFixing linting issues..." -ForegroundColor Yellow
    ruff check . --fix
} else {
    Write-Host "`nChecking for linting issues..." -ForegroundColor Yellow
    ruff check .
}

if ($Format) {
    Write-Host "`nFormatting code..." -ForegroundColor Yellow
    ruff format .
} else {
    Write-Host "`nChecking code formatting..." -ForegroundColor Yellow
    ruff format --check .
}

Write-Host "`nDone!" -ForegroundColor Green
