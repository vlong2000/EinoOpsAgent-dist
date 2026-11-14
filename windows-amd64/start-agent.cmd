@echo off
chcp 65001 >nul 2>&1
echo.
echo  Eino 通信运维智能体 (Windows)
echo.

if not exist ".env" (
    echo [WARNING] .env not found, copying from template...
    copy /Y .env.example .env >nul
    echo [WARNING] Please edit .env with your API key, then run again.
    pause
    exit /b 1
)

echo [OK] Starting eino-ops-agent.exe ...
eino-ops-agent.exe
