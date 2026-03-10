$ScriptPath = Join-Path $PSScriptRoot "ClipTree.ps1"

if (!(Test-Path $ScriptPath)) {
    Write-Host "Error: Could not find ClipTree.ps1 in this folder!" -ForegroundColor Red
    return
}

$LoaderLine = ". `"$ScriptPath`""

$ProfileDir = Split-Path $PROFILE
if (!(Test-Path $ProfileDir)) {
    New-Item -Path $ProfileDir -ItemType Directory -Force
}

Add-Content -Path $PROFILE -Value "`n$LoaderLine"

Write-Host "------------------------------------------------" -ForegroundColor Cyan
Write-Host "Success! Clip-Tree is now linked to your Profile." -ForegroundColor Green
Write-Host "Linked to: $ScriptPath" -ForegroundColor Gray
Write-Host "Please restart PowerShell to activate the command." -ForegroundColor Yellow
Write-Host "------------------------------------------------" -ForegroundColor Cyan