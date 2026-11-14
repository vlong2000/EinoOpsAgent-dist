# Eino Ops Agent - PowerShell Launcher
$ErrorActionPreference = "Continue"

if (-not (Test-Path ".env")) {
    Write-Host "[WARNING] .env not found, copying from template..." -ForegroundColor Yellow
    Copy-Item ".env.example" ".env" -Force
    Write-Host "[WARNING] Please edit .env with your API key, then run again." -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "[OK] Starting eino-ops-agent.exe ..." -ForegroundColor Green
.\eino-ops-agent.exe
