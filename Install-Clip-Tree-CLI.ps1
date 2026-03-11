$TargetDir = Join-Path $HOME "Clip-Tree"
$TargetScriptPath = Join-Path $TargetDir "Clip-Tree.ps1"
$CurrentScriptPath = Join-Path $PSScriptRoot "Clip-Tree.ps1"

if (!(Test-Path $CurrentScriptPath)) {
    Write-Host "Error: Clip-Tree.ps1 not found in the current directory." -ForegroundColor Red
    return
}

Write-Host "Setting up Clip-Tree at: $TargetDir" -ForegroundColor Cyan

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

$content = Get-Content $PROFILE -ErrorAction SilentlyContinue
$newContent = $content | Where-Object { $_ -notlike "*pstree-clip.ps1*" -and $_ -notlike "*Clip-Tree.ps1*" }

($newContent + $LoaderLine) | Set-Content $PROFILE -Force

Write-Host "------------------------------------------------" -ForegroundColor Cyan
Write-Host "Setup finished. Clip-Tree is now linked." -ForegroundColor Green
Write-Host "Primary Command:  Clip-Tree" -ForegroundColor White
Write-Host "Quick Aliases:    ct, clip-tree" -ForegroundColor Gray
Write-Host ""
Write-Host "Note: Please restart your terminal to activate the changes." -ForegroundColor Yellow
Write-Host "------------------------------------------------" -ForegroundColor Cyan