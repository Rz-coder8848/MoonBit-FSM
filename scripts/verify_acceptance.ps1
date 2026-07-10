[CmdletBinding()]
param(
  [switch]$SkipMooncakes,
  [switch]$SkipCommands,
  [string]$ProjectRoot = ""
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
  $ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
}

Set-Location $ProjectRoot

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

function Get-ModuleMetadata {
  $content = Get-Content -Raw "moon.mod"
  $name = [regex]::Match($content, 'name\s*=\s*"([^"]+)"').Groups[1].Value
  $version = [regex]::Match($content, 'version\s*=\s*"([^"]+)"').Groups[1].Value
  $repository = [regex]::Match($content, 'repository\s*=\s*"([^"]+)"').Groups[1].Value

  if (!$name -or !$version -or !$repository) {
    throw "Unable to parse name, version, or repository from moon.mod."
  }

  return @{
    Name = $name
    Version = $version
    Repository = $repository
  }
}

function Test-RequiredPatterns([string]$Content, [string[]]$Patterns) {
  $missing = @()
  foreach ($pattern in $Patterns) {
    if ($Content -notmatch [regex]::Escape($pattern)) {
      $missing += $pattern
    }
  }
  return $missing
}

function Test-HasNativeCompiler {
  foreach ($tool in @("cl", "gcc", "clang")) {
    $cmd = Get-Command $tool -ErrorAction SilentlyContinue
    if ($cmd) {
      return $true
    }
  }
  return $false
}

function Get-TrackedBuildArtifacts {
  $gitDir = Join-Path $ProjectRoot ".git"
  if (!(Test-Path $gitDir)) {
    return @()
  }
  return @(git -C $ProjectRoot ls-files _build 2>$null)
}

$requiredFiles = @(
  "README.md",
  "LICENSE",
  "CHANGELOG.md",
  ".github/workflows/ci.yml",
  "docs/release-alignment.md"
)

$missingFiles = $requiredFiles | Where-Object { !(Test-Path $_) }
$metadata = Get-ModuleMetadata
$readmeContent = if (Test-Path "README.md") { Get-Content -Raw "README.md" } else { "" }
$ciContent = if (Test-Path ".github/workflows/ci.yml") { Get-Content -Raw ".github/workflows/ci.yml" } else { "" }

$versionStep = if ($SkipCommands) {
  @{ Name = "MoonBit version"; Ok = $true; Output = "Skipped by request." }
} else {
  Invoke-Step "MoonBit version" { moon version --all }
}

$infoStep = if ($SkipCommands) {
  @{ Name = "Moon info"; Ok = $true; Output = "Skipped by request." }
} else {
  Invoke-Step "Moon info" { moon info }
}

$formatStep = if ($SkipCommands) {
  @{ Name = "Formatting"; Ok = $true; Output = "Skipped by request." }
} else {
  Invoke-Step "Formatting" { moon fmt --check }
}

$checkStep = if ($SkipCommands) {
  @{ Name = "Type check"; Ok = $true; Output = "Skipped by request." }
} else {
  Invoke-Step "Type check" { moon check --deny-warn --target all }
}

$testStep = if ($SkipCommands) {
  @{ Name = "Tests"; Ok = $true; Output = "Skipped by request." }
} else {
  if (Test-HasNativeCompiler) {
    Invoke-Step "Tests" { moon test --deny-warn --target all }
  } else {
    Invoke-Step "Tests" {
      moon test --deny-warn
      Write-Output "Native target skipped locally because no system C compiler was found. CI still runs moon test --deny-warn --target all."
    }
  }
}

$trackedBuildArtifacts = Get-TrackedBuildArtifacts
$ciRequiredPatterns = @(
  "moon fmt --check",
  "moon info",
  "moon check --deny-warn --target all",
  "moon test --deny-warn --target all"
)
$ciMissingPatterns = Test-RequiredPatterns $ciContent $ciRequiredPatterns
$ciStep = @{
  Name = "CI coverage"
  Ok = ($ciMissingPatterns.Count -eq 0)
  Output = if ($ciMissingPatterns.Count -eq 0) {
    "CI contains all required checks."
  } else {
    "Missing CI commands: " + ($ciMissingPatterns -join ", ")
  }
}

$readmeRequiredPatterns = @(
  "Package version: ``$($metadata.Version)``",
  $metadata.Repository,
  "https://gitlink.org.cn/Douj/moon-fsm",
  "Published on Mooncakes: [Rz-coder8848/moon-fsm v$($metadata.Version)]"
)
$readmeMissingPatterns = Test-RequiredPatterns $readmeContent $readmeRequiredPatterns
$readmeStep = @{
  Name = "README release alignment"
  Ok = ($readmeMissingPatterns.Count -eq 0)
  Output = if ($readmeMissingPatterns.Count -eq 0) {
    "README version, repo links, and Mooncakes marker are aligned."
  } else {
    "README is missing: " + ($readmeMissingPatterns -join ", ")
  }
}

$metadataStep = @{
  Name = "Metadata alignment"
  Ok = ($metadata.Repository -eq "https://github.com/Rz-coder8848/MoonBit-FSM")
  Output = if ($metadata.Repository -eq "https://github.com/Rz-coder8848/MoonBit-FSM") {
    "moon.mod repository matches the public GitHub repository."
  } else {
    "moon.mod repository mismatch: $($metadata.Repository)"
  }
}

$mooncakesUrl = "https://mooncakes.io/api/v0/modules/$($metadata.Name)"
$mooncakesStep = if ($SkipMooncakes) {
  @{
    Name = "Mooncakes search"
    Ok = $true
    Output = "Skipped by request."
  }
} else {
  Invoke-Step "Mooncakes search" {
    $response = curl.exe -fsSL $mooncakesUrl | ConvertFrom-Json
    if ($response.latest_version -ne $metadata.Version) {
      throw "Mooncakes latest version is $($response.latest_version), expected $($metadata.Version)."
    }
    $response.latest_version
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
  Write-Host (($requiredFiles -join ", ") + " are present.")
} else {
  Write-Host ("Missing: " + ($missingFiles -join ", "))
}
Write-Section "Tracked build artifacts:" ($(if ($trackedBuildArtifacts.Count -eq 0) { "PASS" } else { "FAIL" }))
if ($trackedBuildArtifacts.Count -eq 0) {
  Write-Host "No tracked files under _build."
} else {
  $trackedBuildArtifacts | ForEach-Object { Write-Host $_ }
}
Write-Section "CI coverage:" ($(if ($ciStep.Ok) { "PASS" } else { "FAIL" }))
Write-Host $ciStep.Output
Write-Section "README release alignment:" ($(if ($readmeStep.Ok) { "PASS" } else { "FAIL" }))
Write-Host $readmeStep.Output
Write-Section "Metadata alignment:" ($(if ($metadataStep.Ok) { "PASS" } else { "FAIL" }))
Write-Host $metadataStep.Output
Write-Section "Mooncakes search:" ($(if ($mooncakesStep.Ok) { "PASS" } else { "FAIL" }))
if ($mooncakesStep.Ok) {
  if ($SkipMooncakes) {
    Write-Host $mooncakesStep.Output
  } else {
    Write-Host "$mooncakesUrl -> $($metadata.Version)"
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
  -not $ciStep.Ok,
  -not $readmeStep.Ok,
  -not $metadataStep.Ok,
  -not $mooncakesStep.Ok
) -contains $true

if ($hasFailure) {
  exit 1
}
