param(
  [string]$Source = "screenshots",
  [string]$Destination = "docs/screenshots"
)

$src = Join-Path $PSScriptRoot "..\$Source"
$dst = Join-Path $PSScriptRoot "..\$Destination"

if (-not (Test-Path $src)) {
  Write-Host "Source screenshots folder not found: $src" -ForegroundColor Yellow
  exit 0
}

New-Item -ItemType Directory -Path $dst -Force | Out-Null
Copy-Item -Path (Join-Path $src "*.png") -Destination $dst -Force -ErrorAction SilentlyContinue
Write-Host "Copied screenshots to $dst" -ForegroundColor Green

