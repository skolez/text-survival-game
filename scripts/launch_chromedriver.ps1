param(
  [int]$Port = 4444
)

$ErrorActionPreference = "Stop"

$toolsDir = Join-Path $PSScriptRoot "bin\chromedriver"
$exePath  = Join-Path $toolsDir "chromedriver.exe"

if (-not (Test-Path $toolsDir)) { New-Item -ItemType Directory -Path $toolsDir | Out-Null }

function Start-ExistingDriver {
  Write-Host "Starting existing chromedriver at port $Port..."
  Start-Process -FilePath $exePath -ArgumentList @("--port=$Port") -WindowStyle Hidden
}

if (Test-Path $exePath) {
  Start-ExistingDriver
  exit 0
}

# Try to download latest-stable ChromeDriver for win64 via Chrome for Testing API
$api = "https://googlechromelabs.github.io/chrome-for-testing/last-known-good-versions-with-downloads.json"
try {
  Write-Host "Fetching ChromeDriver download info..."
  $json = Invoke-RestMethod -Uri $api -UseBasicParsing
  $win64 = $json.channels.Stable.downloads.chromedriver | Where-Object { $_.platform -eq "win64" } | Select-Object -First 1
  if (-not $win64) { throw "No win64 chromedriver in API response" }
  $zipUrl = $win64.url
  $zipPath = Join-Path $toolsDir "chromedriver-win64.zip"

  Write-Host "Downloading $zipUrl ..."
  Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseBasicParsing

  Write-Host "Extracting..."
  # Expand-Archive requires PowerShell 5+
  Expand-Archive -Path $zipPath -DestinationPath $toolsDir -Force

  # The zip contains a folder chromedriver-win64/chromedriver.exe
  $unpacked = Join-Path $toolsDir "chromedriver-win64\chromedriver.exe"
  if (Test-Path $unpacked) {
    Move-Item -Force $unpacked $exePath
    Remove-Item -Recurse -Force (Join-Path $toolsDir "chromedriver-win64")
  }
  Remove-Item -Force $zipPath

  if (-not (Test-Path $exePath)) { throw "chromedriver.exe not found after extraction" }

  Start-ExistingDriver
} catch {
  Write-Warning "Failed to download chromedriver automatically: $_"
  Write-Warning "Place a compatible chromedriver.exe at $exePath and re-run this script."
  exit 1
}

