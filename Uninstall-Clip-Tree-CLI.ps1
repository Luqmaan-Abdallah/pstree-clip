$TargetDir = Join-Path $HOME "Clip-Tree"

$E = [char]27

Write-Output "$E[36mStarting Clip-Tree removal sequence...$E[0m"

if (Test-Path $PROFILE) {
    Write-Output "$E[90mCleaning PowerShell profile...$E[0m"
    
    $content = Get-Content $PROFILE -ErrorAction SilentlyContinue
    $newContent = $content | Where-Object { 
        $_ -notlike "*Clip-Tree.ps1*" -and 
        $_ -notlike "*pstree-clip.ps1*" 
    }

    $newContent | Set-Content $PROFILE -Force
    Write-Output "$E[32mDone: Profile references removed.$E[0m"
} else {
    Write-Output "$E[90mNote: No PowerShell profile found. Skipping profile cleanup.$E[0m"
}

if (Test-Path $TargetDir) {
    Write-Output "$E[90mRemoving installation directory: $TargetDir$E[0m"
    try {
        Remove-Item -Path $TargetDir -Recurse -Force -ErrorAction Stop
        Write-Output "$E[32mDone: Files deleted.$E[0m"
    }
    catch {
        Write-Output "$E[33mWarning: Could not remove directory. It might be in use.$E[0m"
    }
} else {
    Write-Output "$E[90mNote: Installation directory not found.$E[0m"
}

Write-Output "$E[36m------------------------------------------------$E[0m"
Write-Output "$E[32mUninstallation complete.$E[0m"
Write-Output "The 'Clip-Tree', 'ct', and 'clip-tree' commands are now inactive."
Write-Output ""
Write-Output "$E[33mNote: Restart your terminal to clear existing aliases from memory.$E[0m"
Write-Output "$E[36m------------------------------------------------$E[0m"