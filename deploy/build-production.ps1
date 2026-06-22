param(
    [Parameter(Mandatory = $true)]
    [string]$Domain
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot

Push-Location $root
try {
    flutter pub get
    flutter build web --release `
        --base-href /app/ `
        --dart-define="KOMI_API_BASE=https://$Domain/api/v1"
} finally {
    Pop-Location
}

Write-Host "Build ready in $root\build\web"
