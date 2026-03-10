$TargetDir = Join-Path $HOME "ClipTree"
$TargetScriptPath = Join-Path $TargetDir "ClipTree.ps1"
$CurrentScriptPath = Join-Path $PSScriptRoot "ClipTree.ps1"

if (!(Test-Path $CurrentScriptPath)) {
    Write-Host "Error: Could not find ClipTree.ps1 in this folder!" -ForegroundColor Red
    return
}

Write-Host "Installing ClipTree to standard location: $TargetDir..." -ForegroundColor Cyan

if (!(Test-Path $TargetDir)) {
    New-Item -Path $TargetDir -ItemType Directory -Force | Out-Null
}

Copy-Item -Path $CurrentScriptPath -Destination $TargetScriptPath -Force

$LoaderLine = ". `"$TargetScriptPath`""

$ProfileDir = Split-Path $PROFILE
if (!(Test-Path $ProfileDir)) {
    New-Item -Path $ProfileDir -ItemType Directory -Force | Out-Null
}
if (!(Test-Path $PROFILE)) {
    New-Item -Path $PROFILE -ItemType File -Force | Out-Null
}

$content = Get-Content $PROFILE
$newContent = $content | Where-Object { $_ -notlike "*pstree-clip.ps1*" -and $_ -notlike "*ClipTree.ps1*" }
$newContent | Set-Content $PROFILE

Add-Content -Path $PROFILE -Value "`n$LoaderLine"

Write-Host "------------------------------------------------" -ForegroundColor Cyan
Write-Host "Success! Clip-Tree is now installed and linked." -ForegroundColor Green
Write-Host "Permanent Path: $TargetScriptPath" -ForegroundColor Gray
Write-Host "Please restart PowerShell to activate the 'ct' and 'cliptree' commands." -ForegroundColor Yellow
Write-Host "------------------------------------------------" -ForegroundColor Cyan