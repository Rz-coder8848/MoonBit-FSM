[CmdletBinding()]
param(
  [switch]$SkipMooncakes
)

$ErrorActionPreference = "Stop"

Set-Location (Resolve-Path (Join-Path $PSScriptRoot ".."))

function Write-Section($label, $value) {
  Write-Host "$label $value"
}

function Invoke-Step($name, [scriptblock]$action) {
  try {
    $global:LASTEXITCODE = 0
    $result = & $action
    if ($LASTEXITCODE -ne 0) {
      throw "Command exited with code $LASTEXITCODE"
    }
    return @{
      Name = $name
      Ok = $true
      Output = ($result | Out-String).Trim()
    }
  } catch {
    return @{
      Name = $name
      Ok = $false
      Output = ($_ | Out-String).Trim()
    }
  }
}

function Get-ModuleName {
  if (Test-Path "moon.mod") {
    $content = Get-Content -Raw "moon.mod"
    $match = [regex]::Match($content, 'name\s*=\s*"([^"]+)"')
    if ($match.Success) { return $match.Groups[1].Value }
  }

  if (Test-Path "moon.mod.json") {
    return (Get-Content -Raw "moon.mod.json" | ConvertFrom-Json).name
  }

  throw "Unable to determine module name from moon.mod or moon.mod.json."
}

$requiredFiles = @(
  "README.md",
  "LICENSE",
  "CHANGELOG.md",
  ".github/workflows/ci.yml"
)

$missingFiles = $requiredFiles | Where-Object { !(Test-Path $_) }

$versionStep = Invoke-Step "MoonBit version" { moon version --all }
$infoStep = Invoke-Step "Moon info" { moon info }
$formatStep = Invoke-Step "Formatting" { moon fmt --check }
$checkStep = Invoke-Step "Type check" { moon check }
$testStep = Invoke-Step "Tests" { moon test }

$trackedBuildArtifacts = @(git ls-files _build)
$moduleName = Get-ModuleName
$mooncakesUrl = "https://mooncakes.io/api/v0/modules/$moduleName"
$mooncakesStep = if ($SkipMooncakes) {
  @{
    Name = "Mooncakes search"
    Ok = $true
    Output = "Skipped by request."
  }
} else {
  Invoke-Step "Mooncakes search" {
    curl.exe -fsSL $mooncakesUrl
  }
}

Write-Section "MoonBit version:" ($(if ($versionStep.Ok) { "PASS" } else { "FAIL" }))
Write-Host $versionStep.Output
Write-Section "Moon info:" ($(if ($infoStep.Ok) { "PASS" } else { "FAIL" }))
Write-Host $infoStep.Output
Write-Section "Formatting:" ($(if ($formatStep.Ok) { "PASS" } else { "FAIL" }))
Write-Host $formatStep.Output
Write-Section "Type check:" ($(if ($checkStep.Ok) { "PASS" } else { "FAIL" }))
Write-Host $checkStep.Output
Write-Section "Tests:" ($(if ($testStep.Ok) { "PASS" } else { "FAIL" }))
Write-Host $testStep.Output
Write-Section "Required files:" ($(if ($missingFiles.Count -eq 0) { "PASS" } else { "FAIL" }))
if ($missingFiles.Count -eq 0) {
  Write-Host "README.md, LICENSE, CHANGELOG.md, and .github/workflows/ci.yml are present."
} else {
  Write-Host ("Missing: " + ($missingFiles -join ", "))
}
Write-Section "Tracked build artifacts:" ($(if ($trackedBuildArtifacts.Count -eq 0) { "PASS" } else { "FAIL" }))
if ($trackedBuildArtifacts.Count -eq 0) {
  Write-Host "No tracked files under _build."
} else {
  $trackedBuildArtifacts | ForEach-Object { Write-Host $_ }
}
Write-Section "Mooncakes search:" ($(if ($mooncakesStep.Ok) { "PASS" } else { "FAIL" }))
if ($mooncakesStep.Ok) {
  if ($SkipMooncakes) {
    Write-Host $mooncakesStep.Output
  } else {
    Write-Host $mooncakesUrl
  }
} else {
  Write-Host $mooncakesStep.Output
}

$hasFailure = @(
  -not $versionStep.Ok,
  -not $infoStep.Ok,
  -not $formatStep.Ok,
  -not $checkStep.Ok,
  -not $testStep.Ok,
  $missingFiles.Count -ne 0,
  $trackedBuildArtifacts.Count -ne 0,
  -not $mooncakesStep.Ok
) -contains $true

if ($hasFailure) {
  exit 1
}
