param(
  [string]$ResourceGroup,
  [string]$TopicName,
  [string]$Subject = "demo",
  [string]$Data = '{"message":"hello"}'
)

if (-not $ResourceGroup -or -not $TopicName) {
  Write-Error "Provide -ResourceGroup and -TopicName."
  exit 1
}

Write-Host "Publishing to Event Grid topic '$TopicName' in RG '$ResourceGroup'..."
az eventgrid event publish `
  --resource-group $ResourceGroup `
  --topic-name $TopicName `
  --subject $Subject `
  --data $Data `
  --event-type "DemoEvent" `
  --data-version 1

Write-Host "Done."
