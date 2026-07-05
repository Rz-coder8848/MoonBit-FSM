$ErrorActionPreference = "Stop"

$scriptPath = Join-Path $PSScriptRoot "verify_acceptance.ps1"
if (!(Test-Path $scriptPath)) {
  throw "Missing acceptance script: $scriptPath"
}

$output = cmd /c "powershell -ExecutionPolicy Bypass -File `"$scriptPath`" 2>&1" | Out-String

$requiredMarkers = @(
  "MoonBit version:",
  "Formatting:",
  "Tests:",
  "Tracked build artifacts:",
  "Mooncakes search:"
)

foreach ($marker in $requiredMarkers) {
  if ($output -notmatch [regex]::Escape($marker)) {
    throw "Acceptance output missing marker: $marker`n$output"
  }
}

Write-Host "Acceptance script output markers verified."
