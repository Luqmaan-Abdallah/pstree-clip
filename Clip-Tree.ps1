function Get-Tree {
    $RootPath = (Resolve-Path ".").Path
    $IgnoreFile = Join-Path $RootPath ".treeignore"
    $IgnoreList = @(".treeignore")

    if (Test-Path $IgnoreFile) {
        $IgnoreList += Get-Content $IgnoreFile | Where-Object { $_ -match '\S' } | ForEach-Object { $_.Trim() }
    }

    $report = [System.Text.StringBuilder]::new()

    $allFiles = Get-ChildItem -Path $RootPath -Recurse | Where-Object {
        $itemPath = $_.FullName
        $shouldIgnore = $false
        foreach ($pattern in $IgnoreList) {
            if ($itemPath -like "*$pattern*") { 
                $shouldIgnore = $true
                break 
            }
        }
        !$shouldIgnore
    } | Sort-Object FullName

    foreach ($item in $allFiles) {
        $RelativePath = $item.FullName.Substring($RootPath.Length).TrimStart('\')
        if ([string]::IsNullOrWhiteSpace($RelativePath)) { continue }
        
        $PathParts = $RelativePath -split '\\'
        $Depth = $PathParts.Count - 1
        
        $Indent = "  " * $Depth
        $symbol = if ($item.PSIsContainer) { "+ " } else { "- " }
        [void]$report.AppendLine("$Indent$symbol$($item.Name)")
    }

    $report.ToString() | Set-Clipboard
    
    $E = [char]27
    Write-Output "$E[32m$E[3mCopied to clipboard$E[0m"
}

Set-Alias -Name Clip-Tree -Value Get-Tree
Set-Alias -Name clip-tree -Value Get-Tree
Set-Alias -Name ct -Value Get-Tree