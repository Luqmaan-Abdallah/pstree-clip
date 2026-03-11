$TargetDir = Join-Path $HOME "Clip-Tree"
$TargetScriptPath = Join-Path $TargetDir "Clip-Tree.ps1"
$CurrentScriptPath = Join-Path $PSScriptRoot "Clip-Tree.ps1"

$E = [char]27

if (!(Test-Path $CurrentScriptPath)) {
    Write-Output "$E[31mError: Clip-Tree.ps1 not found in the current directory.$E[0m"
    return
}

Write-Output "$E[36mSetting up Clip-Tree at: $TargetDir$E[0m"

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

Write-Output "$E[36m------------------------------------------------$E[0m"
Write-Output "$E[32mSetup finished. Clip-Tree is now linked.$E[0m"
Write-Output "Primary Command:  Get-Tree"
Write-Output "Branded Alias:    Clip-Tree"
Write-Output "Short Alias:      ct"
Write-Output ""
Write-Output "$E[33mNote: Please restart your terminal to activate the changes.$E[0m"
Write-Output "$E[3m$E[36m------------------------------------------------$E[0m"