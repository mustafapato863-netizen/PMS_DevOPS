# PMS Dashboard - Setup Script
# This script sets up the Backend python virtual environment and installs Frontend packages.

Write-Host "=== Starting PMS Dashboard Setup ===" -ForegroundColor Cyan

# 1. Setup Backend
Write-Host "`n[1/2] Setting up Backend..." -ForegroundColor Yellow
if (Test-Path "Backend") {
    Push-Location Backend
    try {
        if (-not (Test-Path ".venv")) {
            Write-Host "Creating Python virtual environment..." -ForegroundColor Gray
            python -m venv .venv
        } else {
            Write-Host "Virtual environment already exists." -ForegroundColor Gray
        }

        Write-Host "Installing Python requirements..." -ForegroundColor Gray
        .\.venv\Scripts\pip install -r requirements.txt
        Write-Host "Backend setup completed successfully!" -ForegroundColor Green
    } catch {
        Write-Error "Failed to setup Backend: $_"
    } finally {
        Pop-Location
    }
} else {
    Write-Warning "Backend directory not found!"
}

# 2. Setup Frontend
Write-Host "`n[2/2] Setting up Frontend..." -ForegroundColor Yellow
if (Test-Path "Frontend") {
    Push-Location Frontend
    try {
        Write-Host "Installing npm packages..." -ForegroundColor Gray
        npm install
        Write-Host "Frontend setup completed successfully!" -ForegroundColor Green
    } catch {
        Write-Error "Failed to setup Frontend: $_"
    } finally {
        Pop-Location
    }
} else {
    Write-Warning "Frontend directory not found!"
}

Write-Host "`n=== Setup Finished! ===" -ForegroundColor Cyan
Write-Host "To run the Backend: cd Backend; .\.venv\Scripts\activate; uvicorn app:app --reload --port 8000" -ForegroundColor Gray
Write-Host "To run the Frontend: cd Frontend; npm run dev" -ForegroundColor Gray
