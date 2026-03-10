$TargetDir = Join-Path $HOME "ClipTree"
$TargetScriptPath = Join-Path $TargetDir "ClipTree.ps1"

Write-Host "Starting ClipTree removal sequence..." -ForegroundColor Cyan

if (Test-Path $PROFILE) {
    Write-Host "Cleaning PowerShell profile..." -ForegroundColor Gray
    
    $content = Get-Content $PROFILE -ErrorAction SilentlyContinue
    $newContent = $content | Where-Object { 
        $_ -notlike "*ClipTree.ps1*" -and 
        $_ -notlike "*pstree-clip.ps1*" 
    }

    $newContent | Set-Content $PROFILE -Force
    Write-Host "Done: Profile references removed." -ForegroundColor Green
} else {
    Write-Host "Note: No PowerShell profile found. Skipping profile cleanup." -ForegroundColor Gray
}

if (Test-Path $TargetDir) {
    Write-Host "Removing installation directory: $TargetDir" -ForegroundColor Gray
    try {
        Remove-Item -Path $TargetDir -Recurse -Force -ErrorAction Stop
        Write-Host "Done: Files deleted." -ForegroundColor Green
    }
    catch {
        Write-Host "Warning: Could not remove directory. It might be in use." -ForegroundColor Yellow
    }
} else {
    Write-Host "Note: Installation directory not found." -ForegroundColor Gray
}

Write-Host "------------------------------------------------" -ForegroundColor Cyan
Write-Host "Uninstallation complete." -ForegroundColor Green
Write-Host "The 'Clip-Tree', 'ct', and 'cliptree' commands are now inactive." -ForegroundColor White
Write-Host ""
Write-Host "Note: Restart your terminal to clear existing aliases from memory." -ForegroundColor Yellow
Write-Host "------------------------------------------------" -ForegroundColor Cyan