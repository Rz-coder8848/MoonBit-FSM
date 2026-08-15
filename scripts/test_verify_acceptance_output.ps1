$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $false

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$scriptPath = Join-Path $PSScriptRoot "verify_acceptance.ps1"
if (!(Test-Path $scriptPath)) {
  throw "Missing acceptance script: $scriptPath"
}

function Invoke-Verify([string]$ProjectRoot, [switch]$SkipMooncakes, [switch]$SkipCommands) {
  $command = 'powershell -NoProfile -ExecutionPolicy Bypass -File "{0}" -ProjectRoot "{1}"' -f $scriptPath, $ProjectRoot
  if ($SkipMooncakes) {
    $command += " -SkipMooncakes"
  }
  if ($SkipCommands) {
    $command += " -SkipCommands"
  }
  $rawOutput = cmd /c "$command 2>&1"
  $exitCode = $LASTEXITCODE
  return @{
    Output = ($rawOutput | Out-String)
    ExitCode = $exitCode
  }
}

function New-FixtureRoot {
  $root = Join-Path ([System.IO.Path]::GetTempPath()) ("moon-fsm-acceptance-" + [guid]::NewGuid().ToString("N"))
  New-Item -ItemType Directory -Force -Path $root | Out-Null
  New-Item -ItemType Directory -Force -Path (Join-Path $root ".github\workflows") | Out-Null
  New-Item -ItemType Directory -Force -Path (Join-Path $root "docs") | Out-Null
  New-Item -ItemType Directory -Force -Path (Join-Path $root "benchmarks\data") | Out-Null
  New-Item -ItemType Directory -Force -Path (Join-Path $root "examples\order_workflow") | Out-Null
  Copy-Item (Join-Path $repoRoot "audit_test.mbt") (Join-Path $root "audit_test.mbt")
  Copy-Item (Join-Path $repoRoot "batch_test.mbt") (Join-Path $root "batch_test.mbt")
  Copy-Item (Join-Path $repoRoot "snapshot_test.mbt") (Join-Path $root "snapshot_test.mbt")
  Copy-Item (Join-Path $repoRoot "examples\order_workflow\main.mbt") (Join-Path $root "examples\order_workflow\main.mbt")
  Copy-Item (Join-Path $repoRoot "examples\order_workflow\moon.pkg") (Join-Path $root "examples\order_workflow\moon.pkg")
  Copy-Item (Join-Path $repoRoot "README.md") (Join-Path $root "README.md")
  Copy-Item (Join-Path $repoRoot "LICENSE") (Join-Path $root "LICENSE")
  Copy-Item (Join-Path $repoRoot "CHANGELOG.md") (Join-Path $root "CHANGELOG.md")
  Copy-Item (Join-Path $repoRoot "moon.mod") (Join-Path $root "moon.mod")
  Copy-Item (Join-Path $repoRoot ".github\workflows\ci.yml") (Join-Path $root ".github\workflows\ci.yml")
  Copy-Item (Join-Path $repoRoot "docs\release-alignment.md") (Join-Path $root "docs\release-alignment.md")
  Copy-Item (Join-Path $repoRoot "benchmarks\README.md") (Join-Path $root "benchmarks\README.md")
  Copy-Item (Join-Path $repoRoot "benchmarks\data\workflow_cases.csv") (Join-Path $root "benchmarks\data\workflow_cases.csv")
  return $root
}

$baseline = Invoke-Verify -ProjectRoot $repoRoot -SkipMooncakes
$requiredMarkers = @(
  "MoonBit version:",
  "Moon info:",
  "Formatting:",
  "Type check:",
  "Tests:",
  "Workflow benchmark:",
  "Order workflow example:",
  "CI coverage:",
  "README release alignment:",
  "Metadata alignment:",
  "License compliance:",
  "Mooncakes search:"
)

foreach ($marker in $requiredMarkers) {
  if ($baseline.Output -notmatch [regex]::Escape($marker)) {
    throw "Acceptance output missing marker: $marker`n$($baseline.Output)"
  }
}

$fixtureRoot = New-FixtureRoot
try {
  (Get-Content (Join-Path $fixtureRoot ".github\workflows\ci.yml") -Raw).
    Replace("moon info", "moon-info-removed") |
    Set-Content (Join-Path $fixtureRoot ".github\workflows\ci.yml")
  $ciFailure = Invoke-Verify -ProjectRoot $fixtureRoot -SkipMooncakes -SkipCommands
  if ($ciFailure.Output -notmatch "CI coverage: FAIL") {
    throw "Expected CI coverage failure.`n$($ciFailure.Output)"
  }

  (Get-Content (Join-Path $fixtureRoot "README.md") -Raw).
    Replace("Published on Mooncakes: [Rz-coder8848/moon-fsm v0.2.1]", "Published on Mooncakes: pending") |
    Set-Content (Join-Path $fixtureRoot "README.md")
  $readmeFailure = Invoke-Verify -ProjectRoot $fixtureRoot -SkipMooncakes -SkipCommands
  if ($readmeFailure.Output -notmatch "README release alignment: FAIL") {
    throw "Expected README alignment failure.`n$($readmeFailure.Output)"
  }

  (Get-Content (Join-Path $fixtureRoot "moon.mod") -Raw).
    Replace('version = "0.2.1"', 'version = "9.9.9"') |
    Set-Content (Join-Path $fixtureRoot "moon.mod")
  $versionFailure = Invoke-Verify -ProjectRoot $fixtureRoot -SkipMooncakes -SkipCommands
  if ($versionFailure.Output -notmatch "README release alignment: FAIL") {
    throw "Expected version mismatch failure.`n$($versionFailure.Output)"
  }
} finally {
  Remove-Item -Recurse -Force $fixtureRoot
}

Write-Host "Acceptance script output markers and failure modes verified."
