param(
  [string]$FunctionsBaseUrl = "http://localhost:7071",
  [string]$Mode = "all"
)

Write-Host "Starting demo against $FunctionsBaseUrl" -ForegroundColor Cyan

Write-Host "Health check..."
try {
  $health = Invoke-RestMethod -Method GET -Uri "$FunctionsBaseUrl/api/HealthCheck"
  Write-Host ($health | ConvertTo-Json) -ForegroundColor Green
} catch {
  Write-Warning "Health check failed: $($_.Exception.Message)"
}

Write-Host "POST /api/ingest (text/plain)..."
try {
  $textResult = Invoke-RestMethod -Method POST -Uri "$FunctionsBaseUrl/api/ingest" -ContentType 'text/plain' -Body 'hello world'
  Write-Host ($textResult | ConvertTo-Json) -ForegroundColor Green
} catch {
  Write-Warning "Text ingest failed: $($_.Exception.Message)"
}

Write-Host "POST /api/ingest (application/json)..."
try {
  $payload = @{ payload = 'hello world'; contentType = 'text/plain' } | ConvertTo-Json
  $jsonResult = Invoke-RestMethod -Method POST -Uri "$FunctionsBaseUrl/api/ingest" -ContentType 'application/json' -Body $payload
  Write-Host ($jsonResult | ConvertTo-Json) -ForegroundColor Green
} catch {
  Write-Warning "JSON ingest failed: $($_.Exception.Message)"
}

Write-Host "Demo complete." -ForegroundColor Cyan
