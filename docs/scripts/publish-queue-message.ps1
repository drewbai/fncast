param(
  [string]$ConnectionString,
  [string]$QueueName = "fncast-events",
  [string]$Message = "hello"
)

if (-not $ConnectionString) {
  Write-Error "Please provide -ConnectionString for the Storage account."
  exit 1
}

Write-Host "Ensuring queue '$QueueName' exists..."
az storage queue create --name $QueueName --connection-string $ConnectionString | Out-Null

Write-Host "Sending message to '$QueueName'..."
az storage message put --queue-name $QueueName --connection-string $ConnectionString --content $Message | Out-Null

Write-Host "Done."
