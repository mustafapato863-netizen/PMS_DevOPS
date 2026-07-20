# Handover Package Creator Script
$root = "d:\Projects\PMS_Dashboard"
$handoverDir = "$root\Handover"
$tempDir = "$handoverDir\Temp"

if (Test-Path $tempDir) {
    Remove-Item -Recurse -Force $tempDir
}
New-Item -ItemType Directory -Force -Path $tempDir | Out-Null

Write-Host "1. Copying Frontend files..."
robocopy "$root\Frontend" "$tempDir\Frontend" /XD node_modules .git .pytest_cache /S /NJH /NJS /NDL /NC /NS /NFL

Write-Host "2. Copying Backend files..."
robocopy "$root\Backend" "$tempDir\Backend" /XD .venv .git __pycache__ .pytest_cache .hypothesis /S /NJH /NJS /NDL /NC /NS /NFL

Write-Host "3. Copying DevOps files..."
robocopy "$root\DevOps" "$tempDir\DevOps" /XD .git /S /NJH /NJS /NDL /NC /NS /NFL

Write-Host "4. Copying Database files..."
robocopy "$root\Database" "$tempDir\Database" /XD .git /S /NJH /NJS /NDL /NC /NS /NFL

Write-Host "5. Copying Root documentation and scripts..."
Get-ChildItem -Path $root -File -Filter "*.md" | Copy-Item -Destination $tempDir -ErrorAction SilentlyContinue
Get-ChildItem -Path $root -File -Filter "*.ps1" | Copy-Item -Destination $tempDir -ErrorAction SilentlyContinue

$zipPath = "$handoverDir\Project_Handover.zip"
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}

Write-Host "6. Compressing package into Project_Handover.zip..."
Compress-Archive -Path "$tempDir\*" -DestinationPath $zipPath -Force

Write-Host "7. Cleaning up temporary folder..."
Remove-Item -Recurse -Force $tempDir

Write-Host "SUCCESS: Handover package created at $zipPath"
